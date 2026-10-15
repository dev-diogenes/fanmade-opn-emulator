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


## Ficha de ameaça pronta para Ameaca.criar() e a arma dela.
static func ameaca(ruleset: Ruleset, ameaca_id: String) -> Dictionary:
	var d := ler("ameacas")
	assert(d.ameacas.has(ameaca_id), "Ameaça desconhecida: %s" % ameaca_id)
	var info: Dictionary = d.ameacas[ameaca_id]
	var arma: Dictionary = d.armas_extras.get(info.arma, {})
	if arma.is_empty():
		arma = ruleset.arma(info.arma)
	return {"id": ameaca_id, "nome": info.nome, "ficha": info.ficha, "arma": arma, "nivel": int(info.nivel), "chefe": info.get("chefe", false)}
