class_name Agente
extends Ser
## Agente da Ordem controlado por um jogador.

var ruleset: Ruleset
var classe_id := ""
var nex := 5
var atributos: Dictionary = {}   ## {"agi": 2, "for": 1, ...}
var pericias: Dictionary = {}    ## {"luta": "treinado", ...}
var pe := 0
var pe_maximo := 0
var pe_gasto_no_turno := 0


static func criar(p_ruleset: Ruleset, p_nome: String, p_classe: String, p_atributos: Dictionary, p_pericias: Dictionary = {}, p_nex: int = 5) -> Agente:
	var a := Agente.new()
	a.ruleset = p_ruleset
	a.nome = p_nome
	a.lado = "agentes"
	a.classe_id = p_classe
	a.atributos = p_atributos.duplicate()
	a.pericias = p_pericias.duplicate()
	a.nex = p_nex
	a.recalcular_maximos(true)
	return a


## Recalcula PV/PE/SAN máximos (após NEX ou atributo mudar). `encher` restaura os valores atuais.
func recalcular_maximos(encher: bool = false) -> void:
	pv_maximo = ruleset.pv_max(classe_id, nex, atributos)
	pe_maximo = ruleset.pe_max(classe_id, nex, atributos)
	san_maximo = ruleset.san_max(classe_id, nex, atributos)
	if encher:
		pv = pv_maximo
		pe = pe_maximo
		san = san_maximo
	else:
		pv = mini(pv, pv_maximo)
		pe = mini(pe, pe_maximo)
		san = mini(san, san_maximo)


func atributo(atributo_id: String) -> int:
	return int(atributos.get(atributo_id, 0))


func dados_da_pericia(pericia_id: String) -> int:
	return atributo(ruleset.atributo_da_pericia(pericia_id))


func grau(pericia_id: String) -> String:
	return pericias.get(pericia_id, "destreinado")


func bonus_pericia(pericia_id: String) -> int:
	return ruleset.bonus_grau(grau(pericia_id))


func pode_usar_pericia(pericia_id: String) -> bool:
	return not ruleset.pericia(pericia_id).somente_treinada or grau(pericia_id) != "destreinado"


func defesa() -> int:
	return ruleset.defesa_base(atributos)


func limite_pe() -> int:
	return ruleset.limite_pe(nex)


## PE que ainda podem ser gastos neste turno.
func pe_disponivel_no_turno() -> int:
	return mini(pe, limite_pe() - pe_gasto_no_turno)


func pode_gastar_pe(quantidade: int) -> bool:
	return quantidade >= 0 and quantidade <= pe_disponivel_no_turno()


func gastar_pe(quantidade: int) -> bool:
	if not pode_gastar_pe(quantidade):
		return false
	pe -= quantidade
	pe_gasto_no_turno += quantidade
	return true


func recuperar_pe(quantidade: int) -> void:
	pe = mini(pe_maximo, pe + maxi(0, quantidade))


func iniciar_turno() -> void:
	pe_gasto_no_turno = 0
	super.iniciar_turno()


## Teste de perícia. `pe_foco` = PE gastos como Foco: cada um soma +1 d20 (brainstorm §2).
## Retorna null se a perícia exige treino ou se não houver PE suficiente.
func testar(dados: Dados, pericia_id: String, dt: int, pe_foco: int = 0, dados_extras: int = 0, bonus_extra: int = 0) -> ResultadoTeste:
	if not pode_usar_pericia(pericia_id):
		return null
	if not gastar_pe(pe_foco):
		return null
	return Teste.rolar(dados, dados_da_pericia(pericia_id), bonus_pericia(pericia_id) + bonus_extra, dt, dados_extras + pe_foco)
