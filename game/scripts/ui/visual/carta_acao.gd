class_name CartaAcao
extends Button
## Carta de ação (docs/09, 5.2): papel, sigilo no topo, título em Cinzel e dica curta.
## Sobe no hover; borda dourada quando selecionada; atalho numérico no canto.

const TAMANHO := Vector2(132, 176)

var selecionada := false:
	set(v):
		selecionada = v
		_atualizar_estilo()
var _sigilo: Sigilo
var _y_base := 0.0
var _subindo: Tween


static func criar(titulo: String, dica: String, atalho: int, semente: int, cor: Color) -> CartaAcao:
	var c := CartaAcao.new()
	c.custom_minimum_size = TAMANHO
	c.focus_mode = Control.FOCUS_ALL
	c.tooltip_text = "%s (%d)" % [dica, atalho]
	c.set_meta("dica", c.tooltip_text)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 10
	v.offset_bottom = -8
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(v)
	c._sigilo = Sigilo.new()
	c._sigilo.semente = semente
	c._sigilo.cor = cor
	c._sigilo.espessura = 2.4
	c._sigilo.custom_minimum_size = Vector2(0, 82)
	v.add_child(c._sigilo)
	var t := Label.new()
	t.text = titulo.to_upper()
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", 15)
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	var d := Label.new()
	d.text = dica
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_color_override("font_color", Color(Tema.TINTA, 0.7))
	d.add_theme_font_size_override("font_size", 13)
	v.add_child(d)
	var n := Label.new()
	n.text = str(atalho)
	n.position = Vector2(8, 4)
	n.add_theme_color_override("font_color", Color(Tema.TINTA, 0.7))
	n.add_theme_font_size_override("font_size", 13)
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(n)
	c.mouse_entered.connect(c._subir.bind(true))
	c.mouse_exited.connect(c._subir.bind(false))
	c._atualizar_estilo()
	return c


func _atualizar_estilo() -> void:
	var papel := Tema.caixa_papel()
	for estado in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, papel)
	if selecionada:
		var borda := Tema.caixa(Color(0, 0, 0, 0), Tema.OURO_CLARO, 3, 4)
		borda.draw_center = false
		add_theme_stylebox_override("focus", borda)
	else:
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	queue_redraw()


func _draw() -> void:
	# Sombra e, se selecionada, borda dourada desenhada por cima do papel
	if selecionada:
		draw_rect(Rect2(Vector2.ZERO, size), Tema.OURO_CLARO, false, 3.0)
	if disabled:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
		# Cadeado (docs/16, A2): "indisponível" não depende só do cinza; o motivo vai no tooltip
		var c := Vector2(size.x - 18, 18)
		draw_arc(c + Vector2(0, -2), 5, PI, TAU, 10, Tema.PERGAMINHO, 2.0, true)
		draw_rect(Rect2(c + Vector2(-7, -1), Vector2(14, 10)), Tema.PERGAMINHO)


func _subir(sim: bool) -> void:
	if disabled:
		return
	if _subindo != null:
		_subindo.kill()
	_subindo = create_tween()
	_subindo.tween_property(self, "position:y", -12.0 if sim or selecionada else 0.0, 0.12).set_trans(Tween.TRANS_SINE)
