class_name BarraMembrana
extends ProgressBar
## A Membrana como uma barra que racha (docs/10): quanto mais ela cai, mais rachaduras
## escuras atravessam a barra, e abaixo de 25 elas brilham em vermelho e tremem.

var _tempo := 0.0


func _init() -> void:
	show_percentage = false
	max_value = 100
	value_changed.connect(func(_v): queue_redraw())


func _process(delta: float) -> void:
	if value < 25 and Preferencias.efeito("glitch"):
		_tempo += delta
		queue_redraw()


func _draw() -> void:
	var dano := clampf((100.0 - value) / 100.0, 0.0, 1.0)
	var quantas := int(round(dano * 9.0))
	if quantas == 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	var critico := value < 25
	var cor := Tema.SANGUE_CLARO.lightened(0.2) if critico else Color(0, 0, 0, 0.75)
	for i in quantas:
		# Cada rachadura desce em zigue-zague de cima a baixo, com um galho de vez em quando
		var x := rng.randf_range(4.0, size.x - 4.0)
		var pts := PackedVector2Array([Vector2(x, 0)])
		var y := 0.0
		while y < size.y:
			y = minf(size.y, y + rng.randf_range(2.0, 5.0))
			x += rng.randf_range(-4.0, 4.0)
			pts.append(Vector2(x, y))
		if critico:
			var tremor := Vector2(sin(_tempo * 40.0 + i) * 0.8, 0)
			for k in pts.size():
				pts[k] += tremor
		draw_polyline(pts, cor, 1.4, true)
		if rng.randf() < 0.5:
			var meio := pts[pts.size() / 2]
			draw_line(meio, meio + Vector2(rng.randf_range(-9, 9), rng.randf_range(-4, 4)), cor, 1.0, true)
