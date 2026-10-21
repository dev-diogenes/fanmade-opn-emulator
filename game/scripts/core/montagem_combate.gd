class_name MontagemCombate
extends RefCounted
## Monta o combate de um encontro da missão (Missao.encontro_pendente): grade 14×9 com o
## terreno do hex, agentes à esquerda e ameaças à direita. Usada pela arena e pelo simulador.

const COLUNAS := 14
const LINHAS := 9


## Retorna {"combate": Combate, "grade": Grade, "armas": {Ser: arma}}. O combate ainda não foi iniciado.
static func montar(ruleset: Ruleset, config: Dictionary, dados: Dados, membrana: Membrana) -> Dictionary:
	var regras: Dictionary = config.get("regras", {"lesoes": true, "inspiracao_resoluta": true, "presenca_perturbadora": true})
	var c := Combate.new(ruleset, dados, regras)
	var grade := Grade.new(COLUNAS, LINHAS)
	c.grade = grade
	c.membrana = membrana
	_terreno(grade, dados, String(config.get("terreno", "campo")))
	var armas := {}
	var linhas_livres := [4, 2, 6, 3, 5, 1, 7]
	var i := 0
	for a in config.agentes:
		_colocar(c, grade, armas, a, config.armas[a], Vector2i(1, linhas_livres[i % linhas_livres.size()]))
		i += 1
	i = 0
	for info in config.ameacas:
		var amea := Ameaca.criar(ruleset, info.nome, info.ficha)
		_colocar(c, grade, armas, amea, info.arma, Vector2i(COLUNAS - 2 - (i / 7), linhas_livres[i % linhas_livres.size()]))
		i += 1
	return {"combate": c, "grade": grade, "armas": armas}


## Arma de quem entra no meio do combate (cópias, invocações).
static func arma_de(ruleset: Ruleset, ser: Ser) -> Dictionary:
	var lista: Array = (ser as Ameaca).ataques if ser is Ameaca else []
	return lista[0] if not lista.is_empty() else ruleset.arma("desarmado")


## Campo de batalha a partir do terreno do hex (parâmetros "arena" em mapa.json).
## Colunas 0-1 e 12-13 ficam livres para os dois lados se posicionarem.
static func _terreno(grade: Grade, dados: Dados, terreno_id: String) -> void:
	var t: Dictionary = DadosJogo.ler("mapa").terrenos.get(terreno_id, {})
	var param: Dictionary = t.get("arena", {})
	var tipos := {Grade.PAREDE: int(param.get("parede", 0)), Grade.COBERTURA: int(param.get("cobertura", 2)), Grade.DIFICIL: int(param.get("dificil", 0)),
		Grade.ELEVADO: int(param.get("elevado", 0)), Grade.CAMUFLAGEM: int(param.get("camuflagem", 0))}   # docs/40
	for tipo in tipos:
		for i in tipos[tipo]:
			var c := Vector2i(2 + dados.rolar(COLUNAS - 4) - 1, dados.rolar(LINHAS) - 1)
			if not grade.terreno.has(c):
				grade.terreno[c] = tipo


static func _colocar(c: Combate, grade: Grade, armas: Dictionary, ser: Ser, arma: Dictionary, pos: Vector2i) -> void:
	c.adicionar(ser)
	grade.colocar(ser, pos)
	armas[ser] = arma
