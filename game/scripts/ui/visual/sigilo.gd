class_name Sigilo
extends Control
## Sigilo procedural (docs/09, 5.2). Desenhos ORIGINAIS com a gramática visual dos sigilos
## de OP (círculo, raios, ganchos, arcos, pontos), sem copiar os sigilos oficiais.
## A mesma `semente` gera sempre o mesmo sigilo.
## Com `elemento` (docs/77), o miolo segue a gramática que a wiki descreve para o elemento
## (bifurcações no Sangue, espiral na Morte, glifos encadeados no Conhecimento, raio torto na
## Energia, gancho e círculo no Medo), em desenho próprio; `forma` põe mais anéis (discente e
## verdadeiro). `glifo(i)` é a letra i do alfabeto de sigilos do jogo (veja `Cifra`).

const ELEMENTOS := ["sangue", "morte", "conhecimento", "energia", "medo"]
## Forma do ritual -> quantos anéis a mais (indouta 0, discente 1, verdadeiro 2)
const FORMAS := {"": 0, "discente": 1, "verdadeiro": 2}

@export var semente := 1:
	set(v):
		semente = v
		_regenerar()
@export var elemento := "":
	set(v):
		elemento = v
		_regenerar()
@export var forma := 0:
	set(v):
		forma = v
		_regenerar()
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


func _regenerar() -> void:
	_tracos = gerar_de(semente, elemento, forma)
	queue_redraw()


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
static func imagem(p_semente: int, tamanho: int, p_cor: Color, p_espessura: float = 3.0, p_elemento: String = "", p_forma: int = 0) -> ImageTexture:
	return imagem_de_linhas(gerar_de(p_semente, p_elemento, p_forma), tamanho, p_cor, p_espessura)


## Textura da letra `i` do alfabeto de sigilos.
static func imagem_glifo(i: int, tamanho: int, p_cor: Color, p_espessura: float = 3.0) -> ImageTexture:
	return imagem_de_linhas(glifo(i), tamanho, p_cor, p_espessura)


static func imagem_de_linhas(linhas: Array, tamanho: int, p_cor: Color, p_espessura: float) -> ImageTexture:
	var img := Image.create(tamanho, tamanho, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(tamanho, tamanho) / 2.0
	var r := tamanho / 2.0 - p_espessura * 2.0
	for linha in linhas:
		for j in linha.size() - 1:
			_linha_img(img, c + linha[j] * r, c + linha[j + 1] * r, p_cor, p_espessura)
	return ImageTexture.create_from_image(img)


## O sigilo genérico (só semente) ou o de um elemento, com a forma do ritual.
static func gerar_de(p_semente: int, p_elemento: String = "", p_forma: int = 0) -> Array:
	if p_elemento in ELEMENTOS:
		return gerar_elemento(p_elemento, p_semente, p_forma)
	return gerar(p_semente)


## O sigilo de um ritual: elemento e forma vêm do ritual; a semente, do id.
static func de_ritual(ritual: Dictionary, p_forma: String = "") -> Dictionary:
	return {"semente": absi(hash(String(ritual.get("id", "")))) % 100000, "elemento": String(ritual.get("elemento", "")),
		"forma": int(FORMAS.get(p_forma, 0))}


static func _arco(raio: float, inicio: float, fim: float, passos: int, centro := Vector2.ZERO) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in passos + 1:
		var ang: float = lerpf(inicio, fim, float(i) / passos)
		pts.append(centro + Vector2(cos(ang), sin(ang)) * raio)
	return pts


## Sigilo de elemento (docs/77): anéis pela forma, o miolo do elemento e uma assinatura de dois a
## quatro glifos do alfabeto em volta, como os símbolos de culto e de relíquia da lore, que juntam o
## traço do elemento a sigilos do Conhecimento.
static func gerar_elemento(p_elemento: String, p_semente: int, p_forma: int = 0) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_semente * 7919 + absi(hash(p_elemento))
	var linhas: Array = []
	# Anel de fora, aberto num ponto; cada forma a mais põe um anel por dentro (com marcas entre eles)
	var abertura := rng.randf() * TAU
	linhas.append(_arco(0.94, abertura + 0.25, abertura + TAU - 0.05, 44))
	for k in clampi(p_forma, 0, 2):
		var r := 0.94 - 0.1 * (k + 1)
		linhas.append(_arco(r, 0.0, TAU, 40))
		var marcas := 6 + 2 * k
		for m in marcas:
			var ang := TAU * m / marcas + rng.randf_range(-0.1, 0.1)
			var d := Vector2(cos(ang), sin(ang))
			linhas.append(PackedVector2Array([d * r, d * (r + 0.1)]))
	# O miolo do elemento
	var miolo := _radical(p_elemento, rng)
	var escala := 0.62 - 0.06 * clampi(p_forma, 0, 2)
	for linha in miolo:
		var pts := PackedVector2Array()
		for q in linha:
			pts.append(q * escala)
		linhas.append(pts)
	# A assinatura: glifos do alfabeto num arco por dentro do anel
	var n := rng.randi_range(2, 4)
	var raio_g := 0.78 - 0.1 * clampi(p_forma, 0, 2)
	var inicio := rng.randf() * TAU
	for g in n:
		var ang := inicio + g * 0.42
		var centro := Vector2(cos(ang), sin(ang)) * raio_g
		for linha in glifo(rng.randi_range(0, 25)):
			var pts := PackedVector2Array()
			for q in linha:
				pts.append(centro + q * 0.09)
			linhas.append(pts)
	return linhas


## O miolo de cada elemento, em -1..1 (y para baixo). A gramática vem da descrição da wiki; o
## desenho é do jogo, com variação pela semente.
static func _radical(p_elemento: String, rng: RandomNumberGenerator) -> Array:
	var l: Array = []
	match p_elemento:
		"sangue":
			# Haste vertical com bifurcações que descem como veias, e uma gota no pé
			l.append(PackedVector2Array([Vector2(0, -0.95), Vector2(0, 0.7)]))
			var pares := rng.randi_range(2, 3)
			for i in pares:
				var y := lerpf(-0.6, 0.45, float(i) / maxf(1, pares - 1))
				var abre := rng.randf_range(0.35, 0.6)
				var cai := rng.randf_range(0.25, 0.45)
				l.append(PackedVector2Array([Vector2(-abre, y + cai), Vector2(0, y), Vector2(abre * rng.randf_range(0.8, 1.1), y + cai)]))
			l.append(_arco(0.13, 0.0, TAU, 14, Vector2(0, 0.86)))
		"morte":
			# Espiral que fecha para dentro, com riscos ao longo dela, como marcas de tempo
			var voltas := rng.randf_range(1.6, 2.3)
			var pts := PackedVector2Array()
			var passos := 60
			for i in passos + 1:
				var t := float(i) / passos
				var ang := -TAU * voltas * t
				pts.append(Vector2(cos(ang), sin(ang)) * lerpf(0.95, 0.08, t))
			l.append(pts)
			for i in rng.randi_range(4, 6):
				var t := rng.randf_range(0.1, 0.7)
				var ang := -TAU * voltas * t
				var d := Vector2(cos(ang), sin(ang))
				var r := lerpf(0.95, 0.08, t)
				l.append(PackedVector2Array([d * (r - 0.1), d * (r + 0.1)]))
			l.append(PackedVector2Array([Vector2(-0.18, 0), Vector2(0.18, 0)]))
		"conhecimento":
			# Um olho fechado no meio e glifos encadeados numa volta em torno dele
			l.append(_arco(0.2, PI, TAU, 12))
			l.append(_arco(0.2, 0.0, PI, 12))
			var n := rng.randi_range(5, 7)
			for i in n:
				var ang := TAU * i / n - PI / 2.0
				var centro := Vector2(cos(ang), sin(ang)) * 0.62
				for linha in glifo(rng.randi_range(0, 25)):
					var pts := PackedVector2Array()
					for q in linha:
						pts.append(centro + q * 0.2)
					l.append(pts)
			l.append(_arco(0.62, 0.0, TAU, 36))
		"energia":
			# Um raio torto de baixo para cima e dois "V" abertos, desencontrados
			var raio := PackedVector2Array()
			var segs := rng.randi_range(4, 6)
			for i in segs + 1:
				var t := float(i) / segs
				raio.append(Vector2(lerpf(-0.55, 0.5, t) + (0.22 if i % 2 == 1 else -0.08) * rng.randf_range(0.6, 1.3), lerpf(0.9, -0.9, t)))
			l.append(raio)
			var dx := rng.randf_range(-0.2, 0.2)
			l.append(PackedVector2Array([Vector2(-0.8 + dx, -0.35), Vector2(-0.1 + dx, 0.3), Vector2(0.75 + dx, -0.5)]))
			l.append(PackedVector2Array([Vector2(-0.5 - dx, 0.65), Vector2(0.05 - dx, 0.15), Vector2(0.45 - dx, 0.7)]))
		"medo":
			# Um gancho que se enrola em cima, com um círculo na ponta; um arco partido do outro lado
			var gancho := PackedVector2Array([Vector2(0.1, 0.9), Vector2(0.1, -0.2)])
			gancho.append_array(_arco(0.35, 0.0, -PI * 1.4, 16, Vector2(-0.25, -0.2)))
			l.append(gancho)
			var fim := Vector2(-0.25, -0.2) + Vector2(cos(-PI * 1.4), sin(-PI * 1.4)) * 0.35
			l.append(_arco(0.1, 0.0, TAU, 12, fim))
			var ini := rng.randf_range(0.2, 0.6)
			l.append(_arco(0.75, ini, ini + 1.1, 14))
			l.append(_arco(0.75, ini + 1.5, ini + 2.4, 12))
			for i in 3:
				l.append(_arco(0.045, 0.0, TAU, 8, Vector2(rng.randf_range(-0.6, 0.6), rng.randf_range(0.2, 0.7))))
	return l


## A letra `i` (0..25) do alfabeto de sigilos do jogo: uma haste com uma marca em cima e outra
## no meio ou embaixo. São 6 x 5 combinações; as 26 primeiras são as letras. Em -1..1.
static func glifo(i: int) -> Array:
	var i_ := posmod(i, 26)
	var cima := i_ % 6
	var baixo := i_ / 6
	var l: Array = [PackedVector2Array([Vector2(0, -0.8), Vector2(0, 0.85)])]
	match cima:
		0: l.append(PackedVector2Array([Vector2(0, -0.8), Vector2(-0.45, -0.8), Vector2(-0.45, -0.45)]))
		1: l.append(PackedVector2Array([Vector2(0, -0.8), Vector2(0.45, -0.8), Vector2(0.45, -0.45)]))
		2: l.append(_arco(0.2, 0.0, TAU, 10, Vector2(0, -0.95)))
		3: l.append(PackedVector2Array([Vector2(-0.5, -0.8), Vector2(0.5, -0.8)]))
		4: l.append(PackedVector2Array([Vector2(-0.45, -1.0), Vector2(0, -0.55), Vector2(0.45, -1.0)]))
		5: l.append(PackedVector2Array([Vector2(-0.4, -0.4), Vector2(0, -0.8), Vector2(0.4, -0.4)]))
	match baixo:
		1: l.append(PackedVector2Array([Vector2(-0.4, 0.05), Vector2(0.4, 0.05)]))
		2: l.append(_arco(0.18, 0.0, TAU, 10, Vector2(0, 0.85)))
		3: l.append(PackedVector2Array([Vector2(-0.4, 0.35), Vector2(0.4, -0.15)]))
		4: l.append(PackedVector2Array([Vector2(0, 0.85), Vector2(0.4, 0.85), Vector2(0.4, 0.5)]))
	return l


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
