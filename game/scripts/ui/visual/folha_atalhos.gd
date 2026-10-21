class_name FolhaAtalhos
extends CanvasLayer
## Folha de atalhos (docs/18, A4): uma folha datilografada com todas as teclas do jogo, por
## grupo. Clicar numa tecla e apertar outra troca o atalho (Esc desiste). Se a tecla já era de
## outra ação da mesma tela, as duas trocam de lugar e a folha avisa. Abre com H em qualquer
## tela, pela pausa e pela aba Jogadores da Base.
##   FolhaAtalhos.abrir(self)

## Comandos do mouse e teclas fixas, só para consulta.
const FIXOS := [["Esc", "Pausa, fechar e voltar"], ["Clique", "Escolher hex, alvo, carta ou botão"],
	["Botão direito + arrastar", "Girar a câmera"], ["Botão do meio + arrastar", "Deslizar a câmera"],
	["Roda do mouse", "Aproximar e afastar"], ["Setas", "Valem junto com o andar"]]

var esperando := ""            ## id da ação esperando a nova tecla ("" = nenhuma)
var _botoes: Dictionary = {}   ## id -> Button
var _aviso: Label


static func abrir(pai: Node) -> FolhaAtalhos:
	var f := FolhaAtalhos.new()
	f._montar()
	pai.add_child(f)
	return f


static func aberta(pai: Node) -> bool:
	return not pai.find_children("*", "FolhaAtalhos", true, false).is_empty()


func _montar() -> void:
	layer = 96
	name = "FolhaAtalhos"
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.78)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	escuro.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and esperando == "":
			queue_free())
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(26, 18)))
	papel.theme = Tema.tema_papel()
	papel.rotation_degrees = -0.5
	centro.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_M)
	papel.add_child(v)
	var t := Label.new()
	t.text = "FOLHA DE ATALHOS"
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	var f := Tema.fonte_titulo()
	if f != null:
		t.add_theme_font_override("font", f)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Clique numa tecla e aperte a nova. Esc desiste."
	sub.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
	v.add_child(sub)
	var colunas := HBoxContainer.new()
	colunas.add_theme_constant_override("separation", Tema.ESPACO_G + 8)
	v.add_child(colunas)
	var esq := _coluna(colunas)
	var dir := _coluna(colunas)
	for g in Atalhos.GRUPOS:
		var alvo := esq if g in ["geral", "camera", "mover"] else dir
		_cabecalho(alvo, Atalhos.GRUPOS[g])
		var grade := _grade(alvo)
		for id in Atalhos.ACOES:
			if Atalhos.ACOES[id][1] != g:
				continue
			_rotulo(grade, Atalhos.ACOES[id][0])
			var b := Button.new()
			b.theme_type_variation = "BotaoPapel"
			b.custom_minimum_size = Vector2(92, 0)
			b.tooltip_text = "Trocar a tecla de \"%s\"" % Atalhos.ACOES[id][0]
			b.pressed.connect(_esperar.bind(id))
			grade.add_child(b)
			_botoes[id] = b
	_cabecalho(dir, "Fixos")
	var fixos := _grade(dir)
	for par in FIXOS:
		_rotulo(fixos, par[1])
		var k := Label.new()
		k.text = par[0]
		k.add_theme_color_override("font_color", Color(Tema.TINTA, 0.8))
		fixos.add_child(k)
	_aviso = Label.new()
	_aviso.add_theme_color_override("font_color", Tema.SANGUE)
	_aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aviso.custom_minimum_size = Vector2(560, 0)
	v.add_child(_aviso)
	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_END
	botoes.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(botoes)
	var restaurar := Button.new()
	restaurar.text = "Restaurar padrões"
	restaurar.theme_type_variation = "BotaoPapel"
	restaurar.pressed.connect(func():
		Atalhos.restaurar()
		esperando = ""
		_aviso.text = "Teclas de volta ao padrão."
		_atualizar())
	botoes.add_child(restaurar)
	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.theme_type_variation = "BotaoPrincipal"
	fechar.pressed.connect(queue_free)
	botoes.add_child(fechar)
	_atualizar()
	fechar.grab_focus.call_deferred()


func _ready() -> void:
	Som.tocar("papel")


func _atualizar() -> void:
	for id in _botoes:
		_botoes[id].text = "pressione…" if id == esperando else Atalhos.nome_tecla(id)


func _esperar(id: String) -> void:
	esperando = id
	_aviso.text = "Aperte a nova tecla para \"%s\"." % Atalhos.ACOES[id][0]
	_atualizar()


## Troca a tecla da ação esperando. Público para os testes.
func receber_tecla(keycode: int) -> void:
	if esperando == "":
		return
	var id := esperando
	esperando = ""
	if keycode == KEY_ESCAPE:
		_aviso.text = ""
	else:
		var trocados := Atalhos.remapear(id, keycode)
		if trocados.is_empty():
			_aviso.text = "\"%s\" agora é %s." % [Atalhos.ACOES[id][0], Atalhos.nome_de(keycode)]
		else:
			var nomes := PackedStringArray()
			for o in trocados:
				nomes.append("\"%s\" (agora %s)" % [Atalhos.ACOES[o][0], Atalhos.nome_tecla(o)])
			_aviso.text = "%s já era de %s: as duas trocaram de tecla." % [Atalhos.nome_de(keycode), ", ".join(nomes)]
		Som.tocar("clique")
	_atualizar()


func _input(evento: InputEvent) -> void:
	# Esperando uma tecla, ela vem para cá antes de qualquer botão ou tela
	if esperando != "" and evento is InputEventKey and evento.pressed and not evento.echo:
		get_viewport().set_input_as_handled()
		receber_tecla(evento.keycode)


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel") or Atalhos.pressionou(evento, "folha_atalhos"):
		get_viewport().set_input_as_handled()
		queue_free()


func _coluna(pai: Control) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override("separation", Tema.ESPACO_P)
	pai.add_child(c)
	return c


func _cabecalho(pai: Control, texto: String) -> void:
	var l := Label.new()
	l.text = texto.to_upper()
	l.add_theme_color_override("font_color", Tema.SANGUE)
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	pai.add_child(l)


func _grade(pai: Control) -> GridContainer:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", Tema.ESPACO_M)
	g.add_theme_constant_override("v_separation", 2)
	pai.add_child(g)
	return g


func _rotulo(pai: Control, texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", Tema.TINTA)
	pai.add_child(l)
