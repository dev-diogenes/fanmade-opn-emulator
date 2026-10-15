class_name Combate
extends RefCounted
## Cena de combate sem interface: iniciativa, turnos, ataques, reações e
## regras opcionais (cap. 4, p.92–99; cap. 6, p.184). O posicionamento em
## grade (FTK II) entra na Fase 2, numa camada acima desta.

signal turno_iniciado(ser: Ser)
signal ataque_resolvido(resultado: ResultadoAtaque)
signal lesao_sofrida(agente: Agente, atributo_id: String)
signal inspiracao_disponivel(morto: Agente, efeito: String)
signal combate_encerrado(lado_vencedor: String)

const REACOES := ["bloqueio", "esquiva", "contra_ataque"]
const ORDEM_LESAO := ["agi", "for", "int", "pre", "vig"]   ## 1d6: 1..5; 6 = nenhuma (p.184)
const INSPIRACOES := ["chamas_da_vinganca", "chamas_da_vinganca", "forca_do_odio", "forca_do_odio",
	"mente_em_luto", "mente_em_luto", "resoluto", "resoluto", "loucura_selvagem", "loucura_selvagem"]  ## 1d10 (p.184-185)

var ruleset: Ruleset
var dados: Dados
## Regras opcionais ativas nesta run: {"lesoes": true, "inspiracao_resoluta": true}
var regras: Dictionary = {}
var participantes: Array[Ser] = []
var ordem: Array[Ser] = []
var iniciativas: Dictionary = {}   ## Ser -> total de Iniciativa
var rodada := 0
var encerrado := false
## Inspirações sorteadas aguardando o jogador escolher o aliado: [{morto, efeito}]
var inspiracoes_pendentes: Array[Dictionary] = []

var _indice := -1
var _reacoes_declaradas: Dictionary = {}   ## Ser -> {"tipo": String, "arma": Dictionary}
var _mortos_inspiradores: Array[Agente] = []


func _init(p_ruleset: Ruleset, p_dados: Dados, p_regras: Dictionary = {}) -> void:
	ruleset = p_ruleset
	dados = p_dados
	regras = p_regras


func adicionar(ser: Ser) -> void:
	participantes.append(ser)
	ser.morreu.connect(_ao_morrer)


# --- Iniciativa e turnos ---------------------------------------------------

## Rola Iniciativa de todos e ordena do maior para o menor (p.93).
## Empates: maior Agilidade primeiro; persistindo, rolagem de desempate.
## Simplificação: cada ameaça rola a própria Iniciativa (o livro usa um teste só para todas).
func iniciar() -> void:
	var desempate: Dictionary = {}
	for ser in participantes:
		var r := Teste.rolar(dados, ser.dados_da_pericia("iniciativa"), ser.bonus_pericia("iniciativa"), 0)
		iniciativas[ser] = r.total
		desempate[ser] = dados.rolar(20)
	ordem = participantes.duplicate()
	ordem.sort_custom(func(a: Ser, b: Ser) -> bool:
		if iniciativas[a] != iniciativas[b]:
			return iniciativas[a] > iniciativas[b]
		if a.atributo("agi") != b.atributo("agi"):
			return a.atributo("agi") > b.atributo("agi")
		return desempate[a] > desempate[b])
	rodada = 1
	_indice = -1


func ser_atual() -> Ser:
	return ordem[_indice] if _indice >= 0 and _indice < ordem.size() else null


## Avança para o próximo ser que pode agir e inicia o turno dele.
## Seres morrendo ou enlouquecendo também "iniciam turno" (é aí que a contagem avança).
func proximo_turno() -> Ser:
	if encerrado:
		return null
	for _tentativa in ordem.size():
		_indice += 1
		if _indice >= ordem.size():
			_indice = 0
			rodada += 1
			_sortear_inspiracoes()
		var ser := ordem[_indice]
		if ser.tem(Ser.MORTO):
			continue
		ser.iniciar_turno()
		_verificar_lesao(ser)
		if _verificar_fim():
			return null
		if ser.esta_fora_de_combate():
			continue
		turno_iniciado.emit(ser)
		return ser
	_verificar_fim()
	return null


# --- Reações (p.88) --------------------------------------------------------

## O alvo declara uma reação de defesa contra o PRÓXIMO ataque que sofrer.
## Uma por rodada; exige treino (bloqueio: Fortitude, esquiva: Reflexos, contra-ataque: Luta).
## `arma` só é usada no contra-ataque.
func declarar_reacao(ser: Ser, tipo: String, arma: Dictionary = {}) -> bool:
	if not tipo in REACOES or ser.reacao_usada or ser.esta_fora_de_combate():
		return false
	var pericia_exigida: String = {"bloqueio": "fortitude", "esquiva": "reflexos", "contra_ataque": "luta"}[tipo]
	if not ser.treinado_em(pericia_exigida):
		return false
	if tipo == "contra_ataque" and arma.get("ataque", "") != "corpo_a_corpo":
		return false
	_reacoes_declaradas[ser] = {"tipo": tipo, "arma": arma}
	return true


# --- Ataque ----------------------------------------------------------------

## Ataque com uma arma (dicionário no formato de armas.json).
## - `pe_foco`: PE gastos como Foco (+1 d20 cada). Só agentes gastam PE.
## - `opcoes`:
##     "ataque_especial": {"ataque": 5, "dano": 5}  — combatente (custo pelo NEX)
##     "combate_defensivo": true                     — −1 dado no ataque, +5 Defesa até o próximo turno
func atacar(atacante: Ser, alvo: Ser, arma_base: Dictionary, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoAtaque:
	var res := ResultadoAtaque.new()
	res.atacante = atacante
	res.alvo = alvo
	var arma: Dictionary = (atacante as Agente).arma_efetiva(arma_base) if atacante is Agente else arma_base
	res.arma = arma
	var mods := atacante.modificar_ataque(arma, alvo)
	var dados_extras := pe_foco + int(mods.dados_extras)
	var bonus_ataque := int(mods.bonus_ataque)
	var bonus_dano := int(mods.bonus_dano)
	var custo := pe_foco
	var no_minimo := false   # o gasto é só o Ataque Especial no custo mínimo (regra da p.33)

	if opcoes.has("ataque_especial"):
		if not atacante is Agente:
			return res
		var ae: Dictionary = (atacante as Agente).plano_ataque_especial(int(opcoes.ataque_especial.get("ataque", 0)), int(opcoes.ataque_especial.get("dano", 0)), arma)
		if ae.is_empty():
			return res
		custo += int(ae.custo)
		no_minimo = pe_foco == 0 and ae.minimo
		bonus_ataque += int(ae.bonus_ataque)
		bonus_dano += int(ae.bonus_dano)
	if opcoes.get("combate_defensivo", false):
		if not (atacante is Agente and not (atacante as Agente).efeitos("opcao_combate_defensivo").is_empty()):
			return res
		dados_extras -= 1

	if custo > 0:
		if not (atacante is Agente and (atacante as Agente).gastar_pe(custo, no_minimo)):
			return res
	res.pe_gasto = custo
	if opcoes.get("combate_defensivo", false):
		atacante.defesa_temporaria += 5

	# Reação declarada pelo alvo
	var reacao: Dictionary = _reacoes_declaradas.get(alvo, {})
	_reacoes_declaradas.erase(alvo)
	var eh_corpo_a_corpo: bool = arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo"
	var defesa := alvo.defesa()
	var rd_extra := 0
	if not reacao.is_empty():
		match reacao.tipo:
			"esquiva":
				defesa += alvo.bonus_pericia("reflexos")
				res.reacao = "esquiva"
			"bloqueio":
				if eh_corpo_a_corpo:
					rd_extra = _rd_bloqueio(alvo)
					res.reacao = "bloqueio"
			"contra_ataque":
				if eh_corpo_a_corpo:
					res.reacao = "contra_ataque"
		if res.reacao != "":
			alvo.reacao_usada = true

	var pericia_id: String = arma.get("pericia", "luta")
	res.teste = Teste.rolar(dados, atacante.dados_da_pericia(pericia_id), atacante.bonus_pericia(pericia_id) + bonus_ataque, defesa, dados_extras)
	res.acertou = res.teste.sucesso
	if res.acertou:
		var margem := int(arma.get("margem", 20)) - int(mods.margem)
		res.critico = res.teste.escolhido >= margem
		var mult := int(arma.get("multiplicador", 2)) if res.critico else 1
		var e := Dados.interpretar(arma.get("dano", "1d3"))
		var expressao := "%dd%d+%d" % [e.quantidade + int(mods.dados_dano_extra), e.faces, e.bonus]
		var dano := dados.rolar_expressao(expressao, mult) + bonus_dano
		if arma.get("soma_forca", false):
			dano += atacante.atributo("for")
		res.dano_bruto = maxi(1, dano)
		res.dano = aplicar_dano(alvo, res.dano_bruto, arma.get("tipo_dano", ""), rd_extra, atacante)
	elif res.reacao == "contra_ataque":
		res.contra_ataque = atacar(alvo, atacante, reacao.arma)
	ataque_resolvido.emit(res)
	_verificar_fim()
	return res


## Aplica dano já rolado: desconta resistência (tipo + `rd_extra`) e checa dano massivo (p.98).
## Retorna o dano efetivamente sofrido.
func aplicar_dano(alvo: Ser, dano: int, tipo_dano: String = "", rd_extra: int = 0, atacante: Ser = null) -> int:
	var final := maxi(0, dano - alvo.resistencia(tipo_dano) - rd_extra)
	if final <= 0:
		return 0
	alvo.registrar_atacante(atacante)
	alvo.sofrer_dano(final)
	if alvo is Agente and alvo.pv > 0 and final * 2 >= alvo.pv_maximo:
		var dt := 15 + 2 * (final / 10)
		var r := Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), dt)
		if not r.sucesso:
			alvo.sofrer_dano(alvo.pv)
	return final


func _rd_bloqueio(ser: Ser) -> int:
	var rd := ser.bonus_pericia("fortitude")
	if ser is Agente:
		for e in (ser as Agente).efeitos("bloqueio_soma_atributo"):
			rd += ser.atributo(e.atributo)
	return rd


# --- Regras opcionais ------------------------------------------------------

## Lesões (p.184): ao iniciar o turno morrendo pela 2ª vez na cena, teste de Vigor DT 10.
## Falhou: perde 1 ponto permanente num atributo sorteado por 1d6 (6 = nenhum).
func _verificar_lesao(ser: Ser) -> void:
	if not regras.get("lesoes", false) or not ser is Agente:
		return
	if not ser.tem(Ser.MORRENDO) or ser.turnos_morrendo() != 2:
		return
	var agente := ser as Agente
	var r := Teste.rolar(dados, agente.atributo("vig"), 0, 10)
	if r.sucesso:
		return
	var d6 := dados.rolar(6)
	if d6 > ORDEM_LESAO.size():
		return
	var attr_id: String = ORDEM_LESAO[d6 - 1]
	agente.atributos[attr_id] = maxi(0, int(agente.atributos.get(attr_id, 0)) - 1)
	agente.lesoes.append(attr_id)
	agente.recalcular_maximos()
	lesao_sofrida.emit(agente, attr_id)


func _ao_morrer(ser: Ser) -> void:
	if regras.get("inspiracao_resoluta", false) and ser is Agente:
		_mortos_inspiradores.append(ser as Agente)


## Inspiração Resoluta (p.184): no início de cada rodada, cada agente morto na cena rola 1d10.
func _sortear_inspiracoes() -> void:
	for morto in _mortos_inspiradores:
		var efeito: String = INSPIRACOES[dados.rolar(10) - 1]
		inspiracoes_pendentes.append({"morto": morto, "efeito": efeito})
		inspiracao_disponivel.emit(morto, efeito)


## Concede uma inspiração pendente a um aliado vivo.
func aplicar_inspiracao(indice: int, aliado: Agente) -> bool:
	if indice < 0 or indice >= inspiracoes_pendentes.size() or aliado.tem(Ser.MORTO):
		return false
	var insp: Dictionary = inspiracoes_pendentes.pop_at(indice)
	var morto: Agente = insp.morto
	match insp.efeito:
		"chamas_da_vinganca":
			var assassino := morto.ultimo_atacante()
			if assassino != null:
				var contra: Dictionary = aliado.mods_cena.get_or_add("ataque_contra", {})
				contra[assassino] = int(contra.get(assassino, 0)) + 5
		"forca_do_odio":
			var attrs: Dictionary = aliado.mods_cena.get_or_add("atributos", {})
			attrs["for"] = int(attrs.get("for", 0)) + 2
			aliado.acoes_padrao_extras += 1
		"mente_em_luto":
			var res: Dictionary = aliado.mods_cena.get_or_add("resistencias", {})
			res["mental"] = maxi(int(res.get("mental", 0)), 10)
		"resoluto":
			aliado.curar(dados.rolar_expressao("4d8+4"))
			aliado.recuperar_pe(dados.rolar_expressao("2d6"))
		"loucura_selvagem":
			aliado.condicoes.erase(Ser.PARALISADO)
			aliado.acoes_padrao_extras += 1
	return true


# --- Fim -------------------------------------------------------------------

## Lado que ainda tem alguém de pé, ou "" se o combate continua.
func lado_vencedor() -> String:
	var de_pe: Dictionary = {}
	for ser in participantes:
		if not ser.esta_fora_de_combate():
			de_pe[ser.lado] = true
	if de_pe.size() == 1:
		return de_pe.keys()[0]
	if de_pe.is_empty():
		return "nenhum"
	return ""


func _verificar_fim() -> bool:
	if encerrado:
		return true
	var vencedor := lado_vencedor()
	if vencedor != "":
		encerrado = true
		for ser in participantes:
			ser.encerrar_cena()
		combate_encerrado.emit(vencedor)
		return true
	return false
