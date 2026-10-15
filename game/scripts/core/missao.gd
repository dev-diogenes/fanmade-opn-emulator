class_name Missao
extends RefCounted
## Estado e regras de uma missão no mapa-múndi (estilo For The King):
## cada agente joga seu turno (rola movimento em slots de d20, anda, resolve o que
## encontra); depois o mundo age (Membrana enfraquece, ameaças surgem).
## A cena do mapa só exibe e chama estes métodos; o combate acontece na arena.

signal registro(texto: String)
signal evento_aberto(hex: Vector2i, evento: Dictionary, agente: Agente)
signal encontro_iniciado(config: Dictionary)
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
var ultimo_movimento: Dictionary = {}   ## {"slots": [...], "dt": int, "sucessos": int, "total": int}
var evento_pendente: Dictionary = {}    ## {"hex", "evento", "agente"}
var encontro_pendente: Dictionary = {}  ## config para a arena
var encerrada := false
var vitoria := false

## Todas as linhas do registro (a cena do mapa é recriada após cada combate)
var historico: Array[String] = []

var _cfg: Dictionary
var _descansou: Dictionary = {}          ## Agente -> hex onde já descansou nesta visita
var _turnos_sem_surgimento := 0


static func nova(semente: int, ruleset_: Ruleset = null) -> Missao:
	var m := Missao.new()
	m.ruleset = ruleset_ if ruleset_ != null else RulesetOp2022.carregar_padrao()
	m.dados = Dados.new(semente)
	m._cfg = DadosJogo.ler("mapa")
	m.mapa = GeradorMapa.gerar(semente)
	m.membrana = Membrana.carregar_padrao()
	var inicio := m.mapa.encontrar("inicio")
	for ficha in DadosJogo.ler("grupo_inicial").agentes:
		var r := CriacaoAgente.criar(m.ruleset, ficha)
		assert(r.agente != null, "Ficha inicial inválida: %s" % [r.erros])
		var a: Agente = r.agente
		m.agentes.append(a)
		m.armas[a] = m.ruleset.arma(ficha.arma)
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
	return not evento_pendente.is_empty() or not encontro_pendente.is_empty() or encerrada


## Rola o movimento do agente da vez: 1 d20 por ponto de Agilidade (mínimo 1) + 1 por PE de Foco.
## Cada slot >= DT vale 1 ponto, somado à base (mapa.json). Uma vez por turno.
func rolar_movimento(pe_foco: int = 0) -> Dictionary:
	var a := agente_atual()
	if a == null or movimento_rolado or ocupado():
		return {}
	if pe_foco > 0 and not a.gastar_pe(pe_foco):
		return {}
	var regra: Dictionary = _cfg.movimento
	var qtd := maxi(1, a.atributo(regra.atributo)) + pe_foco
	var dt := int(regra.dt_slot)
	var slots := dados.rolar_varios(qtd, 20)
	var sucessos := slots.filter(func(v): return v >= dt).size()
	movimento_restante = int(regra.base) + sucessos
	movimento_rolado = true
	ultimo_movimento = {"slots": slots, "dt": dt, "sucessos": sucessos, "total": movimento_restante, "agente": a.nome}
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
	ultimo_movimento = {}
	var a := agente_atual()
	if a != null:
		a.pe_gasto_no_turno = 0
		turno_mudou.emit(a)


# --- Eventos ---------------------------------------------------------------

func _evento(evento_id: String) -> Dictionary:
	for e in DadosJogo.ler("eventos").eventos:
		if e.id == evento_id:
			return e
	return {}


## O agente que entrou no hex faz o teste do evento. Retorna {teste, sucesso, texto}.
func resolver_evento(pe_foco: int = 0) -> Dictionary:
	if evento_pendente.is_empty():
		return {}
	var ev: Dictionary = evento_pendente.evento
	var a: Agente = evento_pendente.agente
	var teste := a.testar(dados, ev.pericia, int(ev.dt), pe_foco)
	var sucesso := teste != null and teste.sucesso
	var lado: Dictionary = ev.sucesso if sucesso else ev.falha
	var linha := "%s testa %s (DT %d): %s" % [a.nome, ruleset.pericia(ev.pericia).nome, int(ev.dt),
		teste.descrever() if teste != null else "sem treino — falha automática"]
	_log(linha)
	_log(lado.texto)
	for ef in lado.get("efeitos", []):
		_aplicar_efeito(a, ef, evento_pendente.hex)
	mapa.limpar_conteudo(evento_pendente.hex)
	evento_pendente = {}
	_verificar_derrota()
	return {"teste": teste, "sucesso": sucesso, "texto": lado.texto}


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
func _preparar_encontro(h: Vector2i, encontro_id: String, chefe: bool) -> void:
	var info: Dictionary = DadosJogo.ler("encontros").chefe if chefe else _encontro(encontro_id)
	var participantes: Array[Agente] = []
	var alcance := int(_cfg.aliados_entram_no_combate_ate)
	for a in agentes:
		if not a.tem(Ser.MORTO) and not a.esta_fora_de_combate() and Hex.distancia(posicao(a), h) <= alcance:
			participantes.append(a)
	var ameacas: Array = []
	for amea_id in info.ameacas:
		ameacas.append(DadosJogo.ameaca(ruleset, amea_id))
	encontro_pendente = {
		"hex": h, "nome": info.nome, "chefe": chefe, "terreno": mapa.terreno(h),
		"agentes": participantes, "armas": armas, "ameacas": ameacas,
		"nivel_membrana": membrana.nivel_ameaca(), "semente": dados.rolar(1000000),
	}
	_log("[color=#ec7063][b]Encontro: %s![/b][/color] (%d agente(s) entram no combate)" % [info.nome, participantes.size()])
	encontro_iniciado.emit(encontro_pendente)


func _encontro(encontro_id: String) -> Dictionary:
	for e in DadosJogo.ler("encontros").encontros:
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
	if vencedor == "agentes":
		for a in encontro_pendente.agentes:
			if not a.tem(Ser.MORTO) and a.pv == 0:
				a.estabilizar()
				a.curar(1)
				_log("%s é socorrido e volta com 1 PV." % a.nome)
		mapa.limpar_conteudo(h)
		_log("[color=#58d68d]Encontro vencido.[/color]")
		encontro_pendente = {}
		if chefe:
			_encerrar(true)
	else:
		encontro_pendente = {}
		_log("[color=#ec7063]Os agentes caíram.[/color]")
		_encerrar(false)
	_verificar_derrota()


# --- Mundo -----------------------------------------------------------------

func _turno_do_mundo() -> void:
	turno_mundo += 1
	membrana.registrar("turno_mapa")
	_log("[color=#7f8c8d]— Turno %d do mundo — Membrana %d (%s)[/color]" % [turno_mundo, membrana.valor, membrana.estado().get("nome", "")])
	_turnos_sem_surgimento += 1
	if _turnos_sem_surgimento >= int(_cfg.mundo.surgimento_a_cada_turnos) and membrana.nivel_ameaca() >= 1:
		_turnos_sem_surgimento = 0
		_surgir_ameaca()


## Uma nova ameaça surge perto de um agente vivo, com nível até o da Membrana.
func _surgir_ameaca() -> void:
	var vivos := agentes.filter(func(a): return not a.esta_fora_de_combate())
	if vivos.is_empty():
		return
	var alvo: Agente = vivos[dados.rolar(vivos.size()) - 1]
	var nivel := membrana.nivel_ameaca()
	var opcoes: Array = DadosJogo.ler("encontros").encontros.filter(func(e): return int(e.nivel) <= nivel)
	var candidatos: Array[Vector2i] = []
	for h in Hex.area(posicao(alvo), 3):
		if Hex.distancia(h, posicao(alvo)) >= 2 and mapa.passavel(h) and mapa.conteudo(h).is_empty() and agentes_em(h).is_empty():
			candidatos.append(h)
	if candidatos.is_empty() or opcoes.is_empty():
		return
	var h := candidatos[dados.rolar(candidatos.size()) - 1]
	var e: Dictionary = opcoes[dados.rolar(opcoes.size()) - 1]
	mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": e.id})
	mapa.revelar(h, 0)
	_log("[color=#c39bd3]Com a Membrana %s, algo surge perto de %s: %s.[/color]" % [membrana.estado().nome.to_lower(), alvo.nome, e.nome])


func _verificar_derrota() -> void:
	if encerrada:
		return
	if agentes.all(func(a): return a.esta_fora_de_combate()):
		_encerrar(false)


func _encerrar(venceu: bool) -> void:
	if encerrada:
		return
	encerrada = true
	vitoria = venceu
	_log("[b]%s[/b]" % ("MISSÃO CUMPRIDA" if venceu else "MISSÃO FRACASSADA"))
	missao_encerrada.emit(venceu)
