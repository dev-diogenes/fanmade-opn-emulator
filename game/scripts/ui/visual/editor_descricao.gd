class_name EditorDescricao
extends CanvasLayer
## Editar o conceito e a descrição de um agente depois da criação (docs/27): conceito,
## gênero, idade e os toques finais do livro (aparência, personalidade, histórico, objetivo).
## Só apresentação; os limites são os de Carreira.LIMITE_DESCRICAO.
##   EditorDescricao.abrir(self, agente, func(): _salvar())

signal salvo

var agente: Agente
var campos: Dictionary = {}   ## id -> LineEdit/TextEdit
var _idade: SpinBox

const CAMPOS := [
	["conceito", "Conceito", false], ["genero", "Gênero", false], ["aparencia_texto", "Aparência", false],
	["personalidade", "Personalidade", false], ["historico", "Histórico", true], ["objetivo", "Objetivo", false],
]


static func abrir(pai: Node, a: Agente, ao_salvar: Callable = Callable()) -> EditorDescricao:
	var e := EditorDescricao.new()
	e.agente = a
	e._montar()
	if ao_salvar.is_valid():
		e.salvo.connect(ao_salvar)
	pai.add_child(e)
	Som.tocar("papel")
	return e


func _montar() -> void:
	layer = 94
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.78)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(26, 18)))
	papel.theme = Tema.tema_papel()
	papel.custom_minimum_size = Vector2(620, 0)
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	papel.add_child(v)
	var t := Label.new()
	t.text = "DESCRIÇÃO DE %s" % agente.nome.to_upper()
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G)
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	for c in CAMPOS:
		var id: String = c[0]
		v.add_child(FichaAgente.aba(c[1]))
		var limite: int = Carreira.LIMITE_DESCRICAO[id]
		var atual := String(agente.get(id))
		if c[2]:
			var te := TextEdit.new()
			te.custom_minimum_size = Vector2(0, 100)
			te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			te.text = atual
			te.text_changed.connect(func():
				if te.text.length() > limite:
					te.text = te.text.left(limite))
			campos[id] = te
		else:
			var le := LineEdit.new()
			le.max_length = limite
			le.text = atual
			campos[id] = le
		v.add_child(campos[id])
		if id == "genero":
			v.add_child(FichaAgente.aba("Idade"))
			_idade = SpinBox.new()
			_idade.min_value = 0
			_idade.max_value = 99
			_idade.suffix = "anos"
			_idade.value = agente.idade_anos
			_idade.tooltip_text = "0 = não informada. A faixa da regra opcional de idade não muda por aqui."
			v.add_child(_idade)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	botoes.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(botoes)
	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.theme_type_variation = "BotaoPapel"
	cancelar.pressed.connect(queue_free)
	botoes.add_child(cancelar)
	var salvar := Button.new()
	salvar.text = "Salvar"
	salvar.theme_type_variation = "BotaoPrincipal"
	salvar.pressed.connect(salvar_e_fechar)
	botoes.add_child(salvar)


## Grava no agente (com os limites) e avisa quem abriu, que salva a carreira.
func salvar_e_fechar() -> void:
	for id in campos:
		var texto := String(campos[id].text).strip_edges().left(Carreira.LIMITE_DESCRICAO[id])
		agente.set(id, texto)
	agente.idade_anos = int(_idade.value)
	salvo.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
