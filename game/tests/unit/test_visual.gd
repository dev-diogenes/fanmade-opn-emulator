extends GutTest
## Direção de arte (ADR 0008): o tema da interface e as peças com modelos KayKit
## (ou o fallback por código, quando os modelos não estão no clone).


func test_tema_tem_variacoes_e_estilos():
	var t := Tema.criar()
	assert_true(t.has_stylebox("panel", "PanelContainer"))
	assert_true(t.has_stylebox("normal", "Button"))
	assert_eq(t.get_type_variation_base("Titulo"), &"Label")
	assert_eq(t.get_type_variation_base("BotaoPrincipal"), &"Button")
	assert_eq(t.get_type_variation_base("PainelLateral"), &"PanelContainer")


func test_painel_herda_tamanho_do_conteudo():
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(300, 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p := Tema.painel(v, true)
	add_child_autofree(p)
	assert_eq(p.custom_minimum_size, Vector2(300, 0))
	assert_eq(p.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_eq(p.theme_type_variation, &"PainelLateral")
	assert_eq(v.get_parent(), p)


func test_agente_sempre_devolve_figura():
	for classe in ["combatente", "especialista", "ocultista", "mundano", "desconhecida"]:
		var f := Pecas.agente(classe, Color.BLUE, 0.75)
		assert_not_null(f, classe)
		add_child_autofree(f)
		assert_gt(f.get_child_count(), 0, classe)


func test_tile_terreno_usa_modelo_ou_null():
	var tile := Pecas.tile_terreno("floresta", 1.0, 0.24, 42, Color("24452b"))
	if not ResourceLoader.exists(Pecas.DIR_HEX + "hex_grass.gltf"):
		assert_null(tile, "sem os modelos, o mapa usa a primitiva")
		return
	assert_not_null(tile)
	add_child_autofree(tile)
	assert_eq(tile.get_child_count(), 2, "tile e decoração")


func test_slot_d20_por_estado():
	for estado in ["sucesso", "falha", "neutro"]:
		var s := Tema.slot_d20(17, estado)
		add_child_autofree(s)
		var l: Label = s.get_child(0)
		assert_true(l.text.begins_with("17"), estado)
	var falha := Tema.slot_d20(3, "falha")
	add_child_autofree(falha)
	assert_true((falha.get_child(0) as Label).text.ends_with("✗"), "falha não depende só da cor")


func test_bb_usa_o_token():
	assert_eq(Tema.bb("Encontro!", Tema.PERIGO), "[color=#%s]Encontro![/color]" % Tema.PERIGO.to_html(false))


func test_cartao_agente_mostra_vez_e_queda():
	var rs := RulesetOp2022.carregar_padrao()
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2})
	var c := CartaoAgente.criar(a, Tema.CORES_JOGADORES[0])
	add_child_autofree(c)
	c.atualizar(true)
	assert_eq(c.modulate.a, 1.0)
	assert_eq(c._estilo.border_color, Tema.OURO_CLARO, "borda dourada na vez")
	a.condicoes[Ser.INCONSCIENTE] = true
	c.atualizar(false)
	assert_string_contains(c._nome.text, "✝", "caído não depende só da cor")
	assert_eq(c.modulate.a, 0.5)


func test_tela_de_titulo_carrega():
	var t = load("res://scenes/titulo.tscn").instantiate()
	add_child_autofree(t)
	await wait_frames(2)
	assert_not_null(t._mapa3d)
	assert_gt(t._menu.get_child_count(), 3)


func test_sigilo_e_deterministico_e_varia():
	assert_eq(Sigilo.gerar(7), Sigilo.gerar(7), "mesma semente, mesmo sigilo")
	assert_ne(Sigilo.gerar(7), Sigilo.gerar(8))
	assert_gt(Sigilo.gerar(7).size(), 4, "círculo, raios e arcos")


func test_moldura_riscada_tem_margens():
	var m := MolduraRiscada.criar(Tema.OURO, Tema.PEDRA, Vector2(14, 10))
	assert_eq(m.get_content_margin(SIDE_LEFT), 14.0)
	assert_eq(m.get_content_margin(SIDE_TOP), 10.0)


func test_quadro_mostra_fotos_e_carimbo():
	var caso := Caso.gerar(Dados.new(5))
	var q := QuadroInvestigacao.new()
	q.size = Vector2(470, 420)
	add_child_autofree(q)
	caso.registrar_pista("Pista um", "quem", "teste")
	caso.registrar_pista("Pista dois", "quem", "teste")
	q.atualizar(caso)
	assert_eq(q._fios.size(), 2, "um fio por pista")
	var textos: Array = q.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.any(func(t): return t.begins_with("RESOLVIDO")), "pergunta respondida recebe o carimbo")


func test_investigacao_sem_formularios():
	var tela = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	for tipo in ["OptionButton", "CheckBox", "SpinBox"]:
		var visiveis: Array = tela.find_children("*", tipo, true, false).filter(func(n): return n.is_visible_in_tree())
		assert_eq(visiveis.size(), 0, "nenhum %s visível (docs/09, 5.5)" % tipo)
	assert_eq(tela._cartas.size(), 4)
	tela._selecionar_carta("ajudar")
	assert_true(tela._cartas.ajudar.selecionada)


func _sem_formularios(tela: Node) -> void:
	for tipo in ["SpinBox"]:
		var visiveis: Array = tela.find_children("*", tipo, true, false).filter(func(n): return n.is_visible_in_tree())
		assert_eq(visiveis.size(), 0, "nenhum %s visível em %s" % [tipo, tela.name])


func test_mapa_e_hud_flutuante():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	_sem_formularios(tela)
	assert_true(tela._log is RelatorioCampo, "registro recolhível")
	assert_eq(tela._vista.anchor_right, 1.0, "3D em tela cheia")
	tela._mostrar_dica(Vector2(400, 300))   # não quebra fora ou dentro de um hex


func test_combate_tem_cartas():
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.semente = 3
	add_child_autofree(arena)
	await wait_frames(2)
	_sem_formularios(arena)
	assert_eq(arena._cartas.size(), 5)
	arena._abrir_bilhete("item")
	assert_eq(arena._bilhete_tipo, "item")
	arena._abrir_bilhete("item")
	assert_eq(arena._bilhete_tipo, "", "clicar de novo fecha o bilhete")


func test_base_e_dossie_com_abas():
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	await wait_frames(2)
	assert_eq(base._abas.get_tab_count(), 4)
	var tour := TourGuiado.new()   # fora da árvore: não conta como tour aberto
	tour._abrir_aba_de(base._btn_iniciar)
	tour.free()
	assert_eq(base._abas.current_tab, 2, "o tour abre a aba Missão para mostrar o Iniciar")
	for c in get_tree().root.find_children("ConviteTutorial", "", true, false):
		c.queue_free()


func test_marcos_de_op_tem_peca_e_cor():
	for tipo in ["encontro", "evento", "objetivo", "investigacao", "vila", "inicio", "desconhecido"]:
		var m := Pecas.marco(tipo)
		add_child_autofree(m)
		assert_true(m.has_meta("peca"), tipo)
		assert_true(m.get_meta("peca").get_parent() == m, "%s: a peça flutuante fica no marco" % tipo)


func test_ameacas_tem_figura():
	var rs := RulesetOp2022.carregar_padrao()
	for id in ["zumbi_de_sangue", "iniciado", "tita_de_sangue"]:
		var ficha := rs.ameaca(id)
		var a := Ameaca.criar(rs, String(ficha.get("nome", id)), ficha)
		var f := Pecas.ameaca(a)
		add_child_autofree(f)
		assert_gt(f.get_child_count(), 0, id)
