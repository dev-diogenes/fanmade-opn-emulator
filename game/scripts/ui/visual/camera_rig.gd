class_name CameraRig
extends Node3D
## Câmera estilo For The King: olha o tabuleiro de cima, em ângulo; gira, aproxima e desliza.
## A cena de UI chama os métodos (girar, zoom, deslizar) a partir dos eventos de entrada.
## Modos (docs/13, tecla C; revistos no docs/30): "terceira" (de cima, como no FTK),
## "segunda" (por cima do ombro, um pouco atrás do agente da vez) e "primeira" (dos olhos
## do agente, para onde ele está virado). Os dois últimos precisam de `seguir` (a figura).

const MODOS := ["terceira", "segunda", "primeira"]
const NOMES_MODOS := {"terceira": "3ª pessoa", "segunda": "2ª pessoa", "primeira": "1ª pessoa"}

## A cena pode esconder mais peças em 1ª pessoa (o mapa esconde quem divide o hex).
signal modo_mudou(modo: String)

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
		_ultima_frente = Vector3.ZERO   # a próxima atualização vira para onde a figura olha
		_atualizar_visibilidade()
var olhar := -0.15          ## inclinação do olhar em 1ª pessoa (radianos; negativo = para baixo)
## Altura dos olhos da miniatura acima da base. A cena ajusta pela escala das figuras
## (medido nos modelos: ~0,66 da escala; docs/30).
var altura_olhos := 0.66
## Quanto o olho fica à frente do eixo da figura (a frente do rosto).
var avanco_primeira := 0.18
var fov_primeira := 70.0
var _ultima_frente := Vector3.ZERO
## Acompanhar a figura quando ela se vira. Na investigação, quem anda é o WASD relativo à
## câmera: acompanhar a virada faria a câmera girar sem parar ao andar de lado.
var acompanhar_virada := true

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
		_seguir_a_frente_da_figura()
		var cabeca := to_local(seguir.global_position) + Vector3(0, altura_olhos, 0)
		var adiante := Vector3(-sin(giro), 0, -cos(giro))
		if modo == "primeira":
			# Nos olhos, logo à frente do rosto, vendo o que o agente vê
			var frente := Vector3(-sin(giro) * cos(olhar), sin(olhar), -cos(giro) * cos(olhar))
			camera.fov = fov_primeira
			camera.position = cabeca + adiante * avanco_primeira
			camera.look_at(camera.position + frente, Vector3.UP)
		else:
			# Por cima do ombro: atrás, um pouco acima e de lado, olhando adiante do agente
			var d := clampf(_distancia_atual * 0.2, 1.2, 3.5)
			var direita := Vector3(cos(giro), 0, -sin(giro))
			camera.fov = 60.0
			camera.position = cabeca - adiante * d + Vector3.UP * (0.45 * d) + direita * (0.3 * d)
			camera.look_at(cabeca + adiante * (1.5 * d), Vector3.UP)
		return
	camera.fov = 55.0
	var dir := Vector3(sin(giro) * cos(inclinacao), sin(inclinacao), cos(giro) * cos(inclinacao))
	camera.position = _alvo_atual + dir * _distancia_atual
	camera.look_at(_alvo_atual, Vector3.UP)


## Troca o modo de câmera (C, remapeável) e guarda a escolha.
func proximo_modo() -> String:
	definir_modo(MODOS[(MODOS.find(modo) + 1) % MODOS.size()])
	return modo


func definir_modo(novo: String) -> void:
	modo = novo if novo in MODOS else "terceira"
	Preferencias.definir_camera(modo)
	_ultima_frente = Vector3.ZERO
	_atualizar_visibilidade()
	modo_mudou.emit(modo)


## Na 1ª e na 2ª pessoa, a câmera vira para onde a figura está virada: ao trocar de agente
## ou de modo e sempre que a figura se vira (anda). Entre um passo e outro, o botão direito
## continua girando a visão. As figuras olham para +Z do modelo (look_at com use_model_front).
func _seguir_a_frente_da_figura() -> void:
	var z := seguir.global_transform.basis.z
	z.y = 0.0
	if z.length() < 0.01:
		return
	z = z.normalized()
	if _ultima_frente == Vector3.ZERO or (acompanhar_virada and _ultima_frente.dot(z) < 0.999):
		giro = atan2(-z.x, -z.z)
		_ultima_frente = z


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
	# Teclas remapeáveis (docs/18, A4); segurar gira e desliza sem parar
	if Atalhos.pressionou(evento, "camera_modo"): proximo_modo()
	elif Atalhos.pressionou(evento, "camera_girar_esq", true): girar(0.15)
	elif Atalhos.pressionou(evento, "camera_girar_dir", true): girar(-0.15)
	elif Atalhos.pressionou(evento, "mover_cima", true): deslizar(0, 1)
	elif Atalhos.pressionou(evento, "mover_baixo", true): deslizar(0, -1)
	elif Atalhos.pressionou(evento, "mover_esquerda", true): deslizar(-1, 0)
	elif Atalhos.pressionou(evento, "mover_direita", true): deslizar(1, 0)
	else: return false
	return true
