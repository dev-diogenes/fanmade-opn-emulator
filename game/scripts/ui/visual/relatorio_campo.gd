class_name RelatorioCampo
extends PanelContainer
## Registro recolhível (docs/09): uma faixa riscada com "▸ Relatório de campo" que abre
## para cima, mostrando o registro. Fechado, mostra só a última linha.

signal alternado(aberto: bool)

var registro: RichTextLabel
var aberto := false
var altura_aberto := 280.0
var _cabecalho: Button


func _init() -> void:
	add_theme_stylebox_override("panel", MolduraRiscada.criar(Tema.TRACO, Color(Tema.FUNDO, 0.88), Vector2(12, 6)))
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var v := VBoxContainer.new()
	add_child(v)
	_cabecalho = Button.new()
	_cabecalho.flat = true
	_cabecalho.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_cabecalho.clip_text = true
	_cabecalho.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_cabecalho.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	_cabecalho.add_theme_color_override("font_hover_color", Tema.OURO_CLARO)
	_cabecalho.pressed.connect(alternar)
	v.add_child(_cabecalho)
	registro = RichTextLabel.new()
	registro.bbcode_enabled = true
	registro.scroll_following = true
	registro.visible = false
	registro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(registro)
	_atualizar_cabecalho()


## Ancora no canto inferior direito, com a largura dada.
func ancorar_embaixo_direita(largura: float, margem: float = 16.0, baixo: float = 8.0) -> void:
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -largura - margem
	offset_right = -margem
	offset_bottom = -baixo
	offset_top = -baixo - 30.0


func append_text(texto: String) -> void:
	registro.append_text(texto)
	_atualizar_cabecalho()


func alternar() -> void:
	aberto = not aberto
	registro.visible = aberto
	offset_top = offset_bottom - (altura_aberto if aberto else 30.0)
	_atualizar_cabecalho()
	alternado.emit(aberto)


func _atualizar_cabecalho() -> void:
	if _cabecalho == null:
		return
	var ultima := ""
	if registro != null and not aberto:
		var linhas := registro.get_parsed_text().strip_edges().split("\n")
		ultima = "  —  " + linhas[linhas.size() - 1] if linhas.size() > 0 and linhas[linhas.size() - 1] != "" else ""
	_cabecalho.text = ("▾" if aberto else "▸") + " Relatório de campo" + ultima
