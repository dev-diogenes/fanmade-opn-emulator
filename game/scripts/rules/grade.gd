class_name Grade
extends RefCounted
## Grade tática de combate (p.84-89, p.99): quadrados de 1,5 m, diagonal custa o dobro,
## terreno difícil custa o dobro, alcances em quadrados, flanco e cobertura.
## Lógica pura: a cena 2D/3D só desenha o que esta classe decide.

const METROS_POR_QUADRADO := 1.5
## Alcance em quadrados (p.66, p.130). Até o dobro do alcance, o ataque perde 1 dado.
const ALCANCES := {"curto": 6, "medio": 12, "longo": 24, "extremo": 60}

const PAREDE := "parede"                  ## bloqueia movimento e visão (cobertura total)
const COBERTURA := "cobertura"            ## caixote, carro, muro baixo: +5 Defesa contra tiros que passam
const DIFICIL := "dificil"                ## terreno difícil: custo dobrado

var largura := 0
var altura := 0
var terreno: Dictionary = {}   ## Vector2i -> PAREDE | COBERTURA | DIFICIL
var _posicoes: Dictionary = {} ## Ser -> Vector2i


func _init(p_largura: int, p_altura: int) -> void:
	largura = p_largura
	altura = p_altura


# --- Ocupação --------------------------------------------------------------

func dentro(celula: Vector2i) -> bool:
	return celula.x >= 0 and celula.y >= 0 and celula.x < largura and celula.y < altura


func bloqueada(celula: Vector2i) -> bool:
	return not dentro(celula) or terreno.get(celula, "") in [PAREDE, COBERTURA]


func colocar(ser: Ser, celula: Vector2i) -> bool:
	if bloqueada(celula) or (ocupante(celula) != null and ocupante(celula) != ser):
		return false
	_posicoes[ser] = celula
	return true


func remover(ser: Ser) -> void:
	_posicoes.erase(ser)


func posicao(ser: Ser) -> Vector2i:
	return _posicoes.get(ser, Vector2i(-1, -1))


func tem(ser: Ser) -> bool:
	return _posicoes.has(ser)


func ocupante(celula: Vector2i) -> Ser:
	for s in _posicoes:
		if _posicoes[s] == celula and not s.tem(Ser.MORTO):
			return s
	return null


func seres() -> Array[Ser]:
	var lista: Array[Ser] = []
	for s in _posicoes:
		lista.append(s)
	return lista


# --- Distâncias ------------------------------------------------------------

## Distância em quadrados com a regra do livro: cada diagonal conta como 2 quadrados.
static func distancia(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Adjacente = qualquer um dos 8 vizinhos (1,5 m), como no corpo a corpo (p.85).
static func adjacentes(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


func distancia_entre(a: Ser, b: Ser) -> int:
	return distancia(posicao(a), posicao(b))


func estao_adjacentes(a: Ser, b: Ser) -> bool:
	return tem(a) and tem(b) and adjacentes(posicao(a), posicao(b))


## "ok", "longe" (até o dobro do alcance, −1 dado) ou "fora".
func faixa_de_alcance(a: Ser, b: Ser, categoria: String) -> String:
	var limite := int(ALCANCES.get(categoria, 0))
	var d := distancia_entre(a, b)
	if d <= limite:
		return "ok"
	if d <= limite * 2:
		return "longe"
	return "fora"


func em_alcance(a: Ser, b: Ser, categoria: String) -> bool:
	return faixa_de_alcance(a, b, categoria) == "ok"


# --- Situações de combate --------------------------------------------------

## Algum inimigo (lado diferente, de pé) adjacente ao ser?
func em_corpo_a_corpo(ser: Ser) -> bool:
	for outro in _posicoes:
		if outro.lado != ser.lado and not outro.esta_fora_de_combate() and estao_adjacentes(ser, outro):
			return true
	return false


## Flanquear (p.89): atacante e um aliado adjacentes ao alvo, em lados opostos.
func flanqueando(atacante: Ser, alvo: Ser) -> bool:
	if not estao_adjacentes(atacante, alvo):
		return false
	var oposto := posicao(alvo) * 2 - posicao(atacante)
	var aliado := ocupante(oposto)
	return aliado != null and aliado != atacante and aliado.lado == atacante.lado and not aliado.esta_fora_de_combate()


## Células na linha reta entre duas posições, sem as pontas (Bresenham).
static func linha(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var celulas: Array[Vector2i] = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var erro := dx + dy
	var atual := a
	while atual != b:
		var e2 := 2 * erro
		if e2 >= dy:
			erro += dy
			atual.x += sx
		if e2 <= dx:
			erro += dx
			atual.y += sy
		if atual != b:
			celulas.append(atual)
	return celulas


## "nenhuma", "leve" (+5 Defesa) ou "total" (não pode ser alvo) para um ataque à distância (p.99).
## Simplificação: a linha liga os centros dos quadrados em vez dos cantos.
func cobertura(atacante: Ser, alvo: Ser) -> String:
	var resultado := "nenhuma"
	for c in linha(posicao(atacante), posicao(alvo)):
		var t: String = terreno.get(c, "")
		if t == PAREDE:
			return "total"
		var no_meio := ocupante(c)
		if t == COBERTURA or (no_meio != null and not no_meio.esta_fora_de_combate()):
			resultado = "leve"
	return resultado


# --- Movimento -------------------------------------------------------------

## Custo de entrar numa célula vinda de `de`: 1 (ortogonal) ou 2 (diagonal), dobrado em terreno difícil.
func custo_passo(de: Vector2i, para: Vector2i) -> int:
	var custo := 2 if de.x != para.x and de.y != para.y else 1
	if terreno.get(para, "") == DIFICIL:
		custo *= 2
	return custo


## Custos mínimos (em quadrados) a partir da posição do ser, até `limite`.
## Atravessa aliados, mas não inimigos de pé (p.99). Retorna {Vector2i: custo}.
func alcancaveis(ser: Ser, limite: int) -> Dictionary:
	var inicio := posicao(ser)
	var custos := {inicio: 0}
	var fila: Array = [inicio]
	while not fila.is_empty():
		# Fila simples ordenada pelo custo (grades pequenas; suficiente para o combate)
		fila.sort_custom(func(x, y): return custos[x] < custos[y])
		var atual: Vector2i = fila.pop_front()
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var prox: Vector2i = atual + Vector2i(dx, dy)
				if bloqueada(prox):
					continue
				var quem := ocupante(prox)
				if quem != null and quem.lado != ser.lado and not quem.esta_fora_de_combate():
					continue
				var novo: int = custos[atual] + custo_passo(atual, prox)
				if novo <= limite and novo < int(custos.get(prox, 1 << 30)):
					custos[prox] = novo
					fila.append(prox)
	return custos


## Destinos válidos para terminar o movimento (não pode parar sobre outro ser).
func destinos(ser: Ser, limite: int) -> Array[Vector2i]:
	var lista: Array[Vector2i] = []
	var custos := alcancaveis(ser, limite)
	for c in custos:
		if c != posicao(ser) and ocupante(c) == null:
			lista.append(c)
	return lista


## Move o ser se o destino estiver ao alcance do deslocamento (em quadrados). Retorna o custo ou -1.
func mover(ser: Ser, destino: Vector2i, limite: int) -> int:
	var custos := alcancaveis(ser, limite)
	if not custos.has(destino) or destino == posicao(ser) or ocupante(destino) != null:
		return -1
	_posicoes[ser] = destino
	return int(custos[destino])


## Célula livre mais próxima de `alvo` que o ser alcança neste movimento (para a IA).
func aproximar(ser: Ser, alvo: Ser, limite: int) -> Vector2i:
	var melhor := posicao(ser)
	var melhor_dist := distancia(melhor, posicao(alvo))
	for c in destinos(ser, limite):
		var d := distancia(c, posicao(alvo))
		if d < melhor_dist or (d == melhor_dist and adjacentes(c, posicao(alvo))):
			melhor = c
			melhor_dist = d
	return melhor
