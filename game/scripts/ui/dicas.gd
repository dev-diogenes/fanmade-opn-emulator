class_name Dicas
extends RefCounted
## Dicas de primeira vez (docs/74): um bilhete curto no alto da tela, na primeira vez que um
## sistema aparece (munição, Oficina, fobias, subgênero, caçador, fuga, caçada, culto). Os textos
## ficam em data/jogo/tutorial.json ("dicas"). "Entendi" não mostra mais aquela dica; "Sem dicas"
## desliga todas (dá para religar na aba Jogadores). Não bloqueia nada: a tela segue jogável.
## Só valem com `ativas`, que a tela de título liga: testes e sondas ficam sem dicas.

static var ativas := false
static var _nesta_execucao: Dictionary = {}   ## id -> true: já apareceu nesta execução


static func pode(id: String) -> bool:
	return ativas and Preferencias.dicas_ligadas() and not id in Preferencias.dicas_vistas() \
		and not _nesta_execucao.has(id) and DadosJogo.ler("tutorial").get("dicas", {}).has(id)


## Mostra a dica `id` em `raiz`, se ainda não foi vista. Devolve a camada (ou null).
static func mostrar(raiz: Node, id: String) -> CanvasLayer:
	if raiz == null or not raiz.is_inside_tree() or not pode(id) or TourGuiado.em_andamento():
		return null
	_nesta_execucao[id] = true
	var d: Dictionary = DadosJogo.ler("tutorial").dicas[id]
	var camada := CanvasLayer.new()
	camada.layer = 80
	camada.name = "Dica_" + id
	raiz.add_child(camada)
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(18, 14)))
	papel.theme = Tema.tema_papel()
	papel.anchor_left = 0.5
	papel.anchor_right = 0.5
	papel.offset_left = -270
	papel.offset_right = 270
	papel.offset_top = 132
	papel.rotation_degrees = 0.5
	camada.add_child(papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_P)
	papel.add_child(v)
	var titulo := Label.new()
	titulo.text = "DICA · " + String(d.get("titulo", "")).to_upper()
	titulo.add_theme_color_override("font_color", Tema.TINTA)
	var ft := Tema.fonte_titulo()
	if ft != null:
		titulo.add_theme_font_override("font", ft)
	v.add_child(titulo)
	var texto := RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.custom_minimum_size = Vector2(500, 0)
	texto.add_theme_color_override("default_color", Tema.TINTA)
	texto.text = String(d.get("texto", ""))
	v.add_child(texto)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_END
	linha.add_theme_constant_override("separation", Tema.ESPACO_M)
	v.add_child(linha)
	var sem := Button.new()
	sem.text = "Sem dicas"
	sem.theme_type_variation = "BotaoPapel"
	sem.tooltip_text = "Não mostrar mais dicas (religue na aba Jogadores, em Preferências)."
	linha.add_child(sem)
	var ok := Button.new()
	ok.text = "Entendi"
	ok.theme_type_variation = "BotaoPapel"
	linha.add_child(ok)
	sem.pressed.connect(func():
		Preferencias.definir_dicas(false)
		camada.queue_free())
	ok.pressed.connect(func():
		Preferencias.marcar_dica(id)
		camada.queue_free())
	Som.tocar("papel")
	return camada
