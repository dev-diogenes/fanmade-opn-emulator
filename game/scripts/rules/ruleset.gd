class_name Ruleset
extends RefCounted
## Base de um conjunto de regras (ADR 0002). Os dados vêm de
## `res://data/rulesets/<id>/` e as fórmulas que mudam entre versões
## ficam em métodos que as subclasses sobrescrevem.

const RAIZ_PADRAO := "res://data/rulesets"

var id := ""
var nome := ""
## Conteúdo bruto de cada arquivo, indexado pelo nome sem extensão ("pericias", "classes"…).
var dados: Dictionary = {}

var _pericias: Dictionary = {}
var _classes: Dictionary = {}
var _armas: Dictionary = {}
var _graus: Dictionary = {}


## Carrega o manifesto e os arquivos listados. Retorna OK ou um código de erro.
func carregar(pasta: String) -> Error:
	var manifesto = _ler_json(pasta.path_join("ruleset.json"))
	if manifesto == null:
		return ERR_FILE_NOT_FOUND
	id = manifesto.get("id", "")
	nome = manifesto.get("nome", "")
	for arquivo in manifesto.get("arquivos", []):
		var conteudo = _ler_json(pasta.path_join(arquivo))
		if conteudo == null:
			return ERR_PARSE_ERROR
		dados[String(arquivo).get_basename()] = conteudo
	_indexar()
	return OK


func _indexar() -> void:
	for p in dados.get("pericias", {}).get("pericias", []):
		_pericias[p.id] = p
	for g in dados.get("pericias", {}).get("graus", []):
		_graus[g.id] = int(g.bonus)
	for c in dados.get("classes", {}).get("classes", []):
		_classes[c.id] = c
	for a in dados.get("armas", {}).get("armas", []):
		_armas[a.id] = a


static func _ler_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		push_error("Arquivo de ruleset não encontrado: %s" % caminho)
		return null
	var texto := FileAccess.get_file_as_string(caminho)
	var json := JSON.new()
	if json.parse(texto) != OK:
		push_error("JSON inválido em %s (linha %d): %s" % [caminho, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


# --- Consultas -------------------------------------------------------------

func pericia(pericia_id: String) -> Dictionary:
	assert(_pericias.has(pericia_id), "Perícia desconhecida: %s" % pericia_id)
	return _pericias[pericia_id]


func tem_pericia(pericia_id: String) -> bool:
	return _pericias.has(pericia_id)


func classe(classe_id: String) -> Dictionary:
	assert(_classes.has(classe_id), "Classe desconhecida: %s" % classe_id)
	return _classes[classe_id]


func arma(arma_id: String) -> Dictionary:
	assert(_armas.has(arma_id), "Arma desconhecida: %s" % arma_id)
	return _armas[arma_id]


func bonus_grau(grau: String) -> int:
	return _graus.get(grau, 0)


func dt_regra(chave: String) -> int:
	return int(dados.get("dificuldades", {}).get("regras", {}).get(chave, 0))


# --- Fórmulas (sobrescrever em rulesets que mudam a regra) ----------------

## Atributo-base de uma perícia.
func atributo_da_pericia(pericia_id: String) -> String:
	return pericia(pericia_id).atributo


## Limite de PE gastos por turno para um NEX.
func limite_pe(nex: int) -> int:
	var tabela: Dictionary = dados.progressao_nex.limite_pe_por_turno
	var melhor := 0
	for chave in tabela:
		if int(chave) <= nex:
			melhor = maxi(melhor, int(tabela[chave]))
	return melhor


## Quantos "níveis de exposição" o NEX representa (5% = 1, 10% = 2… 99% = 20).
func niveis_de_exposicao(nex: int) -> int:
	return 20 if nex >= 99 else maxi(1, nex / 5)


func pv_max(classe_id: String, nex: int, atributos: Dictionary) -> int:
	return _progressao(classe(classe_id).pv, nex, atributos)


func pe_max(classe_id: String, nex: int, atributos: Dictionary) -> int:
	return _progressao(classe(classe_id).pe, nex, atributos)


func san_max(classe_id: String, nex: int, _atributos: Dictionary) -> int:
	var s: Dictionary = classe(classe_id).san
	return int(s.inicial) + (niveis_de_exposicao(nex) - 1) * int(s.por_nex)


## inicial + atributo, e (por_nex + atributo) a cada nível de exposição após o primeiro (p.35).
func _progressao(regra: Dictionary, nex: int, atributos: Dictionary) -> int:
	var attr := int(atributos.get(regra.get("atributo", ""), 0))
	var extras := niveis_de_exposicao(nex) - 1
	return int(regra.inicial) + attr + extras * (int(regra.por_nex) + attr)


func defesa_base(atributos: Dictionary) -> int:
	var d: Dictionary = dados.classes.derivadas
	return int(d.defesa_base) + int(atributos.get(d.defesa_atributo, 0))


## Valida a distribuição inicial de atributos (p.24). Retorna a lista de erros (vazia = válido).
func validar_atributos_iniciais(atributos: Dictionary) -> Array[String]:
	var erros: Array[String] = []
	var regra: Dictionary = dados.atributos.criacao
	var ids: Array = dados.atributos.atributos.map(func(a): return a.id)
	var inicial := int(regra.valor_inicial)
	var gasto := 0
	var zerados := 0
	for attr_id in ids:
		if not atributos.has(attr_id):
			erros.append("Falta o atributo %s" % attr_id)
			continue
		var v := int(atributos[attr_id])
		if v > int(regra.maximo_inicial):
			erros.append("%s acima do máximo inicial (%d)" % [attr_id, int(regra.maximo_inicial)])
		if v < 0:
			erros.append("%s negativo" % attr_id)
		if v == 0:
			zerados += 1
		gasto += v - inicial
	if zerados > 1 or (zerados == 1 and not regra.pode_reduzir_um_para_zero):
		erros.append("Só um atributo pode ser reduzido a 0")
	if gasto != int(regra.pontos_para_distribuir):
		erros.append("Distribuição deve somar %d pontos (somou %d)" % [int(regra.pontos_para_distribuir), gasto])
	return erros
