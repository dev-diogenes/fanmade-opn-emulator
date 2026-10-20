class_name CameraRig
extends Node3D
## Câmera estilo For The King: olha o tabuleiro de cima, em ângulo; gira, aproxima e desliza.
## A cena de UI chama os métodos (girar, zoom, deslizar) a partir dos eventos de entrada.
## Modos (docs/13, tecla C): "terceira" (de cima, como no FTK), "segunda" (na frente do
## agente da vez, olhando para ele) e "primeira" (dos olhos do agente). Os dois últimos
## precisam de `seguir` (a figura do agente da vez).

const MODOS := ["terceira", "segunda", "primeira"]
const NOMES_MODOS := {"terceira": "3ª pessoa", "segunda": "2ª pessoa", "primeira": "1ª pessoa"}

var camera: Camera3D
var alvo := Vector3.ZERO          ## Ponto que a câmera olha
var distancia := 10.0
var distancia_min := 4.0
var distancia_max := 22.0
var inclinacao := deg_to_rad(52.0)
var giro := deg_to_rad(0.0)
var limites := AABB(Vector3(-100, 0, -100), Vector3(200, 0, 200))
var suavidade := 10.0

var modo := "terceira"
var seguir: Node3D:
	set(v):
		if seguir != null and is_instance_valid(seguir):
			seguir.visible = true
		seguir = v
		_atualizar_visibilidade()
var olhar := -0.32          ## inclinação do olhar em 1ª pessoa (radianos)
var altura_olhos := 0.7

var _alvo_atual := Vector3.ZERO
var _distancia_atual := 10.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_WIDTH   # o campo de visão horizontal fica fixo (viewports estreitos)
	camera.fov = 55.0
	add_child(camera)
	_alvo_atual = alvo
	_distancia_atual = distancia
	modo = Preferencias.camera()
	_aplicar()


func _process(delta: float) -> void:
	var t := clampf(delta * suavidade, 0.0, 1.0)
	_alvo_atual = _alvo_atual.lerp(alvo, t)
	_distancia_atual = lerpf(_distancia_atual, distancia, t)
	_aplicar()


func _aplicar() -> void:
	if modo != "terceira" and seguir != null and is_instance_valid(seguir) and seguir.is_inside_tree():
		var cabeca := to_local(seguir.global_position) + Vector3(0, altura_olhos, 0)
		if modo == "primeira":
			var frente := Vector3(-sin(giro) * cos(olhar), sin(olhar), -cos(giro) * cos(olhar))
			camera.position = cabeca
			camera.look_at(cabeca + frente, Vector3.UP)
		else:
			var d := clampf(_distancia_atual * 0.3, 1.6, 4.0)
			camera.position = cabeca + Vector3(-sin(giro), 0.35, -cos(giro)) * d
			camera.look_at(cabeca, Vector3.UP)
		return
	var dir := Vector3(sin(giro) * cos(inclinacao), sin(inclinacao), cos(giro) * cos(inclinacao))
	camera.position = _alvo_atual + dir * _distancia_atual
	camera.look_at(_alvo_atual, Vector3.UP)


## Troca o modo de câmera (C) e guarda a escolha.
func proximo_modo() -> String:
	definir_modo(MODOS[(MODOS.find(modo) + 1) % MODOS.size()])
	return modo


func definir_modo(novo: String) -> void:
	modo = novo if novo in MODOS else "terceira"
	Preferencias.definir_camera(modo)
	_atualizar_visibilidade()


## Em 1ª pessoa, a figura do próprio agente some (a câmera está dentro dela).
func _atualizar_visibilidade() -> void:
	if seguir != null and is_instance_valid(seguir):
		seguir.visible = modo != "primeira"


## Posiciona imediatamente (sem suavizar).
func focar(ponto: Vector3, imediato: bool = false) -> void:
	alvo = _limitar(ponto)
	if imediato:
		_alvo_atual = alvo
		_distancia_atual = distancia
		if camera != null:
			_aplicar()


func zoom(passos: float) -> void:
	distancia = clampf(distancia * pow(1.12, passos), distancia_min, distancia_max)


func girar(radianos: float) -> void:
	giro += radianos


## Desliza no plano do chão, relativo à direção da câmera.
func deslizar(dx: float, dz: float) -> void:
	var frente := Vector3(-sin(giro), 0, -cos(giro))
	var direita := Vector3(cos(giro), 0, -sin(giro))
	var escala := distancia * 0.08
	alvo = _limitar(alvo + (direita * dx + frente * dz) * escala)


func _limitar(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, limites.position.x, limites.end.x), p.y, clampf(p.z, limites.position.z, limites.end.z))


## Ponto do chão (plano y = altura) sob uma posição de tela do viewport.
func ponto_no_chao(pos_tela: Vector2, altura: float = 0.0) -> Variant:
	var origem := camera.project_ray_origin(pos_tela)
	var direcao := camera.project_ray_normal(pos_tela)
	if absf(direcao.y) < 0.0001:
		return null
	var t := (altura - origem.y) / direcao.y
	if t < 0:
		return null
	return origem + direcao * t


## Repassa eventos de entrada comuns: roda = zoom, botão direito arrastando = girar,
## botão do meio arrastando = deslizar, Q/E giram, WASD/setas deslizam.
func tratar_entrada(evento: InputEvent) -> bool:
	if evento is InputEventMouseButton and evento.pressed:
		if evento.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom(-1)
			return true
		if evento.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom(1)
			return true
	if evento is InputEventMouseMotion:
		if evento.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			girar(-evento.relative.x * 0.008)
			if modo == "primeira":
				olhar = clampf(olhar - evento.relative.y * 0.006, -1.2, 0.6)
			return true
		if evento.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			deslizar(-evento.relative.x * 0.05, -evento.relative.y * 0.05)
			return true
	if evento is InputEventKey and evento.pressed:
		match evento.keycode:
			KEY_C: proximo_modo()
			KEY_Q: girar(0.15)
			KEY_E: girar(-0.15)
			KEY_W, KEY_UP: deslizar(0, 1)
			KEY_S, KEY_DOWN: deslizar(0, -1)
			KEY_A, KEY_LEFT: deslizar(-1, 0)
			KEY_D, KEY_RIGHT: deslizar(1, 0)
			_: return false
		return true
	return false
