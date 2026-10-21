class_name CriacaoDossie
extends CanvasLayer
## Criação de agente como um dossiê (docs/17, E2), na ordem do passo a passo do livro (p.23;
## docs/27): conceito, atributos, origem, classe, perícias, rituais (ocultista), descrição
## (toques finais, p.46-47) e a revisão da ficha, numa pasta de papel. A ficha é validada a cada mudança
## por CriacaoAgente; "Assinar e arquivar" só fica liberado sem erros. Ao lado das abas, a
## foto 3x4 presa com clipe (docs/19): aparência e tom da roupa, que valem para a miniatura.
##   CriacaoDossie.abrir(self, carreira, func(agente): ...)

signal criado(agente: Agente)

const CLASSES := ["combatente", "especialista", "ocultista"]
## Os passos do livro (p.23), mais a descrição dos toques finais (p.46-47).
const PASSOS := ["Conceito", "Atributos", "Origem", "Classe", "Perícias", "Rituais", "Descrição", "Revisão"]
const ATRIBUTOS := ["agi", "for", "int", "pre", "vig"]
const NOMES_ATRIBUTOS := {"agi": "Agilidade", "for": "Força", "int": "Intelecto", "pre": "Presença", "vig": "Vigor"}

var carreira: Carreira
var rs: Ruleset
var ficha := {"nome": "", "origem": "", "classe": "combatente", "nex": 5,
	"atributos": {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1},
	"pericias_origem": [], "pericias_classe": [], "pericias_livres": [], "perito": [], "rituais": [],
	"aparencia": "", "tom": 0, "personalidade": "", "historico": "", "objetivo": "",
	"conceito": "", "genero": "", "idade_anos": 0, "aparencia_texto": "",
	"idade": "", "desvantagens_idade": [], "beneficios_origem": [], "trilha": "", "poderes": []}
## Regra opcional Idade Variada (p.182): a faixa sai da idade em anos.
var idade_variada := false

var _abas: TabContainer
var _paginas: Dictionary = {}     ## nome -> VBoxContainer (reconstruída a cada mudança)
var _erros: Label
var _assinar: Button
var _nome: LineEdit
var _idade: SpinBox
## Campos da descrição (docs/26): reaproveitados entre redesenhos, como o nome.
var _campos_descricao: Dictionary = {}   ## "personalidade" | "historico" | "objetivo" -> LineEdit/TextEdit
var _foto: FotoAgente
var _lbl_aparencia: Label


static func abrir(pai: Node, p_carreira: Carreira, ao_criar: Callable = Callable()) -> CriacaoDossie:
	var d := CriacaoDossie.new()
	d.carreira = p_carreira
	d.rs = p_carreira.ruleset
	if ao_criar.is_valid():
		d.criado.connect(ao_criar)
	d._montar()
	pai.add_child(d)
	Som.tocar("papel")
	return d


func _montar() -> void:
	layer = 88
	name = "CriacaoDossie"
	var origens: Array = rs.dados.origens.origens
	ficha.origem = String(origens[0].id)
	var escuro := ColorRect.new()
	escuro.color = Color(0.01, 0.01, 0.02, 0.8)
	escuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(escuro)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var pasta := VBoxContainer.new()
	pasta.custom_minimum_size = Vector2(980, 600)
	pasta.add_theme_constant_override("separation", 6)
	centro.add_child(pasta)
	var cab := HBoxContainer.new()
	pasta.add_child(cab)
	var t := Label.new()
	t.text = "Novo agente da Ordem"
	t.theme_type_variation = "Titulo"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.pressed.connect(queue_free)
	cab.add_child(fechar)
	var meio := HBoxContainer.new()
	meio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	meio.add_theme_constant_override("separation", Tema.ESPACO_M)
	pasta.add_child(meio)
	_abas = TabContainer.new()
	_abas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_abas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_abas.custom_minimum_size = Vector2(900, 0)
	_abas.add_theme_font_size_override("font_size", Tema.FONTE_M - 1)   # os oito passos do livro cabem   # a pasta não muda de largura entre as abas
	meio.add_child(_abas)
	meio.add_child(_coluna_foto())
	for nome in PASSOS:
		var papel := PanelContainer.new()
		papel.name = nome
		papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(24, 18)))
		papel.theme = Tema.tema_papel()
		_abas.add_child(papel)
		var rolagem := ScrollContainer.new()
		rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		papel.add_child(rolagem)
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 8)
		rolagem.add_child(v)
		_paginas[nome] = v
	_abas.tab_changed.connect(func(_i): _redesenhar())
	_atualizar_foto()
	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", Tema.ESPACO_M)
	pasta.add_child(rodape)
	_erros = Label.new()
	_erros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_erros.add_theme_color_override("font_color", Tema.AVISO)
	_erros.clip_text = true
	_erros.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	rodape.add_child(_erros)
	var voltar := Button.new()
	voltar.text = "◂ Voltar"
	voltar.pressed.connect(func(): _abas.current_tab = maxi(0, _abas.current_tab - 1))
	rodape.add_child(voltar)
	var proximo := Button.new()
	proximo.text = "Próximo ▸"
	proximo.pressed.connect(func(): _abas.current_tab = mini(_abas.get_tab_count() - 1, _abas.current_tab + 1))
	rodape.add_child(proximo)
	_assinar = Button.new()
	_assinar.text = "Assinar e arquivar"
	_assinar.theme_type_variation = "BotaoPrincipal"
	_assinar.pressed.connect(_assinar_ficha)
	rodape.add_child(_assinar)
	_redesenhar()


# --- Validação ----------------------------------------------------------------------

func _validar() -> Dictionary:
	var f := ficha.duplicate(true)
	if f.classe != "ocultista":
		f.erase("rituais")
	if f.classe != "especialista":
		f.erase("perito")
	if f.classe != "combatente":
		f.pericias_classe = []
	return CriacaoAgente.criar(rs, f)


func _redesenhar() -> void:
	var res := _validar()
	var erros: Array = res.erros
	if String(ficha.nome).strip_edges() == "":
		erros = ["Dê um nome ao agente."] + erros
	_erros.text = ("Faltam %d ajuste(s): %s" % [erros.size(), erros[0]]) if not erros.is_empty() else "Ficha completa: pronta para assinar."
	_erros.add_theme_color_override("font_color", Tema.AVISO if not erros.is_empty() else Tema.cor_sucesso(true))
	_assinar.disabled = not erros.is_empty()
	_assinar.tooltip_text = "" if erros.is_empty() else "Bloqueado: " + "; ".join(PackedStringArray(erros))
	var pagina := _abas.get_tab_title(_abas.current_tab)
	var v: VBoxContainer = _paginas[pagina]
	if _idade != null and _idade.get_parent() != null:
		_idade.get_parent().remove_child(_idade)   # a idade mora numa linha que é refeita
	for filho in v.get_children():
		if filho == _nome or filho == _idade or filho in _campos_descricao.values():
			v.remove_child(filho)   # campos de texto são reaproveitados (mantêm o cursor)
			continue
		filho.visible = false
		filho.queue_free()
	_atualizar_foto()
	match pagina:
		"Conceito": _pagina_conceito(v)
		"Origem": _pagina_origem(v)
		"Classe": _pagina_classe(v)
		"Atributos": _pagina_atributos(v)
		"Perícias": _pagina_pericias(v)
		"Rituais": _pagina_rituais(v)
		"Descrição": _pagina_descricao(v)
		"Revisão": _pagina_revisao(v, res, erros)


# --- Foto 3x4 (docs/19) --------------------------------------------------------------

func _coluna_foto() -> Control:
	var caixa := VBoxContainer.new()
	var vao := Control.new()
	vao.custom_minimum_size = Vector2(0, 38)   # alinha com o papel, abaixo das abas
	caixa.add_child(vao)
	var painel := PanelContainer.new()
	painel.theme_type_variation = "PainelLateral"
	painel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caixa.add_child(painel)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(176, 0)
	col.add_theme_constant_override("separation", 6)
	painel.add_child(col)
	var topo := Control.new()
	topo.custom_minimum_size = Vector2(0, 8)   # espaço para o clipe
	col.add_child(topo)
	_foto = FotoAgente.new()
	_foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(_foto)
	_lbl_aparencia = Label.new()
	_lbl_aparencia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_aparencia.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	col.add_child(_lbl_aparencia)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(linha)
	for par in [["◂", -1], ["▸", 1]]:
		var b := Button.new()
		b.text = par[0]
		b.tooltip_text = "Outra aparência (vale para a miniatura no mapa e no combate)"
		b.pressed.connect(_trocar_aparencia.bind(par[1]))
		linha.add_child(b)
		if par[1] < 0:
			var l := Label.new()
			l.text = "Aparência"
			linha.add_child(l)
	var tom := Button.new()
	tom.text = "Tom da roupa"
	tom.tooltip_text = "Original, sépia, noite ou luto"
	tom.pressed.connect(_trocar_tom.bind(1))
	col.add_child(tom)
	var nota := Label.new()
	nota.text = "A foto vale para a miniatura no mapa, no combate e na investigação."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size = Vector2(176, 0)
	nota.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	nota.add_theme_font_size_override("font_size", Tema.FONTE_P)
	col.add_child(nota)
	return caixa


func _trocar_aparencia(passo: int) -> void:
	var lista: Array = Pecas.APARENCIAS.keys()
	var atual := Pecas.modelo_do_agente(String(ficha.classe), String(ficha.aparencia))
	ficha.aparencia = lista[posmod(lista.find(atual) + passo, lista.size())]
	Som.tocar("papel")
	_atualizar_foto()


func _trocar_tom(passo: int) -> void:
	ficha.tom = posmod(int(ficha.tom) + passo, Pecas.TONS.size())
	_atualizar_foto()


## Sem escolha, a foto acompanha a classe; o texto diz o que está valendo.
func _atualizar_foto() -> void:
	if _foto == null:
		return
	_foto.mostrar(String(ficha.classe), String(ficha.aparencia), int(ficha.tom))
	_foto.legenda = String(ficha.nome).strip_edges()
	var modelo := Pecas.modelo_do_agente(String(ficha.classe), String(ficha.aparencia))
	_lbl_aparencia.text = "%s · %s%s" % [Pecas.APARENCIAS.get(modelo, modelo), Pecas.TONS[int(ficha.tom)][0],
		"" if String(ficha.aparencia) != "" else " (da classe)"]


# --- Peças das páginas ------------------------------------------------------------

func _titulo(v: Control, texto: String) -> void:
	var l := Label.new()
	l.text = texto.to_upper()
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", Tema.FONTE_G)
	v.add_child(l)


func _nota(v: Control, texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
	v.add_child(l)
	return l


func _grade(v: Control, colunas: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 4)
	v.add_child(g)
	return g


func _opcao(pai: Control, texto: String, marcado: bool, acao: Callable, dica: String = "") -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = "BotaoPapel"
	b.toggle_mode = true
	b.button_pressed = marcado
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(200, 0)
	b.tooltip_text = dica
	b.pressed.connect(func():
		acao.call()
		_redesenhar())
	pai.add_child(b)
	return b


func _nome_pericia(p: String) -> String:
	return String(rs.pericia(p).get("nome", p))


# --- Páginas ------------------------------------------------------------------------

## Passo 1 (p.23-24): quem é o agente, numa frase. Nome, gênero e idade são dos toques
## finais (p.46-47), mas a idade vem primeiro: com a regra opcional, ela muda os atributos.
func _pagina_conceito(v: VBoxContainer) -> void:
	_titulo(v, "Conceito")
	_nota(v, "Antes dos números, a ideia: o que o agente fazia antes de topar com o paranormal, que evento causou esse primeiro contato, o quanto ele sabe do Outro Lado e como age numa investigação e numa briga. Resuma numa frase.")
	_rotulo(v, "Nome")
	if _nome == null:
		_nome = LineEdit.new()
		_nome.placeholder_text = "Nome do agente (de preferência, coerente com a nacionalidade)"
		_nome.custom_minimum_size = Vector2(360, 0)
		_nome.max_length = 24
		_nome.text_changed.connect(func(t):
			ficha.nome = t
			_foto.legenda = String(t).strip_edges()
			var res := _validar()
			_assinar.disabled = String(t).strip_edges() == "" or not res.erros.is_empty())
	v.add_child(_nome)
	for c in CAMPOS_CONCEITO:
		_campo_texto(v, c)
	_rotulo(v, "Idade")
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 10)
	v.add_child(linha)
	if _idade == null:
		_idade = SpinBox.new()
		_idade.min_value = 9
		_idade.max_value = 99
		_idade.suffix = "anos"
		_idade.value = 22
		ficha.idade_anos = 22
		_idade.value_changed.connect(func(valor):
			ficha.idade_anos = int(valor)
			if idade_variada:
				_aplicar_faixa()
				_redesenhar())
	linha.add_child(_idade)
	var rolar := Button.new()
	rolar.text = "Rolar 2d6+15"
	rolar.theme_type_variation = "BotaoPapel"
	rolar.tooltip_text = "Sem idade em mente? O livro sugere 2d6+15 (17 a 27 anos), ou a idade que combine com a origem."
	rolar.pressed.connect(func(): _idade.value = 15 + randi_range(1, 6) + randi_range(1, 6))
	linha.add_child(rolar)
	var regra := CheckBox.new()
	regra.text = "Regra opcional: idade variada"
	regra.tooltip_text = "Com esta regra, a faixa etária muda o jogo: crianças e adolescentes têm atributos limitados e parte dos benefícios da origem; adultos ganham um poder; maduros e idosos começam com NEX maior e carregam desvantagens. Combine com a mesa."
	regra.button_pressed = idade_variada
	regra.toggled.connect(func(on):
		idade_variada = on
		_aplicar_faixa()
		_redesenhar())
	v.add_child(regra)
	if idade_variada and String(ficha.idade) != "":
		var faixa := rs.faixa_idade(String(ficha.idade))
		_nota(v, "Faixa: %s (%s) — %s" % [faixa.nome, faixa.get("idade", ""), faixa.get("habilidade", {}).get("descricao", "")])
		var n := int(faixa.get("desvantagens", 0))
		if n > 0:
			_nota(v, "Escolha %d desvantage%s de idade (%d/%d):" % [n, "m" if n == 1 else "ns", (ficha.desvantagens_idade as Array).size(), n])
			var g := _grade(v, 3)
			for dv in rs.dados.idades.desvantagens:
				_opcao(g, String(dv.nome), String(dv.id) in ficha.desvantagens_idade, func():
					_alternar(ficha.desvantagens_idade, String(dv.id), n), String(dv.get("descricao", "")))


const CAMPOS_CONCEITO := [
	["conceito", "Conceito", "Numa frase. Ex.: perita forense que nunca segurou uma arma, mas não larga um mistério.", false],
	["genero", "Gênero", "Livre.", false],
]


## A faixa etária da regra opcional a partir da idade em anos, e o NEX inicial dela.
func _aplicar_faixa() -> void:
	ficha.idade = faixa_por_anos(rs, int(ficha.idade_anos)) if idade_variada else ""
	var faixa := rs.faixa_idade(String(ficha.idade)) if String(ficha.idade) != "" else {}
	ficha.nex = 5 + int(faixa.get("nex_bonus", 0))
	var n := int(faixa.get("desvantagens", 0))
	while (ficha.desvantagens_idade as Array).size() > n:
		(ficha.desvantagens_idade as Array).pop_back()
	if not faixa.has("beneficios_de_origem"):
		ficha.beneficios_origem = []
	if int(ficha.nex) < 10:
		ficha.trilha = ""
	while (ficha.poderes as Array).size() > poderes_esperados():
		(ficha.poderes as Array).pop_back()


## "9 a 12 anos" e "65 anos ou mais" viram limites; a primeira faixa que contém a idade.
static func faixa_por_anos(ruleset: Ruleset, anos: int) -> String:
	for f in ruleset.dados.idades.faixas:
		var nums: Array = []
		for m in RegEx.create_from_string("\\d+").search_all(String(f.get("idade", ""))):
			nums.append(int(m.get_string()))
		if nums.size() == 2 and anos >= nums[0] and anos <= nums[1]:
			return String(f.id)
		if nums.size() == 1 and anos >= nums[0]:
			return String(f.id)
	return ""


## Passo 3 (p.26-31): o que fazia antes da Ordem. Crianças e adolescentes, na regra de idade,
## escolhem só parte dos benefícios (p.182).
func _pagina_origem(v: VBoxContainer) -> void:
	_titulo(v, "Origem")
	_nota(v, "O que o agente fazia antes da Ordem. Dá duas perícias treinadas e um poder.")
	var g := _grade(v, 4)
	for o in rs.dados.origens.origens:
		var pers := PackedStringArray((o.get("pericias", []) as Array).map(func(p): return _nome_pericia(p)))
		var dica := "%s\nPerícias: %s\nPoder: %s — %s" % [o.nome, ", ".join(pers) if not pers.is_empty() else "escolha %d" % int(o.get("pericias_escolha", 0)),
			o.get("poder", {}).get("nome", "—"), o.get("poder", {}).get("descricao", "")]
		_opcao(g, o.nome, ficha.origem == o.id, func():
			ficha.origem = o.id
			ficha.pericias_origem = []
			ficha.beneficios_origem = [], dica)
	var atual := rs.origem(ficha.origem)
	_nota(v, "%s · %s" % [atual.nome, atual.get("poder", {}).get("descricao", "")])
	var faixa := rs.faixa_idade(String(ficha.idade)) if String(ficha.idade) != "" else {}
	if faixa.has("beneficios_de_origem"):
		var n := int(faixa.beneficios_de_origem)
		_rotulo(v, "Benefícios da origem (%s): escolha %d" % [faixa.nome, n])
		var opcoes: Array = (atual.get("pericias", []) as Array).map(func(p): return "pericia:" + String(p))
		opcoes.append("poder")
		var gb := _grade(v, 3)
		for b in opcoes:
			var texto := "Poder: " + String(atual.get("poder", {}).get("nome", "")) if b == "poder" else _nome_pericia(String(b).trim_prefix("pericia:"))
			_opcao(gb, texto, b in ficha.beneficios_origem, func(): _alternar(ficha.beneficios_origem, b, n))


func _rotulo(v: Control, texto: String) -> void:
	var l := Label.new()
	l.text = texto.to_upper()
	l.add_theme_color_override("font_color", Tema.TINTA)
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	v.add_child(l)


## Campo de texto livre reaproveitado entre redesenhos: [id, rótulo, dica, várias linhas].
func _campo_texto(v: Control, c: Array) -> void:
	var id: String = c[0]
	_rotulo(v, c[1])
	if not _campos_descricao.has(id):
		var limite: int = Carreira.LIMITE_DESCRICAO[id]
		var campo: Control
		if c[3]:
			var te := TextEdit.new()
			te.custom_minimum_size = Vector2(0, 110)
			te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			te.placeholder_text = c[2]
			te.text_changed.connect(func():
				if te.text.length() > limite:
					te.text = te.text.left(limite)
				ficha[id] = te.text)
			campo = te
		else:
			var le := LineEdit.new()
			le.max_length = limite
			le.placeholder_text = c[2]
			le.text_changed.connect(func(t): ficha[id] = t)
			campo = le
		campo.tooltip_text = "Até %d caracteres." % limite
		_campos_descricao[id] = campo
	v.add_child(_campos_descricao[id])


func _pagina_classe(v: VBoxContainer) -> void:
	_titulo(v, "Classe")
	for cid in CLASSES:
		var c := rs.classe(cid)
		var texto := "%s — %s\nPV %d + VIG · PE %d + PRE · SAN %d" % [c.nome, c.get("descricao", ""), int(c.pv.inicial), int(c.pe.inicial), int(c.san.inicial)]
		var b := _opcao(v, texto, ficha.classe == cid, func():
			ficha.classe = cid
			ficha.pericias_classe = []
			ficha.pericias_livres = []
			ficha.perito = []
			ficha.rituais = []
			ficha.trilha = ""
			ficha.poderes = [])
		b.custom_minimum_size = Vector2(0, 58)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bloco_trilha_e_poderes(v)


## Trilha (NEX 10%) e poderes de classe, quando a idade variada faz o agente começar com
## mais experiência (adulto: um poder a mais; maduro e idoso: NEX maior). Poderes que pedem
## escolhas extras ficam para a Base, depois de assinar.
const PODERES_COM_ESCOLHA := ["treinamento_em_pericia", "especialista_em_elemento", "ritual_predileto"]


func _bloco_trilha_e_poderes(v: VBoxContainer) -> void:
	var nex := int(ficha.nex)
	if nex >= 10:
		_rotulo(v, "Trilha (NEX 10%)")
		var gt := _grade(v, 3)
		for t in rs.dados.trilhas.trilhas.get(String(ficha.classe), []):
			_opcao(gt, String(t.nome), ficha.trilha == t.id, func(): ficha.trilha = String(t.id), String(t.get("descricao", "")))
	var n := poderes_esperados()
	if n <= 0:
		return
	var motivo := "a Vivência do adulto" if nex < 15 else "o NEX %d%%" % nex
	_rotulo(v, "Poderes de classe: %d (%s) — %d/%d" % [n, motivo, (ficha.poderes as Array).size(), n])
	var gp := _grade(v, 3)
	for p in rs.dados.poderes_classe.poderes.get(String(ficha.classe), []):
		if String(p.id) in PODERES_COM_ESCOLHA:
			continue
		var pre := "" if (p.get("pre", {}) as Dictionary).is_empty() else "\nTem pré-requisito: o rodapé avisa se a ficha não cumprir."
		_opcao(gp, String(p.nome), String(p.id) in ficha.poderes, func(): _alternar(ficha.poderes, String(p.id), n),
			String(p.get("descricao", "")) + pre)


func _pagina_atributos(v: VBoxContainer) -> void:
	_titulo(v, "Atributos")
	var gastos := 0
	var zerados := 0
	for k in ATRIBUTOS:
		gastos += int(ficha.atributos[k]) - 1
		zerados += 1 if int(ficha.atributos[k]) == 0 else 0
	_nota(v, "Todos começam em 1. Distribua 4 pontos (máximo 3). Dá para baixar um atributo para 0 e ganhar 1 ponto.  Pontos restantes: %d" % (4 - gastos))
	for k in ATRIBUTOS:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		v.add_child(h)
		var l := Label.new()
		l.text = NOMES_ATRIBUTOS[k]
		l.custom_minimum_size = Vector2(140, 0)
		h.add_child(l)
		var valor := int(ficha.atributos[k])
		var menos := Button.new()
		menos.text = " − "
		menos.theme_type_variation = "BotaoPapel"
		menos.disabled = valor <= 0 or (valor == 1 and zerados >= 1)
		menos.pressed.connect(func():
			ficha.atributos[k] = valor - 1
			_redesenhar())
		h.add_child(menos)
		var n := Label.new()
		n.text = str(valor)
		n.custom_minimum_size = Vector2(30, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", Tema.FONTE_G)
		h.add_child(n)
		var mais := Button.new()
		mais.text = " + "
		mais.theme_type_variation = "BotaoPapel"
		mais.disabled = valor >= 3 or gastos >= 4
		mais.pressed.connect(func():
			ficha.atributos[k] = valor + 1
			_redesenhar())
		h.add_child(mais)
		var efeito := Label.new()
		efeito.text = {"agi": "Defesa, iniciativa e o movimento no mapa", "for": "Dano corpo a corpo e carga",
			"int": "Perícias extras e rituais", "pre": "PE e Sanidade", "vig": "PV e resistência"}[k]
		efeito.add_theme_color_override("font_color", Color(Tema.TINTA, 0.7))
		h.add_child(efeito)


func _pagina_pericias(v: VBoxContainer) -> void:
	var origem := rs.origem(ficha.origem)
	var classe := rs.classe(ficha.classe)
	_titulo(v, "Perícias")
	var garantidas: Array = []
	if int(origem.get("pericias_escolha", 0)) > 0:
		_nota(v, "Origem %s: escolha %d perícias." % [origem.nome, int(origem.pericias_escolha)])
		var g := _grade(v, 4)
		for p in rs.dados.pericias.pericias:
			var pid: String = p.id
			_opcao(g, p.nome, pid in ficha.pericias_origem, func(): _alternar(ficha.pericias_origem, pid, int(origem.pericias_escolha)))
		garantidas.append_array(ficha.pericias_origem)
	else:
		garantidas.append_array(origem.pericias)
		_nota(v, "Da origem (%s): %s." % [origem.nome, ", ".join(PackedStringArray((origem.pericias as Array).map(func(p): return _nome_pericia(p))))])
	garantidas.append_array(classe.get("pericias_fixas", []))
	if not classe.get("pericias_fixas", []).is_empty():
		_nota(v, "Da classe: %s." % ", ".join(PackedStringArray((classe.pericias_fixas as Array).map(func(p): return _nome_pericia(p)))))
	for par in classe.get("pericias_fixas_escolha", []):
		_nota(v, "Da classe, escolha uma:")
		var h := HBoxContainer.new()
		v.add_child(h)
		for p in par:
			_opcao(h, _nome_pericia(p), p in ficha.pericias_classe, func():
				for outra in par:
					ficha.pericias_classe.erase(outra)
				ficha.pericias_classe.append(p))
		garantidas.append_array((par as Array).filter(func(p): return p in ficha.pericias_classe))
	var unicas := {}
	for p in garantidas:
		unicas[p] = true
	var livres := int(classe.pericias_livres.base) + int(ficha.atributos.get("int", 0)) + (garantidas.size() - unicas.size())
	ficha.pericias_livres = ficha.pericias_livres.filter(func(p): return not unicas.has(p))
	_nota(v, "Livres: escolha %d (%d da classe + Intelecto). Faltam %d." % [livres, int(classe.pericias_livres.base), livres - ficha.pericias_livres.size()])
	var g2 := _grade(v, 4)
	for p in rs.dados.pericias.pericias:
		var pid: String = p.id
		if unicas.has(pid):
			continue
		_opcao(g2, p.nome, pid in ficha.pericias_livres, func(): _alternar(ficha.pericias_livres, pid, livres))
	if ficha.classe == "especialista":
		var perito := rs.habilidade_classe("perito")
		_nota(v, "Perito: escolha %d perícias treinadas (exceto Luta e Pontaria) para somar um dado com PE." % int(perito.quantidade_pericias))
		var g3 := _grade(v, 4)
		var treinadas: Array = unicas.keys() + ficha.pericias_livres
		for pid in treinadas:
			if pid in perito.exceto:
				continue
			_opcao(g3, _nome_pericia(pid), pid in ficha.perito, func(): _alternar(ficha.perito, pid, int(perito.quantidade_pericias)))


func _pagina_rituais(v: VBoxContainer) -> void:
	_titulo(v, "Rituais")
	if ficha.classe != "ocultista":
		_nota(v, "Só o Ocultista começa conhecendo rituais. Combatentes e Especialistas aprendem por poderes, mais tarde.")
		return
	var qtd := rituais_esperados()
	var circulo := rs.circulo_maximo(int(ficha.nex))
	_nota(v, "Escolha %d rituais (%d/%d), até o %dº círculo. Os marcados com * ainda não têm efeito no jogo." % [qtd, (ficha.rituais as Array).size(), qtd, circulo])
	var g := _grade(v, 3)
	for r in rs.dados.rituais.rituais:
		if int(r.circulo) > circulo:
			continue
		var rid: String = r.id
		var nome := "%s (%s%s)%s" % [r.nome, r.elemento, "" if int(r.circulo) == 1 else ", %dº" % int(r.circulo), "" if r.get("implementado", false) else " *"]
		_opcao(g, nome, rid in ficha.rituais, func(): _alternar(ficha.rituais, rid, qtd), String(r.get("descricao", "")))


## Ocultista: 3 rituais iniciais, mais 1 por NEX acima de 5% (p.42).
func rituais_esperados() -> int:
	return 3 + rs.niveis_de_exposicao(int(ficha.nex)) - 1


## Poderes de classe que a ficha precisa ter: os do NEX e o da Vivência do adulto (p.183).
func poderes_esperados() -> int:
	var n := rs.quantos_ate("poder", int(ficha.nex))
	if String(ficha.idade) != "" and rs.faixa_idade(String(ficha.idade)).get("poder_extra", false):
		n += 1
	return n


## Descrição (p.46-47; docs/26 e 27): os toques finais. Nada aqui muda as regras.
const CAMPOS_DESCRICAO := [
	["aparencia_texto", "Aparência", "Uma frase pelos traços marcantes, não uma lista. Ex.: físico de halterofilista e um terno dois números menor.", false],
	["personalidade", "Personalidade", "Três traços, um deles em conflito com os outros. Ex.: corajoso e decidido, mas tímido.", false],
	["historico", "Histórico", "Infância e família, se acredita no paranormal, como foi recrutado. Pense em um acontecimento bom e um ruim no passado.", true],
	["objetivo", "Objetivo", "Por que está na Ordem? Proteger inocentes, vingança, uma história para contar, aposentar-se em paz…", false],
]


func _pagina_descricao(v: VBoxContainer) -> void:
	_titulo(v, "Descrição")
	_nota(v, "Opcional, e pode crescer ao longo do jogo. Atributos, origem e classe ajudam: Presença alta pede alguém falante; um militar fala curto e grosso. A foto ao lado é a aparência da miniatura.")
	for c in CAMPOS_DESCRICAO:
		_campo_texto(v, c)


## Revisão (docs/26): a página 1 da ficha nova, como o agente vai ficar — já com o
## equipamento inicial da classe, para os ataques e a Defesa saírem certos.
func _pagina_revisao(v: VBoxContainer, res: Dictionary, erros: Array) -> void:
	_titulo(v, "Revisão da ficha")
	if res.agente != null:
		var a: Agente = res.agente
		a.nome = String(ficha.nome).strip_edges() if String(ficha.nome).strip_edges() != "" else "(sem nome)"
		a.aparencia = String(ficha.aparencia)
		a.tom = int(ficha.tom)
		a.conceito = String(ficha.conceito)
		var kit := carreira.kit_da_classe(ficha.classe)
		for item in kit.get("equipamento", []):
			a.equipamento.append(item)
		a.arma_id = String(kit.get("arma", ""))
		# "Revise sua ficha" (p.23 e p.46): as características derivadas com a conta
		var c := rs.classe(String(ficha.classe))
		var conta := PackedStringArray()
		conta.append("PV %d = %d (classe) + %d VIG" % [a.pv_maximo, int(c.pv.inicial), a.atributo("vig")])
		conta.append("PE %d = %d (classe) + %d PRE" % [a.pe_maximo, int(c.pe.inicial), a.atributo("pre")])
		conta.append("SAN %d (classe)" % a.san_maximo)
		conta.append("Defesa %d = 10 + %d AGI e modificadores" % [a.defesa(), a.atributo("agi")])
		conta.append("Deslocamento %d m" % int(a.deslocamento_m()))
		_nota(v, " · ".join(conta))
		var pend := Progressao.pendencias(a)
		if not pend.is_empty():
			_nota(v, "Depois de assinar, %d escolha%s na ficha (ex.: o poder extra do adulto)." % [pend.size(), "" if pend.size() == 1 else "s"])
		_revisao = FichaAgente.pagina_um(a)
		v.add_child(_revisao)
		_nota(v, "Equipamento (p.23: a Ordem entrega o necessário na primeira missão): %s." % ", ".join(PackedStringArray((kit.equipamento as Array).map(func(i): return rs.equipamento(i).get("nome", i)))))
		var desc := PackedStringArray()
		for campo in CAMPOS_DESCRICAO:
			if String(ficha.get(campo[0], "")).strip_edges() != "":
				desc.append("%s: %s" % [campo[1], String(ficha[campo[0]]).strip_edges()])
		_nota(v, "\n".join(desc) if not desc.is_empty() else "Descrição em branco (opcional).")
	for e in erros:
		var l := _nota(v, "• " + String(e))
		l.add_theme_color_override("font_color", Tema.SANGUE)


## Liga/desliga um item numa lista com limite (o mais antigo sai se passar do limite).
var _revisao: Control   ## a página 1 da ficha na revisão (para os testes)


func _alternar(lista: Array, valor: String, limite: int) -> void:
	if valor in lista:
		lista.erase(valor)
	else:
		lista.append(valor)
		while lista.size() > limite and limite > 0:
			lista.remove_at(0)


func _assinar_ficha() -> void:
	var f := ficha.duplicate(true)
	if f.classe != "ocultista":
		f.erase("rituais")
	if f.classe != "especialista":
		f.erase("perito")
	if f.classe != "combatente":
		f.pericias_classe = []
	var res := carreira.recrutar_ficha(f)
	if res.agente == null:
		_erros.text = "; ".join(PackedStringArray(res.erros))
		return
	Som.tocar("carimbo")
	criado.emit(res.agente)
	queue_free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
