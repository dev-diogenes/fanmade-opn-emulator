class_name CenaInvestigacao
extends RefCounted
## Cena de investigação (p.89-91): rodadas com um turno por agente; cada um escolhe
## Procurar Pistas, Facilitar Investigação, Ajudar ou usar uma habilidade. A urgência
## limita as rodadas; a cada 3 falhas ao procurar, perde-se uma rodada (regra do livro).
## Quando a urgência acaba, um evento encerra a cena e pode haver penalidade.

signal registro(texto: String)
signal terminou(resultado: Dictionary)

var ruleset: Ruleset
var dados: Dados
var caso: Caso
var membrana: Membrana       ## Opcional: cada rodada enfraquece a Membrana
var cena: Dictionary = {}
var agentes: Array[Agente] = []
var rodada := 1
var rodadas_max := 4
var urgencia: Dictionary = {}
var falhas := 0
var indice := 0
var pontos_restantes: Array[String] = []
var pistas_encontradas: Array[Dictionary] = []
var perguntas_respondidas: Array[Dictionary] = []
var encerrada := false
var motivo_fim := ""
var urgencia_estourada := false
var penalidade: Dictionary = {}

var _cfg: Dictionary
var _facilitar: Dictionary = {}       ## Agente -> bônus pendente (+2, não acumula)
var _presteza_pendente := false       ## Presteza Atlética: o próximo aliado que usar o bônus ganha +1 dado
var _ajuda: Dictionary = {}           ## Agente -> bônus de ajuda pendente
var _trilha: Dictionary = {}          ## Agente -> {"sucessos": int, "dados": int} (Na Trilha Certa)
var _acoes_extras := 0
var _atributo_forcado := ""           ## Incansável: a ação extra usa Força ou Agilidade
var _usos_cena: Dictionary = {}       ## "agente_id:habilidade" -> true
var _usos_rodada: Dictionary = {}


## `cenas_extras`: cenas próprias da missão (Fase 7), procuradas antes das do jogo.
static func nova(ruleset_: Ruleset, dados_: Dados, caso_: Caso, cena_id: String, grupo: Array, urgencia_id: String = "", membrana_: Membrana = null, cenas_extras: Array = []) -> CenaInvestigacao:
	var c := CenaInvestigacao.new()
	c.ruleset = ruleset_
	c.dados = dados_
	c.caso = caso_
	c.membrana = membrana_
	c._cfg = ruleset_.dados.get("investigacao", {})
	for cn in cenas_extras + DadosJogo.ler("cenas_investigacao").cenas:
		if cn.id == cena_id:
			c.cena = cn
			break
	assert(not c.cena.is_empty(), "Cena de investigação desconhecida: %s" % cena_id)
	for a in grupo:
		if not a.esta_fora_de_combate():
			c.agentes.append(a)
	var graus: Array = c._cfg.urgencia
	if urgencia_id == "":
		urgencia_id = ["baixo", "medio", "alto"][dados_.rolar(3) - 1]
	for g in graus:
		if g.id == urgencia_id:
			c.urgencia = g
	c.rodadas_max = int(c.urgencia.get("rodadas", 4))
	for p in c.cena.pontos:
		c.pontos_restantes.append(p.id)
	c._log("[b]%s[/b] — urgência %s (%d rodadas)." % [c.cena.nome, String(c.urgencia.get("nome", "")).to_lower(), c.rodadas_max])
	c._log("[i]Pista básica:[/i] %s" % c.cena.pista_basica)
	c._preparar_turno(true)
	return c


func _log(texto: String) -> void:
	registro.emit(texto)


# --- Turnos ---------------------------------------------------------------------

func agente_atual() -> Agente:
	if encerrada or agentes.is_empty():
		return null
	return agentes[indice]


func ponto(ponto_id: String) -> Dictionary:
	for p in cena.pontos:
		if p.id == ponto_id:
			return p
	return {}


func pontos_disponiveis() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for p in cena.pontos:
		if p.id in pontos_restantes:
			lista.append(p)
	return lista


func opcao_facilitar(opcao_id: String) -> Dictionary:
	for o in cena.get("facilitar", []):
		if o.id == opcao_id:
			return o
	return {}


## Distraído (desvantagem de idade): perde o primeiro turno de investigação.
func _perde_turno(a: Agente) -> bool:
	return rodada == 1 and not a.efeitos("surpreendido_inicio").is_empty()


func _preparar_turno(inicio: bool = false) -> void:
	if not inicio:
		return
	while agente_atual() != null and _perde_turno(agente_atual()):
		_log("%s está distraído e perde o primeiro turno." % agente_atual().nome)
		_avancar_indice()
	var a := agente_atual()
	if a != null:
		a.iniciar_turno()


func _avancar_indice() -> void:
	indice += 1
	if indice >= agentes.size():
		indice = 0
		rodada += 1
		_usos_rodada.clear()
		if membrana != null:
			membrana.registrar("rodada_investigacao")
		if rodada > rodadas_max:
			_estourar_urgencia()


## Fim de uma ação: o mesmo agente age de novo se tiver ação extra; senão, o próximo.
func _acao_concluida() -> void:
	_atributo_forcado = ""
	if encerrada:
		return
	if pontos_restantes.is_empty():
		encerrar("todas as pistas foram encontradas")
		return
	if _acoes_extras > 0:
		_acoes_extras -= 1
		return
	for _i in agentes.size() + 1:
		_avancar_indice()
		if encerrada:
			return
		if not _perde_turno(agente_atual()):
			break
		_log("%s está distraído e perde o primeiro turno." % agente_atual().nome)
	agente_atual().iniciar_turno()


# --- Ações (p.90) ---------------------------------------------------------------

## Procurar Pistas: teste da perícia escolhida contra a DT do ponto de interesse.
## `opcoes` é repassado a Agente.testar (habilidades, perito, ecletico…); o contexto
## "procurar_pistas" é colocado aqui (ex.: Faro para Pistas). Retorna {} se inválido.
## Opções e DT do Procurar Pistas: bônus de Facilitar e Ajudar, dados da Na Trilha Certa e
## da Presteza, atributo forçado e Causalidade Fortuita. Usado pelo teste e pela previsão.
func _preparar_procurar(a: Agente, p: Dictionary, pericia: String, opcoes: Dictionary) -> Dictionary:
	var op := opcoes.duplicate()
	op["contexto"] = "procurar_pistas"
	var bonus := int(_facilitar.get(a, 0)) + int(_ajuda.get(a, 0))
	var extras := int(_trilha.get(a, {}).get("dados", 0))
	var presteza := false
	if _facilitar.has(a) and _presteza_pendente:
		extras += 1
		presteza = true
	op["bonus_extra"] = int(op.get("bonus_extra", 0)) + bonus
	op["dados_extras"] = int(op.get("dados_extras", 0)) + extras
	if _atributo_forcado != "":
		op["atributo_base"] = _atributo_forcado
	var dt := int(p.pericias[pericia])
	# Causalidade Fortuita (p.115): −5 na DT até achar uma pista (afinidade: sempre)
	if not a.efeitos("causalidade_fortuita").is_empty():
		var achou := pistas_encontradas.any(func(x): return x.get("agente", "") == a.nome)
		if not achou or not a.efeitos("causalidade_sempre").is_empty():
			dt -= 5
	return {"op": op, "dt": dt, "presteza": presteza}


## Previsão do Procurar Pistas para a UI (docs/21): {"chance", "dados", "bonus", "dt"}.
func prever_procurar(ponto_id: String, pericia: String, pe_foco: int = 0, opcoes: Dictionary = {}) -> Dictionary:
	var a := agente_atual()
	var p := ponto(ponto_id)
	if a == null or p.is_empty() or not p.pericias.has(pericia):
		return {}
	var prep := _preparar_procurar(a, p, pericia, opcoes)
	var r := a.prever_teste(pericia, prep.dt, pe_foco, prep.op)
	r["dt"] = prep.dt
	return r


## Previsão do Facilitar (sem gastar o PE da Presteza Atlética).
func prever_facilitar(opcao_id: String, pericia: String, pe_foco: int = 0, opcoes: Dictionary = {}) -> Dictionary:
	var a := agente_atual()
	var o := opcao_facilitar(opcao_id)
	if a == null or o.is_empty() or not o.pericias.has(pericia):
		return {}
	var op := opcoes.duplicate()
	if op.get("presteza_atletica", false):
		op["atributo_base"] = "for" if a.atributo("for") >= a.atributo("agi") else "agi"
	if a.tem_habilidade("intuicao_paranormal"):
		op["bonus_extra"] = int(op.get("bonus_extra", 0)) + maxi(a.atributo("int"), a.atributo("pre"))
	if _atributo_forcado != "":
		op["atributo_base"] = _atributo_forcado
	var dt := int(o.pericias[pericia])
	var r := a.prever_teste(pericia, dt, pe_foco, op)
	r["dt"] = dt
	return r


## Previsão do Ajudar (DT fixa da cena).
func prever_ajudar(pericia: String) -> Dictionary:
	var a := agente_atual()
	if a == null:
		return {}
	var dt := int(_cfg.ajuda.dt)
	var r := a.prever_teste(pericia, dt)
	r["dt"] = dt
	return r


func procurar(ponto_id: String, pericia: String, pe_foco: int = 0, opcoes: Dictionary = {}) -> Dictionary:
	var a := agente_atual()
	var p := ponto(ponto_id)
	if a == null or p.is_empty() or not ponto_id in pontos_restantes or not p.pericias.has(pericia):
		return {}
	var prep := _preparar_procurar(a, p, pericia, opcoes)
	var op: Dictionary = prep.op
	var dt: int = prep.dt
	var usou_presteza: bool = prep.presteza
	var teste := a.testar(dados, pericia, dt, pe_foco, op)
	if teste == null:
		return {}
	_facilitar.erase(a)
	_ajuda.erase(a)
	if usou_presteza:
		_presteza_pendente = false
	if _trilha.has(a):
		_trilha[a].dados = 0
	var resultado := {"teste": teste, "sucesso": teste.sucesso, "pista": ""}
	_log("%s procura em [b]%s[/b] com %s: %s" % [a.nome, p.nome, ruleset.pericia(pericia).nome, teste.descrever()])
	if teste.sucesso:
		# Depoimento passado por pouco (docs/35): a testemunha hesita e pode estar enganada
		var incerta: bool = p.get("depoimento", false) and teste.total - dt < MARGEM_DEPOIMENTO_FIRME
		resultado.pista = _encontrar_pista(a, ponto_id, incerta)
		resultado.incerta = incerta
		var t: Dictionary = _trilha.get_or_add(a, {"sucessos": 0, "dados": 0})
		t.sucessos += 1
	else:
		falhas += 1
		if _trilha.has(a):
			_trilha[a].sucessos = 0
		if falhas % int(_cfg.get("falhas_para_perder_rodada", 3)) == 0:
			rodadas_max -= 1
			_log("[color=#eda64a]Descuidos acumulados: a urgência aumenta (−1 rodada).[/color]")
	_acao_concluida()
	return resultado


## Depoimento firme: passar no teste da testemunha por 10 ou mais (docs/35; era 5 até o
## docs/44, design do jogo). Examinar com treino (pista central) continua firme.
const MARGEM_DEPOIMENTO_FIRME := 10


## Anota a pista do ponto e tira o ponto da cena. Devolve o texto da pista.
## `incerta`: depoimento aos tropeços; os dados da cena decidem se a testemunha acertou.
func _encontrar_pista(a: Agente, ponto_id: String, incerta: bool = false, sorte: int = -1) -> String:
	var p := ponto(ponto_id)
	pontos_restantes.erase(ponto_id)
	if sorte < 0:   # a sorte da testemunha: da cena, do ponto e do momento, sem rolar dados
		sorte = absi(hash("%s|%s|%d|%d" % [cena.id, ponto_id, rodada, caso.pistas.size()]))
	var pista := caso.registrar_pista(p.pista, p.responde, cena.id, incerta, sorte)
	var texto := String(pista.texto)
	pistas_encontradas.append({"ponto": ponto_id, "texto": texto, "responde": p.responde, "agente": a.nome,
		"indicio": pista.indicio, "duvidosa": incerta})
	var rotulo := String(Caso.indicio(pista.indicio).get("rotulo", "")) if pista.indicio != "" else ""
	if incerta:
		_log("[color=#eda64a]Depoimento incerto:[/color] %s%s [i](a testemunha hesita; pode estar enganada)[/i]" % [texto, "  [color=#e3c27a][?%s][/color]" % rotulo.to_upper() if rotulo != "" else ""])
	else:
		_log("[color=#6fcf8e]Pista:[/color] %s%s" % [texto, "  [color=#e3c27a][%s][/color]" % rotulo.to_upper() if rotulo != "" else ""])
	return texto


## O grupo acusa um candidato no quadro (docs/32). Não gasta a ação de ninguém.
## O efeito da pergunta vale ao sair da cena (Missao.concluir_investigacao); o erro
## custa Membrana na hora.
func deduzir(pergunta_id: String, candidato_id: String) -> Dictionary:
	var r := caso.deduzir(pergunta_id, candidato_id)
	if not r.ok:
		return r
	if r.acertou:
		perguntas_respondidas.append(r.pergunta)
		_log("[color=#e3c27a][b]Dedução certa:[/b] %s → %s[/color]" % [r.pergunta.texto, r.candidato.nome])
		if not r.get("ampliacao", {}).is_empty():
			_log("[color=#c9a0ff][b]A investigação se amplia.[/b] %s Nova pergunta: %s[/color]" % [r.ampliacao.revelacao, r.ampliacao.pergunta.texto])
	else:
		var custo := Caso.penalidade_palpite()
		if membrana != null:
			membrana.alterar(custo, "palpite_errado")
		_log("[color=#e0574a][b]Acusação errada:[/b] %s não bate com tudo. A Membrana cai %d.[/color]" % [r.candidato.nome, -custo])
	return r


# --- Pista central (docs/14, inspirado no GUMSHOE de The Esoterrorists) ---------
# Design do jogo, não do livro: quem tem o treino certo e está no lugar certo encontra a
# pista sem rolar dados. Numa perícia de DT simples (15), é de graça; nas mais difíceis,
# o agente gasta PE (1 a cada 5 de DT acima de 15), como os pontos de habilidade do GUMSHOE.
# Os dados ficam para quem não tem o treino, e para o tempo e o perigo da cena.
const DT_PISTA_GRATIS := 15
const DT_POR_PE := 5


## Custo em PE para examinar o ponto com a perícia, ou -1 se o agente não pode (sem treino).
func custo_examinar(a: Agente, ponto_id: String, pericia: String) -> int:
	var p := ponto(ponto_id)
	if a == null or p.is_empty() or not ponto_id in pontos_restantes or not p.pericias.has(pericia):
		return -1
	if not a.pericias.has(pericia):
		return -1
	return maxi(0, int(ceil(float(int(p.pericias[pericia]) - DT_PISTA_GRATIS) / DT_POR_PE)))


## A perícia mais barata para examinar o ponto ("" se o agente não tem treino em nenhuma).
func melhor_pericia_para_examinar(a: Agente, ponto_id: String) -> String:
	var melhor := ""
	var menor := 99
	for per in ponto(ponto_id).get("pericias", {}):
		var c := custo_examinar(a, ponto_id, per)
		if c >= 0 and c < menor:
			melhor = per
			menor = c
	return melhor


## Examinar: a pista central do ponto, sem teste. Gasta a ação e os PE do custo.
## Retorna {pista, custo} ou {} se inválido (sem treino, sem PE, ponto já vasculhado).
func examinar(ponto_id: String, pericia: String) -> Dictionary:
	var a := agente_atual()
	var custo := custo_examinar(a, ponto_id, pericia)
	if custo < 0 or (custo > 0 and not a.gastar_pe(custo)):
		return {}
	var p := ponto(ponto_id)
	_log("%s examina [b]%s[/b] com o treino em %s%s: pista central, sem teste." % [a.nome, p.nome, ruleset.pericia(pericia).nome,
		"" if custo == 0 else " (%d PE)" % custo])
	var texto := _encontrar_pista(a, ponto_id)
	var t: Dictionary = _trilha.get_or_add(a, {"sucessos": 0, "dados": 0})
	t.sucessos += 1
	_acao_concluida()
	return {"pista": texto, "custo": custo, "pericia": pericia}


## Facilitar Investigação: um teste que muda a cena; se passar, cada aliado recebe +2 no
## próximo Procurar Pistas (não acumula). Presteza Atlética: 1 PE, usa FOR ou AGI e dá +1 dado
## ao primeiro aliado que usar o bônus. Intuição Paranormal soma INT ou PRE.
func facilitar(opcao_id: String, pericia: String, pe_foco: int = 0, opcoes: Dictionary = {}) -> Dictionary:
	var a := agente_atual()
	var o := opcao_facilitar(opcao_id)
	if a == null or o.is_empty() or not o.pericias.has(pericia):
		return {}
	var op := opcoes.duplicate()
	var presteza: bool = op.get("presteza_atletica", false)
	if presteza:
		if not a.tem_habilidade("presteza_atletica") or not a.gastar_pe(1, true):
			return {}
		op["atributo_base"] = "for" if a.atributo("for") >= a.atributo("agi") else "agi"
	if a.tem_habilidade("intuicao_paranormal"):
		op["bonus_extra"] = int(op.get("bonus_extra", 0)) + maxi(a.atributo("int"), a.atributo("pre"))
	if _atributo_forcado != "":
		op["atributo_base"] = _atributo_forcado
	var teste := a.testar(dados, pericia, int(o.pericias[pericia]), pe_foco, op)
	if teste == null:
		return {}
	_log("%s tenta: %s (%s): %s" % [a.nome, o.texto, ruleset.pericia(pericia).nome, teste.descrever()])
	if teste.sucesso:
		var bonus := int(_cfg.facilitar.bonus)
		for aliado in agentes:
			if aliado != a:
				_facilitar[aliado] = bonus
		_presteza_pendente = presteza
		_log("[color=#7fd3c7]A cena fica mais fácil: aliados recebem +%d no próximo Procurar Pistas.[/color]" % bonus)
	_acao_concluida()
	return {"teste": teste, "sucesso": teste.sucesso}


## Ajudar (p.86): teste contra DT 10; passando, o aliado recebe +1 (+1 a cada 10 acima)
## no próximo teste. Teimoso não ajuda nem recebe ajuda. Espírito Cívico: +2 por 1 PE.
func ajudar(alvo: Agente, pericia: String, espirito_civico: bool = false) -> Dictionary:
	var a := agente_atual()
	if a == null or alvo == a or not alvo in agentes:
		return {}
	if not a.efeitos("sem_ajuda").is_empty() or not alvo.efeitos("sem_ajuda").is_empty():
		return {}
	var cfg: Dictionary = _cfg.ajuda
	var teste := a.testar(dados, pericia, int(cfg.dt))
	if teste == null:
		return {}
	var bonus := 0
	if teste.sucesso:
		bonus = int(cfg.bonus) + maxi(0, (teste.total - int(cfg.dt)) / 10) * int(cfg.bonus_por_10_acima)
		if espirito_civico and a.tem_habilidade("espirito_civico") and a.gastar_pe(1, true):
			bonus += 2
		_ajuda[alvo] = maxi(int(_ajuda.get(alvo, 0)), bonus)
	_log("%s ajuda %s (%s): %s%s" % [a.nome, alvo.nome, ruleset.pericia(pericia).nome, teste.descrever(), "  → +%d" % bonus if bonus > 0 else ""])
	_acao_concluida()
	return {"teste": teste, "sucesso": teste.sucesso, "bonus": bonus}


## Ações extras por habilidade (2 PE): Incansável (uma vez por cena, a ação usa FOR ou AGI),
## Pensamento Ágil (uma vez por rodada) e Guiado pelo Paranormal (uma vez por cena).
func acao_extra(habilidade: String) -> bool:
	var a := agente_atual()
	if a == null or not a.tem_habilidade(habilidade):
		return false
	var chave := "%s:%s" % [a.id if a.id != "" else a.nome, habilidade]
	match habilidade:
		"incansavel", "guiado_pelo_paranormal":
			if _usos_cena.has(chave):
				return false
		"pensamento_agil":
			if _usos_rodada.has(chave):
				return false
		_:
			return false
	if not a.gastar_pe(2, true):
		return false
	if habilidade == "pensamento_agil":
		_usos_rodada[chave] = true
	else:
		_usos_cena[chave] = true
	if habilidade == "incansavel":
		_atributo_forcado = "for" if a.atributo("for") >= a.atributo("agi") else "agi"
	_acoes_extras += 1
	_log("%s usa %s: uma ação a mais." % [a.nome, a.ruleset.poder(a.classe_id, habilidade).nome])
	return true


## Na Trilha Certa: depois de achar uma pista, paga PE para dados extras no próximo teste
## (1 PE por sucesso seguido; o bônus acumula). Pode ser chamado no turno seguinte do agente.
func pagar_na_trilha_certa(a: Agente) -> bool:
	if not a.tem_habilidade("na_trilha_certa") or not _trilha.has(a):
		return false
	var t: Dictionary = _trilha[a]
	if t.sucessos <= 0 or not a.gastar_pe(t.sucessos, t.sucessos == 1):
		return false
	t.dados += t.sucessos
	_log("%s segue a trilha certa: +%d dado(s) no próximo teste." % [a.nome, t.dados])
	return true


## Passa o turno sem agir.
func passar() -> void:
	if agente_atual() != null:
		_acao_concluida()


func encerrar(motivo: String = "os agentes deixaram o local") -> void:
	if encerrada:
		return
	encerrada = true
	motivo_fim = motivo
	_log("[b]Fim da cena:[/b] %s. Pistas encontradas: %d de %d." % [motivo, pistas_encontradas.size(), cena.pontos.size()])
	terminou.emit(resultado())


func _estourar_urgencia() -> void:
	urgencia_estourada = true
	var opcoes: Array = DadosJogo.ler("cenas_investigacao").penalidades_urgencia
	penalidade = opcoes[dados.rolar(opcoes.size()) - 1]
	if membrana != null:
		membrana.registrar("urgencia_estourada")
	_log("[color=#e0574a][b]O tempo acabou![/b] %s[/color]" % penalidade.texto)
	encerrar("a urgência se esgotou")


func resultado() -> Dictionary:
	return {"pistas": pistas_encontradas.duplicate(true), "perguntas": perguntas_respondidas.duplicate(true),
		"urgencia_estourada": urgencia_estourada, "penalidade": penalidade, "motivo": motivo_fim}
