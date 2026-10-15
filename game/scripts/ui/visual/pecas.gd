class_name Pecas
extends RefCounted
## Peças low poly geradas por código (sem assets externos), no espírito de For The King.
## Cada função devolve um Node3D pronto para pôr na cena. Quando houver modelos .glb
## feitos no Blender, eles substituem estas funções peça por peça.

static var _materiais: Dictionary = {}


## Material fosco (cache por cor). `transparente` para destaques.
static func material(cor: Color, transparente: bool = false, emissao: float = 0.0) -> StandardMaterial3D:
	var chave := "%s|%s|%s" % [cor.to_html(), transparente, emissao]
	if _materiais.has(chave):
		return _materiais[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	m.metallic = 0.0
	if transparente:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if emissao > 0.0:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = emissao
	_materiais[chave] = m
	return m


static func _malha(mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi


## Prisma hexagonal "pointy-top" de raio `raio` (um tile do mapa).
static func prisma_hex(raio: float, altura: float, cor: Color) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = raio
	m.bottom_radius = raio
	m.height = altura
	m.radial_segments = 6
	m.rings = 1
	return _malha(m, material(cor), Vector3(0, altura / 2.0, 0))


static func arvore(altura: float, cor: Color = Color("2e5e34")) -> Node3D:
	var n := Node3D.new()
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.035
	tronco.bottom_radius = 0.05
	tronco.height = altura * 0.35
	tronco.radial_segments = 5
	n.add_child(_malha(tronco, material(Color("4a3426")), Vector3(0, altura * 0.175, 0)))
	var copa := CylinderMesh.new()
	copa.top_radius = 0.0
	copa.bottom_radius = altura * 0.32
	copa.height = altura * 0.8
	copa.radial_segments = 6
	n.add_child(_malha(copa, material(cor), Vector3(0, altura * 0.35 + altura * 0.4, 0)))
	return n


static func casa(cor_parede: Color = Color("b8a88a"), cor_telhado: Color = Color("7b3f2e")) -> Node3D:
	var n := Node3D.new()
	var corpo := BoxMesh.new()
	corpo.size = Vector3(0.32, 0.22, 0.26)
	n.add_child(_malha(corpo, material(cor_parede), Vector3(0, 0.11, 0)))
	var telhado := PrismMesh.new()
	telhado.size = Vector3(0.36, 0.14, 0.3)
	n.add_child(_malha(telhado, material(cor_telhado), Vector3(0, 0.29, 0)))
	return n


static func pilar_quebrado(altura: float) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(0.1, altura, 0.1)
	return _malha(m, material(Color("8e8496")), Vector3(0, altura / 2.0, 0))


static func rocha(tamanho: float) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = tamanho
	m.height = tamanho * 1.3
	m.radial_segments = 6
	m.rings = 3
	return _malha(m, material(Color("7d7466")), Vector3(0, tamanho * 0.4, 0))


static func caixote(tamanho: float = 0.6) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(tamanho, tamanho * 0.75, tamanho)
	return _malha(m, material(Color("8b6a3e")), Vector3(0, tamanho * 0.375, 0))


static func parede(altura: float = 1.4) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(1.0, altura, 1.0)
	return _malha(m, material(Color("4a4f5c")), Vector3(0, altura / 2.0, 0))


static func capim(cor: Color = Color("2f5a2a")) -> Node3D:
	var n := Node3D.new()
	for i in 4:
		var m := CylinderMesh.new()
		m.top_radius = 0.0
		m.bottom_radius = 0.05
		m.height = 0.25
		m.radial_segments = 4
		n.add_child(_malha(m, material(cor), Vector3(-0.25 + 0.17 * i, 0.12, -0.15 + 0.1 * (i % 3))))
	return n


## Figura low poly (peão): base, corpo e cabeça. `escala` 1 = cabe num tile/quadrado.
static func figura(cor: Color, escala: float = 1.0) -> Node3D:
	var n := Node3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 0.24 * escala
	base.bottom_radius = 0.28 * escala
	base.height = 0.08 * escala
	base.radial_segments = 8
	n.add_child(_malha(base, material(cor.darkened(0.35)), Vector3(0, 0.04 * escala, 0)))
	var corpo := CylinderMesh.new()
	corpo.top_radius = 0.1 * escala
	corpo.bottom_radius = 0.19 * escala
	corpo.height = 0.5 * escala
	corpo.radial_segments = 8
	n.add_child(_malha(corpo, material(cor), Vector3(0, 0.33 * escala, 0)))
	var cabeca := SphereMesh.new()
	cabeca.radius = 0.12 * escala
	cabeca.height = 0.24 * escala
	cabeca.radial_segments = 8
	cabeca.rings = 4
	n.add_child(_malha(cabeca, material(cor.lightened(0.15)), Vector3(0, 0.68 * escala, 0)))
	return n


## Monstro: figura maior e angulosa.
static func criatura(cor: Color, escala: float = 1.0) -> Node3D:
	var n := Node3D.new()
	var corpo := SphereMesh.new()
	corpo.radius = 0.3 * escala
	corpo.height = 0.5 * escala
	corpo.radial_segments = 5
	corpo.rings = 2
	n.add_child(_malha(corpo, material(cor), Vector3(0, 0.3 * escala, 0)))
	for lado in [-1, 1]:
		var chifre := CylinderMesh.new()
		chifre.top_radius = 0.0
		chifre.bottom_radius = 0.06 * escala
		chifre.height = 0.3 * escala
		chifre.radial_segments = 4
		var c := _malha(chifre, material(cor.darkened(0.4)), Vector3(0.14 * lado * escala, 0.6 * escala, 0))
		c.rotation.z = -0.4 * lado
		n.add_child(c)
	return n


## Anel no chão (destaque de seleção / vez).
static func anel(raio: float, cor: Color) -> MeshInstance3D:
	var m := TorusMesh.new()
	m.inner_radius = raio * 0.82
	m.outer_radius = raio
	m.rings = 12
	m.ring_segments = 4
	return _malha(m, material(cor, false, 1.5), Vector3(0, 0.03, 0))


## Marcador flutuante (encontro, evento, objetivo).
static func marcador(tipo: String) -> Node3D:
	var n := Node3D.new()
	var cor: Color = {"encontro": Color("e74c3c"), "evento": Color("f4d03f"), "objetivo": Color("8e1b1b"), "investigacao": Color("48c9b0"),
		"vila": Color("ecf0f1"), "inicio": Color("5dade2")}.get(tipo, Color.WHITE)
	var m: Mesh
	match tipo:
		"encontro":
			var p := PrismMesh.new()
			p.size = Vector3(0.22, 0.3, 0.08)
			m = p
		"investigacao":
			var t := TorusMesh.new()
			t.inner_radius = 0.07
			t.outer_radius = 0.13
			t.rings = 10
			t.ring_segments = 4
			m = t
		"objetivo":
			var s := SphereMesh.new()
			s.radius = 0.16
			s.height = 0.32
			s.radial_segments = 6
			s.rings = 3
			m = s
		_:
			var b := BoxMesh.new()
			b.size = Vector3(0.14, 0.14, 0.14)
			m = b
	var mi := _malha(m, material(cor, false, 0.8), Vector3(0, 0.75, 0))
	if tipo != "encontro":
		mi.rotation = Vector3(0.6, 0.7, 0.0)
	n.add_child(mi)
	return n


static func rotulo(texto: String, tamanho: int = 48, cor: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = texto
	l.font_size = tamanho
	l.pixel_size = 0.004
	l.modulate = cor
	l.outline_size = 12
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	return l


## Luz, ambiente e névoa de horror para qualquer cena 3D.
static func ambiente(raiz: Node3D, cor_ceu: Color = Color("1b1a26")) -> void:
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, -35, 0)
	sol.light_energy = 1.1
	sol.light_color = Color("ffe8cc")
	sol.shadow_enabled = true
	raiz.add_child(sol)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = cor_ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6a6f8a")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color("2a2638")
	env.fog_density = 0.012
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	amb.environment = env
	raiz.add_child(amb)
