class_name EscolhaNex
extends VBoxContainer
## Escolha de NEX por seleção (docs/47): cada opção permitida pelas regras é um botão, com a
## descrição embaixo; quando a opção pede uma escolha a mais, aparece uma segunda lista, só
## com o que vale (perícias que podem subir, poderes paranormais disponíveis e o elemento ou
## ritual de cada um, elemento do Especialista, ritual do Ritual Predileto). Nada se digita.
## As listas vêm de Progressao, que já filtra por classe, NEX e pré-requisitos.
## Usada na Base e no papel da sala de Transcender.
##   EscolhaNex.criar(agente, pendencia, func(tipo, escolha, extra): ...)

const ATRIBUTOS := {"agi": "Agilidade", "for": "Força", "int": "Intelecto", "pre": "Presença", "vig": "Vigor"}
const ELEMENTOS_ESPECIALISTA := ["conhecimento", "energia", "morte", "sangue", "medo"]
const ELEMENTOS := ["conhecimento", "energia", "morte", "sangue"]

var agente: Agente
var pend: Dictionary
var rs: Ruleset
var ao_confirmar: Callable
var papel := false            ## no papel da sala (tema claro) ou na Base

var escolha = null            ## a opção principal (String) ou, no grau, a lista de perícias
var extra: Array = []         ## a escolha a mais (perícias, ou [poder paranormal, escolha dele])
var _botoes: Dictionary = {}  ## opção -> Button
var _descricao: Label
var _caixa_extra: VBoxContainer
var _confirmar: Button


static func criar(a: Agente, p: Dictionary, confirmar: Callable, no_papel: bool = false) -> EscolhaNex:
	var e := EscolhaNex.new()
	e.agente = a
	e.pend = p
	e.rs = a.ruleset
	e.ao_confirmar = confirmar
	e.papel = no_papel
	e._montar()
	return e


func _montar() -> void:
	add_theme_constant_override("separation", Tema.ESPACO_M)
	if pend.tipo == "grau":
		escolha = []
		_nota("Escolha %d perícias (%d/%d)." % [int(pend.quantidade), 0, int(pend.quantidade)])
	var rolagem := ScrollContainer.new()
	rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rolagem.custom_minimum_size = Vector2(0, mini(260, 38 * int(ceil(pend.opcoes.size() / 2.0)) + 4))
	add_child(rolagem)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grade.add_theme_constant_override("h_separation", Tema.ESPACO_M)
	grade.add_theme_constant_override("v_separation", Tema.ESPACO_P)
	rolagem.add_child(grade)
	for o in pend.opcoes:
		var b := _botao(nome_de(o), func(): _escolher(o))
		b.tooltip_text = descricao_de(o)
		grade.add_child(b)
		_botoes[o] = b
	_descricao = Label.new()
	_descricao.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descricao.custom_minimum_size = Vector2(320, 0)
	_descricao.add_theme_font_size_override("font_size", Tema.FONTE_P)
	add_child(_descricao)
	_caixa_extra = VBoxContainer.new()
	_caixa_extra.add_theme_constant_override("separation", Tema.ESPACO_P)
	add_child(_caixa_extra)
	_confirmar = Button.new()
	_confirmar.text = "Confirmar"
	_confirmar.theme_type_variation = "BotaoPrincipal"
	_confirmar.disabled = true
	_confirmar.pressed.connect(func(): ao_confirmar.call(pend.tipo, escolha, extra))
	add_child(_confirmar)


func _botao(texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.toggle_mode = true
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if papel:
		b.theme_type_variation = "BotaoPapel"
	b.pressed.connect(acao)
	return b


func _nota(texto: String) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", Tema.FONTE_P)
	add_child(l)
	return l


# --- Nomes e descrições --------------------------------------------------------------

func nome_de(o) -> String:
	var falta := ""
	match String(pend.tipo):
		"trilha": return String(rs.trilha(agente.classe_id, o).get("nome", o))
		"poder":
			var p := rs.poder(agente.classe_id, o)
			falta = "" if p.get("implementado", false) else " *"
			return String(p.get("nome", o)) + falta
		"aumento": return ATRIBUTOS.get(String(o), String(o).to_upper())
		"ritual":
			var r := rs.ritual(o)
			return "%s (%dº, %s)%s" % [r.nome, int(r.circulo), r.elemento, "" if r.get("implementado", false) else " *"]
		"poder_paranormal":
			var pp := rs.poder_paranormal(o)
			return "%s (%s)%s" % [pp.nome, pp.elemento, "" if pp.get("implementado", false) else " *"]
		"afinidade": return String(o).capitalize()
		"versatilidade":
			if String(o) == "poder":
				return "Mais um poder de classe"
			return "Trilha: %s" % rs.trilha(agente.classe_id, String(o).trim_prefix("trilha:")).get("nome", o)
		"grau": return String(rs.pericia(o).get("nome", o))
	return String(o)


func descricao_de(o) -> String:
	var d := ""
	match String(pend.tipo):
		"trilha": d = String(rs.trilha(agente.classe_id, o).get("descricao", ""))
		"poder": d = String(rs.poder(agente.classe_id, o).get("descricao", ""))
		"ritual": d = String(rs.ritual(o).get("descricao", ""))
		"poder_paranormal": d = String(rs.poder_paranormal(o).get("descricao", ""))
		"afinidade": d = "A afinidade se firma no próximo Transcender (p.114)."
		"aumento": d = "+1 em %s (atual %d)." % [ATRIBUTOS.get(String(o), o), agente.atributo(String(o))]
	if String(pend.tipo) in ["poder", "ritual", "poder_paranormal"] and nome_de(o).ends_with(" *"):
		d += " (* O efeito ainda não está no jogo.)"
	return d


# --- Escolhas ---------------------------------------------------------------------------

func _escolher(o) -> void:
	if pend.tipo == "grau":
		var lista: Array = escolha
		if o in lista:
			lista.erase(o)
		elif lista.size() < int(pend.quantidade):
			lista.append(o)
		for k in _botoes:
			_botoes[k].set_pressed_no_signal(k in lista)
		(get_child(0) as Label).text = "Escolha %d perícias (%d/%d)." % [int(pend.quantidade), lista.size(), int(pend.quantidade)]
		_confirmar.disabled = lista.size() != int(pend.quantidade)
		return
	escolha = o
	extra = []
	for k in _botoes:
		_botoes[k].set_pressed_no_signal(k == o)
	_descricao.text = descricao_de(o)
	_montar_extra()
	_atualizar_confirmar()


## A escolha a mais, quando a opção pede (docs/47).
func _montar_extra() -> void:
	for f in _caixa_extra.get_children():
		f.queue_free()
	match pedido_extra():
		"pericias":
			_lista_extra("Treinamento em Perícia: escolha 2 perícias", pericias_para_treinamento(), 2, 0)
		"poder_paranormal":
			_lista_extra("Transcender: escolha o poder paranormal", Progressao.poderes_paranormais_possiveis(agente), 1, 0)
		"elemento_especialista":
			_lista_extra("Especialista em Elemento: escolha o elemento", ELEMENTOS_ESPECIALISTA, 1, 0)
		"ritual_conhecido":
			_lista_extra("Ritual Predileto: um ritual que %s conhece" % agente.nome, agente.rituais, 1, 0)
		"escolha_do_paranormal":
			_extra_do_paranormal(String(escolha), 0)


## O que a opção escolhida pede a mais: "" (nada), "pericias", "poder_paranormal",
## "elemento_especialista", "ritual_conhecido" ou "escolha_do_paranormal".
func pedido_extra() -> String:
	match String(pend.tipo):
		"poder":
			match String(escolha):
				"treinamento_em_pericia": return "pericias"
				"transcender": return "poder_paranormal"
				"especialista_em_elemento": return "elemento_especialista"
				"ritual_predileto": return "ritual_conhecido"
		"poder_paranormal":
			if rs.poder_paranormal(escolha).has("escolha"):
				return "escolha_do_paranormal"
	return ""


## Perícias que o Treinamento em Perícia pode melhorar agora (a mesma conta de Progressao).
func pericias_para_treinamento() -> Array:
	var lista: Array = []
	for p in rs.dados.pericias.pericias:
		var copia := agente.pericias.duplicate()
		if CriacaoAgente._subir_grau(rs, copia, String(p.id), agente.nex, true) != "":
			lista.append(String(p.id))
	return lista


## Opções da escolha de um poder paranormal (Aprender Ritual, Resistir a Elemento, Expansão).
func opcoes_do_paranormal(pid: String) -> Array:
	match String(rs.poder_paranormal(pid).get("escolha", "")):
		"elemento":
			return ELEMENTOS.duplicate()
		"ritual":
			var max_c := 3 if agente.nex >= 75 else (2 if agente.nex >= 45 else 1)
			return rs.lista_rituais().filter(func(r): return int(r.circulo) <= max_c and not r.id in agente.rituais).map(func(r): return String(r.id))
		"poder_de_outra_classe":
			var lista: Array = []
			for cl in rs.dados.poderes_classe.poderes:
				if cl == agente.classe_id:
					continue
				for p in rs.dados.poderes_classe.poderes[cl]:
					if CriacaoAgente._checar_pre(p.get("pre", {}), agente, p.id).is_empty():
						lista.append("%s:%s" % [cl, p.id])
			return lista
	return []


func _nome_extra(o: String) -> String:
	if rs.tem_pericia(o):
		return String(rs.pericia(o).nome)
	if o in ELEMENTOS_ESPECIALISTA:
		return o.capitalize()
	if o.contains(":"):
		var partes := o.split(":")
		return "%s (%s)" % [rs.poder(partes[0], partes[1]).get("nome", partes[1]), partes[0].capitalize()]
	if not rs.ritual(o).is_empty():
		return "%s (%dº)" % [rs.ritual(o).nome, int(rs.ritual(o).circulo)]
	if not rs.poder_paranormal(o).is_empty():
		return String(rs.poder_paranormal(o).nome)
	return o


## Uma lista de botões para a escolha a mais, guardada em `extra` a partir de `inicio`.
func _lista_extra(titulo: String, opcoes: Array, quantos: int, inicio: int) -> void:
	var t := Label.new()
	t.text = titulo if not opcoes.is_empty() else titulo + ": nenhuma opção disponível agora."
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caixa_extra.add_child(t)
	var grade := GridContainer.new()
	grade.columns = 3
	grade.add_theme_constant_override("h_separation", Tema.ESPACO_P)
	_caixa_extra.add_child(grade)
	var botoes := {}
	for o in opcoes:
		var b := _botao(_nome_extra(String(o)), func():
			if quantos == 1:
				extra.resize(inicio)
				extra.append(String(o))
				for k in botoes:
					botoes[k].set_pressed_no_signal(k == o)
				if inicio == 0 and pedido_extra() == "poder_paranormal":
					_extra_do_paranormal(String(o), 1)   # o poder paranormal pode pedir a escolha dele
			else:
				var sel: Array = extra
				if String(o) in sel:
					sel.erase(String(o))
				elif sel.size() < quantos:
					sel.append(String(o))
				for k in botoes:
					botoes[k].set_pressed_no_signal(String(k) in sel)
			_atualizar_confirmar())
		if not rs.poder_paranormal(String(o)).is_empty():
			b.tooltip_text = String(rs.poder_paranormal(String(o)).get("descricao", ""))
		grade.add_child(b)
		botoes[o] = b


## Escolha do poder paranormal (elemento, ritual ou poder de outra classe), em `extra[inicio]`.
func _extra_do_paranormal(pid: String, inicio: int) -> void:
	# Tira a lista anterior desta escolha (troca de poder paranormal no Transcender)
	if inicio > 0:
		while _caixa_extra.get_child_count() > 2:
			var f := _caixa_extra.get_child(_caixa_extra.get_child_count() - 1)
			_caixa_extra.remove_child(f)
			f.queue_free()
	var tipo := String(rs.poder_paranormal(pid).get("escolha", ""))
	if tipo == "":
		return
	var titulos := {"elemento": "Escolha o elemento", "ritual": "Escolha o ritual", "poder_de_outra_classe": "Escolha o poder de outra classe"}
	_lista_extra("%s: %s" % [rs.poder_paranormal(pid).nome, titulos.get(tipo, "Escolha")], opcoes_do_paranormal(pid), 1, inicio)


## A escolha está completa?
func completa() -> bool:
	if pend.tipo == "grau":
		return (escolha as Array).size() == int(pend.quantidade)
	if escolha == null:
		return false
	match pedido_extra():
		"pericias":
			return extra.size() == 2
		"poder_paranormal":
			if extra.is_empty():
				return false
			return not rs.poder_paranormal(extra[0]).has("escolha") or extra.size() >= 2
		"elemento_especialista", "ritual_conhecido", "escolha_do_paranormal":
			return extra.size() == 1
	return true


func _atualizar_confirmar() -> void:
	_confirmar.disabled = not completa()
