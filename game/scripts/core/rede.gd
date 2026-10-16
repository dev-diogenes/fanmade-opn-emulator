class_name Rede
extends Node
## Rede (Fase 8.2, ADR 0007): ENet por IP e porta, pelo multiplayer de alto nível do Godot.
## Não sabe nada do jogo. Ela só transporta:
## - os pedidos dos clientes ao host;
## - os comandos numerados do host a todos;
## - o estado (checkpoint + registro, comprimido) para quem chega ou se perdeu;
## - o saguão e os donos dos agentes.
## A Sessao cuida da ordem e da validação; o Jogo, das cenas.

signal jogador_entrou(peer: int, nome: String)
signal jogador_saiu(peer: int, nome: String)
signal conectado(meu_peer: int)
signal conexao_perdida(motivo: String)
signal estado_recebido(pacote: Dictionary)
signal estado_pedido(peer: int)
signal saguao_recebido(info: Dictionary)
signal controles_recebidos(dados: Dictionary)
signal aviso(texto: String)

const PORTA_PADRAO := 7777
const VERSAO_PROTOCOLO := 1
const MAX_CLIENTES := 3

var sessao: Sessao
var nome_local := "Jogador"
## Host: peer -> nome dos clientes que já se apresentaram
var nomes: Dictionary = {}
var porta := 0
var endereco := ""
var _encerrando := false


func ligar(s: Sessao) -> void:
	sessao = s
	s.transmitir.connect(_ao_transmitir)
	s.pedir.connect(_ao_pedir)
	s.pedir_estado.connect(_ao_pedir_estado)
	s.recusado.connect(_ao_recusar)


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_ao_desconectar_peer)
	multiplayer.connected_to_server.connect(_ao_conectar_no_host)
	multiplayer.connection_failed.connect(func(): _encerrar_com("Não deu para conectar ao host."))
	multiplayer.server_disconnected.connect(func(): _encerrar_com("O host encerrou a sessão."))


func eh_host() -> bool:
	return sessao != null and sessao.modo == Sessao.HOST


func eh_cliente() -> bool:
	return sessao != null and sessao.modo == Sessao.CLIENTE


func online() -> bool:
	return eh_host() or eh_cliente()


func meu_peer() -> int:
	return multiplayer.get_unique_id() if online() else Sessao.PEER_DO_HOST


# --- Abrir e fechar ------------------------------------------------------------------

func hospedar(porta_: int = PORTA_PADRAO) -> Error:
	encerrar()
	var peer := ENetMultiplayerPeer.new()
	var erro := peer.create_server(porta_, MAX_CLIENTES)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = peer
	porta = porta_
	nomes.clear()
	sessao.iniciar_host()
	return OK


func entrar(endereco_: String, porta_: int, nome: String) -> Error:
	encerrar()
	var peer := ENetMultiplayerPeer.new()
	var erro := peer.create_client(endereco_, porta_)
	if erro != OK:
		return erro
	multiplayer.multiplayer_peer = peer
	endereco = endereco_
	porta = porta_
	nome_local = nome if nome.strip_edges() != "" else "Jogador"
	sessao.iniciar_cliente()
	return OK


func encerrar() -> void:
	_encerrando = true
	var atual := multiplayer.multiplayer_peer
	if atual != null and not atual is OfflineMultiplayerPeer:
		atual.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	nomes.clear()
	if sessao != null and sessao.online():
		sessao.voltar_ao_local()
	_encerrando = false


func _encerrar_com(motivo: String) -> void:
	if _encerrando:
		return
	var era_cliente := eh_cliente()
	encerrar()
	if era_cliente:
		conexao_perdida.emit(motivo)
	else:
		aviso.emit(motivo)


# --- Entrada de jogadores ---------------------------------------------------------------

func _ao_conectar_no_host() -> void:
	_ola.rpc_id(Sessao.PEER_DO_HOST, nome_local, VERSAO_PROTOCOLO)
	conectado.emit(multiplayer.get_unique_id())


func _ao_desconectar_peer(peer: int) -> void:
	if eh_host() and nomes.has(peer):
		var nome: String = nomes[peer]
		nomes.erase(peer)
		jogador_saiu.emit(peer, nome)


@rpc("any_peer", "call_remote", "reliable")
func _ola(nome: String, versao: int) -> void:
	if not eh_host():
		return
	var peer := multiplayer.get_remote_sender_id()
	if versao != VERSAO_PROTOCOLO:
		_recusar_entrada.rpc_id(peer, "A versão do jogo é diferente da do host.")
		return
	var limpo := nome.strip_edges().substr(0, 24)
	nomes[peer] = limpo if limpo != "" else "Jogador"
	jogador_entrou.emit(peer, nomes[peer])


@rpc("authority", "call_remote", "reliable")
func _recusar_entrada(motivo: String) -> void:
	_encerrar_com(motivo)


## Host: manda o cliente embora com um motivo.
func recusar(peer: int, motivo: String) -> void:
	if eh_host():
		nomes.erase(peer)
		_recusar_entrada.rpc_id(peer, motivo)


# --- Comandos e estado -------------------------------------------------------------------

func _ao_transmitir(numero: int, cmd: Dictionary, hash_antes: int) -> void:
	if eh_host():
		_comando.rpc(numero, cmd, hash_antes)


func _ao_pedir(cmd: Dictionary) -> void:
	if eh_cliente():
		_pedido.rpc_id(Sessao.PEER_DO_HOST, cmd)


func _ao_pedir_estado() -> void:
	if eh_cliente():
		_pedir_estado.rpc_id(Sessao.PEER_DO_HOST)


func _ao_recusar(peer: int, _cmd: Dictionary, motivo: String) -> void:
	if eh_host() and nomes.has(peer):
		_avisar.rpc_id(peer, "O host recusou a ação: %s." % motivo)


@rpc("any_peer", "call_remote", "reliable")
func _pedido(cmd: Dictionary) -> void:
	var peer := multiplayer.get_remote_sender_id()
	if eh_host() and nomes.has(peer):
		sessao.receber_pedido(peer, cmd)


@rpc("authority", "call_remote", "reliable")
func _comando(numero: int, cmd: Dictionary, hash_antes: int) -> void:
	if eh_cliente():
		sessao.receber(numero, cmd, hash_antes)


## Host: manda o checkpoint e os comandos desde então (com `extra`, como os donos) a um
## cliente ou, com peer 0, a todos.
func enviar_estado(peer: int = 0, extra: Dictionary = {}) -> void:
	if not eh_host():
		return
	var pacote := sessao.pacote_de_estado()
	pacote.merge(extra, true)
	var bruto := var_to_bytes(pacote)
	var z := bruto.compress(FileAccess.COMPRESSION_ZSTD)
	if peer == 0:
		_estado.rpc(z, bruto.size())
	else:
		_estado.rpc_id(peer, z, bruto.size())


@rpc("authority", "call_remote", "reliable")
func _estado(dados: PackedByteArray, tamanho: int) -> void:
	if not eh_cliente():
		return
	var pacote = bytes_to_var(dados.decompress(tamanho, FileAccess.COMPRESSION_ZSTD))
	if pacote is Dictionary:
		sessao.receber_estado(pacote)
		estado_recebido.emit(pacote)


@rpc("any_peer", "call_remote", "reliable")
func _pedir_estado() -> void:
	var peer := multiplayer.get_remote_sender_id()
	if eh_host() and nomes.has(peer):
		estado_pedido.emit(peer)


# --- Saguão, donos e avisos ------------------------------------------------------------------

func enviar_saguao(info: Dictionary, peer: int = 0) -> void:
	if not eh_host():
		return
	if peer == 0:
		_saguao.rpc(info)
	else:
		_saguao.rpc_id(peer, info)


@rpc("authority", "call_remote", "reliable")
func _saguao(info: Dictionary) -> void:
	if eh_cliente():
		saguao_recebido.emit(info)


func enviar_controles(dados: Dictionary) -> void:
	if eh_host():
		_controles.rpc(dados)


@rpc("authority", "call_remote", "reliable")
func _controles(dados: Dictionary) -> void:
	if eh_cliente():
		controles_recebidos.emit(dados)


@rpc("authority", "call_remote", "reliable")
func _avisar(texto: String) -> void:
	aviso.emit(texto)
