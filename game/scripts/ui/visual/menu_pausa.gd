class_name MenuPausa
extends CanvasLayer
## Pausa da operação (docs/10): Esc abre uma pasta com Continuar, Ajustes de efeitos
## (granulação/vinheta, VHS, estática entre telas) e, quando a tela permite, sair.
## O jogo não congela (no online, a sessão segue); a pasta só cobre a tela.

var _pasta: VBoxContainer
var _ajustes: VBoxContainer


## `saidas`: [[texto, Callable, pedir_confirmacao(String ou "")], …]
static func abrir(pai: Node, saidas: Array = []) -> MenuPausa:
	var m := MenuPausa.new()
	m._montar(saidas)
	pai.add_child(m)
	return m


static func aberto(pai: Node) -> bool:
	return not pai.find_children("*", "MenuPausa", false, false).is_empty()


func _montar(saidas: Array) -> void:
	layer = 92
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.72)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var sig := Sigilo.new()
	sig.semente = 1987
	sig.cor = Color(Tema.SANGUE_CLARO, 0.15)
	sig.espessura = 3.0
	sig.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	sig.size = Vector2(560, 560)
	sig.position -= sig.size / 2.0
	add_child(sig)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(360, 0)
	centro.add_child(painel)
	_pasta = VBoxContainer.new()
	_pasta.add_theme_constant_override("separation", Tema.ESPACO_M)
	painel.add_child(_pasta)
	var t := Label.new()
	t.text = "Operação pausada"
	t.theme_type_variation = "Titulo"
	_pasta.add_child(t)
	var continuar := _item("Continuar", queue_free)
	_item("Ajustes", func(): _ajustes.visible = not _ajustes.visible)
	_ajustes = VBoxContainer.new()
	_ajustes.visible = false
	_pasta.add_child(_ajustes)
	montar_leitura(_ajustes)
	var linha_vol := HBoxContainer.new()
	linha_vol.add_theme_constant_override("separation", Tema.ESPACO_M)
	_ajustes.add_child(linha_vol)
	var lv := Label.new()
	lv.text = "Volume"
	linha_vol.add_child(lv)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = Preferencias.volume()
	volume.custom_minimum_size = Vector2(180, 0)
	volume.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	volume.value_changed.connect(func(v):
		Preferencias.definir_volume(v)
		Som.aplicar_volume())
	linha_vol.add_child(volume)
	var cam := Button.new()
	cam.alignment = HORIZONTAL_ALIGNMENT_LEFT
	cam.text = "Câmera: %s (%s)" % [CameraRig.NOMES_MODOS.get(Preferencias.camera(), "3ª pessoa"), Atalhos.nome_tecla("camera_modo")]
	cam.pressed.connect(func():
		var i := CameraRig.MODOS.find(Preferencias.camera())
		var novo: String = CameraRig.MODOS[(i + 1) % CameraRig.MODOS.size()]
		Preferencias.definir_camera(novo)
		for rig in get_tree().root.find_children("*", "CameraRig", true, false):
			rig.definir_modo(novo)
		cam.text = "Câmera: %s (%s)" % [CameraRig.NOMES_MODOS[novo], Atalhos.nome_tecla("camera_modo")])
	_ajustes.add_child(cam)
	for e in [["grao", "Granulação e vinheta"], ["glitch", "Glitch de VHS e tremores"], ["transicoes", "Estática entre as telas"],
			["ambiente", "Som ambiente (drone e sussurros)"]]:
		var c := CheckBox.new()
		c.text = e[1]
		c.button_pressed = Preferencias.efeito(e[0])
		c.toggled.connect(func(v):
			Preferencias.definir_efeito(e[0], v)
			Som.aplicar_volume())
		_ajustes.add_child(c)
	for s in saidas:
		var texto: String = s[0]
		var acao: Callable = s[1]
		var aviso: String = s[2] if s.size() > 2 else ""
		_item(texto, func():
			if aviso == "":
				acao.call()
			else:
				DialogoPapel.perguntar(self, texto, aviso, "Sair", acao))
	continuar.grab_focus.call_deferred()
	Som.tocar("papel")


## Ajustes de leitura, escala e acessibilidade (docs/16 A1 e A3; docs/18 A4, A5 e A6),
## usados na pausa e na Base.
static func montar_leitura(caixa: Control) -> void:
	var opcoes := [
		["Texto", Preferencias.velocidade_texto, Preferencias.definir_velocidade_texto,
			["lenta", "normal", "instantanea"], {"lenta": "devagar", "normal": "normal", "instantanea": "instantâneo"}],
		["Resultados", Preferencias.tempo_resultado, Preferencias.definir_tempo_resultado,
			["curto", "normal", "clique"], {"curto": "rápidos", "normal": "normais", "clique": "até clicar"}],
	]
	for o in opcoes:
		var b := Button.new()   # botão comum: estes ajustes ficam sobre painel escuro
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var atual: String = o[1].call()
		b.text = "%s: %s" % [o[0], o[4].get(atual, atual)]
		b.pressed.connect(func():
			var lista: Array = o[3]
			var novo: String = lista[(lista.find(o[1].call()) + 1) % lista.size()]
			o[2].call(novo)
			b.text = "%s: %s" % [o[0], o[4].get(novo, novo)])
		caixa.add_child(b)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", Tema.ESPACO_M)
	caixa.add_child(linha)
	var l := Label.new()
	l.text = "Tamanho da interface"
	linha.add_child(l)
	var escala := HSlider.new()
	escala.min_value = 0.8
	escala.max_value = 1.5
	escala.step = 0.1
	escala.value = Preferencias.escala()
	escala.custom_minimum_size = Vector2(150, 0)
	escala.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	linha.add_child(escala)
	var pct := Label.new()
	pct.text = "%d%%" % int(round(escala.value * 100))
	linha.add_child(pct)
	escala.drag_ended.connect(func(_mudou):
		Preferencias.definir_escala(escala.value)
		Tema.aplicar_escala())
	escala.value_changed.connect(func(v): pct.text = "%d%%" % int(round(v * 100)))
	# A5: fotossensibilidade
	var flashes := Button.new()
	flashes.alignment = HORIZONTAL_ALIGNMENT_LEFT
	flashes.tooltip_text = "Suaves: pulsos de VHS fracos e no máximo três trocas por segundo.\nCompletos: a fita trepida como no original.\nPara tirar todos os glitches, desmarque \"Glitch de VHS e tremores\"."
	var nomes_flashes := {"suave": "suaves", "completo": "completos"}
	flashes.text = "Flashes: %s" % nomes_flashes.get(Preferencias.flashes(), "suaves")
	flashes.pressed.connect(func():
		var novo := "completo" if Preferencias.flashes() == "suave" else "suave"
		Preferencias.definir_flashes(novo)
		flashes.text = "Flashes: %s" % nomes_flashes[novo])
	caixa.add_child(flashes)
	# A6: paleta para daltonismo
	var dalt := CheckBox.new()
	dalt.text = "Cores para daltonismo (azul e laranja)"
	dalt.tooltip_text = "Sucesso em azul e falha em laranja, no lugar de verde e vermelho. Os símbolos ✓ e ✗ continuam."
	dalt.button_pressed = Preferencias.daltonismo()
	dalt.toggled.connect(func(v): Preferencias.definir_daltonismo(v))
	caixa.add_child(dalt)
	# A4: folha de atalhos
	var atalhos := Button.new()
	atalhos.alignment = HORIZONTAL_ALIGNMENT_LEFT
	atalhos.text = Atalhos.com_tecla("Atalhos de teclado", "folha_atalhos")
	atalhos.pressed.connect(func(): FolhaAtalhos.abrir(caixa))
	caixa.add_child(atalhos)


func _item(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = "BotaoMenu"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(acao)
	_pasta.add_child(b)
	return b


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
