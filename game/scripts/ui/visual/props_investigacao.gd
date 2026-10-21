class_name PropsInvestigacao
extends RefCounted
## Peças low poly dos pontos de interesse (docs/23, C6), escolhidas pelo id e pelo nome do
## ponto: mesa com papéis, mesa com tela (computador, rádio, câmeras), pessoa, alçapão ou
## cofre, altar com velas, lápides ou inscrições, fogueira, barraca e rastros. Sem palavra
## conhecida, devolve null e a cena usa a peça antiga. Só apresentação.

const PALAVRAS := [
	["tela", ["computador", "radio", "rádio", "camera", "câmera", "painel"]],
	["pessoa", ["vizinha", "zelador", "operario", "operário", "ferido", "testemunha", "morador"]],
	["alcapao", ["porao", "porão", "jazigo", "cofre", "armario", "armário", "alçapão", "alcapao"]],
	["altar", ["altar", "oratorio", "oratório"]],
	["lapides", ["covas", "inscric", "inscriç", "parede", "tumulo", "túmulo"]],
	["fogueira", ["fogueira"]],
	["barraca", ["barraca", "tenda"]],
	["rastros", ["rastro", "pegada", "marca"]],
	["mesa", ["escrivaninha", "mesa", "livro", "registro", "diario", "diário", "relatorio", "relatório",
		"bilhete", "foto", "planta", "escala", "obito", "óbito"]],
]


static func tipo(ponto_id: String, nome: String) -> String:
	var chave := (ponto_id + " " + nome).to_lower()
	for par in PALAVRAS:
		for p in par[1]:
			if chave.contains(p):
				return String(par[0])
	return ""


static func criar(ponto_id: String, nome: String) -> Node3D:
	match tipo(ponto_id, nome):
		"mesa": return mesa(false)
		"tela": return mesa(true)
		"pessoa": return pessoa()
		"alcapao": return alcapao()
		"altar": return altar()
		"lapides": return lapides()
		"fogueira": return fogueira()
		"barraca": return barraca()
		"rastros": return rastros()
	return null


static func _caixa(pai: Node3D, tamanho: Vector3, pos: Vector3, cor: Color, emissao: float = 0.0) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = tamanho
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = Pecas.material(cor, false, emissao)
	mi.position = pos
	pai.add_child(mi)
	return mi


## Mesa de madeira com papéis espalhados; `com_tela`: um monitor velho aceso em verde.
static func mesa(com_tela: bool) -> Node3D:
	var n := Node3D.new()
	var madeira := Color("4a3626")
	_caixa(n, Vector3(1.0, 0.06, 0.6), Vector3(0, 0.55, 0), madeira)
	for x in [-0.44, 0.44]:
		for z in [-0.24, 0.24]:
			_caixa(n, Vector3(0.06, 0.55, 0.06), Vector3(x, 0.27, z), madeira.darkened(0.2))
	for i in 3:
		var folha := _caixa(n, Vector3(0.18, 0.005, 0.24), Vector3(-0.3 + i * 0.16, 0.585, -0.05 + i * 0.04), Color("d8cfb8"))
		folha.rotation.y = 0.3 * (i - 1)
	if com_tela:
		_caixa(n, Vector3(0.36, 0.3, 0.3), Vector3(0.22, 0.74, -0.05), Color("3a3833"))
		_caixa(n, Vector3(0.28, 0.2, 0.01), Vector3(0.22, 0.75, 0.105), Color("5fd38a"), 1.6)   # tela acesa
	return n


## Uma pessoa assustada: corpo e cabeça em tons apagados (as testemunhas não são peças do jogador).
static func pessoa() -> Node3D:
	var n := Node3D.new()
	var corpo := CapsuleMesh.new()
	corpo.radius = 0.18
	corpo.height = 0.8
	var mc := MeshInstance3D.new()
	mc.mesh = corpo
	mc.material_override = Pecas.material(Color("5a5560"))
	mc.position = Vector3(0, 0.4, 0)
	n.add_child(mc)
	var cabeca := SphereMesh.new()
	cabeca.radius = 0.13
	cabeca.height = 0.26
	var mh := MeshInstance3D.new()
	mh.mesh = cabeca
	mh.material_override = Pecas.material(Color("b89a80"))
	mh.position = Vector3(0, 0.92, 0)
	n.add_child(mh)
	n.rotation.z = 0.08   # encolhida
	return n


## Alçapão ou porta trancada no chão, com cadeado.
static func alcapao() -> Node3D:
	var n := Node3D.new()
	_caixa(n, Vector3(0.9, 0.05, 0.7), Vector3(0, 0.025, 0), Color("2e241c"))
	for z in [-0.15, 0.15]:
		_caixa(n, Vector3(0.92, 0.06, 0.06), Vector3(0, 0.05, z), Color("4b4b4f"))
	_caixa(n, Vector3(0.12, 0.14, 0.06), Vector3(0, 0.12, 0.36), Color("8a7a3a"), 0.4)
	return n


## Altar de pedra com duas velas acesas.
static func altar() -> Node3D:
	var n := Node3D.new()
	_caixa(n, Vector3(0.9, 0.6, 0.45), Vector3(0, 0.3, 0), Color("6a6470"))
	_caixa(n, Vector3(1.0, 0.06, 0.55), Vector3(0, 0.63, 0), Color("57515c"))
	for x in [-0.3, 0.3]:
		_caixa(n, Vector3(0.06, 0.2, 0.06), Vector3(x, 0.76, 0), Color("e8dcc0"))
		_caixa(n, Vector3(0.03, 0.05, 0.03), Vector3(x, 0.89, 0), Color("ffb04a"), 3.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffa040")
	luz.light_energy = 0.8
	luz.omni_range = 1.8
	luz.position = Vector3(0, 1.0, 0)
	Qualidade.luz_extra(luz)
	n.add_child(luz)
	return n


## Lápides tortas (ou o trecho de parede com inscrições).
static func lapides() -> Node3D:
	var n := Node3D.new()
	for i in 3:
		var l := _caixa(n, Vector3(0.28, 0.5 - i * 0.08, 0.08), Vector3(-0.35 + i * 0.35, 0.22, -0.1 + i * 0.1), Color("77727c"))
		l.rotation.z = 0.12 * (i - 1)
	return n


## Fogueira apagando: lenha em cruz, brasas e uma luz baixa.
static func fogueira() -> Node3D:
	var n := Node3D.new()
	for a in [0.0, PI / 2.0, PI / 4.0]:
		var tora := _caixa(n, Vector3(0.7, 0.08, 0.08), Vector3(0, 0.06, 0), Color("3a2a1e"))
		tora.rotation.y = a
	_caixa(n, Vector3(0.25, 0.08, 0.25), Vector3(0, 0.1, 0), Color("ff6a2a"), 3.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ff7a33")
	luz.light_energy = 1.4
	luz.omni_range = 2.6
	luz.position = Vector3(0, 0.5, 0)
	Qualidade.luz_extra(luz)
	n.add_child(luz)
	return n


## Barraca rasgada (o modelo da KayKit, ou um prisma de lona).
static func barraca() -> Node3D:
	var m := Pecas.modelo(Pecas.DIR_HEX + "tent.gltf")
	if m != null:
		m.scale = Vector3.ONE * 1.4
		return m
	var n := Node3D.new()
	var p := PrismMesh.new()
	p.size = Vector3(1.0, 0.7, 0.9)
	var mi := MeshInstance3D.new()
	mi.mesh = p
	mi.material_override = Pecas.material(Color("5a5a3c"))
	mi.position = Vector3(0, 0.35, 0)
	n.add_child(mi)
	return n


## Rastros no chão: pegadas escuras em fila.
static func rastros() -> Node3D:
	var n := Node3D.new()
	for i in 5:
		var p := _caixa(n, Vector3(0.12, 0.01, 0.22), Vector3(-0.1 + 0.2 * (i % 2), 0.01, -0.5 + i * 0.25), Color("1a1512"))
		p.rotation.y = 0.15 * (1 if i % 2 == 0 else -1)
	return n
