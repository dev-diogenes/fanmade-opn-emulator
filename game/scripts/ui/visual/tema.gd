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
	t.set_stylebox("panel", "PanelContainer", painel)
	t.set_stylebox("panel", "Panel", painel)
	var lateral := painel.duplicate()
	lateral.set_corner_radius_all(0)
	lateral.border_width_top = 0
	lateral.border_width_bottom = 0
	lateral.border_width_right = 0
	lateral.border_width_left = 3
	lateral.border_color = OURO
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
		t.set_stylebox("normal", tipo, normal)
		t.set_stylebox("hover", tipo, caixa(Color("33283a"), OURO, 1, 4, Vector2(14, 7)))
		t.set_stylebox("pressed", tipo, caixa(SANGUE, OURO_CLARO, 1, 4, Vector2(14, 7)))
		t.set_stylebox("disabled", tipo, caixa(Color(PEDRA, 0.6), Color(OURO_ESCURO, 0.4), 1, 4, Vector2(14, 7)))
		t.set_stylebox("focus", tipo, foco)
		t.set_color("font_color", tipo, PERGAMINHO)
		t.set_color("font_hover_color", tipo, OURO_CLARO)
		t.set_color("font_pressed_color", tipo, Color.WHITE)
		t.set_color("font_focus_color", tipo, PERGAMINHO)
		t.set_color("font_disabled_color", tipo, Color(TEXTO_SUAVE, 0.5))
	# Botão de destaque (ação principal): sangue com borda dourada
	t.set_type_variation("BotaoPrincipal", "Button")
	t.set_stylebox("normal", "BotaoPrincipal", caixa(Color("6e1419"), OURO, 2, 4, Vector2(18, 10)))
	t.set_stylebox("hover", "BotaoPrincipal", caixa(SANGUE_CLARO.darkened(0.2), OURO_CLARO, 2, 4, Vector2(18, 10)))
	t.set_font_size("font_size", "BotaoPrincipal", 18)
	if titulo != null:
		t.set_font("font", "BotaoPrincipal", titulo)
	for tipo in ["CheckBox", "CheckButton"]:
		t.set_color("font_hover_color", tipo, OURO_CLARO)
		t.set_stylebox("normal", tipo, StyleBoxEmpty.new())
		t.set_stylebox("hover", tipo, StyleBoxEmpty.new())
		t.set_stylebox("pressed", tipo, StyleBoxEmpty.new())
		t.set_stylebox("focus", tipo, StyleBoxEmpty.new())

	# Campos
	var campo := caixa(Color("0f0d13"), OURO_ESCURO, 1, 3, Vector2(8, 5))
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

	# Separadores
	t.set_stylebox("separator", "HSeparator", caixa(Color(OURO, 0.35), Color.TRANSPARENT, 0, 0, Vector2(0, 1)))
	t.set_constant("separation", "HSeparator", 10)
	return t


## Trecho de BBCode colorido com um token: `Tema.bb("Encontro!", Tema.PERIGO)`.
static func bb(texto: String, cor: Color) -> String:
	return "[color=#%s]%s[/color]" % [cor.to_html(false), texto]


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
	var fundo: Color = {"sucesso": OURO, "falha": SANGUE}.get(estado, PEDRA_CLARA)
	var borda: Color = {"sucesso": OURO_CLARO, "falha": SANGUE_CLARO}.get(estado, OURO_ESCURO)
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
	l.add_theme_color_override("font_color", FUNDO if estado == "sucesso" else (PERGAMINHO if estado == "falha" else TEXTO_SUAVE))
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
	if m != null:
		m.set_shader_parameter("intensidade", clampf((100.0 - valor) / 75.0, 0.0, 1.0))


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
