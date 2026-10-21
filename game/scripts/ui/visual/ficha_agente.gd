class_name FichaAgente
extends TabContainer
## Ficha de agente no formato da ficha oficial de Ordem Paranormal (docs/25), em três páginas:
##   1. Agente — campos de rótulo preto, atributos no pentágono, origem/classe/trilha, NEX,
##      PE por rodada e deslocamento, PV/PE/SAN, Defesa com a conta, proteção, resistências,
##      ataques e a tabela de perícias (dados, bônus, treino, outros);
##   2. Habilidades e inventário — habilidades, proficiências, PP e patente, limite de itens,
##      crédito, carga, itens (com "Usar" fora de combate) e a descrição com a foto;
##   3. Rituais — otimizada: só os rituais conhecidos, já preenchidos, com custo e DT
##      calculados pelas regras, formas, filtro por elemento e aviso de PE.
## A estrutura segue a ficha oficial; o desenho é nosso (papel, tinta, carimbos).
##   var f := FichaAgente.new(); add_child(f); f.mostrar(agente, usar_item)

signal item_usado(item_id: String)
## A descrição foi editada (docs/27): quem abriu a ficha salva a carreira.
signal descricao_editada

## Na Base, a página 2 ganha "Editar descrição"; no jogo (F), não.
var editavel := false

const ELEMENTOS := ["conhecimento", "energia", "morte", "sangue", "medo"]
const NOMES_ELEMENTO := {"conhecimento": "Conhecimento", "energia": "Energia", "morte": "Morte", "sangue": "Sangue", "medo": "Medo"}
const SIGLAS := {"agi": "AGI", "for": "FOR", "int": "INT", "pre": "PRE", "vig": "VIG"}

var agente: Agente
var usar_item: Callable
var filtro_elemento := ""   ## página de rituais: "" = todos

var pagina_agente: Control
var pagina_habilidades: Control
var pagina_rituais: Control


func mostrar(a: Agente, p_usar_item: Callable = Callable()) -> void:
	agente = a
	usar_item = p_usar_item
	var atual := current_tab
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if agente == null:
		return
	pagina_agente = _pagina("Agente", _montar_agente())
	pagina_habilidades = _pagina("Habilidades e inventário", _montar_habilidades())
	pagina_rituais = _pagina("Rituais", _montar_rituais())
	current_tab = clampi(atual, 0, get_tab_count() - 1)


## Só a página 1 (Agente), sem a pasta: a revisão do dossiê de criação usa (docs/26).
static func pagina_um(a: Agente) -> Control:
	var f := FichaAgente.new()
	f.agente = a
	var c := f._montar_agente()
	f.free()
	c.theme = Tema.tema_papel()
	return c


func _pagina(nome: String, conteudo: Control) -> Control:
	var papel := PanelContainer.new()
	papel.name = nome
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(22, 16)))
	papel.theme = Tema.tema_papel()
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	papel.add_child(rolagem)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolagem.add_child(conteudo)
	add_child(papel)
	return papel


# --- Peças no estilo da ficha oficial -------------------------------------------------

## Rótulo preto com texto claro em caixa alta (as "abas" da ficha oficial).
static func aba(texto: String, largura: float = 0.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa(Tema.TINTA, Tema.TINTA, 0, 2, Vector2(8, 2)))
	if largura > 0.0:
		p.custom_minimum_size = Vector2(largura, 0)
	var l := Label.new()
	l.text = texto.to_upper()
	l.add_theme_color_override("font_color", Tema.PAPEL)
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	var f := Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	p.add_child(l)
	return p


## Valor escrito à máquina sobre uma linha, como num formulário preenchido.
static func valor(texto: String, largura: float = 0.0, tamanho: int = Tema.FONTE_P + 1) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_color_override("font_color", Tema.TINTA)
	l.add_theme_font_size_override("font_size", tamanho)
	var m := Tema.fonte_maquina()
	if m != null:
		l.add_theme_font_override("font", m)
	var linha := StyleBoxFlat.new()
	linha.bg_color = Color(0, 0, 0, 0)
	linha.border_width_bottom = 1
	linha.border_color = Color(Tema.TINTA, 0.55)
	linha.content_margin_left = 6
	linha.content_margin_right = 6
	l.add_theme_stylebox_override("normal", linha)
	if largura > 0.0:
		l.custom_minimum_size = Vector2(largura, 0)
	l.clip_text = true
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return l


static func campo(rotulo: String, texto: String, largura: float = 160.0) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 0)
	h.add_child(aba(rotulo))
	var v := valor(texto, largura)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	return h


static func _texto(t: String, tamanho: int = Tema.FONTE_P, cor: Color = Tema.TINTA, maquina := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_color_override("font_color", cor)
	l.add_theme_font_size_override("font_size", tamanho)
	var f: Font = Tema.fonte_maquina() if maquina else Tema.fonte_titulo()
	if f != null:
		l.add_theme_font_override("font", f)
	return l


## Caixa de PV, PE ou SAN: sigla, "atuais / máximo" grande e o nome por extenso.
static func caixa_status(sigla: String, nome: String, atual: int, maximo: int, cor: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa(Color(Tema.PAPEL, 0.0), Tema.TINTA, 2, 3, Vector2(10, 6)))
	p.custom_minimum_size = Vector2(170, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)
	var cab := HBoxContainer.new()
	cab.add_child(_texto(sigla, Tema.FONTE_G, Tema.TINTA, false))
	var n := _texto(nome.to_upper(), Tema.FONTE_P, Color(Tema.TINTA, 0.75))
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cab.add_child(n)
	v.add_child(cab)
	var numeros := _texto("%d / %d" % [atual, maximo], Tema.FONTE_G + 4)
	v.add_child(numeros)
	var barra := ProgressBar.new()
	barra.max_value = maxi(1, maximo)
	barra.value = atual
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 8)
	barra.add_theme_stylebox_override("background", Tema.caixa(Color(Tema.TINTA, 0.08), Color(Tema.TINTA, 0.4), 1, 2, Vector2.ZERO))
	barra.add_theme_stylebox_override("fill", Tema.caixa(cor, cor.darkened(0.3), 1, 2, Vector2.ZERO))
	v.add_child(barra)
	return p


static func _grade(colunas: int, h_sep: int = 10) -> GridContainer:
	var g := GridContainer.new()
	g.columns = colunas
	g.add_theme_constant_override("h_separation", h_sep)
	g.add_theme_constant_override("v_separation", 2)
	return g


# --- Página 1: Agente -----------------------------------------------------------------

func _montar_agente() -> Control:
	var rs := agente.ruleset
	var raiz := HFlowContainer.new()
	raiz.add_theme_constant_override("h_separation", 26)
	raiz.add_theme_constant_override("v_separation", 18)
	var esq := VBoxContainer.new()
	esq.custom_minimum_size = Vector2(580, 0)
	esq.add_theme_constant_override("separation", 7)   # a página cabe sem rolar a 1280×720
	raiz.add_child(esq)
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	topo.add_child(campo("Personagem", agente.nome, 210))
	topo.add_child(campo("Patente", String(agente.patente().get("nome", "?")), 120))
	esq.add_child(topo)
	if agente.conceito.strip_edges() != "":
		esq.add_child(campo("Conceito", agente.conceito, 420))
	# Atributos no pentágono e a identidade ao lado
	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 14)
	esq.add_child(meio)
	var atrib := VBoxContainer.new()
	atrib.add_child(aba("Atributos"))
	var pent := PentagonoAtributos.new()
	pent.agente = agente
	atrib.add_child(pent)
	meio.add_child(atrib)
	var ident := VBoxContainer.new()
	ident.add_theme_constant_override("separation", 8)
	ident.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meio.add_child(ident)
	ident.add_child(campo("Origem", rs.origem(agente.origem_id).nome if agente.origem_id != "" else "—", 200))
	ident.add_child(campo("Classe", rs.classe(agente.classe_id).nome, 200))
	ident.add_child(campo("Trilha", rs.trilha(agente.classe_id, agente.trilha_id).get("nome", "—") if agente.trilha_id != "" else "—", 200))
	var nums := HBoxContainer.new()
	nums.add_theme_constant_override("separation", 8)
	nums.add_child(campo("NEX", "%d%%" % agente.nex, 46))
	nums.add_child(campo("PE/rodada", str(agente.limite_pe()), 30))
	nums.add_child(campo("Desl.", "%d m" % int(agente.deslocamento_m()), 46))
	ident.add_child(nums)
	# PV, PE e SAN
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 10)
	status.add_child(caixa_status("PV", "Pontos de vida", agente.pv, agente.pv_maximo, Tema.SANGUE))
	status.add_child(caixa_status("PE", "Pontos de esforço", agente.pe, agente.pe_maximo, Tema.ELEMENTO.energia.darkened(0.3)))
	status.add_child(caixa_status("SAN", "Sanidade", agente.san, agente.san_maximo, Color("2f6f7a")))
	esq.add_child(status)
	# Defesa com a conta da ficha (10 + AGI + equipamento + outros)
	var base := rs.defesa_base(agente.atributos)
	var equip := int(agente.protecao().get("defesa", 0))
	var outros := agente.defesa() - base - equip
	var defesa := HBoxContainer.new()
	defesa.add_theme_constant_override("separation", 10)
	var escudo := PanelContainer.new()
	escudo.add_theme_stylebox_override("panel", Tema.caixa(Color(0, 0, 0, 0), Tema.TINTA, 2, 12, Vector2(12, 4)))
	var ve := VBoxContainer.new()
	escudo.add_child(ve)
	ve.add_child(_texto("DEFESA", Tema.FONTE_P, Tema.TINTA, false))
	ve.add_child(_texto(str(agente.defesa()), Tema.FONTE_G + 8))
	defesa.add_child(escudo)
	var conta := VBoxContainer.new()
	conta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	conta.add_child(_texto("= %d (10 + %d AGI) + %d equip. + %d outros" % [base, base - 10, equip, outros], Tema.FONTE_P, Color(Tema.TINTA, 0.85)))
	conta.add_child(campo("Proteção", String(agente.protecao().get("nome", "nenhuma")), 200))
	conta.add_child(campo("Resistências", _resistencias(), 200))
	defesa.add_child(conta)
	esq.add_child(defesa)
	# Ataques
	esq.add_child(aba("Ataques"))
	esq.add_child(grade_ataques(agente))
	esq.add_child(_texto("✦ arma empunhada", Tema.FONTE_P, Color(Tema.TINTA, 0.75)))
	raiz.add_child(_tabela_pericias())
	return raiz


## A tabela de ataques da página 1 (também usada na criação, docs/30).
static func grade_ataques(a: Agente) -> GridContainer:
	var g := _grade(4, 14)
	for cab in ["ATAQUE", "TESTE", "DANO", "CRÍTICO / ALCANCE / ESPECIAL"]:
		g.add_child(_texto(cab, Tema.FONTE_P, Color(Tema.TINTA, 0.75), false))
	for arma in armas_de(a):
		var per := String(arma.get("pericia", "luta"))
		var dados := a.dados_da_pericia(per)
		var dano := String(arma.get("dano", "—"))
		if arma.get("soma_forca", false) and a.atributo("for") != 0:
			dano += "%+d" % a.atributo("for")
		var especial := PackedStringArray(["%d/x%d" % [int(arma.get("margem", 20)), int(arma.get("multiplicador", 2))]])
		especial.append("corpo a corpo" if String(arma.get("ataque", "corpo_a_corpo")) == "corpo_a_corpo" else String(arma.get("alcance", "curto")))
		if arma.has("tipo_dano"):
			especial.append(String(arma.tipo_dano))
		g.add_child(_texto(String(arma.get("nome", "?")) + ("  ✦" if String(arma.get("id", "")) == a.arma_id else "")))
		g.add_child(_texto(LinhaTeste.dados(dados, a.bonus_pericia(per))))
		g.add_child(_texto(dano))
		g.add_child(_texto(" · ".join(especial)))
	return g


static func armas_de(a: Agente) -> Array:
	var lista: Array = []
	for item_id in a.equipamento:
		var e := a.ruleset.equipamento(item_id)
		if e.get("tipo", "") == "arma" and not lista.any(func(x): return x.get("id", "") == item_id):
			lista.append(e)
	if lista.is_empty():
		lista.append(a.ruleset.arma("desarmado"))
	return lista


func _resistencias() -> String:
	var partes := PackedStringArray()
	for tipo in ["balistico", "corte", "impacto", "perfuracao", "fogo", "eletricidade", "frio", "quimico", "mental",
			"conhecimento", "energia", "morte", "sangue", "medo"]:
		var r := agente.resistencia(tipo)
		if r > 0:
			partes.append("%s %d" % [tipo, r])
	return ", ".join(partes) if not partes.is_empty() else "—"


## Todas as perícias da ficha oficial, com dados, bônus total, treino e outros.
func _tabela_pericias() -> Control:
	var rs := agente.ruleset
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(440, 0)
	v.add_theme_constant_override("separation", 4)
	v.add_child(aba("Perícias"))
	var g := _grade(5, 12)
	for cab in ["PERÍCIA", "DADOS", "BÔNUS", "TREINO", "OUTROS"]:
		g.add_child(_texto(cab, Tema.FONTE_P, Color(Tema.TINTA, 0.75), false))
	for p in rs.dados.pericias.pericias:
		var id := String(p.id)
		var grau := agente.grau(id)
		var treino := rs.bonus_grau(grau)
		var total := agente.bonus_pericia(id)
		var treinado := grau != "destreinado"
		var cor := Tema.TINTA if treinado else Color(Tema.TINTA, 0.75)
		var nome := String(p.nome) + ("*" if p.get("somente_treinada", false) else "") + ("†" if p.get("carga", false) else "")
		var n := _texto(nome, Tema.FONTE_P, cor)
		if treinado:
			n.add_theme_color_override("font_outline_color", Tema.TINTA)
			n.add_theme_constant_override("outline_size", 1)   # "negrito" de máquina de escrever
		g.add_child(n)
		g.add_child(_texto("%d %s" % [agente.dados_da_pericia(id), SIGLAS.get(rs.atributo_da_pericia(id), "?")], Tema.FONTE_P, cor))
		g.add_child(_texto("%+d" % total, Tema.FONTE_P, cor))
		g.add_child(_texto("%+d" % treino if treinado else "—", Tema.FONTE_P, cor))
		g.add_child(_texto("%+d" % (total - treino) if total != treino else "—", Tema.FONTE_P, cor))
	v.add_child(g)
	v.add_child(_texto("* somente treinada   † penalidade de carga", Tema.FONTE_P, Color(Tema.TINTA, 0.75)))
	return v


# --- Página 2: Habilidades e inventário ------------------------------------------------

func _montar_habilidades() -> Control:
	var rs := agente.ruleset
	var raiz := HFlowContainer.new()
	raiz.add_theme_constant_override("h_separation", 26)
	raiz.add_theme_constant_override("v_separation", 18)
	var esq := VBoxContainer.new()
	esq.custom_minimum_size = Vector2(520, 0)
	esq.add_theme_constant_override("separation", 10)
	raiz.add_child(esq)
	esq.add_child(aba("Habilidades"))
	var habs := RichTextLabel.new()
	habs.bbcode_enabled = true
	habs.fit_content = true
	habs.add_theme_color_override("default_color", Tema.TINTA)
	var linhas := PackedStringArray()
	for h in agente.habilidades():
		var nome := String(h.get("nome", "?"))
		var desc := String(h.get("descricao", ""))
		var cab := ("[b]%s[/b]" % nome) if h.get("implementado", false) else DossieAgente._sem_efeito(nome)
		linhas.append(cab + ("" if desc == "" else " — " + desc))
	habs.text = "\n".join(linhas) if not linhas.is_empty() else "Nenhuma habilidade."
	esq.add_child(habs)
	esq.add_child(aba("Proficiências"))
	var prof := GridContainer.new()
	prof.columns = 4
	prof.add_theme_constant_override("h_separation", 14)
	for par in [["Armas", ""], ["simples", "armas_simples"], ["táticas", "armas_taticas"], ["pesadas", "armas_pesadas"],
			["Proteções", ""], ["leves", "protecoes_leves"], ["pesadas", "protecoes_pesadas"], ["", ""]]:
		if par[1] == "":
			prof.add_child(_texto(par[0], Tema.FONTE_P, Tema.TINTA, false))
		else:
			prof.add_child(_texto("%s %s" % ["☑" if agente.tem_proficiencia(par[1]) else "☐", par[0]]))
	esq.add_child(prof)
	var cab_desc := HBoxContainer.new()
	cab_desc.add_theme_constant_override("separation", 8)
	var aba_desc := aba("Descrição")
	aba_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab_desc.add_child(aba_desc)
	if editavel:
		var editar := Button.new()
		editar.text = "Editar descrição"
		editar.theme_type_variation = "BotaoPapel"
		editar.pressed.connect(func():
			EditorDescricao.abrir(self, agente, func():
				descricao_editada.emit()
				mostrar(agente, usar_item)))
		cab_desc.add_child(editar)
	esq.add_child(cab_desc)
	var desc := HBoxContainer.new()
	desc.add_theme_constant_override("separation", 14)
	var foto := FotoAgente.new()
	foto.mostrar(agente.classe_id, agente.aparencia, agente.tom)
	foto.legenda = agente.nome
	desc.add_child(foto)
	var texto := VBoxContainer.new()
	texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var origem := rs.origem(agente.origem_id) if agente.origem_id != "" else {}
	var aparencia := Label.new()
	aparencia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aparencia.add_theme_color_override("font_color", Tema.TINTA)
	var modelo := Pecas.modelo_do_agente(agente.classe_id, agente.aparencia)
	var quem := PackedStringArray()
	if agente.genero.strip_edges() != "":
		quem.append(agente.genero)
	if agente.idade_anos > 0:
		quem.append("%d anos" % agente.idade_anos)
	var cabeca := ", ".join(quem)
	if cabeca != "":
		cabeca = cabeca.left(1).to_upper() + cabeca.substr(1) + ".\n"   # só a primeira letra ("31 anos", não "31 Anos")
	aparencia.text = "%sAparência: %s\nOrigem: %s. %s" % [cabeca,
		agente.aparencia_texto if agente.aparencia_texto.strip_edges() != "" else "%s, roupa em tom %s." % [String(Pecas.APARENCIAS.get(modelo, modelo)).to_lower(),
			String(Pecas.TONS[clampi(agente.tom, 0, Pecas.TONS.size() - 1)][0]).to_lower()],
		origem.get("nome", "—"), origem.get("poder", {}).get("descricao", "")]
	texto.add_child(aparencia)
	# Personalidade, histórico e objetivo (docs/26), quando o jogador escreveu
	for par in [["Personalidade", agente.personalidade], ["Histórico", agente.historico], ["Objetivo", agente.objetivo]]:
		if String(par[1]).strip_edges() == "":
			continue
		texto.add_child(aba(par[0]))
		var l := Label.new()
		l.text = String(par[1])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(300, 0)
		l.add_theme_color_override("font_color", Tema.TINTA)
		var m := Tema.fonte_maquina()
		if m != null:
			l.add_theme_font_override("font", m)
		texto.add_child(l)
	desc.add_child(texto)
	esq.add_child(desc)

	var dir := VBoxContainer.new()
	dir.custom_minimum_size = Vector2(460, 0)
	dir.add_theme_constant_override("separation", 10)
	raiz.add_child(dir)
	var pat := agente.patente()
	var l1 := HBoxContainer.new()
	l1.add_theme_constant_override("separation", 10)
	l1.add_child(campo("Pontos de prestígio", str(agente.pp), 50))
	l1.add_child(campo("Patente", String(pat.get("nome", "?")), 110))
	dir.add_child(l1)
	var l2 := HBoxContainer.new()
	l2.add_theme_constant_override("separation", 6)
	l2.add_child(aba("Limite de itens"))
	var lim: Dictionary = pat.get("itens_por_categoria", {})
	for cat in ["1", "2", "3", "4"]:
		l2.add_child(valor("%s: %d" % [["I", "II", "III", "IV"][int(cat) - 1], int(lim.get(cat, 0))], 54))
	dir.add_child(l2)
	var l3 := HBoxContainer.new()
	l3.add_theme_constant_override("separation", 10)
	l3.add_child(campo("Crédito", String(pat.get("credito", "—")), 80))
	l3.add_child(campo("Carga", "%d / %d%s" % [agente.espacos_usados(), agente.capacidade_carga(), " !" if agente.sobrecarregado() else ""], 80))
	dir.add_child(l3)
	dir.add_child(aba("Inventário"))
	var g := _grade(4, 12)
	for cab in ["ITEM", "CATEGORIA", "ESPAÇOS", ""]:
		g.add_child(_texto(cab, Tema.FONTE_P, Color(Tema.TINTA, 0.75), false))
	var contagem := {}
	for item_id in agente.equipamento:
		contagem[item_id] = int(contagem.get(item_id, 0)) + 1
	for item_id in contagem:
		var info := rs.equipamento(item_id)
		var nome := _texto("%s%s" % [info.get("nome", item_id), " ×%d" % contagem[item_id] if contagem[item_id] > 1 else ""])
		nome.tooltip_text = IconeItem.efeito(info, rs)
		nome.mouse_filter = Control.MOUSE_FILTER_PASS
		if info.has("maldicoes"):
			nome.add_theme_color_override("font_color", Tema.SANGUE)
		g.add_child(nome)
		g.add_child(_texto(["0", "I", "II", "III", "IV", "V"][mini(5, int(info.get("categoria", 0)))]))
		g.add_child(_texto(str(int(info.get("espacos", 1)))))
		if usar_item.is_valid() and info.get("uso", {}).has("cura"):
			var usar := Button.new()
			usar.text = "Usar"
			usar.theme_type_variation = "BotaoPapel"
			usar.pressed.connect(func():
				usar_item.call(item_id)
				item_usado.emit(item_id))
			g.add_child(usar)
		else:
			g.add_child(Control.new())
	if contagem.is_empty():
		g.add_child(_texto("Nada no inventário."))
	dir.add_child(g)
	if not agente.rituais.is_empty():
		dir.add_child(aba("Rituais"))
		dir.add_child(_texto("%d conhecido%s — veja a página Rituais." % [agente.rituais.size(), "" if agente.rituais.size() == 1 else "s"]))
	return raiz


# --- Página 3: Rituais (otimizada) -----------------------------------------------------

func _montar_rituais() -> Control:
	var rs := agente.ruleset
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	var cab := HFlowContainer.new()
	cab.add_theme_constant_override("h_separation", 12)
	cab.add_theme_constant_override("v_separation", 6)
	cab.add_child(_texto("FICHA DE RITUAIS", Tema.FONTE_G + 6, Tema.TINTA, false))
	cab.add_child(campo("DT", str(agente.dt_habilidade("pre")), 34))
	cab.add_child(campo("PE/rodada", str(agente.limite_pe_rituais()), 30))
	cab.add_child(campo("PE atuais", "%d / %d" % [agente.pe, agente.pe_maximo], 60))
	cab.add_child(campo("Círculo máx.", "%dº" % agente.circulo_maximo(), 34))
	var custos := PackedStringArray()
	for c in [1, 2, 3, 4]:
		custos.append("%dº %d PE" % [c, rs.custo_base_ritual(c)])
	cab.add_child(campo("Custo", " · ".join(custos), 280))
	v.add_child(cab)
	if agente.rituais.is_empty():
		v.add_child(_texto("Nenhum ritual conhecido. Ocultistas começam com três; outras classes aprendem rituais por poderes."))
		return v
	# Filtro por elemento (só os elementos que o agente conhece)
	var conhecidos: Array = []
	for rid in agente.rituais:
		var el := String(rs.ritual(rid).get("elemento", ""))
		if not el in conhecidos:
			conhecidos.append(el)
	if conhecidos.size() > 1:
		var filtros := HBoxContainer.new()
		filtros.add_theme_constant_override("separation", 6)
		for el in [""] + conhecidos:
			var b := Button.new()
			b.theme_type_variation = "BotaoPapel"
			b.toggle_mode = true
			b.button_pressed = filtro_elemento == el
			b.text = "Todos" if el == "" else NOMES_ELEMENTO.get(el, el)
			b.pressed.connect(func():
				filtro_elemento = el
				mostrar(agente, usar_item))
			filtros.add_child(b)
		v.add_child(filtros)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 14)
	for rid in agente.rituais:
		var r := rs.ritual(rid)
		if filtro_elemento != "" and String(r.get("elemento", "")) != filtro_elemento:
			continue
		grade.add_child(cartao_ritual(rid))
	v.add_child(grade)
	return v


## Um ritual já preenchido: elemento em cor, círculo, custo e DT pelas regras, execução,
## alcance, alvo, duração, resistência, efeito e formas. Público para os testes.
func cartao_ritual(rid: String) -> Control:
	var rs := agente.ruleset
	var r := rs.ritual(rid)
	var el := String(r.get("elemento", ""))
	var cor: Color = Tema.ELEMENTO.get(el, Tema.TINTA)
	var p := PanelContainer.new()
	var estilo := Tema.caixa(Color(Tema.PAPEL_SOMBRA, 0.25), Color(Tema.TINTA, 0.6), 1, 3, Vector2(12, 8))
	estilo.border_width_left = 6
	estilo.border_color = cor.darkened(0.25)
	p.add_theme_stylebox_override("panel", estilo)
	p.custom_minimum_size = Vector2(500, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var topo := HBoxContainer.new()
	var nome := _texto(String(r.get("nome", rid)).to_upper(), Tema.FONTE_M, Tema.TINTA, false)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	topo.add_child(nome)
	var custo := agente.custo_ritual(rid)
	topo.add_child(aba("%dº · %d PE" % [int(r.get("circulo", 1)), custo]))
	v.add_child(topo)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 12)
	linha.add_child(_texto("● " + NOMES_ELEMENTO.get(el, el), Tema.FONTE_P, cor.darkened(0.35)))
	linha.add_child(_texto("DT %d" % agente.dt_ritual(rid)))
	if String(r.get("resistencia", "")) != "":
		linha.add_child(_texto("Resistência: %s" % r.resistencia))
	if agente.pe < custo:
		linha.add_child(_texto("PE insuficiente agora", Tema.FONTE_P, Tema.cor_falha(true)))
	v.add_child(linha)
	var g := _grade(4, 8)
	for par in [["Execução", "execucao"], ["Alcance", "alcance"], ["Alvo", "alvo"], ["Duração", "duracao"]]:
		g.add_child(_texto(par[0].to_upper(), Tema.FONTE_P, Color(Tema.TINTA, 0.75), false))
		var val := _texto(String(r.get(par[1], "—")))
		val.custom_minimum_size = Vector2(170, 0)
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		g.add_child(val)
	v.add_child(g)
	var efeito := Label.new()
	efeito.text = String(r.get("descricao", ""))
	efeito.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	efeito.add_theme_color_override("font_color", Tema.TINTA)
	v.add_child(efeito)
	var formas: Dictionary = r.get("formas", {})
	if not formas.is_empty():
		var fs := PackedStringArray()
		for f in formas:
			fs.append("%s: %d PE (%dº)" % [String(f).capitalize(), agente.custo_ritual(rid, f), int(formas[f].get("circulo", r.get("circulo", 1)))])
		v.add_child(_texto("Formas — " + " · ".join(fs), Tema.FONTE_P, Color(Tema.TINTA, 0.85)))
	if not r.get("implementado", false):
		var aviso := _texto("ainda sem efeito nas regras deste jogo", Tema.FONTE_P, Color(Tema.TINTA, 0.75))
		v.add_child(aviso)
	return p
