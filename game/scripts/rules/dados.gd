class_name Dados
extends RefCounted
## Gerador de rolagens com seed reproduzível.
## Nos testes, use `forcar()` para enfileirar resultados exatos.

var _rng := RandomNumberGenerator.new()
var _fila: Array[int] = []


func _init(semente: int = -1) -> void:
	if semente >= 0:
		_rng.seed = semente
	else:
		_rng.randomize()


## Enfileira resultados que serão devolvidos, em ordem, pelas próximas rolagens.
func forcar(resultados: Array) -> void:
	for r in resultados:
		_fila.append(int(r))


## Estado do gerador, para salvar e continuar a mesma sequência depois.
func estado() -> int:
	return _rng.state


func restaurar_estado(valor: int) -> void:
	_rng.state = valor


func tem_resultados_forcados() -> bool:
	return not _fila.is_empty()


func rolar(faces: int) -> int:
	if not _fila.is_empty():
		var r: int = _fila.pop_front()
		assert(r >= 1 and r <= faces, "Resultado forçado %d fora de 1..%d" % [r, faces])
		return r
	return _rng.randi_range(1, faces)


func rolar_varios(quantidade: int, faces: int) -> Array[int]:
	var resultados: Array[int] = []
	for i in quantidade:
		resultados.append(rolar(faces))
	return resultados


## Rola uma expressão como "2d6+3". `multiplicador` multiplica só os dados (crítico).
func rolar_expressao(expressao: String, multiplicador: int = 1) -> int:
	var e := Dados.interpretar(expressao)
	var total: int = e.bonus
	for r in rolar_varios(e.quantidade * multiplicador, e.faces):
		total += r
	return total


## "2d6+3" -> {quantidade: 2, faces: 6, bonus: 3}. Aceita também "1d8-1" e "5".
static func interpretar(expressao: String) -> Dictionary:
	var texto := expressao.strip_edges().to_lower().replace(" ", "")
	var resultado := {"quantidade": 0, "faces": 0, "bonus": 0}
	var partes_bonus := texto.split("+")
	var principal := partes_bonus[0]
	var bonus := 0
	for i in range(1, partes_bonus.size()):
		bonus += int(partes_bonus[i])
	if "-" in principal:
		var p := principal.split("-")
		principal = p[0]
		for i in range(1, p.size()):
			bonus -= int(p[i])
	if "d" in principal:
		var dd := principal.split("d")
		resultado.quantidade = int(dd[0]) if dd[0] != "" else 1
		resultado.faces = int(dd[1])
	else:
		bonus += int(principal)
	resultado.bonus = bonus
	return resultado
