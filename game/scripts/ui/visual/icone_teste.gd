class_name IconeTeste
extends Control
## O símbolo de um teste (docs/66): o dos cinco atributos e o de cada perícia, desenhados em
## código como os outros ícones do jogo. Vai no cabeçalho da rolagem (a perícia) e no canto de
## cada d20 (o atributo que dá aquele dado), como os slots do For The King 2.
##   var i := IconeTeste.criar("luta", 40)   # perícia, atributo ou "movimento"

## Cores dos atributos (as mesmas da ficha e da rolagem).
const CORES := {"agi": Color("7fd3c7"), "for": Color("e0574a"), "int": Color("e3c27a"), "pre": Color("b98ae6"), "vig": Color("6fcf8e")}
## O atributo de cada perícia que não tem desenho próprio cai no do atributo (p.30-32).
const ATRIBUTO_DA_PERICIA := {"acrobacia": "agi", "adestramento": "pre", "artes": "pre", "atletismo": "for", "atualidades": "int",
	"ciencias": "int", "crime": "agi", "diplomacia": "pre", "enganacao": "pre", "fortitude": "vig", "furtividade": "agi",
	"iniciativa": "agi", "intimidacao": "pre", "intuicao": "pre", "investigacao": "int", "luta": "for", "medicina": "int",
	"ocultismo": "int", "percepcao": "pre", "pilotagem": "agi", "pontaria": "agi", "profissao": "int", "reflexos": "agi",
	"religiao": "pre", "sobrevivencia": "int", "tatica": "int", "tecnologia": "int", "vontade": "pre", "movimento": "agi"}

var chave := ""
var cor := Color.WHITE
var contorno := true   ## o círculo em volta (no canto do dado, sem)


static func criar(p_chave: String, tamanho: float, p_cor: Variant = null) -> IconeTeste:
	var i := IconeTeste.new()
	i.chave = p_chave
	i.cor = p_cor if p_cor is Color else cor_de(p_chave)
	i.custom_minimum_size = Vector2(tamanho, tamanho)
	i.size = i.custom_minimum_size
	return i


## A cor do teste: a do atributo da perícia.
static func cor_de(c: String) -> Color:
	var attr: String = c if CORES.has(c) else String(ATRIBUTO_DA_PERICIA.get(c, ""))
	return CORES.get(attr, Tema.PERGAMINHO)


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - 2.0
	var w := maxf(1.5, r / 9.0)
	if contorno:
		draw_arc(c, r, 0, TAU, 32, cor, w * 0.8, true)
	var k := r * (0.55 if contorno else 0.85)
	match chave:
		"agi", "acrobacia", "iniciativa":   # raio
			draw_polyline(PackedVector2Array([c + Vector2(-k * 0.6, -k), c + Vector2(k * 0.3, -k * 0.1), c + Vector2(-k * 0.3, k * 0.1),
				c + Vector2(k * 0.6, k)]), cor, w * 1.2, true)
		"for", "atletismo":   # punho
			draw_rect(Rect2(c - Vector2(k * 0.8, k * 0.4), Vector2(k * 1.6, k * 1.1)), cor, false, w)
			for i in 4:
				draw_line(c + Vector2(-k * 0.8 + i * k * 0.53, -k * 0.4), c + Vector2(-k * 0.8 + i * k * 0.53, -k * 0.85), cor, w * 0.8)
		"int", "atualidades", "tatica", "profissao":   # olho aberto do intelecto
			draw_arc(c + Vector2(0, k * 0.7), k * 1.2, PI * 1.2, PI * 1.8, 16, cor, w, true)
			draw_arc(c - Vector2(0, k * 0.7), k * 1.2, PI * 0.2, PI * 0.8, 16, cor, w, true)
			draw_circle(c, k * 0.3, cor)
		"pre", "artes", "adestramento":   # estrela
			var pts := PackedVector2Array()
			for i in 6:
				var ang := -PI / 2.0 + i * TAU * 2.0 / 5.0
				pts.append(c + Vector2(cos(ang), sin(ang)) * k)
			draw_polyline(pts, cor, w, true)
		"vig":   # coração
			_coracao(c, k, w)
		"luta":   # duas lâminas cruzadas
			draw_line(c + Vector2(-k, -k), c + Vector2(k, k), cor, w * 1.2, true)
			draw_line(c + Vector2(k, -k), c + Vector2(-k, k), cor, w * 1.2, true)
			draw_line(c + Vector2(-k * 0.5, k * 0.2), c + Vector2(-k * 0.2, k * 0.5), cor, w * 1.6)
			draw_line(c + Vector2(k * 0.5, k * 0.2), c + Vector2(k * 0.2, k * 0.5), cor, w * 1.6)
		"pontaria":   # mira
			draw_arc(c, k * 0.75, 0, TAU, 24, cor, w, true)
			for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				draw_line(c + d * k * 0.35, c + d * k * 1.05, cor, w)
			draw_circle(c, w * 0.8, cor)
		"movimento":   # pegadas
			for lado in [-1, 1]:
				var o := c + Vector2(k * 0.35 * lado, k * 0.3 * lado)
				draw_circle(o, k * 0.28, cor)
				draw_circle(o + Vector2(0, -k * 0.45), k * 0.13, cor)
		"reflexos", "fortitude":   # escudo (com uma cruz na Fortitude)
			var esc := PackedVector2Array([c + Vector2(-k * 0.8, -k * 0.8), c + Vector2(k * 0.8, -k * 0.8), c + Vector2(k * 0.8, 0),
				c + Vector2(0, k), c + Vector2(-k * 0.8, 0), c + Vector2(-k * 0.8, -k * 0.8)])
			draw_polyline(esc, cor, w, true)
			if chave == "fortitude":
				draw_line(c + Vector2(0, -k * 0.45), c + Vector2(0, k * 0.35), cor, w)
				draw_line(c + Vector2(-k * 0.35, -k * 0.05), c + Vector2(k * 0.35, -k * 0.05), cor, w)
			else:
				draw_polyline(PackedVector2Array([c + Vector2(-k * 0.3, -k * 0.5), c + Vector2(k * 0.15, -k * 0.1), c + Vector2(-k * 0.15, k * 0.05),
					c + Vector2(k * 0.3, k * 0.45)]), cor, w * 0.8, true)
		"vontade", "intuicao":   # espiral
			var pts := PackedVector2Array()
			for i in 40:
				var t := i / 39.0 * TAU * 2.0
				pts.append(c + Vector2(cos(t), sin(t)) * k * (0.1 + 0.45 * t / TAU))
			draw_polyline(pts, cor, w, true)
		"percepcao":   # olho com cílios
			draw_arc(c + Vector2(0, k * 0.6), k * 1.1, PI * 1.2, PI * 1.8, 16, cor, w, true)
			draw_arc(c - Vector2(0, k * 0.6), k * 1.1, PI * 0.2, PI * 0.8, 16, cor, w, true)
			draw_circle(c, k * 0.25, cor)
			for i in 3:
				var x := (i - 1) * k * 0.45
				draw_line(c + Vector2(x, -k * 0.55), c + Vector2(x * 1.3, -k * 0.95), cor, w * 0.8)
		"investigacao":   # lupa
			draw_arc(c - Vector2(k * 0.2, k * 0.2), k * 0.55, 0, TAU, 24, cor, w, true)
			draw_line(c + Vector2(k * 0.2, k * 0.2), c + Vector2(k * 0.85, k * 0.85), cor, w * 1.6)
		"ocultismo":   # triângulo com olho
			draw_polyline(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k * 0.9, k * 0.7), c + Vector2(-k * 0.9, k * 0.7), c + Vector2(0, -k)]), cor, w, true)
			draw_circle(c + Vector2(0, k * 0.15), k * 0.2, cor)
		"religiao":   # cruz latina
			draw_line(c + Vector2(0, -k), c + Vector2(0, k), cor, w * 1.2)
			draw_line(c + Vector2(-k * 0.5, -k * 0.4), c + Vector2(k * 0.5, -k * 0.4), cor, w * 1.2)
		"medicina":   # cruz de pronto-socorro
			draw_rect(Rect2(c - Vector2(k * 0.25, k * 0.8), Vector2(k * 0.5, k * 1.6)), cor)
			draw_rect(Rect2(c - Vector2(k * 0.8, k * 0.25), Vector2(k * 1.6, k * 0.5)), cor)
		"tecnologia":   # chip
			draw_rect(Rect2(c - Vector2(k * 0.55, k * 0.55), Vector2(k * 1.1, k * 1.1)), cor, false, w)
			for i in 3:
				var t := -k * 0.35 + i * k * 0.35
				draw_line(c + Vector2(t, -k * 0.55), c + Vector2(t, -k * 0.9), cor, w * 0.8)
				draw_line(c + Vector2(t, k * 0.55), c + Vector2(t, k * 0.9), cor, w * 0.8)
		"ciencias":   # frasco
			draw_polyline(PackedVector2Array([c + Vector2(-k * 0.2, -k), c + Vector2(-k * 0.2, -k * 0.2), c + Vector2(-k * 0.8, k * 0.8),
				c + Vector2(k * 0.8, k * 0.8), c + Vector2(k * 0.2, -k * 0.2), c + Vector2(k * 0.2, -k)]), cor, w, true)
		"crime", "furtividade":   # máscara de olhos
			draw_arc(c + Vector2(-k * 0.4, 0), k * 0.32, 0, TAU, 16, cor, w, true)
			draw_arc(c + Vector2(k * 0.4, 0), k * 0.32, 0, TAU, 16, cor, w, true)
			draw_line(c + Vector2(-k * 0.08, 0), c + Vector2(k * 0.08, 0), cor, w)
			draw_line(c + Vector2(-k * 0.72, 0), c + Vector2(-k, -k * 0.25), cor, w * 0.8)
			draw_line(c + Vector2(k * 0.72, 0), c + Vector2(k, -k * 0.25), cor, w * 0.8)
		"diplomacia", "enganacao", "intimidacao":   # balão de fala (com "!" na Intimidação)
			draw_arc(c - Vector2(0, k * 0.15), k * 0.75, 0, TAU, 24, cor, w, true)
			draw_line(c + Vector2(-k * 0.3, k * 0.5), c + Vector2(-k * 0.6, k * 0.95), cor, w)
			if chave == "intimidacao":
				draw_line(c + Vector2(0, -k * 0.5), c + Vector2(0, k * 0.05), cor, w * 1.2)
				draw_circle(c + Vector2(0, k * 0.3), w * 0.7, cor)
			elif chave == "enganacao":
				draw_arc(c - Vector2(0, k * 0.05), k * 0.35, PI * 0.15, PI * 0.85, 10, cor, w * 0.8, true)
		"sobrevivencia":   # árvore
			draw_polyline(PackedVector2Array([c + Vector2(0, -k), c + Vector2(k * 0.7, k * 0.4), c + Vector2(-k * 0.7, k * 0.4), c + Vector2(0, -k)]), cor, w, true)
			draw_line(c + Vector2(0, k * 0.4), c + Vector2(0, k), cor, w * 1.3)
		"pilotagem":   # volante
			draw_arc(c, k * 0.85, 0, TAU, 24, cor, w, true)
			draw_circle(c, k * 0.2, cor)
			for ang in [PI / 2.0, PI * 7.0 / 6.0, -PI / 6.0]:
				draw_line(c, c + Vector2(cos(ang), sin(ang)) * k * 0.85, cor, w * 0.8)
		_:
			var attr: String = ATRIBUTO_DA_PERICIA.get(chave, "")
			if attr != "" and attr != chave:
				var antes := chave
				chave = attr
				_draw()
				chave = antes
			else:
				draw_circle(c, k * 0.3, cor)


func _coracao(c: Vector2, k: float, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 33:
		var t := TAU * i / 32.0
		var x := 16.0 * pow(sin(t), 3)
		var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
		pts.append(c + Vector2(x, y) * k / 16.0)
	draw_polyline(pts, cor, w, true)
