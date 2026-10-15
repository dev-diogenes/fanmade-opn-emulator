class_name ResultadoAtaque
extends RefCounted

var atacante: Ser
var alvo: Ser
var arma: Dictionary
var teste: ResultadoTeste
var acertou := false
var critico := false
var dano := 0
var pe_gasto := 0


func descrever() -> String:
	if teste == null:
		return "%s não pôde atacar" % atacante.nome
	var txt := "%s ataca %s com %s: %s" % [atacante.nome, alvo.nome, arma.get("nome", "?"), teste.descrever()]
	if acertou:
		txt += " → %d de dano%s" % [dano, " (CRÍTICO)" if critico else ""]
	return txt
