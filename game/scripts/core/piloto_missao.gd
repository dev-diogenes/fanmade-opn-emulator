class_name PilotoMissao
extends RefCounted
## Piloto automático de missão, sem interface: joga uma missão inteira do começo ao fim
## (movimento, eventos, combates, investigações e descanso). Serve para testar seeds em série
## (critério da Fase 4) e, mais tarde, para simular a IA de agentes controlados pelo jogo.

const LIMITE_TURNOS_COMBATE := 600
const LIMITE_PASSOS := 20000


## Resolve o combate pendente da missão só com a IA. Retorna {vencedor, turnos, terminou}.
static func resolver_combate(ruleset: Ruleset, config: Dictionary, membrana: Membrana) -> Dictionary:
	var dados := Dados.new(int(config.get("semente", 1)))
	var montado := MontagemCombate.montar(ruleset, config, dados, membrana)
	var c: Combate = montado.combate
	var armas: Dictionary = montado.armas
	c.iniciar()
	var turnos := 0
	var participantes_antes := c.participantes.size()
	while not c.encerrado and turnos < LIMITE_TURNOS_COMBATE:
		var rodada_antes := c.rodada
		var ser := c.proximo_turno()
		if c.rodada != rodada_antes and membrana != null:
			membrana.registrar("rodada_combate")
		turnos += 1
		if ser == null:
			break
		if c.participantes.size() != participantes_antes:   # cópias e invocações
			for s in c.participantes:
				if not armas.has(s):
					armas[s] = MontagemCombate.arma_de(ruleset, s)
			participantes_antes = c.participantes.size()
		IaCombate.jogar(c, ser, armas)
	return {"vencedor": c.lado_vencedor() if c.encerrado else "", "turnos": turnos, "terminou": c.encerrado, "rodadas": c.rodada}


## Joga a cena de investigação pendente: cada agente procura no ponto em que tem mais chance.
static func resolver_investigacao(m: Missao) -> Dictionary:
	var cena := m.criar_cena_investigacao()
	var passos := 0
	while not cena.encerrada and passos < 200:
		passos += 1
		var a := cena.agente_atual()
		if a == null:
			cena.encerrar()
			break
		var melhor_ponto := ""
		var melhor_pericia := ""
		var melhor_valor: int = -1000000
		for p in cena.pontos_disponiveis():
			for pericia in p.pericias:
				var valor: int = a.dados_da_pericia(pericia) * 5 + a.bonus_pericia(pericia) - int(p.pericias[pericia])
				if valor > melhor_valor:
					melhor_valor = valor
					melhor_ponto = p.id
					melhor_pericia = pericia
		if melhor_ponto == "" or cena.procurar(melhor_ponto, melhor_pericia).is_empty():
			cena.passar()
	if not cena.encerrada:
		cena.encerrar()
	return cena.resultado()


## Joga a missão inteira. Retorna um relatório: {encerrada, vitoria, turnos_mundo, combates,
## combates_sem_fim, eventos, investigacoes, passos, travou}.
static func jogar(m: Missao, limite_turnos_mundo: int = 150) -> Dictionary:
	var rel := {"combates": 0, "combates_sem_fim": 0, "eventos": 0, "investigacoes": 0, "passos": 0, "travou": ""}
	var objetivo := m.mapa.encontrar("objetivo")
	var sem_progresso := 0
	while not m.encerrada:
		rel.passos += 1
		if rel.passos > LIMITE_PASSOS:
			rel.travou = "passos demais"
			break
		if m.turno_mundo > limite_turnos_mundo:
			rel.travou = "turnos do mundo demais"
			break
		if not m.evento_pendente.is_empty():
			m.resolver_evento()
			rel.eventos += 1
			continue
		if not m.encontro_pendente.is_empty():
			var r := resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
			rel.combates += 1
			if not r.terminou:
				rel.combates_sem_fim += 1
			m.concluir_encontro(r.vencedor if r.terminou else "ameacas")
			continue
		if not m.investigacao_pendente.is_empty():
			m.concluir_investigacao(resolver_investigacao(m))
			rel.investigacoes += 1
			continue
		var a := m.agente_atual()
		if a == null:
			rel.travou = "sem agente da vez"
			break
		if a.pv * 2 < a.pv_maximo and m.pode_descansar():
			m.descansar()
			m.encerrar_turno()
			continue
		if not m.movimento_rolado:
			m.rolar_movimento()
			continue
		var destinos := m.destinos()
		if destinos.is_empty():
			m.encerrar_turno()
			continue
		var destino := _escolher_destino(m, a, destinos, objetivo)
		var pos_antes := m.posicao(a)
		if not m.mover(destino) or m.posicao(a) == pos_antes:
			sem_progresso += 1
			m.encerrar_turno()
			if sem_progresso > 500:
				rel.travou = "agentes não saem do lugar"
				break
			continue
		sem_progresso = 0
		if not m.ocupado() and m.movimento_restante <= 0:
			m.encerrar_turno()
	rel["encerrada"] = m.encerrada
	rel["vitoria"] = m.vitoria
	rel["turnos_mundo"] = m.turno_mundo
	return rel


## Vai para o hex alcançável mais perto do objetivo (machucado e com uma vila perto, vai para a vila).
static func _escolher_destino(m: Missao, a: Agente, destinos: Dictionary, objetivo: Vector2i) -> Vector2i:
	var alvo := objetivo
	if a.pv * 2 < a.pv_maximo:
		var melhor_vila := Vector2i(-999, -999)
		for h in destinos:
			if m.mapa.conteudo(h).get("tipo", "") in ["vila", "inicio"]:
				if melhor_vila == Vector2i(-999, -999) or Hex.distancia(h, m.posicao(a)) < Hex.distancia(melhor_vila, m.posicao(a)):
					melhor_vila = h
		if melhor_vila != Vector2i(-999, -999):
			return melhor_vila
	# O covil é a luta mais dura: espera o grupo chegar a até 2 hexes antes de entrar
	var juntos := true
	for outro in m.agentes:
		if outro != a and not outro.esta_fora_de_combate() and Hex.distancia(m.posicao(outro), objetivo) > 2:
			juntos = false
	var melhor: Vector2i = m.posicao(a)
	for h in destinos:
		if h == objetivo and not juntos:
			continue
		if not juntos and Hex.distancia(h, objetivo) < 1:
			continue
		if Hex.distancia(h, alvo) < Hex.distancia(melhor, alvo):
			melhor = h
	return melhor
