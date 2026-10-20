class_name Sigilo
extends Control
## Sigilo procedural (docs/09, 5.2). Desenhos ORIGINAIS com a gramática visual dos sigilos
## de OP (círculo, raios, ganchos, arcos, pontos), sem copiar os sigilos oficiais.
## A mesma `semente` gera sempre o mesmo sigilo.

@export var semente := 1:
	set(v):
		semente = v
		_tracos = gerar(v)
		queue_redraw()
@export var cor := Color(Tema.PERGAMINHO, 0.85)
@export var espessura := 2.0
## 0..1: quanto do traço já foi "desenhado" (animação de revelar)
var progresso := 1.0:
	set(v):
		progresso = v
		queue_redraw()

var _tracos: Array = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tracos = gerar(semente)


## Revela o traço em `duracao` segundos.
func revelar(duracao: float = 0.6) -> void:
	progresso = 0.0
	create_tween().tween_property(self, "progresso", 1.0, duracao).set_trans(Tween.TRANS_SINE)


## Linhas do sigilo em coordenadas normalizadas (-1..1). Cada item é uma PackedVector2Array.
static func gerar(p_semente: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_semente * 7919 + 13
	var linhas: Array = []
	var circulo := func(raio: float, inicio: float, fim: float, passos: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in passos + 1:
			var ang: float = lerpf(inicio, fim, float(i) / passos)
			var r: float = raio * (1.0 + rng.randf_range(-0.025, 0.025))
			pts.append(Vector2(cos(ang), sin(ang)) * r)
		return pts
	linhas.append(circulo.call(0.92, 0.0, TAU + 0.15, 40))
	if rng.randf() < 0.45:
		linhas.append(circulo.call(0.8, 0.3, TAU - 0.2, 36))
	var raios := rng.randi_range(3, 7)
	var base := rng.randf() * TAU
	for i in raios:
		var ang := base + TAU * i / raios + rng.randf_range(-0.25, 0.25)
		var dentro := rng.randf_range(0.0, 0.35)
		var fora := rng.randf_range(0.6, 0.92)
		var d := Vector2(cos(ang), sin(ang))
		var raio := PackedVector2Array([d * dentro, d * fora])
		if rng.randf() < 0.55:   # gancho na ponta
			var lado := 1.0 if rng.randf() < 0.5 else -1.0
			raio.append(d * fora + Vector2(-d.y, d.x) * lado * rng.randf_range(0.12, 0.25) - d * 0.08)
		linhas.append(raio)
	for i in rng.randi_range(1, 2):
		var r := rng.randf_range(0.3, 0.55)
		var ini := rng.randf() * TAU
		linhas.append(circulo.call(r, ini, ini + rng.randf_range(1.2, 3.6), 16))
	if rng.randf() < 0.6:   # barra que cruza o centro
		var ang := rng.randf() * TAU
		var d := Vector2(cos(ang), sin(ang))
		linhas.append(PackedVector2Array([-d * 0.55, d * 0.55]))
	return linhas


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	var total := _tracos.size()
	var visiveis := progresso * total
	for i in total:
		if i >= visiveis:
			break
		var linha: PackedVector2Array = _tracos[i]
		var pts := PackedVector2Array()
		var frac := clampf(visiveis - i, 0.0, 1.0)
		var n := maxi(2, int(ceil(linha.size() * frac)))
		for j in mini(n, linha.size()):
			pts.append(c + linha[j] * r)
		if pts.size() >= 2:
			draw_polyline(pts, cor, espessura, true)
	# um ponto ou dois, sempre no fim
	if progresso >= 1.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = semente
		for i in rng.randi_range(0, 2):
			var ang := rng.randf() * TAU
			draw_circle(c + Vector2(cos(ang), sin(ang)) * r * rng.randf_range(0.2, 0.7), espessura * 1.4, cor)


## Textura do sigilo (para usar no 3D ou em TextureRect). Renderiza por código, sem viewport.
static func imagem(p_semente: int, tamanho: int, p_cor: Color, p_espessura: float = 3.0) -> ImageTexture:
	var img := Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(tamanho, tamanho) / 2.0
	var r := tamanho / 2.0 - p_espessura * 2.0
	for linha in gerar(p_semente):
		for j in linha.size() - 1:
			_linha_img(img, c + linha[j] * r, c + linha[j + 1] * r, p_cor, p_espessura)
	return ImageTexture.create_from_image(img)


static func _linha_img(img: Image, a: Vector2, b: Vector2, cor: Color, esp: float) -> void:
	var passos := int(maxf(1.0, a.distance_to(b)))
	var raio := int(ceil(esp / 2.0))
	for i in passos + 1:
		var p := a.lerp(b, float(i) / passos)
		for dx in range(-raio, raio + 1):
			for dy in range(-raio, raio + 1):
				var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and Vector2(dx, dy).length() <= esp / 2.0:
					img.set_pixelv(q, cor)
