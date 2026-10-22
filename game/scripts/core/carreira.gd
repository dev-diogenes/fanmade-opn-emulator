class_name Carreira
extends RefCounted
## Carreira na Ordem: roster persistente de agentes, opções da run, missões e o
## relatório ao voltar (PP, NEX, patente, mortes). Salva tudo em JSON.

const ARQUIVO := "user://carreira.json"
## Onde o jogo salva. Nos testes, o Jogo troca por um arquivo de teste (docs/31): a suíte não
## pode sobrescrever o save de verdade.
static var arquivo_padrao := ARQUIVO
const VERSAO := 1
const MAX_ROSTER := 8
const MAX_GRUPO := 4

var ruleset: Ruleset
var roster: Array[Agente] = []
var memorial: Array[Dictionary] = []   ## [{"nome", "causa", "missao"}]
## modo_morte: "normal" (Reforços da Ordem) ou "hardcore"; regras opcionais da run
var opcoes: Dictionary = {"modo_morte": "normal", "lesoes": true, "inspiracao_resoluta": true}
var missao: Missao
var missoes_concluidas := 0
var ultimo_relatorio: Dictionary = {}
## Co-op local (ADR 0004): jogadores e dono de cada agente
var controles: ControleLocal = ControleLocal.padrao()
## Campanhas (Fase 7, ADR 0006): progresso por id,
## {etapa, concluida, vezes, marcas: [id], historico: [{etapa, vitoria}]}
var campanhas: Dictionary = {}
## Recrutas liberados pelas campanhas (fichas no formato de recrutas.json)
var recrutas_extras: Array = []
var _proximo_id := 1


static func nova(ruleset_: Ruleset = null) -> Carreira:
	var c := Carreira.new()
	c.ruleset = ruleset_ if ruleset_ != null else RulesetOp2022.carregar_padrao()
	var recrutas: Array = DadosJogo.ler("recrutas").recrutas
	for i in mini(3, recrutas.size()):
		c.recrutar(recrutas[i].nome)
	return c


# --- Roster ------------------------------------------------------------------

func recrutas_disponiveis() -> Array:
	var nomes := roster.map(func(a): return a.nome)
	var caidos := memorial.map(func(m): return m.nome)
	return (DadosJogo.ler("recrutas").recrutas + recrutas_extras).filter(func(r): return not r.nome in nomes and not r.nome in caidos)


func recrutar(nome: String) -> Agente:
	if roster.size() >= MAX_ROSTER or missao != null:
		return null
	for r in recrutas_disponiveis():
		if r.nome == nome:
			var res := CriacaoAgente.criar(ruleset, r)
			if res.agente == null:
				push_error("Recruta inválido %s: %s" % [nome, res.erros])
				return null
			var a: Agente = res.agente
			_copiar_descricao(a, r)
			a.id = "ag%d" % _proximo_id
			_proximo_id += 1
			for item in r.get("equipamento", []):
				a.equipamento.append(item)
			a.arma_id = r.get("arma", "")
			roster.append(a)
			return a
	return null


## Agente criado pelo jogador (docs/17, E2). Valida com CriacaoAgente e dá o kit inicial
## da classe (o primeiro recruta da mesma classe em recrutas.json). Retorna {agente, erros}.
## Tamanho máximo dos textos da descrição (caracteres).
const LIMITE_DESCRICAO := {"personalidade": 140, "historico": 600, "objetivo": 140,
	"conceito": 120, "genero": 40, "aparencia_texto": 200}


func recrutar_ficha(ficha: Dictionary) -> Dictionary:
	if roster.size() >= MAX_ROSTER:
		return {"agente": null, "erros": ["O arquivo já tem %d agentes (o máximo)." % MAX_ROSTER]}
	if missao != null:
		return {"agente": null, "erros": ["Há uma missão em andamento."]}
	var nome := String(ficha.get("nome", "")).strip_edges()
	if nome == "":
		return {"agente": null, "erros": ["Dê um nome ao agente."]}
	if roster.any(func(x): return x.nome == nome) or memorial.any(func(x): return x.nome == nome):
		return {"agente": null, "erros": ["Já existe um agente chamado %s." % nome]}
	var res := CriacaoAgente.criar(ruleset, ficha)
	if res.agente == null:
		return res
	var a: Agente = res.agente
	a.aparencia = String(ficha.get("aparencia", ""))   # a foto do dossiê (docs/19)
	a.tom = int(ficha.get("tom", 0))
	_copiar_descricao(a, ficha)
	a.id = "ag%d" % _proximo_id
	_proximo_id += 1
	var kit: Dictionary = kit_da_classe(String(ficha.get("classe", "")))
	for item in kit.get("equipamento", []):
		a.equipamento.append(item)
	a.arma_id = kit.get("arma", "")
	roster.append(a)
	return {"agente": a, "erros": [] as Array[String]}


## Descrição (docs/26): texto livre, aparado para caber na ficha. Vale para a criação e
## para os recrutas prontos, que trazem a deles em recrutas.json (docs/32).
static func _copiar_descricao(a: Agente, ficha: Dictionary) -> void:
	a.personalidade = String(ficha.get("personalidade", "")).strip_edges().left(LIMITE_DESCRICAO.personalidade)
	a.historico = String(ficha.get("historico", "")).strip_edges().left(LIMITE_DESCRICAO.historico)
	a.objetivo = String(ficha.get("objetivo", "")).strip_edges().left(LIMITE_DESCRICAO.objetivo)
	a.conceito = String(ficha.get("conceito", "")).strip_edges().left(LIMITE_DESCRICAO.conceito)
	a.genero = String(ficha.get("genero", "")).strip_edges().left(LIMITE_DESCRICAO.genero)
	a.idade_anos = int(ficha.get("idade_anos", 0))
	a.aparencia_texto = String(ficha.get("aparencia_texto", "")).strip_edges().left(LIMITE_DESCRICAO.aparencia_texto)
	a.completar_pessoais()   # apelido, cidade e objeto (docs/59)


## Save de antes das descrições dos recrutas (docs/32): o recruta pronto sem conceito nem
## histórico ganha o de recrutas.json, se a classe e a origem ainda são as dele.
static func _descricao_do_recruta(a: Agente) -> void:
	if a.conceito != "" or a.historico != "":
		return
	for r in DadosJogo.ler("recrutas").recrutas:
		if r.nome == a.nome and r.classe == a.classe_id and r.get("origem", "") == a.origem_id:
			_copiar_descricao(a, r)
			return


## Equipamento inicial de uma classe: o do primeiro recruta pronto daquela classe.
func kit_da_classe(classe_id: String) -> Dictionary:
	for r in DadosJogo.ler("recrutas").recrutas:
		if r.get("classe", "") == classe_id:
			return {"equipamento": r.get("equipamento", []), "arma": r.get("arma", "")}
	return {"equipamento": [], "arma": ""}


func agente_por_id(id: String) -> Agente:
	for a in roster:
		if a.id == id:
			return a
	return null


## Requisita o equipamento da próxima missão (substitui o atual). Retorna os erros.
func requisitar(a: Agente, itens: Array, arma_id: String) -> Array[String]:
	var erros := a.validar_equipamento(itens)
	if arma_id != "" and not arma_id in itens:
		erros.append("A arma empunhada precisa estar no equipamento")
	if erros.is_empty():
		a.equipamento.clear()
		for i in itens:
			a.equipamento.append(i)
		a.arma_id = arma_id
	return erros


# --- Missões -------------------------------------------------------------------

## Erros que impedem o grupo de partir.
func validar_grupo(grupo: Array) -> Array[String]:
	var erros: Array[String] = []
	if grupo.is_empty() or grupo.size() > MAX_GRUPO:
		erros.append("Escolha de 1 a %d agentes" % MAX_GRUPO)
	for a in grupo:
		if not a in roster:
			erros.append("%s não está no roster" % a.nome)
		if not Progressao.pendencias(a).is_empty():
			erros.append("%s tem escolhas de NEX pendentes" % a.nome)
		erros.append_array(a.validar_equipamento(a.equipamento))
	return erros


func iniciar_missao(grupo: Array, semente: int) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty():
		return null
	for a in grupo:
		_restaurar(a)
	missao = Missao.nova(semente, ruleset, grupo.duplicate(), _opcoes_da_missao())
	ultimo_relatorio = {}
	return missao


## Missão da comunidade (Fase 6): mesma regra de grupo; o mapa e o conteúdo vêm da definição.
func iniciar_missao_comunidade(grupo: Array, definicao: Dictionary, semente: int) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty() or not MissaoComunidade.validar(definicao, ruleset).is_empty():
		return null
	for a in grupo:
		_restaurar(a)
	missao = MissaoComunidade.criar_missao(definicao, ruleset, grupo.duplicate(), _opcoes_da_missao(), semente)
	ultimo_relatorio = {}
	return missao


## Opções que a missão leva: as da run e se há mestre (ADR 0007: com mestre, as ameaças
## esperam a decisão dele em todas as máquinas).
func _opcoes_da_missao() -> Dictionary:
	var op := opcoes.duplicate()
	op["mestre"] = controles.mestre >= 0
	return op


## Progresso de uma campanha (criado na primeira consulta).
func progresso_campanha(id: String) -> Dictionary:
	if not campanhas.has(id):
		campanhas[id] = {"etapa": 0, "concluida": false, "vezes": 0, "marcas": [], "historico": []}
	return campanhas[id]


## Próxima missão da campanha. Uma campanha concluída recomeça do início: as marcas
## zeram, e os recrutas liberados continuam no roster.
func iniciar_missao_campanha(grupo: Array, campanha: Dictionary, semente: int) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty() or not Campanha.validar(campanha, ruleset).is_empty():
		return null
	var p := progresso_campanha(String(campanha.id))
	if p.concluida:
		p.etapa = 0
		p.concluida = false
		p.marcas = []
	var i := int(p.etapa)
	for a in grupo:
		_restaurar(a)
	missao = MissaoComunidade.criar_missao(campanha.missoes[i].definicao, ruleset, grupo.duplicate(), _opcoes_da_missao(), semente)
	missao.extras["campanha"] = Campanha.extras_da_etapa(campanha, i)
	Campanha.aplicar_marcas(missao, campanha.missoes[i], p.marcas)
	ultimo_relatorio = {}
	return missao


## Volta para a Base: aplica PP, NEX e patente (p.61-63), enterra os mortos e recupera todos.
## A entrada do memorial (docs/59, AG1 do relatório): o bastante para a parede de memória
## na Base e para a despedida na volta. A foto (classe, modelo, tom), o NEX e a patente de
## quando caiu, o lugar do caso, a data, a causa e o último registro em que o nome aparece.
func entrada_do_memorial(a: Agente, m: Missao, causa: String) -> Dictionary:
	var ultimo := ""
	var tags := RegEx.create_from_string("\\[[^\\]]*\\]")
	for i in range(m.historico.size() - 1, -1, -1):
		var linha := tags.sub(m.historico[i], "", true).strip_edges()
		if linha.contains(a.nome) and linha != "%s morreu." % a.nome:   # o aviso da morte não é registro
			ultimo = linha
			break
	return {"nome": a.nome, "causa": causa, "missao": missoes_concluidas + 1,
		"classe": a.classe_id, "aparencia": a.aparencia, "tom": a.tom, "nex": a.nex, "patente": a.patente().get("nome", ""),
		"apelido": a.apelido, "cidade": a.cidade, "objeto": a.objeto,
		"lugar": String(m.caso.local.get("nome", "")) if m.caso != null else "",
		"data": Time.get_date_string_from_system(), "ultimo": ultimo}


func encerrar_missao() -> Dictionary:
	if missao == null or not missao.encerrada:
		return {}
	var m := missao
	var pp_base := 0
	var linhas_pp: Array[String] = []
	if m.caso_solucionado():
		pp_base += ruleset.pp_por_evento("solucao_do_caso")
		linhas_pp.append("Solução do caso: %+d" % ruleset.pp_por_evento("solucao_do_caso"))
	elif m.vitoria:   # só vale o que está na ficha (p.79)
		linhas_pp.append("Caso em aberto: a ficha não responde o objetivo (+0)")
	# Pista adicional (Tabela 3.2): a que passa do que a ficha precisava (docs/43). Sem caso
	# (missões antigas), valem as pistas reunidas, como antes.
	var adicionais := m.caso.pistas_adicionais() if m.caso != null else m.pistas
	if adicionais > 0:
		pp_base += ruleset.pp_por_evento("pista_adicional") * adicionais
		linhas_pp.append("Pistas adicionais (%d): %+d" % [adicionais, ruleset.pp_por_evento("pista_adicional") * adicionais])
	if m.inocentes_mortos > 0:
		pp_base += ruleset.pp_por_evento("morte_de_inocente") * m.inocentes_mortos
		linhas_pp.append("Inocentes mortos (%d): %+d" % [m.inocentes_mortos, ruleset.pp_por_evento("morte_de_inocente") * m.inocentes_mortos])
	if not m.mortos.is_empty():
		pp_base += ruleset.pp_por_evento("morte_de_membro_do_grupo") * m.mortos.size()
		linhas_pp.append("Membros mortos (%d): %+d" % [m.mortos.size(), ruleset.pp_por_evento("morte_de_membro_do_grupo") * m.mortos.size()])
	var agentes_rel: Array = []
	for a in m.agentes_iniciais:
		var linha := {"nome": a.nome, "id": a.id}
		if a in m.mortos or a.tem(Ser.MORTO):
			linha.situacao = "morto"
			memorial.append(entrada_do_memorial(a, m, "morto em missão"))
			roster.erase(a)
		elif a.tem(Ser.INSANO):
			linha.situacao = "insano"
			memorial.append(entrada_do_memorial(a, m, "perdido para o Outro Lado"))
			roster.erase(a)
		else:
			linha.situacao = "resgatado" if a in m.resgatados else "voltou"
			var patente_antes: String = a.patente().get("nome", "")
			a.pp = maxi(0, a.pp + pp_base)
			linha.pp = pp_base
			linha.nex_antes = a.nex
			if m.vitoria and a.nex < 99:
				a.nex = 99 if a.nex >= 95 else a.nex + int(ruleset.dados.progressao_nex.nex_por_missao)
			linha.nex = a.nex
			linha.patente = a.patente().get("nome", "")
			linha.promovido = linha.patente != patente_antes
			linha.pendencias = Progressao.pendencias(a).size()
			_restaurar(a)
		agentes_rel.append(linha)
	missoes_concluidas += 1
	ultimo_relatorio = {"vitoria": m.vitoria, "solucionado": m.caso_solucionado(), "pp": pp_base, "detalhes_pp": linhas_pp, "agentes": agentes_rel,
		"turnos": m.turno_mundo, "membrana": m.membrana.valor, "missao": missoes_concluidas}
	if m.extras.has("campanha"):
		ultimo_relatorio["campanha"] = _avancar_campanha(m)
	missao = null
	return ultimo_relatorio


## Fim de uma missão da campanha. Na vitória, a etapa avança, as marcas ficam e os
## recrutas entram na lista; na derrota, a mesma missão espera outra tentativa.
func _avancar_campanha(m: Missao) -> Dictionary:
	var c: Dictionary = m.extras.campanha
	var p := progresso_campanha(String(c.id))
	var rel := {"titulo": c.titulo, "etapa": int(c.etapa) + 1, "total": int(c.total), "vitoria": m.vitoria,
		"texto": c.depois if m.vitoria else c.falha, "marcas": [], "recrutas": [], "concluida": false, "epilogo": ""}
	p.historico.append({"etapa": int(c.etapa), "vitoria": m.vitoria})
	if not m.vitoria or int(p.etapa) != int(c.etapa):
		return rel
	for marca in Campanha.marcas_ganhas(m):
		if not marca.id in p.marcas:
			p.marcas.append(marca.id)
			rel.marcas.append(String(marca.get("texto", "")))
	for r in c.recrutas:
		if not recrutas_extras.any(func(x): return x.nome == r.nome):
			recrutas_extras.append(r.duplicate(true))
			rel.recrutas.append(r.nome)
	p.etapa = int(p.etapa) + 1
	if int(p.etapa) >= int(c.total):
		p.concluida = true
		p.vezes = int(p.vezes) + 1
		rel.concluida = true
		rel.epilogo = c.epilogo
	return rel


## Entre missões, na Base: recuperação total e fim de condições.
func _restaurar(a: Agente) -> void:
	a.bonus_exercicio = 0   # os bônus do interlúdio valem até o fim da missão (p.93)
	a.bonus_leitura = 0
	a.limpar_insanidade()   # o efeito de insanidade dura no máximo até o fim da missão (p.111)
	a.condicoes.clear()
	a.encerrar_cena()
	a.recalcular_maximos(true)


# --- Salvar / carregar ---------------------------------------------------------

func para_dicionario() -> Dictionary:
	return {
		"versao": VERSAO, "ruleset": ruleset.id, "proximo_id": _proximo_id,
		"roster": roster.map(func(a): return a.para_dicionario()),
		"memorial": memorial.duplicate(true), "opcoes": opcoes.duplicate(), "controles": controles.para_dicionario(),
		"missoes_concluidas": missoes_concluidas, "ultimo_relatorio": ultimo_relatorio.duplicate(true),
		"campanhas": campanhas.duplicate(true), "recrutas_extras": recrutas_extras.duplicate(true),
		"missao": missao.para_dicionario() if missao != null else {},
		# Agentes que estão na missão mas saíram do roster (mortos aguardando o relatório)
		"extras": _agentes_fora_do_roster().map(func(a): return a.para_dicionario()),
	}


func _agentes_fora_do_roster() -> Array:
	if missao == null:
		return []
	return missao.agentes_iniciais.filter(func(a): return not a in roster)


static func de_dicionario(d: Dictionary, ruleset_: Ruleset = null) -> Carreira:
	var c := Carreira.new()
	c.ruleset = ruleset_ if ruleset_ != null else RulesetOp2022.carregar_padrao()
	c._proximo_id = int(d.get("proximo_id", 1))
	var por_id: Dictionary = {}
	for ad in d.get("roster", []):
		var a := Agente.de_dicionario(c.ruleset, ad)
		_descricao_do_recruta(a)
		a.completar_pessoais()   # saves de antes dos adereços (docs/59)
		c.roster.append(a)
		por_id[a.id] = a
	for ad in d.get("extras", []):
		var a := Agente.de_dicionario(c.ruleset, ad)
		por_id[a.id] = a
	for m in d.get("memorial", []):
		c.memorial.append(m)
	c.opcoes = d.get("opcoes", c.opcoes)
	c.controles = ControleLocal.de_dicionario(d.get("controles", {}))
	c.missoes_concluidas = int(d.get("missoes_concluidas", 0))
	c.ultimo_relatorio = d.get("ultimo_relatorio", {})
	c.campanhas = d.get("campanhas", {})
	c.recrutas_extras = d.get("recrutas_extras", [])
	var md: Dictionary = d.get("missao", {})
	if not md.is_empty():
		c.missao = Missao.de_dicionario(c.ruleset, md, por_id)
	return c


func salvar(caminho: String = "") -> Error:
	if caminho == "":
		caminho = arquivo_padrao
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(para_dicionario(), "\t"))
	return OK


static func carregar(caminho: String = "") -> Carreira:
	if caminho == "":
		caminho = arquivo_padrao
	if not FileAccess.file_exists(caminho):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not d is Dictionary or int(d.get("versao", 0)) != VERSAO:
		return null
	return de_dicionario(d)


## Uma linha sobre o save, sem carregar a carreira (tela de título, docs/21):
## "3 agentes · missão em andamento, turno 4". "" sem save legível.
static func resumo_save(caminho: String = "") -> String:
	if caminho == "":
		caminho = arquivo_padrao
	if not FileAccess.file_exists(caminho):
		return ""
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not d is Dictionary:
		return ""
	var n: int = (d.get("roster", []) as Array).size()
	var partes := PackedStringArray(["%d agente%s" % [n, "" if n == 1 else "s"]])
	var m: Dictionary = d.get("missao", {})
	if not m.is_empty():
		partes.append("missão em andamento, turno %d" % int(m.get("turno_mundo", 1)))
	else:
		var feitas := int(d.get("missoes_concluidas", 0))
		partes.append("%d missão concluída" % feitas if feitas == 1 else "%d missões concluídas" % feitas)
	return " · ".join(partes)


static func existe_save(caminho: String = "") -> bool:
	if caminho == "":
		caminho = arquivo_padrao
	return FileAccess.file_exists(caminho)
