class_name QuadroInvestigacao
extends Control
## Quadro de cortiça do caso (docs/09, 5.2): um bilhete por pergunta, uma foto instantânea
## por pista, e o fio vermelho ligando cada foto à pergunta que ela responde.
## Só apresenta o Caso; quem anota pistas é a CenaInvestigacao.
## Dedução (docs/32): cada foto traz o rótulo do indício, e o botão "Deduzir" de cada
## bilhete pede a ficha de suspeitos (sinal `deduzir_pedido`; quem abre é a tela).

signal deduzir_pedido(pergunta_id: String)

const LARGURA_BILHETE := 132.0
const FOTO := Vector2(96, 108)

var caso: Caso
var _pistas_vistas := 0
var _fios: Array = []          ## [[Control origem, Control destino]]
var _camada_fios: Control
var _conteudo: Control


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_conteudo = Control.new()
	_conteudo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_conteudo)
	_camada_fios = Control.new()
	_camada_fios.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_fios.set_anchors_preset(Control.PRESET_FULL_RECT)
	_camada_fios.draw.connect(_desenhar_fios)
	add_child(_camada_fios)
	resized.connect(_reconstruir)


func atualizar(p_caso: Caso) -> void:
	caso = p_caso
	_reconstruir()


func _draw() -> void:
	# Cortiça com moldura de madeira escura
	draw_texture_rect(Tema.textura("cortica"), Rect2(Vector2.ZERO, size), true)
	var madeira := Color("2b1a10")
	draw_rect(Rect2(Vector2.ZERO, size), madeira, false, 10.0)
	draw_rect(Rect2(Vector2(5, 5), size - Vector2(10, 10)), Color(0, 0, 0, 0.35), false, 2.0)


func _reconstruir() -> void:
	for filho in _conteudo.get_children():
		filho.queue_free()
	_fios.clear()
	if caso == null or size.x < 50:
		return
	var titulo := Label.new()
	titulo.text = "QUADRO DO CASO"
	titulo.theme_type_variation = "Subtitulo"
	titulo.add_theme_color_override("font_color", Tema.PAPEL)
	titulo.add_theme_constant_override("outline_size", 6)
	titulo.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	titulo.position = Vector2(20, 14)
	_conteudo.add_child(titulo)
	var objetivo := _bilhete(caso.objetivo, Vector2(size.x - 40, 0), 0.0, Tema.FONTE_P)
	objetivo.position = Vector2(20, 40)
	_conteudo.add_child(objetivo)

	var colunas := maxi(1, caso.perguntas.size())
	var largura := (size.x - 40) / colunas
	var topo := 40.0 + 90.0   # espaço para o "Deduzir" entre o objetivo e os bilhetes (docs/32)
	var novas := caso.pistas.size() > _pistas_vistas
	for i in caso.perguntas.size():
		var q: Dictionary = caso.perguntas[i]
		var x := 20.0 + largura * i + (largura - LARGURA_BILHETE) / 2.0
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(q.id)
		var nota := _bilhete(q.texto, Vector2(LARGURA_BILHETE, 0), rng.randf_range(-3.0, 3.0), Tema.FONTE_P)
		nota.position = Vector2(x, topo)
		_conteudo.add_child(nota)
		var alfinete_nota := _alfinete(nota)
		var resp := caso.resposta(q.id)
		if resp != "":
			_carimbo(nota, resp)
		else:
			_botao_deduzir(nota, q)
		# Fotos das pistas que respondem a esta pergunta, empilhadas abaixo
		var y := topo + 96.0
		var k := 0
		for j in caso.pistas.size():
			var p: Dictionary = caso.pistas[j]
			if p.responde != q.id:
				continue
			var rotulo := String(Caso.indicio(p.indicio).get("rotulo", "")).to_upper() if String(p.get("indicio", "")) != "" else ""
			var duvidosa: bool = p.get("duvidosa", false)   # depoimento incerto (docs/35)
			if duvidosa and rotulo != "":
				rotulo = "? " + rotulo
			var dica := ("Depoimento incerto: a testemunha pode estar enganada.\n" if duvidosa else "") + String(p.texto)
			var foto := _foto(rotulo if rotulo != "" else p.texto, hash(p.texto), rng.randf_range(-5.0, 5.0), dica)
			foto.position = _vaga(x, y, k) + Vector2(rng.randf_range(-6, 6), rng.randf_range(-4, 4))
			_conteudo.add_child(foto)
			_fios.append([alfinete_nota, _alfinete(foto)])
			if novas and j >= _pistas_vistas:
				_animar_entrada(foto)
			k += 1
		# Espaços vazios pontilhados para as pistas que faltam
		for vazio in maxi(0, int(q.pistas_necessarias) - k):
			var buraco := _Pontilhado.new()
			buraco.size = FOTO * 0.78
			buraco.position = _vaga(x, y, k + vazio) + FOTO * 0.11
			_conteudo.add_child(buraco)
	_pistas_vistas = caso.pistas.size()
	_camada_fios.queue_redraw()
	queue_redraw()


## Posição da k-ésima foto de uma coluna: empilhadas, cada uma cobrindo um pouco a anterior.
func _vaga(x: float, y: float, k: int) -> Vector2:
	return Vector2(x + LARGURA_BILHETE / 2.0 - FOTO.x / 2.0 + (8.0 if k % 2 else -8.0), y + k * FOTO.y * 0.62)


func _bilhete(texto: String, tamanho: Vector2, graus: float, fonte: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(10, 14)))
	p.custom_minimum_size = tamanho
	p.size = tamanho
	p.rotation_degrees = graus
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.theme_type_variation = "TextoPapel"
	l.add_theme_font_size_override("font_size", fonte)
	p.add_child(l)
	return p


func _foto(legenda: String, semente: int, graus: float, dica: String = "") -> Control:
	var moldura := PanelContainer.new()
	var estilo := Tema.caixa(Color("f3efe6"), Color(0, 0, 0, 0.25), 1, 1, Vector2(6, 6))
	estilo.content_margin_bottom = 4
	estilo.shadow_color = Color(0, 0, 0, 0.45)
	estilo.shadow_size = 5
	estilo.shadow_offset = Vector2(2, 3)
	moldura.add_theme_stylebox_override("panel", estilo)
	moldura.custom_minimum_size = FOTO
	moldura.size = FOTO
	moldura.pivot_offset = FOTO / 2.0
	moldura.rotation_degrees = graus
	moldura.tooltip_text = dica if dica != "" else legenda
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moldura.add_child(v)
	var imagem := ColorRect.new()
	imagem.color = Color("17141a")
	imagem.custom_minimum_size = Vector2(0, 72)
	imagem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(imagem)
	var s := Sigilo.new()
	s.semente = semente
	s.cor = Color(Tema.ELEMENTO.sangue, 0.9)
	s.set_anchors_preset(Control.PRESET_FULL_RECT)
	s.offset_left = 18
	s.offset_right = -18
	s.offset_top = 6
	s.offset_bottom = -6
	imagem.add_child(s)
	var l := Label.new()
	l.text = legenda
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.max_lines_visible = 2
	l.theme_type_variation = "TextoPapel"
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)   # era 11 (docs/21)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	return moldura


## Alfinete vermelho no topo de um papel. Devolve o nó (o fio liga nele).
## Fica no quadro, e não dentro do papel: o PanelContainer reposicionaria o alfinete.
func _alfinete(papel: Control) -> Control:
	var a := _Alfinete.new()
	a.position = papel.position + Vector2(papel.custom_minimum_size.x / 2.0 - 6, -10)
	_conteudo.add_child(a)
	return a


## "Deduzir" ao lado do bilhete: abre a ficha de suspeitos. Sem pista, fica apagado.
func _botao_deduzir(nota: Control, q: Dictionary) -> void:
	var b := Button.new()
	b.text = "Deduzir"
	b.theme_type_variation = "BotaoPapel"
	b.theme = Tema.tema_papel()
	b.add_theme_font_size_override("font_size", Tema.FONTE_P)
	b.disabled = int(q.encontradas) < 1
	b.tooltip_text = "Abrir a ficha de suspeitos e acusar" if not b.disabled else "Ache uma pista desta pergunta para poder acusar"
	b.position = nota.position + Vector2(LARGURA_BILHETE / 2.0 + 8, -30)   # à direita do alfinete
	b.z_index = 3
	var pid := String(q.id)
	b.pressed.connect(func(): deduzir_pedido.emit(pid))
	b.name = "Deduzir_" + pid
	_conteudo.add_child(b)


func _carimbo(nota: Control, resposta: String) -> void:
	var c := Label.new()
	c.add_theme_stylebox_override("normal", Tema.caixa(Color(0, 0, 0, 0), Color(Tema.SANGUE_CLARO, 0.85), 2, 3, Vector2(6, 2)))
	c.text = "RESOLVIDO\n" + (resposta.to_upper() if resposta.length() <= 20 else resposta.substr(0, 19).to_upper() + "…")
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.add_theme_color_override("font_color", Color(Tema.SANGUE_CLARO, 0.9))
	c.add_theme_font_size_override("font_size", Tema.FONTE_P)
	var titulo := Tema.fonte_titulo()
	if titulo != null:
		c.add_theme_font_override("font", titulo)
	c.rotation_degrees = -9
	c.z_index = 2
	c.add_theme_color_override("font_color", Tema.SANGUE_CLARO)
	c.position = nota.position + Vector2(2, 44)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conteudo.add_child(c)


func _animar_entrada(foto: Control) -> void:
	foto.scale = Vector2.ONE * 1.5
	foto.modulate.a = 0.0
	var tw := foto.create_tween().set_parallel()
	tw.tween_property(foto, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(foto, "modulate:a", 1.0, 0.2)


func _desenhar_fios() -> void:
	for par in _fios:
		var de: Control = par[0]
		var ate: Control = par[1]
		if not is_instance_valid(de) or not is_instance_valid(ate):
			continue
		var a := de.get_global_transform().origin - _camada_fios.global_position + Vector2(6, 6)
		var b := ate.get_global_transform().origin - _camada_fios.global_position + Vector2(6, 6)
		var meio := (a + b) / 2.0 + Vector2(0, 18)   # o fio cai um pouco
		var pts := PackedVector2Array()
		for i in 13:
			var t := i / 12.0
			pts.append(a.lerp(meio, t).lerp(meio.lerp(b, t), t))
		_camada_fios.draw_polyline(pts, Color(0, 0, 0, 0.35), 3.0, true)
		_camada_fios.draw_polyline(pts, Tema.FIO, 2.0, true)


func _process(_delta: float) -> void:
	# As fotos se mexem na animação de entrada: o fio acompanha
	if not _fios.is_empty():
		_camada_fios.queue_redraw()


class _Alfinete:
	extends Control

	func _init() -> void:
		size = Vector2(12, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_circle(Vector2(7, 8), 5, Color(0, 0, 0, 0.4))
		draw_circle(Vector2(6, 6), 5, Tema.FIO)
		draw_circle(Vector2(4.5, 4.5), 1.6, Color(1, 1, 1, 0.6))


class _Pontilhado:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_dashed_line(Vector2.ZERO, Vector2(size.x, 0), Color(Tema.PAPEL, 0.55), 2.0, 6.0)
		draw_dashed_line(Vector2(size.x, 0), size, Color(Tema.PAPEL, 0.55), 2.0, 6.0)
		draw_dashed_line(size, Vector2(0, size.y), Color(Tema.PAPEL, 0.55), 2.0, 6.0)
		draw_dashed_line(Vector2(0, size.y), Vector2.ZERO, Color(Tema.PAPEL, 0.55), 2.0, 6.0)
		draw_string(get_theme_default_font(), Vector2(size.x / 2.0 - 4, size.y / 2.0 + 6), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(Tema.PAPEL, 0.5))
