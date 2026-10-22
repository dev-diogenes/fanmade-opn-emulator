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
## Serra (docs/34): sem decoração KayKit; o paredão vem por código (Mapa3D)
const DECORACAO_POR_TERRENO := {
	"floresta": ["trees_A_large", "trees_A_medium", "trees_B_large", "trees_B_medium"],
	"morro": ["hills_A_trees", "hills_B", "mountain_A_grass_trees", "hill_single_A"],
	"pantano": ["waterlily_A", "waterplant_A", "waterplant_B"],
	"campo": ["tree_single_A", "tree_single_B", "rock_single_A", "", "", ""],
	"cidade": [],   # docs/32: casas, postes e orelhões por código; nada de feira medieval
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
			# Escala de miniatura (docs/32): árvore mais alta que o agente (0,82). Só a altura cresce,
			# para a copa não invadir o centro do hex.
			if terreno == "floresta":
				deco.scale.y = s * 1.1
			elif nome.begins_with("tree"):
				deco.scale.y = s * 1.0
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


## Aparências escolhidas na foto do dossiê (docs/19): modelo da KayKit e tom da roupa.
const APARENCIAS := {"Knight": "Armadura", "Rogue_Hooded": "Capuz", "Mage": "Chapéu", "Barbarian": "Rústico"}
const TONS := [["Original", Color.WHITE], ["Sépia", Color("d9c39c")], ["Noite", Color("8d9bbb")], ["Luto", Color("77707c")]]


## Modelo de um agente: o escolhido na foto ou, sem escolha, o da classe.
static func modelo_do_agente(classe_id: String, aparencia: String = "") -> String:
	return aparencia if APARENCIAS.has(aparencia) else String(PERSONAGEM_POR_CLASSE.get(classe_id, "Knight"))


## Figura de um agente: personagem animado da KayKit sobre uma base na cor do jogador
## (como uma peça de tabuleiro). Sem o modelo, cai no peão de `figura`.
static func agente(classe_id: String, cor: Color, escala: float = 1.0, aparencia: String = "", tom: int = 0) -> Node3D:
	var nome := modelo_do_agente(classe_id, aparencia)
	var tinta: Color = TONS[clampi(tom, 0, TONS.size() - 1)][1]
	var n := personagem(DIR_PERSONAGENS + nome + ".glb", nome.split("_")[0] + "_", cor, escala, tinta)
	return n if n != null else figura(cor, escala)


## A figura com a aparência escolhida pelo jogador.
static func do_agente(a: Agente, cor: Color, escala: float = 1.0) -> Node3D:
	return agente(a.classe_id, cor, escala, a.aparencia, a.tom)


## Figura de uma ameaça (docs/09): criaturas viram esqueletos tingidos pela cor do elemento;
## pessoas e animais viram cultistas encapuzados em vermelho-sangue. Sem os modelos, peças por código.
static func ameaca(ser: Ameaca, escala: float = 1.0) -> Node3D:
	var grande := ser.pv_maximo >= 25
	var cor_base := Color("b03a2e")
	var n: Node3D = null
	if ser.criatura or grande:   # a Aberração da arena de demonstração não vem marcada como criatura
		var nome := "Skeleton_Warrior" if grande else "Skeleton_Minion"
		var elemento: Color = Tema.ELEMENTO.get(ser.elemento, Tema.ELEMENTO.morte)
		var tinta := elemento.lerp(Color.WHITE, 0.45)
		match ser.elemento:   # a cor de cada elemento no mundo (docs/54)
			"morte": tinta = Tema.LODO_MORTE.lerp(elemento, 0.35)
			"energia": tinta = Tema.ESPECTRO_ENERGIA[absi(hash(ser.nome)) % Tema.ESPECTRO_ENERGIA.size()].lightened(0.15)
			"medo": tinta = Color(0.85, 0.88, 0.92)
		n = personagem(DIR_ESQUELETOS + nome + ".glb", nome + "_", elemento.darkened(0.3), escala * (1.25 if grande else 1.0), tinta)
		if n != null and ser.elemento == "medo":
			for mi in n.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).transparency = 0.55   # o Medo distorce: quase transparente
		if n != null and ser.elemento == "energia":
			_neon(n)
	else:
		n = personagem(DIR_PERSONAGENS + "Rogue_Hooded.glb", "Rogue_", cor_base, escala, Color(0.62, 0.2, 0.22))
	if n != null:
		return n
	return criatura(cor_base, escala * 1.2) if grande else figura(cor_base, escala)


## A criatura de Energia pisca no espectro neon (docs/54): uma luz que troca de cor sem parar.
static func _neon(n: Node3D) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = Tema.ESPECTRO_ENERGIA[0]
	luz.light_energy = 1.2
	luz.omni_range = 1.4
	luz.position = Vector3(0, 0.6, 0)
	Qualidade.luz_extra(luz)
	n.add_child(luz)
	var tw := luz.create_tween().set_loops()
	for cor in Tema.ESPECTRO_ENERGIA:
		tw.tween_property(luz, "light_color", cor, 0.35)


## Presságio do elemento no mapa (docs/54): o sinal que aparece num hex revelado vizinho a uma
## criatura, antes de o grupo dar de cara com ela. Sangue: carcaça e mancha; Morte: relva cinza e
## cinza em espiral; Conhecimento: corda e máscara num poste; Energia: poste com luz que pisca em
## neon; Medo: névoa que não se mexe com o vento.
static func pressagio(elemento: String) -> Node3D:
	var n := Node3D.new()
	match elemento:
		"sangue":
			var mancha := CylinderMesh.new()
			mancha.top_radius = 0.28
			mancha.bottom_radius = 0.3
			mancha.height = 0.01
			n.add_child(_malha(mancha, material(Color("4a0f12")), Vector3(0, 0.01, 0)))
			var corpo := SphereMesh.new()
			corpo.radius = 0.13
			corpo.height = 0.14
			n.add_child(_malha(corpo, material(Color("5a3a2e")), Vector3(0.05, 0.05, 0)))
			for i in 3:
				var costela := BoxMesh.new()
				costela.size = Vector3(0.02, 0.09, 0.02)
				var c := _malha(costela, material(Color("d8cfb8")), Vector3(-0.06 + i * 0.06, 0.1, 0.03))
				c.rotation.z = 0.4
				n.add_child(c)
		"morte":
			var relva := CylinderMesh.new()
			relva.top_radius = 0.34
			relva.bottom_radius = 0.34
			relva.height = 0.01
			n.add_child(_malha(relva, material(Color("5c5a5e")), Vector3(0, 0.01, 0)))
			for i in 9:   # cinza em espiral
				var a := i * 0.7
				var cinza := BoxMesh.new()
				cinza.size = Vector3(0.03, 0.015, 0.03)
				n.add_child(_malha(cinza, material(Color("c9c4bc")), Vector3(cos(a) * 0.03 * i, 0.02, sin(a) * 0.03 * i)))
		"conhecimento":
			var poste := BoxMesh.new()
			poste.size = Vector3(0.04, 0.6, 0.04)
			n.add_child(_malha(poste, material(Color("3a2a1e")), Vector3(0, 0.3, 0)))
			var corda := BoxMesh.new()
			corda.size = Vector3(0.012, 0.22, 0.012)
			n.add_child(_malha(corda, material(Color("b8a77a")), Vector3(0.06, 0.45, 0)))
			var mascara := SphereMesh.new()
			mascara.radius = 0.06
			mascara.height = 0.08
			n.add_child(_malha(mascara, material(Tema.ELEMENTO.conhecimento, false, 0.6), Vector3(0.06, 0.32, 0.02)))
		"energia":
			var poste := BoxMesh.new()
			poste.size = Vector3(0.04, 0.7, 0.04)
			n.add_child(_malha(poste, material(Color("2b2b33")), Vector3(0, 0.35, 0)))
			var luz := OmniLight3D.new()
			luz.light_color = Tema.ESPECTRO_ENERGIA[2]
			luz.light_energy = 1.0
			luz.omni_range = 1.1
			luz.position = Vector3(0, 0.72, 0)
			n.add_child(luz)
			var tw := luz.create_tween().set_loops()
			tw.tween_property(luz, "light_energy", 0.0, 0.07)
			tw.tween_property(luz, "light_color", Tema.ESPECTRO_ENERGIA[1], 0.0)
			tw.tween_property(luz, "light_energy", 1.3, 0.12)
			tw.tween_interval(0.9)
			tw.tween_property(luz, "light_energy", 0.0, 0.05)
			tw.tween_property(luz, "light_color", Tema.ESPECTRO_ENERGIA[2], 0.0)
			tw.tween_property(luz, "light_energy", 1.0, 0.1)
			tw.tween_interval(1.4)
		_:   # Medo: névoa parada
			for i in 4:
				var bola := SphereMesh.new()
				bola.radius = 0.18 + 0.05 * (i % 2)
				bola.height = bola.radius * 1.2
				var m := material(Color(0.86, 0.88, 0.92))
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color.a = 0.28
				n.add_child(_malha(bola, m, Vector3(-0.2 + i * 0.13, 0.12, 0.05 * (i % 3))))
	return n


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
	var parede: Color = PAREDES_BR[rng.randi() % PAREDES_BR.size()]
	var telhado := Color("9a4a2c").darkened(rng.randf() * 0.2)
	var acesa := rng.randf() < 0.65   # de noite, nem toda casa tem alguém acordado
	return casa(parede, telhado, acesa, rng.randf() < 0.5)


## Casa de alvenaria do interior (docs/32): reboco com barrado escuro, telha de barro, porta
## de frente (+Z) e, às vezes, a caixa d'água azul no telhado. Tem ~0,88 de altura, um pouco
## mais que o agente no mapa (0,82). `acesa`: janelas quentes na noite (docs/22).
const ALTURA_CASA := 0.88

static func casa(cor_parede: Color = Color("b8a88a"), cor_telhado: Color = Color("7b3f2e"), acesa: bool = true,
		caixa_dagua: bool = false) -> Node3D:
	var n := Node3D.new()
	var corpo := BoxMesh.new()
	corpo.size = Vector3(0.5, 0.6, 0.42)
	n.add_child(_malha(corpo, material(cor_parede), Vector3(0, 0.3, 0)))
	var barrado := BoxMesh.new()   # a faixa de baixo, encardida de barro
	barrado.size = Vector3(0.508, 0.09, 0.428)
	n.add_child(_malha(barrado, material(cor_parede.darkened(0.45)), Vector3(0, 0.045, 0)))
	var telhado := PrismMesh.new()
	telhado.size = Vector3(0.58, 0.28, 0.5)
	n.add_child(_malha(telhado, material(cor_telhado), Vector3(0, 0.74, 0)))
	var porta := BoxMesh.new()
	porta.size = Vector3(0.11, 0.24, 0.008)
	n.add_child(_malha(porta, material(Color("3b2a1e")), Vector3(-0.12, 0.12, 0.212)))
	var vidro := material(Color("ffb04a"), false, 2.6) if acesa else material(Color("0b0a0e"))
	for janela_pos in [Vector3(0.1, 0.32, 0.212), Vector3(-0.12, 0.36, -0.212), Vector3(0.12, 0.36, -0.212)]:
		var janela := BoxMesh.new()
		janela.size = Vector3(0.1, 0.11, 0.008)
		var mi := _malha(janela, vidro, janela_pos)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	if caixa_dagua:
		var caixa := CylinderMesh.new()
		caixa.top_radius = 0.07
		caixa.bottom_radius = 0.06
		caixa.height = 0.08
		caixa.radial_segments = 8
		n.add_child(_malha(caixa, material(Color("2f5f8f")), Vector3(0.12, 0.8, 0)))
	n.set_meta("acesa", acesa)
	return n


## Poste de concreto com cruzeta, fios e uma lâmpada de rua (emissiva se `acesa`). ~1,0 de altura.
static func poste(acesa: bool = true) -> Node3D:
	var n := Node3D.new()
	var haste := CylinderMesh.new()
	haste.top_radius = 0.016
	haste.bottom_radius = 0.026
	haste.height = 1.0
	haste.radial_segments = 6
	n.add_child(_malha(haste, material(Color("8a8780")), Vector3(0, 0.5, 0)))
	var cruzeta := BoxMesh.new()
	cruzeta.size = Vector3(0.24, 0.02, 0.02)
	n.add_child(_malha(cruzeta, material(Color("5a5048")), Vector3(0, 0.92, 0)))
	var braco := BoxMesh.new()
	braco.size = Vector3(0.012, 0.012, 0.16)
	n.add_child(_malha(braco, material(Color("5a5048")), Vector3(0, 0.84, 0.08)))
	var lampada := SphereMesh.new()
	lampada.radius = 0.025
	lampada.height = 0.04
	var cor := Color("ffcf7a")
	n.add_child(_malha(lampada, material(cor, false, 3.0) if acesa else material(Color("2a2a2a")), Vector3(0, 0.82, 0.16)))
	# Fios caídos para os lados (dois segmentos inclinados por lado)
	for lado in [-1.0, 1.0]:
		var fio := BoxMesh.new()
		fio.size = Vector3(0.36, 0.004, 0.004)
		var f := _malha(fio, material(Color("15130f")), Vector3(0.28 * lado, 0.89, 0))
		f.rotation.z = 0.16 * lado
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(f)
	n.set_meta("acesa", acesa)
	return n


## Orelhão (telefone público): haste e a concha laranja. ~0,5 de altura.
static func orelhao() -> Node3D:
	var n := Node3D.new()
	var haste := CylinderMesh.new()
	haste.top_radius = 0.012
	haste.bottom_radius = 0.016
	haste.height = 0.38
	haste.radial_segments = 6
	n.add_child(_malha(haste, material(Color("6f6a64")), Vector3(0, 0.19, 0)))
	var concha := SphereMesh.new()
	concha.radius = 0.09
	concha.height = 0.2
	concha.is_hemisphere = true
	concha.radial_segments = 10
	concha.rings = 4
	var c := _malha(concha, material(Color("d8742a")), Vector3(0, 0.36, 0.04))
	c.rotation.x = deg_to_rad(-80)
	n.add_child(c)
	var aparelho := BoxMesh.new()
	aparelho.size = Vector3(0.05, 0.08, 0.03)
	n.add_child(_malha(aparelho, material(Color("3f4048")), Vector3(0, 0.36, 0.05)))
	return n


## Carro popular largado (fusca/chevette): carroceria, cabine e rodas. ~0,36 de altura, 0,72 de comprimento.
static func carro(cor: Color = Color("6d7a6a")) -> Node3D:
	var n := Node3D.new()
	var corpo := BoxMesh.new()
	corpo.size = Vector3(0.34, 0.14, 0.72)
	n.add_child(_malha(corpo, material(cor), Vector3(0, 0.13, 0)))
	var cabine := BoxMesh.new()
	cabine.size = Vector3(0.3, 0.13, 0.36)
	n.add_child(_malha(cabine, material(cor.darkened(0.1)), Vector3(0, 0.26, -0.04)))
	var vidro := BoxMesh.new()
	vidro.size = Vector3(0.28, 0.09, 0.006)
	n.add_child(_malha(vidro, material(Color("12161c")), Vector3(0, 0.27, 0.141)))
	var roda := CylinderMesh.new()
	roda.top_radius = 0.06
	roda.bottom_radius = 0.06
	roda.height = 0.05
	roda.radial_segments = 8
	for x in [-0.17, 0.17]:
		for z in [-0.22, 0.22]:
			var r := _malha(roda, material(Color("141414")), Vector3(x, 0.06, z))
			r.rotation.z = PI / 2.0
			n.add_child(r)
	return n


## Pedaço de parede de tijolo que sobrou (ruínas): altura irregular, reboco caído.
static func parede_quebrada(altura: float, largura: float = 0.4) -> Node3D:
	var n := Node3D.new()
	var base := BoxMesh.new()
	base.size = Vector3(largura, altura * 0.6, 0.07)
	n.add_child(_malha(base, material(Color("8c5a44")), Vector3(0, altura * 0.3, 0)))
	var topo := BoxMesh.new()   # o lado que ainda está de pé
	topo.size = Vector3(largura * 0.45, altura * 0.4, 0.07)
	n.add_child(_malha(topo, material(Color("8c5a44")), Vector3(-largura * 0.275, altura * 0.8, 0)))
	var reboco := BoxMesh.new()
	reboco.size = Vector3(largura * 0.5, altura * 0.35, 0.074)
	n.add_child(_malha(reboco, material(Color("7d7466")), Vector3(largura * 0.15, altura * 0.22, 0)))
	return n


## Cruz de madeira (capelas de beira de estrada, túmulos). `caida` a deita torta no chão.
static func cruz(altura: float = 0.6, caida: bool = false) -> Node3D:
	var n := Node3D.new()
	var madeira := material(Color("4a3426"))
	var haste := BoxMesh.new()
	haste.size = Vector3(0.05, altura, 0.05)
	n.add_child(_malha(haste, madeira, Vector3(0, altura / 2.0, 0)))
	var travessa := BoxMesh.new()
	travessa.size = Vector3(altura * 0.55, 0.045, 0.045)
	n.add_child(_malha(travessa, madeira, Vector3(0, altura * 0.72, 0)))
	if caida:
		n.rotation.x = deg_to_rad(-78)
		n.position.y = 0.03
	return n


## Fita de isolamento amarela em estacas, num círculo de `raio` (cena de investigação, docs/32).
## As figuras ficam dentro do círculo.
static func fita_isolamento(raio: float = 0.5, estacas: int = 5) -> Node3D:
	var n := Node3D.new()
	var amarelo := material(Color("e8c33a"), false, 0.25)
	var cantos: Array[Vector3] = []
	for i in estacas:
		var ang := TAU * i / estacas + 0.3
		cantos.append(Vector3(cos(ang), 0, sin(ang)) * raio)
	for i in estacas:
		var estaca := CylinderMesh.new()
		estaca.top_radius = 0.012
		estaca.bottom_radius = 0.012
		estaca.height = 0.24
		estaca.radial_segments = 5
		n.add_child(_malha(estaca, material(Color("3a3530")), cantos[i] + Vector3(0, 0.12, 0)))
		var a := cantos[i]
		var b := cantos[(i + 1) % estacas]
		if i == estacas - 1:
			continue   # um lado aberto: a fita foi arrebentada (ou é a entrada)
		var fita := BoxMesh.new()
		fita.size = Vector3(a.distance_to(b), 0.035, 0.004)
		var f := _malha(fita, amarelo, (a + b) / 2.0 + Vector3(0, 0.2, 0))
		f.rotation.y = -atan2(b.z - a.z, b.x - a.x)
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(f)
	# A plaquinha amarela de evidência, perto da borda
	var placa := PrismMesh.new()
	placa.size = Vector3(0.09, 0.08, 0.06)
	n.add_child(_malha(placa, amarelo, Vector3(raio * 0.55, 0.04, -raio * 0.3)))
	return n


## Cerca de arame e mourões de madeira (campos e pastos, docs/34). ~0,22 de altura.
static func cerca(comprimento: float = 0.5) -> Node3D:
	var n := Node3D.new()
	var madeira := material(Color("5a4330"))
	var postes := 3
	for i in postes:
		var m := BoxMesh.new()
		m.size = Vector3(0.025, 0.24, 0.025)
		n.add_child(_malha(m, madeira, Vector3(-comprimento / 2.0 + comprimento * i / (postes - 1), 0.12, 0)))
	for y in [0.1, 0.18]:
		var fio := BoxMesh.new()
		fio.size = Vector3(comprimento, 0.005, 0.005)
		var f := _malha(fio, material(Color("8a8780")), Vector3(0, y, 0))
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(f)
	return n


## Moita baixa: duas ou três bolas de folhagem.
static func arbusto(tamanho: float = 0.14, cor: Color = Color("2f4f2a")) -> Node3D:
	var n := Node3D.new()
	for i in 3:
		var m := SphereMesh.new()
		m.radius = tamanho * (1.0 - 0.2 * i)
		m.height = tamanho * 1.6 * (1.0 - 0.2 * i)
		m.radial_segments = 6
		m.rings = 3
		n.add_child(_malha(m, material(cor.darkened(0.08 * i)), Vector3((i - 1) * tamanho * 0.8, tamanho * 0.6, (i % 2) * tamanho * 0.5)))
	return n


## Toco de árvore cortada.
static func toco() -> Node3D:
	var n := Node3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.045
	m.bottom_radius = 0.06
	m.height = 0.08
	m.radial_segments = 7
	n.add_child(_malha(m, material(Color("4a3426")), Vector3(0, 0.04, 0)))
	var topo := CylinderMesh.new()
	topo.top_radius = 0.042
	topo.bottom_radius = 0.042
	topo.height = 0.006
	topo.radial_segments = 7
	n.add_child(_malha(topo, material(Color("b39566")), Vector3(0, 0.082, 0)))
	return n


## Cupinzeiro de pasto (o morrinho de terra vermelha do interior).
static func cupinzeiro() -> Node3D:
	var n := Node3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.02
	m.bottom_radius = 0.09
	m.height = 0.2
	m.radial_segments = 7
	n.add_child(_malha(m, material(Color("8a4a2c")), Vector3(0, 0.1, 0)))
	var lado := CylinderMesh.new()
	lado.top_radius = 0.01
	lado.bottom_radius = 0.05
	lado.height = 0.11
	lado.radial_segments = 6
	n.add_child(_malha(lado, material(Color("7d4228")), Vector3(0.06, 0.055, 0.02)))
	return n


## Marco de quilômetro de estrada: o toco branco de concreto com a faixa preta.
static func marco_km() -> Node3D:
	var n := Node3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.07, 0.16, 0.04)
	n.add_child(_malha(m, material(Color("d9d4c8")), Vector3(0, 0.08, 0)))
	var faixa := BoxMesh.new()
	faixa.size = Vector3(0.072, 0.03, 0.042)
	n.add_child(_malha(faixa, material(Color("1a1a1a")), Vector3(0, 0.13, 0)))
	return n


## Árvore seca de galhos tortos (pântano e beira de estrada à noite).
static func arvore_seca(altura: float = 0.8) -> Node3D:
	var n := Node3D.new()
	var madeira := material(Color("3a2c22"))
	var tronco := CylinderMesh.new()
	tronco.top_radius = 0.018
	tronco.bottom_radius = 0.04
	tronco.height = altura
	tronco.radial_segments = 5
	n.add_child(_malha(tronco, madeira, Vector3(0, altura / 2.0, 0)))
	for i in 3:
		var galho := CylinderMesh.new()
		galho.top_radius = 0.004
		galho.bottom_radius = 0.016
		galho.height = altura * (0.45 - 0.08 * i)
		galho.radial_segments = 4
		var g := _malha(galho, madeira, Vector3(0, altura * (0.55 + 0.13 * i), 0))
		g.rotation = Vector3(0.0, TAU * i / 3.0, 0.75 * (1 if i % 2 == 0 else -1))
		g.position += Vector3(cos(TAU * i / 3.0), 0, sin(TAU * i / 3.0)) * altura * 0.08
		n.add_child(g)
	return n


## Paredão de pedra da serra (docs/34): blocos escuros na borda do platô, deixando o centro
## livre para quem consegue subir.
static func paredao(semente: int) -> Node3D:
	var n := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in 6:
		var ang := TAU * i / 6.0 + rng.randf_range(-0.3, 0.3)
		var m := CylinderMesh.new()   # agulha de pedra: base larga, topo fino, 5 faces
		var alto := rng.randf_range(0.35, 0.75)
		m.bottom_radius = rng.randf_range(0.13, 0.19)
		m.top_radius = m.bottom_radius * rng.randf_range(0.35, 0.6)
		m.height = alto
		m.radial_segments = 5
		m.rings = 1
		var b := _malha(m, material(Color("7a7066").darkened(rng.randf() * 0.3)), Vector3(cos(ang), 0, sin(ang)) * 0.72 + Vector3(0, alto / 2.0, 0))
		b.rotation = Vector3(rng.randf_range(-0.15, 0.15), -ang + rng.randf_range(-0.4, 0.4), rng.randf_range(-0.12, 0.12))
		n.add_child(b)
	return n


## Placa de estrada torta, sem nada escrito (evento no mapa, docs/32).
static func placa_estrada() -> Node3D:
	var n := Node3D.new()
	var haste := BoxMesh.new()
	haste.size = Vector3(0.03, 0.5, 0.03)
	n.add_child(_malha(haste, material(Color("6f6a64")), Vector3(0, 0.25, 0)))
	var chapa := BoxMesh.new()
	chapa.size = Vector3(0.2, 0.2, 0.012)
	var c := _malha(chapa, material(Color("c9a43a")), Vector3(0, 0.46, 0.02))
	c.rotation.z = PI / 4.0   # losango de advertência
	n.add_child(c)
	n.rotation.z = deg_to_rad(9)
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


static func caixote(tamanho: float = 0.6, cor: Color = Color("8b6a3e")) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(tamanho, tamanho * 0.75, tamanho)
	return _malha(m, material(cor), Vector3(0, tamanho * 0.375, 0))


static func parede(altura: float = 1.4, cor: Color = Color("4a4f5c")) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(1.0, altura, 1.0)
	return _malha(m, material(cor), Vector3(0, altura / 2.0, 0))


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
## Marcos diegéticos (docs/32): a investigação ganha fita de isolamento em volta do centro e o
## evento, uma placa de estrada na borda. O símbolo flutua menor, acima da cabeça das figuras.
const COR_MARCO := {"encontro": Color("c0392b"), "evento": Color("e3c27a"), "objetivo": Color("8e1b22"),
	"investigacao": Color("7fd3c7"), "vila": Color("f2c6a0"), "inicio": Color("5dade2"), "mirante": Color("f0d27a")}

static func marco(tipo: String) -> Node3D:
	var cor: Color = COR_MARCO.get(tipo, Color.WHITE)
	var n := Node3D.new()
	n.add_child(sigilo_no_chao(hash(tipo) % 997, cor, 0.8 if tipo != "objetivo" else 1.0))
	var peca: Node3D
	match tipo:
		"encontro":
			var cult := cultista_miniatura(0.7)   # a mesma escala de miniatura do agente (0,75)
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
		"evento", "investigacao", "vila", "inicio", "mirante":
			var simbolo: String = {"evento": "?", "investigacao": "◎", "vila": "⌂", "inicio": "✦", "mirante": "▲"}[tipo]
			var l := rotulo(simbolo, 90, cor)
			l.position = Vector3(0, 0.95, 0)
			l.outline_size = 18
			var fonte := Tema.fonte_titulo()
			if fonte != null and tipo == "evento":
				l.font = fonte
			peca = Node3D.new()
			peca.add_child(l)
			match tipo:
				"investigacao":
					n.add_child(fita_isolamento(0.5))
				"evento":
					var placa := placa_estrada()
					placa.position = Vector3(0.5, 0, -0.3)
					placa.rotation.y = 0.6
					n.add_child(placa)
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


## Luz, ambiente e névoa de horror para qualquer cena 3D (ADR 0008; noite desde o docs/22):
## lua fria e alta, um brilho de brasa baixo no horizonte, céu quase preto, névoa rasteira
## (fog de altura), cores lavadas (saturação 0,62) e glow para as janelas e os marcos.
## Devolve o Environment, para a cena reagir à Membrana (`clima_membrana`).
const NOITE := {"lua": Color("b4c3ff"), "brasa": Color("c9603f"), "ambiente": Color("4a5378"),
	"nevoa": Color("161a2a"), "saturacao": 0.62, "densidade": 0.03}

static func ambiente(raiz: Node3D, cor_ceu: Color = Color("0b0d18")) -> Environment:
	var lua := DirectionalLight3D.new()
	lua.rotation_degrees = Vector3(-42, -35, 0)
	lua.light_energy = 0.75
	lua.light_color = NOITE.lua
	lua.shadow_enabled = true
	lua.shadow_blur = 2.0
	lua.directional_shadow_max_distance = 60.0
	raiz.add_child(lua)
	# Brasa: luz quente, rasante e fraca do lado oposto (cidade queimando longe; recorta as peças)
	var brasa := DirectionalLight3D.new()
	brasa.rotation_degrees = Vector3(-12, 145, 0)
	brasa.light_energy = 0.22
	brasa.light_color = NOITE.brasa
	raiz.add_child(brasa)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = cor_ceu.darkened(0.5)
	ceu.sky_horizon_color = cor_ceu.lerp(Color("3a1620"), 0.3)
	ceu.ground_horizon_color = ceu.sky_horizon_color
	ceu.ground_bottom_color = Color.BLACK
	ceu.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = ceu
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = NOITE.ambiente
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = NOITE.nevoa
	env.fog_density = NOITE.densidade
	env.fog_sky_affect = 0.6
	# Névoa rasteira: mais densa perto do chão, some acima das peças
	env.fog_height = 0.35
	env.fog_height_density = 0.9
	env.ssao_enabled = true
	env.ssao_radius = 0.6
	env.ssao_intensity = 1.8
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_saturation = NOITE.saturacao
	env.adjustment_contrast = 1.12
	env.adjustment_brightness = 0.96
	amb.environment = env
	var camera_attr := CameraAttributesPractical.new()
	camera_attr.dof_blur_far_enabled = true
	camera_attr.dof_blur_far_distance = 16.0
	camera_attr.dof_blur_far_transition = 12.0
	camera_attr.dof_blur_amount = 0.06
	amb.camera_attributes = camera_attr
	Qualidade.ambiente(amb)   # SSAO, glow, névoa rasteira e desfoque conforme a qualidade (docs/24)
	Qualidade.sombra(lua)
	raiz.add_child(amb)
	# Mesa escura sob o diorama: o vazio deixa de ser uma cor chapada
	var mesa := PlaneMesh.new()
	mesa.size = Vector2(400, 400)
	var chao := _malha(mesa, material(cor_ceu.lerp(Color("0d0c12"), 0.5)), Vector3(0, -0.5, 0))
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	raiz.add_child(chao)
	return env


## A Membrana pesa no clima (docs/22): a névoa engrossa e puxa para o vermelho-sangue, e as
## cores se lavam ainda mais. Quase nada acima de 75; a partir daí, cresce até 25.
static func clima_membrana(env: Environment, valor: int) -> void:
	if env == null:
		return
	var t := intensidade_membrana(valor)
	env.fog_light_color = (NOITE.nevoa as Color).lerp(Color("3a0c16"), t * 0.75)
	env.fog_density = float(NOITE.densidade) + 0.03 * t
	env.adjustment_saturation = float(NOITE.saturacao) - 0.2 * t
	env.ambient_light_color = (NOITE.ambiente as Color).lerp(Color("5a2a3a"), t * 0.5)


## 0 com a Membrana em 75 ou mais (um leve 0..0,15 de 100 a 75), 1 em 25 ou menos.
static func intensidade_membrana(valor: int) -> float:
	if valor >= 75:
		return clampf((100.0 - valor) / 25.0, 0.0, 1.0) * 0.15
	return clampf(0.15 + (75.0 - valor) / 50.0 * 0.85, 0.15, 1.0)
