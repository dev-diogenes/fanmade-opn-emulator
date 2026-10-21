extends GutTest
## Transcender como ritual (docs/31): a sala do agente, o sigilo e as escolhas de NEX.
## A Base é substituída por uma falsa (sem tocar na carreira do Jogo nem no save).


class BaseFalsa:
	extends Node
	signal pendencias_mudaram(agente: Agente, erros: Array)
	var montagens := 0

	func _montar_pendencia(a: Agente, caixa: VBoxContainer = null) -> void:
		montagens += 1
		var l := Label.new()
		l.text = "%d pendente(s)" % Progressao.pendencias(a).size()
		caixa.add_child(l)

	func aplicar(a: Agente) -> void:
		var p: Dictionary = Progressao.pendencias(a)[0]
		var escolha = p.opcoes[0] if p.tipo != "grau" else p.opcoes.slice(0, int(p.get("quantidade", 1)))
		var erros := Progressao.aplicar(a, p.tipo, escolha, [])
		pendencias_mudaram.emit(a, erros)


func _ocultista() -> Agente:
	var rs := RulesetOp2022.carregar_padrao()
	var r := CriacaoAgente.criar(rs, {"nome": "Rita", "classe": "ocultista", "origem": "academico", "nex": 5,
		"atributos": {"agi": 1, "for": 1, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["intuicao", "percepcao", "religiao", "atualidades", "medicina", "diplomacia"],
		"rituais": rs.dados.rituais.rituais.filter(func(x): return int(x.circulo) == 1).slice(0, 3).map(func(x): return String(x.id))})
	assert_not_null(r.agente, "ficha de teste: %s" % [r.erros])
	return r.agente


func test_andar_ate_o_sigilo_comeca_o_ritual():
	var sala := SalaTranscender.new()
	add_child_autofree(sala)
	sala.construir(_ocultista())
	assert_false(sala.no_sigilo(), "começa na porta")
	for i in 120:
		sala.mover(-sala.figura.position, 1.0 / 60.0)
		if sala.no_sigilo():
			break
	assert_true(sala.no_sigilo(), "andando para o centro, chega ao sigilo")
	sala.mover(Vector3(0, 0, 50), 10.0)
	assert_lte(Vector2(sala.figura.position.x, sala.figura.position.z).length(), SalaTranscender.RAIO_SALA + 0.001, "não atravessa as paredes")


func test_escolhas_de_nex_no_ritual():
	var a := _ocultista()
	a.nex = 10
	var base := BaseFalsa.new()
	add_child_autofree(base)
	var t := Transcender.abrir(base, a)
	assert_false(t.no_ritual)
	t.comecar_ritual()
	assert_true(t.no_ritual)
	await wait_seconds(2.6)
	assert_true(t._papel.visible, "as escolhas aparecem depois de ajoelhar")
	assert_gt(base.montagens, 0, "o papel usa as escolhas da Base")
	var guarda := 0
	while not Progressao.pendencias(a).is_empty() and guarda < 8:
		base.aplicar(a)
		guarda += 1
	await wait_frames(2)
	var textos: Array = t._caixa.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree()).map(func(b): return b.text)
	assert_true(textos.has("Levantar e voltar à Base"), "feitas as escolhas, o ritual termina")
	t.fechar()
