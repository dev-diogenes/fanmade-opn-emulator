class_name CerimoniaNex
extends CanvasLayer
## Cerimônia de NEX e patente (docs/23, C7): na volta de uma missão, a Base abre uma folha
## "Relatório de progressão" com a foto de cada agente que voltou, o NEX antes e depois, a
## patente e o carimbo PROMOVIDO, e quantas escolhas novas esperam na ficha. Quem morreu ou
## enlouqueceu entra no rodapé, em memória. Aparece uma vez por missão.
##   if CerimoniaNex.tem_o_que_mostrar(carreira.ultimo_relatorio): CerimoniaNex.abrir(self, carreira)

signal fechada
## "Transcender agora" no cartão de quem subiu (docs/32): a Base abre a sala desse agente.
signal transcender(agente: Agente)

var _papel: PanelContainer
var _carimbos: Array[Label] = []


static func tem_o_que_mostrar(r: Dictionary) -> bool:
	if r.is_empty() or r.get("cerimonia_vista", false):
		return false
	for ag in r.get("agentes", []):
		if int(ag.get("nex", 0)) > int(ag.get("nex_antes", 0)) or ag.get("promovido", false) or String(ag.get("situacao", "")) in ["morto", "insano"]:
			return true
	return false


static func abrir(pai: Node, carreira: Carreira) -> CerimoniaNex:
	var c := CerimoniaNex.new()
	c._montar(carreira)
	carreira.ultimo_relatorio["cerimonia_vista"] = true
	pai.add_child(c)
	return c


func _montar(carreira: Carreira) -> void:
	layer = 89
	name = "CerimoniaNex"
	var r := carreira.ultimo_relatorio
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.82)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_papel = PanelContainer.new()
	_papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(30, 22)))
	_papel.theme = Tema.tema_papel()
	_papel.rotation_degrees = -0.5
	centro.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_M)
	_papel.add_child(v)
	var cab := Label.new()
	cab.text = "ORDEM DA REALIDADE — RELATÓRIO DE PROGRESSÃO · MISSÃO %d" % int(r.get("missao", 0))
	cab.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
	v.add_child(cab)
	var t := Label.new()
	t.text = "Missão cumprida" if r.get("vitoria", false) else "Missão fracassada"
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 4)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	v.add_child(t)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", Tema.ESPACO_GG)
	v.add_child(linha)
	var por_id := {}
	for a in carreira.roster:
		por_id[a.id] = a
	var memoria: Array[String] = []
	for ag in r.get("agentes", []):
		if String(ag.get("situacao", "")) in ["morto", "insano"]:
			memoria.append("%s (%s)" % [ag.nome, "morto" if ag.situacao == "morto" else "perdido para o Outro Lado"])
			continue
		linha.add_child(_cartao(ag, por_id.get(String(ag.get("id", "")))))
	if not memoria.is_empty():
		var m := Label.new()
		m.text = "Em memória: " + ", ".join(PackedStringArray(memoria))
		m.add_theme_color_override("font_color", Tema.SANGUE)
		v.add_child(m)
	var botao := Button.new()
	botao.text = "Arquivar"
	botao.theme_type_variation = "BotaoPrincipal"
	botao.size_flags_horizontal = Control.SIZE_SHRINK_END
	botao.pressed.connect(fechar)
	v.add_child(botao)
	botao.grab_focus.call_deferred()


## Cartão de um agente: foto, NEX antes → depois, patente, carimbo e escolhas novas.
func _cartao(ag: Dictionary, agente: Agente) -> Control:
	var c := VBoxContainer.new()
	c.custom_minimum_size = Vector2(190, 0)
	c.add_theme_constant_override("separation", 4)
	var foto := FotoAgente.new()
	foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if agente != null:
		foto.mostrar(agente.classe_id, agente.aparencia, agente.tom, hash(agente.nome))
	foto.legenda = String(ag.nome)
	c.add_child(foto)
	var nex := Label.new()
	var subiu := int(ag.get("nex", 0)) > int(ag.get("nex_antes", 0))
	nex.text = "NEX %d%% → %d%%" % [int(ag.get("nex_antes", 0)), int(ag.get("nex", 0))] if subiu else "NEX %d%%" % int(ag.get("nex", 0))
	nex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nex.add_theme_color_override("font_color", Tema.TINTA)
	nex.add_theme_font_size_override("font_size", Tema.FONTE_M + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		nex.add_theme_font_override("font", ft)
	c.add_child(nex)
	var pat := Label.new()
	pat.text = "%s · %+d PP" % [ag.get("patente", ""), int(ag.get("pp", 0))]
	pat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pat.add_theme_color_override("font_color", Color(Tema.TINTA, 0.85))
	c.add_child(pat)
	if int(ag.get("pendencias", 0)) > 0:
		var p := Label.new()
		p.text = "%d escolha%s nova%s na ficha" % [int(ag.pendencias), "" if int(ag.pendencias) == 1 else "s", "" if int(ag.pendencias) == 1 else "s"]
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.add_theme_color_override("font_color", Tema.cor_sucesso(true))
		c.add_child(p)
		if agente != null:
			var ir := Button.new()
			ir.text = "✦ Transcender agora"
			ir.theme_type_variation = "BotaoPapel"
			ir.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ir.tooltip_text = "Ir à sala de %s e fazer as escolhas do novo NEX" % agente.nome
			ir.pressed.connect(func():
				transcender.emit(agente)
				fechar())
			c.add_child(ir)
	if ag.get("promovido", false):
		var carimbo := Label.new()
		carimbo.text = "PROMOVIDO"
		carimbo.add_theme_color_override("font_color", Tema.SANGUE_CLARO)
		carimbo.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Tema.SANGUE_CLARO, 3, 4, Vector2(10, 2)))
		carimbo.add_theme_font_size_override("font_size", Tema.FONTE_G)
		if ft != null:
			carimbo.add_theme_font_override("font", ft)
		carimbo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		carimbo.rotation_degrees = -7
		carimbo.modulate.a = 0.0
		c.add_child(carimbo)
		_carimbos.append(carimbo)
	return c


func _ready() -> void:
	Som.tocar("papel")
	# Os carimbos batem um a um, depois que a folha aparece
	var tw := create_tween()
	tw.tween_interval(0.6)
	for carimbo in _carimbos:
		tw.tween_callback(func():
			carimbo.pivot_offset = carimbo.size / 2.0
			carimbo.scale = Vector2.ONE * 1.6
			Som.tocar("carimbo"))
		tw.tween_property(carimbo, "modulate:a", 0.9, 0.01)
		tw.parallel().tween_property(carimbo, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_interval(0.35)


func fechar() -> void:
	fechada.emit()
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()
