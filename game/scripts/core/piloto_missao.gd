class_name PilotoMissao
extends RefCounted
## Piloto automático de missão, sem interface: joga uma missão inteira do começo ao fim
## (movimento, eventos, combates, investigações e descanso). Serve para testar seeds em série
## (critério da Fase 4) e, mais tarde, para simular a IA de agentes controlados pelo jogo.

const LIMITE_PASSOS := 20000


## Resolve o combate pendente da missão só com a IA. Retorna {vencedor, turnos, terminou}.
static func resolver_combate(ruleset: Ruleset, config: Dictionary, membrana: Membrana) -> Dictionary:
	var fluxo := FluxoCombate.montar(ruleset, config, membrana)
	fluxo.ia_para_agentes = true
	fluxo.ameacas_pelo_mestre = false
	fluxo.iniciar()
	fluxo.avancar_ate_decisao()
	var c := fluxo.combate
	return {"vencedor": c.lado_vencedor() if c.encerrado else "", "turnos": fluxo.turnos, "terminou": c.encerrado, "rodadas": c.rodada}


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


## Faz as escolhas de NEX pendentes pela primeira opção que der certo (piloto e testes).
static func resolver_pendencias(a: Agente) -> void:
	for _i in 40:
		var pend := Progressao.pendencias(a)
		if pend.is_empty():
			return
		var p: Dictionary = pend[0]
		var feito := false
		if p.tipo == "grau":
			var opcoes: Array = p.opcoes
			feito = opcoes.size() >= int(p.quantidade) and Progressao.aplicar(a, "grau", opcoes.slice(0, int(p.quantidade))).is_empty()
		else:
			for op in p.opcoes:
				if Progressao.aplicar(a, p.tipo, op).is_empty():
					feito = true
					break
		if not feito:
			return


## Joga a missão inteira. Retorna um relatório: {encerrada, vitoria, turnos_mundo, combates,
## combates_sem_fim, eventos, investigacoes, passos, travou}. As decisões no mapa viram
## comandos (ADR 0007); com `registro`, eles ficam guardados para um replay.
static func jogar(m: Missao, limite_turnos_mundo: int = 150, registro = null) -> Dictionary:
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
			_cmd(m, {"acao": "resolver_evento"}, registro)
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
			deduzir(m, false, registro)
			continue
		var a := m.agente_atual()
		if a == null:
			rel.travou = "sem agente da vez"
			break
		if a.pv * 2 < a.pv_maximo and m.pode_descansar():
			_cmd(m, {"acao": "descansar"}, registro)
			_cmd(m, {"acao": "encerrar_turno"}, registro)
			continue
		if not m.movimento_rolado:
			_cmd(m, {"acao": "rolar_movimento"}, registro)
			continue
		var destinos := m.destinos()
		if destinos.is_empty():
			_cmd(m, {"acao": "encerrar_turno"}, registro)
			continue
		# Covil fechado e nada mais a investigar: arrisca as acusações (docs/42)
		deduzir(m, not m.covil_aberto() and not _tem_pista_no_mapa(m), registro)
		var destino := _escolher_destino(m, a, destinos, objetivo)
		var pos_antes := m.posicao(a)
		if not _cmd(m, {"acao": "mover", "hex": Comandos.vetor(destino)}, registro).ok or m.posicao(a) == pos_antes:
			sem_progresso += 1
			_cmd(m, {"acao": "encerrar_turno"}, registro)
			if sem_progresso > 500:
				rel.travou = "agentes não saem do lugar"
				break
			continue
		sem_progresso = 0
		if not m.ocupado() and m.movimento_restante <= 0:
			_cmd(m, {"acao": "encerrar_turno"}, registro)
	rel["encerrada"] = m.encerrada
	rel["vitoria"] = m.vitoria
	rel["turnos_mundo"] = m.turno_mundo
	return rel


static func _cmd(m: Missao, args: Dictionary, registro) -> Dictionary:
	var cmd := Comandos.novo("mapa", String(args.acao), args)
	if registro is Array:
		registro.append(cmd)
	return Comandos.aplicar_mapa(m, cmd)


## Acusa quando as pistas firmes deixam um só suspeito (docs/42). `arriscar`: com o covil
## fechado e nada mais a investigar, acusa os compatíveis em ordem até acertar.
static func deduzir(m: Missao, arriscar: bool, registro = null) -> void:
	if m.caso == null:
		return
	# Relatório à Ordem (docs/52): quem, o quê e onde juntos
	if m.caso.perguntas_do_relatorio().size() > 1:
		var lote := lote_para_relatar(m.caso, arriscar)
		if not lote.is_empty():
			_cmd(m, {"acao": "relatar", "respostas": lote}, registro)
	for q in m.caso.perguntas.duplicate():
		if q.respondida or int(q.encontradas) < 1:
			continue
		if String(q.id) in Caso.PERGUNTAS_BASE and m.caso.perguntas_do_relatorio().size() > 1:
			continue   # vai no relatório
		var comp := m.caso.compativeis(q.id)
		if comp.size() != 1 and not arriscar:
			continue
		for cand in comp:
			var res := _cmd(m, {"acao": "deduzir", "pergunta": q.id, "candidato": cand.id}, registro)
			if res.get("deducao", {}).get("acertou", false) or not arriscar:
				break


## O relatório que o piloto manda (docs/52): com um só compatível em cada pergunta, esse; com
## `arriscar`, a primeira combinação de compatíveis que a Ordem ainda não recusou. {} se falta
## pista em alguma pergunta (ou, sem arriscar, se alguma ainda tem mais de um suspeito).
static func lote_para_relatar(caso: Caso, arriscar: bool) -> Dictionary:
	var listas: Array = []
	var ids: Array = []
	for q in caso.perguntas_do_relatorio():
		var comp := caso.compativeis(String(q.id))
		if int(q.encontradas) < 1 or comp.is_empty() or (comp.size() != 1 and not arriscar):
			return {}
		listas.append(comp.map(func(c): return String(c.id)))
		ids.append(String(q.id))
	var combos: Array = [{}]
	for i in ids.size():
		var novos: Array = []
		for parcial in combos:
			for cid in listas[i]:
				var c: Dictionary = parcial.duplicate()
				c[ids[i]] = cid
				novos.append(c)
		combos = novos
	for c in combos:
		if not c in caso.relatorios_recusados:
			return c
	return {}


## Próximo lugar com o que investigar (investigação ou evento) mais perto do agente, ou o covil.
static func _proxima_pista(m: Missao, a: Agente, objetivo: Vector2i) -> Vector2i:
	var melhor := Vector2i(-999, -999)
	for h in m.mapa.celulas:
		if String(m.mapa.conteudo(h).get("tipo", "")) in ["investigacao", "evento"]:
			if melhor == Vector2i(-999, -999) or Hex.distancia(h, m.posicao(a)) < Hex.distancia(melhor, m.posicao(a)):
				melhor = h
	return melhor if melhor != Vector2i(-999, -999) else objetivo


static func _tem_pista_no_mapa(m: Missao) -> bool:
	for h in m.mapa.celulas:
		if String(m.mapa.conteudo(h).get("tipo", "")) in ["investigacao", "evento"]:
			return true
	return false


## Vai para o hex alcançável mais perto do objetivo (machucado e com uma vila perto, vai para a vila).
## Com o covil selado (docs/42), antes vai atrás de pistas.
static func _escolher_destino(m: Missao, a: Agente, destinos: Dictionary, objetivo: Vector2i) -> Vector2i:
	var alvo := objetivo if m.covil_aberto() else _proxima_pista(m, a, objetivo)
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
