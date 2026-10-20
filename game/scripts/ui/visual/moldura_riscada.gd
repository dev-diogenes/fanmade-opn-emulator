class_name MolduraRiscada
extends StyleBox
## Moldura em traço riscado (docs/09, 5.2): fundo chapado e 2–3 traços tortos sobrepostos
## que passam um pouco dos cantos, como desenhados à mão. O desvio usa uma semente
## tirada do tamanho, então o desenho não treme de um quadro para outro.

var fundo := Color(Tema.PEDRA, 0.92)
var traco := Color(Tema.PERGAMINHO, 0.75)
var tracos := 2
var espessura := 1.6
var desvio := 1.6
var escape := 6.0     ## Quanto o traço passa do canto
var sombra := 6


static func criar(p_traco: Color = Color(Tema.PERGAMINHO, 0.75), p_fundo: Color = Color(Tema.PEDRA, 0.92),
		margem := Vector2(14, 10)) -> MolduraRiscada:
	var m := MolduraRiscada.new()
	m.traco = p_traco
	m.fundo = p_fundo
	m.content_margin_left = margem.x
	m.content_margin_right = margem.x
	m.content_margin_top = margem.y
	m.content_margin_bottom = margem.y
	return m


func _draw(item: RID, rect: Rect2) -> void:
	if sombra > 0:
		RenderingServer.canvas_item_add_rect(item, rect.grow(2).grow_individual(0, 0, 2, 3), Color(0, 0, 0, 0.35))
	if fundo.a > 0.0:
		RenderingServer.canvas_item_add_rect(item, rect, fundo)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.size.x * 31.0 + rect.size.y * 17.0)
	for t in tracos:
		var cor := traco
		cor.a *= 1.0 if t == 0 else 0.55
		for lado in 4:
			RenderingServer.canvas_item_add_polyline(item, _lado(rect, lado, rng), [cor], espessura, true)


## Um lado da moldura como linha torta com 4 segmentos, escapando dos cantos.
func _lado(r: Rect2, lado: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var a: Vector2
	var b: Vector2
	match lado:
		0: a = r.position; b = Vector2(r.end.x, r.position.y)
		1: a = Vector2(r.end.x, r.position.y); b = r.end
		2: a = r.end; b = Vector2(r.position.x, r.end.y)
		_: a = Vector2(r.position.x, r.end.y); b = r.position
	var dir := (b - a).normalized()
	a -= dir * rng.randf_range(0.0, escape)
	b += dir * rng.randf_range(0.0, escape)
	var normal := Vector2(-dir.y, dir.x)
	var pontos := PackedVector2Array()
	for i in 5:
		var p := a.lerp(b, i / 4.0)
		pontos.append(p + normal * rng.randf_range(-desvio, desvio))
	return pontos
