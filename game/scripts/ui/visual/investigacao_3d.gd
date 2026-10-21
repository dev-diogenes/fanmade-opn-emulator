class_name Investigacao3D
extends Node3D
## Cena de investigação em 3D: câmera aproximada e visão reduzida (névoa densa e uma luz de
## raio curto). Os pontos de interesse ficam em volta do grupo; Facilitar aumenta a luz.

const RAIO_PONTOS := 3.0
const CORES_CHAO := {"casa_abandonada": Color("3b3430"), "capela": Color("3a3640"), "acampamento": Color("2c3a2a")}

var rig: CameraRig
var _props: Dictionary = {}       ## ponto_id -> Node3D
var _marcas: Dictionary = {}      ## ponto_id -> Node3D (marcador flutuante)
var _luz: OmniLight3D
var _ambiente: Environment
var _anel_sel: MeshInstance3D
var _rotulos_pontos: Dictionary = {}   ## ponto_id -> Label3D (docs/23: só perto e fora do HUD)
## Distância até onde o nome de um ponto aparece (o alcance para investigar é 1,5).
const ALCANCE_ROTULO := 2.8
## Faixa de baixo da tela ocupada pelo HUD (retratos, bilhete, cartas): rótulo ali some.
const FAIXA_HUD := 0.7
var _nivel_luz := 0
var _figuras: Dictionary = {}     ## Agente -> Node3D (andam com WASD, docs/13)
const ALCANCE_PONTO := 1.5        ## distância para investigar um ponto
const RAIO_CENA := 5.4            ## o grupo não sai do chão iluminado
const VELOCIDADE := 2.6


func construir(cena: Dictionary, agentes: Array) -> void:
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-60, -30, 0)
	sol.light_energy = 0.15
	add_child(sol)
	var amb := WorldEnvironment.new()
	_ambiente = Environment.new()
	_ambiente.background_mode = Environment.BG_COLOR
	_ambiente.background_color = Color("07070b")
	_ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_ambiente.ambient_light_color = Color("3a3550")
	_ambiente.ambient_light_energy = 0.25
	_ambiente.fog_enabled = true
	_ambiente.fog_light_color = Color("0c0b12")
	_ambiente.fog_density = 0.11
	_ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	amb.environment = _ambiente
	Qualidade.ambiente(amb)
	add_child(amb)

	var chao := CylinderMesh.new()
	chao.top_radius = 6.0
	chao.bottom_radius = 6.0
	chao.height = 0.2
	chao.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = chao
	mi.material_override = Pecas.material(CORES_CHAO.get(cena.get("visual", cena.id), Color("333333")))
	mi.position.y = -0.1
	add_child(mi)

	_luz = OmniLight3D.new()
	_luz.position = Vector3(0, 2.2, 0)
	_luz.light_color = Color("ffd9a0")
	_luz.light_energy = 2.2
	_luz.shadow_enabled = true
	Qualidade.sombra(_luz)
	add_child(_luz)
	_aplicar_luz()

	var pontos: Array = cena.pontos
	for i in pontos.size():
		var p: Dictionary = pontos[i]
		var ang := TAU * i / pontos.size() + 0.4
		var pos := Vector3(cos(ang) * RAIO_PONTOS, 0, sin(ang) * RAIO_PONTOS)
		# Peça pelo tipo do ponto (docs/23, C6); sem palavra conhecida, a peça antiga da cena
		var prop := PropsInvestigacao.criar(String(p.id), String(p.nome))
		if prop == null:
			prop = _prop_para(String(cena.get("visual", cena.id)), i)
		prop.position = pos
		prop.rotation.y = -ang
		add_child(prop)
		_props[p.id] = prop
		# Sigilo procedural no chão do ponto de interesse, pulsando (docs/09)
		var marca := _sigilo_no_chao(hash(p.id), Tema.ELEMENTO.conhecimento)
		marca.position = pos + Vector3(0, 0.02, 0)
		add_child(marca)
		_marcas[p.id] = marca
		var rot := Pecas.rotulo(p.nome, 34, Tema.PERGAMINHO)
		rot.position = pos + Vector3(0, 1.45, 0)
		add_child(rot)
		_rotulos_pontos[p.id] = rot
	var cores := Tema.CORES_JOGADORES
	for i in agentes.size():
		var f := Pecas.do_agente(agentes[i], cores[i % cores.size()], 0.9)
		f.position = Vector3(-0.5 + 0.5 * i, 0, 0.3 * (i % 2))
		_figuras[agentes[i]] = f
		var r := Pecas.rotulo(agentes[i].nome, 40)
		r.position = Vector3(0, 1.15, 0)
		f.add_child(r)
		add_child(f)
	_anel_sel = Pecas.anel(0.95, Tema.OURO_CLARO)
	_anel_sel.visible = false
	add_child(_anel_sel)
	rig = CameraRig.new()
	add_child(rig)
	rig.distancia = 9.0
	rig.distancia_min = 4.0
	rig.distancia_max = 13.0
	rig.limites = AABB(Vector3(-4, 0, -4), Vector3(8, 0, 8))
	rig.focar(Vector3.ZERO, true)


func _sigilo_no_chao(semente: int, cor: Color) -> MeshInstance3D:
	var plano := PlaneMesh.new()
	plano.size = Vector2(1.9, 1.9)
	var m := StandardMaterial3D.new()
	m.albedo_texture = Sigilo.imagem(semente, 192, Color.WHITE, 5.0)
	m.albedo_color = cor
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = 1.2
	m.emission_texture = m.albedo_texture
	var mi := MeshInstance3D.new()
	mi.mesh = plano
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pulso := mi.create_tween().set_loops()
	pulso.tween_property(m, "albedo_color:a", 0.35, 1.2).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(m, "albedo_color:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	return mi


func _prop_para(cena_id: String, i: int) -> Node3D:
	# Cria só a peça usada (montar uma lista com todas deixaria as outras órfãs na memória).
	match "%s:%d" % [cena_id, i % 4]:
		"casa_abandonada:0": return Pecas.caixote(0.9)
		"casa_abandonada:1": return Pecas.caixote(0.7)
		"casa_abandonada:2": return Pecas.casa(Color("b8a88a"), Color("7b3f2e"), false)   # abandonada: janelas apagadas
		"casa_abandonada:3": return Pecas.parede(0.8)
		"capela:0", "capela:3": return Pecas.pilar_quebrado(0.9 if i % 4 == 0 else 0.6)
		"capela:1": return Pecas.parede(1.2)
		"capela:2": return Pecas.caixote(0.8)
		_:
			match i % 4:
				0: return Pecas.rocha(0.35)
				1: return Pecas.casa(Color("6b7d5c"), Color("4a5a3e"))
				2: return Pecas.capim()
	return Pecas.caixote(0.6)


## Facilitar a investigação ilumina a cena (o raio de visão cresce).
func iluminar() -> void:
	_nivel_luz += 1
	_aplicar_luz()


func _aplicar_luz() -> void:
	_luz.omni_range = 3.6 + 1.6 * _nivel_luz
	_ambiente.fog_density = maxf(0.03, 0.11 - 0.03 * _nivel_luz)


func atualizar(cena: CenaInvestigacao, selecionado: String) -> void:
	for pid in _marcas:
		var achado: bool = not pid in cena.pontos_restantes
		_marcas[pid].visible = not achado
		for filho in _props[pid].get_children():
			if filho is MeshInstance3D:
				filho.transparency = 0.6 if achado else 0.0
	_anel_sel.visible = selecionado != "" and _props.has(selecionado)
	if _anel_sel.visible:
		_anel_sel.position = _props[selecionado].position + Vector3(0, 0.02, 0)


## Anda com a figura do agente na direção `dir` (no plano), virada para onde vai.
func mover_agente(a: Agente, dir: Vector3, delta: float) -> void:
	var f: Node3D = _figuras.get(a)
	if f == null:
		return
	if dir.length() < 0.01:
		Pecas.animar(f, "Idle")
		return
	dir = dir.normalized()
	var novo := f.position + dir * VELOCIDADE * delta
	if Vector2(novo.x, novo.z).length() > RAIO_CENA:
		novo = Vector3(novo.x, 0, novo.z).normalized() * RAIO_CENA
	# Não atravessa os objetos dos pontos de interesse
	for pid in _props:
		var p: Vector3 = _props[pid].position
		var dist := Vector2(novo.x - p.x, novo.z - p.z)
		if dist.length() < 0.55:
			var fora := dist.normalized() * 0.55
			novo = Vector3(p.x + fora.x, 0, p.z + fora.y)
	f.position = novo
	f.rotation.y = atan2(dir.x, dir.z)
	Pecas.animar(f, "Walking_A")


## Ponto de interesse ao alcance do agente ("" se nenhum).
## Nomes dos pontos só perto do agente da vez (ou o escolhido) e nunca atrás do HUD
## (docs/23, C6). Chamado a cada quadro pela cena.
func atualizar_rotulos(a: Agente, escolhido: String) -> void:
	var f: Node3D = _figuras.get(a)
	var cam := rig.camera if rig != null else null
	var altura_tela := cam.get_viewport().get_visible_rect().size.y if cam != null else 0.0
	for pid in _rotulos_pontos:
		var rot: Label3D = _rotulos_pontos[pid]
		var perto: bool = f != null and Vector2(rot.position.x - f.position.x, rot.position.z - f.position.z).length() < ALCANCE_ROTULO
		var ver: bool = perto or pid == escolhido
		if ver and cam != null and altura_tela > 0.0 and not cam.is_position_behind(rot.global_position):
			ver = cam.unproject_position(rot.global_position).y < altura_tela * FAIXA_HUD
		rot.visible = ver


func ponto_proximo(a: Agente, restantes: Array) -> String:
	var f: Node3D = _figuras.get(a)
	if f == null:
		return ""
	var melhor := ""
	var melhor_d := ALCANCE_PONTO
	for pid in _props:
		if not pid in restantes:
			continue
		var d := Vector2(_props[pid].position.x - f.position.x, _props[pid].position.z - f.position.z).length()
		if d < melhor_d:
			melhor = pid
			melhor_d = d
	return melhor


func figura(a: Agente) -> Node3D:
	return _figuras.get(a)


## Ponto de interesse sob o ponteiro ("" se nenhum).
func ponto_em(pos_tela: Vector2) -> String:
	var chao = rig.ponto_no_chao(pos_tela, 0.0)
	if chao == null:
		return ""
	var melhor := ""
	var melhor_d := 1.0
	for pid in _props:
		var d: float = (_props[pid].position - chao).length()
		if d < melhor_d:
			melhor = pid
			melhor_d = d
	return melhor
