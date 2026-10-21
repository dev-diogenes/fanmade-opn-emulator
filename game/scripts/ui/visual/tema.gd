class_name Tema
extends RefCounted
## Tema único da interface (ADR 0008): painéis de pedra escura com borda dourada
## envelhecida, vermelho-sangue para o perigo e texto cor de pergaminho.
## O autoload Jogo chama `aplicar()`, que funde o tema no tema padrão do Godot:
## assim valem também as camadas (CanvasLayer) do tutorial e os popups.

const FUNDO := Color("0c0b10")
const PEDRA := Color("17141c")
const PEDRA_CLARA := Color("241e29")
const OURO := Color("b08d4f")
const OURO_ESCURO := Color("5e4a2b")
const OURO_CLARO := Color("e3c27a")
const SANGUE := Color("8e1b22")
const SANGUE_CLARO := Color("c0392b")
const PERGAMINHO := Color("e9dfc8")
const TEXTO_SUAVE := Color("a69b88")

## Semânticos (docs/08-direcao-de-arte-e-ux.md): use estes, e não cores soltas
const PERIGO := Color("e0574a")      ## dano, encontro, falha, erro
const SUCESSO := Color("6fcf8e")     ## cura, vitória, confirmação
const AVISO := Color("eda64a")       ## custo, NEX, alerta
const INFO := Color("7fd3c7")        ## online, investigação, pista
const MESTRE := Color("f2c6a0")      ## painel e ações do mestre
const ELEMENTO := {"sangue": Color("c0392b"), "morte": Color("6b6670"), "conhecimento": Color("e3b341"),
	"energia": Color("a35ce0"), "medo": Color("e8eef5")}

## Materiais da Ordem (docs/09, 5.1): papel, tinta, cortiça e fio vermelho
const PAPEL := Color("e8dcc0")
const PAPEL_SOMBRA := Color("bfae8a")
const TINTA := Color("2a2320")
const CORTICA := Color("8a5a36")
const FIO := Color("b3121c")
const TRACO := Color(0.914, 0.875, 0.784, 0.75)

static var _texturas: Dictionary = {}

## Cor de cada jogador: base da figura no 3D e borda do retrato
const CORES_JOGADORES := [Color("3d7bd9"), Color("27ae60"), Color("af7ac5"), Color("e67e22")]

## Escalas
const ESPACO_P := 4
const ESPACO_M := 8
const ESPACO_G := 12
const ESPACO_GG := 20
const FONTE_P := 14
const FONTE_M := 17
const FONTE_G := 20
const FONTE_TITULO := 28
const FONTE_LOGO := 64

## Fontes opcionais (OFL). Sem os arquivos, fica a fonte padrão do Godot.
const ARQ_TITULO := "res://assets/fonts/Cinzel.ttf"
const ARQ_TEXTO := "res://assets/fonts/AlegreyaSans-Regular.ttf"
const ARQ_NEGRITO := "res://assets/fonts/AlegreyaSans-Bold.ttf"
## Máquina de escrever (docs/09): bilhetes, fichas em papel e relatório de campo
const ARQ_MAQUINA := "res://assets/fonts/SpecialElite-Regular.ttf"


static func _fonte(caminho: String) -> Font:
	return load(caminho) if ResourceLoader.exists(caminho) else null


static func caixa(fundo: Color, borda: Color = Color.TRANSPARENT, largura: int = 0, raio: int = 4,
		margem := Vector2(10, 6)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fundo
	s.border_color = borda
	s.set_border_width_all(largura)
	s.set_corner_radius_all(raio)
	s.content_margin_left = margem.x
	s.content_margin_right = margem.x
	s.content_margin_top = margem.y
	s.content_margin_bottom = margem.y
	s.anti_aliasing = true
	return s


static func _icone_marcar(marcado: bool, alfa: float = 1.0) -> ImageTexture:
	var n := 18
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var borda := Color(OURO, alfa)
	if marcado:
		img.fill_rect(Rect2i(2, 2, n - 4, n - 4), Color(SANGUE, alfa))
	for i in n:
		for d in [1, 2]:
			img.set_pixel(i, d, borda)
			img.set_pixel(i, n - 1 - d, borda)
			img.set_pixel(d, i, borda)
			img.set_pixel(n - 1 - d, i, borda)
	if marcado:
		var tinta := Color(PERGAMINHO, alfa)
		for p in [Vector2i(4, 9), Vector2i(5, 10), Vector2i(6, 11), Vector2i(7, 12), Vector2i(8, 11), Vector2i(9, 10),
				Vector2i(10, 9), Vector2i(11, 8), Vector2i(12, 7), Vector2i(13, 6)]:
			img.set_pixelv(p, tinta)
			img.set_pixelv(p + Vector2i(0, -1), tinta)
	return ImageTexture.create_from_image(img)


## Tema para conteúdo escrito sobre papel (texto em tinta escura).
static func tema_papel() -> Theme:
	var t := Theme.new()
	for tipo in ["Label", "Subtitulo", "CheckBox", "CheckButton"]:
		t.set_color("font_color", tipo, TINTA)
	t.set_color("default_color", "RichTextLabel", TINTA)
	var maquina := _fonte(ARQ_MAQUINA)
	if maquina != null:
		t.set_font("font", "Label", maquina)
		t.set_font("normal_font", "RichTextLabel", maquina)
	return t


## Moldura em traço riscado com margens; `leve` = um traço só, sem sombra (botões).
static func riscada(traco: Color, fundo: Color, margem := Vector2(14, 10), leve: bool = false) -> MolduraRiscada:
	var m := MolduraRiscada.criar(traco, fundo, margem)
	if leve:
		m.tracos = 1
		m.sombra = 0
		m.escape = 3.0
		m.desvio = 1.0
	return m


static func criar() -> Theme:
	var t := Theme.new()
	var texto := _fonte(ARQ_TEXTO)
	var negrito := _fonte(ARQ_NEGRITO)
	var titulo := _fonte(ARQ_TITULO)
	if texto != null:
		t.default_font = texto
	t.default_font_size = FONTE_M

	# Painéis
	var painel := caixa(Color(PEDRA, 0.94), OURO_ESCURO, 2, 6, Vector2(14, 12))
	painel.shadow_color = Color(0, 0, 0, 0.55)
	painel.shadow_size = 8
	painel.border_blend = true
	# Painéis em traço riscado (docs/09): nada de caixa reta
	var riscado := riscada(Color(OURO, 0.7), Color(PEDRA, 0.94), Vector2(14, 12))
	t.set_stylebox("panel", "PanelContainer", riscado)
	t.set_stylebox("panel", "Panel", riscado)
	var lateral := riscada(OURO, Color(PEDRA, 0.94), Vector2(14, 12))
	lateral.escape = 0.0
	t.set_type_variation("PainelLateral", "PanelContainer")
	t.set_stylebox("panel", "PainelLateral", lateral)

	# Textos
	for tipo in ["Label", "CheckBox", "CheckButton"]:
		t.set_color("font_color", tipo, PERGAMINHO)
	t.set_color("default_color", "RichTextLabel", PERGAMINHO)
	if negrito != null:
		t.set_font("bold_font", "RichTextLabel", negrito)
	t.set_type_variation("Titulo", "Label")
	t.set_color("font_color", "Titulo", OURO_CLARO)
	t.set_font_size("font_size", "Titulo", 24)
	t.set_color("font_shadow_color", "Titulo", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_y", "Titulo", 2)
	if titulo != null:
		t.set_font("font", "Titulo", titulo)
	t.set_type_variation("Subtitulo", "Label")
	t.set_color("font_color", "Subtitulo", OURO)
	t.set_font_size("font_size", "Subtitulo", 15)
	if titulo != null:
		t.set_font("font", "Subtitulo", titulo)

	# Botões
	var normal := caixa(PEDRA_CLARA, OURO_ESCURO, 1, 4, Vector2(14, 7))
	var foco := caixa(Color(0, 0, 0, 0), OURO_CLARO, 1, 4)
	for tipo in ["Button", "OptionButton", "MenuButton"]:
		t.set_stylebox("normal", tipo, riscada(Color(OURO, 0.55), PEDRA_CLARA, Vector2(14, 7), true))
		t.set_stylebox("hover", tipo, riscada(OURO_CLARO, Color("33283a"), Vector2(14, 7), true))
		t.set_stylebox("pressed", tipo, riscada(OURO_CLARO, SANGUE, Vector2(14, 7), true))
		t.set_stylebox("disabled", tipo, riscada(Color(OURO_ESCURO, 0.4), Color(PEDRA, 0.6), Vector2(14, 7), true))
		t.set_stylebox("focus", tipo, foco)
		t.set_color("font_color", tipo, PERGAMINHO)
		t.set_color("font_hover_color", tipo, OURO_CLARO)
		t.set_color("font_pressed_color", tipo, Color.WHITE)
		t.set_color("font_focus_color", tipo, PERGAMINHO)
		t.set_color("font_disabled_color", tipo, Color("998d7a"))   # 5:1 sobre o botão apagado (docs/16, A2)
	# Botão de destaque (ação principal): sangue com borda dourada
	t.set_type_variation("BotaoPrincipal", "Button")
	t.set_stylebox("normal", "BotaoPrincipal", riscada(OURO, Color("6e1419"), Vector2(18, 10)))
	t.set_stylebox("hover", "BotaoPrincipal", riscada(OURO_CLARO, SANGUE_CLARO.darkened(0.2), Vector2(18, 10)))
	# Item de menu (título): só texto; no hover, o traço riscado aparece em volta
	t.set_type_variation("BotaoMenu", "Button")
	t.set_stylebox("normal", "BotaoMenu", StyleBoxEmpty.new())
	t.set_stylebox("hover", "BotaoMenu", riscada(OURO_CLARO, Color(SANGUE, 0.35), Vector2(18, 8), true))
	t.set_stylebox("pressed", "BotaoMenu", riscada(OURO_CLARO, SANGUE, Vector2(18, 8), true))
	t.set_stylebox("focus", "BotaoMenu", riscada(Color(OURO_CLARO, 0.8), Color(0, 0, 0, 0), Vector2(18, 8), true))
	t.set_font_size("font_size", "BotaoMenu", FONTE_G + 2)
	t.set_color("font_color", "BotaoMenu", PERGAMINHO)
	t.set_color("font_hover_color", "BotaoMenu", OURO_CLARO)
	t.set_color("font_focus_color", "BotaoMenu", OURO_CLARO)
	if titulo != null:
		t.set_font("font", "BotaoMenu", titulo)
	t.set_font_size("font_size", "BotaoPrincipal", 18)
	if titulo != null:
		t.set_font("font", "BotaoPrincipal", titulo)
	# Botão sobre papel (bilhetes e cartas): tinta escura; marcado = lavado de ouro com borda
	# dourada escura (docs/21: o vermelho fica para a ação principal e o perigo)
	t.set_type_variation("BotaoPapel", "Button")
	t.set_stylebox("normal", "BotaoPapel", caixa(Color(0, 0, 0, 0), Color(TINTA, 0.25), 1, 3, Vector2(10, 5)))
	t.set_stylebox("hover", "BotaoPapel", caixa(Color(PAPEL_SOMBRA, 0.6), Color(TINTA, 0.5), 1, 3, Vector2(10, 5)))
	t.set_stylebox("pressed", "BotaoPapel", caixa(Color(OURO, 0.38), OURO_ESCURO, 2, 3, Vector2(10, 5)))
	t.set_stylebox("hover_pressed", "BotaoPapel", caixa(Color(OURO, 0.5), OURO_ESCURO, 2, 3, Vector2(10, 5)))
	t.set_stylebox("disabled", "BotaoPapel", caixa(Color(0, 0, 0, 0), Color(TINTA, 0.1), 1, 3, Vector2(10, 5)))
	t.set_stylebox("focus", "BotaoPapel", caixa(Color(0, 0, 0, 0), SANGUE_CLARO, 1, 3))
	t.set_color("font_color", "BotaoPapel", TINTA)
	t.set_color("font_hover_color", "BotaoPapel", TINTA)
	t.set_color("font_pressed_color", "BotaoPapel", TINTA)
	t.set_color("font_hover_pressed_color", "BotaoPapel", TINTA)
	t.set_color("font_focus_color", "BotaoPapel", TINTA)
	t.set_color("font_disabled_color", "BotaoPapel", Color(TINTA, 0.7))   # 4,9:1 no papel (A2)
	t.set_type_variation("TextoPapel", "Label")
	t.set_color("font_color", "TextoPapel", TINTA)
	var maquina := _fonte(ARQ_MAQUINA)
	if maquina != null:
		t.set_font("font", "TextoPapel", maquina)
		t.set_font("font", "BotaoPapel", maquina)
		t.set_font_size("font_size", "BotaoPapel", FONTE_P + 1)
	# Caixas de marcar desenhadas: quadrado riscado claro; marcado = sangue com ✓
	t.set_icon("unchecked", "CheckBox", _icone_marcar(false))
	t.set_icon("checked", "CheckBox", _icone_marcar(true))
	t.set_icon("unchecked_disabled", "CheckBox", _icone_marcar(false, 0.4))
	t.set_icon("checked_disabled", "CheckBox", _icone_marcar(true, 0.4))
	for tipo in ["CheckBox", "CheckButton"]:
		t.set_color("font_hover_color", tipo, OURO_CLARO)
		t.set_stylebox("normal", tipo, StyleBoxEmpty.new())
		t.set_stylebox("hover", tipo, StyleBoxEmpty.new())
		t.set_stylebox("pressed", tipo, StyleBoxEmpty.new())
		t.set_stylebox("focus", tipo, StyleBoxEmpty.new())

	# Abas como pastas de arquivo (Base da Ordem)
	t.set_stylebox("panel", "TabContainer", riscada(Color(OURO, 0.6), Color(PEDRA, 0.9), Vector2(18, 16)))
	t.set_stylebox("tab_selected", "TabContainer", riscada(OURO_CLARO, Color("2a2230"), Vector2(18, 7), true))
	t.set_stylebox("tab_unselected", "TabContainer", caixa(Color(PEDRA, 0.8), Color(OURO_ESCURO, 0.5), 1, 3, Vector2(18, 7)))
	t.set_stylebox("tab_hovered", "TabContainer", riscada(OURO, Color("231d28"), Vector2(18, 7), true))
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", OURO_CLARO)
	t.set_color("font_unselected_color", "TabContainer", TEXTO_SUAVE)
	t.set_color("font_hovered_color", "TabContainer", PERGAMINHO)
	t.set_constant("side_margin", "TabContainer", 12)
	t.set_font_size("font_size", "TabContainer", FONTE_M + 1)
	if titulo != null:
		t.set_font("font", "TabContainer", titulo)

	# Campos
	var campo := caixa(Color("0f0d13"), Color("8a6d3e"), 1, 3, Vector2(8, 5))   # borda 3,8:1 (WCAG 1.4.11, A2)
	t.set_stylebox("normal", "LineEdit", campo)
	t.set_stylebox("focus", "LineEdit", caixa(Color("0f0d13"), OURO_CLARO, 1, 3, Vector2(8, 5)))
	t.set_stylebox("read_only", "LineEdit", campo)
	t.set_color("font_color", "LineEdit", PERGAMINHO)
	t.set_color("caret_color", "LineEdit", OURO_CLARO)
	t.set_color("selection_color", "LineEdit", Color(SANGUE, 0.7))
	t.set_stylebox("normal", "TextEdit", campo)
	t.set_stylebox("focus", "TextEdit", campo)
	t.set_color("font_color", "TextEdit", PERGAMINHO)

	# Listas
	t.set_stylebox("panel", "ItemList", caixa(Color("0f0d13"), OURO_ESCURO, 1, 4, Vector2(4, 4)))
	t.set_stylebox("focus", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("selected", "ItemList", caixa(Color(SANGUE, 0.75), OURO, 1, 3))
	t.set_stylebox("selected_focus", "ItemList", caixa(SANGUE, OURO_CLARO, 1, 3))
	t.set_stylebox("hovered", "ItemList", caixa(Color(OURO, 0.12)))
	t.set_stylebox("cursor", "ItemList", StyleBoxEmpty.new())
	t.set_stylebox("cursor_unfocused", "ItemList", StyleBoxEmpty.new())
	t.set_color("font_color", "ItemList", PERGAMINHO)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)
	t.set_color("guide_color", "ItemList", Color(OURO, 0.08))
	t.set_constant("v_separation", "ItemList", 6)
	var popup := caixa(Color(PEDRA, 0.98), OURO, 1, 4, Vector2(6, 6))
	t.set_stylebox("panel", "PopupMenu", popup)
	t.set_stylebox("hover", "PopupMenu", caixa(Color(SANGUE, 0.8)))
	t.set_color("font_color", "PopupMenu", PERGAMINHO)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_stylebox("panel", "TooltipPanel", popup)
	t.set_color("font_color", "TooltipLabel", PERGAMINHO)

	# Barras (Membrana, PV)
	t.set_stylebox("background", "ProgressBar", caixa(Color("0f0d13"), OURO_ESCURO, 1, 3, Vector2(0, 0)))
	t.set_stylebox("fill", "ProgressBar", caixa(SANGUE, SANGUE_CLARO, 1, 3, Vector2(0, 0)))
	t.set_color("font_color", "ProgressBar", PERGAMINHO)
	t.set_color("font_outline_color", "ProgressBar", Color.BLACK)
	t.set_constant("outline_size", "ProgressBar", 4)

	# Rolagem fina e dourada
	for tipo in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", tipo, caixa(Color(0, 0, 0, 0.25), Color.TRANSPARENT, 0, 3, Vector2(3, 3)))
		t.set_stylebox("grabber", tipo, caixa(OURO_ESCURO, Color.TRANSPARENT, 0, 3))
		t.set_stylebox("grabber_highlight", tipo, caixa(OURO, Color.TRANSPARENT, 0, 3))
		t.set_stylebox("grabber_pressed", tipo, caixa(OURO_CLARO, Color.TRANSPARENT, 0, 3))

	# Slider (volume)
	t.set_stylebox("slider", "HSlider", caixa(Color("0f0d13"), OURO_ESCURO, 1, 3, Vector2(0, 3)))
	t.set_stylebox("grabber_area", "HSlider", caixa(SANGUE, Color.TRANSPARENT, 0, 3, Vector2(0, 3)))
	t.set_stylebox("grabber_area_highlight", "HSlider", caixa(SANGUE_CLARO, Color.TRANSPARENT, 0, 3, Vector2(0, 3)))

	# Separadores
	t.set_stylebox("separator", "HSeparator", caixa(Color(OURO, 0.35), Color.TRANSPARENT, 0, 0, Vector2(0, 1)))
	t.set_constant("separation", "HSeparator", 10)
	return t


## Sucesso e falha (docs/18, A6). Com a paleta para daltonismo, azul e laranja (Okabe-Ito)
## no lugar de verde e vermelho. `papel`: a versão escura, para tinta sobre papel.
##   Escuro: 7,9:1 e 8,1:1 sobre a pedra. Papel: 5,4:1 e 4,8:1.
static func cor_sucesso(papel := false) -> Color:
	if Preferencias.daltonismo():
		return Color("0b5a8f") if papel else Color("56b4e9")
	return Color("2f6b3f") if papel else SUCESSO


static func cor_falha(papel := false) -> Color:
	if Preferencias.daltonismo():
		return Color("9a4500") if papel else Color("e69f00")
	return SANGUE if papel else PERIGO


## Fundo, borda e texto do dado (slot) de sucesso ou falha. Normal: dourado e sangue.
static func cores_slot(estado: String) -> Array:
	if Preferencias.daltonismo():
		match estado:
			"sucesso": return [Color("1f5f99"), Color("56b4e9"), PERGAMINHO]
			"falha": return [Color("8a4a00"), Color("e69f00"), PERGAMINHO]
	match estado:
		"sucesso": return [OURO, OURO_CLARO, FUNDO]
		"falha": return [SANGUE, SANGUE_CLARO, PERGAMINHO]
	return [PEDRA_CLARA, OURO_ESCURO, TEXTO_SUAVE]


## Trecho de BBCode colorido com um token: `Tema.bb("Encontro!", Tema.PERIGO)`.
static func bb(texto: String, cor: Color) -> String:
	return "[color=#%s]%s[/color]" % [cor.to_html(false), texto]


## Fonte de máquina de escrever, ou null sem o arquivo.
static func fonte_maquina() -> Font:
	return _fonte(ARQ_MAQUINA)


## Fonte de títulos (Cinzel), ou null sem o arquivo.
static func fonte_titulo() -> Font:
	return _fonte(ARQ_TITULO)


static func aplicar() -> void:
	var t := criar()
	var padrao := ThemeDB.get_default_theme()
	padrao.merge_with(t)
	if t.default_font != null:
		padrao.default_font = t.default_font
	padrao.default_font_size = t.default_font_size


## Slot de d20 (docs/08, R7). `estado`: "sucesso" (dourado, ✓), "falha" (sangue, ✗)
## ou "neutro" (pedra: dado que não decidiu o teste). `ordem` atrasa a entrada.
static func slot_d20(valor: int, estado: String, ordem: int = 0) -> Control:
	var caixa := PanelContainer.new()
	var cores := cores_slot(estado)
	var fundo: Color = cores[0]
	var borda: Color = cores[1]
	var estilo := caixa(fundo, borda, 2, 6, Vector2(8, 2))
	estilo.shadow_color = Color(borda, 0.45) if estado != "neutro" else Color(0, 0, 0, 0.4)
	estilo.shadow_size = 6 if estado != "neutro" else 3
	caixa.add_theme_stylebox_override("panel", estilo)
	caixa.custom_minimum_size = Vector2(46, 42)
	var l := Label.new()
	l.text = str(valor) + {"sucesso": "
✓", "falha": "
✗"}.get(estado, "")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", FONTE_M)
	l.add_theme_constant_override("line_spacing", -6)
	l.add_theme_color_override("font_color", cores[2])
	caixa.add_child(l)
	caixa.scale = Vector2.ONE * 0.6
	caixa.modulate.a = 0.0
	caixa.ready.connect(func():
		caixa.pivot_offset = caixa.custom_minimum_size / 2.0
		var tw := caixa.create_tween().set_parallel()
		tw.tween_property(caixa, "scale", Vector2.ONE, 0.18).set_delay(0.08 * ordem).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(caixa, "modulate:a", 1.0, 0.12).set_delay(0.08 * ordem))
	return caixa


## Véu da Membrana sobre a vista 3D (docs/08, R4). Chame `membrana_na_tela` a cada atualização.
static func veu(vista: SubViewportContainer) -> void:
	var caminho := "res://assets/shaders/veu_membrana.gdshader"
	if not ResourceLoader.exists(caminho):
		return
	var m := ShaderMaterial.new()
	m.shader = load(caminho)
	vista.material = m


## Intensidade do véu: quase nada com a Membrana em 100, máxima abaixo de 25.
static func membrana_na_tela(vista: SubViewportContainer, valor: int) -> void:
	var m := vista.material as ShaderMaterial
	# A mesma curva do clima 3D (docs/22): leve até 75, pesada a partir daí
	var t := Pecas.intensidade_membrana(valor)
	Som.ambiente(t)
	if m != null:
		var ligado := Preferencias.efeito("grao")
		m.set_shader_parameter("intensidade", t if ligado else 0.0)
		m.set_shader_parameter("grao", 1.0 if ligado else 0.0)


## Textura procedural (cache): "papel" (manchas suaves) ou "cortica" (grãos escuros).
static func textura(tipo: String) -> Texture2D:
	if _texturas.has(tipo):
		return _texturas[tipo]
	var ruido := FastNoiseLite.new()
	ruido.seed = 7 if tipo == "papel" else 11
	ruido.frequency = 0.012 if tipo == "papel" else 0.09
	ruido.fractal_octaves = 4
	var grao := FastNoiseLite.new()
	grao.seed = 3
	grao.frequency = 0.6
	# Imagens "seamless": o papel e a cortiça se repetem sem emenda visível
	ruido.frequency = 0.02 if tipo == "papel" else 0.09
	var manchas := ruido.get_seamless_image(256, 256)
	var graos := grao.get_seamless_image(256, 256)
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var n := manchas.get_pixel(x, y).r
			var g := graos.get_pixel(x, y).r
			var cor: Color
			if tipo == "papel":
				cor = PAPEL.lerp(PAPEL_SOMBRA, smoothstep(0.5, 0.95, n) * 0.35).darkened(g * 0.06)
			else:
				cor = CORTICA.lerp(CORTICA.darkened(0.45), smoothstep(0.55, 0.8, g)).lerp(CORTICA.lightened(0.15), n * 0.35)
			img.set_pixel(x, y, cor)
	var tex := ImageTexture.create_from_image(img)
	_texturas[tipo] = tex
	return tex


## Caixa de papel (bilhetes, cartas, fichas).
static func caixa_papel(margem := Vector2(12, 10)) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = textura("papel")
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	s.content_margin_left = margem.x
	s.content_margin_right = margem.x
	s.content_margin_top = margem.y
	s.content_margin_bottom = margem.y
	return s


## Pulso de VHS na vista (docs/09, 5.3): pista encontrada = 0.8/0.6 s; falha = 0.35/0.3 s.
## Fração da velocidade da fita no modo suave: 18 trocas/s viram 2,7 (docs/18, A5).
const RITMO_SUAVE := 0.15

static func pulso_vhs(vista: SubViewportContainer, forca: float = 0.8, duracao: float = 0.6) -> void:
	var m := vista.material as ShaderMaterial
	if m == null or not vista.is_inside_tree() or not Preferencias.efeito("glitch"):
		return
	# Fotossensibilidade (docs/18, A5): no modo suave o pulso é mais fraco, dura mais e a fita
	# troca de faixa no máximo ~3 vezes por segundo (WCAG 2.3.1), em vez de 18.
	var suave := Preferencias.flashes() == "suave"
	if suave:
		forca *= 0.45
		duracao = maxf(duracao, 0.9)
	m.set_shader_parameter("ritmo", RITMO_SUAVE if suave else 1.0)
	m.set_shader_parameter("glitch", forca)
	Som.tocar("glitch")
	vista.create_tween().tween_method(func(v: float): m.set_shader_parameter("glitch", v), forca, 0.0, duracao)


## Datilografia (docs/10): o texto aparece letra a letra, como numa máquina de escrever.
## Vale para Label e RichTextLabel. A duração acompanha o tamanho do texto (até `maximo` s).
static func datilografar(rotulo: Control, por_letra: float = 0.018, maximo: float = 1.6) -> void:
	if not (rotulo is Label or rotulo is RichTextLabel) or not rotulo.is_inside_tree():
		return
	var n: int = rotulo.get_total_character_count() if rotulo is RichTextLabel else rotulo.text.length()
	var ritmo: float = {"lenta": 1.7, "normal": 1.0, "instantanea": 0.0}.get(Preferencias.velocidade_texto(), 1.0)
	if ritmo <= 0.0:
		rotulo.visible_ratio = 1.0
		return
	rotulo.visible_ratio = 0.0
	var duracao := minf(maximo * ritmo, maxf(0.15, n * por_letra * ritmo))
	rotulo.create_tween().tween_property(rotulo, "visible_ratio", 1.0, duracao)
	# As teclas batem junto (no máximo uma a cada 45 ms, para não virar zumbido)
	var teclas := mini(n, int(duracao / 0.045))
	if teclas > 0:
		var tw := rotulo.create_tween().set_loops(teclas)
		tw.tween_callback(func(): Som.tocar("tecla"))
		tw.tween_interval(duracao / teclas)


## Quanto tempo um resultado fica na tela (A3): `normal` segundos, metade no "curto";
## 0 = fica até o jogador clicar.
static func duracao_resultado(normal: float) -> float:
	match Preferencias.tempo_resultado():
		"curto": return normal * 0.55
		"clique": return 0.0
	return normal


## Escala da interface (A1): a janela inteira cresce ou diminui, textos e painéis juntos.
static func aplicar_escala(janela: Window = null) -> void:
	if janela == null:
		var arvore := Engine.get_main_loop() as SceneTree
		if arvore == null:
			return
		janela = arvore.root
	# O HUD foi desenhado para 1280 × 720 lógicos: a escala não passa do que cabe na janela
	var tamanho := Vector2(janela.size)
	var cabe := minf(tamanho.x / 1180.0, tamanho.y / 660.0) if tamanho.x > 0 else 1.0
	janela.content_scale_factor = clampf(minf(Preferencias.escala(), maxf(cabe, 0.8)), 0.8, 1.5)


## Fundo de tela: gradiente radial (vinheta) em vez de cor chapada.
static func fundo() -> Control:
	var tr := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color("231a24"))
	g.set_color(1, FUNDO)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.35)
	tex.fill_to = Vector2(1.1, 1.0)
	tex.width = 256
	tex.height = 256
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	return tr


## Envolve `conteudo` num painel. `lateral` = barra ao lado do 3D (borda só à esquerda).
static func painel(conteudo: Control, lateral: bool = false) -> PanelContainer:
	var p := PanelContainer.new()
	if lateral:
		p.theme_type_variation = "PainelLateral"
	p.size_flags_horizontal = conteudo.size_flags_horizontal
	p.size_flags_vertical = conteudo.size_flags_vertical
	p.custom_minimum_size = conteudo.custom_minimum_size
	conteudo.custom_minimum_size = Vector2.ZERO
	p.add_child(conteudo)
	return p
