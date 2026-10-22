class_name Sinais
extends RefCounted
## Os sinais da rede (docs/62, OR1) e o ponto de encontro de fachada (OR3). Na Base, a Ordem
## mostra três sinais, cada um com fonte, relato e confiança; o jogador escolhe qual investigar.
## Um sinal de confiança baixa pode ser alarme falso (não é paranormal) e, se for real, rende
## mais prestígio. Tudo sai da semente, sem gastar os Dados, igual em qualquer máquina.
##   Sinais.gerar(semente_base) -> [sinal, sinal, sinal]
##   Sinais.de(semente, confianca) -> {semente, fonte, relato, confianca, rotulo, alarme_falso, elemento, explicacao}
##   Sinais.fachada(semente) -> {lugar, senha, resposta}

const NIVEIS := ["baixa", "media", "alta"]


static func _escolher(lista: Array, semente: int, sal: String):
	return lista[absi(hash("%d|%s" % [semente, sal])) % lista.size()]


## O sinal de uma missão com esta semente e este nível de confiança.
static func de(semente: int, confianca: String) -> Dictionary:
	var d := DadosJogo.ler("sinais")
	var el := Caso.gerar(Dados.new(semente)).elemento   # o mesmo caso que Missao.nova gera
	var conf: Dictionary = d.confianca.get(confianca, d.confianca.media)
	var falso := absi(hash("%d|alarme" % semente)) % 100 < int(conf.alarme_falso)
	return {"semente": semente, "fonte": String(_escolher(d.fontes, semente, "fonte")),
		"relato": String(_escolher(d.relatos[el], semente, "relato")), "confianca": confianca,
		"rotulo": String(conf.rotulo), "alarme_falso": falso, "elemento": el,
		"explicacao": String(_escolher(d.explicacoes[el], semente, "explicacao")),
		"bonus_pp": int(conf.get("bonus_pp", 0)), "subgenero": Culto.subgenero(semente)}


## Três sinais, um de cada nível de confiança, com sementes tiradas da semente da Base e
## relatos diferentes entre si.
static func gerar(semente_base: int) -> Array:
	var lista: Array = []
	var relatos: Array = []
	for i in NIVEIS.size():
		var sinal := {}
		for k in 30:
			var s := absi(hash("%d|sinal|%d|%d" % [semente_base, i, k])) % 1000000
			sinal = de(s, NIVEIS[(i + absi(semente_base)) % NIVEIS.size()])
			if not sinal.relato in relatos:
				break
		relatos.append(sinal.relato)
		lista.append(sinal)
	return lista


## O ponto de encontro do briefing (OR3): um lugar banal, com senha e resposta.
static func fachada(semente: int) -> Dictionary:
	return (_escolher(DadosJogo.ler("sinais").fachadas, semente, "fachada") as Dictionary).duplicate()


## O texto do sinal num cartão: "Post viral · confiança baixa · Perseguição — um açougue…".
static func resumo(s: Dictionary) -> String:
	var sub := String(s.get("subgenero", "classico"))
	var marca := "" if sub == "classico" else " · " + String(Culto.dados_subgenero(sub).nome)
	if s.get("vilao", {}).get("final", false):
		marca += " · O VILÃO"
	return "%s · confiança %s%s\n%s" % [s.fonte, s.rotulo, marca, String(s.relato).left(1).to_upper() + String(s.relato).substr(1) + "."]
