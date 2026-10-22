class_name NotaInsanidade
extends CanvasLayer
## Efeito de insanidade novo (p.111-113, docs/49): uma nota escura, rasgada do caderno de campo,
## aparece no alto da tela com o agente, o 1d20 e o efeito datilografado. Não bloqueia: some
## sozinha ou com um clique. Duas ao mesmo tempo (dano em área) ficam uma embaixo da outra.
##   NotaInsanidade.mostrar(self, agente, {"id": 6, "ate_o_fim": false})

const DURACAO := 8.0

var _papel: PanelContainer
var _fechando := false
var _datilografar: Array[Label] = []


static func mostrar(pai: Node, a: Agente, efeito: Dictionary) -> NotaInsanidade:
	var abertas := pai.find_children("*", "NotaInsanidade", false, false).size()
	var n := NotaInsanidade.new()
	n.name = "NotaInsanidade"
	n._montar(a, efeito, abertas)
	pai.add_child(n)
	return n


func _montar(a: Agente, efeito: Dictionary, ordem: int) -> void:
	layer = 73
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	var info := a.ruleset.efeito_insanidade(int(efeito.id))
	_papel = PanelContainer.new()
	var estilo := Tema.caixa(Color(0.06, 0.02, 0.03, 0.95), Tema.SANGUE, 2, 2, Vector2(20, 14))
	estilo.shadow_color = Color(Tema.SANGUE, 0.45)
	estilo.shadow_size = 14
	_papel.add_theme_stylebox_override("panel", estilo)
	_papel.anchor_left = 0.5
	_papel.anchor_right = 0.5
	_papel.offset_left = -250
	_papel.offset_right = 250
	_papel.offset_top = 120 + ordem * 170
	_papel.rotation_degrees = -1.2 if ordem % 2 == 0 else 0.9
	_papel.mouse_filter = Control.MOUSE_FILTER_STOP
	_papel.tooltip_text = "Clique para fechar"
	_papel.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: _fechar())
	raiz.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_papel.add_child(v)
	var t := Label.new()
	t.text = "EFEITO DE INSANIDADE"
	t.add_theme_color_override("font_color", Tema.SANGUE_CLARO.lightened(0.15))
	t.add_theme_font_size_override("font_size", Tema.FONTE_M)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	v.add_child(t)
	var quem := Label.new()
	var duracao := "até o fim da missão" if efeito.get("ate_o_fim", false) else "enquanto a SAN estiver abaixo da metade"
	quem.text = "%s  ·  1d20: %d  ·  %s" % [a.nome, int(efeito.id), duracao]
	quem.add_theme_color_override("font_color", Color(Tema.PERGAMINHO, 0.6))
	quem.add_theme_font_size_override("font_size", Tema.FONTE_P)
	v.add_child(quem)
	var nome := Label.new()
	nome.text = String(info.get("nome", "?"))
	nome.add_theme_color_override("font_color", Tema.PERGAMINHO)
	nome.add_theme_font_size_override("font_size", Tema.FONTE_G + 4)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		nome.add_theme_font_override("font", maquina)
	v.add_child(nome)
	var texto := Label.new()
	texto.text = String(info.get("texto", ""))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(450, 0)
	texto.add_theme_color_override("font_color", Color(Tema.PERGAMINHO, 0.88))
	texto.add_theme_font_size_override("font_size", Tema.FONTE_M)
	v.add_child(texto)
	var regra := Label.new()
	regra.text = "Só de interpretação: não muda os testes (p.111)."
	regra.add_theme_color_override("font_color", Color(Tema.PERGAMINHO, 0.45))
	regra.add_theme_font_size_override("font_size", Tema.FONTE_P - 1)
	v.add_child(regra)
	_datilografar = [nome, texto]


func _ready() -> void:
	Som.tocar("glitch")
	for l in _datilografar:
		Tema.datilografar(l, 0.03, 1.4)
	_papel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(DURACAO)
	tw.tween_callback(_fechar)


func _fechar() -> void:
	if _fechando or not is_inside_tree():
		return
	_fechando = true
	var tw := create_tween()
	tw.tween_property(_papel, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
