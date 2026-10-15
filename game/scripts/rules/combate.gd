class_name Combate
extends RefCounted
## Cena de combate sem interface: iniciativa, turnos e ataques (cap. 4, p.92–99).
## O posicionamento em grade (FTK II) entra na Fase 2, numa camada acima desta.

signal turno_iniciado(ser: Ser)
signal ataque_resolvido(resultado: ResultadoAtaque)
signal combate_encerrado(lado_vencedor: String)

var ruleset: Ruleset
var dados: Dados
var participantes: Array[Ser] = []
var ordem: Array[Ser] = []
var iniciativas: Dictionary = {}   ## Ser -> total de Iniciativa
var rodada := 0
var _indice := -1
var encerrado := false


func _init(p_ruleset: Ruleset, p_dados: Dados) -> void:
	ruleset = p_ruleset
	dados = p_dados


func adicionar(ser: Ser) -> void:
	participantes.append(ser)


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
		var ser := ordem[_indice]
		if ser.tem(Ser.MORTO):
			continue
		ser.iniciar_turno()
		if _verificar_fim():
			return null
		if ser.esta_fora_de_combate():
			continue
		turno_iniciado.emit(ser)
		return ser
	_verificar_fim()
	return null


## Ataque com uma arma (dicionário no formato de armas.json).
## `pe_foco`: PE gastos como Foco (+1 d20 cada). Só agentes gastam PE.
func atacar(atacante: Ser, alvo: Ser, arma: Dictionary, pe_foco: int = 0) -> ResultadoAtaque:
	var res := ResultadoAtaque.new()
	res.atacante = atacante
	res.alvo = alvo
	res.arma = arma
	var pericia_id: String = arma.get("pericia", "luta")
	if pe_foco > 0:
		if not (atacante is Agente and (atacante as Agente).gastar_pe(pe_foco)):
			return res
		res.pe_gasto = pe_foco
	res.teste = Teste.rolar(dados, atacante.dados_da_pericia(pericia_id), atacante.bonus_pericia(pericia_id), alvo.defesa(), pe_foco)
	res.acertou = res.teste.sucesso
	if res.acertou:
		res.critico = res.teste.escolhido >= int(arma.get("margem", 20))
		var mult := int(arma.get("multiplicador", 2)) if res.critico else 1
		res.dano = dados.rolar_expressao(arma.get("dano", "1d3"), mult)
		if arma.get("soma_forca", false):
			res.dano += atacante.atributo("for")
		res.dano = maxi(1, res.dano)
		alvo.sofrer_dano(res.dano)
	ataque_resolvido.emit(res)
	_verificar_fim()
	return res


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
