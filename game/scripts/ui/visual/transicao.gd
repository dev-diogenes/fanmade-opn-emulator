class_name Transicao
extends CanvasLayer
## Entrada de tela com estática e "abrindo arquivo" datilografado (docs/10).
## O autoload Jogo cria uma quando uma cena nova entra na raiz; ela some sozinha.

const LEGENDAS := {
	"titulo": "", "base_ordem": "ORDEM DA REALIDADE · ARQUIVO CENTRAL", "mapa_mundo": "OPERAÇÃO EM CAMPO",
	"arena_teste": "CONFRONTO", "investigacao": "CENA DE INVESTIGAÇÃO", "editor_missao": "ARQUIVO DE MISSÕES",
	"saguao": "SESSÃO ONLINE",
}

var _fundo: ColorRect
var _texto: Label


static func para_cena(caminho: String) -> String:
	return String(LEGENDAS.get(caminho.get_file().get_basename(), ""))


func _init(legenda: String = "") -> void:
	layer = 120
	name = "Transicao"
	_fundo = ColorRect.new()
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caminho := "res://assets/shaders/estatica.gdshader"
	if ResourceLoader.exists(caminho):
		var m := ShaderMaterial.new()
		m.shader = load(caminho)
		_fundo.material = m
	else:
		_fundo.color = Tema.FUNDO
	add_child(_fundo)
	_texto = Label.new()
	_texto.text = legenda
	_texto.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_texto.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_texto.add_theme_color_override("font_color", Tema.PERGAMINHO)
	_texto.add_theme_font_size_override("font_size", Tema.FONTE_G)
	_texto.add_theme_constant_override("outline_size", 8)
	_texto.add_theme_color_override("font_outline_color", Color.BLACK)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_texto.add_theme_font_override("font", maquina)
	add_child(_texto)


func _ready() -> void:
	Som.tocar("estatica")
	var forca := func(v: float):
		if _fundo.material != null:
			(_fundo.material as ShaderMaterial).set_shader_parameter("forca", v)
		else:
			_fundo.modulate.a = v
	var tw := create_tween()
	if _texto.text != "":
		_texto.visible_ratio = 0.0
		tw.tween_property(_texto, "visible_ratio", 1.0, 0.45)
		tw.tween_interval(0.25)
	else:
		_texto.visible = false
		tw.tween_interval(0.15)
	tw.tween_method(forca, 1.0, 0.0, 0.45).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_texto, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
