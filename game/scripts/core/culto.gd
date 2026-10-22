class_name Culto
extends RefCounted
## Cultos, o vilão que liga os casos e o subgênero da missão (docs/71, OR6 e OR7). Tudo sai
## de sementes, sem gastar os Dados: igual em qualquer máquina e no online.
##   Culto.gerar(semente, elemento) -> {nome, elemento, fachada, estrutura, metodo, sinal, efeito}
##   Culto.vilao(semente) -> {nome, derrotados}
##   Culto.recorte(vilao, culto, semente) -> String
##   Culto.subgenero(semente) -> id; Culto.dados_subgenero(id) -> {nome, texto, cfg?, membrana_por_turno?}


static func _escolher(lista: Array, semente: int, sal: String):
	return lista[absi(hash("%d|%s" % [semente, sal])) % lista.size()]


## O culto de um caso: os cinco eixos (elemento, fachada, estrutura, método, sinal) e o efeito
## somado da estrutura e do método.
static func gerar(semente: int, elemento: String) -> Dictionary:
	var d := DadosJogo.ler("cultos")
	var nucleos: Array = d.nomes.nucleos.get(elemento, d.nomes.nucleos.medo)
	var fachada: Dictionary = _escolher(d.fachadas, semente, "fachada")
	var estrutura: Dictionary = _escolher(d.estruturas, semente, "estrutura")
	var metodo: Dictionary = _escolher(d.metodos, semente, "metodo")
	var efeito: Dictionary = (estrutura.get("efeito", {}) as Dictionary).duplicate()
	efeito.merge(metodo.get("efeito", {}))
	return {
		"nome": "%s %s" % [_escolher(d.nomes.prefixos, semente, "prefixo"), _escolher(nucleos, semente, "nucleo")],
		"elemento": elemento,
		"fachada": fachada.duplicate(), "estrutura": estrutura.duplicate(), "metodo": metodo.duplicate(),
		"sinal": String(_escolher(d.sinais.get(elemento, d.sinais.medo), semente, "sinal")),
		"efeito": efeito,
	}


## Uma linha sobre o culto, para o quadro e o relatório.
static func resumo(c: Dictionary) -> String:
	if c.is_empty():
		return ""
	return "%s: %s, organizado em %s, que %s. Sinal: %s." % [c.nome, c.fachada.nome, c.estrutura.nome, c.metodo.nome, c.sinal]


## O vilão da carreira: uma empresa de fachada que liga os cultos.
static func vilao(semente: int, derrotados: int = 0) -> Dictionary:
	var v: Dictionary = DadosJogo.ler("cultos").vilao
	return {"nome": "%s %s" % [_escolher(v.empresas, semente, "empresa%d" % derrotados), _escolher(v.sobrenomes, semente, "sobrenome%d" % derrotados)],
		"derrotados": derrotados, "semente": semente}


## A manchete de um recorte que liga o culto ao vilão.
static func recorte(v: Dictionary, c: Dictionary, semente: int) -> String:
	var modelo := String(_escolher(DadosJogo.ler("cultos").vilao.recortes, semente, "recorte"))
	return modelo.replace("{empresa}", String(v.get("nome", "a empresa"))).replace("{fachada}", String(c.get("fachada", {}).get("nome", "um grupo"))) \
		.replace("{sinal}", String(c.get("sinal", "sinais estranhos")))


## A missão é ligada ao vilão? Metade delas (cultos.json, chance_de_ligar).
static func liga_ao_vilao(semente: int) -> bool:
	return absi(hash("%d|vilao" % semente)) % 100 < int(DadosJogo.ler("cultos").vilao.get("chance_de_ligar", 50))


## O subgênero da missão, pelos pesos de subgeneros.json.
static func subgenero(semente: int) -> String:
	var pesos: Dictionary = DadosJogo.ler("subgeneros").pesos
	var total := 0
	for k in pesos:
		total += int(pesos[k])
	var r := absi(hash("%d|subgenero" % semente)) % maxi(1, total)
	for k in pesos:
		r -= int(pesos[k])
		if r < 0:
			return String(k)
	return "classico"


static func dados_subgenero(id: String) -> Dictionary:
	return DadosJogo.ler("subgeneros").lista.get(id, DadosJogo.ler("subgeneros").lista.classico)


## Junta `extra` em `base` (dicionários dentro de dicionários), sem mexer no `base` original.
static func mesclar(base: Dictionary, extra: Dictionary) -> Dictionary:
	var r := base.duplicate(true)
	for k in extra:
		if r.get(k) is Dictionary and extra[k] is Dictionary:
			r[k] = mesclar(r[k], extra[k])
		else:
			r[k] = extra[k]
	return r
