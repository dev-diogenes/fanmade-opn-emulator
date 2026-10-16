class_name DadosJogo
extends RefCounted
## Lê os JSON de design do jogo em res://data/jogo/ (com cache).

const PASTA := "res://data/jogo"

static var _cache: Dictionary = {}


static func ler(nome: String) -> Dictionary:
	if _cache.has(nome):
		return _cache[nome]
	var caminho := PASTA.path_join(nome + ".json")
	var dados = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	assert(dados is Dictionary, "JSON inválido: %s" % caminho)
	_cache[nome] = dados
	return dados


## Ficha de ameaça pronta para Ameaca.criar() e a arma dela. Procura primeiro nas ameaças
## criadas para o jogo (data/jogo/ameacas.json) e depois nas do livro (ruleset).
static func ameaca(ruleset: Ruleset, ameaca_id: String) -> Dictionary:
	var d := ler("ameacas")
	if not d.ameacas.has(ameaca_id):
		var b := ruleset.ameaca(ameaca_id)
		assert(not b.is_empty(), "Ameaça desconhecida: %s" % ameaca_id)
		var ataques: Array = b.ficha.get("ataques", [])
		return {"id": ameaca_id, "nome": b.nome, "ficha": b.ficha, "arma": ataques[0] if not ataques.is_empty() else ruleset.arma("desarmado"),
			"nivel": nivel_por_vd(int(b.vd)), "chefe": false, "vd": int(b.vd)}
	return info_ameaca(ruleset, ameaca_id, d.ameacas[ameaca_id])


## Monta a ficha pronta a partir de uma ameaça no formato do jogo ({nome, nivel, arma, ficha}).
## `arma` pode ser o id de uma arma (do ruleset ou de armas_extras) ou a própria arma; se a ficha
## tiver "ataques" (formato do livro), vale o primeiro. Usada também pelas missões da comunidade.
static func info_ameaca(ruleset: Ruleset, ameaca_id: String, info: Dictionary) -> Dictionary:
	var ficha: Dictionary = info.get("ficha", {})
	var arma: Dictionary = {}
	if not ficha.get("ataques", []).is_empty():
		arma = ficha.ataques[0]
	elif info.get("arma") is Dictionary:
		arma = info.arma
	else:
		arma = ler("ameacas").armas_extras.get(String(info.get("arma", "")), {})
		if arma.is_empty():
			arma = ruleset.arma(String(info.get("arma", "desarmado")))
	var vd := int(ficha.get("vd", info.get("vd", 10)))
	return {"id": ameaca_id, "nome": info.get("nome", ameaca_id), "ficha": ficha, "arma": arma,
		"nivel": int(info.get("nivel", nivel_por_vd(vd))), "chefe": info.get("chefe", false), "vd": vd}


## Nível de ameaça (1 a 4) a partir do VD, para ordenar e equilibrar encontros.
static func nivel_por_vd(vd: int) -> int:
	if vd <= 20:
		return 1
	if vd <= 40:
		return 2
	if vd <= 80:
		return 3
	return 4
