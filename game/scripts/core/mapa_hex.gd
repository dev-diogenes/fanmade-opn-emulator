class_name MapaHex
extends RefCounted
## Mapa-múndi: terreno, conteúdo e névoa de cada hex, mais a busca de caminhos.
## Cada célula: {"terreno": String, "conteudo": Dictionary, "revelado": bool}
## Conteúdo: {} | {"tipo": "inicio"|"vila"|"encontro"|"evento"|"objetivo", ...}

var celulas: Dictionary = {}   ## Vector2i -> Dictionary
var terrenos: Dictionary = {}  ## id -> {"custo": int, ...} (de mapa.json)
var colunas := 0
var linhas := 0


func _init(p_terrenos: Dictionary = {}) -> void:
	terrenos = p_terrenos


func tem(h: Vector2i) -> bool:
	return celulas.has(h)


func celula(h: Vector2i) -> Dictionary:
	return celulas.get(h, {})


func terreno(h: Vector2i) -> String:
	return celula(h).get("terreno", "")


## Custo para ENTRAR no hex; -1 = intransponível. `escalar` (docs/34): quem tirou 20 nos
## dados de movimento do turno sobe a serra, pagando o `custo_escalada` do terreno.
func custo(h: Vector2i, escalar: bool = false) -> int:
	if not tem(h):
		return -1
	var t: Dictionary = terrenos.get(terreno(h), {})
	if escalar and t.get("escalavel", false):
		return int(t.get("custo_escalada", 2))
	return int(t.get("custo", 1))


func passavel(h: Vector2i, escalar: bool = false) -> bool:
	return custo(h, escalar) > 0


## Terreno bloqueado que dá para escalar (a serra).
func escalavel(h: Vector2i) -> bool:
	return bool(terrenos.get(terreno(h), {}).get("escalavel", false))


func conteudo(h: Vector2i) -> Dictionary:
	return celula(h).get("conteudo", {})


func definir_conteudo(h: Vector2i, c: Dictionary) -> void:
	celulas[h]["conteudo"] = c


func limpar_conteudo(h: Vector2i) -> void:
	celulas[h]["conteudo"] = {}


func revelado(h: Vector2i) -> bool:
	return celula(h).get("revelado", false)


func revelar(centro: Vector2i, raio: int) -> void:
	for h in Hex.area(centro, raio):
		if tem(h):
			celulas[h]["revelado"] = true


## Primeiro hex com conteúdo do tipo dado (ou Vector2i(-999, -999)).
func encontrar(tipo: String) -> Vector2i:
	for h in celulas:
		if conteudo(h).get("tipo", "") == tipo:
			return h
	return Vector2i(-999, -999)


## Custos mínimos a partir de `inicio` até `limite` (Dijkstra simples).
## `parar_em_conteudo`: não atravessa hexes com conteúdo (entra neles, mas não passa adiante).
func alcancaveis(inicio: Vector2i, limite: int, parar_em_conteudo: bool = true, escalar: bool = false) -> Dictionary:
	var custos := {inicio: 0}
	var fila: Array = [inicio]
	while not fila.is_empty():
		fila.sort_custom(func(a, b): return custos[a] < custos[b])
		var atual: Vector2i = fila.pop_front()
		if parar_em_conteudo and atual != inicio and not conteudo(atual).is_empty():
			continue
		for v in Hex.vizinhos(atual):
			if not passavel(v, escalar):
				continue
			var novo: int = custos[atual] + custo(v, escalar)
			if novo <= limite and novo < int(custos.get(v, 1 << 30)):
				custos[v] = novo
				fila.append(v)
	return custos


## Caminho (lista de hexes, sem o inicial) de menor custo, ou [] se não houver.
func caminho(inicio: Vector2i, destino: Vector2i, parar_em_conteudo: bool = true, escalar: bool = false) -> Array[Vector2i]:
	var custos := {inicio: 0}
	var veio: Dictionary = {}
	var fila: Array = [inicio]
	while not fila.is_empty():
		fila.sort_custom(func(a, b): return custos[a] < custos[b])
		var atual: Vector2i = fila.pop_front()
		if atual == destino:
			break
		if parar_em_conteudo and atual != inicio and not conteudo(atual).is_empty():
			continue
		for v in Hex.vizinhos(atual):
			if not passavel(v, escalar):
				continue
			var novo: int = custos[atual] + custo(v, escalar)
			if novo < int(custos.get(v, 1 << 30)):
				custos[v] = novo
				veio[v] = atual
				fila.append(v)
	var resultado: Array[Vector2i] = []
	if not custos.has(destino) or destino == inicio:
		return resultado
	var h := destino
	while h != inicio:
		resultado.push_front(h)
		h = veio[h]
	return resultado


func custo_do_caminho(passos: Array[Vector2i], escalar: bool = false) -> int:
	var total := 0
	for h in passos:
		total += custo(h, escalar)
	return total


func para_dicionario() -> Dictionary:
	var lista: Array = []
	for h in celulas:
		var c: Dictionary = celulas[h]
		lista.append({"q": h.x, "r": h.y, "terreno": c.terreno, "conteudo": c.conteudo, "revelado": c.revelado})
	return {"colunas": colunas, "linhas": linhas, "celulas": lista}


func de_dicionario(d: Dictionary) -> void:
	colunas = int(d.get("colunas", 0))
	linhas = int(d.get("linhas", 0))
	celulas.clear()
	for c in d.get("celulas", []):
		celulas[Vector2i(int(c.q), int(c.r))] = {"terreno": c.terreno, "conteudo": c.conteudo, "revelado": c.revelado}
