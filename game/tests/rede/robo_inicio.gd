extends Node
## Cena inicial do teste online de dois processos: só põe o robô na raiz, para ele
## sobreviver às trocas de cena.


func _ready() -> void:
	get_tree().root.add_child.call_deferred(load("res://tests/rede/robo_online.gd").new())
