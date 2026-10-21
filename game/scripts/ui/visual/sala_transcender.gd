class_name SalaTranscender
extends Node3D
## A sala do agente para Transcender (docs/31): um quarto fechado e escuro (paredes de um
## vermelho fundo, chão de tábuas), estante com livros, mesa com um crânio e velas, gaiola e
## ervas penduradas, e o sigilo no chão, no meio. Só apresentação; quem anda e decide é a cena.

const RAIO_SALA := 3.2             ## o agente não passa das paredes
const RAIO_SIGILO := 0.55          ## pisou aqui, começa o ritual
const PORTA := Vector3(0, 0, 2.6)  ## onde o agente entra
const COR_RITUAL := Color("f2b24a")

var rig: CameraRig
var figura: Node3D
var sigilo: MeshInstance3D
var _material_sigilo: StandardMaterial3D
var _luz_sigilo: OmniLight3D
var _env: Environment


func construir(agente: Agente) -> void:
	_ambiente()
	_quarto()
	_sigilo_central()
	figura = Pecas.do_agente(agente, Tema.CORES_JOGADORES[0], 1.0)
	if figura.get_child_count() > 1 and figura.get_child(0) is MeshInstance3D:
		figura.get_child(0).visible = false   # sem a base de peça: é a sala dele, não o tabuleiro
	figura.position = PORTA
	figura.rotation.y = atan2(-PORTA.x, -PORTA.z)   # olhando para o sigilo (sem look_at: pode estar fora da árvore)
	add_child(figura)
	rig = CameraRig.new()
	add_child(rig)
	rig.distancia = 6.5
	rig.distancia_min = 3.5
	rig.distancia_max = 9.0
	rig.inclinacao = deg_to_rad(38.0)
	rig.limites = AABB(Vector3(-3, 0, -3), Vector3(6, 0, 6))
	rig.altura_olhos = 0.66
	rig.acompanhar_virada = false
	rig.focar(Vector3(0, 0, 1.0), true)


func _ambiente() -> void:
	var amb := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color("050307")
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color("6a2a32")
	_env.ambient_light_energy = 0.9
	_env.glow_enabled = true
	_env.glow_intensity = 1.0
	_env.glow_hdr_threshold = 0.85
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.fog_enabled = true
	_env.fog_light_color = Color("12070b")
	_env.fog_density = 0.04
	amb.environment = _env
	Qualidade.ambiente(amb)
	add_child(amb)
	# Uma lâmpada fraca no alto, perto da porta, e um banho vermelho nas paredes (a sala da
	# referência é vermelha e quente)
	var lampada := OmniLight3D.new()
	lampada.light_color = Color("ffcf9a")
	lampada.light_energy = 1.3
	lampada.omni_range = 6.0
	lampada.position = Vector3(0.6, 2.8, 1.8)
	lampada.shadow_enabled = true
	Qualidade.sombra(lampada)
	add_child(lampada)
	var parede := OmniLight3D.new()
	parede.light_color = Color("c0303a")
	parede.light_energy = 1.0
	parede.omni_range = 5.0
	parede.position = Vector3(0, 2.2, -2.6)
	add_child(parede)


func _caixa(tamanho: Vector3, pos: Vector3, cor: Color, emissao := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = tamanho
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	add_child(mi)
	return mi


func _quarto() -> void:
	# Chão de tábuas (faixas alternadas) e três paredes; a quarta fica aberta para a câmera
	for i in 9:
		_caixa(Vector3(7.2, 0.1, 0.78), Vector3(0, -0.05, -3.2 + i * 0.8), Color("2a1a14") if i % 2 == 0 else Color("24160f"))
	_caixa(Vector3(7.2, 3.2, 0.2), Vector3(0, 1.6, -3.6), Color("4a0f16"))
	_caixa(Vector3(0.2, 3.2, 7.2), Vector3(-3.6, 1.6, 0), Color("3e0c12"))
	_caixa(Vector3(0.2, 3.2, 7.2), Vector3(3.6, 1.6, 0), Color("3e0c12"))
	# Estante com livros (esquerda, ao fundo)
	_caixa(Vector3(1.6, 2.0, 0.4), Vector3(-2.4, 1.0, -3.3), Color("2b1d14"))
	var cores := [Color("6b2a1e"), Color("2f3a4a"), Color("4a3b1c"), Color("3b2a40"), Color("1f3a2a")]
	for prateleira in 3:
		for k in 6:
			_caixa(Vector3(0.18, 0.34, 0.26), Vector3(-3.0 + k * 0.22, 0.4 + prateleira * 0.62, -3.15), cores[(k + prateleira) % cores.size()])
	# Livro aberto sobre um atril, com uma luz roxa (o paranormal) — como na imagem de referência
	_caixa(Vector3(0.12, 1.0, 0.12), Vector3(-2.6, 0.5, -1.6), Color("2b1d14"))
	var livro := _caixa(Vector3(0.6, 0.06, 0.42), Vector3(-2.6, 1.04, -1.6), Color("d8cfb8"))
	livro.rotation.z = 0.2
	var luz_livro := OmniLight3D.new()
	luz_livro.light_color = Color("a06bff")
	luz_livro.light_energy = 0.8
	luz_livro.omni_range = 1.6
	luz_livro.position = Vector3(-2.6, 1.3, -1.6)
	Qualidade.luz_extra(luz_livro)
	add_child(luz_livro)
	# Mesa com um crânio e velas (direita, à frente)
	_caixa(Vector3(1.2, 0.08, 0.7), Vector3(2.5, 0.8, 0.6), Color("2b1d14"))
	for x in [-0.5, 0.5]:
		for z in [-0.28, 0.28]:
			_caixa(Vector3(0.08, 0.8, 0.08), Vector3(2.5 + x, 0.4, 0.6 + z), Color("21160f"))
	var cranio := SphereMesh.new()
	cranio.radius = 0.14
	cranio.height = 0.26
	var mc := MeshInstance3D.new()
	mc.mesh = cranio
	mc.material_override = Pecas.material(Color("d9cfb6"))
	mc.position = Vector3(2.3, 0.97, 0.6)
	add_child(mc)
	for i in 5:
		var ang := TAU * i / 5.0
		var pos := Vector3(cos(ang), 0, sin(ang)) * 1.15
		_vela(pos, 0.18 + 0.06 * (i % 2))
	_vela(Vector3(2.75, 0.84, 0.45), 0.2)
	# Gaiola pendurada (direita, ao fundo) e ervas no teto
	var gaiola := Node3D.new()
	gaiola.position = Vector3(2.4, 1.7, -2.6)
	add_child(gaiola)
	for i in 8:
		var barra := MeshInstance3D.new()
		var cil := CylinderMesh.new()
		cil.top_radius = 0.012
		cil.bottom_radius = 0.012
		cil.height = 0.7
		barra.mesh = cil
		barra.material_override = Pecas.material(Color("6b5a3a"))
		var a := TAU * i / 8.0
		barra.position = Vector3(cos(a), 0, sin(a)) * 0.22
		gaiola.add_child(barra)
	for i in 4:
		var erva := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.09
		cone.height = 0.35
		erva.mesh = cone
		erva.material_override = Pecas.material(Color("3d4a2a"))
		erva.position = Vector3(-1.2 + i * 0.45, 2.7, -3.3)
		erva.rotation.x = PI
		add_child(erva)


func _vela(pos: Vector3, altura: float) -> void:
	_caixa(Vector3(0.07, altura, 0.07), pos + Vector3(0, altura / 2.0, 0), Color("e8dcc0"))
	_caixa(Vector3(0.04, 0.06, 0.04), pos + Vector3(0, altura + 0.04, 0), Color("ffb04a"), 3.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ff9a3c")
	luz.light_energy = 0.45
	luz.omni_range = 1.4
	luz.position = pos + Vector3(0, altura + 0.2, 0)
	Qualidade.luz_extra(luz)
	add_child(luz)


func _sigilo_central() -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(2.4, 2.4)
	_material_sigilo = StandardMaterial3D.new()
	_material_sigilo.albedo_texture = Sigilo.imagem(4242, 256, Color.WHITE, 4.0)
	_material_sigilo.albedo_color = COR_RITUAL
	_material_sigilo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_sigilo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material_sigilo.emission_enabled = true
	_material_sigilo.emission = COR_RITUAL
	_material_sigilo.emission_energy_multiplier = 1.0
	_material_sigilo.emission_texture = _material_sigilo.albedo_texture
	sigilo = MeshInstance3D.new()
	sigilo.mesh = plano
	sigilo.material_override = _material_sigilo
	sigilo.position = Vector3(0, 0.02, 0)
	sigilo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(sigilo)
	# Dois anéis com runas entre eles, como o círculo do ritual da referência
	for raio in [1.12, 1.42]:
		var anel := TorusMesh.new()
		anel.inner_radius = raio - 0.025
		anel.outer_radius = raio
		anel.rings = 48
		anel.ring_segments = 4
		var mi := MeshInstance3D.new()
		mi.mesh = anel
		mi.material_override = Pecas.material(COR_RITUAL, false, 2.2)
		mi.position = Vector3(0, 0.02, 0)
		mi.scale = Vector3(1, 0.2, 1)
		sigilo.add_child(mi)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 28:
		var a := TAU * i / 28.0
		var runa := BoxMesh.new()
		runa.size = Vector3(rng.randf_range(0.04, 0.12), 0.01, rng.randf_range(0.06, 0.16))
		var r := MeshInstance3D.new()
		r.mesh = runa
		r.material_override = Pecas.material(COR_RITUAL, false, 2.0)
		r.position = Vector3(cos(a), 0, sin(a)) * 1.27 + Vector3(0, 0.02, 0)
		r.rotation.y = -a + rng.randf_range(-0.4, 0.4)
		sigilo.add_child(r)
	var pulso := sigilo.create_tween().set_loops()
	pulso.tween_property(_material_sigilo, "emission_energy_multiplier", 1.6, 1.4).set_trans(Tween.TRANS_SINE)
	pulso.tween_property(_material_sigilo, "emission_energy_multiplier", 0.8, 1.4).set_trans(Tween.TRANS_SINE)
	_luz_sigilo = OmniLight3D.new()
	_luz_sigilo.light_color = COR_RITUAL
	_luz_sigilo.light_energy = 0.8
	_luz_sigilo.omni_range = 2.6
	_luz_sigilo.position = Vector3(0, 0.5, 0)
	add_child(_luz_sigilo)


## Anda com a direção (relativa à câmera, como na investigação) e vira a figura.
func mover(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		Pecas.animar(figura, "Idle")
		return
	dir = dir.normalized()
	var novo := figura.position + dir * 2.2 * delta
	if Vector2(novo.x, novo.z).length() > RAIO_SALA:
		novo = Vector3(novo.x, 0, novo.z).normalized() * RAIO_SALA
	figura.position = novo
	figura.rotation.y = atan2(dir.x, dir.z)
	Pecas.animar(figura, "Walking_A")


func no_sigilo() -> bool:
	return Vector2(figura.position.x, figura.position.z).length() < RAIO_SIGILO


## O ritual: a figura vai ao centro, ajoelha virada para a frente da sala e o círculo acende.
func ajoelhar() -> Tween:
	var tw := create_tween()
	tw.tween_property(figura, "position", Vector3.ZERO, 0.35).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(figura, "rotation:y", 0.0, 0.35)
	tw.tween_callback(func():
		Pecas.animar(figura, "Sit_Floor_Down")
		Som.tocar("ritual"))
	tw.tween_interval(0.9)
	tw.tween_callback(func(): Pecas.animar(figura, "Sit_Floor_Idle"))
	tw.parallel().tween_property(_luz_sigilo, "light_energy", 3.2, 0.8)
	tw.parallel().tween_property(_luz_sigilo, "omni_range", 4.5, 0.8)
	tw.parallel().tween_property(sigilo, "scale", Vector3.ONE * 1.25, 0.8).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(_env, "ambient_light_color", Color("4a2a12"), 0.8)
	return tw


func levantar() -> void:
	Pecas.animar(figura, "Sit_Floor_StandUp")
	var tw := create_tween()
	tw.tween_property(_luz_sigilo, "light_energy", 0.8, 0.6)
	tw.parallel().tween_property(sigilo, "scale", Vector3.ONE, 0.6)
