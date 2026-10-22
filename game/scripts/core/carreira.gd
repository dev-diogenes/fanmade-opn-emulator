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
## A varredura malfeita do último covil (docs/62): a próxima missão começa com o eco dele.
var eco_do_covil := false
## A contenção da Base (docs/63, OR8): [{nome, papel, elemento, cela, segredos, interrogado}].
var contencao: Array = []
## O que um preso contou e vale na próxima missão: uma pista firme no começo (docs/63).
var pista_do_preso: Dictionary = {}
## Amostras para o laboratório (docs/63, OR2): saem das pistas além do necessário.
var amostras := 0
## O vilão que liga os casos (docs/71): a empresa de fachada e os recortes que a apontam.
var vilao: Dictionary = {}
var recortes: Array = []
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


## Recrutas prontos que mudaram de nome (docs/60, ADR 0012): o nome coincidia com o de um
## personagem do cânone, e a licença não deixa usá-los. Saves antigos trocam na carga.
const RENOMEADOS := {"Mauro": "Cléber", "Joana": "Celeste", "Tiago": "Ademir"}


## Save de antes das descrições dos recrutas (docs/32): o recruta pronto sem conceito nem
## histórico ganha o de recrutas.json, se a classe e a origem ainda são as dele.
static func _descricao_do_recruta(a: Agente) -> void:
	if RENOMEADOS.has(a.nome):
		var novo: String = RENOMEADOS[a.nome]
		for r in DadosJogo.ler("recrutas").recrutas:
			if r.nome == novo and r.classe == a.classe_id:
				a.nome = novo
				break
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
		if a.em_tratamento:
			erros.append("%s está em tratamento na Enfermaria" % a.nome)
		erros.append_array(a.validar_equipamento(a.equipamento))
	return erros


func iniciar_missao(grupo: Array, semente: int, sinal: Dictionary = {}) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty():
		return null
	for a in grupo:
		_restaurar(a)
	var op := _opcoes_da_missao()
	if not sinal.is_empty():
		op["sinal"] = _ligar_ao_vilao(sinal)
	missao = Missao.nova(semente, ruleset, grupo.duplicate(), op)
	missao.aplicar_efeitos_do_culto()   # docs/71
	if eco_do_covil:
		missao.plantar_eco_do_covil()
		eco_do_covil = false
	if not pista_do_preso.is_empty():
		missao.receber_pista_do_preso(pista_do_preso)
		pista_do_preso = {}
	ultimo_relatorio = {}
	return missao


## Missão da comunidade (Fase 6): mesma regra de grupo; o mapa e o conteúdo vêm da definição.
func iniciar_missao_comunidade(grupo: Array, definicao: Dictionary, semente: int) -> Missao:
	if missao != null or not validar_grupo(grupo).is_empty() or not MissaoComunidade.validar(definicao, ruleset).is_empty():
		return null
	for a in grupo:
		_restaurar(a)
	missao = MissaoComunidade.criar_missao(definicao, ruleset, grupo.duplicate(), _opcoes_da_missao(), semente)
	if missao.caso != null:
		missao.caso.culto = {}   # o caso escrito à mão não ganha culto sorteado (docs/71)
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
	if missao.caso != null:
		missao.caso.culto = {}   # o caso escrito à mão não ganha culto sorteado (docs/71)
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
	var cfg_sinais := DadosJogo.ler("sinais")
	if m.alarme_confirmado:
		# Alarme falso (docs/62): pouco prestígio, e o NEX não sobe (ninguém tocou o paranormal)
		pp_base += int(cfg_sinais.get("alarme_falso_pp", 2))
		linhas_pp.append("Alarme falso, não era paranormal: %+d" % int(cfg_sinais.get("alarme_falso_pp", 2)))
	elif m.caso_solucionado():
		pp_base += ruleset.pp_por_evento("solucao_do_caso")
		linhas_pp.append("Solução do caso: %+d" % ruleset.pp_por_evento("solucao_do_caso"))
	elif m.vitoria:   # só vale o que está na ficha (p.79)
		linhas_pp.append("Caso em aberto: a ficha não responde o objetivo (+0)")
	if m.vitoria and not m.alarme_confirmado and int(m.sinal.get("bonus_pp", 0)) > 0:
		pp_base += int(m.sinal.bonus_pp)   # ninguém dava nada por esse sinal (docs/62)
		linhas_pp.append("Sinal de confiança baixa, e era real: %+d" % int(m.sinal.bonus_pp))
	pp_base += _fechar_vilao(m, linhas_pp)   # docs/71
	match m.varredura:   # docs/62
		"equipe":
			pp_base -= 2
			linhas_pp.append("Equipe de varredura: -2")
		"limpa":
			linhas_pp.append("Varredura limpa: nada ficou para trás (+0)")
		"rastro":
			eco_do_covil = true
			linhas_pp.append("Varredura malfeita: algo ficou no covil (+0)")
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
			if m.vitoria and not m.alarme_confirmado and a.nex < 99:
				a.nex = 99 if a.nex >= 95 else a.nex + int(ruleset.dados.progressao_nex.nex_por_missao)
			linha.nex = a.nex
			linha.patente = a.patente().get("nome", "")
			linha.promovido = linha.patente != patente_antes
			linha.pendencias = Progressao.pendencias(a).size()
			var trauma := _trauma_da_missao(a, m)
			if trauma != "":
				linha.trauma = trauma
			_restaurar(a)
		agentes_rel.append(linha)
	# Quem ficou na Enfermaria durante a missão sai tratado (docs/70)
	var cfg_t := DadosJogo.ler("traumas")
	for a in roster:
		if a.em_tratamento and not a in m.agentes_iniciais:
			a.em_tratamento = false
			if not a.traumas.is_empty():
				var curado: Dictionary = a.traumas.pop_front()
				var nome_fobia := String(cfg_t.fobias.get(String(curado.elemento), {}).get("nome", "fobia"))
				linhas_pp.append("%s terminou o tratamento: a %s passou (+0)" % [a.nome, nome_fobia.to_lower()])
	# A contenção e o laboratório (docs/63): presos para as celas livres, amostras das pistas a mais
	var cfg_c: Dictionary = DadosJogo.ler("sinais").contencao
	var presos_novos: Array = []
	if m.vitoria:
		for p in m.presos:
			var livres: Array = (cfg_c.celas as Array).filter(func(cl): return not contencao.any(func(x): return x.cela == cl))
			if livres.is_empty():
				linhas_pp.append("%s foi transferido: as celas estão cheias (+0)" % p.nome)
				continue
			var preso: Dictionary = p.duplicate()
			preso.cela = String(livres[0])
			preso.segredos = maxi(1, int(cfg_c.segredos) + (int(m.caso.culto.get("efeito", {}).get("segredos_preso", 0)) if m.caso != null and m.extras.get("culto", false) else 0))   # a estrutura do culto (docs/71)
			preso.interrogado = -1
			contencao.append(preso)
			presos_novos.append("%s (cela %s)" % [preso.nome, preso.cela])
		if adicionais > 0 and not m.alarme_confirmado:
			var novas := mini(adicionais, int(DadosJogo.ler("sinais").laboratorio.amostras_por_missao))
			amostras += novas
			linhas_pp.append("Amostras para o laboratório: %d (+0)" % novas)
	if not presos_novos.is_empty():
		linhas_pp.append("Contenção: %s (+0)" % ", ".join(PackedStringArray(presos_novos)))
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


## Interrogar um preso (docs/63, OR8): uma vez por visita à Base. O agente testa a melhor
## das perícias sociais contra a DT; passando, o preso conta algo que vale uma pista firme no
## começo da próxima missão e gasta um segredo; sem segredos, é transferido.
func interrogar(indice: int, agente: Agente) -> Dictionary:
	if indice < 0 or indice >= contencao.size() or agente == null or not agente in roster:
		return {"ok": false}
	var p: Dictionary = contencao[indice]
	if int(p.get("interrogado", -1)) == missoes_concluidas:
		return {"ok": false, "erro": "já interrogado nesta visita"}
	var cfg: Dictionary = DadosJogo.ler("sinais").contencao
	var melhor := String(cfg.pericias[0])
	for per in cfg.pericias:
		if agente.dados_da_pericia(per) * 100 + agente.bonus_pericia(per) > agente.dados_da_pericia(melhor) * 100 + agente.bonus_pericia(melhor):
			melhor = String(per)
	var dados := Dados.new(absi(hash("%d|%s|%s" % [missoes_concluidas, p.nome, agente.id])))
	var t := agente.testar(dados, melhor, int(cfg.dt))
	p.interrogado = missoes_concluidas
	var sucesso := t != null and t.sucesso
	var texto := ""
	if sucesso:
		pista_do_preso = {"cela": p.cela, "nome": p.nome}
		p.segredos = int(p.segredos) - 1
		texto = "%s fala. A próxima missão começa com uma pista firme." % p.nome
		if int(p.segredos) <= 0:
			contencao.remove_at(indice)
			texto += " Sem mais o que contar, %s é transferido." % p.nome
	else:
		texto = String(cfg.falha)
	return {"ok": true, "sucesso": sucesso, "teste": t, "pericia": melhor, "texto": texto}


## Laboratório (docs/63, OR2): uma amostra diz se um sinal é real ou alarme falso.
func analisar_sinal(sinal: Dictionary) -> Dictionary:
	if amostras <= 0:
		return {"ok": false}
	amostras -= 1
	sinal["verificado"] = true
	return {"ok": true, "alarme_falso": bool(sinal.get("alarme_falso", false))}


## Entre missões, na Base: recuperação total e fim de condições.
# --- O vilão que liga os casos (docs/71, OR6) -------------------------------------

## Metade das missões tem um culto ligado ao vilão da carreira; o sinal final já vem ligado.
func _ligar_ao_vilao(sinal: Dictionary) -> Dictionary:
	var s := sinal.duplicate(true)
	if vilao.is_empty():
		vilao = Culto.vilao(int(s.get("semente", 0)))
	if s.get("vilao", {}).get("final", false):
		return s
	if not s.get("alarme_falso", false) and Culto.liga_ao_vilao(int(s.get("semente", 0))):
		s["vilao"] = {"ligado": true, "nome": vilao.nome}
	return s


## Três recortes no quadro: a Ordem acha a sede do vilão.
func vilao_encontrado() -> bool:
	return not vilao.is_empty() and recortes.size() >= int(DadosJogo.ler("cultos").vilao.get("recortes_para_achar", 3))


## O sinal da sede do vilão: certeza total, chefe mais forte.
func sinal_do_vilao(semente: int) -> Dictionary:
	var fim: Dictionary = DadosJogo.ler("cultos").vilao.final
	var s := Sinais.de(semente, "alta")
	s.fonte = String(fim.fonte)
	s.relato = String(fim.relato).replace("{empresa}", String(vilao.nome))
	s.rotulo = "certeza"
	s.alarme_falso = false
	s.vilao = {"final": true, "nome": vilao.nome}
	return s


## Fim de missão: o recorte novo, ou a queda do vilão. Devolve o PP a somar.
func _fechar_vilao(m: Missao, linhas_pp: Array[String]) -> int:
	var vil: Dictionary = m.sinal.get("vilao", {})
	if vil.is_empty() or m.caso == null or not m.vitoria or not m.caso_solucionado():
		return 0
	if vil.get("final", false):
		var pp := int(DadosJogo.ler("cultos").vilao.final.pp)
		linhas_pp.append("A %s cai: os cultos que ela pagava ficam sem dono: %+d" % [vil.nome, pp])
		vilao = Culto.vilao(int(m.semente) + 1, int(vilao.get("derrotados", 0)) + 1)
		recortes.clear()
		return pp
	var texto := Culto.recorte(vilao, m.caso.culto, int(m.semente))
	recortes.append({"missao": missoes_concluidas + 1, "texto": texto, "culto": String(m.caso.culto.get("nome", ""))})
	linhas_pp.append("Recorte para o quadro do escritório: \"%s\" (+0)" % texto)
	return 0


## Traumas que ficam (docs/70): quem chegou a enlouquecer na missão (o efeito de insanidade
## durava até o fim dela) testa Vontade; falhando, leva uma fobia do elemento do caso.
func _trauma_da_missao(a: Agente, m: Missao) -> String:
	if not a.efeitos_insanidade.any(func(e): return e.get("ate_o_fim", false)):
		return ""
	var cfg := DadosJogo.ler("traumas")
	var elemento := m.caso.elemento if m.caso != null else String(cfg.get("elemento_sem_caso", "medo"))
	if a.tem_fobia(elemento):
		return ""
	var t := a.testar(m.dados, "vontade", int(cfg.get("dt_vontade", 20)))
	if t != null and t.sucesso:
		return ""
	a.traumas.append({"elemento": elemento, "missao": missoes_concluidas + 1})
	return String(cfg.fobias.get(elemento, {}).get("nome", "Fobia"))


## Enfermaria (docs/70): quem tem trauma pode ficar fora da próxima missão para se tratar
## (de novo, desiste do tratamento).
func tratar(a: Agente) -> bool:
	if a.traumas.is_empty() or missao != null:
		return false
	a.em_tratamento = not a.em_tratamento
	return true


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
		"missoes_concluidas": missoes_concluidas, "ultimo_relatorio": ultimo_relatorio.duplicate(true), "eco_do_covil": eco_do_covil,
		"contencao": contencao.duplicate(true), "pista_do_preso": pista_do_preso.duplicate(), "amostras": amostras,
		"vilao": vilao.duplicate(true), "recortes": recortes.duplicate(true),
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
	c.eco_do_covil = bool(d.get("eco_do_covil", false))
	for p in d.get("contencao", []):
		var preso: Dictionary = p.duplicate()
		preso.segredos = int(preso.get("segredos", 0))
		preso.interrogado = int(preso.get("interrogado", -1))
		c.contencao.append(preso)
	c.pista_do_preso = (d.get("pista_do_preso", {}) as Dictionary).duplicate()
	c.amostras = int(d.get("amostras", 0))
	c.vilao = (d.get("vilao", {}) as Dictionary).duplicate(true)
	c.recortes = (d.get("recortes", []) as Array).duplicate(true)
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
