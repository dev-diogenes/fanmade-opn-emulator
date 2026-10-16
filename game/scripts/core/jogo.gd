extends Node
## Autoload "Jogo": guarda a carreira (e a missão em andamento) entre as cenas
## Base <-> Mapa <-> Arena e salva automaticamente em user://carreira.json.

const CENA_BASE := "res://scenes/base_ordem.tscn"
const CENA_MAPA := "res://scenes/mapa_mundo.tscn"
const CENA_ARENA := "res://scenes/arena_teste.tscn"
const CENA_INVESTIGACAO := "res://scenes/investigacao.tscn"

var carreira: Carreira
## Configuração do combate que a arena deve montar (vazia = arena de demonstração)
var combate_config: Dictionary = {}
## false nos testes automáticos, para não mexer no save do jogador
var salvar_automaticamente := true

var missao: Missao:
	get:
		return carreira.missao if carreira != null else null


func _ready() -> void:
	Entrada.configurar()


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
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
	return m


func ir_para_combate(config: Dictionary) -> void:
	combate_config = config
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_ARENA)


func voltar_do_combate(vencedor: String) -> void:
	if missao != null:
		missao.concluir_encontro(vencedor)
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
	if carreira != null and missao != null and missao.encerrada:
		carreira.encerrar_missao()
	salvar()
	get_tree().change_scene_to_file.call_deferred(CENA_BASE)


func continuar_missao() -> void:
	if missao != null:
		get_tree().change_scene_to_file.call_deferred(CENA_MAPA)


func salvar() -> void:
	if carreira != null and salvar_automaticamente:
		carreira.salvar()
