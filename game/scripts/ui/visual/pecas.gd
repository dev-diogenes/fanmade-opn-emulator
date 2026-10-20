class_name Pecas
extends RefCounted
## Peças low poly geradas por código (sem assets externos), no espírito de For The King.
## Cada função devolve um Node3D pronto para pôr na cena. Quando houver modelos .glb
## feitos no Blender, eles substituem estas funções peça por peça.

static var _materiais: Dictionary = {}
static var _cenas: Dictionary = {}

## Modelos de terceiros (ADR 0008). Sem os arquivos, cada função cai na primitiva.
const DIR_HEX := "res://assets/models/kaykit_hex/"
const DIR_PERSONAGENS := "res://assets/models/kaykit_personagens/"
const DIR_ESQUELETOS := "res://assets/models/kaykit_esqueletos/"
## Raio externo do hex da KayKit (2 de largura entre lados planos)
const RAIO_KAYKIT := 1.1547
const PERSONAGEM_POR_CLASSE := {"combatente": "Knight", "especialista": "Rogue_Hooded",
	"ocultista": "Mage", "mundano": "Barbarian"}
## Tile e decorações por terreno do mapa-múndi
## Estrada usa grama: o caminho é desenhado por cima, ligando os vizinhos (Mapa3D)
const TILE_POR_TERRENO := {"agua": "hex_water", "pantano": "hex_water"}
const DECORACAO_POR_TERRENO := {
	"floresta": ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium"],
	"morro": ["hills_A_trees", "hills_B", "mountain_A_grass_trees", "hill_single_A"],
	"pantano": ["waterlily_A", "waterplant_A", "waterplant_B"],
	"campo": ["tree_single_A", "tree_single_B", "rock_single_A", "", "", ""],
	"cidade": ["barrel", "crate_A_big", "sack", "tent"],
	"ruina": ["rock_single_C", "rock_single_E"],
}


## Instancia um modelo importado, ou null se o arquivo não existe (clone sem LFS, testes).
static func modelo(caminho: String) -> Node3D:
	if not _cenas.has(caminho):
		_cenas[caminho] = load(caminho) if ResourceLoader.exists(caminho) else null
	var cena: PackedScene = _cenas[caminho]
	return cena.instantiate() if cena != null else null


## Tile do mapa com modelo KayKit (topo na altura `altura`) e a decoração do terreno.
## Devolve null sem os modelos: aí o mapa usa `tile_hex` e a decoração por código.
static func tile_terreno(terreno: String, raio: float, altura: float, semente: int,
		tinta: Color = Color.WHITE) -> Node3D:
	var base := modelo(DIR_HEX + TILE_POR_TERRENO.get(terreno, "hex_grass") + ".gltf")
	if base == null:
		return null
	if tinta != Color.WHITE:
		tingir(base, tinta)
	var s := raio / RAIO_KAYKIT * 0.985
	var n := Node3D.new()
	base.scale = Vector3(s, 0.5, s)
	base.position.y = altura
	n.add_child(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var opcoes: Array = DECORACAO_POR_TERRENO.get(terreno, [])
	if not opcoes.is_empty():
		var nome: String = opcoes[rng.randi() % opcoes.size()]
		var deco := modelo(DIR_HEX + nome + ".gltf") if nome != "" else null
		if deco != null:
			if tinta != Color.WHITE:
				tingir(deco, tinta.lerp(Color.WHITE, 0.45))
			# As decorações de cobertura (árvores, morros) ocupam o tile; as soltas são menores e deslocadas
			# O centro do hex fica livre para as figuras (docs/13): a decoração vai para a borda.
			# Morros e matas ficam menores e num dos cantos; as peças soltas, menores ainda.
			var solta := terreno in ["campo", "cidade", "ruina", "pantano"]
			deco.scale = Vector3.ONE * s * (0.45 if solta else 0.6)
			deco.rotation.y = PI / 3.0 * rng.randi_range(0, 5)
			deco.position = Vector3(0, altura - (0.2 * 0.5 if terreno == "pantano" else 0.0), 0)
			var ang := PI / 3.0 * rng.randi_range(0, 5) + PI / 6.0
			deco.position += Vector3(cos(ang), 0, sin(ang)) * raio * (0.5 if solta else 0.42)
			n.add_child(deco)
	return n


## Multiplica a cor dos materiais de um modelo (o atlas da KayKit é claro demais
## para o clima de OP; a tinta vem da cor do terreno no ruleset). Cache por material e tinta.
static func tingir(raiz: Node, tinta: Color) -> void:
	for mi: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var original := mi.mesh.surface_get_material(i) as StandardMaterial3D
			if original == null:
				continue
			var chave := "tinta|%d|%s" % [original.get_instance_id(), tinta.to_html()]
			if not _materiais.has(chave):
				var m := original.duplicate() as StandardMaterial3D
				m.albedo_color = original.albedo_color * tinta
				_materiais[chave] = m
			mi.set_surface_override_material(i, _materiais[chave])


## Figura de um agente: personagem animado da KayKit sobre uma base na cor do jogador
## (como uma peça de tabuleiro). Sem o modelo, cai no peão de `figura`.
static func agente(classe_id: String, cor: Color, escala: float = 1.0) -> Node3D:
	var nome: String = PERSONAGEM_POR_CLASSE.get(classe_id, "Knight")
	var n := personagem(DIR_PERSONAGENS + nome + ".glb", nome.split("_")[0] + "_", cor, escala)
	return n if n != null else figura(cor, escala)


## Figura de uma ameaça (docs/09): criaturas viram esqueletos tingidos pela cor do elemento;
## pessoas e animais viram cultistas encapuzados em vermelho-sangue. Sem os modelos, peças por código.
static func ameaca(ser: Ameaca, escala: float = 1.0) -> Node3D:
	var grande := ser.pv_maximo >= 25
	var cor_base := Color("b03a2e")
	var n: Node3D = null
	if ser.criatura or grande:   # a Aberração da arena de demonstração não vem marcada como criatura
		var nome := "Skeleton_Warrior" if grande else "Skeleton_Minion"
		var elemento: Color = Tema.ELEMENTO.get(ser.elemento, Tema.ELEMENTO.morte)
		n = personagem(DIR_ESQUELETOS + nome + ".glb", nome + "_", elemento.darkened(0.3), escala * (1.25 if grande else 1.0),
			elemento.lerp(Color.WHITE, 0.45))
	else:
		n = personagem(DIR_PERSONAGENS + "Rogue_Hooded.glb", "Rogue_", cor_base, escala, Color(0.62, 0.2, 0.22))
	if n != null:
		return n
	return criatura(cor_base, escala * 1.2) if grande else figura(cor_base, escala)


## Personagem animado sobre uma base colorida (peça de tabuleiro). `prefixo`: só ficam
## visíveis as malhas do corpo (o pacote traz armas e escudos). `tinta` tinge os materiais.
static func personagem(caminho: String, prefixo: String, cor: Color, escala: float = 1.0, tinta: Color = Color.WHITE) -> Node3D:
	var m := modelo(caminho)
	if m == null:
		return null
	var n := Node3D.new()
	var base := CylinderMesh.new()
	base.top_radius = 0.3 * escala
	base.bottom_radius = 0.34 * escala
	base.height = 0.06 * escala
	base.radial_segments = 16
	n.add_child(_malha(base, material(cor.darkened(0.2), false, 0.25), Vector3(0, 0.03 * escala, 0)))
	m.scale = Vector3.ONE * 0.42 * escala
	m.position.y = 0.06 * escala
	for mi in m.find_children("*", "MeshInstance3D", true, false):
		mi.visible = String(mi.name).begins_with(prefixo)
	if tinta != Color.WHITE:
		tingir(m, tinta)
	n.add_child(m)
	var anims := m.find_children("*", "AnimationPlayer", true, false)
	var anim: AnimationPlayer = anims.front() if not anims.is_empty() else null
	if anim != null:
		n.set_meta("anim", anim)
		for a in ["Idle", "Walking_A", "Unarmed_Idle", "2H_Melee_Idle", "Skeletons_Idle"]:
			if anim.has_animation(a):
				anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		for a in ["Idle", "Skeletons_Idle", "2H_Melee_Idle", "Unarmed_Idle"]:
			if anim.has_animation(a):
				n.set_meta("parado", a)
				animar(n, a)
				break
	return n


## Toca uma animação da figura (se ela tiver). Sem efeito nos peões por código.
static func animar(figura_no: Node3D, nome: String, mistura: float = 0.2) -> void:
	if not figura_no.has_meta("anim"):
		return
	if nome == "Idle":
		nome = String(figura_no.get_meta("parado", "Idle"))
	var anim: AnimationPlayer = figura_no.get_meta("anim")
	if anim.has_animation(nome) and anim.current_animation != nome:
		anim.play(nome, mistura)


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


## Paredes de reboco do interior (cal, amarelo, rosa, azul desbotado) e telha de barro.
const PAREDES_BR := [Color("e8e2d0"), Color("d9b45a"), Color("c98f86"), Color("8fa7b3"), Color("b9c49a")]

static func casa_br(semente: int) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	return casa(PAREDES_BR[rng.randi() % PAREDES_BR.size()], Color("9a4a2c").darkened(rng.randf() * 0.2))


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


## Marco de OP no mapa (docs/09): sigilo no chão na cor do tipo e uma peça flutuante
## (cultista em miniatura no encontro, obelisco no covil, "?" no evento, foto na investigação).
## Devolve um Node3D com meta "peca" (o que flutua) e "cor".
const COR_MARCO := {"encontro": Color("c0392b"), "evento": Color("e3c27a"), "objetivo": Color("8e1b22"),
	"investigacao": Color("7fd3c7"), "vila": Color("f2c6a0"), "inicio": Color("5dade2")}

static func marco(tipo: String) -> Node3D:
	var cor: Color = COR_MARCO.get(tipo, Color.WHITE)
	var n := Node3D.new()
	n.add_child(sigilo_no_chao(hash(tipo) % 997, cor, 0.8 if tipo != "objetivo" else 1.0))
	var peca: Node3D
	match tipo:
		"encontro":
			var cult := cultista_miniatura(0.55)
			peca = cult if cult != null else _peca_do_marcador(tipo)
		"objetivo":
			peca = Node3D.new()
			var obelisco := PrismMesh.new()
			obelisco.size = Vector3(0.16, 0.7, 0.16)
			peca.add_child(_malha(obelisco, material(Color("0b0a0e")), Vector3(0, 0.35, 0)))
			var nucleo := SphereMesh.new()
			nucleo.radius = 0.07
			nucleo.height = 0.14
			peca.add_child(_malha(nucleo, material(cor.lightened(0.3), false, 3.0), Vector3(0, 0.78, 0)))
		"evento", "investigacao", "vila", "inicio":
			var simbolo: String = {"evento": "?", "investigacao": "◎", "vila": "⌂", "inicio": "✦"}[tipo]
			var l := rotulo(simbolo, 120, cor)
			l.position = Vector3(0, 0.55, 0)
			l.outline_size = 18
			var fonte := Tema.fonte_titulo()
			if fonte != null and tipo == "evento":
				l.font = fonte
			peca = Node3D.new()
			peca.add_child(l)
		_:
			peca = _peca_do_marcador(tipo)
	n.add_child(peca)
	n.set_meta("peca", peca)
	n.set_meta("cor", cor)
	return n


## A peça flutuante do marcador antigo (sem modelos), solta do nó que a criou.
static func _peca_do_marcador(tipo: String) -> Node3D:
	var antigo := marcador(tipo)
	var peca: Node3D = antigo.get_child(0)
	antigo.remove_child(peca)
	antigo.free()
	return peca


## Cultista encapuzado em miniatura (encontros no mapa), ou null sem o modelo.
static func cultista_miniatura(escala: float) -> Node3D:
	return personagem(DIR_PERSONAGENS + "Rogue_Hooded.glb", "Rogue_", Color("b03a2e"), escala, Color(0.62, 0.2, 0.22))


## Sigilo procedural deitado no chão (cache da textura por semente e cor).
static func sigilo_no_chao(semente: int, cor: Color, tamanho: float = 0.9) -> MeshInstance3D:
	var chave := "sigilo|%d|%s" % [semente, cor.to_html()]
	if not _materiais.has(chave):
		var m := StandardMaterial3D.new()
		m.albedo_texture = Sigilo.imagem(semente, 128, Color.WHITE, 4.0)
		m.albedo_color = cor
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materiais[chave] = m
	var plano := PlaneMesh.new()
	plano.size = Vector2(tamanho, tamanho)
	var mi := _malha(plano, _materiais[chave], Vector3(0, 0.015, 0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


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


## Tile de hexágono em diorama (ADR 0008): corpo de terra chanfrado e tampa na cor do terreno.
static func tile_hex(raio: float, altura: float, cor: Color) -> Node3D:
	var n := Node3D.new()
	var tampa := 0.06
	var corpo := CylinderMesh.new()
	corpo.top_radius = raio * 0.97
	corpo.bottom_radius = raio * 0.9
	corpo.height = altura + 0.3   # desce abaixo do zero: o tile parece uma peça grossa
	corpo.radial_segments = 6
	corpo.rings = 1
	var terra := cor.lerp(Color("4a3a2c"), 0.6).darkened(0.25)
	n.add_child(_malha(corpo, material(terra), Vector3(0, (altura - tampa) - corpo.height / 2.0, 0)))
	var topo := CylinderMesh.new()
	topo.top_radius = raio * 0.93
	topo.bottom_radius = raio
	topo.height = tampa
	topo.radial_segments = 6
	topo.rings = 1
	n.add_child(_malha(topo, material(cor), Vector3(0, altura - tampa / 2.0, 0)))
	return n


## Hex não revelado: peça escura com a névoa roxa animada do Outro Lado por cima (docs/08, R5).
static func nevoa(raio: float, altura: float, cor: Color) -> Node3D:
	var n := tile_hex(raio, altura, cor)
	var shader: Shader = load("res://assets/shaders/nevoa_outro_lado.gdshader") 		if ResourceLoader.exists("res://assets/shaders/nevoa_outro_lado.gdshader") else null
	if shader == null:
		return n
	if not _materiais.has("nevoa"):
		var m := ShaderMaterial.new()
		m.shader = shader
		_materiais["nevoa"] = m
	var topo := CylinderMesh.new()
	topo.top_radius = raio * 0.95
	topo.bottom_radius = raio * 0.95
	topo.height = 0.01
	topo.radial_segments = 6
	topo.rings = 1
	var mi := _malha(topo, _materiais["nevoa"], Vector3(0, altura + 0.006, 0))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(mi)
	return n


## Luz, ambiente e névoa de horror para qualquer cena 3D (ADR 0008: luz quente,
## céu em gradiente, névoa, SSAO, glow, ACES e desfoque de maquete nas bordas).
static func ambiente(raiz: Node3D, cor_ceu: Color = Color("1b1a26")) -> void:
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-50, -40, 0)
	sol.light_energy = 1.2
	sol.light_color = Color("fff0dc")
	sol.shadow_enabled = true
	sol.shadow_blur = 1.5
	sol.directional_shadow_max_distance = 60.0
	raiz.add_child(sol)
	# Luz de recorte fria do lado oposto: separa as peças do fundo
	var recorte := DirectionalLight3D.new()
	recorte.rotation_degrees = Vector3(-25, 140, 0)
	recorte.light_energy = 0.35
	recorte.light_color = Color("7f8fd6")
	raiz.add_child(recorte)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = cor_ceu.darkened(0.3)
	ceu.sky_horizon_color = cor_ceu.lerp(Color("5a3a4a"), 0.45)
	ceu.ground_horizon_color = ceu.sky_horizon_color
	ceu.ground_bottom_color = cor_ceu.darkened(0.5)
	ceu.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = ceu
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("767c9c")
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = ceu.sky_horizon_color
	env.fog_density = 0.018
	env.fog_sky_affect = 0.4
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.6
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.95
	env.adjustment_contrast = 1.05
	amb.environment = env
	var camera_attr := CameraAttributesPractical.new()
	camera_attr.dof_blur_far_enabled = true
	camera_attr.dof_blur_far_distance = 16.0
	camera_attr.dof_blur_far_transition = 12.0
	camera_attr.dof_blur_amount = 0.06
	amb.camera_attributes = camera_attr
	raiz.add_child(amb)
	# Mesa escura sob o diorama: o vazio deixa de ser uma cor chapada
	var mesa := PlaneMesh.new()
	mesa.size = Vector2(400, 400)
	var chao := _malha(mesa, material(cor_ceu.lerp(Color("0d0c12"), 0.5)), Vector3(0, -0.5, 0))
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(chao)
