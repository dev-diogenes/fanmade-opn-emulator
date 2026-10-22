class_name PainelInterludio
extends CanvasLayer
## Interlúdio (p.92-93, docs/48): uma folha com os agentes que estão no hex. Cada um escolhe
## até duas ações (Dormir, Relaxar, Alimentar-se, Exercitar-se, Ler, Revisar Caso); Alimentar-se
## pede o prato e Revisar Caso pede o ponto. Tudo por seleção. "Encerrar interlúdio" envia as
## escolhas (comando `interludio`, lockstep no online).
##   PainelInterludio.abrir(self, missao, func(escolhas): ...)

const NOMES := {"dormir": "Dormir", "relaxar": "Relaxar", "alimentar": "Alimentar-se", "exercitar": "Exercitar-se",
	"ler": "Ler", "revisar": "Revisar caso"}

var missao: Missao
var ao_encerrar: Callable
var escolhas: Dictionary = {}   ## agente_id -> {"acoes": [], "prato": "", "revisar": ""}
var _linhas: Dictionary = {}    ## agente_id -> VBoxContainer
var _encerrar: Button


static func abrir(pai: Node, m: Missao, ao_fim: Callable) -> PainelInterludio:
	var p := PainelInterludio.new()
	p.missao = m
	p.ao_encerrar = ao_fim
	p._montar()
	pai.add_child(p)
	return p


func _montar() -> void:
	layer = 94
	name = "PainelInterludio"
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.8)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(26, 18)))
	papel.theme = Tema.tema_papel()
	papel.custom_minimum_size = Vector2(860, 0)
	papel.rotation_degrees = -0.3
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_M)
	papel.add_child(v)
	var t := Label.new()
	t.text = "INTERLÚDIO"
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Um lugar seguro por algumas horas (descanso %s). Cada agente faz até duas ações. Dormir e relaxar recuperam o limite de PE do NEX (p.93)." % missao.condicao_interludio()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.add_theme_color_override("font_color", Color(Tema.TINTA, 0.8))
	sub.add_theme_font_size_override("font_size", Tema.FONTE_P)
	v.add_child(sub)
	for a in missao.participantes_interludio():
		escolhas[a.id] = {"acoes": [], "prato": "", "revisar": ""}
		var linha := VBoxContainer.new()
		linha.add_theme_constant_override("separation", Tema.ESPACO_P)
		v.add_child(linha)
		_linhas[a.id] = linha
		_redesenhar(a)
	var rodape := HBoxContainer.new()
	rodape.alignment = BoxContainer.ALIGNMENT_END
	rodape.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(rodape)
	var cancelar := Button.new()
	cancelar.text = "Voltar"
	cancelar.theme_type_variation = "BotaoPapel"
	cancelar.pressed.connect(queue_free)
	rodape.add_child(cancelar)
	_encerrar = Button.new()
	_encerrar.text = "Encerrar interlúdio"
	_encerrar.theme_type_variation = "BotaoPrincipal"
	_encerrar.pressed.connect(func():
		ao_encerrar.call(escolhas.duplicate(true))
		queue_free())
	rodape.add_child(_encerrar)
	_atualizar_encerrar()


func _agente(id: String) -> Agente:
	for a in missao.agentes:
		if a.id == id:
			return a
	return null


func _redesenhar(a: Agente) -> void:
	var linha: VBoxContainer = _linhas[a.id]
	for f in linha.get_children():
		f.queue_free()
	var e: Dictionary = escolhas[a.id]
	var cab := Label.new()
	cab.text = "%s  ·  PV %d/%d · PE %d/%d · SAN %d/%d  ·  ações %d/2" % [a.nome, a.pv, a.pv_maximo, a.pe, a.pe_maximo, a.san, a.san_maximo, (e.acoes as Array).size()]
	cab.add_theme_color_override("font_color", Tema.TINTA)
	var negrito := Tema._fonte(Tema.ARQ_NEGRITO)
	if negrito != null:
		cab.add_theme_font_override("font", negrito)
	linha.add_child(cab)
	var botoes := HBoxContainer.new()
	botoes.add_theme_constant_override("separation", Tema.ESPACO_P)
	linha.add_child(botoes)
	for acao in Missao.ACOES_INTERLUDIO:
		var b := Button.new()
		b.text = NOMES[acao]
		b.toggle_mode = true
		b.theme_type_variation = "BotaoPapel"
		b.button_pressed = acao in e.acoes
		b.tooltip_text = _dica(a, acao)
		b.disabled = acao == "revisar" and missao.pontos_revisaveis().is_empty()
		b.pressed.connect(func(): _alternar(a, acao))
		botoes.add_child(b)
	if "alimentar" in e.acoes:
		_sub_lista(linha, "Prato:", missao._cfg.interludio.pratos.keys(), e, "prato",
			func(k): return String(missao._cfg.interludio.pratos[k].nome), func(k): return String(missao._cfg.interludio.pratos[k].texto), a)
	if "revisar" in e.acoes:
		_sub_lista(linha, "Revisar:", missao.pontos_revisaveis(), e, "revisar", func(k): return _nome_ponto(k), func(_k): return "", a)


func _sub_lista(linha: VBoxContainer, titulo: String, opcoes: Array, e: Dictionary, chave: String, nome: Callable, dica: Callable, a: Agente) -> void:
	var h := HFlowContainer.new()
	h.add_theme_constant_override("h_separation", Tema.ESPACO_P)
	linha.add_child(h)
	var l := Label.new()
	l.text = titulo
	l.add_theme_color_override("font_color", Color(Tema.TINTA, 0.8))
	h.add_child(l)
	for k in opcoes:
		var b := Button.new()
		b.text = nome.call(k)
		b.tooltip_text = dica.call(k)
		b.toggle_mode = true
		b.theme_type_variation = "BotaoPapel"
		b.button_pressed = String(e.get(chave, "")) == String(k)
		b.pressed.connect(func():
			e[chave] = String(k)
			_redesenhar(a)
			_atualizar_encerrar())
		h.add_child(b)


func _nome_ponto(k: String) -> String:
	var partes := k.split(":")
	var cena := missao.cena_info(partes[0])
	for p in cena.get("pontos", []):
		if p.id == partes[1]:
			return "%s: %s" % [cena.get("nome", partes[0]), p.nome]
	return k


func _dica(a: Agente, acao: String) -> String:
	var lim := a.ruleset.limite_pe(a.nex)
	match acao:
		"dormir": return "Recupera %d PV e %d PE (limite de PE do NEX)." % [lim, lim]
		"relaxar": return "Recupera %d SAN, +1 por agente que relaxar neste interlúdio (contando você)." % lim
		"alimentar": return "Um prato com benefício neste interlúdio."
		"exercitar": return "+1d6 no próximo teste de AGI, FOR ou VIG desta missão (até %d guardados)." % maxi(1, a.atributo("vig"))
		"ler": return "+1d6 no próximo teste de INT ou PRE desta missão (até %d guardados)." % maxi(1, a.atributo("int"))
		"revisar": return "Volta a um ponto que ficou para trás numa cena já vista e testa para achar a pista."
	return ""


func _alternar(a: Agente, acao: String) -> void:
	var e: Dictionary = escolhas[a.id]
	var acoes: Array = e.acoes
	if acao in acoes:
		acoes.erase(acao)
	elif acoes.size() < 2:
		acoes.append(acao)
	_redesenhar(a)
	_atualizar_encerrar()


## Encerrar só quando alguém escolheu algo, e quem come ou revisa escolheu o quê.
func _atualizar_encerrar() -> void:
	if _encerrar == null:
		return
	var algum := false
	var completo := true
	for id in escolhas:
		var e: Dictionary = escolhas[id]
		if not (e.acoes as Array).is_empty():
			algum = true
		if "alimentar" in e.acoes and String(e.prato) == "":
			completo = false
		if "revisar" in e.acoes and String(e.revisar) == "":
			completo = false
	_encerrar.disabled = not (algum and completo)


func _unhandled_key_input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed:
		return
	get_viewport().set_input_as_handled()
	if (evento as InputEventKey).keycode == KEY_ESCAPE:
		queue_free()
