class_name Transcender
extends CanvasLayer
## Transcender (docs/31): subir de NEX é um ritual. O agente entra na própria sala, anda com
## WASD (ou as setas, ou o botão "Ir ao sigilo") até o sigilo no meio do chão, ajoelha e o
## círculo acende; então as escolhas do novo NEX aparecem num papel sobre a cena. Feitas
## todas, ele se levanta e volta à Base. As escolhas são as mesmas da Base (Progressao).
##   Transcender.abrir(base, agente)

var base: Node            ## a Base (monta as escolhas e aplica)
var agente: Agente
var sala: SalaTranscender
var no_ritual := false
var _vista: SubViewportContainer
var _dica: Label
var _papel: PanelContainer
var _caixa: VBoxContainer
var _indo := false        ## o botão "Ir ao sigilo" leva o agente sozinho
var _botao_ir: Button


static func abrir(p_base: Node, a: Agente) -> Transcender:
	var t := Transcender.new()
	t.base = p_base
	t.agente = a
	t._montar()
	p_base.add_child(t)
	if p_base.has_signal("pendencias_mudaram"):
		p_base.pendencias_mudaram.connect(t._ao_aplicar)
	return t


func _montar() -> void:
	layer = 87
	name = "Transcender"
	add_to_group("papel_modal")   # o tour do tutorial espera ele fechar (docs/57)
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	_vista = SubViewportContainer.new()
	_vista.stretch = true
	_vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	Tema.veu(_vista)
	Tema.membrana_na_tela(_vista, 60)   # o Outro Lado está perto: um pouco de véu
	add_child(_vista)
	var vp := SubViewport.new()
	Qualidade.vista(vp)
	_vista.add_child(vp)
	sala = SalaTranscender.new()
	vp.add_child(sala)
	sala.construir(agente)
	# Cabeçalho e dica
	var topo := VBoxContainer.new()
	topo.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	topo.grow_horizontal = Control.GROW_DIRECTION_BOTH
	topo.offset_top = 24
	topo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(topo)
	var t := Label.new()
	t.text = "TRANSCENDER · %s · NEX %d%%" % [agente.nome.to_upper(), agente.nex]
	t.theme_type_variation = "Titulo"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	topo.add_child(t)
	_dica = Label.new()
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dica.add_theme_color_override("font_color", Tema.PERGAMINHO)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_dica.add_theme_font_override("font", maquina)
	_dica.text = "Ande até o sigilo (WASD ou setas)."
	topo.add_child(_dica)
	# Botões no canto: ir sozinho (acessibilidade) e sair
	var botoes := HBoxContainer.new()
	botoes.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	botoes.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	botoes.grow_vertical = Control.GROW_DIRECTION_BEGIN
	botoes.offset_right = -20
	botoes.offset_bottom = -20
	botoes.add_theme_constant_override("separation", Tema.ESPACO_M)
	add_child(botoes)
	_botao_ir = Button.new()
	_botao_ir.text = "Ir ao sigilo   ⏎"
	_botao_ir.pressed.connect(func(): _indo = true)
	botoes.add_child(_botao_ir)
	var sair := Button.new()
	sair.text = "Sair da sala"
	sair.pressed.connect(fechar)
	botoes.add_child(sair)
	# O papel das escolhas, à direita (o agente ajoelhado fica à esquerda), escondido até o ritual
	var centro := CenterContainer.new()
	centro.anchor_left = 0.52
	centro.anchor_right = 1.0
	centro.anchor_bottom = 1.0
	centro.offset_right = -24
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	_papel = PanelContainer.new()
	_papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(24, 18)))
	_papel.theme = Tema.tema_papel()
	_papel.custom_minimum_size = Vector2(520, 0)
	_papel.rotation_degrees = -0.6
	_papel.visible = false
	centro.add_child(_papel)
	_caixa = VBoxContainer.new()
	_caixa.add_theme_constant_override("separation", Tema.ESPACO_M)
	_papel.add_child(_caixa)


func _ready() -> void:
	Som.tocar("papel")
	Som.ambiente(0.6)


func _process(delta: float) -> void:
	if no_ritual or sala == null:
		return
	var entrada := Vector2.ZERO
	if Atalhos.segurando("mover_cima"): entrada.y -= 1
	if Atalhos.segurando("mover_baixo"): entrada.y += 1
	if Atalhos.segurando("mover_esquerda"): entrada.x -= 1
	if Atalhos.segurando("mover_direita"): entrada.x += 1
	var dir := Vector3.ZERO
	if _indo:
		dir = -sala.figura.position
		dir.y = 0
	elif entrada != Vector2.ZERO:
		var g := sala.rig.giro
		var frente := Vector3(-sin(g), 0, -cos(g))
		var direita := Vector3(cos(g), 0, -sin(g))
		dir = direita * entrada.x + frente * -entrada.y
	sala.mover(dir, delta)
	sala.rig.alvo = sala.figura.position.lerp(Vector3.ZERO, 0.4)
	if sala.no_sigilo():
		comecar_ritual()


## Pisou no sigilo: ajoelha, a fita treme e o papel das escolhas aparece.
func comecar_ritual() -> void:
	if no_ritual:
		return
	no_ritual = true
	_botao_ir.visible = false
	_dica.text = "O Outro Lado responde."
	# A câmera chega perto e põe o agente à esquerda (o papel fica à direita)
	sala.rig.distancia = 4.2
	sala.rig.alvo = Vector3(1.1, 0, 0.2)
	Tema.pulso_vhs(_vista, 0.6, 0.9)
	var tw := sala.ajoelhar()
	tw.tween_callback(_mostrar_escolhas)


func _mostrar_escolhas() -> void:
	_papel.visible = true
	_papel.modulate.a = 0.0
	_papel.create_tween().tween_property(_papel, "modulate:a", 1.0, 0.4)
	_redesenhar()


func _redesenhar() -> void:
	for f in _caixa.get_children():
		f.queue_free()
	var cab := Label.new()
	cab.text = "NEX %d%% — O QUE O OUTRO LADO DEIXOU" % agente.nex
	cab.add_theme_color_override("font_color", Tema.SANGUE)
	var ft := Tema.fonte_titulo()
	if ft != null:
		cab.add_theme_font_override("font", ft)
	cab.add_theme_font_size_override("font_size", Tema.FONTE_G)
	_caixa.add_child(cab)
	if Progressao.pendencias(agente).is_empty():
		var fim := Label.new()
		fim.text = "%s se levanta. Algo ficou diferente — e não vai voltar a ser o que era." % agente.nome
		fim.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fim.add_theme_color_override("font_color", Tema.TINTA)
		_caixa.add_child(fim)
		var voltar := Button.new()
		voltar.text = "Levantar e voltar à Base"
		voltar.theme_type_variation = "BotaoPrincipal"
		voltar.pressed.connect(func():
			sala.levantar()
			var tw := create_tween()
			tw.tween_interval(0.8)
			tw.tween_callback(fechar))
		_caixa.add_child(voltar)
		voltar.grab_focus.call_deferred()
		_dica.text = "Ritual concluído."
		return
	if base != null and base.has_method("_montar_pendencia"):
		var escolhas := VBoxContainer.new()
		escolhas.add_theme_constant_override("separation", 6)
		_caixa.add_child(escolhas)
		base._montar_pendencia(agente, escolhas)


func _ao_aplicar(a: Agente, erros: Array) -> void:
	if a != agente or not no_ritual:
		return
	if erros.is_empty():
		Tema.pulso_vhs(_vista, 0.4, 0.6)
		Som.tocar("pista")
		# A afinidade se firmou neste Transcender (p.114): a sala vira a do elemento (docs/34)
		var tema := SalaTranscender.tema_de(agente)
		if tema != sala.tipo_sala:
			sala.transformar(tema)
			Tema.pulso_vhs(_vista, 1.0, 1.2)
			Som.tocar("ritual")
			_dica.text = "A afinidade com %s desperta." % tema.capitalize()
	_redesenhar()


func fechar() -> void:
	if base != null and base.has_signal("pendencias_mudaram") and base.pendencias_mudaram.is_connected(_ao_aplicar):
		base.pendencias_mudaram.disconnect(_ao_aplicar)
	Som.ambiente(0.0)
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()
	elif not no_ritual and (evento.is_action_pressed("ui_accept") or Atalhos.pressionou(evento, "confirmar_carta")):
		get_viewport().set_input_as_handled()
		_indo = true
