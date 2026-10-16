class_name FluxoCombate
extends RefCounted
## O passo a passo do combate (Fase 8, ADR 0007): passar o turno, contar a rodada na
## Membrana, armar quem entra no meio, jogar a IA e aplicar a Inspiração Resoluta. A arena
## (com pausas para o jogador acompanhar), o piloto automático, os testes e a rede usam este
## mesmo código, e por isso o combate sai igual em toda máquina.

signal nova_rodada(rodada: int)

const LIMITE_TURNOS := 600

var ruleset: Ruleset
var combate: Combate
var grade: Grade
var armas: Dictionary = {}
var membrana: Membrana
## Autoplay: a IA joga também os agentes
var ia_para_agentes := false
## Modo Mestre: as ameaças esperam a decisão do mestre (vem da configuração do encontro)
var ameacas_pelo_mestre := false
var turnos := 0


## Combate de um encontro da missão (a seed vem da configuração).
static func montar(ruleset_: Ruleset, config: Dictionary, membrana_: Membrana) -> FluxoCombate:
	var montado := MontagemCombate.montar(ruleset_, config, Dados.new(int(config.get("semente", 1))), membrana_)
	var f := de_combate(ruleset_, montado.combate, montado.grade, montado.armas, membrana_)
	f.ameacas_pelo_mestre = bool(config.get("mestre", false))
	return f


## Combate já montado (a arena de demonstração monta o seu).
static func de_combate(ruleset_: Ruleset, combate_: Combate, grade_: Grade, armas_: Dictionary, membrana_: Membrana) -> FluxoCombate:
	var f := FluxoCombate.new()
	f.ruleset = ruleset_
	f.combate = combate_
	f.grade = grade_
	f.armas = armas_
	f.membrana = membrana_
	combate_.ser_adicionado.connect(f._ao_adicionar)
	combate_.inspiracao_disponivel.connect(f._ao_inspirar)
	return f


func iniciar() -> void:
	combate.iniciar()


## Passa para o próximo ser e devolve quem age (null quando o combate acaba). Não joga a IA.
func proximo() -> Ser:
	if combate.encerrado or turnos >= LIMITE_TURNOS:
		return null
	var rodada_antes := combate.rodada
	var ser := combate.proximo_turno()
	if combate.rodada != rodada_antes:
		if membrana != null:
			membrana.registrar("rodada_combate")
		nova_rodada.emit(combate.rodada)
	turnos += 1
	return ser


## O ser espera a decisão de um jogador? Agentes do lado dos agentes, fora do autoplay
## (hipnotizados e em fúria jogam pela IA); com mestre, também as ameaças.
func decide_jogador(ser: Ser) -> bool:
	if ser is Ameaca:
		return ameacas_pelo_mestre and ser.lado == "ameacas"
	return ser is Agente and ser.lado == "agentes" and not ia_para_agentes


func jogar_ia(ser: Ser) -> void:
	IaCombate.jogar(combate, ser, armas)


## Avança, jogando a IA, até a próxima decisão de jogador. Devolve quem decide ou null (fim).
func avancar_ate_decisao() -> Ser:
	while true:
		var ser := proximo()
		if ser == null:
			return null
		if decide_jogador(ser):
			return ser
		jogar_ia(ser)
	return null


## O ser da vez, se for uma decisão de jogador.
func decisor() -> Ser:
	var s := combate.ser_atual()
	return s if s != null and not combate.encerrado and decide_jogador(s) else null


func aplicar(cmd: Dictionary) -> Dictionary:
	return Comandos.aplicar_combate(combate, armas, cmd)


func hash_estado() -> int:
	return Comandos.hash_combate(combate)


func _ao_adicionar(ser: Ser) -> void:
	armas[ser] = MontagemCombate.arma_de(ruleset, ser)


## Inspiração Resoluta: vai para o agente vivo com menos PV.
func _ao_inspirar(morto: Agente, efeito: String) -> void:
	var melhor: Agente = null
	for s in combate.participantes:
		if s is Agente and not s.esta_fora_de_combate() and (melhor == null or s.pv < melhor.pv):
			melhor = s
	if melhor != null:
		combate.aplicar_inspiracao(combate.inspiracoes_pendentes.size() - 1, melhor)
		combate.registro.emit("[color=#bb8fce]Inspiração Resoluta de %s: %s para %s.[/color]" % [morto.nome, efeito.replace("_", " "), melhor.nome])
