class_name CartaoChefe
extends CanvasLayer
## Apresentação do chefe (docs/58, AU2 do relatório): ao abrir o combate do covil, uma ficha de
## dossiê com o lugar, o nome, o elemento (carimbado se o grupo o confirmou; "?" se não), a
## fraqueza que o ciclo dos elementos dá e o Enigma de Medo. Some sozinha ou com um clique.
## A mesma folha, menor e em vermelho, anuncia a virada na metade dos PV.
##   CartaoChefe.apresentar(self, {"local", "nome", "elemento", "fraqueza", "enigma"}, ao_fechar)
##   CartaoChefe.anunciar_virada(self, texto, elemento)

const DURACAO := 5.0
const DURACAO_VIRADA := 3.2

var ao_fechar: Callable
var _papel: PanelContainer
var _textos: Array[Label] = []
var _fechando := false
var _duracao := DURACAO


static func apresentar(pai: Node, info: Dictionary, p_ao_fechar: Callable = Callable()) -> CartaoChefe:
	var c := CartaoChefe.new()
	c.name = "CartaoChefe"
	c.ao_fechar = p_ao_fechar
	c.add_to_group("papel_modal")   # o tour do combate espera a apresentação (docs/57)
	c._montar(info)
	pai.add_child(c)
	return c


static func anunciar_virada(pai: Node, texto: String, elemento: String = "") -> CartaoChefe:
	var c := CartaoChefe.new()
	c.name = "CartaoVirada"
	c._duracao = DURACAO_VIRADA
	c._montar_virada(texto, elemento)
	pai.add_child(c)
	return c


func _raiz() -> Control:
	layer = 76
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	_papel = PanelContainer.new()
	_papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(26, 18)))
	_papel.theme = Tema.tema_papel()
	_papel.anchor_left = 0.5
	_papel.anchor_right = 0.5
	_papel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_papel.offset_top = 150
	_papel.rotation_degrees = 0.7
	_papel.mouse_filter = Control.MOUSE_FILTER_STOP
	_papel.tooltip_text = "Clique para fechar"
	_papel.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: fechar())
	raiz.add_child(_papel)
	return raiz


func _montar(info: Dictionary) -> void:
	_raiz()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	v.custom_minimum_size = Vector2(520, 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papel.add_child(v)
	var local := String(info.get("local", ""))
	v.add_child(_linha("COVIL · " + (local.to_upper() if local != "" else "LOCAL DESCONHECIDO"), Color(Tema.TINTA, 0.7)))
	var cab := HBoxContainer.new()
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cab)
	var nome := _linha(String(info.get("nome", "")).to_upper(), Tema.SANGUE)
	nome.autowrap_mode = TextServer.AUTOWRAP_OFF
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.add_theme_font_size_override("font_size", Tema.FONTE_G + 8)
	var ft := Tema.fonte_titulo()
	if ft != null:
		nome.add_theme_font_override("font", ft)
	cab.add_child(nome)
	var el := String(info.get("elemento", ""))
	cab.add_child(_carimbo(el.to_upper() if el != "" else "ELEMENTO ?", Tema.ELEMENTO.get(el, Color(Tema.TINTA, 0.6)) if el != "medo" else Tema.TINTA))
	var fraqueza := String(info.get("fraqueza", ""))
	if el != "" and fraqueza != "":
		v.add_child(_linha("Fraqueza: %s. O ciclo dos elementos diz o que o fere em dobro." % fraqueza.capitalize(), Color(Tema.TINTA, 0.85)))
	elif el == "":
		v.add_child(_linha("O relatório ainda não confirmou o elemento: o que o fere é um palpite.", Color(Tema.TINTA, 0.7)))
	var enigma := String(info.get("enigma", ""))
	if enigma != "":
		var e := _linha("Enigma de Medo: " + enigma, Tema.TINTA)
		var maquina := Tema.fonte_maquina()
		if maquina != null:
			e.add_theme_font_override("font", maquina)
		v.add_child(e)
		_textos.append(e)
		v.add_child(_linha("Enquanto ninguém resolver, ele se refaz a cada turno.", Color(Tema.SANGUE, 0.85)))


func _montar_virada(texto: String, elemento: String) -> void:
	_raiz()
	_papel.offset_top = 170
	_papel.rotation_degrees = -1.2
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	v.custom_minimum_size = Vector2(440, 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papel.add_child(v)
	var t := _linha("VIRADA", Tema.ELEMENTO.get(elemento, Tema.SANGUE) if elemento != "medo" else Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 6)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	v.add_child(t)
	var l := _linha(texto, Tema.TINTA)
	v.add_child(l)
	_textos.append(l)


func _linha(texto: String, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _carimbo(texto: String, cor: Color) -> Label:
	var c := Label.new()
	c.text = texto
	c.add_theme_color_override("font_color", cor)
	c.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), cor, 3, 4, Vector2(10, 2)))
	c.add_theme_font_size_override("font_size", Tema.FONTE_M + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		c.add_theme_font_override("font", ft)
	c.rotation_degrees = -6
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _ready() -> void:
	Som.tocar("carimbo" if name == "CartaoVirada" else "encontro")
	for l in _textos:
		Tema.datilografar(l, 0.015, 1.6)
	_papel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(_duracao)
	tw.tween_callback(fechar)


func fechar() -> void:
	if _fechando or not is_inside_tree():
		return
	_fechando = true
	remove_from_group("papel_modal")
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		if ao_fechar.is_valid():
			ao_fechar.call()
		queue_free())
