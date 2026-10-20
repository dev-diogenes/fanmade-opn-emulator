class_name TourGuiado
extends CanvasLayer
## Tour guiado (estilo UserGuiding): escurece a tela, deixa à mostra só o elemento do passo,
## com uma moldura, e explica numa caixa com Voltar / Pular / Próximo e o número do passo.
## Passo sem elemento (ou com o elemento escondido) aparece no centro. Teclado: Enter ou →
## avança, ← volta, Esc pula. Enquanto o tour está aberto, as telas ignoram os comandos de
## jogo (veja `em_andamento()`).

signal terminou(concluido: bool, passo: int)

const COR_ESCURO := Color(0.02, 0.02, 0.04, 0.72)
const COR_MOLDURA := Tema.OURO_CLARO
const MARGEM := 6.0

## Quantos tours estão abertos agora (as telas consultam para não agir por baixo do tour)
static var _abertos := 0

var passos: Array = []   ## [{titulo, texto, alvo: Control ou null}]
var indice := 0
var _escuros: Array[ColorRect] = []
var _moldura: Panel
var _bloqueio: Control       ## cobre o elemento destacado: ele aparece, mas não recebe cliques
var _balao: PanelContainer
var _lbl_titulo: Label
var _lbl_texto: RichTextLabel
var _lbl_contador: Label
var _btn_voltar: Button
var _btn_proximo: Button
var _encerrado := false


static func em_andamento() -> bool:
	return _abertos > 0


func _init() -> void:
	layer = 100


func _enter_tree() -> void:
	_abertos += 1


func _exit_tree() -> void:
	_abertos = maxi(0, _abertos - 1)


func iniciar(lista: Array) -> void:
	passos = lista
	_montar()
	get_viewport().size_changed.connect(_reposicionar)
	await get_tree().process_frame   # espera a tela terminar o layout
	if is_inside_tree():
		mostrar(0)


func _montar() -> void:
	for i in 4:
		var r := ColorRect.new()
		r.color = COR_ESCURO
		r.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(r)
		_escuros.append(r)
	_bloqueio = Control.new()
	_bloqueio.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bloqueio)
	_moldura = Panel.new()
	_moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var estilo := StyleBoxFlat.new()
	estilo.draw_center = false
	estilo.border_color = COR_MOLDURA
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(6)
	_moldura.add_theme_stylebox_override("panel", estilo)
	add_child(_moldura)
	var pulso := create_tween().set_loops()
	pulso.tween_property(_moldura, "modulate:a", 0.45, 0.6)
	pulso.tween_property(_moldura, "modulate:a", 1.0, 0.6)

	_balao = PanelContainer.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Tema.PEDRA
	fundo.border_color = COR_MOLDURA
	fundo.set_border_width_all(2)
	fundo.set_corner_radius_all(8)
	fundo.set_content_margin_all(14)
	_balao.add_theme_stylebox_override("panel", fundo)
	_balao.custom_minimum_size = Vector2(380, 0)
	add_child(_balao)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	_balao.add_child(caixa)
	_lbl_titulo = Label.new()
	_lbl_titulo.add_theme_font_size_override("font_size", 19)
	_lbl_titulo.theme_type_variation = "Titulo"
	caixa.add_child(_lbl_titulo)
	_lbl_texto = RichTextLabel.new()
	_lbl_texto.bbcode_enabled = true
	_lbl_texto.fit_content = true
	_lbl_texto.scroll_active = false
	_lbl_texto.custom_minimum_size = Vector2(380, 0)
	caixa.add_child(_lbl_texto)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 6)
	caixa.add_child(linha)
	_lbl_contador = Label.new()
	_lbl_contador.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	_lbl_contador.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(_lbl_contador)
	var pular := Button.new()
	pular.text = "Pular tutorial"
	pular.flat = true
	pular.pressed.connect(pular_tour)
	linha.add_child(pular)
	_btn_voltar = Button.new()
	_btn_voltar.text = "Voltar"
	_btn_voltar.pressed.connect(voltar)
	linha.add_child(_btn_voltar)
	_btn_proximo = Button.new()
	_btn_proximo.pressed.connect(avancar)
	linha.add_child(_btn_proximo)


## Mostra o passo `i`: recorta o escuro em volta do elemento e põe a caixa perto dele.
func mostrar(i: int) -> void:
	indice = clampi(i, 0, passos.size() - 1)
	var p: Dictionary = passos[indice]
	_lbl_titulo.text = String(p.get("titulo", ""))
	_lbl_texto.text = String(p.get("texto", ""))
	_lbl_contador.text = "%d de %d" % [indice + 1, passos.size()]
	_btn_voltar.disabled = indice == 0
	_btn_proximo.text = "Concluir" if indice == passos.size() - 1 else "Próximo"
	var alvo = p.get("alvo")
	if alvo is Control and is_instance_valid(alvo) and alvo.is_visible_in_tree():
		_rolar_ate(alvo)
		await get_tree().process_frame
		if not is_inside_tree():
			return
	_reposicionar()
	_btn_proximo.grab_focus()


func _reposicionar() -> void:
	if passos.is_empty() or _balao == null:
		return
	var tela := get_viewport().get_visible_rect().size
	var alvo = passos[indice].get("alvo")
	var r := Rect2()
	if alvo is Control and is_instance_valid(alvo) and alvo.is_visible_in_tree() and alvo.size.x > 4 and alvo.size.y > 4:
		r = alvo.get_global_rect().grow(MARGEM).intersection(Rect2(Vector2.ZERO, tela))
	if r.size == Vector2.ZERO:
		# Sem elemento: tudo escuro, caixa no centro
		_escuros[0].position = Vector2.ZERO
		_escuros[0].size = tela
		for k in range(1, 4):
			_escuros[k].size = Vector2.ZERO
		_bloqueio.size = Vector2.ZERO
		_moldura.visible = false
		_balao.reset_size()
		_balao.position = (tela - _balao.size) / 2.0
		return
	_escuros[0].position = Vector2.ZERO
	_escuros[0].size = Vector2(tela.x, r.position.y)
	_escuros[1].position = Vector2(0, r.end.y)
	_escuros[1].size = Vector2(tela.x, tela.y - r.end.y)
	_escuros[2].position = Vector2(0, r.position.y)
	_escuros[2].size = Vector2(r.position.x, r.size.y)
	_escuros[3].position = Vector2(r.end.x, r.position.y)
	_escuros[3].size = Vector2(tela.x - r.end.x, r.size.y)
	_bloqueio.position = r.position
	_bloqueio.size = r.size
	_moldura.visible = true
	_moldura.position = r.position
	_moldura.size = r.size
	_balao.reset_size()
	_balao.position = _posicao_do_balao(r, _balao.size, tela)


## Abaixo do elemento se couber; senão acima; senão ao lado; sempre dentro da tela.
func _posicao_do_balao(r: Rect2, b: Vector2, tela: Vector2) -> Vector2:
	var pos := Vector2(r.position.x, r.end.y + 12)
	if pos.y + b.y > tela.y:
		pos.y = r.position.y - b.y - 12
	if pos.y < 0:
		pos.y = clampf(r.position.y, 8, tela.y - b.y - 8)
		pos.x = r.end.x + 12 if r.end.x + 12 + b.x <= tela.x else r.position.x - b.x - 12
	pos.x = clampf(pos.x, 8, maxf(8, tela.x - b.x - 8))
	pos.y = clampf(pos.y, 8, maxf(8, tela.y - b.y - 8))
	return pos


## Se o elemento está dentro de uma lista com rolagem, rola até ele.
func _rolar_ate(alvo: Control) -> void:
	var n := alvo.get_parent()
	while n != null:
		if n is ScrollContainer:
			(n as ScrollContainer).ensure_control_visible(alvo)
			return
		n = n.get_parent()


func avancar() -> void:
	if indice >= passos.size() - 1:
		_encerrar(true)
	else:
		mostrar(indice + 1)


func voltar() -> void:
	if indice > 0:
		mostrar(indice - 1)


func pular_tour() -> void:
	_encerrar(false)


func _encerrar(concluido: bool) -> void:
	if _encerrado:
		return
	_encerrado = true
	terminou.emit(concluido, indice + 1)
	queue_free()


func _input(evento: InputEvent) -> void:
	if not evento is InputEventKey or not evento.pressed or evento.echo:
		return
	match evento.keycode:
		KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT:
			avancar()
		KEY_LEFT:
			voltar()
		KEY_ESCAPE:
			pular_tour()
		_:
			return
	get_viewport().set_input_as_handled()
