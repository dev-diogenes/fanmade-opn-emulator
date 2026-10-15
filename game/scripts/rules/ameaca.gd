class_name Ameaca
extends Ser
## Ameaça (criatura, cultista, animal…) com ficha resumida, como no cap. 7.

var defesa_fixa := 10
var atributos: Dictionary = {}
## {"luta": {"dados": 2, "bonus": 10}, ...} — perícias fora da lista usam o atributo-base, sem bônus.
var pericias: Dictionary = {}
var ataques: Array[Dictionary] = []   ## Mesmo formato de armas.json
var ruleset: Ruleset
var deslocamento := 9.0
var elemento := ""   ## Elemento da criatura (rituais opressores/do mesmo elemento, p.128)


static func criar(p_ruleset: Ruleset, p_nome: String, ficha: Dictionary) -> Ameaca:
	var a := Ameaca.new()
	a.ruleset = p_ruleset
	a.nome = p_nome
	a.lado = "ameacas"
	a.pv_maximo = int(ficha.get("pv", 10))
	a.pv = a.pv_maximo
	a.defesa_fixa = int(ficha.get("defesa", 10))
	a.atributos = ficha.get("atributos", {})
	a.pericias = ficha.get("pericias", {})
	for at in ficha.get("ataques", []):
		a.ataques.append(at)
	a.resistencias_base = ficha.get("resistencias", {})
	a.deslocamento = float(ficha.get("deslocamento", 9))
	a.elemento = ficha.get("elemento", "")
	a.tem_sanidade = false
	return a


func atributo(atributo_id: String) -> int:
	return int(atributos.get(atributo_id, 1)) + efeito_ritual("atributo_" + atributo_id)


func dados_da_pericia(pericia_id: String) -> int:
	var attr := ruleset.atributo_da_pericia(pericia_id)
	var d := int(pericias[pericia_id].get("dados", 1)) if pericias.has(pericia_id) else atributo(attr)
	return d - penalidade_dados_atributo(attr)


func bonus_pericia(pericia_id: String) -> int:
	var b := int(pericias[pericia_id].get("bonus", 0)) if pericias.has(pericia_id) else 0
	return b + efeito_ritual("pericias")


func treinado_em(pericia_id: String) -> bool:
	return pericias.has(pericia_id) and int(pericias[pericia_id].get("bonus", 0)) > 0


func defesa() -> int:
	return defesa_fixa + ajustes_de_defesa() + efeito_ritual("defesa_ritual")


func deslocamento_m() -> float:
	return deslocamento
