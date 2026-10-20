class_name Missao
extends RefCounted
## Estado e regras de uma missão no mapa-múndi (estilo For The King):
## cada agente joga seu turno (rola movimento em slots de d20, anda, resolve o que
## encontra); depois o mundo age (Membrana enfraquece, ameaças surgem).
## A cena do mapa só exibe e chama estes métodos; o combate acontece na arena.

signal registro(texto: String)
signal evento_aberto(hex: Vector2i, evento: Dictionary, agente: Agente)
signal encontro_iniciado(config: Dictionary)
signal investigacao_iniciada(config: Dictionary)
signal turno_mudou(agente: Agente)
signal missao_encerrada(vitoria: bool)

var ruleset: Ruleset
var dados: Dados
var mapa: MapaHex
var membrana: Membrana
var agentes: Array[Agente] = []
var armas: Dictionary = {}       ## Agente -> arma (Dictionary)
var posicoes: Dictionary = {}    ## Agente -> Vector2i
var turno_mundo := 1
var indice := 0
var movimento_restante := 0
var movimento_rolado := false
## Ação do turno no mapa (docs/13): usar um item ou conjurar um ritual que não seja de ataque.
var acao_usada := false
var ultimo_movimento: Dictionary = {}   ## {"slots": [...], "dt": int, "sucessos": int, "total": int}
var evento_pendente: Dictionary = {}    ## {"hex", "evento", "agente"}
var encontro_pendente: Dictionary = {}  ## config para a arena
var investigacao_pendente: Dictionary = {}  ## {"hex", "cena", "agentes"} para a cena de investigação
var caso: Caso
## Modificador de PV do chefe pelas investigações (+0.2 fortalecido, −0.2 enfraquecido)
var modificador_chefe := 0.0
var encerrada := false
var vitoria := false
## Opções da run (Carreira): modo_morte, lesoes, inspiracao_resoluta
var opcoes: Dictionary = {"modo_morte": "normal", "lesoes": true, "inspiracao_resoluta": true}
var semente := 0
var agentes_iniciais: Array[Agente] = []
var reforcos := 0                        ## Reforços da Ordem restantes (modo Normal)
var pistas := 0                          ## Eventos resolvidos com sucesso (pistas adicionais, p.63)
var mortos: Array[Agente] = []
var resgatados: Array[Agente] = []

## Todas as linhas do registro (a cena do mapa é recriada após cada combate)
var historico: Array[String] = []
## Missão da comunidade (Fase 6): conteúdo próprio que vem antes dos dados do jogo.
## {"id", "titulo", "encontros": [], "eventos": [], "ameacas": {}, "covil": {}, "surgimentos": "padrao"}
var extras: Dictionary = {}

var _cfg: Dictionary
var _descansou: Dictionary = {}          ## Agente -> hex onde já descansou nesta visita
var _turnos_sem_surgimento := 0


## Nova missão. `grupo`: agentes da carreira (vazio = grupo padrão de demonstração).
static func nova(semente_: int, ruleset_: Ruleset = null, grupo: Array = [], opcoes_: Dictionary = {}) -> Missao:
	var m := Missao.new()
	m.ruleset = ruleset_ if ruleset_ != null else RulesetOp2022.carregar_padrao()
	m.semente = semente_
	m.dados = Dados.new(semente_)
	m._cfg = DadosJogo.ler("mapa")
	m.mapa = GeradorMapa.gerar(semente_)
	m.membrana = Membrana.carregar_padrao()
	for k in opcoes_:
		m.opcoes[k] = opcoes_[k]
	m.reforcos = 2 if m.opcoes.get("modo_morte", "normal") == "normal" else 0
	m.caso = Caso.gerar(m.dados)
	var inicio := m.mapa.encontrar("inicio")
	if grupo.is_empty():
		for ficha in DadosJogo.ler("grupo_inicial").agentes:
			var r := CriacaoAgente.criar(m.ruleset, ficha)
			assert(r.agente != null, "Ficha inicial inválida: %s" % [r.erros])
			var novo: Agente = r.agente
			for item in ficha.get("equipamento", [ficha.arma]):
				novo.equipamento.append(item)
			novo.arma_id = ficha.arma
			grupo.append(novo)
	for a in grupo:
		m.agentes.append(a)
		m.agentes_iniciais.append(a)
		m.armas[a] = a.arma()
		m.posicoes[a] = inicio
	m._iniciar_turno_do_agente()
	return m


func _log(texto: String) -> void:
	historico.append(texto)
	registro.emit(texto)


# --- Turno dos agentes -----------------------------------------------------

func agente_atual() -> Agente:
	if encerrada or agentes.is_empty():
		return null
	return agentes[indice]


func posicao(a: Agente) -> Vector2i:
	return posicoes.get(a, Vector2i(-999, -999))


func agentes_em(h: Vector2i) -> Array[Agente]:
	var lista: Array[Agente] = []
	for a in agentes:
		if posicoes.get(a) == h and not a.tem(Ser.MORTO):
			lista.append(a)
	return lista


func ocupado() -> bool:
	return not evento_pendente.is_empty() or not encontro_pendente.is_empty() or not investigacao_pendente.is_empty() or encerrada


## Rola o movimento do agente da vez: 1 d20 por ponto de Agilidade (mínimo 1) + 1 por PE de Foco.
## Cada slot >= DT vale 1 ponto, somado à base (mapa.json). Uma vez por turno.
func rolar_movimento(pe_foco: int = 0) -> Dictionary:
	var a := agente_atual()
	if a == null or movimento_rolado or ocupado():
		return {}
	if pe_foco > 0 and not a.gastar_pe(pe_foco):
		return {}
	var regra: Dictionary = _cfg.movimento
	var qtd := maxi(1, a.atributo(regra.atributo)) + int(regra.get("slots_extras", 0)) + pe_foco
	var dt := int(regra.dt_slot)
	var slots := dados.rolar_varios(qtd, 20)
	var sucessos := slots.filter(func(v): return v >= dt).size()
	movimento_restante = int(regra.base) + sucessos
	movimento_rolado = true
	ultimo_movimento = {"slots": slots, "dt": dt, "sucessos": sucessos, "total": movimento_restante, "agente": a.nome}
	ultimo_movimento["atributo"] = String(regra.atributo)
	_log("%s rola movimento: %s (DT %d) → %d de movimento" % [a.nome, str(slots), dt, movimento_restante])
	return ultimo_movimento


## Custos dos hexes ao alcance do movimento restante.
func destinos() -> Dictionary:
	var a := agente_atual()
	if a == null or not movimento_rolado or ocupado():
		return {}
	var custos := mapa.alcancaveis(posicao(a), movimento_restante)
	custos.erase(posicao(a))
	return custos


## Anda até `destino` pelo caminho mais barato. Para ao entrar num hex com conteúdo.
func mover(destino: Vector2i) -> bool:
	var a := agente_atual()
	if a == null or not destinos().has(destino):
		return false
	var passos := mapa.caminho(posicao(a), destino, true)
	if passos.is_empty() or mapa.custo_do_caminho(passos) > movimento_restante:
		return false
	_descansou.erase(a)
	for h in passos:
		movimento_restante -= mapa.custo(h)
		posicoes[a] = h
		mapa.revelar(h, int(_cfg.visao))
		if not mapa.conteudo(h).is_empty():
			_entrar(a, h)
			break
	return true


func _entrar(a: Agente, h: Vector2i) -> void:
	var c := mapa.conteudo(h)
	match c.get("tipo", ""):
		"encontro":
			_preparar_encontro(h, c.encontro, false)
		"objetivo":
			_preparar_encontro(h, c.encontro, true)
		"evento":
			var ev := _evento(c.evento)
			evento_pendente = {"hex": h, "evento": ev, "agente": a}
			_log("[b]%s[/b]: %s" % [ev.titulo, ev.texto])
			evento_aberto.emit(h, ev, a)
		"investigacao":
			_preparar_investigacao(h, c.cena)
		"vila", "inicio":
			_log("%s chega a %s. Dá para descansar aqui." % [a.nome, c.get("nome", "uma cidade")])


func pode_descansar() -> bool:
	var a := agente_atual()
	if a == null or ocupado():
		return false
	var tipo: String = mapa.conteudo(posicao(a)).get("tipo", "")
	return tipo in ["vila", "inicio"] and not _descansou.has(a)


## Descanso numa cidade: recupera uma fração dos máximos e encerra o movimento do turno.
func descansar() -> bool:
	if not pode_descansar():
		return false
	var a := agente_atual()
	var f := float(_cfg.descanso.fracao)
	a.curar(maxi(1, int(a.pv_maximo * f)))
	a.recuperar_pe(maxi(1, int(a.pe_maximo * f)))
	a.recuperar_sanidade(maxi(1, int(a.san_maximo * f)))
	_descansou[a] = posicao(a)
	movimento_restante = 0
	movimento_rolado = true
	_log("%s descansa (PV %d/%d, PE %d/%d, SAN %d/%d)." % [a.nome, a.pv, a.pv_maximo, a.pe, a.pe_maximo, a.san, a.san_maximo])
	return true


func encerrar_turno() -> void:
	if ocupado():
		return
	for _i in agentes.size():
		indice += 1
		if indice >= agentes.size():
			indice = 0
			_turno_do_mundo()
		if not agentes[indice].esta_fora_de_combate():
			break
	_iniciar_turno_do_agente()


func _iniciar_turno_do_agente() -> void:
	movimento_restante = 0
	movimento_rolado = false
	acao_usada = false
	ultimo_movimento = {}
	var a := agente_atual()
	if a != null:
		a.iniciar_turno()   # zera o PE do turno e conta "enlouquecendo" também no mapa
		turno_mudou.emit(a)


# --- Eventos ---------------------------------------------------------------

func _evento(evento_id: String) -> Dictionary:
	for e in extras.get("eventos", []):
		if e.id == evento_id:
			return e
	var d := DadosJogo.ler("eventos")
	for e in d.eventos + d.get("eventos_medo", []):
		if e.id == evento_id:
			return e
	return {}


## Opções do evento (docs/13): cada uma é um teste de perícia diferente, ou "sem_teste".
## Eventos antigos (só "pericia" e "dt") viram uma opção única. Opções com "treinada"
## só aparecem para quem é treinado na perícia; com "habilidade", para quem a tem.
func opcoes_do_evento(ev: Dictionary = {}, a: Agente = null) -> Array:
	if ev.is_empty() and not evento_pendente.is_empty():
		ev = evento_pendente.evento
		a = evento_pendente.agente
	var lista: Array = ev.get("opcoes", [])
	if lista.is_empty():
		lista = [{"texto": "", "pericia": ev.get("pericia", ""), "dt": ev.get("dt", 10), "sucesso": ev.get("sucesso", {}), "falha": ev.get("falha", {})}]
	return lista.filter(func(o):
		if a == null:
			return true
		if o.get("treinada", false) and not a.pericias.has(String(o.get("pericia", ""))):
			return false
		if o.has("habilidade") and not a.tem_habilidade(String(o.habilidade)):
			return false
		return true)


## O agente que entrou no hex escolhe uma opção e faz o teste. Retorna {teste, sucesso, texto}.
func resolver_evento(pe_foco: int = 0, opcao: int = 0) -> Dictionary:
	if evento_pendente.is_empty():
		return {}
	var a: Agente = evento_pendente.agente
	var opcoes := opcoes_do_evento()
	var o: Dictionary = opcoes[clampi(opcao, 0, opcoes.size() - 1)]
	var teste: ResultadoTeste = null
	var sucesso := true
	var linha := ""
	if o.get("sem_teste", false):
		linha = "%s: %s" % [a.nome, String(o.get("texto", "segue em frente"))]
	else:
		teste = a.testar(dados, String(o.pericia), int(o.dt), pe_foco)
		sucesso = teste != null and teste.sucesso
		linha = "%s testa %s (DT %d): %s" % [a.nome, ruleset.pericia(o.pericia).nome, int(o.dt),
			teste.descrever() if teste != null else "sem treino — falha automática"]
	var lado: Dictionary = o.get("sucesso", {}) if sucesso else o.get("falha", {})
	if sucesso and not o.get("sem_teste", false):
		pistas += 1
	_log(linha)
	if String(lado.get("texto", "")) != "":
		_log(lado.texto)
	for ef in lado.get("efeitos", []):
		_aplicar_efeito(a, ef, evento_pendente.hex)
	mapa.limpar_conteudo(evento_pendente.hex)
	evento_pendente = {}
	_verificar_derrota()
	return {"teste": teste, "sucesso": sucesso, "texto": lado.get("texto", "")}


# --- Ação do turno no mapa (docs/13) ------------------------------------------------

## Agentes que o agente da vez alcança fora de combate: ele mesmo e quem está no mesmo hex.
func alcance_de_toque() -> Array:
	var a := agente_atual()
	if a == null:
		return []
	return agentes.filter(func(x): return posicao(x) == posicao(a) and not x.tem(Ser.MORTO))


## Itens que dá para usar fora de combate (consumíveis com "uso" de cura).
func itens_fora_de_combate(a: Agente) -> Array:
	var vistos := {}
	var lista: Array = []
	for item_id in a.equipamento:
		var info := ruleset.equipamento(item_id)
		if vistos.has(item_id) or not info.has("uso") or String(info.uso.get("cura", "")) == "":
			continue
		vistos[item_id] = true
		lista.append(item_id)
	return lista


## Rituais que dá para conjurar fora de combate: só os de cura e PV temporários,
## sem área e com alvo em você ou por toque. Devolve [[ritual_id, forma], …].
func rituais_fora_de_combate(a: Agente) -> Array:
	var lista: Array = []
	for rid in a.rituais:
		var r := ruleset.ritual(rid)
		if not r.get("implementado", false):
			continue
		for forma in [""] + r.get("formas", {}).keys():
			if _efeito_fora(r, forma).is_empty():
				continue
			if forma != "":
				var f: Dictionary = r.formas[forma]
				if int(f.get("circulo", 1)) > a.circulo_maximo() or (f.get("afinidade", false) and a.afinidade != r.elemento):
					continue
			lista.append([rid, forma])
	return lista


func _efeito_fora(r: Dictionary, forma: String) -> Dictionary:
	var efeitos: Array = r.get("efeitos", [])
	if efeitos.size() != 1:
		return {}
	var ef: Dictionary = efeitos[0].duplicate()
	if forma != "":
		var f: Dictionary = r.formas[forma]
		if f.has("area") or f.has("tipo"):
			return {}
		if f.has("dados"):
			ef["dados"] = f.dados
	if not String(ef.get("tipo", "")) in ["cura", "pv_temporario"]:
		return {}
	return ef


func pode_agir_no_mapa() -> bool:
	var a := agente_atual()
	return a != null and not acao_usada and not ocupado() and not a.esta_fora_de_combate()


func usar_item_no_mapa(item_id: String, alvo: Agente) -> Dictionary:
	var a := agente_atual()
	if not pode_agir_no_mapa() or not item_id in itens_fora_de_combate(a) or not alvo in alcance_de_toque():
		return {}
	var info := ruleset.equipamento(item_id)
	a.consumir_item(item_id)
	var cura := dados.rolar_expressao(String(info.uso.get("cura", "0")))
	alvo.curar(cura)
	acao_usada = true
	_log("%s usa %s em %s: +%d PV." % [a.nome, info.nome, alvo.nome, cura])
	return {"cura": cura, "alvo": alvo}


func conjurar_no_mapa(ritual_id: String, forma: String, alvo: Agente) -> Dictionary:
	var a := agente_atual()
	if not pode_agir_no_mapa() or not [ritual_id, forma] in rituais_fora_de_combate(a):
		return {}
	var r := ruleset.ritual(ritual_id)
	var pessoal := String(r.get("alcance", "")).begins_with("pessoal")
	if (pessoal and alvo != a) or not alvo in alcance_de_toque():
		return {}
	var custo := a.custo_ritual(ritual_id, forma)
	if not a.gastar_pe(custo):
		return {}
	var ef := _efeito_fora(r, forma)
	var valor := dados.rolar_expressao(String(ef.get("dados", "0")))
	if ef.tipo == "cura":
		alvo.curar(valor)
	else:
		alvo.pv_temporario = maxi(alvo.pv_temporario, valor)
	acao_usada = true
	_log("[color=#b98ae6]%s conjura %s%s em %s (%d PE): %s %d.[/color]" % [a.nome, r.nome, "" if forma == "" else " " + forma, alvo.nome, custo,
		"+PV" if ef.tipo == "cura" else "PV temporários", valor])
	return {"valor": valor, "tipo": ef.tipo, "alvo": alvo}


func _valor(v) -> int:
	return dados.rolar_expressao(v) if v is String else int(v)


func _aplicar_efeito(a: Agente, ef: Dictionary, h: Vector2i) -> void:
	match ef.tipo:
		"dano":
			var d := _valor(ef.valor)
			a.sofrer_dano(d)
			_log("%s sofre %d de dano." % [a.nome, d])
		"dano_mental":
			var d := _valor(ef.valor)
			a.sofrer_dano_mental(d)
			_log("%s perde %d de Sanidade." % [a.nome, d])
		"cura":
			a.curar(_valor(ef.valor))
		"recupera_pe":
			a.recuperar_pe(_valor(ef.valor))
		"recupera_san":
			a.recuperar_sanidade(_valor(ef.valor))
		"membrana":
			membrana.alterar(_valor(ef.valor), "evento")
		"revelar_raio":
			mapa.revelar(h, _valor(ef.valor))
		"revelar_objetivo":
			var obj := mapa.encontrar("objetivo")
			mapa.revelar(obj, 1)
			_log("O objetivo foi revelado no mapa.")


# --- Encontros -------------------------------------------------------------

## Monta a configuração do combate: agentes no hex + aliados até 1 hex de distância (FTK).
## `semente_salva`: ao carregar um save, o encontro volta com a mesma seed e sem novo registro.
func _preparar_encontro(h: Vector2i, encontro_id: String, chefe: bool, semente_salva: int = -1) -> void:
	var participantes: Array[Agente] = []
	var alcance := int(_cfg.aliados_entram_no_combate_ate)
	for a in agentes:
		if not a.tem(Ser.MORTO) and not a.esta_fora_de_combate() and Hex.distancia(posicao(a), h) <= alcance:
			participantes.append(a)
	var info: Dictionary = (extras.covil if not extras.get("covil", {}).is_empty() else covil_para(participantes)) if chefe else _encontro(encontro_id)
	var ameacas: Array = []
	for amea_id in info.ameacas:
		var am := ameaca_info(amea_id)
		if chefe and amea_id == info.ameacas[0]:
			am.chefe = true   # a primeira ameaça do covil é o chefe
		if chefe and am.chefe and modificador_chefe != 0.0:
			am.ficha = am.ficha.duplicate(true)
			am.ficha.pv = maxi(1, roundi(float(am.ficha.pv) * (1.0 + modificador_chefe)))
			if caso != null and caso.pergunta("quem").get("respondida", false):
				am.nome = caso.sujeito.get("chefe_titulo", am.nome)
		ameacas.append(am)
	# Balanceamento (p.187): fora do covil, a soma do VD das ameaças não passa da soma do NEX
	# de quem entra no combate (× dificuldade); sempre sobra ao menos a mais fraca.
	if not participantes.is_empty():
		var orcamento := 0
		for a in participantes:
			orcamento += a.nex
		if not chefe:
			ameacas = escolher_por_vd(ameacas, int(orcamento * float(_cfg.get("dificuldade_encontro", 1.0))))
		elif not ameacas.is_empty():
			# Covil: o chefe sempre está lá; a escolta cabe no que sobra do orçamento difícil (× 1,5)
			var chefe_am: Dictionary = ameacas[0]
			var sobra := int(orcamento * float(_cfg.get("dificuldade_covil", 1.5))) - int(chefe_am.get("vd", 0))
			ameacas = [chefe_am] + escolher_por_vd(ameacas.slice(1), sobra, false)
	encontro_pendente = {
		"hex": h, "nome": info.nome, "chefe": chefe, "terreno": mapa.terreno(h),
		"agentes": participantes, "armas": armas, "ameacas": ameacas, "encontro": encontro_id,
		"regras": {"lesoes": opcoes.get("lesoes", true), "inspiracao_resoluta": opcoes.get("inspiracao_resoluta", true),
			"presenca_perturbadora": true, "bonus_enigma": mini(10, pistas * 2), "perguntas_respondidas": _perguntas_respondidas()},
		"nivel_membrana": membrana.nivel_ameaca(), "semente": semente_salva if semente_salva >= 0 else dados.rolar(1000000),
		"mestre": bool(opcoes.get("mestre", false)),
	}
	if semente_salva < 0:
		_log("[color=#e0574a][b]Encontro: %s![/b][/color] (%d agente(s) entram no combate)" % [info.nome, participantes.size()])
	encontro_iniciado.emit(encontro_pendente)


## O covil muda com o grupo: o de maior "nex_minimo" que a soma do NEX alcança.
static func covil_para(grupo: Array) -> Dictionary:
	var d := DadosJogo.ler("encontros")
	var nex_total := 0
	for a in grupo:
		nex_total += a.nex
	var melhor: Dictionary = d.chefe
	for c in d.get("chefes", []):
		if nex_total >= int(c.nex_minimo) and int(c.nex_minimo) >= int(melhor.get("nex_minimo", 0)):
			melhor = c
	return melhor


## Escolhe ameaças da lista, da mais forte para a mais fraca, sem passar do orçamento de VD.
static func escolher_por_vd(lista: Array, orcamento: int, ao_menos_uma: bool = true) -> Array:
	var ordenadas := lista.duplicate()
	ordenadas.sort_custom(func(a, b): return int(a.get("vd", 0)) > int(b.get("vd", 0)))
	var escolhidas: Array = []
	var total := 0
	for am in ordenadas:
		if total + int(am.get("vd", 0)) <= orcamento:
			escolhidas.append(am)
			total += int(am.get("vd", 0))
	if escolhidas.is_empty() and not ordenadas.is_empty() and ao_menos_uma:
		escolhidas.append(ordenadas[-1])
	return escolhidas


## Encontros que podem surgir: nível até o da Membrana e cuja ameaça mais fraca tenha VD de até
## o dobro do NEX somado do grupo (para uma Membrana fraca não trazer algo impossível).
func encontros_para_surgir(nivel: int, vivos: Array) -> Array:
	var nex_total := 0
	for a in vivos:
		nex_total += a.nex
	var modo := String(extras.get("surgimentos", "padrao"))
	if modo == "nenhum":
		return []
	var base: Array = extras.get("encontros", []) if modo == "proprios" else DadosJogo.ler("encontros").encontros
	var opcoes: Array = base.filter(func(e): return int(e.get("nivel", 0)) <= nivel and _vd_minimo(e) <= nex_total * 2)
	if opcoes.is_empty() and modo != "proprios":
		opcoes = base.filter(func(e): return int(e.get("nivel", 0)) == 0)
	return opcoes


## Ficha de uma ameaça: primeiro as próprias da missão, depois as do jogo e as do livro.
func ameaca_info(amea_id: String) -> Dictionary:
	if extras.get("ameacas", {}).has(amea_id):
		return DadosJogo.info_ameaca(ruleset, amea_id, extras.ameacas[amea_id])
	return DadosJogo.ameaca(ruleset, amea_id)


## VD da ameaça mais fraca de um encontro (o mínimo que o combate terá).
func _vd_minimo(e: Dictionary) -> int:
	var minimo := 1 << 20
	for id in e.ameacas:
		minimo = mini(minimo, int(ameaca_info(id).vd))
	return minimo


func _perguntas_respondidas() -> Array:
	var ids: Array = []
	if caso != null:
		for p in caso.respondidas():
			ids.append(p.id)
	return ids


func _encontro(encontro_id: String) -> Dictionary:
	for e in extras.get("encontros", []) + DadosJogo.ler("encontros").encontros:
		if e.id == encontro_id:
			return e
	return {}


## Chamado quando o combate termina. Vitória limpa o hex (e vence a missão no covil).
## Agentes caídos são socorridos com 1 PV ao fim de uma vitória (simplificação da fatia vertical).
func concluir_encontro(vencedor: String) -> void:
	if encontro_pendente.is_empty():
		return
	var h: Vector2i = encontro_pendente.hex
	var chefe: bool = encontro_pendente.chefe
	for a in encontro_pendente.agentes:
		a.encerrar_cena()
	var participantes: Array = encontro_pendente.agentes
	encontro_pendente = {}
	if vencedor == "agentes":
		for a in participantes:
			if a.tem(Ser.MORTO):
				_tratar_queda(a)
			elif a.pv == 0:
				a.estabilizar()
				a.curar(1)
				a.condicoes.erase(Ser.INCONSCIENTE)
				_log("%s é socorrido e volta com 1 PV." % a.nome)
		mapa.limpar_conteudo(h)
		_log("[color=#6fcf8e]Encontro vencido.[/color]")
		if chefe:
			_encerrar(true)
	else:
		_log("[color=#e0574a]Os agentes caíram.[/color]")
		for a in participantes:
			if a.esta_fora_de_combate() or a.tem(Ser.MORTO):
				_tratar_queda(a)
	_ajustar_indice()
	_verificar_derrota()


## Agente morto ou caído num combate perdido. Modo Normal: gasta um Reforço da Ordem e o
## agente é resgatado (sai da missão com uma lesão). Sem reforços, ou no Hardcore, morre.
func _tratar_queda(a: Agente) -> void:
	if a.tem(Ser.INSANO):
		agentes.erase(a)
		return
	if opcoes.get("modo_morte", "normal") == "normal" and reforcos > 0:
		reforcos -= 1
		agentes.erase(a)
		resgatados.append(a)
		a.condicoes.clear()
		a.pv = maxi(1, a.pv)
		var ordem := ["agi", "for", "int", "pre", "vig"]
		var d6 := dados.rolar(6)
		if d6 <= 5:
			var attr: String = ordem[d6 - 1]
			a.atributos[attr] = maxi(0, int(a.atributos.get(attr, 0)) - 1)
			a.lesoes.append(attr)
			a.recalcular_maximos()
			_log("[color=#eda64a]Reforços da Ordem resgatam %s (lesão: −1 %s). Reforços restantes: %d.[/color]" % [a.nome, attr.to_upper(), reforcos])
		else:
			_log("[color=#eda64a]Reforços da Ordem resgatam %s, sem sequelas. Reforços restantes: %d.[/color]" % [a.nome, reforcos])
	else:
		a.condicoes.clear()
		a.condicoes[Ser.MORTO] = true
		agentes.erase(a)
		mortos.append(a)
		_log("[color=#e0574a]%s morreu.[/color]" % a.nome)


func _ajustar_indice() -> void:
	if agentes.is_empty():
		indice = 0
		return
	if indice >= agentes.size():
		indice = 0
	_iniciar_turno_do_agente()


# --- Investigação ----------------------------------------------------------

func _preparar_investigacao(h: Vector2i, cena_id: String, semente_salva: int = -1) -> void:
	var participantes: Array[Agente] = []
	for a in agentes:
		if not a.esta_fora_de_combate() and Hex.distancia(posicao(a), h) <= int(_cfg.aliados_entram_no_combate_ate):
			participantes.append(a)
	investigacao_pendente = {"hex": h, "cena": cena_id, "agentes": participantes, "semente": semente_salva if semente_salva >= 0 else dados.rolar(1000000)}
	if semente_salva < 0:
		_log("[color=#7fd3c7][b]Investigação: %s![/b][/color] (%d agente(s) participam)" % [cena_info(cena_id).get("nome", ""), participantes.size()])
	investigacao_iniciada.emit(investigacao_pendente)


## Cena de investigação pelo id: primeiro as da própria missão, depois as do jogo.
func cena_info(cena_id: String) -> Dictionary:
	for cn in extras.get("cenas", []) + DadosJogo.ler("cenas_investigacao").cenas:
		if cn.id == cena_id:
			return cn
	return {}


## Cria a cena de investigação pendente (a cena da UI chama isto).
func criar_cena_investigacao() -> CenaInvestigacao:
	if investigacao_pendente.is_empty():
		return null
	var d := Dados.new(int(investigacao_pendente.get("semente", 1)))
	return CenaInvestigacao.nova(ruleset, d, caso, investigacao_pendente.cena, investigacao_pendente.agentes, "", membrana, extras.get("cenas", []))


## Aplica o resultado de uma cena de investigação: pistas (PP), perguntas respondidas e
## penalidades da urgência. O hex fica limpo (ou vira um encontro, se a penalidade mandar).
func concluir_investigacao(resultado: Dictionary) -> void:
	if investigacao_pendente.is_empty():
		return
	var h: Vector2i = investigacao_pendente.hex
	investigacao_pendente = {}
	mapa.limpar_conteudo(h)
	pistas += resultado.get("pistas", []).size()
	for p in resultado.get("perguntas", []):
		var ef: Dictionary = p.get("efeito", {})
		_log("[color=#e3c27a]%s[/color]" % ef.get("texto", ""))
		match ef.get("tipo", ""):
			"chefe_enfraquecido":
				modificador_chefe -= 0.2
			"membrana":
				membrana.alterar(int(ef.get("valor", 0)), "investigacao")
			"revelar_objetivo":
				var obj := mapa.encontrar("objetivo")
				mapa.revelar(obj, 1)
	var pen: Dictionary = resultado.get("penalidade", {})
	match pen.get("tipo", ""):
		"chefe_fortalecido":
			modificador_chefe += 0.2
		"encontro":
			mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": pen.get("encontro", "celula_cultista")})
	# "membrana" já foi aplicada pela própria cena (urgência estourada)
	_iniciar_turno_do_agente_sem_reset()
	_verificar_derrota()


## Volta ao mesmo agente depois da cena, sem zerar o movimento que ele tinha.
func _iniciar_turno_do_agente_sem_reset() -> void:
	var a := agente_atual()
	if a != null:
		turno_mudou.emit(a)


# --- Mundo -----------------------------------------------------------------

func _turno_do_mundo() -> void:
	turno_mundo += 1
	membrana.registrar("turno_mapa")
	_log("[color=#a69b88]— Turno %d do mundo — Membrana %d (%s)[/color]" % [turno_mundo, membrana.valor, membrana.estado().get("nome", "")])
	_turnos_sem_surgimento += 1
	if _turnos_sem_surgimento >= int(_cfg.mundo.surgimento_a_cada_turnos) and membrana.nivel_ameaca() >= 1:
		_turnos_sem_surgimento = 0
		_surgir_ameaca()
	_ataque_a_sanidade()


## Membrana Rompendo: o Outro Lado ataca a mente de todos (Vontade ou perde Sanidade).
func _ataque_a_sanidade() -> void:
	var cfg: Dictionary = DadosJogo.ler("membrana").get("medo", {}).get("ataque_sanidade", {})
	if cfg.is_empty() or membrana.nivel_ameaca() < int(cfg.nivel):
		return
	for a in agentes:
		if a.esta_fora_de_combate():
			continue
		var t := a.testar(dados, String(cfg.pericia), int(cfg.dt))
		if t == null or not t.sucesso:
			var antes := a.san
			a.sofrer_dano_mental(dados.rolar_expressao(String(cfg.dano)))
			_log("[color=#b98ae6]O Medo sussurra para %s: −%d de Sanidade.[/color]" % [a.nome, antes - a.san])
	_verificar_derrota()


## Uma nova ameaça surge perto de um agente vivo, com nível até o da Membrana.
func _surgir_ameaca() -> void:
	var vivos := agentes.filter(func(a): return not a.esta_fora_de_combate())
	if vivos.is_empty():
		return
	var alvo: Agente = vivos[dados.rolar(vivos.size()) - 1]
	var nivel := membrana.nivel_ameaca()
	var opcoes := encontros_para_surgir(nivel, vivos)
	var candidatos: Array[Vector2i] = []
	for h in Hex.area(posicao(alvo), 3):
		if Hex.distancia(h, posicao(alvo)) >= 2 and mapa.passavel(h) and mapa.conteudo(h).is_empty() and agentes_em(h).is_empty():
			candidatos.append(h)
	if candidatos.is_empty() or opcoes.is_empty():
		return
	var h := candidatos[dados.rolar(candidatos.size()) - 1]
	var medo: Dictionary = DadosJogo.ler("membrana").get("medo", {}).get("manifestacoes", {})
	var eventos_medo: Array = DadosJogo.ler("eventos").get("eventos_medo", [])
	if not medo.is_empty() and nivel >= int(medo.nivel) and not eventos_medo.is_empty() and dados.rolar(int(medo.chance_em)) == 1:
		var ev: Dictionary = eventos_medo[dados.rolar(eventos_medo.size()) - 1]
		mapa.definir_conteudo(h, {"tipo": "evento", "evento": ev.id})
		mapa.revelar(h, 0)
		_log("[color=#b98ae6]O Medo se manifesta perto de %s: %s.[/color]" % [alvo.nome, ev.titulo])
		return
	var e: Dictionary = opcoes[dados.rolar(opcoes.size()) - 1]
	mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": e.id})
	mapa.revelar(h, 0)
	_log("[color=#b98ae6]Com a Membrana %s, algo surge perto de %s: %s.[/color]" % [membrana.estado().nome.to_lower(), alvo.nome, e.nome])


func _verificar_derrota() -> void:
	if encerrada:
		return
	if agentes.is_empty() or agentes.all(func(a): return a.esta_fora_de_combate()):
		_encerrar(false)


func _encerrar(venceu: bool) -> void:
	if encerrada:
		return
	encerrada = true
	vitoria = venceu
	_log("[b]%s[/b]" % ("MISSÃO CUMPRIDA" if venceu else "MISSÃO FRACASSADA"))
	missao_encerrada.emit(venceu)


# --- Salvar / carregar ------------------------------------------------------

## Os agentes são referenciados pelo id (eles mesmos são salvos pela Carreira).
func para_dicionario() -> Dictionary:
	var pos: Dictionary = {}
	for a in posicoes:
		pos[a.id] = [posicoes[a].x, posicoes[a].y]
	var ev: Dictionary = {}
	if not evento_pendente.is_empty():
		ev = {"hex": [evento_pendente.hex.x, evento_pendente.hex.y], "evento": evento_pendente.evento.id, "agente": evento_pendente.agente.id}
	var enc: Dictionary = {}
	if not encontro_pendente.is_empty():
		enc = {"hex": [encontro_pendente.hex.x, encontro_pendente.hex.y], "encontro": encontro_pendente.encontro, "chefe": encontro_pendente.chefe,
			"semente": int(encontro_pendente.semente)}
	var descansos: Dictionary = {}
	for a in _descansou:
		descansos[a.id] = [_descansou[a].x, _descansou[a].y]
	return {
		"semente": semente, "rng": str(dados.estado()), "mapa": mapa.para_dicionario(), "membrana": membrana.para_dicionario(),
		"opcoes": opcoes.duplicate(), "agentes": agentes.map(func(a): return a.id),
		"agentes_iniciais": agentes_iniciais.map(func(a): return a.id),
		"mortos": mortos.map(func(a): return a.id), "resgatados": resgatados.map(func(a): return a.id),
		"posicoes": pos, "turno_mundo": turno_mundo, "indice": indice,
		"movimento_restante": movimento_restante, "movimento_rolado": movimento_rolado, "acao_usada": acao_usada,
		"evento_pendente": ev, "encontro_pendente": enc, "reforcos": reforcos, "pistas": pistas,
		"caso": caso.para_dicionario() if caso != null else {}, "modificador_chefe": modificador_chefe,
		"investigacao_pendente": {"hex": [investigacao_pendente.hex.x, investigacao_pendente.hex.y], "cena": investigacao_pendente.cena,
			"semente": int(investigacao_pendente.semente)} if not investigacao_pendente.is_empty() else {},
		"turnos_sem_surgimento": _turnos_sem_surgimento, "descansos": descansos,
		"historico": historico.slice(maxi(0, historico.size() - 300)),
		"encerrada": encerrada, "vitoria": vitoria, "extras": extras.duplicate(true),
	}


## `por_id`: {id: Agente} vindo da Carreira.
static func de_dicionario(ruleset_: Ruleset, d: Dictionary, por_id: Dictionary) -> Missao:
	var m := Missao.new()
	m.ruleset = ruleset_
	m._cfg = DadosJogo.ler("mapa")
	m.semente = int(d.get("semente", 0))
	m.extras = d.get("extras", {})
	m.dados = Dados.new(m.semente)
	m.dados.restaurar_estado(String(d.get("rng", "0")).to_int())
	m.mapa = MapaHex.new(m._cfg.terrenos)
	m.mapa.de_dicionario(d.mapa)
	m.membrana = Membrana.carregar_padrao()
	m.membrana.de_dicionario(d.membrana)
	m.opcoes = d.get("opcoes", m.opcoes)
	for i in d.get("agentes", []):
		if por_id.has(i):
			m.agentes.append(por_id[i])
	for i in d.get("agentes_iniciais", []):
		if por_id.has(i):
			m.agentes_iniciais.append(por_id[i])
	for i in d.get("mortos", []):
		if por_id.has(i):
			m.mortos.append(por_id[i])
	for i in d.get("resgatados", []):
		if por_id.has(i):
			m.resgatados.append(por_id[i])
	for a in m.agentes_iniciais:
		m.armas[a] = a.arma()
		var p: Array = d.posicoes.get(a.id, [0, 0])
		m.posicoes[a] = Vector2i(int(p[0]), int(p[1]))
	m.turno_mundo = int(d.get("turno_mundo", 1))
	m.indice = int(d.get("indice", 0))
	m.movimento_restante = int(d.get("movimento_restante", 0))
	m.movimento_rolado = d.get("movimento_rolado", false)
	m.acao_usada = d.get("acao_usada", false)
	m.reforcos = int(d.get("reforcos", 0))
	m.pistas = int(d.get("pistas", 0))
	m._turnos_sem_surgimento = int(d.get("turnos_sem_surgimento", 0))
	for i in d.get("descansos", {}):
		if por_id.has(i):
			var hx: Array = d.descansos[i]
			m._descansou[por_id[i]] = Vector2i(int(hx[0]), int(hx[1]))
	for linha in d.get("historico", []):
		m.historico.append(linha)
	m.encerrada = d.get("encerrada", false)
	m.vitoria = d.get("vitoria", false)
	m.caso = Caso.de_dicionario(d.caso) if not d.get("caso", {}).is_empty() else Caso.gerar(m.dados)
	m.modificador_chefe = float(d.get("modificador_chefe", 0.0))
	var inv: Dictionary = d.get("investigacao_pendente", {})
	if not inv.is_empty():
		m._preparar_investigacao(Vector2i(int(inv.hex[0]), int(inv.hex[1])), inv.cena, int(inv.get("semente", -1)))
	var ev: Dictionary = d.get("evento_pendente", {})
	if not ev.is_empty() and por_id.has(ev.agente):
		m.evento_pendente = {"hex": Vector2i(int(ev.hex[0]), int(ev.hex[1])), "evento": m._evento(ev.evento), "agente": por_id[ev.agente]}
	var enc: Dictionary = d.get("encontro_pendente", {})
	if not enc.is_empty():
		m._preparar_encontro(Vector2i(int(enc.hex[0]), int(enc.hex[1])), enc.encontro, enc.chefe, int(enc.get("semente", -1)))
	return m
