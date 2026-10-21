extends SceneTree
## Playtest automatizado (docs/41): joga missões completas como um jogador cuidadoso
## ("investigador") e como o piloto antigo ("pressa") e grava um resumo em playtest.json.
##   Godot --headless --path game -s res://dev/playtest_auto.gd -- <pasta de saída>

var notas: Array = []


func _initialize():
	var pasta: String = OS.get_cmdline_user_args()[0]
	Preferencias.caminho = "user://sonda_prefs.json"
	await process_frame
	root.get_node("Jogo").salvar_automaticamente = false
	var resumo := []
	for perfil in ["investigador", "pressa"]:
		for semente in [3, 11, 17, 23, 29, 41, 53, 67, 79, 97]:
			var r := _jogar(perfil, semente)
			resumo.append(r)
	var f := FileAccess.open(pasta + "/playtest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"resumo": resumo, "notas": notas}, "  "))
	f.close()
	quit()


func _nota(texto: String) -> void:
	notas.append(texto)


func _jogar(perfil: String, semente: int) -> Dictionary:
	var c := Carreira.nova()
	var m := c.iniciar_missao(c.roster.duplicate(), semente)
	var log: Array = []
	m.registro.connect(func(t): log.append(String(t))) if m.has_signal("registro") else null
	var r := {"perfil": perfil, "semente": semente, "combates": 0, "vitorias_combate": 0, "investigacoes": 0, "eventos": 0,
		"pistas_firmes": 0, "pistas_duvidosas": 0, "acusacoes_certas": 0, "acusacoes_erradas": 0, "ampliou": false,
		"escaladas_possiveis": 0, "subiu_serra": 0, "descansos": 0, "inocentes": 0, "eventos_com_pista": 0,
		"rodadas_investigacao": 0, "pistas_por_cena": [], "membrana_min": 100}
	var passos := 0
	var visitados := {}
	while not m.encerrada and passos < 6000 and m.turno_mundo <= 80:
		passos += 1
		r.membrana_min = mini(r.membrana_min, m.membrana.valor)
		if not m.evento_pendente.is_empty():
			var op := _melhor_opcao(m)
			var antes := m.caso.pistas.size()
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "resolver_evento", {"opcao": op}))
			r.eventos += 1
			if m.caso.pistas.size() > antes:
				r.eventos_com_pista += 1
			continue
		if not m.encontro_pendente.is_empty():
			var rc := PilotoMissao.resolver_combate(m.ruleset, m.encontro_pendente, m.membrana)
			r.combates += 1
			if rc.vencedor == "agentes":
				r.vitorias_combate += 1
			m.concluir_encontro(rc.vencedor if rc.terminou else "ameacas")
			continue
		if not m.investigacao_pendente.is_empty():
			var antes := m.caso.pistas.size()
			var res := PilotoMissao.resolver_investigacao(m)
			r.investigacoes += 1
			r.rodadas_investigacao += 1
			m.concluir_investigacao(res)
			r.pistas_por_cena.append(m.caso.pistas.size() - antes)
			if perfil == "investigador":
				_deduzir(m, r, false)
			continue
		var a := m.agente_atual()
		if a == null:
			break
		if perfil == "investigador":
			_deduzir(m, r, false)
		if a.pv * 2 < a.pv_maximo and m.pode_descansar():
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "descansar"))
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "encerrar_turno"))
			r.descansos += 1
			continue
		if not m.movimento_rolado:
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "rolar_movimento"))
			if m.pode_escalar:
				r.escaladas_possiveis += 1
			continue
		var destinos := m.destinos()
		if destinos.is_empty():
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "encerrar_turno"))
			continue
		var alvo := _alvo(m, perfil, r)
		var melhor: Vector2i = destinos.keys()[0]
		for h in destinos:
			if Hex.distancia(h, alvo) < Hex.distancia(melhor, alvo):
				melhor = h
		if perfil == "investigador" and alvo == m.mapa.encontrar("objetivo"):
			_deduzir(m, r, true)   # antes do covil, arrisca o que der
		var pos := m.posicao(a)
		var ok: bool = Comandos.aplicar_mapa(m, Comandos.novo("mapa", "mover", {"hex": Comandos.vetor(melhor)})).ok
		if ok and m.mapa.terreno(m.posicao(a)) == "serra":
			r.subiu_serra += 1
		if not ok or m.posicao(a) == pos:
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "encerrar_turno"))
			continue
		if not m.ocupado() and m.movimento_restante <= 0:
			Comandos.aplicar_mapa(m, Comandos.novo("mapa", "encerrar_turno"))
	r.encerrada = m.encerrada
	r.vitoria = m.vitoria
	r.turnos = m.turno_mundo
	r.membrana_fim = m.membrana.valor
	r.inocentes = m.inocentes_mortos
	r.solucionado = m.caso_solucionado()
	r.ampliou = m.caso.ampliada
	r.perguntas = m.caso.perguntas.map(func(q): return "%s:%s(%d)" % [q.id, "ok" if q.respondida else "-", int(q.encontradas)])
	for p in m.caso.pistas:
		if p.get("duvidosa", false):
			r.pistas_duvidosas += 1
		else:
			r.pistas_firmes += 1
	var rel := c.encerrar_missao() if m.encerrada else {}
	r.pp = rel.get("pp", 0)
	r.detalhes_pp = rel.get("detalhes_pp", [])
	r.mortos = m.mortos.size()
	return r


## Primeiro investigações e eventos; com o caso respondido (quem e o quê) ou sem mais nada, o covil.
func _alvo(m: Missao, perfil: String, r: Dictionary) -> Vector2i:
	var objetivo := m.mapa.encontrar("objetivo")
	r.covil_aberto_no_turno = r.get("covil_aberto_no_turno", -1) if r.get("covil_aberto_no_turno", -1) >= 0 or not m.covil_aberto() else m.turno_mundo
	# Com o covil selado (docs/42), até quem tem pressa precisa achar onde ele fica
	if m.covil_aberto() and (perfil == "pressa" or m.caso.solucionado() or m.turno_mundo > 30):
		return objetivo
	var a := m.agente_atual()
	var melhor := Vector2i(-999, -999)
	for h in m.mapa.celulas:
		var tipo := String(m.mapa.conteudo(h).get("tipo", ""))
		if tipo in ["investigacao", "evento"]:
			if melhor == Vector2i(-999, -999) or Hex.distancia(h, m.posicao(a)) < Hex.distancia(melhor, m.posicao(a)):
				melhor = h
	if melhor == Vector2i(-999, -999):
		_deduzir(m, r, true)   # nada mais a investigar: arrisca
	return melhor if melhor != Vector2i(-999, -999) else objetivo


## Opção do evento: a de melhor chance, com bônus se der pista.
func _melhor_opcao(m: Missao) -> int:
	var a: Agente = m.evento_pendente.agente
	var ops := m.opcoes_do_evento()
	var melhor := 0
	var nota := -1000
	for i in ops.size():
		var o: Dictionary = ops[i]
		var v := -50
		if o.get("sem_teste", false):
			v = -20
		else:
			v = a.dados_da_pericia(String(o.pericia)) * 4 + a.bonus_pericia(String(o.pericia)) - int(o.dt)
		for ef in o.get("sucesso", {}).get("efeitos", []):
			if ef.tipo == "pista":
				v += 6
		if v > nota:
			nota = v
			melhor = i
	return melhor


## Acusa quando as pistas firmes deixam um só suspeito. `arriscar`: com 1+ pista, acusa o
## mais provável (os incertos desempatam).
func _deduzir(m: Missao, r: Dictionary, arriscar: bool) -> void:
	for q in m.caso.perguntas.duplicate():
		if q.respondida or int(q.encontradas) < 1:
			continue
		var comp := m.caso.compativeis(q.id)
		if comp.size() != 1 and not arriscar:
			continue
		var duv := m.caso.indicios_duvidosos(q.id)
		comp.sort_custom(func(x, y): return x.indicios.filter(func(t): return t in duv).size() > y.indicios.filter(func(t): return t in duv).size())
		for cand in comp:
			var res := m.deduzir(q.id, cand.id)
			if not res.get("ok", false):
				continue
			if res.acertou:
				r.acusacoes_certas += 1
				break
			r.acusacoes_erradas += 1
			if not arriscar:
				break
