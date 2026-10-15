class_name RulesetOp2022
extends Ruleset
## Livro básico de 2022 (v1.3). Hoje usa todas as fórmulas da base;
## regras específicas da V1 que a V2 mudar ficam sobrescritas aqui.

const PASTA := "res://data/rulesets/op2022"


static func carregar_padrao() -> RulesetOp2022:
	var r := RulesetOp2022.new()
	var erro := r.carregar(PASTA)
	assert(erro == OK, "Falha ao carregar o ruleset op2022 (%s)" % error_string(erro))
	return r
