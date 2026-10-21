extends GutTest
## Acessibilidade (docs/18): atalhos remapeáveis (A4), fotossensibilidade (A5) e paleta para
## daltonismo (A6).

var _antes := ""


func before_each():
	_antes = Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_acessibilidade.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias._daltonismo_cache = -1
	Preferencias._efeitos_cache = {}
	Atalhos.configurar()


func after_each():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = _antes
	Preferencias._daltonismo_cache = -1
	Preferencias._efeitos_cache = {}
	Atalhos.configurar()


func _tecla(keycode: int, eco := false) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.pressed = true
	ev.echo = eco
	return ev


func test_padroes_viram_acoes_do_inputmap():
	assert_eq(Atalhos.tecla("ficha"), KEY_F)
	assert_eq(Atalhos.nome_tecla("quadro"), "Tab")
	assert_true(Atalhos.pressionou(_tecla(KEY_F), "ficha"))
	assert_false(Atalhos.pressionou(_tecla(KEY_G), "ficha"))
	assert_false(Atalhos.pressionou(_tecla(KEY_F, true), "ficha"), "repetição não conta")
	assert_true(Atalhos.pressionou(_tecla(KEY_Q, true), "camera_girar_esq", true), "a câmera aceita segurar")
	assert_true(Atalhos.pressionou(_tecla(KEY_UP), "mover_cima"), "as setas continuam valendo")
	assert_true(Atalhos.pressionou(_tecla(KEY_KP_ENTER), "confirmar_carta"))


func test_remapear_grava_e_troca_a_tecla():
	assert_true(Atalhos.remapear("ficha", KEY_I).is_empty())
	assert_eq(Atalhos.tecla("ficha"), KEY_I)
	assert_true(Atalhos.pressionou(_tecla(KEY_I), "ficha"))
	assert_false(Atalhos.pressionou(_tecla(KEY_F), "ficha"), "a tecla antiga deixa de valer")
	assert_eq(int(Preferencias.atalhos().get("ficha", 0)), KEY_I, "fica salvo nas preferências")
	Atalhos.remapear("ficha", KEY_F)
	assert_false(Preferencias.atalhos().has("ficha"), "voltar ao padrão limpa a entrada")


func test_conflito_na_mesma_tela_troca_as_duas():
	# W é "para a frente"; se a ficha passa a ser W, "para a frente" fica com F
	var trocados := Atalhos.remapear("ficha", KEY_W)
	assert_eq(trocados, ["mover_cima"] as Array[String])
	assert_eq(Atalhos.tecla("ficha"), KEY_W)
	assert_eq(Atalhos.tecla("mover_cima"), KEY_F)


func test_telas_diferentes_podem_dividir_tecla():
	# E gira a câmera (mapa e combate) e procura pistas (investigação): não brigam
	assert_eq(Atalhos.tecla("camera_girar_dir"), Atalhos.tecla("examinar"))
	assert_true(Atalhos.conflitos("examinar", KEY_E).is_empty())


func test_esc_e_reservado_e_restaurar_volta_tudo():
	assert_true(Atalhos.remapear("ficha", KEY_ESCAPE).is_empty())
	assert_eq(Atalhos.tecla("ficha"), KEY_F, "Esc não pode ser escolhido")
	Atalhos.remapear("quadro", KEY_Q)
	Atalhos.restaurar()
	assert_eq(Atalhos.tecla("quadro"), KEY_TAB)
	assert_true(Preferencias.atalhos().is_empty())


func test_folha_de_atalhos_remapeia_pela_tecla():
	var f := FolhaAtalhos.abrir(self)
	assert_true(FolhaAtalhos.aberta(self))
	assert_eq(f._botoes.size(), Atalhos.ACOES.size(), "um botão por ação")
	assert_eq(f._botoes["ficha"].text, "F")
	f._botoes["ficha"].pressed.emit()
	assert_eq(f.esperando, "ficha")
	assert_eq(f._botoes["ficha"].text, "pressione…")
	f.receber_tecla(KEY_J)
	assert_eq(f.esperando, "")
	assert_eq(f._botoes["ficha"].text, "J")
	assert_eq(Atalhos.tecla("ficha"), KEY_J)
	f._botoes["ficha"].pressed.emit()
	f.receber_tecla(KEY_ESCAPE)
	assert_eq(Atalhos.tecla("ficha"), KEY_J, "Esc desiste sem mudar nada")
	f.free()


func test_carta_mostra_a_tecla_escolhida():
	Atalhos.remapear("carta_2", KEY_Z)
	var c := CartaAcao.criar("Atacar", "Clique num inimigo", 2, 1, Tema.OURO)
	add_child_autofree(c)
	assert_true(c.tooltip_text.ends_with("(Z)"))


func test_flashes_suaves_por_padrao():
	assert_eq(Preferencias.flashes(), "suave")
	assert_false(Preferencias.aviso_flashes_visto())
	Preferencias.marcar_aviso_flashes()
	assert_true(Preferencias.aviso_flashes_visto())
	var vista := SubViewportContainer.new()
	add_child_autofree(vista)
	Tema.veu(vista)
	var m := vista.material as ShaderMaterial
	Tema.pulso_vhs(vista, 0.8, 0.3)
	assert_almost_eq(float(m.get_shader_parameter("glitch")), 0.36, 0.001, "pulso mais fraco")
	assert_almost_eq(float(m.get_shader_parameter("ritmo")), Tema.RITMO_SUAVE, 0.001, "fita mais lenta")
	Preferencias.definir_flashes("completo")
	Tema.pulso_vhs(vista, 0.8, 0.3)
	assert_almost_eq(float(m.get_shader_parameter("glitch")), 0.8, 0.001)
	assert_almost_eq(float(m.get_shader_parameter("ritmo")), 1.0, 0.001)


func test_paleta_para_daltonismo_troca_verde_e_vermelho():
	assert_eq(Tema.cor_sucesso(), Tema.SUCESSO)
	assert_eq(Tema.cor_falha(true), Tema.SANGUE)
	assert_eq(Tema.cores_slot("sucesso")[0], Tema.OURO)
	Preferencias.definir_daltonismo(true)
	assert_true(Preferencias.daltonismo())
	assert_eq(Tema.cor_sucesso(), Color("56b4e9"), "azul")
	assert_eq(Tema.cor_falha(), Color("e69f00"), "laranja")
	assert_eq(Tema.cores_slot("falha")[0], Color("8a4a00"))
	var s := Tema.slot_d20(15, "sucesso")
	add_child_autofree(s)
	assert_true((s.get_child(0) as Label).text.contains("✓"), "o símbolo continua")
	var b := BilheteDesfecho.new()
	var selo := b._selo_efeito({"texto": "−2 PV", "tipo": "dano"})
	assert_eq((selo.get_theme_stylebox("normal") as StyleBoxFlat).bg_color, Tema.cor_falha(true))
	selo.free()
	b.free()
