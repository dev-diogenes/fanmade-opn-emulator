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
const FATIGADO := "fatigado"
const ATORDOADO := "atordoado"
const PASMO := "pasmo"
const ABALADO := "abalado"
const APAVORADO := "apavorado"
const ENJOADO := "enjoado"
const AGARRADO := "agarrado"
## Caído (p.310): −2 dados no corpo a corpo, deslocamento 1,5 m, −5 na Defesa contra corpo a
## corpo e +5 contra ataques à distância. Levantar-se é uma ação de movimento (p.84).
const CAIDO := "caido"
const EXAUSTO := "exausto"
const FRACO := "fraco"
const DEBILITADO := "debilitado"
const OFUSCADO := "ofuscado"
const SEM_CURA := "sem_cura"   ## Poeira da Podridão: não recupera PV
const SANGRANDO := "sangrando"  ## p.321: Vigor DT 20 no início do turno ou perde 1d6 PV
const POCA := "poca"
const ASFIXIADO := "asfixiado"  ## Afogar em Sangue (Mulher Afogada)
const EM_CHAMAS := "em_chamas"  ## p.320: 1d6 de fogo no início do turno; ação padrão para apagar
const FASCINADO := "fascinado"  ## p.321: não age (no jogo, enquanto estiver agarrado pelo anjo)
const CONFUSO := "confuso"      ## p.320: age de modo aleatório (no jogo: perde o turno, exceto com 6 no 1d6)
const LENTO := "lento"
const PARALISADO_ := "paralisado"           ## Imortalidade (esqueleto de Lodo, enraizado): desfeito, mas volta
## Condições mentais e de medo (p.320-321): criaturas paranormais são imunes (p.190)
const CONDICOES_MENTAIS := ["abalado", "apavorado", "alquebrado", "atordoado", "confuso", "esmorecido", "fascinado", "frustrado", "pasmo"]
## Condição repetida vira a seguinte (p.320-321)
const AGRAVA := {"abalado": "apavorado", "fatigado": "exausto", "fraco": "debilitado"}

const DANO_FISICO := ["balistico", "corte", "impacto", "perfuracao"]

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
## PV temporários: absorvem dano antes dos PV normais e somem no fim da cena.
var pv_temporario := 0
## Condições com duração em rodadas (diminuem no início do turno do ser): {condicao: rodadas}
var duracoes: Dictionary = {}
## Rituais ativos sobre o ser: {ritual_id: {efeito..., "conjurador": Ser}}
var rituais_ativos: Dictionary = {}
## Hemorragia (Descarnar): {"dados": "2d8", "dt": int, "sucessos": int}
var hemorragia: Dictionary = {}

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
## Primeiros Socorros e Acalmar (p.46 e p.44): a DT sobe +5 por vez que o ser já foi
## estabilizado (ou acalmado) na cena.
var estabilizado_na_cena := 0
## Dano não letal (p.88): soma com o letal para deixar inconsciente, mas não para morrendo.
## A cura tira primeiro o não letal. Some no fim da cena (design do jogo).
var dano_nao_letal := 0
var acalmado_na_cena := 0
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


## Deslocamento em metros (padrão 9 m, p.46).
func deslocamento_m() -> float:
	return 9.0


## Deslocamento em quadrados de 1,5 m (9 m = 6 quadrados).
func deslocamento_quadrados() -> int:
	if tem(CAIDO):
		return mini(1, int(deslocamento_m() / 1.5))   # caído: 1,5 m (p.310)
	return int(deslocamento_m() / 1.5)


## Ajustes comuns a todos os seres: temporários, de cena e condições (p.89, p.320).
func ajustes_de_defesa() -> int:
	var total := defesa_temporaria + int(mods_cena.get("defesa", 0)) + efeito_ritual("embaralhar")
	if esta_indefeso():
		total -= 10
	elif tem(DESPREVENIDO) or tem(SURPREENDIDO):
		total -= 5
	elif tem(AGARRADO):
		total -= 5   # agarrado inclui desprevenido
	if tem(VULNERAVEL) or tem(FATIGADO) or tem(EXAUSTO):
		total -= 2   # fatigado e exausto incluem vulnerável (p.320)
	return total


## Soma de uma chave de efeito entre os rituais ativos no ser.
func efeito_ritual(chave: String) -> int:
	var total := 0
	for r in rituais_ativos.values():
		total += int(r.get(chave, 0))
	return total


## Penalidade de dados por condições (p.320-321): fraco/fatigado −1 e debilitado/exausto −2 em
## Agilidade, Força e Vigor; abalado −1 e apavorado −2 em todos os testes.
func penalidade_dados_atributo(atributo_id: String) -> int:
	var p := 0
	if atributo_id in ["agi", "for", "vig"]:
		if tem(DEBILITADO) or tem(EXAUSTO):
			p += 2
		elif tem(FATIGADO) or tem(FRACO):
			p += 1
	if tem(APAVORADO):
		p += 2
	elif tem(ABALADO):
		p += 1
	return p + int(mods_cena.get("penalidade_aura", 0))   # Aura Manifestada (lembrado)


func imune_a_condicao(_condicao: String) -> bool:
	return false


## Vulnerabilidade (p.190): sofre o dobro do dano desse tipo. Efeitos de cena podem dar uma.
func vulneravel_a(tipo_dano: String) -> bool:
	return tipo_dano in mods_cena.get("vulnerabilidades", [])


## DT dos rituais que o ser conjura (Agente: Presença e limite de PE; ameaças: valor fixo da ficha).
func dt_ritual(_ritual_id: String) -> int:
	return 10


func bonus_ritual_potente() -> int:
	return 0


## Aplica uma condição; `rodadas` 0 = até o fim da cena. Repetir abalado, fatigado ou fraco agrava.
func aplicar_condicao(condicao: String, rodadas: int = 0) -> void:
	if condicao == "" or imune_a_condicao(condicao):
		return
	if tem(condicao) and AGRAVA.has(condicao):
		condicoes.erase(condicao)
		duracoes.erase(condicao)
		condicao = AGRAVA[condicao]
	condicoes[condicao] = true
	if rodadas > 0:
		duracoes[condicao] = rodadas


func esta_indefeso() -> bool:
	return tem(INDEFESO) or tem(INCONSCIENTE) or tem(PARALISADO)


## Modificadores que o ser aplica ao atacar com `arma` contra `alvo`:
## {bonus_ataque, dados_extras, margem (redução da margem de ameaça), bonus_dano, dados_dano_extra}
func modificar_ataque(arma: Dictionary, alvo: Ser) -> Dictionary:
	var mods := {"bonus_ataque": 0, "dados_extras": -penalidade_ataque_temporaria, "margem": 0, "bonus_dano": 0, "dados_dano_extra": 0}
	mods.bonus_ataque += int(mods_cena.get("ataque_contra", {}).get(alvo, 0))
	mods.bonus_ataque -= int(mods_cena.get("penalidade_ataque", 0))
	mods.dados_extras += efeito_ritual("dados_ataque")
	mods.dados_dano_extra += efeito_ritual("dados_dano_extra")   # Ordens (comandante mercenário)
	if tem(AGARRADO):
		mods.dados_extras -= 1
	if tem(CAIDO) and arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo":
		mods.dados_extras -= 2   # caído: −OO no corpo a corpo (p.310)
	if tem(OFUSCADO):
		mods.dados_extras -= 1
	mods.bonus_ataque += efeito_ritual("pericias")   # Coincidência Forçada vale para testes de ataque
	var corpo_a_corpo: bool = arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo"
	if corpo_a_corpo:
		mods.bonus_ataque += efeito_ritual("ataque_corpo_a_corpo") + efeito_ritual("bonus_ataque")
		mods.bonus_dano += efeito_ritual("dano_corpo_a_corpo")
		mods.margem += efeito_ritual("margem")
	for r in rituais_ativos.values():
		if r.has("dano_extra") and corpo_a_corpo:
			mods["dados_dano_ritual"] = String(mods.get("dados_dano_ritual", "")) + ("+" if mods.has("dados_dano_ritual") else "") + String(r.dano_extra)
	return mods


## Bônus em testes de resistência (Fortitude, Reflexos, Vontade).
func bonus_testes_resistencia() -> int:
	return int(mods_cena.get("resistencia_testes", 0))


func resistencia(tipo_dano: String) -> int:
	var total := int(resistencias_base.get(tipo_dano, 0)) + int(mods_cena.get("resistencias", {}).get(tipo_dano, 0)) + int(mods_cena.get("resistencia_extra", 0))
	if tipo_dano != "mental":
		total += int(resistencias_base.get("dano", 0))   # "Resistência a dano N": vale para todos os tipos
	if tipo_dano in DANO_FISICO:
		total += efeito_ritual("resistencia_fisica")   # Ódio Incontrolável
	return total


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


## Dano não letal: acumula à parte; quando alcança os PV, o ser desmaia (sem morrendo).
func sofrer_dano_nao_letal(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO):
		return
	dano_nao_letal += quantidade
	if dano_nao_letal >= pv and pv > 0:
		condicoes[INCONSCIENTE] = true
		mods_cena["rendido"] = true


func sofrer_dano(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO):
		return
	if pv_temporario > 0:
		var absorvido := mini(pv_temporario, quantidade)
		pv_temporario -= absorvido
		quantidade -= absorvido
		if quantidade <= 0:
			return
	pv = maxi(0, pv - quantidade)
	_atualizar_pv()


## Dano mental: reduzido pela resistência mental; vai para a SAN (ou para os PV de ameaças da Realidade, p.82).
func sofrer_dano_mental(quantidade: int) -> void:
	if imune_a_condicao("abalado"):
		return   # Origem Paranormal: criaturas são imunes a dano mental (p.190)
	quantidade -= resistencia("mental")
	if quantidade <= 0:
		return
	if not tem_sanidade:
		sofrer_dano(quantidade)
		return
	san = maxi(0, san - quantidade)
	_atualizar_san()


func curar(quantidade: int) -> void:
	if quantidade <= 0 or tem(MORTO) or tem(SEM_CURA):
		return
	if dano_nao_letal > 0:   # a cura tira primeiro o dano não letal (p.88)
		var tirado := mini(dano_nao_letal, quantidade)
		dano_nao_letal -= tirado
		quantidade -= tirado
		if dano_nao_letal < pv:
			condicoes.erase(INCONSCIENTE)
			mods_cena.erase("rendido")
		if quantidade <= 0:
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


## Perda direta de Sanidade (custo de rituais): não é dano mental, ignora resistência.
func perder_sanidade(quantidade: int) -> void:
	if quantidade <= 0 or not tem_sanidade:
		return
	san = maxi(0, san - quantidade)
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
	for c in duracoes.keys():
		duracoes[c] -= 1
		if duracoes[c] <= 0:
			duracoes.erase(c)
			condicoes.erase(c)
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
	estabilizado_na_cena = 0
	acalmado_na_cena = 0
	dano_nao_letal = 0
	mods_cena.clear()
	defesa_temporaria = 0
	penalidade_ataque_temporaria = 0
	for c in [DESPREVENIDO, SURPREENDIDO, IMOVEL, VULNERAVEL, FATIGADO, ATORDOADO, PASMO, ABALADO, APAVORADO, ENJOADO, AGARRADO, CAIDO, OFUSCADO, SEM_CURA, SANGRANDO, EM_CHAMAS, CONFUSO, ASFIXIADO]:
		condicoes.erase(c)   # condições terminam no fim da cena (p.321)
	duracoes.clear()
	rituais_ativos.clear()
	hemorragia.clear()
	pv_temporario = 0
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
	var era_perturbado := tem(PERTURBADO)
	var enlouquecia := tem(ENLOUQUECENDO)
	if san * 2 < san_maximo:
		condicoes[PERTURBADO] = true
	else:
		condicoes.erase(PERTURBADO)
	if san == 0 and not tem(INSANO):
		condicoes[ENLOUQUECENDO] = true
	if tem(PERTURBADO) != era_perturbado:
		_mudou_perturbado(tem(PERTURBADO))
	if tem(ENLOUQUECENDO) and not enlouquecia:
		_comecou_a_enlouquecer()


## Ganchos da insanidade (p.111): o Agente rola o efeito ao ficar perturbado e o fixa até o fim
## da missão ao enlouquecer. Ameaças não têm efeito de insanidade.
func _mudou_perturbado(_agora: bool) -> void:
	pass


func _comecou_a_enlouquecer() -> void:
	pass


func _morrer() -> void:
	condicoes.clear()
	condicoes[MORTO] = true
	morreu.emit(self)
