class_name Ser
extends RefCounted
## Qualquer criatura em cena: agente ou ameaça (o livro usa "ser").
## Guarda PV, SAN e condições, e implementa ferimentos e insanidade (p.98).

signal morreu(ser: Ser)
signal ficou_insano(ser: Ser)

const MORRENDO := "morrendo"
const INCONSCIENTE := "inconsciente"
const MORTO := "morto"
const MACHUCADO := "machucado"
const ENLOUQUECENDO := "enlouquecendo"
const PERTURBADO := "perturbado"
const INSANO := "insano"

const TURNOS_PARA_MORRER := 3
const TURNOS_PARA_ENLOUQUECER := 3

var nome := ""
var lado := ""          ## "agentes" ou "ameacas"
var pv := 0
var pv_maximo := 0
var san := 0
var san_maximo := 0
var tem_sanidade := true
var condicoes: Dictionary = {}

var _turnos_morrendo := 0
var _turnos_enlouquecendo := 0


# --- Interface que subclasses implementam ---------------------------------

func atributo(_atributo_id: String) -> int:
	return 0


## Quantos d20 o ser rola numa perícia, antes de modificadores.
func dados_da_pericia(_pericia_id: String) -> int:
	return 0


func bonus_pericia(_pericia_id: String) -> int:
	return 0


func defesa() -> int:
	return 10


# --- Estado ----------------------------------------------------------------

func tem(condicao: String) -> bool:
	return condicoes.has(condicao)


func esta_fora_de_combate() -> bool:
	return tem(MORTO) or tem(INCONSCIENTE) or tem(INSANO)


func sofrer_dano(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO):
		return
	pv = maxi(0, pv - quantidade)
	_atualizar_pv()


func sofrer_dano_mental(quantidade: int) -> void:
	if quantidade <= 0:
		return
	if not tem_sanidade:
		sofrer_dano(quantidade)  # Ameaças da Realidade perdem PV (p.82)
		return
	san = maxi(0, san - quantidade)
	_atualizar_san()


func curar(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO):
		return
	pv = mini(pv_maximo, pv + quantidade)
	condicoes.erase(INCONSCIENTE)  # curar 1 PV encerra inconsciente; morrendo exige Medicina
	_atualizar_pv()


func recuperar_sanidade(quantidade: int) -> void:
	if quantidade <= 0 or not tem_sanidade:
		return
	san = mini(san_maximo, san + quantidade)
	condicoes.erase(ENLOUQUECENDO)  # qualquer cura de SAN encerra enlouquecendo
	_atualizar_san()


## Encerra a condição morrendo (teste de Medicina DT 20 bem-sucedido, p.98).
func estabilizar() -> void:
	condicoes.erase(MORRENDO)


## Chamado no início de cada turno do ser. Três turnos iniciados morrendo
## (ou enlouquecendo) na mesma cena matam (ou enlouquecem) o ser.
func iniciar_turno() -> void:
	if tem(MORRENDO):
		_turnos_morrendo += 1
		if _turnos_morrendo >= TURNOS_PARA_MORRER:
			_morrer()
	if tem(ENLOUQUECENDO):
		_turnos_enlouquecendo += 1
		if _turnos_enlouquecendo >= TURNOS_PARA_ENLOUQUECER:
			condicoes.erase(ENLOUQUECENDO)
			condicoes[INSANO] = true
			ficou_insano.emit(self)


## Zera os contadores ao fim de uma cena.
func encerrar_cena() -> void:
	_turnos_morrendo = 0
	_turnos_enlouquecendo = 0


func _atualizar_pv() -> void:
	if tem(MORTO):
		return
	if pv * 2 <= pv_maximo:
		condicoes[MACHUCADO] = true
	else:
		condicoes.erase(MACHUCADO)
	if pv == 0:
		condicoes[INCONSCIENTE] = true
		condicoes[MORRENDO] = true


func _atualizar_san() -> void:
	if san * 2 < san_maximo:
		condicoes[PERTURBADO] = true
	else:
		condicoes.erase(PERTURBADO)
	if san == 0 and not tem(INSANO):
		condicoes[ENLOUQUECENDO] = true


func _morrer() -> void:
	condicoes.clear()
	condicoes[MORTO] = true
	morreu.emit(self)
