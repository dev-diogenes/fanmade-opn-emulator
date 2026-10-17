class_name Tutorial
extends RefCounted
## Tutorial do jogo (docs/07-tutorial.md): o convite ao abrir o jogo, um tour curto por tela
## (Base, mapa, combate, investigação) na primeira vez que a pessoa chega a ela, e o botão "?"
## de cada tela para rever. Os textos vêm de data/jogo/tutorial.json; cada tela informa os
## próprios elementos (chave -> Control).

const TELAS := ["base", "mapa", "combate", "investigacao"]

## A pessoa aceitou o tutorial nesta execução do jogo
static var na_sessao := false
## O convite já apareceu nesta execução (voltar de uma missão para a Base não pergunta de novo)
static var convite_feito := false
static var _vistos_na_sessao: Dictionary = {}


## Passos da tela com os elementos já trocados pelos Controls da tela.
static func passos(tela: String, alvos: Dictionary) -> Array:
	var lista: Array = []
	for p in DadosJogo.ler("tutorial").get("telas", {}).get(tela, {}).get("passos", []):
		lista.append({"titulo": p.get("titulo", ""), "texto": p.get("texto", ""), "alvo": alvos.get(String(p.get("alvo", "")))})
	return lista


## Abre o tour da tela (com o "?" ou automaticamente) e grava as estatísticas.
static func abrir(tela: String, raiz: Node, alvos: Dictionary) -> TourGuiado:
	var lista := passos(tela, alvos)
	if lista.is_empty() or raiz == null or not raiz.is_inside_tree():
		return null
	_vistos_na_sessao[tela] = true
	var tour := TourGuiado.new()
	raiz.add_child(tour)
	Preferencias.registrar_tour(tela, "inicio")
	tour.terminou.connect(func(concluido, passo): Preferencias.registrar_tour(tela, "concluido" if concluido else "pulado", passo))
	tour.iniciar(lista)
	return tour


## Chamado por cada tela ao abrir: com o tutorial aceito, mostra o tour dela uma vez por execução.
static func ao_entrar(tela: String, raiz: Node, alvos: Dictionary) -> TourGuiado:
	if not na_sessao or _vistos_na_sessao.has(tela):
		return null
	return abrir(tela, raiz, alvos)


## Botão "?" no canto de cima, à direita, que reabre o tour da tela.
static func botao_ajuda(raiz: Control, tela: String, alvos: Callable) -> Button:
	var b := Button.new()
	b.text = "?"
	b.tooltip_text = "Como funciona esta tela (tutorial)"
	b.custom_minimum_size = Vector2(32, 32)
	b.anchor_left = 1.0
	b.anchor_right = 1.0
	b.offset_left = -40
	b.offset_right = -8
	b.offset_top = 6
	b.offset_bottom = 38
	b.pressed.connect(func(): Tutorial.abrir(tela, raiz, alvos.call()))
	raiz.add_child(b)
	return b


## Convite que aparece quando o jogo abre (uma vez por execução, a menos que a pessoa tenha
## pedido para não perguntar). `ao_aceitar` abre o tour da tela atual.
static func convidar(raiz: Node, ao_aceitar: Callable) -> CanvasLayer:
	if convite_feito or not Preferencias.perguntar_tutorial():
		convite_feito = true
		return null
	convite_feito = true
	var camada := CanvasLayer.new()
	camada.layer = 90
	camada.name = "ConviteTutorial"
	raiz.add_child(camada)
	var escuro := ColorRect.new()
	escuro.color = Color(0.02, 0.02, 0.04, 0.72)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(centro)
	var painel := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("1b1f27")
	estilo.border_color = Color("f7dc6f")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(22)
	painel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	caixa.custom_minimum_size = Vector2(440, 0)
	painel.add_child(caixa)
	var conv: Dictionary = DadosJogo.ler("tutorial").get("convite", {})
	var titulo := Label.new()
	titulo.text = String(conv.get("titulo", "Bem-vindo à Ordem"))
	titulo.add_theme_font_size_override("font_size", 24)
	titulo.add_theme_color_override("font_color", Color("f7dc6f"))
	caixa.add_child(titulo)
	var texto := Label.new()
	texto.text = String(conv.get("texto", "Quer ver o tutorial?"))
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(440, 0)
	caixa.add_child(texto)
	var nao_perguntar := CheckBox.new()
	nao_perguntar.text = "Não perguntar de novo ao abrir o jogo"
	caixa.add_child(nao_perguntar)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_END
	linha.add_theme_constant_override("separation", 8)
	caixa.add_child(linha)
	var agora_nao := Button.new()
	agora_nao.text = "Agora não"
	linha.add_child(agora_nao)
	var ver := Button.new()
	ver.text = "Ver o tutorial"
	linha.add_child(ver)
	var fechar := func(aceitou: bool):
		if nao_perguntar.button_pressed:
			Preferencias.definir_perguntar_tutorial(false)
		Preferencias.registrar_tour("convite", "concluido" if aceitou else "pulado")
		camada.queue_free()
		if aceitou:
			na_sessao = true
			ao_aceitar.call()
	ver.pressed.connect(fechar.bind(true))
	agora_nao.pressed.connect(fechar.bind(false))
	ver.grab_focus.call_deferred()
	return camada


## Testes: volta ao estado de uma execução nova.
static func reiniciar_sessao() -> void:
	na_sessao = false
	convite_feito = false
	_vistos_na_sessao.clear()
