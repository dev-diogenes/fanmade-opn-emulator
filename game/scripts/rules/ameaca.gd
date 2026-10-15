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
var ficha_original: Dictionary = {}   ## ficha usada para criar (cópias do escutado)
## Forma de Sangue (Mulher Afogada): {"resistencias", "cura_acelerada", "deslocamento"} até o enigma ser resolvido
var forma_de_sangue: Dictionary = {}
var transformacao: Dictionary = {}   ## {"nome", "ficha"}: a 0 PV vira outra criatura (Enpap-X)

const CONDICOES_PARALISIA := ["agarrado", "enredado", "imovel", "lento", "paralisado"]


static func criar(p_ruleset: Ruleset, p_nome: String, ficha: Dictionary) -> Ameaca:
	var a := Ameaca.new()
	a.ruleset = p_ruleset
	a.nome = p_nome
	a.lado = "ameacas"
	a.ficha_original = ficha
	a.aplicar_ficha(ficha)
	a.pv = a.pv_maximo
	a.tem_sanidade = false
	return a


## Usa os números de uma ficha (na criação e na transformação). Não mexe nos PV atuais.
func aplicar_ficha(ficha: Dictionary) -> void:
	pv_maximo = int(ficha.get("pv", 10))
	defesa_fixa = int(ficha.get("defesa", 10))
	atributos = ficha.get("atributos", {})
	pericias = ficha.get("pericias", {})
	ataques.clear()
	for at in ficha.get("ataques", []):
		ataques.append(at)
	resistencias_base = ficha.get("resistencias", {})
	deslocamento = float(ficha.get("deslocamento", 9))
	elemento = ficha.get("elemento", "")
	criatura = ficha.get("criatura", false)
	vd = int(ficha.get("vd", 0))
	presenca = ficha.get("presenca_perturbadora", {}).duplicate()
	enigma = ficha.get("enigma", {}).duplicate(true)
	if not enigma.is_empty():
		enigma["resolvido"] = false
		enigma["etapa"] = 0
	vulnerabilidades = ficha.get("vulnerabilidades", []).duplicate()
	imunidades = ficha.get("imunidades", []).duplicate()
	habilidades = ficha.get("habilidades", []).duplicate(true)
	conjurador = ficha.get("conjurador", {}).duplicate(true)
	forma_de_sangue = ficha.get("forma_de_sangue", {}).duplicate(true)
	transformacao = ficha.get("transformacao", {})


func atributo(atributo_id: String) -> int:
	return int(atributos.get(atributo_id, 1)) + efeito_ritual("atributo_" + atributo_id)


func dados_da_pericia(pericia_id: String) -> int:
	var attr := ruleset.atributo_da_pericia(pericia_id)
	var d := int(pericias[pericia_id].get("dados", 1)) if pericias.has(pericia_id) else atributo(attr)
	return d - penalidade_dados_atributo(attr) + efeito_ritual("dados_testes") - int(mods_cena.get("menos_dados", {}).get(pericia_id, 0))


func bonus_pericia(pericia_id: String) -> int:
	var b := int(pericias[pericia_id].get("bonus", 0)) if pericias.has(pericia_id) else 0
	return b + efeito_ritual("pericias")


func treinado_em(pericia_id: String) -> bool:
	return pericias.has(pericia_id) and int(pericias[pericia_id].get("bonus", 0)) > 0


func defesa() -> int:
	return defesa_fixa + ajustes_de_defesa() + efeito_ritual("defesa_ritual") - int(mods_cena.get("menos_defesa", 0))


func deslocamento_m() -> float:
	if na_forma_de_sangue():
		return float(forma_de_sangue.get("deslocamento", deslocamento))
	return maxf(0.0, deslocamento - float(mods_cena.get("menos_deslocamento", 0)))


func na_forma_de_sangue() -> bool:
	return not forma_de_sangue.is_empty() and enigma_pendente()


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


## Etapas do enigma (o formato antigo, com "pericias" e "dt", é uma etapa só).
func etapas_do_enigma() -> Array:
	if enigma.has("etapas"):
		return enigma.etapas
	return [{"texto": enigma.get("texto", ""), "pericias": enigma.get("pericias", ["ocultismo"]), "dt": enigma.get("dt", 20)}]


func etapa_atual() -> Dictionary:
	var etapas := etapas_do_enigma()
	var i := int(enigma.get("etapa", 0))
	return etapas[i] if i < etapas.size() else {}


func resistencia(tipo_dano: String) -> int:
	if enigma_pendente() and String(enigma.get("efeito", "remove_imunidade")) == "remove_imunidade":
		return 1 << 20   # Enigma de Medo: nada fere a criatura antes de ser resolvido
	if tipo_dano in imunidades or "dano" in imunidades:
		return 1 << 20   # imunidade da ficha
	var lodo := habilidade("lodo_protetor")
	if not lodo.is_empty() and not tipo_dano in lodo.get("exceto", []) and not mods_cena.get("queimada", false):
		return 1 << 20   # Aracnasita: o Lodo a protege de tudo, menos do fogo
	if na_forma_de_sangue():
		return int(forma_de_sangue.get("resistencias", {}).get(tipo_dano, 0)) + int(mods_cena.get("resistencia_extra", 0))
	return maxi(0, super(tipo_dano) - int(mods_cena.get("menos_resistencia", 0)))
