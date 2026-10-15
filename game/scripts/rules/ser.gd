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
const PARALISADO := "paralisado"
const DESPREVENIDO := "desprevenido"
const INDEFESO := "indefeso"
const SURPREENDIDO := "surpreendido"
const VULNERAVEL := "vulneravel"
const IMOVEL := "imovel"

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
## Resistência a dano fixa por tipo ("corte", "mental", "paranormal"…).
var resistencias_base: Dictionary = {}

## Modificadores que duram até o fim da cena (Inspiração Resoluta etc.):
## {"atributos": {"for": 2}, "resistencias": {"mental": 10}, "ataque_contra": {Ser: 5}}
var mods_cena: Dictionary = {}
## Bônus de Defesa até o início do próximo turno (Combate Defensivo).
var defesa_temporaria := 0
## Dados a menos nos ataques até o início do próximo turno (Combate Defensivo, Duas Armas).
var penalidade_ataque_temporaria := 0
## Ações padrão extras no próximo turno (concedidas por efeitos; a UI consome).
var acoes_padrao_extras := 0
## Reação DEFENSIVA (bloqueio, esquiva, contra-ataque) usada nesta rodada: só uma (p.88).
var reacao_usada := false
## Quem causou o último dano (para "Chamas da Vingança"). Referência fraca para evitar ciclos.
var _ultimo_atacante: WeakRef

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


func treinado_em(_pericia_id: String) -> bool:
	return false


func defesa() -> int:
	return 10 + ajustes_de_defesa()


## Ajustes comuns a todos os seres: temporários, de cena e condições (p.89, p.320).
func ajustes_de_defesa() -> int:
	var total := defesa_temporaria + int(mods_cena.get("defesa", 0))
	if esta_indefeso():
		total -= 10
	elif tem(DESPREVENIDO) or tem(SURPREENDIDO):
		total -= 5
	if tem(VULNERAVEL):
		total -= 2
	return total


func esta_indefeso() -> bool:
	return tem(INDEFESO) or tem(INCONSCIENTE) or tem(PARALISADO)


## Modificadores que o ser aplica ao atacar com `arma` contra `alvo`:
## {bonus_ataque, dados_extras, margem (redução da margem de ameaça), bonus_dano, dados_dano_extra}
func modificar_ataque(_arma: Dictionary, alvo: Ser) -> Dictionary:
	var mods := {"bonus_ataque": 0, "dados_extras": -penalidade_ataque_temporaria, "margem": 0, "bonus_dano": 0, "dados_dano_extra": 0}
	mods.bonus_ataque += int(mods_cena.get("ataque_contra", {}).get(alvo, 0))
	mods.bonus_ataque -= int(mods_cena.get("penalidade_ataque", 0))
	return mods


## Bônus em testes de resistência (Fortitude, Reflexos, Vontade).
func bonus_testes_resistencia() -> int:
	return int(mods_cena.get("resistencia_testes", 0))


func resistencia(tipo_dano: String) -> int:
	return int(resistencias_base.get(tipo_dano, 0)) + int(mods_cena.get("resistencias", {}).get(tipo_dano, 0))


# --- Estado ----------------------------------------------------------------

func tem(condicao: String) -> bool:
	return condicoes.has(condicao)


func esta_fora_de_combate() -> bool:
	return tem(MORTO) or tem(INCONSCIENTE) or tem(INSANO)


func ultimo_atacante() -> Ser:
	return _ultimo_atacante.get_ref() as Ser if _ultimo_atacante != null else null


func registrar_atacante(atacante: Ser) -> void:
	_ultimo_atacante = weakref(atacante) if atacante != null else null


func turnos_morrendo() -> int:
	return _turnos_morrendo


func sofrer_dano(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO):
		return
	pv = maxi(0, pv - quantidade)
	_atualizar_pv()


## Dano mental: reduzido pela resistência mental; vai para a SAN (ou para os PV de ameaças da Realidade, p.82).
func sofrer_dano_mental(quantidade: int) -> void:
	quantidade -= resistencia("mental")
	if quantidade <= 0:
		return
	if not tem_sanidade:
		sofrer_dano(quantidade)
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
	defesa_temporaria = 0
	penalidade_ataque_temporaria = 0
	reacao_usada = false
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


## Zera contadores e modificadores temporários ao fim de uma cena.
func encerrar_cena() -> void:
	_turnos_morrendo = 0
	_turnos_enlouquecendo = 0
	mods_cena.clear()
	defesa_temporaria = 0
	penalidade_ataque_temporaria = 0
	for c in [DESPREVENIDO, SURPREENDIDO, IMOVEL, VULNERAVEL]:
		condicoes.erase(c)   # condições terminam no fim da cena (p.321)
	acoes_padrao_extras = 0
	reacao_usada = false


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
