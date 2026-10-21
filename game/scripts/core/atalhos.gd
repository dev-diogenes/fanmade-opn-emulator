class_name Atalhos
extends RefCounted
## Atalhos de teclado remapeáveis (docs/18, A4). Cada ação vira uma ação "atalho_<id>" no
## InputMap, com a tecla padrão ou a que o jogador escolheu (Preferencias.atalhos()).
## As telas perguntam por id, nunca por KEY_*:
##   if Atalhos.pressionou(evento, "ficha"): ...
##   if Atalhos.segurando("mover_cima"): ...
## Esc fica fixo (pausa e "voltar"); as setas continuam valendo junto com WASD.

## id -> [nome na folha, grupo, tecla padrão]
const ACOES := {
	"folha_atalhos": ["Folha de atalhos", "geral", KEY_H],
	"ficha": ["Ficha e inventário do agente", "geral", KEY_F],
	"camera_modo": ["Trocar câmera (3ª, 2ª, 1ª pessoa)", "camera", KEY_C],
	"camera_girar_esq": ["Girar a câmera à esquerda", "camera", KEY_Q],
	"camera_girar_dir": ["Girar a câmera à direita", "camera", KEY_E],
	"mover_cima": ["Para a frente", "mover", KEY_W],
	"mover_baixo": ["Para trás", "mover", KEY_S],
	"mover_esquerda": ["Para a esquerda", "mover", KEY_A],
	"mover_direita": ["Para a direita", "mover", KEY_D],
	"carta_1": ["Carta 1", "cartas", KEY_1],
	"carta_2": ["Carta 2", "cartas", KEY_2],
	"carta_3": ["Carta 3", "cartas", KEY_3],
	"carta_4": ["Carta 4", "cartas", KEY_4],
	"carta_5": ["Carta 5", "cartas", KEY_5],
	"quadro": ["Abrir o quadro do caso", "investigacao", KEY_TAB],
	"examinar": ["Procurar no ponto próximo", "investigacao", KEY_E],
	"confirmar_carta": ["Confirmar a carta escolhida", "investigacao", KEY_ENTER],
}

const GRUPOS := {
	"geral": "Em qualquer tela", "camera": "Câmera (mapa e combate)", "mover": "Andar e deslizar a câmera",
	"cartas": "Cartas (combate e investigação)", "investigacao": "Investigação",
}

## Em que telas cada grupo vale: duas ações só brigam pela mesma tecla se dividem uma tela.
const TELAS := {
	"geral": ["mapa", "combate", "investigacao"], "camera": ["mapa", "combate"],
	"mover": ["mapa", "combate", "investigacao"], "cartas": ["combate", "investigacao"],
	"investigacao": ["investigacao"],
}

## Teclas que não podem ser escolhidas: Esc é a saída de tudo.
const RESERVADAS := [KEY_ESCAPE]

## Teclas fixas que valem junto com a escolhida: as setas e o Enter do teclado numérico.
const EXTRAS := {"mover_cima": KEY_UP, "mover_baixo": KEY_DOWN, "mover_esquerda": KEY_LEFT, "mover_direita": KEY_RIGHT,
	"confirmar_carta": KEY_KP_ENTER}


## Cria (ou refaz) as ações no InputMap. Chamar de novo depois de remapear.
static func configurar() -> void:
	var mapa := Preferencias.atalhos()
	for id: String in ACOES:
		var nome := "atalho_" + id
		if InputMap.has_action(nome):
			InputMap.action_erase_events(nome)
		else:
			InputMap.add_action(nome)
		InputMap.action_add_event(nome, _tecla_evento(int(mapa.get(id, ACOES[id][2]))))
		if EXTRAS.has(id):
			InputMap.action_add_event(nome, _tecla_evento(EXTRAS[id]))


static func padrao(id: String) -> int:
	return int(ACOES[id][2])


static func tecla(id: String) -> int:
	return int(Preferencias.atalhos().get(id, padrao(id)))


## "F", "Tab", "1"… para mostrar em botões e na folha.
static func nome_tecla(id: String) -> String:
	return nome_de(tecla(id))


static func nome_de(keycode: int) -> String:
	var s := OS.get_keycode_string(keycode)
	return {"Enter": "Enter", "Space": "Espaço", "Up": "↑", "Down": "↓", "Left": "←", "Right": "→"}.get(s, s)


## Texto com a tecla no fim, para botões e dicas: "Ficha (F)".
static func com_tecla(texto: String, id: String) -> String:
	return "%s (%s)" % [texto, nome_tecla(id)]


## O evento é o aperto (sem repetição, a menos que `eco`) da tecla desta ação.
static func pressionou(evento: InputEvent, id: String, eco := false) -> bool:
	if not evento is InputEventKey or not evento.pressed or (evento.echo and not eco):
		return false
	return InputMap.has_action("atalho_" + id) and evento.is_action("atalho_" + id, true)


static func segurando(id: String) -> bool:
	return InputMap.has_action("atalho_" + id) and Input.is_action_pressed("atalho_" + id)


## Ações que já usam esta tecla numa tela em comum com `id`.
static func conflitos(id: String, keycode: int) -> Array[String]:
	var saida: Array[String] = []
	var telas: Array = TELAS[ACOES[id][1]]
	for outro: String in ACOES:
		if outro == id or tecla(outro) != keycode:
			continue
		for t in TELAS[ACOES[outro][1]]:
			if t in telas:
				saida.append(outro)
				break
	return saida


## Troca a tecla de `id`. Se outra ação da mesma tela já usava essa tecla, as duas trocam de
## lugar (ninguém fica sem tecla). Devolve os ids que trocaram com ela.
static func remapear(id: String, keycode: int) -> Array[String]:
	var trocados: Array[String] = []
	if not ACOES.has(id) or keycode in RESERVADAS or keycode == KEY_NONE:
		return trocados
	var antiga := tecla(id)
	trocados = conflitos(id, keycode)
	var mapa := Preferencias.atalhos()
	for outro in trocados:
		_guardar(mapa, outro, antiga)
	_guardar(mapa, id, keycode)
	Preferencias.definir_atalhos(mapa)
	configurar()
	return trocados


static func restaurar() -> void:
	Preferencias.definir_atalhos({})
	configurar()


static func _guardar(mapa: Dictionary, id: String, keycode: int) -> void:
	if keycode == padrao(id):
		mapa.erase(id)
	else:
		mapa[id] = keycode


static func _tecla_evento(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	return ev
