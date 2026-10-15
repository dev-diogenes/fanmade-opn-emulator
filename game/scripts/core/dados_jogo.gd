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
	var info: Dictionary = d.ameacas[ameaca_id]
	var arma: Dictionary = d.armas_extras.get(info.arma, {})
	if arma.is_empty():
		arma = ruleset.arma(info.arma)
	return {"id": ameaca_id, "nome": info.nome, "ficha": info.ficha, "arma": arma, "nivel": int(info.nivel), "chefe": info.get("chefe", false),
		"vd": int(info.ficha.get("vd", 10))}


## Nível de ameaça (1 a 4) a partir do VD, para ordenar e equilibrar encontros.
static func nivel_por_vd(vd: int) -> int:
	if vd <= 20:
		return 1
	if vd <= 40:
		return 2
	if vd <= 80:
		return 3
	return 4
