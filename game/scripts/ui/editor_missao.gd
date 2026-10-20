extends Control
## Editor mínimo de missões da comunidade (Fase 6). À esquerda, o mapa em hexes: clique para
## pintar terreno ou pôr conteúdo com a ferramenta escolhida. À direita, os dados da missão,
## o covil, eventos próprios, validação e salvar/testar. A lógica fica em EditorMissao.

const COR_FUNDO := Tema.FUNDO
const TAMANHO_HEX := 22.0
const MARCAS := {"inicio": "I", "objetivo": "X", "vila": "V", "encontro": "!", "evento": "?", "investigacao": "◆"}
const FERRAMENTAS := [
	["Terreno: campo", "terreno", "campo"], ["Terreno: estrada", "terreno", "estrada"], ["Terreno: mata fechada", "terreno", "floresta"],
	["Terreno: pântano", "terreno", "pantano"], ["Terreno: morro", "terreno", "morro"], ["Terreno: cidade", "terreno", "cidade"],
	["Terreno: ruínas", "terreno", "ruina"], ["Terreno: água", "terreno", "agua"],
	["Início do grupo (I)", "conteudo", "inicio"], ["Objetivo / covil (X)", "conteudo", "objetivo"], ["Vila (V)", "conteudo", "vila"],
	["Encontro (!)", "conteudo", "encontro"], ["Evento (?)", "conteudo", "evento"], ["Investigação (◆)", "conteudo", "investigacao"],
	["Apagar conteúdo", "apagar", ""],
]
const EFEITOS_SUCESSO := [["Nenhum", {}], ["Revela o objetivo", {"tipo": "revelar_objetivo"}], ["Revela os arredores (3)", {"tipo": "revelar_raio", "valor": 3}],
	["Membrana +5", {"tipo": "membrana", "valor": 5}], ["Recupera 1d4 de SAN", {"tipo": "recupera_san", "valor": "1d4"}], ["Cura 1d6 PV", {"tipo": "cura", "valor": "1d6"}]]
const EFEITOS_FALHA := [["Nenhum", {}], ["1d6 de dano", {"tipo": "dano", "valor": "1d6"}], ["1d6 de dano mental", {"tipo": "dano_mental", "valor": "1d6"}],
	["Membrana −3", {"tipo": "membrana", "valor": -3}]]

var editor: EditorMissao
var ruleset: Ruleset
var _jogo: Node
var _terrenos: Dictionary

var _tela: Control
var _opt_ferramenta: OptionButton
var _opt_alvo: OptionButton
var _ed_titulo: LineEdit
var _ed_autor: LineEdit
var _ed_descricao: TextEdit
var _ed_briefing: TextEdit
var _spin_col: SpinBox
var _spin_lin: SpinBox
var _spin_seed: SpinBox
var _ed_covil: LineEdit
var _lbl_covil: Label
var _opt_ameaca: OptionButton
var _opt_surg: OptionButton
var _ev_titulo: LineEdit
var _ev_texto: LineEdit
var _ev_pericia: OptionButton
var _ev_dt: SpinBox
var _ev_ok: LineEdit
var _ev_ok_ef: OptionButton
var _ev_falha: LineEdit
var _ev_falha_ef: OptionButton
var _lbl_eventos: Label
var _opt_abrir: OptionButton
var _lbl_status: Label


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	ruleset = RulesetOp2022.carregar_padrao()
	_terrenos = DadosJogo.ler("mapa").terrenos
	editor = EditorMissao.nova()
	_montar_interface()
	_carregar_campos()


# --- Mapa (desenho e clique) -------------------------------------------------------

func _centro(col: int, lin: int) -> Vector2:
	return Hex.para_pixel(Hex.de_offset(col, lin), TAMANHO_HEX) + Vector2(TAMANHO_HEX * 1.5, TAMANHO_HEX * 1.5)


func _desenhar() -> void:
	for lin in editor.linhas():
		for col in editor.colunas():
			var c := _centro(col, lin)
			var t := editor.terreno_em(col, lin)
			var cor := Color(String(_terrenos.get(t, {}).get("cor", "4f6b3a")))
			var vertices := Hex.vertices(c, TAMANHO_HEX * 0.96)
			_tela.draw_colored_polygon(vertices, cor)
			var contorno := PackedVector2Array(vertices)
			contorno.append(vertices[0])
			_tela.draw_polyline(contorno, Color(0, 0, 0, 0.35), 1.5, true)
			var cont := editor.conteudo_em(col, lin)
			if not cont.is_empty():
				var marca: String = MARCAS.get(cont.tipo, "•")
				_tela.draw_circle(c, TAMANHO_HEX * 0.45, Color(0, 0, 0, 0.55))
				_tela.draw_string(get_theme_default_font(), c + Vector2(-6, 6), marca, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Tema.OURO_CLARO)


func _clique_no_mapa(evento: InputEvent) -> void:
	var pintando: bool = evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT
	var arrastando: bool = evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if not (pintando or arrastando):
		return
	var h := Hex.de_pixel(evento.position - Vector2(TAMANHO_HEX * 1.5, TAMANHO_HEX * 1.5), TAMANHO_HEX)
	var o := Hex.para_offset(h)
	if editor.terreno_em(o.x, o.y) == "":
		return
	var f: Array = FERRAMENTAS[_opt_ferramenta.selected]
	match f[1]:
		"terreno":
			editor.pintar(o.x, o.y, f[2])
		"apagar":
			if pintando:
				editor.apagar(o.x, o.y)
		"conteudo":
			if not pintando:
				return
			var cont := {"tipo": f[2]}
			match f[2]:
				"vila":
					cont["nome"] = "Vila"
				"encontro", "evento":
					if _opt_alvo.selected < 0:
						_status("Escolha qual %s na lista ao lado." % f[2])
						return
					cont[f[2]] = _opt_alvo.get_item_metadata(_opt_alvo.selected)
				"investigacao":
					cont["cena"] = _opt_alvo.get_item_metadata(_opt_alvo.selected)
			editor.colocar(o.x, o.y, cont)
	_tela.queue_redraw()


# --- Interface ---------------------------------------------------------------------

func _montar_interface() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())
	var raiz := HBoxContainer.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.offset_left = 14
	raiz.offset_top = 12
	raiz.offset_right = -14
	raiz.offset_bottom = -12
	raiz.add_theme_constant_override("separation", Tema.ESPACO_G)
	add_child(raiz)

	var esquerda := VBoxContainer.new()
	esquerda.custom_minimum_size = Vector2(540, 0)
	esquerda.add_theme_constant_override("separation", Tema.ESPACO_M)
	raiz.add_child(Tema.painel(esquerda))
	esquerda.add_child(_titulo("Editor de missões", 20))
	var dica := Label.new()
	dica.text = "Clique (ou arraste) no mapa para usar a ferramenta. I = início, X = objetivo/covil, V = vila, ! = encontro, ? = evento, ◆ = investigação."
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	esquerda.add_child(dica)
	var linha_f := HBoxContainer.new()
	esquerda.add_child(linha_f)
	_opt_ferramenta = OptionButton.new()
	for f in FERRAMENTAS:
		_opt_ferramenta.add_item(f[0])
	_opt_ferramenta.item_selected.connect(func(_i): _atualizar_alvos())
	linha_f.add_child(_opt_ferramenta)
	_opt_alvo = OptionButton.new()
	_opt_alvo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_alvo.clip_text = true
	linha_f.add_child(_opt_alvo)
	_tela = Control.new()
	_tela.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tela.mouse_filter = Control.MOUSE_FILTER_STOP
	_tela.draw.connect(_desenhar)
	_tela.gui_input.connect(_clique_no_mapa)
	esquerda.add_child(_tela)

	var rolagem := ScrollContainer.new()
	rolagem.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.custom_minimum_size = Vector2(560, 0)
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	raiz.add_child(Tema.painel(rolagem))
	var p := VBoxContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_constant_override("separation", 4)
	rolagem.add_child(p)

	p.add_child(_titulo("Missão"))
	_ed_titulo = _campo(p, "Título")
	_ed_autor = _campo(p, "Autor")
	_ed_descricao = _texto(p, "Descrição (aparece na Base)", 50)
	_ed_briefing = _texto(p, "Briefing (aparece no início da missão)", 70)

	p.add_child(_titulo("Mapa"))
	var lt := HBoxContainer.new()
	p.add_child(lt)
	_spin_col = _spin(lt, "Colunas", 4, MissaoComunidade.MAX_COLUNAS)
	_spin_lin = _spin(lt, "Linhas", 3, MissaoComunidade.MAX_LINHAS)
	lt.add_child(_botao("Aplicar tamanho", _redimensionar))
	var ls := HBoxContainer.new()
	p.add_child(ls)
	_spin_seed = _spin(ls, "Seed", 0, 999999)
	ls.add_child(_botao("Gerar terreno", _gerar_terreno))

	p.add_child(_titulo("Covil (a primeira ameaça é o chefe)"))
	_ed_covil = _campo(p, "Nome do covil")
	_lbl_covil = Label.new()
	_lbl_covil.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(_lbl_covil)
	var lc := HBoxContainer.new()
	p.add_child(lc)
	_opt_ameaca = OptionButton.new()
	_opt_ameaca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_ameaca.clip_text = true
	for id in DadosJogo.ler("ameacas").ameacas:
		var info := DadosJogo.ameaca(ruleset, id)
		_opt_ameaca.add_item("%s (VD %d)" % [info.nome, info.vd])
		_opt_ameaca.set_item_metadata(_opt_ameaca.item_count - 1, id)
	for a in ruleset.lista_ameacas():
		_opt_ameaca.add_item("%s (VD %d, livro)" % [a.nome, int(a.vd)])
		_opt_ameaca.set_item_metadata(_opt_ameaca.item_count - 1, a.id)
	lc.add_child(_opt_ameaca)
	lc.add_child(_botao("Adicionar", _adicionar_ao_covil))
	lc.add_child(_botao("Limpar", _limpar_covil))
	var lsu := HBoxContainer.new()
	p.add_child(lsu)
	var lbl_s := Label.new()
	lbl_s.text = "Ameaças que surgem com a Membrana:"
	lsu.add_child(lbl_s)
	_opt_surg = OptionButton.new()
	for t in ["As do jogo", "Só as da missão", "Nenhuma"]:
		_opt_surg.add_item(t)
	lsu.add_child(_opt_surg)

	p.add_child(_titulo("Novo evento"))
	_ev_titulo = _campo(p, "Título do evento")
	_ev_texto = _campo(p, "O que os agentes encontram")
	var le := HBoxContainer.new()
	p.add_child(le)
	_ev_pericia = OptionButton.new()
	for per in ["vontade", "percepcao", "investigacao", "ocultismo", "sobrevivencia", "diplomacia", "atletismo", "tecnologia", "intuicao", "furtividade"]:
		_ev_pericia.add_item(ruleset.pericia(per).nome)
		_ev_pericia.set_item_metadata(_ev_pericia.item_count - 1, per)
	le.add_child(_ev_pericia)
	_ev_dt = _spin(le, "DT", 5, 40)
	_ev_dt.value = 15
	_ev_ok = _campo(p, "Texto do sucesso")
	_ev_ok_ef = _opcoes(p, EFEITOS_SUCESSO)
	_ev_falha = _campo(p, "Texto da falha")
	_ev_falha_ef = _opcoes(p, EFEITOS_FALHA)
	p.add_child(_botao("Adicionar evento", _adicionar_evento))
	_lbl_eventos = Label.new()
	_lbl_eventos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_eventos.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	p.add_child(_lbl_eventos)

	p.add_child(_titulo("Arquivo"))
	var la := HBoxContainer.new()
	p.add_child(la)
	_opt_abrir = OptionButton.new()
	_opt_abrir.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_opt_abrir.clip_text = true
	la.add_child(_opt_abrir)
	la.add_child(_botao("Abrir", _abrir))
	la.add_child(_botao("Nova", _nova))
	var lb := HBoxContainer.new()
	p.add_child(lb)
	lb.add_child(_botao("Validar", _validar))
	lb.add_child(_botao("Salvar", _salvar))
	lb.add_child(_botao("Testar missão", _testar))
	lb.add_child(_botao("Voltar à Base", _voltar))
	_lbl_status = Label.new()
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(_lbl_status)
	var pasta := Label.new()
	pasta.text = "As missões ficam em %s (no Windows, %%APPDATA%%\\Godot\\app_userdata\\…\\missoes). Dá para editar o JSON à mão: veja docs/04-missoes-da-comunidade.md." % MissaoComunidade.PASTA_USUARIO
	pasta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pasta.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	p.add_child(pasta)


func _titulo(texto: String, tamanho: int = 14) -> Label:
	var l := Label.new()
	l.text = texto
	l.theme_type_variation = "Titulo" if tamanho > 14 else "Subtitulo"
	return l


func _campo(pai: Control, dica: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = dica
	pai.add_child(e)
	return e


func _texto(pai: Control, dica: String, altura: int) -> TextEdit:
	var e := TextEdit.new()
	e.placeholder_text = dica
	e.custom_minimum_size = Vector2(0, altura)
	e.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	pai.add_child(e)
	return e


func _spin(pai: Control, prefixo: String, minimo: int, maximo: int) -> SpinBox:
	var s := SpinBox.new()
	s.prefix = prefixo
	s.custom_minimum_size = Vector2(130, 0)
	s.min_value = minimo
	s.max_value = maximo
	pai.add_child(s)
	return s


func _opcoes(pai: Control, lista: Array) -> OptionButton:
	var o := OptionButton.new()
	for item in lista:
		o.add_item(item[0])
	pai.add_child(o)
	return o


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	return b


func _status(texto: String, erro: bool = false) -> void:
	_lbl_status.text = texto
	_lbl_status.add_theme_color_override("font_color", Tema.PERIGO if erro else Tema.SUCESSO)


# --- Sincronizar campos e definição ---------------------------------------------------

func _carregar_campos() -> void:
	var d := editor.definicao
	_ed_titulo.text = String(d.get("titulo", ""))
	_ed_autor.text = String(d.get("autor", ""))
	_ed_descricao.text = String(d.get("descricao", ""))
	_ed_briefing.text = String(d.get("briefing", ""))
	_spin_col.value = editor.colunas()
	_spin_lin.value = editor.linhas()
	_ed_covil.text = String(d.get("covil", {}).get("nome", "O covil"))
	_opt_surg.select(maxi(0, MissaoComunidade.SURGIMENTOS.find(String(d.get("opcoes", {}).get("surgimentos", "padrao")))))
	_atualizar_alvos()
	_atualizar_listas()
	_tela.queue_redraw()


func _guardar_campos() -> void:
	var d := editor.definicao
	d.titulo = _ed_titulo.text.strip_edges()
	d.autor = _ed_autor.text.strip_edges()
	d.descricao = _ed_descricao.text.strip_edges()
	d.briefing = _ed_briefing.text.strip_edges()
	var covil: Dictionary = d.get("covil", {"ameacas": []})
	covil.nome = _ed_covil.text.strip_edges() if _ed_covil.text.strip_edges() != "" else "O covil"
	d.covil = covil
	var opcoes: Dictionary = d.get("opcoes", {})
	opcoes.surgimentos = MissaoComunidade.SURGIMENTOS[_opt_surg.selected]
	d.opcoes = opcoes


func _atualizar_alvos() -> void:
	_opt_alvo.clear()
	var f: Array = FERRAMENTAS[_opt_ferramenta.selected]
	match f[2]:
		"encontro":
			for e in editor.definicao.get("encontros", []) + DadosJogo.ler("encontros").encontros:
				_opt_alvo.add_item("%s (%s)" % [e.nome, e.id])
				_opt_alvo.set_item_metadata(_opt_alvo.item_count - 1, e.id)
		"evento":
			for e in editor.definicao.get("eventos", []):
				_opt_alvo.add_item("%s (da missão)" % e.titulo)
				_opt_alvo.set_item_metadata(_opt_alvo.item_count - 1, e.id)
			for e in DadosJogo.ler("eventos").eventos:
				_opt_alvo.add_item(e.titulo)
				_opt_alvo.set_item_metadata(_opt_alvo.item_count - 1, e.id)
		"investigacao":
			for cn in editor.definicao.get("cenas", []) + DadosJogo.ler("cenas_investigacao").cenas:
				_opt_alvo.add_item(cn.nome)
				_opt_alvo.set_item_metadata(_opt_alvo.item_count - 1, cn.id)
	_opt_alvo.visible = _opt_alvo.item_count > 0


func _atualizar_listas() -> void:
	var nomes := PackedStringArray()
	for id in editor.definicao.get("covil", {}).get("ameacas", []):
		nomes.append(DadosJogo.ameaca(ruleset, id).nome if not editor.definicao.get("ameacas", {}).has(id) else editor.definicao.ameacas[id].get("nome", id))
	_lbl_covil.text = "Ameaças: %s" % (", ".join(nomes) if not nomes.is_empty() else "nenhuma")
	var evs := PackedStringArray()
	for e in editor.definicao.get("eventos", []):
		evs.append(e.titulo)
	_lbl_eventos.text = "Eventos da missão: %s" % (", ".join(evs) if not evs.is_empty() else "nenhum")
	_opt_abrir.clear()
	for m in MissaoComunidade.listar(ruleset):
		_opt_abrir.add_item("%s%s" % [m.definicao.get("titulo", m.caminho.get_file()), "" if m.erros.is_empty() else " (com erros)"])
		_opt_abrir.set_item_metadata(_opt_abrir.item_count - 1, m.caminho)


# --- Ações -----------------------------------------------------------------------

func _redimensionar() -> void:
	editor.redimensionar(int(_spin_col.value), int(_spin_lin.value))
	_tela.queue_redraw()


func _gerar_terreno() -> void:
	editor.gerar_terreno(int(_spin_seed.value))
	_tela.queue_redraw()


func _adicionar_ao_covil() -> void:
	if _opt_ameaca.selected < 0:
		return
	var covil: Dictionary = editor.definicao.get("covil", {"nome": "O covil", "ameacas": []})
	covil.ameacas = covil.get("ameacas", []) + [_opt_ameaca.get_item_metadata(_opt_ameaca.selected)]
	editor.definicao.covil = covil
	_atualizar_listas()


func _limpar_covil() -> void:
	editor.definicao.covil = {"nome": _ed_covil.text, "ameacas": []}
	_atualizar_listas()


func _adicionar_evento() -> void:
	if _ev_titulo.text.strip_edges() == "" or _ev_texto.text.strip_edges() == "":
		_status("O evento precisa de título e de texto.", true)
		return
	var ok_ef: Dictionary = EFEITOS_SUCESSO[_ev_ok_ef.selected][1]
	var falha_ef: Dictionary = EFEITOS_FALHA[_ev_falha_ef.selected][1]
	var id := editor.adicionar_evento({"titulo": _ev_titulo.text.strip_edges(), "texto": _ev_texto.text.strip_edges(),
		"pericia": _ev_pericia.get_item_metadata(_ev_pericia.selected), "dt": int(_ev_dt.value),
		"sucesso": {"texto": _ev_ok.text.strip_edges() if _ev_ok.text.strip_edges() != "" else "Você consegue.", "efeitos": [] if ok_ef.is_empty() else [ok_ef]},
		"falha": {"texto": _ev_falha.text.strip_edges() if _ev_falha.text.strip_edges() != "" else "Não dá certo.", "efeitos": [] if falha_ef.is_empty() else [falha_ef]}})
	for campo in [_ev_titulo, _ev_texto, _ev_ok, _ev_falha]:
		campo.text = ""
	_status("Evento \"%s\" criado: escolha a ferramenta Evento para pô-lo no mapa." % id)
	_atualizar_alvos()
	_atualizar_listas()


func _validar() -> bool:
	_guardar_campos()
	var erros := editor.validar(ruleset)
	if erros.is_empty():
		_status("Missão válida.")
	else:
		_status("\n".join(erros), true)
	return erros.is_empty()


func _salvar() -> void:
	_guardar_campos()
	var caminho := editor.salvar()
	var erros := editor.validar(ruleset)
	_status("Salva em %s.%s" % [caminho, "" if erros.is_empty() else " Atenção, ainda há erros:\n" + "\n".join(erros)], not erros.is_empty())
	_atualizar_listas()


func _abrir() -> void:
	if _opt_abrir.selected < 0:
		return
	var lido := MissaoComunidade.ler_arquivo(_opt_abrir.get_item_metadata(_opt_abrir.selected), ruleset)
	if lido.definicao.is_empty():
		_status("\n".join(lido.erros), true)
		return
	editor = EditorMissao.de_definicao(lido.definicao)
	_carregar_campos()
	_status("Missão aberta.%s" % ("" if lido.erros.is_empty() else " Erros:\n" + "\n".join(lido.erros)), not lido.erros.is_empty())


func _nova() -> void:
	editor = EditorMissao.nova()
	_carregar_campos()
	_status("Missão nova.")


func _testar() -> void:
	if not _validar():
		return
	if _jogo == null:
		_status("Abra pelo jogo (Base da Ordem) para testar.", true)
		return
	var car: Carreira = _jogo.carregar_ou_criar()
	if car.missao != null:
		_status("Já há uma missão em andamento na carreira: termine-a antes de testar.", true)
		return
	if _jogo.iniciar_missao_comunidade(car.roster.slice(0, mini(3, car.roster.size())), editor.definicao) == null:
		_status("Não deu para iniciar a missão (o grupo precisa de 1 a 4 agentes vivos).", true)


func _voltar() -> void:
	if _jogo != null:
		_jogo.voltar_para_base()
	else:
		get_tree().quit()
