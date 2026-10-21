class_name CriacaoDossie
extends CanvasLayer
## Criação de agente preenchendo a própria ficha (docs/30): as mesmas páginas da ficha do
## jogo (Agente; Habilidades e inventário; Rituais), editáveis. Os blocos levam os números do
## passo a passo do livro (p.23): ① conceito, ② atributos, ③ origem, ④ classe, ⑤ perícias;
## os toques finais (p.46-47) ficam na descrição. A ficha se calcula enquanto é preenchida. A ficha é validada a cada mudança
## por CriacaoAgente; "Assinar e arquivar" só fica liberado sem erros. Ao lado das abas, a
## foto 3x4 presa com clipe (docs/19): aparência e tom da roupa, que valem para a miniatura.
##   CriacaoDossie.abrir(self, carreira, func(agente): ...)

signal criado(agente: Agente)

const CLASSES := ["combatente", "especialista", "ocultista"]
## Os passos do livro (p.23), mais a descrição dos toques finais (p.46-47).
const PASSOS := ["Agente", "Habilidades e inventário", "Rituais"]
const NUMEROS := ["①", "②", "③", "④", "⑤"]
const ATRIBUTOS := ["agi", "for", "int", "pre", "vig"]
const NOMES_ATRIBUTOS := {"agi": "Agilidade", "for": "Força", "int": "Intelecto", "pre": "Presença", "vig": "Vigor"}

var carreira: Carreira
var rs: Ruleset
var ficha := {"nome": "", "origem": "", "classe": "combatente", "nex": 5,
	"atributos": {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1},
	"pericias_origem": [], "pericias_classe": [], "pericias_livres": [], "perito": [], "rituais": [],
	"aparencia": "", "tom": 0, "personalidade": "", "historico": "", "objetivo": "",
	"conceito": "", "genero": "", "idade_anos": 0, "aparencia_texto": "",
	"idade": "", "desvantagens_idade": [], "beneficios_origem": [], "trilha": "", "poderes": [],
	"treinamentos": [], "escolhas": {}}
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
var _bloco_foto: HBoxContainer
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
	pasta.custom_minimum_size = Vector2(1180, 620)
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
	_abas.custom_minimum_size = Vector2(1180, 0)
	_abas.add_theme_font_size_override("font_size", Tema.FONTE_M - 1)   # os oito passos do livro cabem   # a pasta não muda de largura entre as abas
	meio.add_child(_abas)
	_montar_foto()
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
	# Campos de texto e a foto são reaproveitados (mantêm o cursor e não refazem o retrato)
	for c in [_nome, _idade, _bloco_foto] + _campos_descricao.values():
		if c != null and c.get_parent() != null:
			c.get_parent().remove_child(c)
	for filho in v.get_children():
		filho.visible = false
		filho.queue_free()
	_atualizar_foto()
	match pagina:
		"Agente": _pagina_agente(v, res)
		"Habilidades e inventário": _pagina_habilidades(v, res)
		"Rituais": _pagina_rituais(v)


# --- Foto 3x4 (docs/19) --------------------------------------------------------------

## A foto 3x4 e os botões de aparência: criados uma vez, colocados na descrição (página 2).
func _montar_foto() -> void:
	_bloco_foto = HBoxContainer.new()
	_bloco_foto.add_theme_constant_override("separation", 12)
	_foto = FotoAgente.new()
	_foto.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_bloco_foto.add_child(_foto)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_bloco_foto.add_child(col)
	_lbl_aparencia = Label.new()
	_lbl_aparencia.add_theme_color_override("font_color", Tema.TINTA)
	col.add_child(_lbl_aparencia)
	var linha := HBoxContainer.new()
	col.add_child(linha)
	for par in [["◂", -1], ["▸", 1]]:
		var b := Button.new()
		b.text = par[0]
		b.theme_type_variation = "BotaoPapel"
		b.tooltip_text = "Outra aparência (vale para a miniatura no mapa e no combate)"
		b.pressed.connect(_trocar_aparencia.bind(par[1]))
		linha.add_child(b)
		if par[1] < 0:
			var l := Label.new()
			l.text = " Modelo "
			l.add_theme_color_override("font_color", Tema.TINTA)
			linha.add_child(l)
	var tom := Button.new()
	tom.text = "Tom da roupa"
	tom.theme_type_variation = "BotaoPapel"
	tom.tooltip_text = "Original, sépia, noite ou luto"
	tom.pressed.connect(_trocar_tom.bind(1))
	col.add_child(tom)
	var nota := Label.new()
	nota.text = "A foto vale para a miniatura no mapa, no combate e na investigação."
	nota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nota.custom_minimum_size = Vector2(220, 0)
	nota.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
	col.add_child(nota)


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
## Garante o campo do nome (reaproveitado entre redesenhos).
func _campo_nome() -> LineEdit:
	if _nome == null:
		_nome = LineEdit.new()
		_nome.placeholder_text = "Nome do agente (coerente com a nacionalidade)"
		_nome.max_length = 24
		_nome.text_changed.connect(func(t):
			ficha.nome = t
			if _foto != null:
				_foto.legenda = String(t).strip_edges()
			var res := _validar()
			_assinar.disabled = String(t).strip_edges() == "" or not res.erros.is_empty())
	_nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return _nome


func _campo_idade() -> SpinBox:
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
	return _idade


## Selo com o número do passo do livro (p.23) e o rótulo preto da ficha.
func _cabeca(numero: int, texto: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	if numero > 0:
		var n := Label.new()
		n.text = NUMEROS[numero - 1]
		n.add_theme_color_override("font_color", Tema.SANGUE)
		n.add_theme_font_size_override("font_size", Tema.FONTE_G)
		n.tooltip_text = "Passo %d do livro (p.23)" % numero
		n.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(n)
	var a := FichaAgente.aba(texto)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	return h


## Linha de formulário: rótulo preto e um controle à direita.
func _linha_campo(rotulo: String, controle: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	h.add_child(FichaAgente.aba(rotulo))
	controle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(controle)
	return h


## O agente como ficaria: o da validação (com o kit) quando a ficha fecha; senão, null.
func _previa(res: Dictionary) -> Agente:
	var a: Agente = res.agente
	if a == null:
		return null
	a.nome = String(ficha.nome).strip_edges()
	var kit := carreira.kit_da_classe(String(ficha.classe))
	for item in kit.get("equipamento", []):
		a.equipamento.append(item)
	a.arma_id = String(kit.get("arma", ""))
	return a


## Página 1 — Agente (docs/30): a ficha oficial preenchida na hora.
func _pagina_agente(v: VBoxContainer, res: Dictionary) -> void:
	var previa := _previa(res)
	var raiz := HFlowContainer.new()
	raiz.add_theme_constant_override("h_separation", 18)
	raiz.add_theme_constant_override("v_separation", 14)
	v.add_child(raiz)
	var esq := VBoxContainer.new()
	esq.custom_minimum_size = Vector2(570, 0)
	esq.add_theme_constant_override("separation", 7)
	raiz.add_child(esq)
	_nota(esq, "Preencha na ordem dos números, como no passo a passo do livro. O rodapé diz o que falta.")
	# ① Conceito
	esq.add_child(_cabeca(1, "Conceito"))
	esq.add_child(_linha_campo("Personagem", _campo_nome()))
	_campo_linha(esq, CAMPOS_CONCEITO[0])
	var linha_idade := HBoxContainer.new()
	linha_idade.add_theme_constant_override("separation", 6)
	linha_idade.add_child(FichaAgente.aba("Idade"))
	linha_idade.add_child(_campo_idade())
	var rolar := Button.new()
	rolar.text = "2d6+15"
	rolar.theme_type_variation = "BotaoPapel"
	rolar.tooltip_text = "Sem idade em mente? O livro sugere 2d6+15 (17 a 27 anos), ou a idade que combine com a origem."
	rolar.pressed.connect(func(): _idade.value = 15 + randi_range(1, 6) + randi_range(1, 6))
	linha_idade.add_child(rolar)
	var regra := CheckBox.new()
	regra.text = "Idade variada (regra opcional)"
	regra.tooltip_text = "A faixa etária muda o jogo: crianças e adolescentes têm atributos limitados e parte dos benefícios da origem; adultos ganham um poder; maduros e idosos começam com NEX maior e carregam desvantagens. Combine com a mesa."
	regra.button_pressed = idade_variada
	regra.toggled.connect(func(on):
		idade_variada = on
		_aplicar_faixa()
		_redesenhar())
	linha_idade.add_child(regra)
	esq.add_child(linha_idade)
	_detalhes_idade(esq)
	# ② Atributos ao lado de ③ origem e ④ classe
	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 12)
	esq.add_child(meio)
	var col_attr := VBoxContainer.new()
	col_attr.add_child(_cabeca(2, "Atributos"))
	col_attr.add_child(_pentagono_editavel())
	meio.add_child(col_attr)
	var ident := VBoxContainer.new()
	ident.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ident.add_theme_constant_override("separation", 6)
	meio.add_child(ident)
	ident.add_child(_cabeca(3, "Origem"))
	ident.add_child(_lista_origens())
	var origem := rs.origem(String(ficha.origem))
	var poder := _nota(ident, "Poder: %s — %s" % [origem.get("poder", {}).get("nome", "—"), origem.get("poder", {}).get("descricao", "")])
	poder.custom_minimum_size = Vector2(300, 0)
	_beneficios_origem(ident)
	ident.add_child(_cabeca(4, "Classe"))
	ident.add_child(_lista_classes())
	var c := rs.classe(String(ficha.classe))
	_nota(ident, "PV %d + VIG · PE %d + PRE · SAN %d" % [int(c.pv.inicial), int(c.pe.inicial), int(c.san.inicial)])
	if int(ficha.nex) >= 10:
		ident.add_child(_linha_campo("Trilha", _lista_trilhas()))
	var nums := HBoxContainer.new()
	nums.add_theme_constant_override("separation", 8)
	nums.add_child(FichaAgente.campo("NEX", "%d%%" % int(ficha.nex), 40))
	nums.add_child(FichaAgente.campo("PE/rodada", str(rs.limite_pe(int(ficha.nex))), 24))
	nums.add_child(FichaAgente.campo("Desl.", "9 m" if previa == null else "%d m" % int(previa.deslocamento_m()), 40))
	ident.add_child(nums)
	# PV, PE, SAN e Defesa: a conta do livro (p.46), ao vivo
	var vig := int(ficha.atributos.vig)
	var pre := int(ficha.atributos.pre)
	var pv := previa.pv_maximo if previa != null else int(c.pv.inicial) + vig
	var pe := previa.pe_maximo if previa != null else int(c.pe.inicial) + pre
	var san := previa.san_maximo if previa != null else int(c.san.inicial)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 10)
	status.add_child(FichaAgente.caixa_status("PV", "Pontos de vida", pv, pv, Tema.SANGUE))
	status.add_child(FichaAgente.caixa_status("PE", "Pontos de esforço", pe, pe, Tema.ELEMENTO.energia.darkened(0.3)))
	status.add_child(FichaAgente.caixa_status("SAN", "Sanidade", san, san, Color("2f6f7a")))
	esq.add_child(status)
	var agi := int(ficha.atributos.agi)
	var defesa := previa.defesa() if previa != null else 10 + agi
	_nota(esq, "Defesa %d = 10 + %d AGI%s · PV %d = %d + %d VIG · PE %d = %d + %d PRE · SAN %d (classe)" % [defesa, agi,
		"" if defesa == 10 + agi else " e modificadores", pv, int(c.pv.inicial), vig, pe, int(c.pe.inicial), pre, san])
	esq.add_child(FichaAgente.aba("Ataques"))
	if previa != null:
		esq.add_child(FichaAgente.grade_ataques(previa))
	else:
		var kit := carreira.kit_da_classe(String(ficha.classe))
		_nota(esq, "Com a arma do kit (%s), os números aparecem quando a ficha fechar." % rs.equipamento(String(kit.get("arma", "desarmado"))).get("nome", "desarmado"))
	# ⑤ Perícias, como a tabela da ficha
	raiz.add_child(_tabela_pericias_criacao())


## Campo de uma linha com rótulo preto (conceito), reaproveitado entre redesenhos.
func _campo_linha(v: Control, c: Array) -> void:
	var id: String = c[0]
	if not _campos_descricao.has(id):
		var le := LineEdit.new()
		le.max_length = Carreira.LIMITE_DESCRICAO[id]
		le.placeholder_text = c[2]
		le.text_changed.connect(func(t): ficha[id] = t)
		le.tooltip_text = "Até %d caracteres." % le.max_length
		_campos_descricao[id] = le
	v.add_child(_linha_campo(c[1], _campos_descricao[id]))


## Faixa e desvantagens da idade variada (p.182).
func _detalhes_idade(v: Control) -> void:
	if not idade_variada or String(ficha.idade) == "":
		return
	var faixa := rs.faixa_idade(String(ficha.idade))
	_nota(v, "Faixa: %s (%s) — %s" % [faixa.nome, faixa.get("idade", ""), faixa.get("habilidade", {}).get("descricao", "")])
	var n := int(faixa.get("desvantagens", 0))
	if n > 0:
		_nota(v, "Escolha %d desvantage%s de idade (%d/%d):" % [n, "m" if n == 1 else "ns", (ficha.desvantagens_idade as Array).size(), n])
		var g := _grade(v, 3)
		for dv in rs.dados.idades.desvantagens:
			_opcao(g, String(dv.nome), String(dv.id) in ficha.desvantagens_idade, func():
				_alternar(ficha.desvantagens_idade, String(dv.id), n), String(dv.get("descricao", "")))


## ② Os atributos no pentágono da ficha, com − e + em volta de cada círculo (p.24).
func _pentagono_editavel() -> Control:
	var gastos := 0
	var zerados := 0
	for k in ATRIBUTOS:
		gastos += int(ficha.atributos[k]) - 1
		zerados += 1 if int(ficha.atributos[k]) == 0 else 0
	var caixa := VBoxContainer.new()
	var area := Control.new()
	area.custom_minimum_size = PentagonoAtributos.TAMANHO + Vector2(44, 0)
	caixa.add_child(area)
	var p := PentagonoAtributos.new()
	p.position = Vector2(22, 0)
	p.size = PentagonoAtributos.TAMANHO
	var temp := Agente.criar(rs, "?", String(ficha.classe), ficha.atributos)
	p.agente = temp
	area.add_child(p)
	var vertices := p.vertices()
	for i in PentagonoAtributos.ORDEM.size():
		var k: String = PentagonoAtributos.ORDEM[i]
		var valor := int(ficha.atributos[k])
		var centro := vertices[i] + p.position
		var menos := _botao_mini("−", valor <= 0 or (valor == 1 and zerados >= 1), func():
			ficha.atributos[k] = valor - 1
			_redesenhar())
		menos.position = centro + Vector2(23, 2)   # − embaixo e + em cima, à direita do círculo
		menos.tooltip_text = "Baixar %s" % NOMES_ATRIBUTOS[k]
		area.add_child(menos)
		var mais := _botao_mini("+", valor >= 3 or gastos >= 4, func():
			ficha.atributos[k] = valor + 1
			_redesenhar())
		mais.position = centro + Vector2(23, -26)
		mais.tooltip_text = "Subir %s — %s" % [NOMES_ATRIBUTOS[k], {"agi": "Defesa, iniciativa e o movimento no mapa", "for": "Dano corpo a corpo e carga",
			"int": "Perícias extras e rituais", "pre": "PE e Sanidade", "vig": "PV e resistência"}[k]]
		area.add_child(mais)
	_nota(caixa, "Pontos: %d de 4 · máximo 3 · um em 0 dá +1" % (4 - gastos))
	return caixa


func _botao_mini(texto: String, desligado: bool, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.theme_type_variation = "BotaoPapel"
	b.custom_minimum_size = Vector2(24, 24)
	b.add_theme_font_size_override("font_size", Tema.FONTE_P)
	b.disabled = desligado
	b.pressed.connect(acao)
	return b


## ③ As 26 origens numa lista, com as perícias e o poder na dica de cada uma.
func _lista_origens() -> OptionButton:
	var o := OptionButton.new()
	var lista: Array = rs.dados.origens.origens
	for i in lista.size():
		var org: Dictionary = lista[i]
		o.add_item(String(org.nome))
		var pers := PackedStringArray((org.get("pericias", []) as Array).map(func(p): return _nome_pericia(p)))
		o.set_item_tooltip(i, "Perícias: %s\nPoder: %s — %s" % [", ".join(pers) if not pers.is_empty() else "escolha %d" % int(org.get("pericias_escolha", 0)),
			org.get("poder", {}).get("nome", "—"), org.get("poder", {}).get("descricao", "")])
		if org.id == ficha.origem:
			o.select(i)
	o.item_selected.connect(func(i):
		ficha.origem = String(lista[i].id)
		ficha.pericias_origem = []
		ficha.beneficios_origem = []
		_redesenhar())
	return o


## Criança e adolescente escolhem parte dos benefícios da origem (p.182).
func _beneficios_origem(v: Control) -> void:
	var faixa := rs.faixa_idade(String(ficha.idade)) if String(ficha.idade) != "" else {}
	if not faixa.has("beneficios_de_origem"):
		return
	var n := int(faixa.beneficios_de_origem)
	var atual := rs.origem(String(ficha.origem))
	_nota(v, "Benefícios da origem (%s): escolha %d" % [faixa.nome, n])
	var opcoes: Array = (atual.get("pericias", []) as Array).map(func(p): return "pericia:" + String(p))
	opcoes.append("poder")
	var gb := _grade(v, 3)
	for b in opcoes:
		var texto := "Poder" if b == "poder" else _nome_pericia(String(b).trim_prefix("pericia:"))
		_opcao(gb, texto, b in ficha.beneficios_origem, func(): _alternar(ficha.beneficios_origem, b, n))


## ④ As classes numa lista; trocar zera o que depende dela.
func _lista_classes() -> OptionButton:
	var o := OptionButton.new()
	for i in CLASSES.size():
		var c := rs.classe(CLASSES[i])
		o.add_item(String(c.nome))
		o.set_item_tooltip(i, String(c.get("descricao", "")))
		if CLASSES[i] == ficha.classe:
			o.select(i)
	o.item_selected.connect(func(i):
		ficha.classe = CLASSES[i]
		ficha.pericias_classe = []
		ficha.pericias_livres = []
		ficha.perito = []
		ficha.rituais = []
		ficha.trilha = ""
		ficha.poderes = []
		ficha.treinamentos = []
		ficha.escolhas = {}
		_redesenhar())
	return o


func _lista_trilhas() -> OptionButton:
	var o := OptionButton.new()
	o.add_item("— escolha —")
	var ids: Array = [""]
	for t in rs.dados.trilhas.trilhas.get(String(ficha.classe), []):
		if falta_pre(t.get("pre", {})) != "":
			continue
		o.add_item(String(t.nome))
		o.set_item_tooltip(o.item_count - 1, String(t.get("descricao", "")))
		ids.append(String(t.id))
		if ficha.trilha == t.id:
			o.select(o.item_count - 1)
	if not ficha.trilha in ids:
		ficha.trilha = ""
	o.item_selected.connect(func(i):
		ficha.trilha = ids[i]
		_redesenhar())
	return o


## ⑤ A tabela de perícias da ficha, para marcar: as da origem e da classe já vêm marcadas;
## as livres e as escolhas (classe, origem com escolha, Perito) se marcam clicando.
func _tabela_pericias_criacao() -> Control:
	var origem := rs.origem(String(ficha.origem))
	var classe := rs.classe(String(ficha.classe))
	var escolha_origem := int(origem.get("pericias_escolha", 0))
	var da_origem: Array = (ficha.pericias_origem as Array).duplicate() if escolha_origem > 0 else (origem.get("pericias", []) as Array).duplicate()
	var faixa := rs.faixa_idade(String(ficha.idade)) if String(ficha.idade) != "" else {}
	if faixa.has("beneficios_de_origem"):
		da_origem = (ficha.beneficios_origem as Array).filter(func(b): return b != "poder").map(func(b): return String(b).trim_prefix("pericia:"))
	var pares: Array = classe.get("pericias_fixas_escolha", [])
	var da_classe: Array = (classe.get("pericias_fixas", []) as Array).duplicate()
	for par in pares:
		for p in par:
			if p in ficha.pericias_classe:
				da_classe.append(p)
	var garantidas := {}
	for p in da_origem + da_classe:
		garantidas[p] = true
	var livres := int(classe.pericias_livres.base) + int(ficha.atributos.get("int", 0)) + (da_origem.size() + da_classe.size() - garantidas.size())
	ficha.pericias_livres = (ficha.pericias_livres as Array).filter(func(p): return not garantidas.has(p))
	var especialista := String(ficha.classe) == "especialista"
	var perito := rs.habilidade_classe("perito") if especialista else {}
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(470, 0)
	v.add_theme_constant_override("separation", 4)
	v.add_child(_cabeca(5, "Perícias"))
	var resumo := PackedStringArray()
	if escolha_origem > 0:
		resumo.append("origem: escolha %d (%d/%d)" % [escolha_origem, da_origem.size(), escolha_origem])
	for par in pares:
		resumo.append("classe: %s" % " ou ".join(PackedStringArray((par as Array).map(func(p): return _nome_pericia(p)))))
	resumo.append("livres: %d/%d (classe + INT)" % [(ficha.pericias_livres as Array).size(), livres])
	if especialista:
		resumo.append("Perito: %d/%d" % [(ficha.perito as Array).size(), int(perito.quantidade_pericias)])
	_nota(v, " · ".join(resumo))
	var g := GridContainer.new()
	g.columns = 5 if especialista else 4
	g.add_theme_constant_override("h_separation", 10)
	g.add_theme_constant_override("v_separation", 1)
	v.add_child(g)
	for cab in ["PERÍCIA", "DADOS", "TREINO", "FONTE"] + (["PERITO"] if especialista else []):
		var l := Label.new()
		l.text = cab
		l.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
		g.add_child(l)
	var siglas := FichaAgente.SIGLAS
	for p in rs.dados.pericias.pericias:
		var pid := String(p.id)
		var fonte := ""
		var travada := false
		if pid in da_origem:
			fonte = "origem"
			travada = escolha_origem == 0 and not faixa.has("beneficios_de_origem")
		elif pid in da_classe:
			fonte = "classe"
			travada = pid in classe.get("pericias_fixas", [])
		elif pid in ficha.pericias_livres:
			fonte = "livre"
		var treinada := fonte != ""
		var b := Button.new()
		b.theme_type_variation = "BotaoPapel"
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.text = "%s %s%s" % ["☑" if treinada else "☐", p.nome, "*" if p.get("somente_treinada", false) else ""]
		b.disabled = travada
		b.tooltip_text = "Vem da %s." % fonte if travada else ("Clique para marcar ou desmarcar." + (" Só pode ser usada com treino." if p.get("somente_treinada", false) else ""))
		b.pressed.connect(_marcar_pericia.bind(pid, escolha_origem, pares, livres))
		g.add_child(b)
		var attr := rs.atributo_da_pericia(pid)
		var d := Label.new()
		d.text = "%d %s" % [int(ficha.atributos.get(attr, 1)), siglas.get(attr, "?")]
		d.add_theme_color_override("font_color", Tema.TINTA)
		g.add_child(d)
		var t := Label.new()
		t.text = "+5" if treinada else "—"
		t.add_theme_color_override("font_color", Tema.TINTA)
		g.add_child(t)
		var fl := Label.new()
		fl.text = fonte
		fl.add_theme_color_override("font_color", Color(Tema.TINTA, 0.75))
		g.add_child(fl)
		if especialista:
			if treinada and not pid in perito.get("exceto", []):
				var pb := _botao_mini("◆" if pid in ficha.perito else "◇", false, func():
					_alternar(ficha.perito, pid, int(perito.quantidade_pericias))
					_redesenhar())
				pb.tooltip_text = "Perito: soma um dado com PE nesta perícia"
				g.add_child(pb)
			else:
				g.add_child(Control.new())
	_nota(v, "* somente treinada")
	return v


func _marcar_pericia(pid: String, escolha_origem: int, pares: Array, livres: int) -> void:
	if escolha_origem > 0 and (pid in ficha.pericias_origem or (ficha.pericias_origem as Array).size() < escolha_origem):
		_alternar(ficha.pericias_origem, pid, escolha_origem)
	else:
		var no_par := false
		for par in pares:
			if pid in par:
				no_par = true
				for outra in par:
					(ficha.pericias_classe as Array).erase(outra)
				if not pid in ficha.pericias_livres:
					(ficha.pericias_classe as Array).append(pid)
		if not no_par or pid in ficha.pericias_livres:
			_alternar(ficha.pericias_livres, pid, livres)
	_redesenhar()


## Página 2 — Habilidades e inventário (docs/30): habilidades, trilha e poderes, a descrição
## com a foto, e os recursos e o equipamento inicial.
func _pagina_habilidades(v: VBoxContainer, res: Dictionary) -> void:
	var previa := _previa(res)
	var raiz := HFlowContainer.new()
	raiz.add_theme_constant_override("h_separation", 26)
	raiz.add_theme_constant_override("v_separation", 14)
	v.add_child(raiz)
	var esq := VBoxContainer.new()
	esq.custom_minimum_size = Vector2(600, 0)
	esq.add_theme_constant_override("separation", 7)
	raiz.add_child(esq)
	esq.add_child(FichaAgente.aba("Habilidades"))
	var habs := RichTextLabel.new()
	habs.bbcode_enabled = true
	habs.fit_content = true
	habs.add_theme_color_override("default_color", Tema.TINTA)
	var linhas := PackedStringArray()
	if previa != null:
		for h in previa.habilidades():
			linhas.append("[b]%s[/b] — %s" % [h.get("nome", "?"), h.get("descricao", "")])
	else:
		var o := rs.origem(String(ficha.origem))
		linhas.append("[b]%s[/b] (origem) — %s" % [o.get("poder", {}).get("nome", "—"), o.get("poder", {}).get("descricao", "")])
		linhas.append("[i]As habilidades da classe aparecem quando a página Agente fechar.[/i]")
	habs.text = "\n".join(linhas)
	esq.add_child(habs)
	_bloco_trilha_e_poderes(esq)
	esq.add_child(FichaAgente.aba("Descrição"))
	esq.add_child(_bloco_foto)
	_campo_linha(esq, CAMPOS_CONCEITO[1])   # gênero
	for c in CAMPOS_DESCRICAO:
		_campo_texto(esq, c)
	var dir := VBoxContainer.new()
	dir.custom_minimum_size = Vector2(440, 0)
	dir.add_theme_constant_override("separation", 8)
	raiz.add_child(dir)
	var l1 := HBoxContainer.new()
	l1.add_theme_constant_override("separation", 10)
	l1.add_child(FichaAgente.campo("Pontos de prestígio", "0", 40))
	l1.add_child(FichaAgente.campo("Patente", "Recruta", 90))
	dir.add_child(l1)
	dir.add_child(FichaAgente.aba("Inventário inicial"))
	var kit := carreira.kit_da_classe(String(ficha.classe))
	for item in kit.get("equipamento", []):
		var e := rs.equipamento(item)
		_nota(dir, "%s · cat. %s · %d esp." % [e.get("nome", item), ["0", "I", "II", "III", "IV"][mini(4, int(e.get("categoria", 0)))], int(e.get("espacos", 1))])
	_nota(dir, "Livro (p.23): a Ordem entrega o necessário na primeira missão. Requisite mais no Arsenal da Base.")


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


## Trilha (NEX 10%) e poderes de classe, quando a idade variada faz o agente começar com
## mais experiência (adulto: um poder a mais; maduro e idoso: NEX maior). Só aparecem os
## poderes cujos pré-requisitos a ficha cumpre agora; os que pedem escolha extra (docs/28)
## abrem a escolha logo abaixo.
const PODERES_COM_ESCOLHA := ["treinamento_em_pericia", "especialista_em_elemento", "ritual_predileto"]
const ELEMENTOS := ["conhecimento", "energia", "morte", "sangue", "medo"]


## Perícias treinadas pela ficha como está: origem (ou os benefícios escolhidos), classe,
## livres e as do Treinamento em Perícia.
func pericias_treinadas() -> Array:
	var lista: Array = []
	var origem := rs.origem(String(ficha.origem))
	var da_origem: Array = (origem.get("pericias", []) as Array).duplicate()
	if int(origem.get("pericias_escolha", 0)) > 0:
		da_origem = (ficha.pericias_origem as Array).duplicate()
	if String(ficha.idade) != "" and rs.faixa_idade(String(ficha.idade)).has("beneficios_de_origem"):
		da_origem = (ficha.beneficios_origem as Array).filter(func(b): return b != "poder").map(func(b): return String(b).trim_prefix("pericia:"))
	var classe := rs.classe(String(ficha.classe))
	for p in da_origem + (classe.get("pericias_fixas", []) as Array) + (ficha.pericias_classe as Array) + (ficha.pericias_livres as Array):
		if not p in lista:
			lista.append(p)
	for par in ficha.treinamentos:
		for p in par:
			if not p in lista:
				lista.append(p)
	return lista


## O pré-requisito de um poder ou trilha, conferido na ficha em construção (o mesmo que
## CriacaoAgente._checar_pre confere no agente pronto). Devolve o que falta ("" = cumpre).
func falta_pre(pre: Dictionary) -> String:
	var faltas := PackedStringArray()
	for attr in pre.get("atributos", {}):
		if int(ficha.atributos.get(attr, 0)) < int(pre.atributos[attr]):
			faltas.append("%s %d" % [String(attr).to_upper(), int(pre.atributos[attr])])
	var treinadas := pericias_treinadas()
	for p in pre.get("treinado", []):
		if not p in treinadas:
			faltas.append("treino em " + _nome_pericia(p))
	var algum: Array = pre.get("treinado_algum", [])
	if not algum.is_empty() and not algum.any(func(p): return p in treinadas):
		faltas.append("treino em " + " ou ".join(PackedStringArray(algum.map(func(p): return _nome_pericia(p)))))
	if int(ficha.nex) < int(pre.get("nex", 0)):
		faltas.append("NEX %d%%" % int(pre.nex))
	if pre.has("poder") and not pre.poder in ficha.poderes:
		faltas.append("o poder " + String(rs.poder(String(ficha.classe), String(pre.poder)).get("nome", pre.poder)))
	return ", ".join(faltas)


func _bloco_trilha_e_poderes(v: VBoxContainer) -> void:
	var nex := int(ficha.nex)   # a trilha fica na página Agente (docs/30)
	var n := poderes_esperados()
	if n <= 0:
		return
	var motivo := "a Vivência do adulto" if nex < 15 else "o NEX %d%%" % nex
	_rotulo(v, "Poderes de classe: %d (%s) — %d/%d" % [n, motivo, (ficha.poderes as Array).size(), n])
	# Poderes escolhidos que deixaram de cumprir o pré-requisito (ex.: mudou um atributo) saem
	for pid in (ficha.poderes as Array).duplicate():
		if falta_pre(rs.poder(String(ficha.classe), String(pid)).get("pre", {})) != "":
			_tirar_poder(String(pid))
	var gp := _grade(v, 3)
	var escondidos := 0
	for p in rs.dados.poderes_classe.poderes.get(String(ficha.classe), []):
		if falta_pre(p.get("pre", {})) != "":
			escondidos += 1
			continue
		_opcao(gp, String(p.nome), String(p.id) in ficha.poderes, func():
			if String(p.id) in ficha.poderes:
				_tirar_poder(String(p.id))
			else:
				_alternar(ficha.poderes, String(p.id), n)
				for tirado in PODERES_COM_ESCOLHA:   # quem saiu pelo limite leva a escolha junto
					if not tirado in ficha.poderes:
						_limpar_escolha(tirado), String(p.get("descricao", "")))
	if escondidos > 0:
		_nota(v, "%d poder%s com pré-requisito que a ficha ainda não cumpre (atributo, treino, NEX ou outro poder) não aparece%s." % [escondidos, "" if escondidos == 1 else "es", "" if escondidos == 1 else "m"])
	_escolhas_dos_poderes(v)


func _tirar_poder(pid: String) -> void:
	(ficha.poderes as Array).erase(pid)
	_limpar_escolha(pid)


func _limpar_escolha(pid: String) -> void:
	match pid:
		"treinamento_em_pericia": ficha.treinamentos = []
		"especialista_em_elemento", "ritual_predileto": (ficha.escolhas as Dictionary).erase(pid)


## As escolhas extras (docs/28): duas perícias para o Treinamento em Perícia, o elemento do
## Especialista em Elemento e o ritual do Ritual Predileto (entre os escolhidos na aba Rituais).
func _escolhas_dos_poderes(v: VBoxContainer) -> void:
	if "treinamento_em_pericia" in ficha.poderes:
		if (ficha.treinamentos as Array).is_empty():
			ficha.treinamentos = [[]]
		var par: Array = ficha.treinamentos[0]
		_rotulo(v, "Treinamento em Perícia: duas perícias novas (%d/2)" % par.size())
		var ja := pericias_treinadas().filter(func(p): return not p in par)
		var g := _grade(v, 4)
		for p in rs.dados.pericias.pericias:
			var pid := String(p.id)
			if pid in ja:
				continue   # em NEX abaixo de 35%, o treinamento só treina perícias novas
			_opcao(g, String(p.nome), pid in par, func(): _alternar(par, pid, 2))
	if "especialista_em_elemento" in ficha.poderes:
		_rotulo(v, "Especialista em Elemento: escolha o elemento")
		var g := _grade(v, 3)   # 5 colunas de 200 px estouravam a pasta
		for el in ELEMENTOS:
			_opcao(g, String(el).capitalize(), ficha.escolhas.get("especialista_em_elemento", "") == el,
				func(): ficha.escolhas["especialista_em_elemento"] = el)
	if "ritual_predileto" in ficha.poderes:
		_rotulo(v, "Ritual Predileto: um dos rituais escolhidos")
		if (ficha.rituais as Array).is_empty():
			_nota(v, "Escolha os rituais na aba Rituais primeiro.")
		var g := _grade(v, 3)
		for rid in ficha.rituais:
			_opcao(g, String(rs.ritual(rid).get("nome", rid)), ficha.escolhas.get("ritual_predileto", "") == rid,
				func(): ficha.escolhas["ritual_predileto"] = rid)


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
		_opcao(g, nome, rid in ficha.rituais, func():
			_alternar(ficha.rituais, rid, qtd)
			if not ficha.escolhas.get("ritual_predileto", "") in ficha.rituais:
				(ficha.escolhas as Dictionary).erase("ritual_predileto"), String(r.get("descricao", "")))


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


## Os campos reaproveitados podem estar fora da árvore (entre um redesenho e outro): saem junto.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for c in [_nome, _idade, _bloco_foto] + _campos_descricao.values():
			if c != null and is_instance_valid(c) and c.get_parent() == null:
				c.free()


func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()
