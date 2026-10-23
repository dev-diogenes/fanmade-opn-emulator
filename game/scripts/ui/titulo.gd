extends Control
## Tela de título (docs/08, R2): diorama 3D girando devagar ao fundo, o logo e o menu.
## Teclado e controle navegam pelos botões (o primeiro já vem com foco).

const VELOCIDADE_GIRO := 0.06   ## radianos por segundo

var _jogo: Node
var _mapa3d: Mapa3D
var _menu: VBoxContainer
var _sigilo: Sigilo
var _logo: Label
var _ecos_logo: Array[Label] = []
var _proxima_falha := 3.0
## Mostra o aviso de fotossensibilidade na primeira vez (docs/18, A5). Os testes desligam.
var avisar_flashes := true


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_montar_diorama()
	_montar_menu()
	Som.musica("caixinha")   # caixinha de música desafinada (docs/12)
	# Na primeira vez: o aviso de conteúdo (exigido pela licença, docs/60) e depois o de flashes
	if avisar_flashes and not _capturando():
		Dicas.ativas = true   # docs/74: só no jogo de verdade (testes e sondas não passam por aqui)
		if not Preferencias.aviso_conteudo_visto():
			_avisar_conteudo.call_deferred()
		elif not Preferencias.aviso_flashes_visto():
			_avisar_flashes.call_deferred()


## Aviso de conteúdo sensível (docs/60): a licença pede aviso adequado para terror intenso e
## violência. Aparece antes de tudo, uma vez por máquina; o texto fica também em Sobre.
func _avisar_conteudo() -> void:
	Preferencias.marcar_aviso_conteudo()
	var d := DialogoPapel.perguntar(self, "Aviso de conteúdo", Licenca.AVISO_CONTEUDO + "\n\n" + Licenca.NAO_OFICIAL,
		"Entendi", func(): pass, "Sair do jogo", true)
	d.respondido.connect(func(ok: bool):
		if not ok:
			get_tree().quit()
		elif not Preferencias.aviso_flashes_visto():
			_avisar_flashes.call_deferred())


## Aviso de fotossensibilidade (docs/18, A5), uma vez por máquina. Esc ou "Desligar" tira os
## glitches; "Manter" fica com o modo suave, que já é o padrão.
func _avisar_flashes() -> void:
	Preferencias.marcar_aviso_flashes()
	var d := DialogoPapel.perguntar(self, "Aviso de fotossensibilidade",
		"Este jogo imita fita VHS: a imagem treme, faixas pulam, há estática entre as telas e " +
		"clarões quando o paranormal aparece. Os efeitos começam no modo suave, com no máximo " +
		"três trocas por segundo.\n\nSe luzes piscando incomodam você, desligue os glitches agora. " +
		"Dá para mudar a qualquer hora em Pausa › Ajustes.",
		"Manter suave", func(): pass, "Desligar glitches", false)
	d.respondido.connect(func(ok: bool):
		if not ok:
			Preferencias.definir_efeito("glitch", false))


func _capturando() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--captura="):
			return true
	return false


func _process(delta: float) -> void:
	if _mapa3d != null and _mapa3d.rig != null:
		_mapa3d.rig.girar(delta * VELOCIDADE_GIRO)
	if _sigilo != null:
		_sigilo.rotation += delta * 0.03
	_proxima_falha -= delta
	if _proxima_falha <= 0.0 and _logo != null and Preferencias.efeito("glitch"):
		_proxima_falha = randf_range(4.0, 9.0)
		_falha_no_logo()


func _falha_no_logo() -> void:
	# Modo suave (docs/18, A5): dois saltos lentos em vez de três trancos a 20 por segundo
	var suave := Preferencias.flashes() == "suave"
	var passos := 3 if suave else 4
	var tw := create_tween()
	for passo in passos:
		tw.tween_callback(func():
			for i in _ecos_logo.size():
				var e := _ecos_logo[i]
				e.visible = passo < passos - 1
				e.size = _logo.size
				e.position = Vector2(randf_range(-7, 7) * (1 if i == 0 else -1), randf_range(-2, 2)) * (0.6 if suave else 1.0))
		tw.tween_interval(0.35 if suave else 0.05)


func _montar_diorama() -> void:
	var vista := SubViewportContainer.new()
	vista.stretch = true
	vista.set_anchors_preset(Control.PRESET_FULL_RECT)
	vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Tema.veu(vista)
	Tema.membrana_na_tela(vista, 70)   # um pouco de véu: o Outro Lado já está por perto
	var vp := SubViewport.new()
	Qualidade.vista(vp)   # MSAA e escala 3D conforme a qualidade (docs/24)
	vista.add_child(vp)
	add_child(vista)
	_mapa3d = Mapa3D.new()
	vp.add_child(_mapa3d)
	var mapa := _mapa_vitrine()
	_mapa3d.construir(mapa, DadosJogo.ler("mapa").terrenos)
	_mapa3d.clima_membrana(70)   # a mesma Membrana do véu: a noite já pesa
	_mapa3d.revelar_tudo()
	var centro := Vector3.ZERO
	for h in mapa.celulas:
		centro += _mapa3d.posicao_hex(h, 0.0)
	centro /= maxf(1.0, mapa.celulas.size())
	_mapa3d.rig.distancia = 19.0
	_mapa3d.rig.focar(centro, true)


## Um mapa bonito para o fundo: pouca água, com cidade e floresta (determinístico).
func _mapa_vitrine() -> MapaHex:
	for semente in range(2026, 2076):
		var m := GeradorMapa.gerar(semente)
		var conta := {}
		for h in m.celulas:
			conta[m.terreno(h)] = conta.get(m.terreno(h), 0) + 1
		if conta.get("agua", 0) * 5 < m.celulas.size() and conta.has("cidade") and conta.get("floresta", 0) >= 4:
			return m
	return GeradorMapa.gerar(2026)


func _montar_menu() -> void:
	# Faixa escura à esquerda, como a coluna de menu do FTK2
	var faixa := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(Tema.FUNDO, 0.92))
	g.set_color(1, Color(Tema.FUNDO, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.width = 256
	tex.height = 4
	faixa.texture = tex
	faixa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	faixa.stretch_mode = TextureRect.STRETCH_SCALE
	faixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faixa.anchor_bottom = 1.0
	faixa.offset_right = 620
	add_child(faixa)

	# Sigilo grande se desenhando atrás do logo (docs/09, 6), girando devagar
	_sigilo = Sigilo.new()
	_sigilo.semente = 1987
	_sigilo.cor = Color(Tema.SANGUE_CLARO, 0.4)
	_sigilo.espessura = 3.5
	_sigilo.size = Vector2(460, 460)
	_sigilo.position = Vector2(60, -40)
	_sigilo.pivot_offset = _sigilo.size / 2.0
	add_child(_sigilo)
	_sigilo.revelar(2.2)

	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	margem.add_theme_constant_override("margin_left", 64)
	margem.add_theme_constant_override("margin_top", 56)
	margem.add_theme_constant_override("margin_bottom", 40)
	add_child(margem)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", Tema.ESPACO_G)
	margem.add_child(coluna)

	# O título de trabalho, sem a marca "Ordem Paranormal" (a licença não deixa usá-la no título)
	var sobre := Label.new()
	sobre.text = Licenca.SUBTITULO.to_upper()
	sobre.theme_type_variation = "Subtitulo"
	sobre.add_theme_constant_override("outline_size", 0)
	coluna.add_child(sobre)
	var logo := Label.new()
	logo.text = Licenca.TITULO.to_upper()
	logo.theme_type_variation = "Titulo"
	logo.add_theme_font_size_override("font_size", Tema.FONTE_LOGO)
	logo.add_theme_constant_override("line_spacing", -12)
	logo.add_theme_constant_override("outline_size", 10)
	logo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	coluna.add_child(logo)
	# Falha de fita no logo, de tempos em tempos: cópias vermelha e ciano deslocadas
	for cor in [Color(1, 0.1, 0.15, 0.7), Color(0.2, 0.9, 1, 0.55)]:
		var eco := logo.duplicate() as Label
		eco.add_theme_color_override("font_color", cor)
		eco.add_theme_constant_override("outline_size", 0)
		eco.visible = false
		eco.mouse_filter = Control.MOUSE_FILTER_IGNORE
		logo.add_child(eco)
		_ecos_logo.append(eco)
	_logo = logo
	var fio := ColorRect.new()
	fio.color = Tema.SANGUE_CLARO
	fio.custom_minimum_size = Vector2(320, 3)
	fio.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	coluna.add_child(fio)
	# A descrição (docs/60): em letra de texto, abaixo do traço; não faz parte do nome
	var desc := Label.new()
	desc.text = Licenca.DESCRICAO
	desc.add_theme_color_override("font_color", Tema.PERGAMINHO)
	coluna.add_child(desc)
	var sub := Label.new()
	sub.text = "Fanmade · não oficial · gratuito"
	sub.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	coluna.add_child(sub)

	var espaco := Control.new()
	espaco.custom_minimum_size = Vector2(0, Tema.ESPACO_GG)
	coluna.add_child(espaco)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", Tema.ESPACO_M)
	_menu.custom_minimum_size = Vector2(300, 0)
	_menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	coluna.add_child(_menu)
	var tem_save := Carreira.existe_save()
	var principal := _botao("Continuar carreira" if tem_save else "Começar", _continuar)
	if tem_save:
		principal.tooltip_text = Carreira.resumo_save()
		var resumo := Label.new()   # o que "continuar" continua (docs/21, C4)
		resumo.text = Carreira.resumo_save()
		resumo.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
		resumo.add_theme_font_size_override("font_size", Tema.FONTE_P)
		resumo.position = Vector2(2, 44)
		resumo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		principal.add_child(resumo)
		principal.custom_minimum_size.y = 66
	_botao("Nova carreira", _pedir_nova_carreira)
	_botao("Editor de missões", _editor)
	_botao("Sobre e licença", func(): PainelSobre.abrir(self))
	_botao("Sair", func(): get_tree().quit())
	principal.grab_focus.call_deferred()

	var rodape := Label.new()
	rodape.text = Licenca.NAO_OFICIAL
	rodape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rodape.custom_minimum_size = Vector2(560, 0)
	rodape.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rodape.add_theme_font_size_override("font_size", Tema.FONTE_P)
	rodape.add_theme_color_override("font_color", Color(Tema.TEXTO_SUAVE, 0.85))
	rodape.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rodape.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	coluna.add_child(rodape)
	_montar_selo()


## O selo da licença na "capa" (docs/60): no canto de baixo, à direita, com ao menos 10% da
## largura da tela e opaco; junto dele, o aviso de IA (mesma posição, como a licença pede) e
## a linha de conteúdo sensível.
func _montar_selo() -> void:
	var caixa := VBoxContainer.new()
	caixa.name = "CaixaSelo"
	caixa.alignment = BoxContainer.ALIGNMENT_END
	caixa.add_theme_constant_override("separation", 4)
	caixa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	caixa.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	caixa.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)
	var largura := get_viewport_rect().size.x if is_inside_tree() else 1280.0
	var selo := Licenca.selo(largura)
	selo.size_flags_horizontal = Control.SIZE_SHRINK_END
	caixa.add_child(selo)
	for par in [[Licenca.AVISO_IA, Tema.PERGAMINHO], [Licenca.AVISO_CONTEUDO_CURTO, Tema.TEXTO_SUAVE]]:
		var l := Label.new()
		l.text = par[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.add_theme_font_size_override("font_size", Tema.FONTE_P)
		l.add_theme_color_override("font_color", par[1])
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		caixa.add_child(l)



func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.theme_type_variation = "BotaoMenu"
	b.custom_minimum_size = Vector2(0, 48)
	# Um pequeno sigilo aparece ao lado do item com foco ou mouse
	var marca := Sigilo.new()
	marca.semente = _menu.get_child_count() + 40
	marca.cor = Tema.SANGUE_CLARO
	marca.espessura = 1.6
	marca.size = Vector2(26, 26)
	marca.position = Vector2(-34, 11)
	marca.visible = false
	b.add_child(marca)
	var mostrar := func(sim: bool):
		marca.visible = sim
		if sim:
			marca.revelar(0.25)
	b.mouse_entered.connect(mostrar.bind(true))
	b.mouse_exited.connect(func(): mostrar.call(b.has_focus()))
	b.focus_entered.connect(mostrar.bind(true))
	b.focus_exited.connect(mostrar.bind(false))
	b.pressed.connect(acao)
	_menu.add_child(b)
	return b


func _continuar() -> void:
	if _jogo != null:
		_jogo.carregar_ou_criar()
		_jogo.ir_para_base()


func _pedir_nova_carreira() -> void:
	if Carreira.existe_save():
		DialogoPapel.perguntar(self, "Nova carreira", "Começar uma carreira nova apaga o save atual: agentes, memorial e a missão em andamento. Não dá para desfazer.", "Apagar e começar", _nova_carreira)
	else:
		_nova_carreira()


func _nova_carreira() -> void:
	if _jogo != null:
		_jogo.nova_carreira()
		_jogo.ir_para_base()


func _editor() -> void:
	if _jogo != null:
		_jogo.ir_para_editor()
