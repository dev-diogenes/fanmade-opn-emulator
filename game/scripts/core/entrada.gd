class_name Entrada
extends RefCounted
## Atalhos de controle (ADR 0004), criados no InputMap em tempo de execução:
## cursor nos tabuleiros (direcional e analógico esquerdo), confirmar (A), cancelar (B)
## e troca de foco com os gatilhos (LB/RB). Chamar mais de uma vez não duplica nada.

const ZONA_MORTA := 0.5


static func configurar() -> void:
	_acao("cursor_esquerda", [_botao(JOY_BUTTON_DPAD_LEFT), _eixo(JOY_AXIS_LEFT_X, -1.0)])
	_acao("cursor_direita", [_botao(JOY_BUTTON_DPAD_RIGHT), _eixo(JOY_AXIS_LEFT_X, 1.0)])
	_acao("cursor_cima", [_botao(JOY_BUTTON_DPAD_UP), _eixo(JOY_AXIS_LEFT_Y, -1.0)])
	_acao("cursor_baixo", [_botao(JOY_BUTTON_DPAD_DOWN), _eixo(JOY_AXIS_LEFT_Y, 1.0)])
	_acao("confirmar", [_botao(JOY_BUTTON_A)])
	_acao("cancelar", [_botao(JOY_BUTTON_B)])
	for par in [["ui_focus_next", JOY_BUTTON_RIGHT_SHOULDER], ["ui_focus_prev", JOY_BUTTON_LEFT_SHOULDER]]:
		var ev := _botao(par[1])
		if InputMap.has_action(par[0]) and not InputMap.action_has_event(par[0], ev):
			InputMap.action_add_event(par[0], ev)


const DIRECOES := {"cursor_esquerda": Vector2i(-1, 0), "cursor_direita": Vector2i(1, 0), "cursor_cima": Vector2i(0, -1), "cursor_baixo": Vector2i(0, 1)}

## Último sentido de cada eixo de cada controle ("device:eixo" -> -1, 0 ou 1): o analógico só
## move o cursor quando cruza a zona morta, e não a cada evento enquanto está inclinado.
static var _eixos: Dictionary = {}


## Direção do cursor pedida por um evento de controle (Vector2i.ZERO se não for).
static func direcao(evento: InputEvent) -> Vector2i:
	if evento is InputEventJoypadMotion:
		var m := evento as InputEventJoypadMotion
		var chave := "%d:%d" % [m.device, m.axis]
		var sentido := 0 if absf(m.axis_value) < ZONA_MORTA else signi(roundi(signf(m.axis_value)))
		var antes := int(_eixos.get(chave, 0))
		_eixos[chave] = sentido
		if sentido == 0 or sentido == antes:
			return Vector2i.ZERO
	elif not evento.is_pressed() or evento.is_echo():
		return Vector2i.ZERO
	for nome in DIRECOES:
		if InputMap.has_action(nome) and evento.get_action_strength(nome) >= ZONA_MORTA:
			return DIRECOES[nome]
	return Vector2i.ZERO


static func _acao(nome: String, eventos: Array) -> void:
	if not InputMap.has_action(nome):
		InputMap.add_action(nome, ZONA_MORTA)
	for ev in eventos:
		if not InputMap.action_has_event(nome, ev):
			InputMap.action_add_event(nome, ev)


static func _botao(b: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	ev.device = -1   # qualquer controle; o filtro do co-op separa os jogadores
	return ev


static func _eixo(eixo: int, valor: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = eixo
	ev.axis_value = valor
	ev.device = -1
	return ev
