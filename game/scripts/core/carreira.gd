class_name Carreira
extends RefCounted
## Carreira na Ordem: roster persistente de agentes, opções da run, missões e o
## relatório ao voltar (PP, NEX, patente, mortes). Salva tudo em JSON.

const ARQUIVO := "user://carreira.json"
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
	return DadosJogo.ler("recrutas").recrutas.filter(func(r): return not r.nome in nomes and not r.nome in caidos)


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
			a.id = "ag%d" % _proximo_id
			_proximo_id += 1
			for item in r.get("equipamento", []):
				a.equipamento.append(item)
			a.arma_id = r.get("arma", "")
			roster.append(a)
			return a
	return null


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
	missao = Missao.nova(semente, ruleset, grupo.duplicate(), opcoes.duplicate())
	ultimo_relatorio = {}
	return missao


## Missão da comunidade (Fase 6): mesma regra de grupo; o mapa e o conteúdo vêm da definição.
func iniciar_missao_comunidade(grupo: Array, definicao: Dictionary, semente: int) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty() or not MissaoComunidade.validar(definicao, ruleset).is_empty():
		return null
	for a in grupo:
		_restaurar(a)
	missao = MissaoComunidade.criar_missao(definicao, ruleset, grupo.duplicate(), opcoes.duplicate(), semente)
	ultimo_relatorio = {}
	return missao


## Volta para a Base: aplica PP, NEX e patente (p.61-63), enterra os mortos e recupera todos.
func encerrar_missao() -> Dictionary:
	if missao == null or not missao.encerrada:
		return {}
	var m := missao
	var pp_base := 0
	var linhas_pp: Array[String] = []
	if m.vitoria:
		pp_base += ruleset.pp_por_evento("solucao_do_caso")
		linhas_pp.append("Solução do caso: %+d" % ruleset.pp_por_evento("solucao_do_caso"))
	if m.pistas > 0:
		pp_base += ruleset.pp_por_evento("pista_adicional") * m.pistas
		linhas_pp.append("Pistas adicionais (%d): %+d" % [m.pistas, ruleset.pp_por_evento("pista_adicional") * m.pistas])
	if not m.mortos.is_empty():
		pp_base += ruleset.pp_por_evento("morte_de_membro_do_grupo") * m.mortos.size()
		linhas_pp.append("Membros mortos (%d): %+d" % [m.mortos.size(), ruleset.pp_por_evento("morte_de_membro_do_grupo") * m.mortos.size()])
	var agentes_rel: Array = []
	for a in m.agentes_iniciais:
		var linha := {"nome": a.nome, "id": a.id}
		if a in m.mortos or a.tem(Ser.MORTO):
			linha.situacao = "morto"
			memorial.append({"nome": a.nome, "causa": "morto em missão", "missao": missoes_concluidas + 1})
			roster.erase(a)
		elif a.tem(Ser.INSANO):
			linha.situacao = "insano"
			memorial.append({"nome": a.nome, "causa": "perdido para o Outro Lado", "missao": missoes_concluidas + 1})
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
	ultimo_relatorio = {"vitoria": m.vitoria, "pp": pp_base, "detalhes_pp": linhas_pp, "agentes": agentes_rel,
		"turnos": m.turno_mundo, "membrana": m.membrana.valor, "missao": missoes_concluidas}
	missao = null
	return ultimo_relatorio


## Entre missões, na Base: recuperação total e fim de condições.
func _restaurar(a: Agente) -> void:
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
	var md: Dictionary = d.get("missao", {})
	if not md.is_empty():
		c.missao = Missao.de_dicionario(c.ruleset, md, por_id)
	return c


func salvar(caminho: String = ARQUIVO) -> Error:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(para_dicionario(), "\t"))
	return OK


static func carregar(caminho: String = ARQUIVO) -> Carreira:
	if not FileAccess.file_exists(caminho):
		return null
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not d is Dictionary or int(d.get("versao", 0)) != VERSAO:
		return null
	return de_dicionario(d)


static func existe_save(caminho: String = ARQUIVO) -> bool:
	return FileAccess.file_exists(caminho)
