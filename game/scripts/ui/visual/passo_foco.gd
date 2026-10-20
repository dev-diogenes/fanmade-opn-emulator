class_name PassoFoco
extends HBoxContainer
## Foco (PE → +1 d20) como − n + (docs/09): substitui o SpinBox nas telas de jogo.
## `sobre_papel` usa a tinta escura dos bilhetes.

signal mudou(valor: int)

var valor := 0
var maximo := 0
var _menos: Button
var _mais: Button
var _numero: Label


static func criar(sobre_papel: bool = false) -> PassoFoco:
	var p := PassoFoco.new()
	p.add_theme_constant_override("separation", 4)
	var l := Label.new()
	l.text = "Foco"
	l.tooltip_text = "Gaste PE para rolar mais d20 (1 PE = +1 dado)"
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	if sobre_papel:
		l.theme_type_variation = "TextoPapel"
	p.add_child(l)
	p._menos = Button.new()
	p._menos.text = " − "
	p._menos.pressed.connect(func(): p.definir(p.valor - 1, p.maximo))
	p.add_child(p._menos)
	p._numero = Label.new()
	p._numero.custom_minimum_size = Vector2(44, 0)
	p._numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(p._numero)
	p._mais = Button.new()
	p._mais.text = " + "
	p._mais.pressed.connect(func(): p.definir(p.valor + 1, p.maximo))
	p.add_child(p._mais)
	if sobre_papel:
		for b in [p._menos, p._mais]:
			b.theme_type_variation = "BotaoPapel"
		p._numero.theme_type_variation = "TextoPapel"
	p.definir(0, 0)
	return p


func definir(p_valor: int, p_maximo: int) -> void:
	maximo = maxi(0, p_maximo)
	var novo := clampi(p_valor, 0, maximo)
	var mudou_valor := novo != valor
	valor = novo
	_numero.text = "%d / %d" % [valor, maximo]
	_menos.disabled = valor <= 0
	_mais.disabled = valor >= maximo
	if mudou_valor:
		mudou.emit(valor)


## Lê e zera (o Foco vale para um teste só).
func consumir() -> int:
	var v := valor
	definir(0, maximo)
	return v
