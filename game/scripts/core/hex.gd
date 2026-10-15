class_name Hex
extends RefCounted
## Matemática de hexágonos em coordenadas axiais (q, r), "pointy-top".
## Referência: redblobgames.com/grids/hexagons. Vector2i(q, r).

const DIRECOES: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]


static func vizinhos(h: Vector2i) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for d in DIRECOES:
		lista.append(h + d)
	return lista


static func distancia(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (absi(dq) + absi(dq + dr) + absi(dr)) / 2


## Todos os hexes a até `raio` de `centro`.
static func area(centro: Vector2i, raio: int) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	for q in range(-raio, raio + 1):
		for r in range(maxi(-raio, -q - raio), mini(raio, -q + raio) + 1):
			lista.append(centro + Vector2i(q, r))
	return lista


## Coluna/linha "odd-r" (retângulo na tela) -> axial.
static func de_offset(coluna: int, linha: int) -> Vector2i:
	return Vector2i(coluna - (linha - (linha & 1)) / 2, linha)


## Axial -> coluna/linha "odd-r".
static func para_offset(h: Vector2i) -> Vector2i:
	return Vector2i(h.x + (h.y - (h.y & 1)) / 2, h.y)


## Centro do hex em pixels, para hexes de raio `tamanho`.
static func para_pixel(h: Vector2i, tamanho: float) -> Vector2:
	return Vector2(tamanho * sqrt(3.0) * (h.x + h.y / 2.0), tamanho * 1.5 * h.y)


static func de_pixel(p: Vector2, tamanho: float) -> Vector2i:
	var q := (sqrt(3.0) / 3.0 * p.x - p.y / 3.0) / tamanho
	var r := (2.0 / 3.0 * p.y) / tamanho
	return arredondar(q, r)


static func arredondar(qf: float, rf: float) -> Vector2i:
	var sf := -qf - rf
	var q := roundi(qf)
	var r := roundi(rf)
	var s := roundi(sf)
	var dq := absf(q - qf)
	var dr := absf(r - rf)
	var ds := absf(s - sf)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(q, r)


## Os 6 vértices do hex (para desenhar).
static func vertices(centro_px: Vector2, tamanho: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var ang := deg_to_rad(60.0 * i - 30.0)
		pts.append(centro_px + Vector2(cos(ang), sin(ang)) * tamanho)
	return pts
