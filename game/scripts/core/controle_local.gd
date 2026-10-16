class_name ControleLocal
extends RefCounted
## Co-op local (ADR 0004): até 4 jogadores no mesmo PC. Cada agente tem um dono (jogador),
## e na vez daquele agente só o dispositivo do dono controla o jogo.

const MAX_JOGADORES := 4
const TECLADO := "teclado"
const CONTROLE := "controle"

## [{"dispositivo": "teclado" | "controle", "indice": int}] — Jogador 1 é o índice 0
var jogadores: Array[Dictionary] = []
## agente_id -> índice do jogador
var donos: Dictionary = {}


static func padrao() -> ControleLocal:
	var c := ControleLocal.new()
	c.jogadores.append({"dispositivo": TECLADO, "indice": 0})
	return c


func co_op() -> bool:
	return jogadores.size() > 1


## Adiciona um jogador (até 4). Retorna o índice dele ou -1.
func adicionar_jogador(dispositivo: String, indice: int = 0) -> int:
	if jogadores.size() >= MAX_JOGADORES:
		return -1
	jogadores.append({"dispositivo": dispositivo, "indice": indice})
	return jogadores.size() - 1


## Remove um jogador; os agentes dele voltam para o Jogador 1.
func remover_jogador(j: int) -> void:
	if j <= 0 or j >= jogadores.size():
		return
	jogadores.remove_at(j)
	for id in donos.keys():
		if int(donos[id]) == j:
			donos.erase(id)
		elif int(donos[id]) > j:
			donos[id] = int(donos[id]) - 1


func definir_dispositivo(j: int, dispositivo: String, indice: int = 0) -> void:
	if j >= 0 and j < jogadores.size():
		jogadores[j] = {"dispositivo": dispositivo, "indice": indice}


func definir_dono(agente: Agente, j: int) -> void:
	if j <= 0 or j >= jogadores.size():
		donos.erase(agente.id)
	else:
		donos[agente.id] = j


func jogador_de(agente: Agente) -> int:
	if agente == null:
		return 0
	var j := int(donos.get(agente.id, 0))
	return j if j < jogadores.size() else 0


## "Jogador 2 (controle 1)" ou "Jogador 1 (teclado)".
func descricao(j: int) -> String:
	if j < 0 or j >= jogadores.size():
		return "Jogador ?"
	var jog: Dictionary = jogadores[j]
	return "Jogador %d (%s)" % [j + 1, "teclado e mouse" if jog.dispositivo == TECLADO else "controle %d" % (int(jog.indice) + 1)]


## Faixa do topo das cenas: de quem é a vez. Vazia sem co-op.
func faixa_da_vez(agente: Agente) -> String:
	if not co_op() or agente == null:
		return ""
	return "Vez de %s — %s" % [agente.nome, descricao(jogador_de(agente))]


func usa_controle(agente: Agente) -> bool:
	return jogadores[jogador_de(agente)].dispositivo == CONTROLE


## Pode este evento agir agora? Sem co-op, sim. Com co-op, só o dispositivo do dono do agente da vez.
## `agente` nulo (vez de uma ameaça, cena sem agente) deixa tudo passar.
func evento_permitido(evento: InputEvent, agente: Agente) -> bool:
	if not co_op() or agente == null:
		return true
	var jog: Dictionary = jogadores[jogador_de(agente)]
	if evento is InputEventJoypadButton or evento is InputEventJoypadMotion:
		return jog.dispositivo == CONTROLE and evento.device == int(jog.indice)
	if evento is InputEventKey or evento is InputEventMouse:
		return jog.dispositivo == TECLADO
	return true


func para_dicionario() -> Dictionary:
	return {"jogadores": jogadores.duplicate(true), "donos": donos.duplicate()}


static func de_dicionario(d: Dictionary) -> ControleLocal:
	var c := ControleLocal.new()
	for j in d.get("jogadores", []):
		c.jogadores.append({"dispositivo": String(j.get("dispositivo", TECLADO)), "indice": int(j.get("indice", 0))})
	if c.jogadores.is_empty():
		c.jogadores.append({"dispositivo": TECLADO, "indice": 0})
	for id in d.get("donos", {}):
		c.donos[id] = int(d.donos[id])
	return c
