class_name CriacaoDossie
extends CanvasLayer
## Criação de agente como um dossiê (docs/17, E2): identidade e origem, classe, atributos,
## perícias, rituais e a revisão, numa pasta de papel. A ficha é validada a cada mudança
## por CriacaoAgente; "Assinar e arquivar" só fica liberado sem erros. Ao lado das abas, a
## foto 3x4 presa com clipe (docs/19): aparência e tom da roupa, que valem para a miniatura.
##   CriacaoDossie.abrir(self, carreira, func(agente): ...)

signal criado(agente: Agente)

const CLASSES := ["combatente", "especialista", "ocultista"]
const ATRIBUTOS := ["agi", "for", "int", "pre", "vig"]
const NOMES_ATRIBUTOS := {"agi": "Agilidade", "for": "Força", "int": "Intelecto", "pre": "Presença", "vig": "Vigor"}

var carreira: Carreira
var rs: Ruleset
var ficha := {"nome": "", "origem": "", "classe": "combatente", "nex": 5,
	"atributos": {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1},
	"pericias_origem": [], "pericias_classe": [], "pericias_livres": [], "perito": [], "rituais": [],
	"aparencia": "", "tom": 0, "personalidade": "", "historico": "", "objetivo": ""}

var _abas: TabContainer
var _paginas: Dictionary = {}     ## nome -> VBoxContainer (reconstruída a cada mudança)
var _erros: Label
var _assinar: Button
var _nome: LineEdit
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
	_abas.custom_minimum_size = Vector2(900, 0)   # a pasta não muda de largura entre as abas
	meio.add_child(_abas)
	meio.add_child(_coluna_foto())
	for nome in ["Identidade", "Classe", "Atributos", "Perícias", "Rituais", "Descrição", "Revisão"]:
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
	for filho in v.get_children():
		if filho == _nome or filho in _campos_descricao.values():
			v.remove_child(filho)   # campos de texto são reaproveitados (mantêm o cursor)
			continue
		filho.visible = false
		filho.queue_free()
	_atualizar_foto()
	match pagina:
		"Identidade": _pagina_identidade(v)
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

func _pagina_identidade(v: VBoxContainer) -> void:
	_titulo(v, "Identidade")
	if _nome == null:
		_nome = LineEdit.new()
		_nome.placeholder_text = "Nome do agente"
		_nome.custom_minimum_size = Vector2(360, 0)
		_nome.max_length = 24
		_nome.text_changed.connect(func(t):
			ficha.nome = t
			_foto.legenda = String(t).strip_edges()
			var res := _validar()
			_assinar.disabled = String(t).strip_edges() == "" or not res.erros.is_empty())
	v.add_child(_nome)
	_titulo(v, "Origem")
	_nota(v, "O que o agente fazia antes da Ordem. Dá duas perícias treinadas e um poder.")
	var g := _grade(v, 4)
	for o in rs.dados.origens.origens:
		var pers := PackedStringArray((o.get("pericias", []) as Array).map(func(p): return _nome_pericia(p)))
		var dica := "%s\nPerícias: %s\nPoder: %s — %s" % [o.nome, ", ".join(pers) if not pers.is_empty() else "escolha %d" % int(o.get("pericias_escolha", 0)),
			o.get("poder", {}).get("nome", "—"), o.get("poder", {}).get("descricao", "")]
		_opcao(g, o.nome, ficha.origem == o.id, func():
			ficha.origem = o.id
			ficha.pericias_origem = [], dica)
	var atual := rs.origem(ficha.origem)
	_nota(v, "%s · %s" % [atual.nome, atual.get("poder", {}).get("descricao", "")])


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
			ficha.rituais = [])
		b.custom_minimum_size = Vector2(0, 58)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


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
	_nota(v, "Escolha 3 rituais de 1º círculo. Os marcados com * ainda não têm efeito no jogo.")
	var g := _grade(v, 3)
	for r in rs.dados.rituais.rituais:
		if int(r.circulo) != 1:
			continue
		var rid: String = r.id
		var nome := "%s (%s)%s" % [r.nome, r.elemento, "" if r.get("implementado", false) else " *"]
		_opcao(g, nome, rid in ficha.rituais, func(): _alternar(ficha.rituais, rid, 3), String(r.get("descricao", "")))


## Descrição (docs/26): o quadro "Descrição" da ficha oficial. A aparência fica na foto ao
## lado; personalidade, histórico e objetivo são texto livre e opcional.
const CAMPOS_DESCRICAO := [
	["personalidade", "Personalidade", "Como o agente age sob pressão? Ex.: calado e observador; faz piada quando está com medo.", false],
	["historico", "Histórico", "De onde veio, o que fazia antes da Ordem e como topou com o paranormal pela primeira vez.", true],
	["objetivo", "Objetivo", "O que o mantém na Ordem? Ex.: descobrir o que aconteceu com a irmã.", false],
]


func _pagina_descricao(v: VBoxContainer) -> void:
	_titulo(v, "Descrição")
	_nota(v, "Opcional. Aparece na ficha do agente (página Habilidades e inventário). A aparência é a da foto, ao lado.")
	for c in CAMPOS_DESCRICAO:
		var id: String = c[0]
		var rotulo := Label.new()
		rotulo.text = String(c[1]).to_upper()
		rotulo.add_theme_color_override("font_color", Tema.TINTA)
		var f := Tema.fonte_titulo()
		if f != null:
			rotulo.add_theme_font_override("font", f)
		v.add_child(rotulo)
		if not _campos_descricao.has(id):
			var limite: int = Carreira.LIMITE_DESCRICAO[id]
			var campo: Control
			if c[3]:
				var te := TextEdit.new()
				te.custom_minimum_size = Vector2(0, 130)
				te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				te.placeholder_text = c[2]
				te.text_changed.connect(func():
					if te.text.length() > limite:
						te.text = te.text.left(limite)
						te.set_caret_column(te.get_line(te.get_line_count() - 1).length(), false)
						te.set_caret_line(te.get_line_count() - 1)
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


## Revisão (docs/26): a página 1 da ficha nova, como o agente vai ficar — já com o
## equipamento inicial da classe, para os ataques e a Defesa saírem certos.
func _pagina_revisao(v: VBoxContainer, res: Dictionary, erros: Array) -> void:
	_titulo(v, "Revisão da ficha")
	if res.agente != null:
		var a: Agente = res.agente
		a.nome = String(ficha.nome).strip_edges() if String(ficha.nome).strip_edges() != "" else "(sem nome)"
		a.aparencia = String(ficha.aparencia)
		a.tom = int(ficha.tom)
		var kit := carreira.kit_da_classe(ficha.classe)
		for item in kit.get("equipamento", []):
			a.equipamento.append(item)
		a.arma_id = String(kit.get("arma", ""))
		_revisao = FichaAgente.pagina_um(a)
		v.add_child(_revisao)
		_nota(v, "Equipamento inicial: %s." % ", ".join(PackedStringArray((kit.equipamento as Array).map(func(i): return rs.equipamento(i).get("nome", i)))))
		var desc := PackedStringArray()
		for c in CAMPOS_DESCRICAO:
			if String(ficha.get(c[0], "")).strip_edges() != "":
				desc.append("%s: %s" % [c[1], String(ficha[c[0]]).strip_edges()])
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
