class_name CloseupPista
extends CanvasLayer
## O momento da pista (docs/56): quando um agente acha algo, a câmera chega perto do objeto e um
## bilhete mostra o que foi achado. Com que lente (a lanterna, a câmera modificada, o pó de
## sigilos…), um sentido além da visão (o cheiro do elemento, como pede o livro na p.161), o texto
## datilografado e o traço carimbado. Some sozinho ou com um clique; não bloqueia o jogo.
##   CloseupPista.mostrar(self, {"titulo", "lente", "sentido", "texto", "rotulo", "duvidosa"}, ao_fechar)

const DURACAO := 4.5

var ao_fechar: Callable
var _papel: PanelContainer
var _textos: Array[Label] = []
var _fechando := false


static func mostrar(pai: Node, info: Dictionary, p_ao_fechar: Callable = Callable()) -> CloseupPista:
	for antigo in pai.find_children("*", "CloseupPista", false, false):
		antigo.queue_free()
	var c := CloseupPista.new()
	c.name = "CloseupPista"
	c.ao_fechar = p_ao_fechar
	c._montar(info)
	pai.add_child(c)
	return c


func _montar(info: Dictionary) -> void:
	layer = 74
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	_papel = PanelContainer.new()
	_papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(22, 16)))
	_papel.theme = Tema.tema_papel()
	_papel.anchor_left = 0.5
	_papel.anchor_right = 0.5
	_papel.offset_left = -300
	_papel.offset_right = 300
	_papel.offset_top = 96
	_papel.rotation_degrees = -0.8
	_papel.mouse_filter = Control.MOUSE_FILTER_STOP
	_papel.tooltip_text = "Clique para fechar"
	_papel.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: fechar())
	raiz.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papel.add_child(v)
	var cab := HBoxContainer.new()
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cab)
	var t := Label.new()
	t.text = ("DEPOIMENTO · " if info.get("duvidosa", false) else "PISTA · ") + String(info.get("titulo", "")).to_upper()
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_color_override("font_color", Tema.TINTA)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	cab.add_child(t)
	var rotulo := String(info.get("rotulo", ""))
	if rotulo != "":
		var selo := Label.new()
		var duvida: bool = info.get("duvidosa", false)
		selo.text = ("? " if duvida else "✔ ") + rotulo.to_upper()
		var cor := Tema.AVISO if duvida else Tema.cor_sucesso(true)
		selo.add_theme_color_override("font_color", cor)
		selo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), cor, 2, 3, Vector2(6, 1)))
		if ft != null:
			selo.add_theme_font_override("font", ft)
		selo.rotation_degrees = -5
		cab.add_child(selo)
	var simbolo: Dictionary = info.get("simbolo", {})
	if not simbolo.is_empty():   # docs/73: o símbolo do culto, na cor do elemento
		var tr := TextureRect.new()
		tr.texture = Sigilo.imagem(int(simbolo.semente), 96, Tema.ELEMENTO.get(String(simbolo.elemento), Tema.TINTA), 4.0, String(simbolo.elemento))
		tr.custom_minimum_size = Vector2(72, 72)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cab.add_child(tr)
	if not (simbolo.get("cifra", []) as Array).is_empty():
		v.add_child(_anel_lido(simbolo))
	var lente := String(info.get("lente", ""))
	if lente != "":
		var l := _linha("Com %s." % lente, Color(Tema.TINTA, 0.7))
		v.add_child(l)
	var sentido := String(info.get("sentido", ""))
	if sentido != "":
		var s := _linha(sentido, Color(Tema.SANGUE, 0.85))
		var maquina := Tema.fonte_maquina()
		if maquina != null:
			s.add_theme_font_override("font", maquina)
		v.add_child(s)
		_textos.append(s)
	var corpo := _linha(String(info.get("texto", "")), Tema.TINTA)
	corpo.custom_minimum_size = Vector2(560, 0)
	v.add_child(corpo)
	_textos.append(corpo)
	var noticia := String(info.get("noticia", ""))
	if noticia != "":   # docs/73: a manchete do vilão no celular da testemunha
		var n := _linha(noticia, Color("1f5c58"))
		n.custom_minimum_size = Vector2(560, 0)
		v.add_child(n)
		_textos.append(n)


## O anel do símbolo lido (docs/77): cada sigilo com a letra embaixo, e quantas letras novas
## entram na tabela da Ordem.
func _anel_lido(simbolo: Dictionary) -> Control:
	var caixa := VBoxContainer.new()
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fila := HFlowContainer.new()
	fila.add_theme_constant_override("h_separation", 2)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(fila)
	var leitura := String(simbolo.get("leitura", ""))
	var cifra: Array = simbolo.cifra
	for k in cifra.size():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.custom_minimum_size = Vector2(28, 0)
		if int(cifra[k]) >= 0:
			var g := TextureRect.new()
			g.texture = Sigilo.imagem_glifo(int(cifra[k]), 56, Tema.TINTA, 4.0)
			g.custom_minimum_size = Vector2(28, 32)
			g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			g.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(g)
		var letra := Label.new()
		letra.text = leitura.substr(k, 1) if k < leitura.length() else ""
		letra.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letra.add_theme_color_override("font_color", Tema.TINTA)
		letra.add_theme_font_size_override("font_size", Tema.FONTE_P)
		col.add_child(letra)
		fila.add_child(col)
	var novas := int(simbolo.get("novas", 0))
	if novas > 0:
		caixa.add_child(_linha("Tabela de sigilos da Ordem: %d letra%s nova%s." % [novas, "" if novas == 1 else "s", "" if novas == 1 else "s"], Color(Tema.TINTA, 0.7)))
	return caixa


func _linha(texto: String, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _ready() -> void:
	Som.tocar("papel")
	for l in _textos:
		Tema.datilografar(l, 0.02, 1.4)
	_papel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 1.0, 0.2)
	tw.tween_interval(DURACAO)
	tw.tween_callback(fechar)


func fechar() -> void:
	if _fechando or not is_inside_tree():
		return
	_fechando = true
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		if ao_fechar.is_valid():
			ao_fechar.call()
		queue_free())
