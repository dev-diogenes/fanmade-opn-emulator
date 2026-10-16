class_name Comandos
extends RefCounted
## Comandos (Fase 8, ADR 0007): cada decisão de jogador é um dicionário que vira JSON sem
## perda, e aplicar o mesmo comando ao mesmo estado dá o mesmo resultado em qualquer máquina
## (toda rolagem sai de `Dados`, com seed). Seres do combate entram pelo índice em
## `participantes`; agentes da investigação, pelo índice na cena; hexes e células, como [x, y].
## Números chegam da rede como float: tudo passa por int() aqui.

const ACOES_MAPA := ["rolar_movimento", "mover", "descansar", "encerrar_turno", "resolver_evento"]
const ACOES_INVESTIGACAO := ["procurar", "facilitar", "ajudar", "passar", "encerrar", "acao_extra", "trilha_certa", "sair"]
const ACOES_COMBATE := ["mover", "agredir", "conjurar", "granada", "contra", "item", "decifrar", "apagar", "soltar", "encerrar_turno", "sair"]


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
			return {"ok": true, "teste": m.resolver_evento(int(cmd.get("foco", 0)))}
	return {"ok": false, "erro": "ação de mapa desconhecida: %s" % cmd.get("acao", "")}


# --- Investigação -----------------------------------------------------------------------

static func aplicar_investigacao(cena: CenaInvestigacao, cmd: Dictionary) -> Dictionary:
	match String(cmd.get("acao", "")):
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


## Aplica uma decisão do ser da vez (`ator`). "encerrar_turno" e "sair" não mexem no combate:
## quem chama (arena, testes, rede) avança os turnos com o FluxoCombate ou troca de cena.
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
			var r := c.agredir(ator, alvo, armas.get(ator, c.ruleset.arma("desarmado")), int(cmd.get("foco", 0)), _opcoes(cmd))
			return {"ok": r.teste != null, "ataque": r}
		"conjurar":
			if not ator is Agente:
				return {"ok": false, "erro": "só agentes conjuram por comando"}
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
		"soltar":
			return {"ok": c.escapar(ator)}
	return {"ok": false, "erro": "ação de combate desconhecida: %s" % acao}


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
