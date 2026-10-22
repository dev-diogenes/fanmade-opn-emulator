class_name FaixaIniciativa
extends HBoxContainer
## Faixa de iniciativa (docs/57): quem age agora e quem vem depois, como a fila de retratos do
## For The King 2. A ficha da vez fica maior e com borda dourada; os agentes têm a cor do
## jogador e as criaturas, a do elemento. Um "↻" marca onde começa a próxima rodada.
##   faixa.atualizar(combate, {agente: cor})

const MOSTRAR := 7
const NOME_MAX := 18


func _init() -> void:
	add_theme_constant_override("separation", 4)
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func atualizar(combate: Combate, cores: Dictionary) -> void:
	for f in get_children():
		remove_child(f)
		f.queue_free()
	visible = combate != null and not combate.encerrado and combate.ser_atual() != null
	if not visible:
		return
	var primeiro := true
	for item in combate.proximos(MOSTRAR):
		if item.nova_rodada:
			var volta := Label.new()
			volta.text = "↻"
			volta.tooltip_text = "Rodada seguinte"
			volta.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
			add_child(volta)
		var ser: Ser = item.ser
		add_child(_ficha(ser, primeiro, _cor(ser, cores), int(combate.iniciativas.get(ser, 0))))
		primeiro = false


func _cor(ser: Ser, cores: Dictionary) -> Color:
	if ser is Ameaca:
		return Tema.ELEMENTO.get((ser as Ameaca).elemento, Tema.PERIGO)
	return cores.get(ser, Tema.OURO)


func _ficha(ser: Ser, da_vez: bool, cor: Color, iniciativa: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	p.tooltip_text = "%s · Iniciativa %d%s" % [ser.nome, iniciativa, " · age agora" if da_vez else ""]
	var fundo := Color(Tema.PEDRA, 0.95 if da_vez else 0.8)
	var borda := Tema.OURO_CLARO if da_vez else cor
	p.add_theme_stylebox_override("panel", Tema.caixa(fundo, borda, 2 if da_vez else 1, 4, Vector2(8 if da_vez else 6, 3)))
	var l := Label.new()
	l.text = "%s %s" % [_icone(ser), nome_curto(ser.nome)]
	l.add_theme_font_size_override("font_size", Tema.FONTE_P + (2 if da_vez else 0))
	l.add_theme_color_override("font_color", Tema.OURO_CLARO if da_vez else (cor.lightened(0.25) if ser is Ameaca else Tema.PERGAMINHO))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(l)
	if ser.tem(Ser.MORRENDO) or ser.tem(Ser.ENLOUQUECENDO):
		p.modulate = Color(1, 1, 1, 0.6)
	return p


func _icone(ser: Ser) -> String:
	if ser is Agente:
		return CartaoAgente.ICONE_CLASSE.get((ser as Agente).classe_id, "●")
	return "◆"


## "o Sacerdote Carmesim" -> "Sacerdote Carmesim"; nomes longos terminam em reticências.
static func nome_curto(nome: String) -> String:
	var n := nome.strip_edges()
	for artigo in ["o ", "a ", "os ", "as "]:
		if n.begins_with(artigo):
			n = n.substr(artigo.length())
			break
	if n.length() > NOME_MAX:
		n = n.substr(0, NOME_MAX - 1).strip_edges() + "…"
	return n
