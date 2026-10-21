class_name SalaTranscender
extends Node3D
## A sala do agente para Transcender (docs/31): um quarto fechado e escuro (paredes de um
## vermelho fundo, chão de tábuas), estante com livros, mesa com um crânio e velas, gaiola e
## ervas penduradas, e o sigilo no chão, no meio. Só apresentação; quem anda e decide é a cena.

const RAIO_SALA := 3.2             ## o agente não passa das paredes
const RAIO_SIGILO := 0.55          ## pisou aqui, começa o ritual
const PORTA := Vector3(0, 0, 2.6)  ## onde o agente entra
const COR_RITUAL := Color("f2b24a")

## A sala muda com a AFINIDADE do agente (docs/34). A afinidade se firma na primeira vez que
## ele transcende depois de escolher o elemento em NEX 50% (p.114). Cada elemento ganha a
## sala das coisas a que o livro o associa (p.110-116), descritas aqui com palavras próprias:
##   sangue: carne em ganchos, metal enferrujado, lâminas, poças e veias nas paredes;
##   morte: preto, espirais, cinzas, ossos, relógios parados e pedras;
##   conhecimento: branco e ouro, papéis, sigilos, máscaras e cordas penduradas;
##   energia: neon rosa, roxo e verde, televisores chiando e cabos pelo chão.
## Sem afinidade ainda, a sala é a da classe (docs/33). O sigilo no meio é sempre o mesmo.
const ELEMENTOS := ["sangue", "morte", "conhecimento", "energia"]
const SALA_POR_CLASSE := {"combatente": "combatente", "especialista": "especialista", "ocultista": "ocultista"}
const PAREDES := {"ocultista": [Color("4a0f16"), Color("3e0c12")], "combatente": [Color("3a1a12"), Color("30150f")],
	"especialista": [Color("2c1f30"), Color("251a29")],
	"sangue": [Color("5a0c12"), Color("4a0a0f")], "morte": [Color("16151a"), Color("121115")],
	"conhecimento": [Color("cfc6a8"), Color("b9b092")], "energia": [Color("1a1424"), Color("15101e")]}

## Luz de cada sala: [ambiente, banho nas paredes].
const LUZES := {"ocultista": [Color("6a2a32"), Color("c0303a")], "combatente": [Color("5a3a26"), Color("d07a36")],
	"especialista": [Color("3a3a52"), Color("7f95c8")],
	"sangue": [Color("701820"), Color("e0303a")], "morte": [Color("2c2b33"), Color("8a8496")],
	"conhecimento": [Color("6a5a30"), Color("f0c24a")], "energia": [Color("402060"), Color("c05cff")]}


## O tema da sala: o elemento da afinidade, ou a classe enquanto não houver afinidade.
static func tema_de(a: Agente) -> String:
	if a.afinidade in ELEMENTOS:
		return a.afinidade
	return SALA_POR_CLASSE.get(a.classe_id, "ocultista")

var tipo_sala := "ocultista"
var _moveis: Node3D
var _luz_parede: OmniLight3D
var rig: CameraRig
var figura: Node3D
var sigilo: MeshInstance3D
var _material_sigilo: StandardMaterial3D
var _luz_sigilo: OmniLight3D
var _env: Environment


func construir(agente: Agente) -> void:
	tipo_sala = tema_de(agente)
	_ambiente()
	_moveis = Node3D.new()
	_moveis.name = "Moveis"
	add_child(_moveis)
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
	_env.ambient_light_color = LUZES[tipo_sala][0]
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
	parede.light_color = LUZES[tipo_sala][1]
	parede.light_energy = 1.0
	parede.omni_range = 5.0
	parede.position = Vector3(0, 2.2, -2.6)
	add_child(parede)
	_luz_parede = parede


func _caixa(tamanho: Vector3, pos: Vector3, cor: Color, emissao := 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = tamanho
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	_moveis.add_child(mi)
	return mi


func _quarto() -> void:
	# Chão de tábuas (faixas alternadas) e três paredes; a quarta fica aberta para a câmera
	for i in 9:
		_caixa(Vector3(7.2, 0.1, 0.78), Vector3(0, -0.05, -3.2 + i * 0.8), Color("2a1a14") if i % 2 == 0 else Color("24160f"))
	var paredes: Array = PAREDES[tipo_sala]
	_caixa(Vector3(7.2, 3.2, 0.2), Vector3(0, 1.6, -3.6), paredes[0])
	_caixa(Vector3(0.2, 3.2, 7.2), Vector3(-3.6, 1.6, 0), paredes[1])
	_caixa(Vector3(0.2, 3.2, 7.2), Vector3(3.6, 1.6, 0), paredes[1])
	for i in 5:   # as velas em volta do sigilo, em toda sala
		var ang := TAU * i / 5.0
		var pos := Vector3(cos(ang), 0, sin(ang)) * 1.15
		_vela(pos, 0.18 + 0.06 * (i % 2))
	match tipo_sala:
		"combatente": _sala_combatente()
		"especialista": _sala_especialista()
		"sangue": _sala_sangue()
		"morte": _sala_morte()
		"conhecimento": _sala_conhecimento()
		"energia": _sala_energia()
		_: _sala_ocultista()


## A afinidade acabou de se firmar no ritual: a sala vira a do elemento (docs/34).
func transformar(tema: String) -> void:
	if tema == tipo_sala:
		return
	tipo_sala = tema
	for m in _moveis.get_children():
		m.queue_free()
	_quarto()
	_env.ambient_light_color = LUZES[tipo_sala][0]
	_luz_parede.light_color = LUZES[tipo_sala][1]


func _cilindro(raio_base: float, raio_topo: float, altura: float, pos: Vector3, cor: Color, emissao := 0.0) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.bottom_radius = raio_base
	m.top_radius = raio_topo
	m.height = altura
	m.radial_segments = 7
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	_moveis.add_child(mi)
	return mi


## Sangue: carne pendurada em ganchos, mesa de metal enferrujado com lâminas, poças no chão e
## veias subindo pelas paredes.
func _sala_sangue() -> void:
	var ganchos := Node3D.new()
	ganchos.name = "Ganchos"
	_moveis.add_child(ganchos)
	_caixa(Vector3(3.0, 0.06, 0.06), Vector3(-1.2, 2.9, -2.6), Color("5a3a2a"))
	for k in 4:
		var x := -2.4 + k * 0.8
		var corrente := _caixa(Vector3(0.02, 0.5, 0.02), Vector3(x, 2.62, -2.6), Color("6b4a32"))
		corrente.reparent(ganchos, false)
		var carne := _cilindro(0.16, 0.1, 0.7, Vector3(x, 2.0, -2.6), Color("7a1a20").lightened(0.05 * k))
		carne.reparent(ganchos, false)
	_caixa(Vector3(1.3, 0.06, 0.7), Vector3(2.4, 0.85, 0.6), Color("6b4030"))
	for x in [-0.55, 0.55]:
		for z in [-0.28, 0.28]:
			_caixa(Vector3(0.06, 0.85, 0.06), Vector3(2.4 + x, 0.42, 0.6 + z), Color("4a2e22"))
	for k in 3:
		var lamina := _caixa(Vector3(0.4, 0.01, 0.06), Vector3(2.2 + k * 0.2, 0.89, 0.45 + k * 0.12), Color("b0aaa0"))
		lamina.rotation.y = 0.4 * (k - 1)
	for pos in [Vector3(-1.6, 0.005, 1.2), Vector3(1.4, 0.005, -1.4), Vector3(-0.6, 0.005, -2.2)]:
		var poca := _cilindro(0.35, 0.35, 0.01, pos, Color("4a060c"))
		poca.scale = Vector3(1.0, 1.0, 0.6)
	for k in 6:   # veias nas paredes laterais
		var veia := _caixa(Vector3(0.03, 1.6, 0.03), Vector3(-3.48, 1.4, -2.0 + k * 0.7), Color("8e1b22"), 0.4)
		veia.rotation.x = 0.3 * (1 if k % 2 == 0 else -1)
	_vela(Vector3(2.75, 0.88, 0.35), 0.2)


## Morte: preto e cinza, um relógio de pêndulo parado, montes de cinza, ossos, pedras e uma
## espiral riscada no chão em volta do sigilo.
func _sala_morte() -> void:
	var relogio := Node3D.new()
	relogio.name = "Relogio"
	_moveis.add_child(relogio)
	var caixa_relogio := _caixa(Vector3(0.5, 2.0, 0.3), Vector3(-2.6, 1.0, -3.3), Color("2b241e"))
	caixa_relogio.reparent(relogio, false)
	var mostrador := _cilindro(0.18, 0.18, 0.02, Vector3(-2.6, 1.65, -3.14), Color("bdb6a6"))
	mostrador.rotation.x = PI / 2.0
	mostrador.reparent(relogio, false)
	var ponteiro := _caixa(Vector3(0.02, 0.14, 0.01), Vector3(-2.6, 1.7, -3.12), Color("111111"))
	ponteiro.reparent(relogio, false)
	for pos in [Vector3(2.4, 0, -2.4), Vector3(2.8, 0, 0.8), Vector3(-2.7, 0, 1.4)]:
		_cilindro(0.38, 0.05, 0.4, pos + Vector3(0, 0.2, 0), Color("6a6662"))   # cinza amontoada
	for k in 7:
		var osso := _cilindro(0.025, 0.02, 0.32, Vector3(1.6 + 0.12 * k, 0.04, 2.0 - 0.09 * k), Color("d9cfb6"))
		osso.rotation = Vector3(PI / 2.0, 0.6 * k, 0)
	for k in 4:
		_cilindro(0.3, 0.18, 0.5 + 0.2 * k, Vector3(-2.8 + 0.3 * k, 0.25 + 0.1 * k, -1.2 - 0.4 * k), Color("3a3836"))
	# Espiral de traços no chão, de fora para dentro
	for k in 28:
		var ang := k * 0.55
		var r := 2.6 - k * 0.055
		var traco := _caixa(Vector3(0.16, 0.006, 0.03), Vector3(cos(ang) * r, 0.004, sin(ang) * r), Color("8a8496"), 0.3)
		traco.rotation.y = -ang + PI / 2.0
	_vela(Vector3(2.4, 0.4, -2.4), 0.12)
	var luz := OmniLight3D.new()   # um luar frio e baço, só para as cinzas e o relógio aparecerem
	luz.light_color = Color("a9a3c4")
	luz.light_energy = 0.8
	luz.omni_range = 4.5
	luz.position = Vector3(-1.2, 2.6, -1.6)
	_moveis.add_child(luz)


## Conhecimento: paredes claras cobertas de papéis e sigilos dourados, máscaras penduradas,
## pilhas de pergaminhos e cordas que descem do teto.
func _sala_conhecimento() -> void:
	var mascaras := Node3D.new()
	mascaras.name = "Mascaras"
	_moveis.add_child(mascaras)
	for k in 5:
		var m := _cilindro(0.14, 0.14, 0.03, Vector3(-1.6 + k * 0.8, 1.9 + 0.12 * (k % 2), -3.47), Color("efe6cc"))
		m.rotation.x = PI / 2.0
		m.scale = Vector3(1.0, 1.0, 1.3)
		m.reparent(mascaras, false)
		for olho in [-0.05, 0.05]:
			var o := _caixa(Vector3(0.04, 0.02, 0.01), Vector3(-1.6 + k * 0.8 + olho, 1.95 + 0.12 * (k % 2), -3.44), Color("1a1408"))
			o.reparent(mascaras, false)
	for k in 18:   # papéis nas paredes laterais
		var lado := -1.0 if k % 2 == 0 else 1.0
		var folha := _caixa(Vector3(0.01, 0.3, 0.22), Vector3(3.48 * lado, 0.9 + (k % 3) * 0.55, -2.6 + (k / 2) * 0.6), Color("f4ecd2"))
		folha.rotation.x = 0.15 * ((k % 5) - 2)
	for k in 6:   # sigilos dourados no fundo
		_caixa(Vector3(0.3, 0.3, 0.01), Vector3(-2.5 + k * 1.0, 0.9, -3.48), Color("e3b341"), 1.2)
	for k in 5:   # cordas do teto
		_caixa(Vector3(0.02, 1.4, 0.02), Vector3(-2.0 + k * 1.0, 2.5, -1.6 + (k % 2) * 0.8), Color("a08a5a"))
	for k in 4:   # pergaminhos
		var rolo := _cilindro(0.06, 0.06, 0.5, Vector3(2.5, 0.06 + 0.12 * k, 1.0 + 0.05 * k), Color("e8dcc0"))
		rolo.rotation.z = PI / 2.0
	_vela(Vector3(2.5, 0.5, 1.6), 0.2)


## Energia: escuro cortado por tubos de neon rosa, roxo e verde, uma pilha de televisores
## chiando e cabos espalhados pelo chão.
func _sala_energia() -> void:
	var tvs := Node3D.new()
	tvs.name = "Televisores"
	_moveis.add_child(tvs)
	var cores := [Color("ff4fa8"), Color("a35cff"), Color("4fff9a")]
	for k in 6:
		var x := -2.6 + (k % 3) * 0.55
		var y := 0.25 + (k / 3) * 0.5
		var tv := _caixa(Vector3(0.5, 0.45, 0.45), Vector3(x, y, -2.8), Color("2a2a2e"))
		tv.reparent(tvs, false)
		var tela := _caixa(Vector3(0.38, 0.32, 0.01), Vector3(x, y, -2.57), cores[k % 3].lerp(Color.WHITE, 0.4), 2.0)
		tela.reparent(tvs, false)
	for k in 3:   # neon nas paredes
		_caixa(Vector3(0.05, 0.05, 2.4), Vector3(-3.46, 1.2 + k * 0.6, 0.6), cores[k], 3.0)
		_caixa(Vector3(0.05, 1.6, 0.05), Vector3(3.46, 1.4, -2.2 + k * 1.2), cores[(k + 1) % 3], 3.0)
	for k in 8:   # cabos
		var cabo := _caixa(Vector3(1.2, 0.025, 0.025), Vector3(-1.0 + (k % 4) * 0.7, 0.012, 1.4 - (k / 4) * 2.8 + (k % 3) * 0.2), Color("141414"))
		cabo.rotation.y = 0.5 * (k - 4)
	var luz := OmniLight3D.new()
	luz.light_color = cores[0]
	luz.light_energy = 0.9
	luz.omni_range = 2.4
	luz.position = Vector3(-2.0, 1.0, -2.2)
	Qualidade.luz_extra(luz)
	_moveis.add_child(luz)


## Porão de treino: saco de pancada, suporte de armas, mesa com munição e um alvo na parede.
func _sala_combatente() -> void:
	var corrente := _caixa(Vector3(0.03, 0.9, 0.03), Vector3(-2.3, 2.75, -2.2), Color("4a4a4a"))
	corrente.name = "Corrente"
	var saco := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.26
	cil.bottom_radius = 0.24
	cil.height = 1.1
	cil.radial_segments = 10
	saco.mesh = cil
	saco.material_override = Pecas.material(Color("5a2a1c"))
	saco.position = Vector3(-2.3, 1.75, -2.2)
	saco.name = "SacoDePancada"
	_moveis.add_child(saco)
	# Suporte de armas na parede do fundo: tábua, ganchos e três silhuetas de arma
	_caixa(Vector3(1.6, 0.9, 0.08), Vector3(1.4, 1.6, -3.45), Color("2b1d14"))
	for k in 3:
		_caixa(Vector3(0.08, 0.75, 0.06), Vector3(0.9 + k * 0.5, 1.6, -3.38), Color("23252a"))
		_caixa(Vector3(0.22, 0.08, 0.06), Vector3(0.9 + k * 0.5, 1.4, -3.36), Color("3a2a1c"))
	# Mesa com caixas de munição e uma lanterna acesa
	_caixa(Vector3(1.2, 0.08, 0.7), Vector3(2.5, 0.8, 0.6), Color("2b2b2b"))
	for x in [-0.5, 0.5]:
		for z in [-0.28, 0.28]:
			_caixa(Vector3(0.08, 0.8, 0.08), Vector3(2.5 + x, 0.4, 0.6 + z), Color("1d1d1d"))
	_caixa(Vector3(0.3, 0.18, 0.2), Vector3(2.3, 0.93, 0.6), Color("4a5236"))
	_caixa(Vector3(0.3, 0.18, 0.2), Vector3(2.65, 0.93, 0.7), Color("4a5236"))
	_vela(Vector3(2.75, 0.84, 0.35), 0.2)
	# Alvo de papel na parede esquerda
	var alvo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.4
	disco.bottom_radius = 0.4
	disco.height = 0.02
	alvo.mesh = disco
	alvo.material_override = Pecas.material(Color("d8cfb8"))
	alvo.position = Vector3(-3.48, 1.7, 0.6)
	alvo.rotation.z = PI / 2.0
	_moveis.add_child(alvo)
	var miolo := MeshInstance3D.new()
	var m2 := CylinderMesh.new()
	m2.top_radius = 0.12
	m2.bottom_radius = 0.12
	m2.height = 0.03
	miolo.mesh = m2
	miolo.material_override = Pecas.material(Color("8e1b22"))
	miolo.position = Vector3(-3.47, 1.7, 0.6)
	miolo.rotation.z = PI / 2.0
	_moveis.add_child(miolo)


## Escritório: mesa com computador (a tela acesa), arquivo de aço, caixas de processo e o
## quadro de cortiça com fios vermelhos.
func _sala_especialista() -> void:
	_caixa(Vector3(1.6, 0.08, 0.8), Vector3(-2.3, 0.8, -2.4), Color("3b2a1c"))
	for x in [-0.7, 0.7]:
		for z in [-0.32, 0.32]:
			_caixa(Vector3(0.08, 0.8, 0.08), Vector3(-2.3 + x, 0.4, -2.4 + z), Color("2b1d14"))
	_caixa(Vector3(0.5, 0.36, 0.06), Vector3(-2.3, 1.1, -2.6), Color("1a1c20"))
	var tela := _caixa(Vector3(0.44, 0.3, 0.01), Vector3(-2.3, 1.1, -2.565), Color("6fb4d8"), 1.6)
	tela.name = "TelaComputador"
	_caixa(Vector3(0.4, 0.03, 0.15), Vector3(-2.3, 0.86, -2.25), Color("2a2c30"))
	var luz_tela := OmniLight3D.new()
	luz_tela.light_color = Color("6fb4d8")
	luz_tela.light_energy = 0.7
	luz_tela.omni_range = 1.8
	luz_tela.position = Vector3(-2.3, 1.2, -2.2)
	Qualidade.luz_extra(luz_tela)
	_moveis.add_child(luz_tela)
	# Arquivo de aço e caixas de processo
	_caixa(Vector3(0.6, 1.3, 0.5), Vector3(-3.1, 0.65, -0.6), Color("5a6066"))
	for k in 3:
		_caixa(Vector3(0.62, 0.02, 0.02), Vector3(-3.1, 0.3 + k * 0.4, -0.34), Color("2a2c30"))
	for k in 3:
		_caixa(Vector3(0.45, 0.3, 0.35), Vector3(2.6 - k * 0.12, 0.15 + k * 0.3, 1.2), Color("a08a5a").darkened(0.1 * k))
	# Quadro de cortiça na parede do fundo, com fotos e fios
	_caixa(Vector3(1.8, 1.1, 0.06), Vector3(1.3, 1.7, -3.47), Color("8a5a36"))
	for i in 5:
		var px := 0.6 + (i % 3) * 0.6
		var py := 1.45 + (i / 3) * 0.5
		_caixa(Vector3(0.22, 0.26, 0.01), Vector3(px, py, -3.43), Color("e8dcc0"))
	for i in 3:
		var fio := _caixa(Vector3(0.7, 0.012, 0.005), Vector3(0.9 + i * 0.4, 1.7 + 0.1 * (i % 2), -3.42), Color("b3121c"))
		fio.rotation.z = 0.35 - 0.3 * i


## A sala da referência (ocultista): estante, atril com livro e luz roxa, mesa com crânio,
## gaiola e ervas penduradas.
func _sala_ocultista() -> void:
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
	_moveis.add_child(luz_livro)
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
	_moveis.add_child(mc)
	_vela(Vector3(2.75, 0.84, 0.45), 0.2)
	# Gaiola pendurada (direita, ao fundo) e ervas no teto
	var gaiola := Node3D.new()
	gaiola.position = Vector3(2.4, 1.7, -2.6)
	_moveis.add_child(gaiola)
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
		_moveis.add_child(erva)


func _vela(pos: Vector3, altura: float) -> void:
	_caixa(Vector3(0.07, altura, 0.07), pos + Vector3(0, altura / 2.0, 0), Color("e8dcc0"))
	_caixa(Vector3(0.04, 0.06, 0.04), pos + Vector3(0, altura + 0.04, 0), Color("ffb04a"), 3.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ff9a3c")
	luz.light_energy = 0.45
	luz.omni_range = 1.4
	luz.position = pos + Vector3(0, altura + 0.2, 0)
	Qualidade.luz_extra(luz)
	_moveis.add_child(luz)


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
