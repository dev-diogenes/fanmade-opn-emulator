class_name LinhaTeste
extends RefCounted
## Linha de teste das escolhas (docs/21, C2): o mesmo formato no evento, no Procurar, no
## Facilitar, no Ajudar e no ataque. Mostra o que se rola e a chance, para decidir sem
## fazer conta: "Diplomacia · 2d20+5 · DT 15 · ≈ 64% (provável)".
## A chance vem das regras (Agente.prever_teste, CenaInvestigacao.prever_*, Combate.chance_de_acerto).

const FAIXAS := [[0.85, "quase certo"], [0.6, "provável"], [0.35, "arriscado"], [0.0, "difícil"]]


## "2d20+5"; com reserva 0 ou menos, "2d20 (o pior)+0" (p.24).
static func dados(reserva: int, bonus: int) -> String:
	if reserva <= 0:
		return "%dd20 (o pior)%+d" % [2 - reserva, bonus]
	return "%dd20%+d" % [reserva, bonus]


## "≈ 64% (provável)". Chance negativa = impossível daqui.
static func chance(p: float) -> String:
	if p < 0.0:
		return "fora de alcance"
	return "≈ %d%% (%s)" % [roundi(p * 100.0), faixa(p)]


static func faixa(p: float) -> String:
	for f in FAIXAS:
		if p >= float(f[0]):
			return String(f[1])
	return "difícil"


## A chance de uma previsão, ou "exige treino" quando a perícia só vale treinada.
static func resumo(previsao: Dictionary) -> String:
	if previsao.get("exige_treino", false):
		return "exige treino"
	return chance(float(previsao.get("chance", 0.0)))


static func bloqueada(previsao: Dictionary) -> bool:
	return bool(previsao.get("exige_treino", false))


## Linha completa a partir de uma previsão {"chance", "dados", "bonus"} e da DT.
static func texto(nome_pericia: String, previsao: Dictionary, dt: int) -> String:
	if previsao.is_empty():
		return "%s · DT %d" % [nome_pericia, dt]
	if bloqueada(previsao):
		return "%s · DT %d · exige treino" % [nome_pericia, dt]
	return "%s · %s · DT %d · %s" % [nome_pericia, dados(int(previsao.dados), int(previsao.bonus)), dt, chance(float(previsao.chance))]


## Tooltip que explica os números (o "−5" deixa de ser mistério).
static func explicar(a: Agente, pericia_id: String, previsao: Dictionary) -> String:
	if a == null or previsao.is_empty():
		return ""
	if bloqueada(previsao):
		return "Esta perícia só pode ser usada por quem tem treino nela."
	var linhas := PackedStringArray()
	var treinado := a.treinado_em(pericia_id)
	linhas.append("%s rola %s com %s." % [a.nome, dados(int(previsao.dados), int(previsao.bonus)),
		a.ruleset.atributo_da_pericia(pericia_id).to_upper()])
	if not treinado:
		linhas.append("Sem treino nesta perícia: nenhum bônus de grau.")
	if int(previsao.bonus) < 0:
		linhas.append("O bônus negativo vem de penalidades (kit faltando, carga ou condição).")
	linhas.append("Vale o maior dado; um 20 natural sempre passa. A chance é uma estimativa.")
	return "\n".join(linhas)


## A ★ de recomendação (docs/57) só vai numa escolha que dá para passar: 50% ou mais.
const CHANCE_RECOMENDADA := 0.5


## Índice da escolha que leva a ★: a de maior chance, se ela for de 50% ou mais; senão, -1
## (recomendar 20% contra 15% é recomendar um erro).
static func recomendada(previsoes: Array) -> int:
	var i := melhor(previsoes)
	if i < 0 or float(previsoes[i].get("chance", 0.0)) < CHANCE_RECOMENDADA:
		return -1
	return i


## Índice da escolha com a maior chance (a perícia que já vem escolhida).
static func melhor(previsoes: Array) -> int:
	var idx := -1
	var maior := -1.0
	for i in previsoes.size():
		var p: Dictionary = previsoes[i]
		if not p.is_empty() and float(p.chance) > maior:
			maior = float(p.chance)
			idx = i
	return idx
