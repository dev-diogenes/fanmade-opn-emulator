class_name Vela
extends Control
## Uma vela acesa (docs/59): o pavio e a chama que treme, desenhados em código. Vai ao lado de
## cada foto da parede de memória e na despedida.

const TAMANHO := Vector2(22, 56)

var _t := 0.0
var _fase := 0.0


func _init() -> void:
	custom_minimum_size = TAMANHO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fase = randf() * TAU   # cada vela treme no seu tempo


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var base := Vector2(TAMANHO.x / 2.0, TAMANHO.y)
	# A cera, com a gota escorrida
	draw_rect(Rect2(base.x - 6, base.y - 30, 12, 30), Color("e9e1cc"))
	draw_rect(Rect2(base.x + 2, base.y - 30, 3, 9), Color("d8cfb6"))
	draw_line(Vector2(base.x, base.y - 30), Vector2(base.x, base.y - 34), Color("2a2622"), 1.5)
	# A chama: tremor lento e um piscar rápido de leve
	var tremor := sin(_t * 7.0 + _fase) * 0.8 + sin(_t * 17.0 + _fase * 2.0) * 0.4
	var altura := 12.0 + sin(_t * 5.0 + _fase) * 1.5
	var topo := Vector2(base.x + tremor, base.y - 34 - altura)
	var brilho := Color(1.0, 0.75, 0.35, 0.18 + 0.05 * sin(_t * 9.0 + _fase))
	draw_circle(Vector2(base.x, base.y - 40), 11.0, brilho)
	var chama := PackedVector2Array([Vector2(base.x - 3.5, base.y - 35), topo, Vector2(base.x + 3.5, base.y - 35),
		Vector2(base.x, base.y - 32)])
	draw_colored_polygon(chama, Color("ffb547"))
	draw_colored_polygon(PackedVector2Array([Vector2(base.x - 1.5, base.y - 35), topo.lerp(Vector2(base.x, base.y - 35), 0.45),
		Vector2(base.x + 1.5, base.y - 35)]), Color("fff1c4"))
