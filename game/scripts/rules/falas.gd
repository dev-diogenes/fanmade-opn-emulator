class_name Falas
extends RefCounted
## Frases curtas (AG6, docs/75): a linha que o agente diz conforme o estado (ferido, perturbado,
## um aliado caído, a fobia). Só voz: não mudam regras. Os textos ficam em data/jogo/falas.json;
## a fobia usa as frases de traumas.json. A escolha sai do nome, do estado e de um contador, sem
## gastar os Dados (igual no online).
##   Falas.de(agente, "aliado_caiu", 3, {"nome": "Rita"}) -> "Rita! Segura aí, eu cubro."

const ESTADOS := ["ferido", "perturbado", "aliado_caiu", "fobia"]


## A fala de `a` no `estado` ("" se não houver). `n` varia a escolha; `extra` troca {chave} no
## texto e, na fobia, diz o elemento ({"elemento": "sangue"}).
static func de(a: Agente, estado: String, n: int, extra: Dictionary = {}) -> String:
	var lista: Array = []
	if estado == "fobia":
		lista = DadosJogo.ler("traumas").get("fobias", {}).get(String(extra.get("elemento", "")), {}).get("frases", [])
	else:
		var por_classe: Dictionary = DadosJogo.ler("falas").get("estados", {}).get(estado, {})
		lista = por_classe.get(a.classe_id, por_classe.get("geral", []))
	if lista.is_empty():
		return ""
	var texto := String(lista[absi(hash("%s|%s|%d" % [a.nome, estado, n])) % lista.size()])
	for k in extra:
		texto = texto.replace("{%s}" % k, String(extra[k]))
	return texto


## O estado de que o agente fala agora, pela ordem de urgência ("" se nenhum): perturbado (SAN
## na metade ou menos) antes de ferido (PV na metade ou menos).
static func estado_de(a: Agente) -> String:
	if a.tem_sanidade and a.san_maximo > 0 and a.san * 2 <= a.san_maximo:
		return "perturbado"
	if a.pv_maximo > 0 and a.pv * 2 <= a.pv_maximo:
		return "ferido"
	return ""
