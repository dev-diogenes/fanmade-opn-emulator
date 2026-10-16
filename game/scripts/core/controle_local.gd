class_name ControleLocal
extends RefCounted
## Co-op local (ADR 0004): até 4 jogadores no mesmo PC. Cada agente tem um dono (jogador),
## e na vez daquele agente só o dispositivo do dono controla o jogo.
## Online (ADR 0007): cada jogador tem o `peer` da máquina dele (1 = host). Uma máquina só
## age na vez dos agentes dos seus jogadores; os de outra máquina chegam pela rede.

const MAX_JOGADORES := 4
const TECLADO := "teclado"
const CONTROLE := "controle"
const REDE := "rede"
const PEER_DO_HOST := 1

## [{"dispositivo": "teclado" | "controle" | "rede", "indice": int, "peer": int, "nome": String}]
## Jogador 1 é o índice 0 (sempre do host)
var jogadores: Array[Dictionary] = []
## O peer desta máquina (não vai no save): 1 no host e offline
var meu_peer := PEER_DO_HOST
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
	jogadores.append({"dispositivo": dispositivo, "indice": indice, "peer": PEER_DO_HOST})
	return jogadores.size() - 1


## Jogador de outra máquina (online). Retorna o índice dele ou -1.
func adicionar_jogador_rede(peer: int, nome: String) -> int:
	if jogadores.size() >= MAX_JOGADORES:
		return -1
	jogadores.append({"dispositivo": REDE, "indice": 0, "peer": peer, "nome": nome})
	return jogadores.size() - 1


## A máquina saiu: os jogadores dela somem e os agentes voltam para o Jogador 1.
func remover_peer(peer: int) -> void:
	for j in range(jogadores.size() - 1, 0, -1):
		if peer_do_jogador(j) == peer:
			remover_jogador(j)


## Sem rede: só ficam os jogadores desta máquina.
func remover_remotos() -> void:
	for j in range(jogadores.size() - 1, 0, -1):
		if peer_do_jogador(j) != PEER_DO_HOST:
			remover_jogador(j)


func peer_do_jogador(j: int) -> int:
	return int(jogadores[j].get("peer", PEER_DO_HOST)) if j >= 0 and j < jogadores.size() else PEER_DO_HOST


func peer_de(agente: Agente) -> int:
	return peer_do_jogador(jogador_de(agente))


## O agente é desta máquina?
func e_local(agente: Agente) -> bool:
	return peer_de(agente) == meu_peer


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
	if j >= 0 and j < jogadores.size() and jogadores[j].dispositivo != REDE:
		jogadores[j] = {"dispositivo": dispositivo, "indice": indice, "peer": peer_do_jogador(j)}


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
	if jog.dispositivo == REDE:
		return "Jogador %d (online: %s)" % [j + 1, jog.get("nome", "?")]
	return "Jogador %d (%s)" % [j + 1, "teclado e mouse" if jog.dispositivo == TECLADO else "controle %d" % (int(jog.indice) + 1)]


## Faixa do topo das cenas: de quem é a vez. Vazia sem co-op.
func faixa_da_vez(agente: Agente) -> String:
	if not co_op() or agente == null:
		return ""
	return "Vez de %s — %s" % [agente.nome, descricao(jogador_de(agente))]


func usa_controle(agente: Agente) -> bool:
	return jogadores[jogador_de(agente)].dispositivo == CONTROLE and e_local(agente)


## Pode este evento agir agora? Sem co-op, sim. Com co-op, só o dispositivo do dono do agente da vez.
## `agente` nulo (vez de uma ameaça, cena sem agente) deixa tudo passar.
func evento_permitido(evento: InputEvent, agente: Agente) -> bool:
	if not co_op() or agente == null:
		return true
	if not e_local(agente):
		return false   # vez de um jogador de outra máquina
	var jog: Dictionary = jogadores[jogador_de(agente)]
	if jog.dispositivo == REDE:
		return true    # o jogador online, na máquina dele, usa o que tiver
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
		var jog := {"dispositivo": String(j.get("dispositivo", TECLADO)), "indice": int(j.get("indice", 0)), "peer": int(j.get("peer", PEER_DO_HOST))}
		if j.has("nome"):
			jog["nome"] = String(j.nome)
		c.jogadores.append(jog)
	if c.jogadores.is_empty():
		c.jogadores.append({"dispositivo": TECLADO, "indice": 0})
	for id in d.get("donos", {}):
		c.donos[id] = int(d.donos[id])
	return c
