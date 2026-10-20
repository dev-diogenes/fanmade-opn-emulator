class_name DialogoPapel
extends CanvasLayer
## Diálogo modal em papel (docs/10): a tela escurece e um bilhete datilografado pergunta.
## Substitui as janelas padrão do Godot. Esc ou "voltar" fecha sem confirmar.
##   DialogoPapel.perguntar(self, "Nova carreira", "Isso apaga o save…", "Apagar", _nova)

signal respondido(confirmou: bool)

var _texto: Label
var _confirmar: Button


static func perguntar(pai: Node, titulo: String, texto: String, sim: String, ao_confirmar: Callable,
		nao: String = "Voltar", perigoso: bool = true) -> DialogoPapel:
	var d := DialogoPapel.new()
	d._montar(titulo, texto, sim, nao, perigoso)
	d.respondido.connect(func(ok: bool):
		if ok:
			ao_confirmar.call())
	pai.add_child(d)
	return d


func _montar(titulo: String, texto: String, sim: String, nao: String, perigoso: bool) -> void:
	layer = 95
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.78)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(28, 22)))
	papel.theme = Tema.tema_papel()
	papel.custom_minimum_size = Vector2(460, 0)
	papel.rotation_degrees = -0.8
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_G)
	papel.add_child(v)
	var t := Label.new()
	t.text = titulo.to_upper()
	t.add_theme_color_override("font_color", Tema.SANGUE if perigoso else Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	_texto = Label.new()
	_texto.text = texto
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(400, 0)
	v.add_child(_texto)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	botoes.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(botoes)
	var voltar := Button.new()
	voltar.text = nao
	voltar.theme_type_variation = "BotaoPapel"
	voltar.pressed.connect(_responder.bind(false))
	botoes.add_child(voltar)
	_confirmar = Button.new()
	_confirmar.text = sim
	_confirmar.theme_type_variation = "BotaoPrincipal"
	_confirmar.pressed.connect(_responder.bind(true))
	botoes.add_child(_confirmar)


func _ready() -> void:
	Tema.datilografar(_texto)
	_confirmar.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_responder(false)


func _responder(ok: bool) -> void:
	respondido.emit(ok)
	queue_free()
