class_name BilheteDesfecho
extends CanvasLayer
## Desfecho de um evento (docs/16, E1): depois da rolagem, um bilhete diz o que aconteceu
## e mostra os efeitos como selos (−3 PV, +2 PE, Membrana −2, Covil revelado). Some sozinho
## ou fica até um clique, conforme a preferência de tempo da rolagem (A3).

var _raiz: Control


static func mostrar(pai: Node, titulo: String, texto: String, efeitos: Array, sucesso: Variant, atraso: float = 0.0) -> BilheteDesfecho:
	for antigo in pai.find_children("*", "BilheteDesfecho", false, false):
		antigo.queue_free()
	var b := BilheteDesfecho.new()
	b.name = "BilheteDesfecho"
	b._montar(titulo, texto, efeitos, sucesso)
	pai.add_child(b)
	b._raiz.visible = false
	b._aparecer(atraso)
	return b


func _montar(titulo: String, texto: String, efeitos: Array, sucesso) -> void:
	layer = 72
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(22, 16)))
	papel.theme = Tema.tema_papel()
	papel.anchor_left = 0.5
	papel.anchor_right = 0.5
	papel.anchor_top = 1.0
	papel.anchor_bottom = 1.0
	papel.offset_left = -260
	papel.offset_right = 260
	papel.offset_bottom = -150
	papel.offset_top = -150
	papel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	papel.rotation_degrees = 0.6
	papel.mouse_filter = Control.MOUSE_FILTER_STOP
	papel.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _fechar())
	papel.tooltip_text = "Clique para fechar"
	_raiz.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	papel.add_child(v)
	var cab := HBoxContainer.new()
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cab)
	var t := Label.new()
	t.text = ("DESFECHO · " + titulo).to_upper()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	cab.add_child(t)
	if sucesso != null:
		var selo := Label.new()
		selo.text = "SUCESSO" if sucesso else "FALHA"
		var cor := Tema.cor_sucesso(true) if sucesso else Tema.cor_falha(true)
		selo.add_theme_color_override("font_color", cor)
		selo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), cor, 2, 3, Vector2(6, 1)))
		if f != null:
			selo.add_theme_font_override("font", f)
		selo.rotation_degrees = -6
		cab.add_child(selo)
	var corpo := Label.new()
	corpo.text = texto if texto != "" else "Nada de especial acontece."
	corpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	corpo.custom_minimum_size = Vector2(470, 0)
	v.add_child(corpo)
	if not efeitos.is_empty():
		var linha := HFlowContainer.new()
		linha.add_theme_constant_override("h_separation", 8)
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(linha)
		for ef in efeitos:
			linha.add_child(_selo_efeito(ef))
	_corpo = corpo


var _corpo: Label


## Um selo por efeito: vermelho para perda, verde para ganho (laranja e azul na paleta para
## daltonismo, docs/18), roxo para a Membrana e o mapa.
func _selo_efeito(ef: Dictionary) -> Label:
	var l := Label.new()
	l.text = String(ef.get("texto", ""))
	var tipo := String(ef.get("tipo", ""))
	var cor := Color("5b2a86")
	if tipo in ["dano", "dano_mental"]:
		cor = Tema.cor_falha(true)
	elif tipo in ["cura", "recupera_pe", "recupera_san"]:
		cor = Tema.cor_sucesso(true)
	elif tipo == "membrana":
		cor = Tema.cor_falha(true) if int(ef.get("valor", 0)) < 0 else Tema.cor_sucesso(true)
	elif tipo == "pista":
		cor = Color("7a5a1e")   # o ouro escuro das pistas do quadro (docs/32)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_stylebox_override("normal", Tema.caixa(cor, cor.darkened(0.3), 1, 4, Vector2(8, 2)))
	return l


func _aparecer(atraso: float) -> void:
	var tw := create_tween()
	if atraso > 0.0:
		tw.tween_interval(atraso)
	tw.tween_callback(func():
		_raiz.visible = true
		Som.tocar("papel")
		Tema.datilografar(_corpo))
	var ficar := Tema.duracao_resultado(4.0)
	if ficar > 0.0:
		tw.tween_interval(ficar)
		tw.tween_callback(_fechar)


func _unhandled_input(evento: InputEvent) -> void:
	if _raiz.visible and (evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_fechar()


func _fechar() -> void:
	if is_queued_for_deletion():
		return
	var tw := create_tween()
	tw.tween_property(_raiz, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
