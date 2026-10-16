class_name Sessao
extends RefCounted
## A sessão de jogo (Fase 8, ADR 0007). As telas não chamam a lógica direto: montam um
## comando e o entregam aqui. Offline (modo "local"), a sessão aplica na hora, pela tela ativa.
## Ela também guarda o checkpoint (o estado da carreira na última troca de cena) e os comandos
## aplicados desde então: com os dois dá para refazer a partida, o que a rede usa para
## ressincronizar um cliente (Fase 8.2).

signal comando_aplicado(cmd: Dictionary, resultado: Dictionary)

var modo := "local"
## Tela ativa: "mapa", "combate" ou "investigacao"
var contexto := ""
var checkpoint: Dictionary = {}
var registro: Array[Dictionary] = []
var _aplicador := Callable()


## A tela ativa se registra: os comandos do contexto dela passam pelo `aplicador`
## (que aplica na lógica e atualiza a tela) e devolve o resultado.
func entrar(ctx: String, aplicador: Callable) -> void:
	contexto = ctx
	_aplicador = aplicador


func sair(ctx: String) -> void:
	if contexto == ctx:
		contexto = ""
		_aplicador = Callable()


## Novo ponto de partida (troca de cena): o estado é a carreira inteira, como no save.
func marcar_checkpoint(estado: Dictionary) -> void:
	checkpoint = estado
	registro.clear()


## Entrega um comando. Offline, aplica na hora e devolve o resultado.
func enviar(cmd: Dictionary) -> Dictionary:
	if String(cmd.get("ctx", "")) != contexto or not _aplicador.is_valid():
		return {"ok": false, "erro": "comando fora da tela ativa"}
	var res: Dictionary = _aplicador.call(cmd)
	registro.append(cmd.duplicate(true))
	comando_aplicado.emit(cmd, res)
	return res
