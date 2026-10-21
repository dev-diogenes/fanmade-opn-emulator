class_name DossieAgente
extends CanvasLayer
## Ficha do agente durante o jogo (docs/13; formato da ficha oficial desde o docs/25): as
## páginas Agente, Habilidades e inventário (com "Usar" no mapa) e Rituais.
## Abre clicando no retrato do agente ou com F (o agente da vez). Esc ou clique fora fecha.
##   DossieAgente.abrir(self, agente, usar_item)   # usar_item(item_id) = null fora do mapa

var agente: Agente
var _usar_item: Callable


## Texto da ficha em BBCode, com cores legíveis sobre papel (a Base usa o mesmo).
## `completa` = false omite o cabeçalho, os números e os atributos (a ficha em blocos da Base
## mostra isso em barras e no pentágono, docs/23) e põe as perícias em duas colunas.
static func ficha_bbcode(a: Agente, completa: bool = true) -> String:
	var rs := a.ruleset
	var linhas: Array[String] = []
	if completa:
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
	if completa:
		linhas.append("[color=#4e4034]Perícias:[/color] " + ", ".join(pers))
	else:
		var tabela := "[table=2]"
		for p in pers:
			tabela += "[cell]%s     [/cell]" % p
		if pers.size() % 2 == 1:
			tabela += "[cell][/cell]"
		linhas.append("[b]Perícias[/b]\n" + tabela + "[/table]")
	var habs := PackedStringArray()
	for h in a.habilidades():
		habs.append(h.nome if h.get("implementado", false) else _sem_efeito(h.nome))
	linhas.append("[color=#4e4034]Habilidades:[/color] " + ", ".join(habs))
	if not a.poderes_paranormais.is_empty():
		var pps := PackedStringArray()
		for e in a.poderes_paranormais:
			pps.append(rs.poder_paranormal(e.id).get("nome", e.id) + ("" if String(e.get("escolha", "")) == "" else " (%s)" % e.escolha))
		linhas.append("[color=#5b2a86]Poderes paranormais:[/color] %s%s" % [", ".join(pps), "  ·  afinidade: " + a.afinidade if a.afinidade != "" else ""])
	if not a.rituais.is_empty():
		var rits := PackedStringArray()
		for rid in a.rituais:
			var nome_r: String = rs.ritual(rid).get("nome", rid)
			rits.append(nome_r if rs.ritual(rid).get("implementado", false) else _sem_efeito(nome_r))
		linhas.append("[color=#5b2a86]Rituais:[/color] " + ", ".join(rits))
	if not a.lesoes.is_empty():
		linhas.append("[color=#9a4a10]Lesões:[/color] " + ", ".join(PackedStringArray(a.lesoes)))
	if not a.condicoes.is_empty():
		linhas.append("[color=#a51c1c]Condições:[/color] " + ", ".join(PackedStringArray(a.condicoes.keys())))
	return "\n".join(linhas)


## Nome em itálico com dica ao passar o mouse, no lugar do asterisco e da nota de rodapé
## de desenvolvimento (docs/21, C4).
static func _sem_efeito(nome: String) -> String:
	return "[i][hint=Ainda sem efeito nas regras deste jogo]%s[/hint][/i]" % nome


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
	var ficha := FichaAgente.new()
	ficha.custom_minimum_size = Vector2(1180, 660)
	centro.add_child(ficha)
	ficha.mostrar(agente, _usar_item)
	ficha.item_usado.connect(func(_id): queue_free())   # usou: volta ao mapa
	_ficha = ficha


var _ficha: FichaAgente


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or Atalhos.pressionou(evento, "ficha"):
		get_viewport().set_input_as_handled()
		queue_free()
