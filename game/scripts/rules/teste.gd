class_name Teste
extends RefCounted
## Mecânica básica de teste (p.19, p.49, p.86).


## Rola `atributo + dados_extras` d20 e soma `bonus`.
## - Reserva >= 1: vale o maior.
## - Reserva <= 0: rola (2 - reserva) d20 e vale o menor. Atributo 0 = 2d20, o pior (p.24).
##   Penalidades além disso adicionam dados ao "pior" (interpretação nossa; validar na p.322).
## - Um 20 natural no dado escolhido é sucesso automático (p.86).
static func rolar(dados: Dados, atributo: int, bonus: int, dt: int, dados_extras: int = 0) -> ResultadoTeste:
	var r := ResultadoTeste.new()
	var reserva := atributo + dados_extras
	var quantidade := reserva
	if reserva <= 0:
		quantidade = 2 - reserva
		r.usa_pior = true
	r.atributo = atributo
	r.dados_extras = dados_extras
	r.slots = dados.rolar_varios(quantidade, 20)
	r.escolhido = r.slots.min() if r.usa_pior else r.slots.max()
	r.bonus = bonus
	r.total = r.escolhido + bonus
	r.dt = dt
	r.natural_20 = r.escolhido == 20
	r.sucesso = r.natural_20 or r.total >= dt
	return r


## Refaz um teste com os mesmos parâmetros (ex.: Inspirar Confiança). Bônus pós-rolagem não são refeitos.
static func rerrolar(dados: Dados, anterior: ResultadoTeste) -> ResultadoTeste:
	var base_bonus := anterior.bonus
	for extra in anterior.dados_bonus:
		base_bonus -= extra
	return rolar(dados, anterior.atributo, base_bonus, anterior.dt, anterior.dados_extras)


## Probabilidade (0..1) de passar, para a dica "chance de passar" da UI.
static func chance_de_passar(atributo: int, bonus: int, dt: int, dados_extras: int = 0) -> float:
	var reserva := atributo + dados_extras
	var usa_pior := reserva <= 0
	var quantidade := 2 - reserva if usa_pior else reserva
	# Menor face do d20 que passa (20 sempre passa).
	var minimo := clampi(dt - bonus, 1, 20)
	var p_um := float(21 - minimo) / 20.0  # chance de um único d20 passar
	if usa_pior:
		return pow(p_um, quantidade)  # todos precisam passar
	return 1.0 - pow(1.0 - p_um, quantidade)  # basta um passar
