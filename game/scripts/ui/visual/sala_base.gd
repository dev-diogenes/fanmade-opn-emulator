class_name SalaBase
extends Node3D
## A Base como lugar (docs/65): um bar velho de bairro por fora e, nos fundos, as salas da
## Ordem. O agente anda com WASD (como na investigação e na sala de Transcender); cada seção
## acende a placa quando ele chega perto, e entrar nela leva a uma opção do menu.
##   var sala := SalaBase.new(); sala.construir(agente); sala.mover(dir, delta); sala.estacao_proxima()

const LIMITE := Vector2(5.4, 4.0)       ## o agente não passa das paredes (x, z)
const PORTA := Vector3(0, 0, 3.6)       ## onde o agente entra
const RAIO_ESTACAO := 1.45              ## perto o bastante para entrar
const VELOCIDADE := 2.6

## As seções da Base, pela wiki: o bar de fachada, o escritório com o quadro de fios
## vermelhos, a central, o balcão de equipamentos, a enfermaria, o laboratório, o memorial,
## a sala de ocultismo e as celas com uma vela. `destino`: a aba do menu ou o serviço.
const ESTACOES := [
	{"id": "bar", "nome": "Bar de fachada", "pos": Vector3(3.9, 0, 2.2), "destino": "Jogadores", "luz": "ffb060",
		"texto": "Uma cerveja e uma senha: a mesa dos jogadores."},
	{"id": "escritorio", "nome": "Escritório", "pos": Vector3(-3.9, 0, 2.2), "destino": "Agentes", "luz": "ffd9a0",
		"texto": "As pastas dos agentes e o quadro de fios vermelhos."},
	{"id": "central", "nome": "Central de sinais", "pos": Vector3(0, 0, 0.3), "destino": "Missão", "luz": "9fd0ff",
		"texto": "A rede varre posts, jornais e boletins. A próxima missão sai daqui."},
	{"id": "balcao", "nome": "Balcão de equipamentos", "pos": Vector3(-4.6, 0, -0.8), "destino": "Arsenal", "luz": "ffcf8a",
		"texto": "Requisição por patente e por carga."},
	{"id": "enfermaria", "nome": "Enfermaria", "pos": Vector3(4.6, 0, -0.8), "destino": "enfermaria", "luz": "d6ffe6",
		"texto": "Quem volta, volta inteiro."},
	{"id": "laboratorio", "nome": "Laboratório", "pos": Vector3(-3.9, 0, -3.2), "destino": "laboratorio", "luz": "bfe6ff",
		"texto": "As amostras dizem se um sinal é real."},
	{"id": "memorial", "nome": "Memorial", "pos": Vector3(-1.3, 0, -3.5), "destino": "Memorial", "luz": "ff9a3c",
		"texto": "A parede de memória, com as velas."},
	{"id": "ocultismo", "nome": "Sala de ocultismo", "pos": Vector3(1.4, 0, -3.2), "destino": "ocultismo", "luz": "f2b24a",
		"texto": "Os sigilos dormem até alguém transcender."},
	{"id": "contencao", "nome": "Contenção", "pos": Vector3(3.9, 0, -3.2), "destino": "contencao", "luz": "ff9a3c",
		"texto": "Celas de A a D, escuras, só com uma vela."},
]

var rig: CameraRig
var figura: Node3D
var _moveis: Node3D
var _placas: Dictionary = {}   ## id -> Label3D
var _luzes: Dictionary = {}    ## id -> OmniLight3D
var _perto := ""


func construir(agente: Agente) -> void:
	_ambiente()
	_moveis = Node3D.new()
	_moveis.name = "Moveis"
	add_child(_moveis)
	_casa()
	for e in ESTACOES:
		_estacao(e)
	if agente != null:
		figura = Pecas.do_agente(agente, Tema.CORES_JOGADORES[0], 1.0)
		if figura.get_child_count() > 1 and figura.get_child(0) is MeshInstance3D:
			figura.get_child(0).visible = false   # sem a base de peça: é a Base, não o tabuleiro
	else:
		figura = Node3D.new()
	figura.position = PORTA
	figura.rotation.y = PI   # entra olhando para dentro
	add_child(figura)
	rig = CameraRig.new()
	add_child(rig)
	rig.distancia = 13.5
	rig.distancia_min = 8.0
	rig.distancia_max = 17.0
	rig.inclinacao = deg_to_rad(54.0)
	rig.limites = AABB(Vector3(-5.5, 0, -4.2), Vector3(11, 0, 8.4))
	rig.altura_olhos = 0.6
	rig.acompanhar_virada = false
	rig.focar(Vector3(0, 0, 1.2), true)


func _ambiente() -> void:
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("06050a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("5a463a")
	env.ambient_light_energy = 1.25
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_hdr_threshold = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_light_color = Color("0c0808")
	env.fog_density = 0.025
	amb.environment = env
	Qualidade.ambiente(amb)
	add_child(amb)
	var teto := OmniLight3D.new()   # a lâmpada de bar, amarela e fraca, no meio do salão
	teto.light_color = Color("ffcf9a")
	teto.light_energy = 1.8
	teto.omni_range = 12.0
	teto.position = Vector3(0, 3.2, 1.0)
	teto.shadow_enabled = true
	Qualidade.sombra(teto)
	add_child(teto)


func _caixa(tamanho: Vector3, pos: Vector3, cor: Color, emissao := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = tamanho
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	_moveis.add_child(mi)
	return mi


func _cilindro(raio: float, altura: float, pos: Vector3, cor: Color, emissao := 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = raio
	m.bottom_radius = raio
	m.height = altura
	m.radial_segments = 10
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	_moveis.add_child(mi)
	return mi


## O salão: piso de ladrilho de bar, três paredes (a da frente fica aberta para a câmera) e a
## divisão entre o bar da frente e os fundos da Ordem, com a passagem no meio.
func _casa() -> void:
	for x in 12:
		for z in 9:
			var cor := Color("2c2622") if (x + z) % 2 == 0 else Color("3a322b")
			_caixa(Vector3(0.98, 0.1, 0.98), Vector3(-5.5 + x, -0.05, -4.0 + z), cor)
	_caixa(Vector3(12.2, 3.2, 0.2), Vector3(0, 1.6, -4.6), Color("3b2e2a"))
	_caixa(Vector3(0.2, 3.2, 9.4), Vector3(-6.1, 1.6, 0), Color("4a3a30"))
	_caixa(Vector3(0.2, 3.2, 9.4), Vector3(6.1, 1.6, 0), Color("4a3a30"))
	# Meia parede entre o bar e os fundos, com a passagem no meio (a porta "só para funcionários")
	_caixa(Vector3(4.6, 1.1, 0.16), Vector3(-3.7, 0.55, -1.9), Color("5a4434"))
	_caixa(Vector3(4.6, 1.1, 0.16), Vector3(3.7, 0.55, -1.9), Color("5a4434"))
	# Lambri e um quadro de cerveja na parede do fundo
	_caixa(Vector3(12.0, 0.9, 0.06), Vector3(0, 0.45, -4.48), Color("5a3a24"))


## Cada seção: os móveis dela, a luz da cor do lugar e a placa que acende de perto.
func _estacao(e: Dictionary) -> void:
	var p: Vector3 = e.pos
	match String(e.id):
		"bar":
			_caixa(Vector3(2.6, 1.0, 0.7), p + Vector3(0, 0.5, 0.3), Color("6a3e22"))
			_caixa(Vector3(2.7, 0.06, 0.8), p + Vector3(0, 1.03, 0.3), Color("8a5a32"))
			_caixa(Vector3(2.6, 1.6, 0.25), p + Vector3(0, 1.4, 1.2), Color("3a2418"))
			for i in 7:   # garrafas na prateleira
				_cilindro(0.06, 0.32, p + Vector3(-1.1 + i * 0.36, 1.46, 1.06), Color(["2f6b3a", "7a3a1a", "c8b070", "3a4a7a"][i % 4]), 0.2)
			for i in 3:   # banquetas
				_cilindro(0.18, 0.06, p + Vector3(-0.8 + i * 0.8, 0.7, -0.35), Color("8a2a24"))
				_cilindro(0.04, 0.68, p + Vector3(-0.8 + i * 0.8, 0.34, -0.35), Color("6a6a6a"))
		"escritorio":
			_caixa(Vector3(1.6, 0.08, 0.8), p + Vector3(0, 0.76, 0), Color("5a3e26"))
			_caixa(Vector3(1.5, 0.72, 0.7), p + Vector3(0, 0.36, 0), Color("4a3220"))
			for i in 3:   # arquivos de aço
				_caixa(Vector3(0.5, 1.3, 0.5), p + Vector3(-1.3, 0.65, -0.6 + i * 0.55), Color("6a7074"))
			# O quadro de fios vermelhos, na parede
			_caixa(Vector3(0.06, 1.2, 1.8), Vector3(-6.0, 1.6, p.z), Color("8a6a44"))
			for i in 5:
				_caixa(Vector3(0.02, 0.18, 0.14), Vector3(-5.96, 1.3 + (i % 3) * 0.3, p.z - 0.7 + i * 0.35), Color("e9dfc8"))
			for i in 3:
				var fio := _caixa(Vector3(0.01, 0.02, 0.9), Vector3(-5.95, 1.5 + i * 0.15, p.z - 0.1), Color("c0392b"), 0.6)
				fio.rotation.x = 0.35 * (i - 1)
		"central":
			_caixa(Vector3(2.2, 0.08, 1.2), p + Vector3(0, 0.78, 0), Color("3a3a40"))
			_caixa(Vector3(2.0, 0.74, 1.0), p + Vector3(0, 0.37, 0), Color("2a2a30"))
			_caixa(Vector3(1.4, 0.01, 0.8), p + Vector3(0, 0.83, 0.05), Color("c9b98a"))   # o mapa aberto
			for i in 3:   # monitores com o brilho das telas
				var tela := _caixa(Vector3(0.55, 0.36, 0.04), p + Vector3(-0.65 + i * 0.65, 1.12, -0.42), Color("3a8fd0"), 1.6)
				tela.rotation.x = -0.15
			_caixa(Vector3(0.18, 0.06, 0.1), p + Vector3(0.85, 0.86, 0.35), Color("1a1a1a"))   # o telefone
		"balcao":
			_caixa(Vector3(0.7, 1.0, 2.0), p + Vector3(-0.4, 0.5, 0), Color("4a4038"))
			_caixa(Vector3(0.12, 1.8, 2.2), Vector3(-6.0, 1.4, p.z), Color("3a3430"))
			for i in 4:   # as armas no painel
				_caixa(Vector3(0.05, 0.08, 0.7), Vector3(-5.93, 1.0 + i * 0.32, p.z - 0.2 + (i % 2) * 0.3), Color("2a2a2a"))
		"enfermaria":
			var maca := Pecas.maca()
			maca.position = p + Vector3(0.3, 0, 0)
			maca.rotation.y = PI / 2.0
			_moveis.add_child(maca)
			_caixa(Vector3(0.04, 1.8, 1.6), p + Vector3(-0.5, 0.9, 0), Color("c9d1c4"))   # a cortina
		"laboratorio":
			_caixa(Vector3(2.0, 0.9, 0.7), p + Vector3(0, 0.45, -0.3), Color("dfe6e1"))
			for i in 6:   # tubos de ensaio
				_cilindro(0.04, 0.22, p + Vector3(-0.7 + i * 0.28, 1.01, -0.3), Color(["5dff8a", "bfe6ff", "ff6b5e"][i % 3]), 1.2)
			_caixa(Vector3(0.5, 0.4, 0.4), p + Vector3(0.7, 1.1, -0.35), Color("a7b0ad"))   # o microscópio
		"memorial":
			_caixa(Vector3(2.0, 1.4, 0.06), Vector3(p.x, 1.6, -4.45), Color("2a2220"))
			for i in 6:   # as fotos
				_caixa(Vector3(0.26, 0.32, 0.02), Vector3(p.x - 0.75 + (i % 3) * 0.75, 1.4 + (i / 3) * 0.45, -4.4), Color("efe8da"))
			_caixa(Vector3(1.6, 0.06, 0.3), Vector3(p.x, 0.9, -4.3), Color("4a3220"))
			for i in 3:
				_vela(Vector3(p.x - 0.5 + i * 0.5, 0.93, -4.25))
		"ocultismo":
			var sig := MeshInstance3D.new()
			var plano := PlaneMesh.new()
			plano.size = Vector2(1.6, 1.6)
			sig.mesh = plano
			var mat := StandardMaterial3D.new()
			mat.albedo_texture = Sigilo.imagem(1987, 128, Color.WHITE, 3.0)
			mat.albedo_color = Color("f2b24a")
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sig.material_override = mat
			sig.position = p + Vector3(0, 0.02, -0.2)
			_moveis.add_child(sig)
			for i in 4:
				var ang := TAU * i / 4.0
				_vela(p + Vector3(cos(ang) * 0.9, 0, sin(ang) * 0.9 - 0.2))
		"contencao":
			for i in 9:   # as grades das celas
				_caixa(Vector3(0.04, 2.0, 0.04), p + Vector3(-1.1 + i * 0.28, 1.0, -0.6), Color("4a4a4a"))
			_caixa(Vector3(2.4, 0.06, 0.06), p + Vector3(0, 1.9, -0.6), Color("4a4a4a"))
			_vela(p + Vector3(0.2, 0, -1.0))
	var luz := OmniLight3D.new()
	luz.light_color = Color(String(e.luz))
	luz.light_energy = 1.4 if e.id == "central" else 0.7
	luz.omni_range = 3.0
	luz.position = p + Vector3(0, 2.0, 0)
	Qualidade.luz_extra(luz)
	_moveis.add_child(luz)
	_luzes[e.id] = luz
	var placa := Label3D.new()
	placa.text = String(e.nome).to_upper()
	placa.font_size = 32
	placa.pixel_size = 0.0045
	placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placa.outline_size = 10
	placa.modulate = Color(Tema.PERGAMINHO, 0.7)
	placa.no_depth_test = true
	var maquina := Tema.fonte_titulo()
	if maquina != null:
		placa.font = maquina
	placa.position = p + Vector3(0, 2.3, 0)
	_moveis.add_child(placa)
	_placas[e.id] = placa


func _vela(pos: Vector3) -> void:
	_caixa(Vector3(0.06, 0.16, 0.06), pos + Vector3(0, 0.08, 0), Color("e8dcc0"))
	_caixa(Vector3(0.035, 0.05, 0.035), pos + Vector3(0, 0.19, 0), Color("ffb04a"), 3.0)


## Troca quem anda pela Base (o agente escolhido nas outras abas), no mesmo lugar.
func trocar_agente(agente: Agente) -> void:
	if agente == null:
		return
	var pos := figura.position if figura != null else PORTA
	var rot := figura.rotation.y if figura != null else PI
	if figura != null:
		figura.queue_free()
	figura = Pecas.do_agente(agente, Tema.CORES_JOGADORES[0], 1.0)
	if figura.get_child_count() > 1 and figura.get_child(0) is MeshInstance3D:
		figura.get_child(0).visible = false
	figura.position = pos
	figura.rotation.y = rot
	add_child(figura)


## Anda com a direção (relativa à câmera) e vira a figura; a placa da seção mais perto acende.
func mover(dir: Vector3, delta: float) -> void:
	if figura == null:
		return
	if dir.length() < 0.01:
		Pecas.animar(figura, "Idle")
	else:
		dir = dir.normalized()
		var novo := figura.position + dir * VELOCIDADE * delta
		novo.x = clampf(novo.x, -LIMITE.x, LIMITE.x)
		novo.z = clampf(novo.z, -LIMITE.y, LIMITE.y)
		figura.position = novo
		figura.rotation.y = atan2(dir.x, dir.z)
		Pecas.animar(figura, "Walking_A")
	_acender(estacao_proxima())


## A seção ao alcance do agente ({} se nenhuma).
func estacao_proxima() -> Dictionary:
	if figura == null:
		return {}
	var melhor: Dictionary = {}
	var md := RAIO_ESTACAO
	for e in ESTACOES:
		var d := Vector2(figura.position.x - e.pos.x, figura.position.z - e.pos.z).length()
		if d < md:
			md = d
			melhor = e
	return melhor


## Leva o agente até a seção (atalho de teclado 1–9 e o clique na lista).
func ir_para(id: String) -> Dictionary:
	for e in ESTACOES:
		if e.id == id:
			figura.position = e.pos + Vector3(0, 0, 1.0 if e.pos.z < 0 else -1.0)
			figura.rotation.y = 0.0 if e.pos.z < 0 else PI
			_acender(e)
			return e
	return {}


func _acender(e: Dictionary) -> void:
	var id := String(e.get("id", ""))
	if id == _perto:
		return
	_perto = id
	for k in _placas:
		(_placas[k] as Label3D).modulate = Color(Tema.OURO_CLARO, 1.0) if k == id else Color(Tema.PERGAMINHO, 0.7)
		(_luzes[k] as OmniLight3D).light_energy = (2.2 if k == id else (1.4 if k == "central" else 0.7))
