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
var criatura := false   ## Origem Paranormal (p.190): imune a dano mental e a condições mentais e de medo
var vd := 0             ## Valor de dificuldade (escolhe a Presença Perturbadora da cena)
## Presença Perturbadora (p.190): {"dt", "dano", "nex"}; vazio = não tem
var presenca: Dictionary = {}
## Enigma de Medo (p.190): {"texto", "pericias", "dt", "resolvido"}; enquanto não resolvido, imune a dano
var enigma: Dictionary = {}
var vulnerabilidades: Array = []   ## tipos de dano que causam o dobro
var imunidades: Array = []         ## tipos de dano, condições ou "paralisia" (todas as condições de paralisia)
var habilidades: Array = []        ## [{id, ...}] habilidades da ficha (cap. 7)
var conjurador: Dictionary = {}    ## {"rituais", "dt", "limite_pe"}: cultistas conjuram sem gastar PE (p.296)
var vd_valor := 0
var usos: Dictionary = {}          ## habilidade -> usos na cena

const CONDICOES_PARALISIA := ["agarrado", "enredado", "imovel", "lento", "paralisado"]


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
	a.criatura = ficha.get("criatura", false)
	a.vd = int(ficha.get("vd", 0))
	a.presenca = ficha.get("presenca_perturbadora", {}).duplicate()
	a.enigma = ficha.get("enigma", {}).duplicate()
	if not a.enigma.is_empty():
		a.enigma["resolvido"] = false
	a.vulnerabilidades = ficha.get("vulnerabilidades", []).duplicate()
	a.imunidades = ficha.get("imunidades", []).duplicate()
	a.habilidades = ficha.get("habilidades", []).duplicate(true)
	a.conjurador = ficha.get("conjurador", {}).duplicate(true)
	a.tem_sanidade = false
	return a


func atributo(atributo_id: String) -> int:
	return int(atributos.get(atributo_id, 1)) + efeito_ritual("atributo_" + atributo_id)


func dados_da_pericia(pericia_id: String) -> int:
	var attr := ruleset.atributo_da_pericia(pericia_id)
	var d := int(pericias[pericia_id].get("dados", 1)) if pericias.has(pericia_id) else atributo(attr)
	return d - penalidade_dados_atributo(attr) + efeito_ritual("dados_testes")


func bonus_pericia(pericia_id: String) -> int:
	var b := int(pericias[pericia_id].get("bonus", 0)) if pericias.has(pericia_id) else 0
	return b + efeito_ritual("pericias")


func treinado_em(pericia_id: String) -> bool:
	return pericias.has(pericia_id) and int(pericias[pericia_id].get("bonus", 0)) > 0


func defesa() -> int:
	return defesa_fixa + ajustes_de_defesa() + efeito_ritual("defesa_ritual")


func deslocamento_m() -> float:
	return deslocamento


func imune_a_condicao(condicao: String) -> bool:
	if condicao in imunidades or ("paralisia" in imunidades and condicao in CONDICOES_PARALISIA):
		return true
	return criatura and condicao in CONDICOES_MENTAIS


func habilidade(hab_id: String) -> Dictionary:
	for h in habilidades:
		if h.id == hab_id:
			return h
	return {}


func tem_hab(hab_id: String) -> bool:
	return not habilidade(hab_id).is_empty()


func vulneravel_a(tipo_dano: String) -> bool:
	return tipo_dano in vulnerabilidades or super(tipo_dano)


func dt_ritual(_ritual_id: String) -> int:
	return int(conjurador.get("dt", 10))


func conhece_ritual(ritual_id: String) -> bool:
	return ritual_id in conjurador.get("rituais", [])


func enigma_pendente() -> bool:
	return not enigma.is_empty() and not enigma.get("resolvido", false)


func resistencia(tipo_dano: String) -> int:
	if enigma_pendente() or tipo_dano in imunidades:
		return 1 << 20   # imune a dano (Enigma de Medo ou imunidade da ficha)
	return super(tipo_dano)
