extends Node
## Autoload "Jogo": guarda a carreira (e a missão em andamento) entre as cenas
## Base <-> Mapa <-> Arena e salva automaticamente em user://carreira.json.
## Online (Fase 8.2, ADR 0007): o host joga a própria carreira e manda o estado a quem entra;
## o cliente guarda a carreira dele de lado e joga a do host, sem salvar, até sair.

const CENA_TITULO := "res://scenes/titulo.tscn"
const CENA_BASE := "res://scenes/base_ordem.tscn"
const CENA_MAPA := "res://scenes/mapa_mundo.tscn"
const CENA_ARENA := "res://scenes/arena_teste.tscn"
const CENA_INVESTIGACAO := "res://scenes/investigacao.tscn"
const CENA_EDITOR := "res://scenes/editor_missao.tscn"
const CENA_SAGUAO := "res://scenes/saguao.tscn"

signal jogadores_mudaram()
signal saguao_mudou()

var carreira: Carreira
## Configuração do combate que a arena deve montar (vazia = arena de demonstração)
var combate_config: Dictionary = {}
## false nos testes automáticos, para não mexer no save do jogador
var salvar_automaticamente := true
## Comandos das telas e checkpoints (ADR 0007)
var sessao := Sessao.new()
var rede: Rede
## Cliente: o que o host mandou para o saguão
var saguao_info: Dictionary = {}
## Último aviso da rede (conexão perdida, ação recusada), mostrado na Base e no saguão
var aviso_rede := ""
var _carreira_local: Carreira

var missao: Missao:
	get:
		return carreira.missao if carreira != null else null


func _ready() -> void:
	_isolar_testes()
	_modo_captura()
	Tema.aplicar()
	Tema.aplicar_escala(get_tree().root)
	get_tree().root.size_changed.connect(func(): Tema.aplicar_escala(get_tree().root))
	# Toda tela nova entra com estática e o nome do arquivo datilografado (docs/10)
	get_tree().node_added.connect(_ao_entrar_no)
	var som := Som.new()
	som.name = "Som"
	add_child(som)
	Entrada.configurar()
	rede = Rede.new()
	rede.name = "Rede"
	add_child(rede)
	rede.ligar(sessao)
	sessao.validar_dono = func(peer, ser): return controles().mestre_peer() == peer if ser is Ameaca else controles().peer_de(ser) == peer
	sessao.validar_mestre = func(peer): return controles().mestre_peer() == peer
	sessao.registrar_mestre(_aplicar_mestre)
	rede.jogador_entrou.connect(_ao_entrar_jogador)
	rede.jogador_saiu.connect(_ao_sair_jogador)
	rede.estado_pedido.connect(_ao_pedirem_estado)
	rede.estado_recebido.connect(_ao_receber_estado)
	rede.saguao_recebido.connect(_ao_receber_saguao)
	rede.controles_recebidos.connect(_ao_receber_controles)
	rede.conexao_perdida.connect(_ao_perder_conexao)
	rede.aviso.connect(func(t): aviso_rede = t)


## H abre a folha de atalhos em qualquer tela (docs/18, A4). As telas tratam as próprias
## teclas antes: esta só recebe o que ninguém usou.
func _unhandled_key_input(evento: InputEvent) -> void:
	if Atalhos.pressionou(evento, "folha_atalhos") and not FolhaAtalhos.aberta(get_tree().root):
		get_viewport().set_input_as_handled()
		FolhaAtalhos.abrir(get_tree().current_scene if get_tree().current_scene != null else self)


func _ao_entrar_no(no: Node) -> void:
	# Todo botão do jogo faz um clique seco; passar o mouse, um tique baixo (docs/11)
	if no is BaseButton:
		var b := no as BaseButton
		b.pressed.connect(func(): Som.tocar("clique"))
		b.mouse_entered.connect(func():
			if not b.disabled:
				Som.tocar("hover"))
		return
	if no.get_parent() == get_tree().root and no.scene_file_path.begins_with("res://scenes/") and no.scene_file_path != CENA_TITULO:
		Som.musica("")
	if no.get_parent() == get_tree().root and no.scene_file_path in [CENA_BASE, CENA_EDITOR, CENA_SAGUAO]:
		Som.ambiente(0.0)   # a Base é um lugar seguro: só o drone baixo
	if no.get_parent() != get_tree().root or no.scene_file_path == "" or not Preferencias.efeito("transicoes"):
		return
	if not no.scene_file_path.begins_with("res://scenes/"):
		return
	get_tree().root.add_child.call_deferred(Transicao.new(Transicao.para_cena(no.scene_file_path)))


## Captura de tela para a documentação: `godot --path game <cena> -- --captura=arquivo.png`.
## Não salva a carreira; espera a cena assentar, grava a imagem e fecha.
## Rodando a suíte de testes (GUT), o save e as preferências vão para arquivos de teste:
## antes, um teste que religava o salvamento automático sobrescrevia o save do jogador.
func _isolar_testes() -> void:
	for arg in OS.get_cmdline_args():
		if String(arg).contains("gut_cmdln"):
			Carreira.arquivo_padrao = "user://teste_carreira.json"
			Preferencias.caminho = "user://teste_preferencias.json"
			return


func _modo_captura() -> void:
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--captura="):
			continue
		salvar_automaticamente = false
		var caminho: String = arg.trim_prefix("--captura=")
		for i in 90:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(caminho)
		get_tree().quit()


## Jogadores locais da carreira (um só, no teclado, se ainda não houver carreira).
func controles() -> ControleLocal:
	return carreira.controles if carreira != null else ControleLocal.padrao()


func carregar_ou_criar() -> Carreira:
	if carreira == null:
		carreira = Carreira.carregar()
	if carreira == null:
		carreira = Carreira.nova()
	return carreira


func nova_carreira() -> Carreira:
	carreira = Carreira.nova()
	salvar()
	return carreira


## Compatibilidade: missão avulsa (cena do mapa aberta direto, sem passar pela Base).
func nova_missao(semente: int = -1) -> Missao:
	carregar_ou_criar()
	if carreira.missao == null:
		var grupo := carreira.roster.slice(0, mini(3, carreira.roster.size()))
		carreira.iniciar_missao(grupo, semente if semente >= 0 else randi() % 1000000)
	return carreira.missao


func iniciar_missao(grupo: Array, semente: int = -1) -> Missao:
	var m := carreira.iniciar_missao(grupo, semente if semente >= 0 else randi() % 1000000)
	if m != null:
		salvar()
		_mandar_estado()
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
	return m


func iniciar_missao_comunidade(grupo: Array, definicao: Dictionary, semente: int = -1) -> Missao:
	var m := carreira.iniciar_missao_comunidade(grupo, definicao, semente if semente >= 0 else randi() % 1000000)
	if m != null:
		salvar()
		_mandar_estado()
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
	return m


func iniciar_missao_campanha(grupo: Array, campanha: Dictionary, semente: int = -1) -> Missao:
	var m := carreira.iniciar_missao_campanha(grupo, campanha, semente if semente >= 0 else randi() % 1000000)
	if m != null:
		salvar()
		_mandar_estado()
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
	return m


func ir_para_base() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_BASE)


func ir_para_editor() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_EDITOR)


func ir_para_combate(config: Dictionary) -> void:
	combate_config = config
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_ARENA)


func voltar_do_combate(vencedor: String, rendidos: int = 0) -> void:
	if missao != null:
		missao.concluir_encontro(vencedor, rendidos)
	combate_config = {}
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func ir_para_investigacao() -> void:
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_INVESTIGACAO)


func voltar_da_investigacao(resultado: Dictionary) -> void:
	if missao != null:
		missao.concluir_investigacao(resultado)
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func voltar_para_base() -> void:
	if rede.eh_cliente():
		ir_para_saguao()
		return
	if carreira != null and missao != null and missao.encerrada:
		carreira.encerrar_missao()
	salvar()
	if rede.eh_host():
		rede.enviar_saguao(_info_saguao())
	get_tree().change_scene_to_file.call_deferred(CENA_BASE)


func continuar_missao() -> void:
	if missao != null:
		salvar()
		_mandar_estado()
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


## Toda troca de cena salva a carreira e marca o checkpoint da sessão. O cliente não salva:
## a carreira que ele joga é a do host.
func salvar() -> void:
	if carreira == null:
		return
	sessao.marcar_checkpoint(carreira.para_dicionario())
	if salvar_automaticamente and not (rede != null and rede.eh_cliente()):
		carreira.salvar()


## Comandos do mestre (Fase 8.3): mexem na missão em andamento, em qualquer tela.
func _aplicar_mestre(cmd: Dictionary) -> Dictionary:
	if missao == null:
		return {"ok": false, "erro": "sem missão"}
	return Comandos.aplicar_mestre(missao, cmd)


## A missão em andamento tem mestre, e esta máquina faz esse papel?
func sou_mestre() -> bool:
	return missao != null and bool(missao.opcoes.get("mestre", false)) and controles().e_mestre_local()


# --- Online (Fase 8.2) ----------------------------------------------------------------

func hospedar(porta: int = Rede.PORTA_PADRAO) -> Error:
	carregar_ou_criar()
	var erro := rede.hospedar(porta)
	if erro == OK:
		aviso_rede = ""
		controles().meu_peer = Sessao.PEER_DO_HOST
		jogadores_mudaram.emit()
	return erro


func entrar_em_sessao(endereco: String, porta: int, nome: String) -> Error:
	carregar_ou_criar()
	salvar()
	var guardada := carreira
	var erro := rede.entrar(endereco, porta, nome)
	if erro == OK:
		_carreira_local = guardada
		aviso_rede = ""
		saguao_info = {"status": "Conectando à sala…"}   # o endereço fica no código (docs/29)
		ir_para_saguao()
	return erro


## Sai da sessão (ou para de hospedar) e volta para a Base com a carreira desta máquina.
func sair_da_sessao() -> void:
	var era_cliente := rede.eh_cliente()
	rede.encerrar()
	if era_cliente:
		_voltar_a_carreira_local()
	elif carreira != null:
		controles().remover_remotos()
		salvar()
	jogadores_mudaram.emit()
	get_tree().change_scene_to_file.call_deferred(CENA_BASE)


func ir_para_saguao() -> void:
	get_tree().change_scene_to_file.call_deferred(CENA_SAGUAO)


## A Base mudou os donos: os clientes ficam sabendo.
func controles_mudaram() -> void:
	if rede.eh_host():
		rede.enviar_controles(controles().para_dicionario())
		if missao == null:
			rede.enviar_saguao(_info_saguao())


func _mandar_estado(peer: int = 0) -> void:
	if rede.eh_host():
		rede.enviar_estado(peer, {"controles": controles().para_dicionario()})


func _info_saguao() -> Dictionary:
	var ctl := controles()
	var jogadores: Array = []
	for j in ctl.jogadores.size():
		jogadores.append(ctl.descricao(j))
	var agentes: Array = []
	for a in carreira.roster:
		agentes.append({"nome": a.nome, "nex": a.nex, "jogador": ctl.descricao(ctl.jogador_de(a)), "peer": ctl.peer_de(a)})
	return {"status": "Conectado. Aguardando o host começar uma missão.", "jogadores": jogadores, "agentes": agentes,
		"mestre": ctl.descricao_mestre(),
		"relatorio": carreira.ultimo_relatorio.duplicate(true)}


func _ao_entrar_jogador(peer: int, nome: String) -> void:
	carregar_ou_criar()
	if controles().adicionar_jogador_rede(peer, nome) < 0:
		rede.recusar(peer, "A sessão está cheia (até %d jogadores)." % ControleLocal.MAX_JOGADORES)
		return
	rede.enviar_controles(controles().para_dicionario())
	if missao != null:
		_mandar_estado(peer)
	else:
		rede.enviar_saguao(_info_saguao())
	jogadores_mudaram.emit()


func _ao_sair_jogador(peer: int, _nome: String) -> void:
	controles().remover_peer(peer)
	rede.enviar_controles(controles().para_dicionario())
	if missao == null:
		rede.enviar_saguao(_info_saguao())
	jogadores_mudaram.emit()


func _ao_pedirem_estado(peer: int) -> void:
	if missao != null:
		_mandar_estado(peer)
	else:
		rede.enviar_saguao(_info_saguao(), peer)


## Cliente: chegou o estado do host. A carreira passa a ser a dele, e a cena é a do estado.
func _ao_receber_estado(pacote: Dictionary) -> void:
	var c := Carreira.de_dicionario(pacote.get("checkpoint", {}))
	if pacote.has("controles"):
		c.controles = ControleLocal.de_dicionario(pacote.controles)
	c.controles.meu_peer = rede.meu_peer()
	carreira = c
	var m := carreira.missao
	if m == null:
		ir_para_saguao()
	elif not m.encontro_pendente.is_empty():
		combate_config = m.encontro_pendente
		get_tree().change_scene_to_file.call_deferred(CENA_ARENA)
	elif not m.investigacao_pendente.is_empty():
		get_tree().change_scene_to_file.call_deferred(CENA_INVESTIGACAO)
	else:
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func _ao_receber_saguao(info: Dictionary) -> void:
	saguao_info = info
	saguao_mudou.emit()
	var atual := get_tree().current_scene
	if atual == null or atual.scene_file_path != CENA_SAGUAO:
		if missao == null or missao.encerrada:
			ir_para_saguao()


func _ao_receber_controles(dados: Dictionary) -> void:
	if carreira != null and rede.eh_cliente():
		carreira.controles = ControleLocal.de_dicionario(dados)
		carreira.controles.meu_peer = rede.meu_peer()
		saguao_mudou.emit()


func _ao_perder_conexao(motivo: String) -> void:
	aviso_rede = motivo
	_voltar_a_carreira_local()
	get_tree().change_scene_to_file.call_deferred(CENA_BASE)


func _voltar_a_carreira_local() -> void:
	carreira = _carreira_local if _carreira_local != null else Carreira.carregar()
	if carreira == null:
		carreira = Carreira.nova()
	_carreira_local = null
	combate_config = {}
	saguao_info = {}
