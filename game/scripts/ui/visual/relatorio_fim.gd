class_name RelatorioFim
extends CanvasLayer
## Fim de cena como relatório da Ordem (docs/10): a tela escurece, uma folha datilografada
## resume o que aconteceu e um carimbo bate por cima ("CASO ENCERRADO", "AGENTES PERDIDOS"…).
## `rotulo` e `botao` ficam expostos para as telas que já usavam _lbl_fim e _btn_fim.

var rotulo: Label        ## o texto do carimbo
var botao: Button
var _resumo: Label
var _carimbo: Control
var _raiz: Control
## true depois de mostrar(). O CanvasLayer fica sempre visível; quem some é a raiz
## (esconder o CanvasLayer e reexibir não reexibe todos os filhos).
var aberto := false


func _init(texto_botao: String = "Continuar") -> void:
	layer = 90
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.visible = false
	add_child(_raiz)
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.8)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(34, 28)))
	papel.theme = Tema.tema_papel()
	papel.custom_minimum_size = Vector2(520, 320)
	papel.rotation_degrees = 0.6
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_G)
	papel.add_child(v)
	var cab := Label.new()
	cab.text = "ORDEM DA REALIDADE — RELATÓRIO DE OPERAÇÃO"
	cab.add_theme_color_override("font_color", Color(Tema.TINTA, 0.6))
	cab.add_theme_font_size_override("font_size", Tema.FONTE_P)
	v.add_child(cab)
	_resumo = Label.new()
	_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resumo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(_resumo)
	botao = Button.new()
	botao.text = texto_botao
	botao.theme_type_variation = "BotaoPrincipal"
	botao.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(botao)
	# O carimbo fica por cima da folha, torto
	_carimbo = Control.new()   # sem contêiner: o carimbo precisa ficar torto
	_carimbo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_carimbo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_carimbo)
	rotulo = Label.new()
	rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rotulo.add_theme_font_size_override("font_size", 40)
	rotulo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Tema.SANGUE_CLARO, 4, 6, Vector2(18, 6)))
	rotulo.add_theme_color_override("font_color", Tema.SANGUE_CLARO)
	var f := Tema.fonte_titulo()
	if f != null:
		rotulo.add_theme_font_override("font", f)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carimbo.add_child(rotulo)


## Mostra a folha. `sucesso` deixa o carimbo verde-escuro; senão, vermelho-sangue.
func mostrar(carimbo: String, linhas: Array, sucesso: bool) -> void:
	rotulo.text = carimbo
	var cor := Color("2f6b3f") if sucesso else Tema.SANGUE_CLARO
	rotulo.add_theme_color_override("font_color", cor)
	rotulo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), cor, 4, 6, Vector2(18, 6)))
	_resumo.text = "\n".join(PackedStringArray(linhas.map(func(l): return String(l))))
	_raiz.visible = true
	aberto = true
	if not is_inside_tree():
		return
	rotulo.reset_size()
	var tela := _raiz.get_viewport_rect().size
	rotulo.position = tela / 2.0 + Vector2(-rotulo.size.x / 2.0 + 70.0, 40.0)
	Tema.datilografar(_resumo, 0.02, 1.8)
	# O carimbo "bate" depois do texto
	rotulo.modulate.a = 0.0
	rotulo.pivot_offset = rotulo.size / 2.0
	rotulo.rotation_degrees = -14
	rotulo.scale = Vector2.ONE * 1.8
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(rotulo, "modulate:a", 0.88, 0.01)
	tw.parallel().tween_callback(func(): Som.tocar("carimbo")).set_delay(0.14)
	tw.parallel().tween_property(rotulo, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	botao.grab_focus.call_deferred()
