extends Node
## Autoload "Jogo": guarda a missão em andamento entre as cenas (mapa <-> arena).

const CENA_MAPA := "res://scenes/mapa_mundo.tscn"
const CENA_ARENA := "res://scenes/arena_teste.tscn"

var missao: Missao
## Configuração do combate que a arena deve montar (vazia = arena de demonstração)
var combate_config: Dictionary = {}


func nova_missao(semente: int = -1) -> Missao:
	missao = Missao.nova(semente if semente >= 0 else randi() % 1000000)
	combate_config = {}
	return missao


func ir_para_combate(config: Dictionary) -> void:
	combate_config = config
	get_tree().change_scene_to_file.call_deferred(CENA_ARENA)


func voltar_do_combate(vencedor: String) -> void:
	if missao != null:
		missao.concluir_encontro(vencedor)
	combate_config = {}
	get_tree().change_scene_to_file.call_deferred(CENA_MAPA)
