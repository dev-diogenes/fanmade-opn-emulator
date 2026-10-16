class_name Sessao
extends RefCounted
## A sessão de jogo (Fase 8, ADR 0007). As telas não chamam a lógica direto: montam um
## comando e o entregam aqui.
## - **local** (offline): aplica na hora, pela tela ativa.
## - **host**: confere se quem pediu é o dono do agente da vez, numera o comando, manda a
##   todos (sinal `transmitir`) e aplica.
## - **cliente**: pede ao host (sinal `pedir`) e só aplica o que volta numerado, em ordem e
##   quando a tela chega ao mesmo ponto; se o estado não bate com o do host, pede o estado de
##   novo (`pedir_estado`).
## A sessão guarda o checkpoint (a carreira na última troca de cena) e os comandos aplicados
## desde então: com os dois, um cliente que chega ou se perde refaz a partida.

signal comando_aplicado(cmd: Dictionary, resultado: Dictionary)
signal transmitir(seq: int, cmd: Dictionary, hash_antes: int)
signal pedir(cmd: Dictionary)
signal pedir_estado()
signal recusado(peer: int, cmd: Dictionary, motivo: String)

const LOCAL := "local"
const HOST := "host"
const CLIENTE := "cliente"
const PEER_DO_HOST := 1
const CONTEXTOS := {"mapa": Comandos.ACOES_MAPA, "investigacao": Comandos.ACOES_INVESTIGACAO, "combate": Comandos.ACOES_COMBATE, "mestre": Comandos.ACOES_MESTRE}
const MESTRE := "mestre"

var modo := LOCAL
## Tela ativa: "mapa", "combate" ou "investigacao"
var contexto := ""
var checkpoint: Dictionary = {}
var seq_checkpoint := 0
## Comandos aplicados desde o checkpoint (online, com "seq" e "hash_antes")
var registro: Array[Dictionary] = []
## Número do último comando aplicado
var seq := 0
## A tela está ocupada (animando os turnos da IA ou ainda montando): os comandos esperam.
var ocupado := false
## Host: func(peer, ser) -> bool. O Jogo monta a partir dos donos (ControleLocal); com mestre,
## o ser da vez pode ser uma ameaça, e o dono é o mestre.
var validar_dono := Callable()
## Host: func(peer) -> bool, para os comandos do mestre (ctx "mestre")
var validar_mestre := Callable()
var dessincronias := 0

var _aplicador := Callable()
var _aplicador_mestre := Callable()
var _quem_decide := Callable()
var _hash := Callable()
var _pedidos: Array[Dictionary] = []     ## host: [{peer, cmd}]
var _recebidos: Array[Dictionary] = []   ## cliente: comandos numerados, em ordem de seq
var _processando := false
var _ultimo_resultado: Dictionary = {}


func online() -> bool:
	return modo != LOCAL


# --- Telas ---------------------------------------------------------------------------

## A tela ativa se registra:
## - `aplicador(cmd) -> resultado` aplica na lógica e atualiza a tela;
## - `quem_decide() -> Agente` diz de quem é a vez (o host confere o dono);
## - `hash_estado() -> int` é o checksum do ponto de decisão.
## Ela começa ocupada: chama `liberar()` quando estiver pronta para comandos.
func entrar(ctx: String, aplicador: Callable, quem_decide := Callable(), hash_estado := Callable()) -> void:
	contexto = ctx
	_aplicador = aplicador
	_quem_decide = quem_decide
	_hash = hash_estado
	ocupado = online()


func sair(ctx: String) -> void:
	if contexto == ctx:
		contexto = ""
		_aplicador = Callable()
		_quem_decide = Callable()
		_hash = Callable()


## Quem aplica os comandos do mestre (o Jogo, na missão em andamento). Eles valem em qualquer tela.
func registrar_mestre(aplicador: Callable) -> void:
	_aplicador_mestre = aplicador


func liberar() -> void:
	ocupado = false
	processar_fila()


## Há comandos esperando para serem aplicados? (A arena dispensa as pausas da IA para alcançar.)
func atrasado() -> bool:
	return not _recebidos.is_empty()


## Novo ponto de partida (troca de cena): o estado é a carreira inteira, como no save.
func marcar_checkpoint(estado: Dictionary) -> void:
	checkpoint = estado
	seq_checkpoint = seq
	registro.clear()


# --- Comandos ---------------------------------------------------------------------------

## Entrega um comando da tela. Offline, aplica na hora; no host, valida, numera e aplica; no
## cliente, pede ao host (o resultado chega depois, por `comando_aplicado`).
func enviar(cmd: Dictionary) -> Dictionary:
	match modo:
		CLIENTE:
			pedir.emit(cmd.duplicate(true))
			return {"ok": true, "pendente": true}
		HOST:
			var antes := seq
			receber_pedido(PEER_DO_HOST, cmd)
			return _ultimo_resultado if seq > antes else {"ok": false, "pendente": not _pedidos.is_empty()}
	if String(cmd.get("ctx", "")) == MESTRE:
		if not _aplicador_mestre.is_valid():
			return {"ok": false, "erro": "sem missão para o mestre"}
		return _aplicar(cmd.duplicate(true))
	if String(cmd.get("ctx", "")) != contexto or not _aplicador.is_valid():
		return {"ok": false, "erro": "comando fora da tela ativa"}
	return _aplicar(cmd.duplicate(true))


## Host: um pedido chegou (de um cliente, ou do próprio host).
func receber_pedido(peer: int, cmd) -> void:
	if not _bem_formado(cmd):
		recusado.emit(peer, {}, "comando mal formado")
		return
	_pedidos.append({"peer": peer, "cmd": (cmd as Dictionary).duplicate(true)})
	processar_fila()


## Cliente: um comando numerado chegou do host.
func receber(numero: int, cmd: Dictionary, hash_antes: int) -> void:
	var e := cmd.duplicate(true)
	e["seq"] = numero
	e["hash_antes"] = hash_antes
	var i := _recebidos.size()
	while i > 0 and int(_recebidos[i - 1].seq) > numero:
		i -= 1
	_recebidos.insert(i, e)
	processar_fila()


## Aplica o que der: no host, os pedidos válidos; no cliente, os comandos na ordem certa.
func processar_fila() -> void:
	if _processando:
		return
	_processando = true
	while not ocupado and _aplicador.is_valid():
		if modo == HOST and not _pedidos.is_empty():
			if not _passo_do_host():
				break
		elif modo == CLIENTE and not _recebidos.is_empty():
			if not _passo_do_cliente():
				break
		else:
			break
	_processando = false


func _passo_do_host() -> bool:
	var p: Dictionary = _pedidos[0]
	var cmd: Dictionary = p.cmd
	if String(cmd.ctx) == MESTRE:
		cmd["tela"] = contexto   # o cliente aplica na mesma tela em que o host aceitou
	elif String(cmd.ctx) != contexto:
		if contexto == "":
			return false   # trocando de cena: o pedido espera
		_pedidos.pop_front()
		recusado.emit(int(p.peer), cmd, "a tela já mudou")
		return true
	_pedidos.pop_front()
	var motivo := _motivo_de_recusa(int(p.peer), cmd)
	if motivo != "":
		recusado.emit(int(p.peer), cmd, motivo)
		return true
	var h: int = _hash.call() if _hash.is_valid() else 0
	seq += 1
	transmitir.emit(seq, cmd, h)
	cmd["seq"] = seq
	cmd["hash_antes"] = h
	_aplicar(cmd)
	return true


func _passo_do_cliente() -> bool:
	var e: Dictionary = _recebidos[0]
	if int(e.seq) <= seq:
		_recebidos.pop_front()   # repetido
		return true
	var tela := String(e.get("tela", "")) if String(e.get("ctx", "")) == MESTRE else String(e.get("ctx", ""))
	if int(e.seq) != seq + 1 or tela != contexto:
		return false   # falta um anterior, ou a tela ainda não chegou lá
	if _hash.is_valid() and int(e.get("hash_antes", 0)) != 0 and _hash.call() != int(e.hash_antes):
		dessincronias += 1
		_recebidos.clear()
		ocupado = true
		pedir_estado.emit()
		return false
	_recebidos.pop_front()
	seq = int(e.seq)
	_aplicar(e)
	return true


func _motivo_de_recusa(peer: int, cmd: Dictionary) -> String:
	if String(cmd.get("ctx", "")) == MESTRE:
		if not _aplicador_mestre.is_valid():
			return "não há missão para o mestre"
		if validar_mestre.is_valid() and not validar_mestre.call(peer):
			return "só o mestre faz isso"
		return ""
	if String(cmd.get("acao", "")) == "sair":
		return ""   # a tela confere se a cena acabou
	var ser = _quem_decide.call() if _quem_decide.is_valid() else null
	if not ser is Ser:
		return "não é a vez de ninguém"
	if validar_dono.is_valid() and not validar_dono.call(peer, ser):
		return "a vez é de um agente de outro jogador" if ser is Agente else "a vez é do mestre"
	return ""


func _bem_formado(cmd) -> bool:
	if not cmd is Dictionary:
		return false
	var ctx := String(cmd.get("ctx", ""))
	return CONTEXTOS.has(ctx) and String(cmd.get("acao", "")) in CONTEXTOS[ctx]


func _aplicar(cmd: Dictionary) -> Dictionary:
	var res: Dictionary = _aplicador_mestre.call(cmd) if String(cmd.get("ctx", "")) == MESTRE else _aplicador.call(cmd)
	registro.append(cmd)
	_ultimo_resultado = res
	comando_aplicado.emit(cmd, res)
	return res


# --- Rede: modos e estado -------------------------------------------------------------

## Vira host. O que já foi aplicado desde o checkpoint ganha número (sem checksum).
func iniciar_host() -> void:
	modo = HOST
	for c in registro:
		if not c.has("seq"):
			seq += 1
			c["seq"] = seq
			c["hash_antes"] = 0
	ocupado = false


func iniciar_cliente() -> void:
	modo = CLIENTE
	_recebidos.clear()
	_pedidos.clear()


func voltar_ao_local() -> void:
	modo = LOCAL
	_recebidos.clear()
	_pedidos.clear()
	ocupado = false


## Host: o que um cliente precisa para chegar ao estado atual.
func pacote_de_estado() -> Dictionary:
	return {"checkpoint": checkpoint, "seq_checkpoint": seq_checkpoint, "registro": registro.duplicate(true), "seq": seq}


## Cliente: recomeça do checkpoint do host; os comandos desde então esperam na fila até a
## tela certa abrir (o Jogo troca de cena) e se liberar.
func receber_estado(pacote: Dictionary) -> void:
	checkpoint = pacote.get("checkpoint", {})
	seq = int(pacote.get("seq_checkpoint", 0))
	seq_checkpoint = seq
	registro.clear()
	_recebidos.clear()
	for c in pacote.get("registro", []):
		if int(c.get("seq", 0)) > seq:
			_recebidos.append(c.duplicate(true))
	_recebidos.sort_custom(func(a, b): return int(a.seq) < int(b.seq))
	ocupado = true
