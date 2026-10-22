class_name PainelSobre
extends CanvasLayer
## Sobre e licença (docs/60): uma folha em papel com o que o jogo é, a licença sob a qual é
## publicado, o que usa do sistema, o aviso de conteúdo, o aviso de IA, a privacidade e os
## créditos. Abre pelo menu do título. Esc ou "Fechar" fecha.
##   PainelSobre.abrir(self)

const SECOES := [
	["O que é", "Um RPG de fã, gratuito, no estilo For The King, sobre agentes da Ordo Realitas investigando o paranormal no Brasil de hoje. Os casos, as cidades, os agentes e as testemunhas são criados para este jogo."],
	["Licença", "Publicado sob a Licença da Comunidade de Ordem Paranormal ({versao}): {url}. O universo, as marcas e os personagens pertencem ao seu titular. Este jogo não usa a marca no título, nem logos, nem a identidade visual oficial, nem textos ou imagens dos livros."],
	["O que vem do sistema", "Os números e as estruturas das regras do livro básico: atributos, perícias, NEX, PE, Sanidade, classes, trilhas, rituais e ameaças. As descrições foram escritas com palavras próprias; cada regra aponta a página do livro."],
	["Conteúdo sensível", "{conteudo}"],
	["Inteligência artificial", "{ia}: o código, os textos e parte dos dados foram escritos com assistência de IA. Por isso o jogo é e continuará gratuito."],
	["Privacidade", "O jogo não coleta, não envia e não compartilha dados pessoais. O save e as preferências ficam só no seu computador; no modo online, um computador hospeda e os outros entram pelo endereço dele, sem servidor nosso no meio."],
	["Créditos", "Feito em Godot 4, com GUT para os testes. Modelos 3D da KayKit (CC0); fontes Cinzel e Alegreya Sans (SIL OFL) e Special Elite (Apache 2.0). Os sons são sintetizados em código. A lista completa está em assets/CREDITS.md."],
]

var _papel: PanelContainer


static func abrir(pai: Node) -> PainelSobre:
	var p := PainelSobre.new()
	p.name = "PainelSobre"
	p._montar()
	pai.add_child(p)
	return p


static func texto_da_secao(i: int) -> String:
	return String(SECOES[i][1]).format({"versao": Licenca.VERSAO_LICENCA, "url": Licenca.LICENCA_URL,
		"conteudo": Licenca.AVISO_CONTEUDO, "ia": Licenca.AVISO_IA})


func _montar() -> void:
	layer = 92
	add_to_group("papel_modal")
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.8)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	_papel = PanelContainer.new()
	_papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(28, 20)))
	_papel.theme = Tema.tema_papel()
	_papel.rotation_degrees = -0.4
	centro.add_child(_papel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_M)
	_papel.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", Tema.ESPACO_G)
	v.add_child(cab)
	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulos)
	var t := Label.new()
	t.text = "SOBRE · " + Licenca.TITULO.to_upper()
	t.add_theme_color_override("font_color", Tema.TINTA)
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	titulos.add_child(t)
	var nao := Label.new()
	nao.text = Licenca.NAO_OFICIAL
	nao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nao.custom_minimum_size = Vector2(520, 0)
	nao.add_theme_color_override("font_color", Tema.SANGUE)
	titulos.add_child(nao)
	var selo_e_ia := VBoxContainer.new()
	cab.add_child(selo_e_ia)
	selo_e_ia.add_child(Licenca.selo(1280.0))
	var ia := Label.new()
	ia.text = Licenca.AVISO_IA
	ia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia.custom_minimum_size = Vector2(132, 0)
	ia.add_theme_font_size_override("font_size", Tema.FONTE_P - 1)
	ia.add_theme_color_override("font_color", Tema.TINTA)
	selo_e_ia.add_child(ia)
	var rolagem := ScrollContainer.new()
	rolagem.custom_minimum_size = Vector2(700, 330)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(rolagem)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", Tema.ESPACO_P)
	corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(corpo)
	for i in SECOES.size():
		var s := Label.new()
		s.text = String(SECOES[i][0]).to_upper()
		s.add_theme_color_override("font_color", Color(Tema.TINTA, 0.65))
		corpo.add_child(s)
		var l := Label.new()
		l.text = texto_da_secao(i)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(660, 0)
		l.add_theme_color_override("font_color", Tema.TINTA)
		corpo.add_child(l)
	var fechar_b := Button.new()
	fechar_b.text = "Fechar"
	fechar_b.theme_type_variation = "BotaoPrincipal"
	fechar_b.size_flags_horizontal = Control.SIZE_SHRINK_END
	fechar_b.pressed.connect(fechar)
	v.add_child(fechar_b)
	fechar_b.grab_focus.call_deferred()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fechar()


func fechar() -> void:
	remove_from_group("papel_modal")
	queue_free()
