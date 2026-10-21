class_name Comandos
extends RefCounted
## Comandos (Fase 8, ADR 0007): cada decisão de jogador é um dicionário que vira JSON sem
## perda, e aplicar o mesmo comando ao mesmo estado dá o mesmo resultado em qualquer máquina
## (toda rolagem sai de `Dados`, com seed). Seres do combate entram pelo índice em
## `participantes`; agentes da investigação, pelo índice na cena; hexes e células, como [x, y].
## Números chegam da rede como float: tudo passa por int() aqui.

const ACOES_MAPA := ["rolar_movimento", "mover", "descansar", "encerrar_turno", "resolver_evento", "usar_item", "conjurar", "deduzir"]
const ACOES_INVESTIGACAO := ["examinar", "procurar", "facilitar", "ajudar", "passar", "encerrar", "acao_extra", "trilha_certa", "sair", "deduzir"]
const ACOES_COMBATE := ["mover", "agredir", "conjurar", "granada", "contra", "item", "decifrar", "apagar", "soltar", "habilidade", "ia", "encerrar_turno", "sair",
	"socorrer", "acalmar", "manobra", "levantar", "pegar_arma"]
## Modo Mestre (Fase 8.3): valem em qualquer tela, só do peer do mestre
const ACOES_MESTRE := ["narrar", "membrana", "revelar", "encontro", "evento", "limpar", "curar", "ferir", "sanidade"]


static func novo(ctx: String, acao: String, args: Dictionary = {}) -> Dictionary:
	var cmd := {"ctx": ctx, "acao": acao}
	cmd.merge(args)
	return cmd


static func vetor(v: Vector2i) -> Array:
	return [v.x, v.y]


static func de_vetor(a) -> Vector2i:
	return Vector2i(int(a[0]), int(a[1]))


# --- Mapa -----------------------------------------------------------------------------

static func aplicar_mapa(m: Missao, cmd: Dictionary) -> Dictionary:
	match String(cmd.get("acao", "")):
		"rolar_movimento":
			if m.movimento_rolado:
				return {"ok": false, "erro": "o movimento já foi rolado"}
			return {"ok": true, "rolagem": m.rolar_movimento(int(cmd.get("foco", 0)))}
		"mover":
			return {"ok": m.mover(de_vetor(cmd.hex))}
		"descansar":
			return {"ok": m.descansar()}
		"encerrar_turno":
			m.encerrar_turno()
			return {"ok": true}
		"resolver_evento":
			if m.evento_pendente.is_empty():
				return {"ok": false, "erro": "nenhum evento pendente"}
			return {"ok": true, "teste": m.resolver_evento(int(cmd.get("foco", 0)), int(cmd.get("opcao", 0)))}
		"usar_item":
			var alvo := _agente_da_missao(m, cmd.get("alvo", ""))
			var r := m.usar_item_no_mapa(String(cmd.get("item", "")), alvo) if alvo != null else {}
			return {"ok": not r.is_empty(), "resultado": r}
		"conjurar":
			var alvo := _agente_da_missao(m, cmd.get("alvo", ""))
			var r := m.conjurar_no_mapa(String(cmd.get("ritual", "")), String(cmd.get("forma", "")), alvo) if alvo != null else {}
			return {"ok": not r.is_empty(), "resultado": r}
		"deduzir":
			var r := m.deduzir(String(cmd.get("pergunta", "")), String(cmd.get("candidato", "")))
			return {"ok": r.get("ok", false), "deducao": r}
	return {"ok": false, "erro": "ação de mapa desconhecida: %s" % cmd.get("acao", "")}


static func _agente_da_missao(m: Missao, agente_id) -> Agente:
	for a in m.agentes:
		if a.id == String(agente_id):
			return a
	return null


# --- Investigação -----------------------------------------------------------------------

static func aplicar_investigacao(cena: CenaInvestigacao, cmd: Dictionary) -> Dictionary:
	match String(cmd.get("acao", "")):
		"examinar":
			var r := cena.examinar(String(cmd.ponto), String(cmd.pericia))
			return {"ok": not r.is_empty(), "exame": r}
		"procurar":
			var r := cena.procurar(String(cmd.ponto), String(cmd.pericia), int(cmd.get("foco", 0)), _opcoes(cmd))
			return {"ok": not r.is_empty(), "teste": r}
		"facilitar":
			var r := cena.facilitar(String(cmd.opcao), String(cmd.pericia), int(cmd.get("foco", 0)), _opcoes(cmd))
			return {"ok": not r.is_empty(), "teste": r}
		"ajudar":
			var aliado := _agente_da_cena(cena, cmd.get("aliado", -1))
			if aliado == null:
				return {"ok": false, "erro": "aliado inválido"}
			var r := cena.ajudar(aliado, String(cmd.pericia), bool(cmd.get("espirito_civico", true)))
			return {"ok": not r.is_empty(), "teste": r}
		"passar":
			cena.passar()
			return {"ok": true}
		"encerrar":
			cena.encerrar()
			return {"ok": true}
		"acao_extra":
			return {"ok": cena.acao_extra(String(cmd.habilidade))}
		"trilha_certa":
			var a := _agente_da_cena(cena, cmd.get("agente", -1))
			return {"ok": a != null and cena.pagar_na_trilha_certa(a)}
		"deduzir":
			var r := cena.deduzir(String(cmd.get("pergunta", "")), String(cmd.get("candidato", "")))
			return {"ok": r.get("ok", false), "deducao": r}
		"sair":
			if not cena.encerrada:
				return {"ok": false, "erro": "a cena ainda não acabou"}
			return {"ok": true, "resultado": cena.resultado()}
	return {"ok": false, "erro": "ação de investigação desconhecida: %s" % cmd.get("acao", "")}


static func indice_na_cena(cena: CenaInvestigacao, a: Agente) -> int:
	return cena.agentes.find(a)


static func _agente_da_cena(cena: CenaInvestigacao, i) -> Agente:
	var k := int(i)
	return cena.agentes[k] if k >= 0 and k < cena.agentes.size() else null


static func _opcoes(cmd: Dictionary) -> Dictionary:
	var op = cmd.get("opcoes", {})
	return op.duplicate(true) if op is Dictionary else {}


# --- Combate ----------------------------------------------------------------------------

static func ref(c: Combate, s: Ser) -> int:
	return c.participantes.find(s) if s != null else -1


static func ser(c: Combate, i) -> Ser:
	if i == null:
		return null
	var k := int(i)
	return c.participantes[k] if k >= 0 and k < c.participantes.size() else null


## Aplica uma decisão do ser da vez (`ator`): de um agente ou, com mestre, de uma ameaça.
## "encerrar_turno", "ia" e "sair" pedem a quem chama (arena, testes, rede) que avance os
## turnos com o FluxoCombate ou troque de cena; "ia" antes joga o turno inteiro pela IA.
static func aplicar_combate(c: Combate, armas: Dictionary, cmd: Dictionary) -> Dictionary:
	var acao := String(cmd.get("acao", ""))
	if acao == "sair":
		return {"ok": c.encerrado, "vencedor": c.lado_vencedor() if c.encerrado else ""}
	var ator := ser(c, cmd.get("ator", -1))
	if ator == null or ator != c.ser_atual() or c.encerrado:
		return {"ok": false, "erro": "não é a vez desse ser"}
	match acao:
		"encerrar_turno":
			return {"ok": true}
		"mover":
			return {"ok": c.mover(ator, de_vetor(cmd.celula))}
		"agredir":
			var alvo := ser(c, cmd.get("alvo", -1))
			if alvo == null:
				return {"ok": false, "erro": "alvo inválido"}
			var arma: Dictionary = armas.get(ator, c.ruleset.arma("desarmado"))
			if ator is Ameaca and cmd.has("arma"):
				var k := int(cmd.arma)
				if k >= 0 and k < (ator as Ameaca).ataques.size():
					arma = (ator as Ameaca).ataques[k]
			var r := c.agredir(ator, alvo, arma, int(cmd.get("foco", 0)), _opcoes(cmd))
			return {"ok": r.teste != null, "ataque": r}
		"ia":
			IaCombate.jogar(c, ator, armas)
			return {"ok": true}
		"habilidade":
			if not ator is Ameaca:
				return {"ok": false, "erro": "só ameaças usam habilidades da ficha"}
			var celula = de_vetor(cmd.celula) if cmd.get("celula") is Array else null
			return c.usar_habilidade(ator as Ameaca, String(cmd.get("habilidade", "")), ser(c, cmd.get("alvo", -1)), celula)
		"conjurar":
			if ator is Ameaca:
				var alvo_r := ser(c, cmd.get("alvo", -1))
				if alvo_r == null:
					return {"ok": false, "erro": "alvo inválido"}
				return c.conjurar_ameaca(ator as Ameaca, String(cmd.ritual), alvo_r, _opcoes(cmd))
			if not ator is Agente:
				return {"ok": false, "erro": "esse ser não conjura"}
			var op := _opcoes(cmd)
			if op.has("celula"):
				op.celula = de_vetor(op.celula)
			if op.has("alvos"):
				var alvos: Array = []
				for i in op.alvos:
					if ser(c, i) != null:
						alvos.append(ser(c, i))
				op.alvos = alvos
			return c.conjurar(ator as Agente, String(cmd.ritual), ser(c, cmd.get("alvo", -1)), String(cmd.get("forma", "")), op)
		"granada":
			if not ator is Agente:
				return {"ok": false, "erro": "só agentes usam granadas"}
			return c.usar_granada(ator as Agente, String(cmd.item), de_vetor(cmd.celula))
		"contra":
			var alvo := ser(c, cmd.get("alvo", -1))
			if not ator is Agente or not alvo is Ameaca:
				return {"ok": false, "erro": "alvo inválido"}
			return {"ok": c.usar_contra(ator as Agente, alvo as Ameaca, String(cmd.item))}
		"item":
			var alvo := ser(c, cmd.get("alvo", -1))
			if not ator is Agente or alvo == null:
				return {"ok": false, "erro": "alvo inválido"}
			var cura := c.usar_item(ator as Agente, String(cmd.item), alvo)
			return {"ok": cura >= 0, "cura": cura, "alvo": alvo}
		"decifrar":
			var criatura := ser(c, cmd.get("alvo", -1))
			if not ator is Agente or not criatura is Ameaca:
				return {"ok": false, "erro": "alvo inválido"}
			var t := c.decifrar_enigma(ator as Agente, criatura as Ameaca, String(cmd.get("pericia", "")))
			return {"ok": t != null, "teste": t}
		"apagar":
			return {"ok": c.apagar_chamas(ator)}
		"manobra":
			var alvo_m := ser(c, cmd.get("alvo", -1))
			if alvo_m == null:
				return {"ok": false, "erro": "alvo inválido"}
			return c.manobra(ator, alvo_m, String(cmd.get("tipo", "")))
		"levantar":
			return {"ok": c.levantar(ator)}
		"pegar_arma":
			return {"ok": c.pegar_arma(ator)}
		"socorrer", "acalmar":
			var aliado := ser(c, cmd.get("alvo", -1))
			if not ator is Agente or aliado == null:
				return {"ok": false, "erro": "alvo inválido"}
			var t := c.primeiros_socorros(ator as Agente, aliado) if acao == "socorrer" else c.acalmar(ator as Agente, aliado, String(cmd.get("pericia", "diplomacia")))
			return {"ok": t != null, "teste": t, "alvo": aliado}
		"soltar":
			return {"ok": c.escapar(ator)}
	return {"ok": false, "erro": "ação de combate desconhecida: %s" % acao}


# --- Mestre (Fase 8.3) ------------------------------------------------------------------

## Comando do mestre na missão. O texto narrado perde os colchetes (nada de BBCode alheio).
static func aplicar_mestre(m: Missao, cmd: Dictionary) -> Dictionary:
	match String(cmd.get("acao", "")):
		"narrar":
			var t := String(cmd.get("texto", "")).replace("[", "(").replace("]", ")").strip_edges().substr(0, 400)
			if t == "":
				return {"ok": false, "erro": "nada para narrar"}
			m._log("[color=#f2c6a0][b]Mestre:[/b] %s[/color]" % t)
			return {"ok": true, "texto": t}
		"membrana":
			var v := clampi(int(cmd.get("valor", 0)), -50, 50)
			if v == 0:
				return {"ok": false, "erro": "valor zero"}
			m.membrana.alterar(v, "mestre")
			m._log("[color=#b98ae6]O mestre %s a Membrana (%+d).[/color]" % ["fortalece" if v > 0 else "enfraquece", v])
			return {"ok": true}
		"revelar":
			var h := de_vetor(cmd.hex)
			if not m.mapa.tem(h):
				return {"ok": false, "erro": "hex fora do mapa"}
			m.mapa.revelar(h, clampi(int(cmd.get("raio", 1)), 0, 10))
			return {"ok": true}
		"encontro", "evento":
			var h := de_vetor(cmd.hex)
			if not _hex_livre(m, h):
				return {"ok": false, "erro": "o hex precisa estar livre"}
			var id := String(cmd.get("id", ""))
			if cmd.acao == "encontro":
				if m._encontro(id).is_empty():
					return {"ok": false, "erro": "encontro desconhecido"}
				m.mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": id})
			else:
				if m._evento(id).is_empty():
					return {"ok": false, "erro": "evento desconhecido"}
				m.mapa.definir_conteudo(h, {"tipo": "evento", "evento": id})
			return {"ok": true}
		"limpar":
			var h := de_vetor(cmd.hex)
			if not m.mapa.tem(h) or String(m.mapa.conteudo(h).get("tipo", "")) in ["inicio", "objetivo"]:
				return {"ok": false, "erro": "esse hex não pode ser limpo"}
			m.mapa.limpar_conteudo(h)
			return {"ok": true}
		"curar", "ferir", "sanidade":
			var a: Agente = null
			for ag in m.agentes:
				if ag.id == String(cmd.get("agente", "")):
					a = ag
			var v := int(cmd.get("valor", 0))
			if a == null or v == 0 or a.tem(Ser.MORTO):
				return {"ok": false, "erro": "agente ou valor inválido"}
			v = clampi(v, -100, 100)
			match String(cmd.acao):
				"curar":
					a.curar(absi(v))
					m._log("[color=#f2c6a0]O mestre: %s recupera %d PV.[/color]" % [a.nome, absi(v)])
				"ferir":
					a.sofrer_dano(absi(v))
					m._log("[color=#f2c6a0]O mestre: %s sofre %d de dano.[/color]" % [a.nome, absi(v)])
				"sanidade":
					if v > 0:
						a.recuperar_sanidade(v)
					else:
						a.perder_sanidade(-v)
					m._log("[color=#f2c6a0]O mestre: %s %s %d de Sanidade.[/color]" % [a.nome, "recupera" if v > 0 else "perde", absi(v)])
			m._verificar_derrota()
			return {"ok": true}
	return {"ok": false, "erro": "ação de mestre desconhecida: %s" % cmd.get("acao", "")}


static func _hex_livre(m: Missao, h: Vector2i) -> bool:
	if not m.mapa.tem(h) or not m.mapa.passavel(h) or not m.mapa.conteudo(h).is_empty():
		return false
	for a in m.agentes:
		if m.posicao(a) == h:
			return false
	return true


# --- Checksum -------------------------------------------------------------------------

## Hash do estado da missão e dos agentes. Números inteiros guardados como float (depois de
## passar por JSON) contam igual, e as chaves vão ordenadas: o hash do host e o de um cliente
## que carregou o checkpoint batem quando o jogo está igual.
static func hash_missao(m: Missao) -> int:
	var d := {"missao": m.para_dicionario(), "agentes": m.agentes_iniciais.map(func(a): return a.para_dicionario())}
	return JSON.stringify(_normalizar(d), "", true).hash()


static func hash_combate(c: Combate) -> int:
	var seres: Array = []
	for s in c.participantes:
		var linha := [s.nome, s.lado, s.pv, s.condicoes.keys()]
		if s is Agente:
			linha.append_array([(s as Agente).pe, (s as Agente).san])
		if c.grade != null and c.grade.tem(s):
			linha.append(vetor(c.grade.posicao(s)))
		seres.append(linha)
	var d := {"rodada": c.rodada, "vez": ref(c, c.ser_atual()), "encerrado": c.encerrado, "rng": str(c.dados.estado()), "seres": seres}
	return JSON.stringify(_normalizar(d), "", true).hash()


static func hash_investigacao(cena: CenaInvestigacao) -> int:
	var d := {"rodada": cena.rodada, "indice": cena.indice, "falhas": cena.falhas, "encerrada": cena.encerrada,
		"pontos": cena.pontos_restantes.duplicate(), "pistas": cena.pistas_encontradas.size(),
		"agentes": cena.agentes.map(func(a): return [a.pv, a.pe, a.san]), "rng": str(cena.dados.estado())}
	return JSON.stringify(_normalizar(d), "", true).hash()


static func _normalizar(v):
	if v is float and v == floorf(v) and absf(v) < 1e15:
		return int(v)
	if v is Dictionary:
		var d := {}
		for k in v:
			d[str(k)] = _normalizar(v[k])
		return d
	if v is Array:
		return v.map(func(x): return Comandos._normalizar(x))
	return v
