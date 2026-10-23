class_name TesteEstendido
extends RefCounted
## Teste estendido (p.86-87, Tabela 4.2): o grupo junta sucessos antes de três falhas. Testes
## estendidos em grupo vão por rodadas, cada um faz um teste; na variante aberta, cada um
## escolhe a perícia e explica como ela ajuda. Aqui, cada agente usa a sua melhor perícia da
## lista que ainda não usou neste teste (docs/72: fuga e caçada).
##   var t := TesteEstendido.novo(20, "media", ["atletismo", "furtividade"])
##   t.testar(dados, agente) -> {agente, pericia, teste, sucesso}

const COMPLEXIDADE := {"baixa": 3, "media": 5, "alta": 7}
const FALHAS_MAXIMAS := 3

var dt := 15
var exigidos := 3
var complexidade := "baixa"
var pericias: Array = []
var sucessos := 0
var falhas := 0
var registros: Array = []          ## [{agente, pericia, teste, sucesso}]
var _usadas: Dictionary = {}       ## Agente -> [pericias]


static func novo(dt_: int, complexidade_: String, pericias_: Array) -> TesteEstendido:
	var t := TesteEstendido.new()
	t.dt = dt_
	t.complexidade = complexidade_
	t.exigidos = int(COMPLEXIDADE.get(complexidade_, 3))
	t.pericias = pericias_.duplicate()
	return t


func terminou() -> bool:
	return sucessos >= exigidos or falhas >= FALHAS_MAXIMAS


func venceu() -> bool:
	return sucessos >= exigidos


## A melhor perícia que o agente ainda não usou neste teste (todas usadas: a melhor de novo).
func melhor_pericia(a: Agente) -> String:
	var usadas: Array = _usadas.get(a, [])
	var melhor := ""
	var nota := -1000000
	for repetir in [false, true]:
		for p in pericias:
			if (p in usadas and not repetir) or not a.pode_usar_pericia(p):
				continue
			var n := a.dados_da_pericia(p) * 5 + a.bonus_pericia(p)
			if n > nota:
				nota = n
				melhor = String(p)
		if melhor != "":
			break
	return melhor


func testar(dados: Dados, a: Agente) -> Dictionary:
	if terminou():
		return {}
	var p := melhor_pericia(a)
	if p == "":
		return {}
	var t := a.testar(dados, p, dt)
	var ok := t != null and t.sucesso
	if ok:
		sucessos += 1
	else:
		falhas += 1
	var usadas: Array = _usadas.get_or_add(a, [])
	usadas.append(p)
	var r := {"agente": a, "pericia": p, "teste": t, "sucesso": ok}
	registros.append(r)
	return r


func placar() -> String:
	return "%d/%d sucessos · %d/%d falhas" % [sucessos, exigidos, falhas, FALHAS_MAXIMAS]
