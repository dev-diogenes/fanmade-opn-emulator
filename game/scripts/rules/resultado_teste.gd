class_name ResultadoTeste
extends RefCounted
## Resultado de um teste de OP mostrado como slots de d20 (estilo FTK).

var slots: Array[int] = []        ## Cada d20 rolado
var usa_pior := false             ## true quando a reserva de dados ficou em 0 ou menos
var escolhido := 0                ## O d20 que vale (maior, ou menor se usa_pior)
var bonus := 0                    ## Bônus de perícia e modificadores
var total := 0
var dt := 0
var natural_20 := false
var sucesso := false


## Texto curto para debug/log, ex.: "[14, 3, 9] maior 14 +5 = 19 vs DT 20 ✗"
func descrever() -> String:
	var criterio := "menor" if usa_pior else "maior"
	var sinal := "+" if bonus >= 0 else ""
	var marca := "✓" if sucesso else "✗"
	return "%s %s %d %s%d = %d vs DT %d %s" % [str(slots), criterio, escolhido, sinal, bonus, total, dt, marca]
