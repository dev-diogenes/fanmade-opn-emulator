class_name ResultadoAtaque
extends RefCounted

var atacante: Ser
var alvo: Ser
var arma: Dictionary
var teste: ResultadoTeste
var acertou := false
var critico := false
var dano := 0           ## Dano efetivamente sofrido (após resistência)
var dano_bruto := 0     ## Dano rolado, antes da resistência
var pe_gasto := 0
var critico_ignorado := false   ## Anatomia Insana / proteção letárgica anulou o crítico
var reacao := ""        ## Reação usada pelo alvo: "esquiva", "bloqueio", "contra_ataque" ou ""
var contra_ataque: ResultadoAtaque
var ataque_adicional: ResultadoAtaque
var ataques_extras: Array = []   ## Ataques a mais da mesma ação (ameaças com "Corpo a corpo x2")   ## Ódio Incontrolável (discente): o segundo golpe do Agredir


func descrever() -> String:
	if teste == null:
		return "%s não pôde atacar" % atacante.nome
	var txt := "%s ataca %s com %s: %s" % [atacante.nome, alvo.nome, arma.get("nome", "?"), teste.descrever()]
	if acertou:
		txt += " → %d de dano%s" % [dano, " (CRÍTICO)" if critico else ""]
	return txt
