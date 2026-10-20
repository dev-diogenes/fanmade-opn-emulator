class_name DossieAgente
extends CanvasLayer
## Ficha e inventário do agente durante o jogo (docs/13): uma pasta em papel com a ficha
## (atributos, perícias, habilidades, rituais) e o inventário (itens, espaços, uso).
## Abre clicando no retrato do agente ou com F (o agente da vez). Esc ou clique fora fecha.
##   DossieAgente.abrir(self, agente, usar_item)   # usar_item(item_id) = null fora do mapa

var agente: Agente
var _usar_item: Callable


## Texto da ficha em BBCode, com cores legíveis sobre papel (a Base usa o mesmo).
static func ficha_bbcode(a: Agente) -> String:
	var rs := a.ruleset
	var linhas: Array[String] = []
	linhas.append("[b]%s[/b] — %s (%s), origem %s" % [a.nome, rs.classe(a.classe_id).nome, a.trilha_id if a.trilha_id != "" else "sem trilha", rs.origem(a.origem_id).nome if a.origem_id != "" else "—"])
	linhas.append("NEX %d%%   %s (%d PP)" % [a.nex, a.patente().get("nome", "?"), a.pp])
	linhas.append("PV %d/%d   PE %d/%d   SAN %d/%d   Defesa %d   Desloc. %d m" % [a.pv, a.pv_maximo, a.pe, a.pe_maximo, a.san, a.san_maximo, a.defesa(), int(a.deslocamento_m())])
	var attrs := PackedStringArray()
	for k in ["agi", "for", "int", "pre", "vig"]:
		attrs.append("%s %d" % [k.to_upper(), a.atributo(k)])
	linhas.append("  ".join(attrs))
	var pers := PackedStringArray()
	for p in a.pericias:
		pers.append("%s %+d" % [rs.pericia(p).nome, a.bonus_pericia(p)])
	linhas.append("[color=#6b5a48]Perícias:[/color] " + ", ".join(pers))
	var habs := PackedStringArray()
	for h in a.habilidades():
		habs.append(h.nome + ("" if h.get("implementado", false) else "*"))
	linhas.append("[color=#6b5a48]Habilidades:[/color] " + ", ".join(habs))
	if not a.poderes_paranormais.is_empty():
		var pps := PackedStringArray()
		for e in a.poderes_paranormais:
			pps.append(rs.poder_paranormal(e.id).get("nome", e.id) + ("" if String(e.get("escolha", "")) == "" else " (%s)" % e.escolha))
		linhas.append("[color=#5b2a86]Poderes paranormais:[/color] %s%s" % [", ".join(pps), "  ·  afinidade: " + a.afinidade if a.afinidade != "" else ""])
	if not a.rituais.is_empty():
		var rits := PackedStringArray()
		for rid in a.rituais:
			rits.append(rs.ritual(rid).get("nome", rid) + ("" if rs.ritual(rid).get("implementado", false) else "*"))
		linhas.append("[color=#5b2a86]Rituais:[/color] " + ", ".join(rits))
	if not a.lesoes.is_empty():
		linhas.append("[color=#9a4a10]Lesões:[/color] " + ", ".join(PackedStringArray(a.lesoes)))
	if not a.condicoes.is_empty():
		linhas.append("[color=#a51c1c]Condições:[/color] " + ", ".join(PackedStringArray(a.condicoes.keys())))
	linhas.append("[color=#6b5a48]* ainda sem efeito no motor[/color]")
	return "\n".join(linhas)


static func abrir(pai: Node, p_agente: Agente, usar_item: Callable = Callable()) -> DossieAgente:
	for antigo in pai.find_children("*", "DossieAgente", false, false):
		antigo.queue_free()
	var d := DossieAgente.new()
	d.agente = p_agente
	d._usar_item = usar_item
	d._montar()
	pai.add_child(d)
	Som.tocar("papel")
	return d


func _montar() -> void:
	layer = 85
	name = "DossieAgente"
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.7)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: queue_free())
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var pasta := TabContainer.new()
	pasta.custom_minimum_size = Vector2(760, 470)
	centro.add_child(pasta)

	var ficha := PanelContainer.new()
	ficha.name = "Ficha"
	ficha.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(24, 18)))
	ficha.theme = Tema.tema_papel()
	pasta.add_child(ficha)
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.text = ficha_bbcode(agente)
	texto.add_theme_color_override("default_color", Tema.TINTA)
	ficha.add_child(texto)

	var inv := PanelContainer.new()
	inv.name = "Inventário"
	inv.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(24, 18)))
	inv.theme = Tema.tema_papel()
	pasta.add_child(inv)
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv.add_child(rolagem)
	var lista := VBoxContainer.new()
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista.add_theme_constant_override("separation", 6)
	rolagem.add_child(lista)
	var cab := Label.new()
	cab.text = "Carga: %d / %d espaços%s" % [agente.espacos_usados(), agente.capacidade_carga(), "  —  SOBRECARREGADO" if agente.sobrecarregado() else ""]
	lista.add_child(cab)
	var contagem := {}
	for item_id in agente.equipamento:
		contagem[item_id] = contagem.get(item_id, 0) + 1
	if contagem.is_empty():
		var vazio := Label.new()
		vazio.text = "Nada no inventário."
		lista.add_child(vazio)
	for item_id in contagem:
		lista.add_child(_linha_item(item_id, contagem[item_id]))


func _linha_item(item_id: String, qtd: int) -> Control:
	var info := agente.ruleset.equipamento(item_id)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", Tema.ESPACO_M)
	var nome := Label.new()
	var detalhes := PackedStringArray()
	detalhes.append("cat. %s" % ["0", "I", "II", "III", "IV", "V"][mini(5, int(info.get("categoria", 0)))])
	detalhes.append("%d esp." % int(info.get("espacos", 1)))
	if info.has("dano"):
		detalhes.append("dano %s" % info.dano)
	if info.get("uso", {}).has("cura"):
		detalhes.append("cura %s" % info.uso.cura)
	if item_id == agente.arma_id:
		detalhes.append("empunhada")
	nome.text = "%s%s  ·  %s" % [info.get("nome", item_id), " ×%d" % qtd if qtd > 1 else "", "  ·  ".join(detalhes)]
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if info.has("maldicoes"):
		nome.add_theme_color_override("font_color", Tema.SANGUE)
		nome.tooltip_text = "Maldições: %s" % ", ".join(PackedStringArray(info.maldicoes.map(func(m): return m.nome)))
		nome.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(nome)
	if _usar_item.is_valid() and info.get("uso", {}).has("cura"):
		var usar := Button.new()
		usar.text = "Usar"
		usar.theme_type_variation = "BotaoPapel"
		usar.pressed.connect(func():
			_usar_item.call(item_id)
			queue_free())
		h.add_child(usar)
	return h


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or (evento is InputEventKey and evento.pressed and evento.keycode == KEY_F):
		get_viewport().set_input_as_handled()
		queue_free()
