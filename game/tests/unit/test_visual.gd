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
