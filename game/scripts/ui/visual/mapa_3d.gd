class_name Mapa3D
extends Node3D
## Mapa-múndi em 3D low poly: tiles hexagonais com altura e decoração por terreno,
## névoa nos hexes não revelados, marcadores de conteúdo e as figuras dos agentes.
## Só apresenta: quem decide o que acontece é a Missao.

const RAIO := 1.0
const ALTURAS := {"agua": 0.08, "pantano": 0.12, "campo": 0.2, "estrada": 0.2, "cidade": 0.22,
	"ruina": 0.22, "floresta": 0.24, "morro": 0.5, "serra": 0.85}   # serra: o platô alto (docs/34)
const COR_NEVOA := Color("1c1b24")
const COR_DESTAQUE := Color(0.35, 0.65, 1.0, 0.45)
const COR_LONGE_DO_GRUPO := Color(0.95, 0.6, 0.2, 0.45)   ## destino em que o agente fica sozinho (docs/42)
const CORES_AGENTES := Tema.CORES_JOGADORES

var rig: CameraRig
var mapa: MapaHex
var _terrenos: Dictionary
var _tiles: Dictionary = {}        ## Vector2i -> {"terreno": Node3D, "nevoa": Node3D}
var _marcadores: Dictionary = {}   ## Vector2i -> Node3D (com meta "tipo")
var _fichas: Dictionary = {}       ## Agente -> Node3D
var _destaques: Node3D
var _anel_vez: MeshInstance3D
var _ultima_posicao: Dictionary = {}
var _cursor: MeshInstance3D   ## cursor do controle (co-op local)
## Modo Mestre: a tela do mestre mostra o mapa inteiro (só o desenho; o estado não muda)
var ver_tudo := false


var _env: Environment   ## noite do mapa (docs/22); a Membrana engrossa a névoa
var _rastros: Dictionary = {}   ## Vector2i -> Node3D: por onde algo passou (docs/53)
var _rumores: Node3D            ## fios das pistas até o "?" (docs/61)
var _chave_rumores := ""
var _pressagios: Dictionary = {}   ## Vector2i (da criatura) -> Node3D no hex vizinho (docs/54)
var _noite := false
var _centro_mapa := Vector3.ZERO   ## as peças nascem viradas para cá (docs/30)


## Dia e noite (docs/53): o dia é um crepúsculo; a noite escurece, esfria a luz e fecha a névoa.
func ciclo(noite: bool, imediato: bool = false) -> void:
	if _env == null or (noite == _noite and not imediato):
		return
	_noite = noite
	var alvo_amb := 0.32 if noite else 0.55
	var alvo_cor: Color = Color("2e3a66") if noite else Pecas.NOITE.ambiente
	if imediato or not is_inside_tree():
		_env.ambient_light_energy = alvo_amb
		_env.ambient_light_color = alvo_cor
		return
	var tw := create_tween().set_parallel()
	tw.tween_property(_env, "ambient_light_energy", alvo_amb, 1.6)
	tw.tween_property(_env, "ambient_light_color", alvo_cor, 1.6)


## A peça de uma ameaça que caça anda de um hex ao vizinho (docs/53), em vez de sumir e aparecer.
func mover_marcador(de: Vector2i, para: Vector2i) -> void:
	var m: Node3D = _marcadores.get(de)
	if m == null or _marcadores.has(para):
		return
	_marcadores.erase(de)
	_marcadores[para] = m
	var tw := m.create_tween()
	tw.tween_property(m, "position", posicao_hex(para), 0.9).set_trans(Tween.TRANS_SINE)


## Presságios (docs/54): cada criatura paranormal deixa o sinal do seu elemento num hex revelado
## vizinho, de onde o grupo o vê antes de dar de cara com ela. Some quando a criatura sai.
func atualizar_pressagios(missao: Missao) -> void:
	var vivos := {}
	for h in mapa.celulas:
		var c := mapa.conteudo(h)
		if String(c.get("tipo", "")) != "encontro":
			continue
		var el := missao.elemento_de(String(c.get("encontro", "")))
		if el == "":
			continue
		vivos[h] = true
		if _pressagios.has(h):
			continue
		var vizinhos: Array = Hex.vizinhos(h).filter(func(v): return mapa.tem(v) and (ver_tudo or mapa.revelado(v)) and mapa.conteudo(v).is_empty())
		if vizinhos.is_empty():
			continue
		vizinhos.sort()
		var onde: Vector2i = vizinhos[absi(hash(h)) % vizinhos.size()]
		var p := Pecas.pressagio(el)
		p.position = posicao_hex(onde) + Vector3(0.25, 0, -0.2)
		p.rotation.y = float(absi(hash(onde)) % 628) / 100.0
		add_child(p)
		_pressagios[h] = p
	for h in _pressagios.keys():
		if not vivos.has(h):
			_pressagios[h].queue_free()
			_pressagios.erase(h)


## Rastros nos hexes revelados por onde algo passou (docs/53), na cor do elemento do caso.
func atualizar_rastros(rastros: Dictionary, cor: Color) -> void:
	for h in _rastros.keys():
		if not rastros.has(h):
			_rastros[h].queue_free()
			_rastros.erase(h)
	for h in rastros:
		if _rastros.has(h) or not (ver_tudo or mapa.revelado(h)):
			continue
		var r := PropsInvestigacao.rastros()
		for f in r.get_children():
			if f is MeshInstance3D:
				f.material_override = Pecas.material(cor.darkened(0.45))
		r.position = posicao_hex(h) + Vector3(0, 0.02, 0)
		r.rotation.y = float(hash(h) % 628) / 100.0
		add_child(r)
		_rastros[h] = r


## Mapa de rumores (docs/61, IN5): um fio tracejado vermelho de cada lugar onde o grupo achou
## pista firme até um "?" que flutua sobre a região onde o covil deve estar, com um anel fino
## no chão marcando o tamanho dela. Mais pistas, região menor. Só refaz quando muda.
const COR_FIO := Color("c0392b")


func atualizar_rumores(regiao: Dictionary) -> void:
	var chave := str(regiao)
	if chave == _chave_rumores:
		return
	_chave_rumores = chave
	if _rumores != null:
		_rumores.queue_free()
		_rumores = null
	if regiao.is_empty():
		return
	_rumores = Node3D.new()
	_rumores.name = "Rumores"
	add_child(_rumores)
	var centro := posicao_hex(regiao.centro) + Vector3(0, 0.3, 0)
	var mat := Pecas.material(COR_FIO, false, 0.8)
	for o in regiao.origens:
		var de := posicao_hex(o) + Vector3(0, 0.3, 0)
		var v := centro - de
		var n := int(v.length() / 0.4)
		for i in n:
			if i % 2 == 1:
				continue   # tracejado: um traço, um vão
			var traco := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.05, 0.03, 0.34)
			traco.mesh = b
			traco.material_override = mat
			traco.position = de + v * ((float(i) + 0.5) / float(n))
			traco.basis = Basis.looking_at(Vector3(v.x, 0, v.z).normalized(), Vector3.UP)
			_rumores.add_child(traco)
	var anel := MeshInstance3D.new()
	var t := TorusMesh.new()
	var r := float(regiao.raio) * RAIO * 1.732 + RAIO * 0.8
	t.inner_radius = r - 0.07
	t.outer_radius = r
	t.rings = 48
	t.ring_segments = 3
	anel.mesh = t
	anel.material_override = Pecas.material(Color(COR_FIO, 0.7), true)
	anel.position = posicao_hex(regiao.centro) + Vector3(0, 0.25, 0)
	_rumores.add_child(anel)
	var q := Label3D.new()
	q.text = "?"
	q.font_size = 160
	q.pixel_size = 0.006
	q.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	q.modulate = Color("ff6b5e")
	q.outline_size = 24
	q.outline_modulate = Color(0, 0, 0, 0.85)
	q.no_depth_test = true
	q.position = posicao_hex(regiao.centro) + Vector3(0, 1.4, 0)
	_rumores.add_child(q)
	if q.is_inside_tree():
		var tw := q.create_tween().set_loops()   # o "?" respira devagar
		tw.tween_property(q, "position:y", q.position.y + 0.15, 1.2).set_trans(Tween.TRANS_SINE)
		tw.tween_property(q, "position:y", q.position.y, 1.2).set_trans(Tween.TRANS_SINE)


## A Membrana pesa no clima do mapa (docs/22).
func clima_membrana(valor: int) -> void:
	Pecas.clima_membrana(_env, valor)


func construir(p_mapa: MapaHex, terrenos: Dictionary) -> void:
	mapa = p_mapa
	_terrenos = terrenos
	_env = Pecas.ambiente(self)
	rig = CameraRig.new()
	add_child(rig)
	var minimo := Vector3(INF, 0, INF)
	var maximo := Vector3(-INF, 0, -INF)
	for h in mapa.celulas:
		var raiz := Node3D.new()
		var p := posicao_hex(h, 0.0)
		raiz.position = p
		minimo = minimo.min(p)
		maximo = maximo.max(p)
		add_child(raiz)
		var t: String = mapa.terreno(h)
		var cor := Color(_terrenos.get(t, {}).get("cor", "555555"))
		var terreno := Node3D.new()
		var altura: float = ALTURAS.get(t, 0.2)
		var cor_tile := cor if t != "estrada" else Color(_terrenos.get("campo", {}).get("cor", "4f6b3a"))
		var tile := Pecas.tile_terreno(t, RAIO, altura, hash(h), cor_tile.lightened(0.2 if t in ["agua", "pantano"] else 0.4))
		if tile != null:
			terreno.add_child(tile)
			if t in ["cidade", "ruina", "serra"]:   # casas, ruínas e paredão continuam por código
				_decorar(terreno, h, t, altura)
		else:
			terreno.add_child(Pecas.tile_hex(RAIO, altura, cor))
			_decorar(terreno, h, t, altura)
		_enfeitar(terreno, h, t, altura)
		raiz.add_child(terreno)
		var nevoa := Pecas.nevoa(RAIO, 0.16, COR_NEVOA)
		raiz.add_child(nevoa)
		_tiles[h] = {"terreno": terreno, "nevoa": nevoa}
	_desenhar_estradas()
	_destaques = Node3D.new()
	add_child(_destaques)
	_anel_vez = Pecas.anel(0.42, Color("f1c40f"))
	add_child(_anel_vez)
	rig.limites = AABB(minimo, maximo - minimo)
	rig.distancia = 10.0
	# 1ª e 2ª pessoa no mapa (docs/30): os olhos da miniatura (escala 0,75), olhando um pouco
	# para baixo, para ver o caminho
	rig.altura_olhos = 0.5
	rig.avanco_primeira = 0.14
	rig.olhar = -0.18
	_centro_mapa = (minimo + maximo) / 2.0
	rig.modo_mudou.connect(func(_m): _visibilidade_das_pecas())


## Estradas (docs/13): uma faixa de terra do centro até a borda de cada vizinho que também
## é estrada, cidade, vila ou início. Assim os trechos sempre se encontram.
func _desenhar_estradas() -> void:
	var ligam := ["estrada", "cidade"]
	var terra := Pecas.material(Color("8a6f4e"))
	for h in mapa.celulas:
		if mapa.terreno(h) != "estrada":
			continue
		var raiz: Node3D = _tiles[h].terreno
		var altura: float = ALTURAS.get("estrada", 0.2)
		var centro := posicao_hex(h, 0.0)
		var ligou := false
		for v in Hex.vizinhos(h):
			if not mapa.tem(v):
				continue
			var tv := mapa.terreno(v)
			var tipo := String(mapa.conteudo(v).get("tipo", ""))
			if not (tv in ligam or tipo in ["vila", "inicio"]):
				continue
			ligou = true
			var dir := posicao_hex(v, 0.0) - centro
			var faixa := BoxMesh.new()
			faixa.size = Vector3(0.3, 0.02, dir.length() / 2.0 + 0.15)
			var mi := MeshInstance3D.new()
			mi.mesh = faixa
			mi.material_override = terra
			mi.position = dir / 4.0 + Vector3(0, altura + 0.012, 0)
			mi.rotation.y = atan2(dir.x, dir.z)
			raiz.add_child(mi)
		var miolo := CylinderMesh.new()
		miolo.top_radius = 0.2 if ligou else 0.35
		miolo.bottom_radius = miolo.top_radius
		miolo.height = 0.024
		miolo.radial_segments = 10
		var mc := MeshInstance3D.new()
		mc.mesh = miolo
		mc.material_override = terra
		mc.position = Vector3(0, altura + 0.012, 0)
		raiz.add_child(mc)


## Vitrine (tela de título): mostra o mapa inteiro, sem névoa nem peças.
func revelar_tudo() -> void:
	ver_tudo = true
	for h in _tiles:
		_tiles[h].terreno.visible = true
		_tiles[h].nevoa.visible = false
	_anel_vez.visible = false


func posicao_hex(h: Vector2i, altura: float = -1.0) -> Vector3:
	var p := Hex.para_pixel(h, RAIO)
	var y := altura
	if y < 0.0:
		y = ALTURAS.get(mapa.terreno(h), 0.2) if ver_tudo or mapa.revelado(h) else 0.16
	return Vector3(p.x, y, p.y)


## Hex sob o ponteiro (posição no viewport), ou Vector2i(-999, -999).
func hex_em(pos_tela: Vector2) -> Vector2i:
	var ponto = rig.ponto_no_chao(pos_tela, 0.2)
	if ponto == null:
		return Vector2i(-999, -999)
	var h := Hex.de_pixel(Vector2(ponto.x, ponto.z), RAIO)
	return h if mapa.tem(h) else Vector2i(-999, -999)


func _decorar(raiz: Node3D, h: Vector2i, terreno: String, altura: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(h)
	# O centro do hex fica livre para as figuras (docs/13): tudo vai para o anel de fora
	var pontos := func(qtd: int) -> Array:
		var lista: Array = []
		for i in qtd:
			var ang := rng.randf() * TAU
			var r := rng.randf_range(0.45, 0.7)
			lista.append(Vector3(cos(ang) * r, altura, sin(ang) * r))
		return lista
	match terreno:
		"floresta":
			for p in pontos.call(4):
				var a := Pecas.arvore(rng.randf_range(0.9, 1.3))
				a.position = p
				raiz.add_child(a)
		"campo":
			if rng.randf() < 0.35:
				var a := Pecas.arvore(rng.randf_range(0.8, 1.05), Color("3f6b33"))
				a.position = pontos.call(1)[0]
				raiz.add_child(a)
		"morro":
			for p in pontos.call(2):
				var r := Pecas.rocha(rng.randf_range(0.12, 0.22))
				r.position = p
				raiz.add_child(r)
		"cidade":
			# Escala da miniatura (docs/32): uma ou duas casas de alvenaria na borda, de porta
			# para o centro (a rua), um poste e, às vezes, um orelhão ou um carro largado
			var acesas := 0
			var base := PI / 3.0 * rng.randi_range(0, 5) + PI / 6.0
			var casas := 2 if rng.randf() < 0.55 else 1
			for i in casas:
				var ang := base + TAU / 3.0 * i
				var c := Pecas.casa_br(hash(h) + i * 7919)
				c.position = Vector3(cos(ang), 0, sin(ang)) * 0.58 + Vector3(0, altura, 0)
				c.rotation.y = atan2(-cos(ang), -sin(ang))   # a porta (+Z) olha para o centro
				raiz.add_child(c)
				if c.get_meta("acesa", false):
					acesas += 1
			var ang_poste := base + TAU / 3.0 * 2.0
			var poste := Pecas.poste(rng.randf() < 0.7)
			poste.position = Vector3(cos(ang_poste), 0, sin(ang_poste)) * 0.62 + Vector3(0, altura, 0)
			poste.rotation.y = -ang_poste
			raiz.add_child(poste)
			var extra := rng.randf()
			if extra < 0.3 or (casas == 1 and extra < 0.6):
				var ang_extra := base + TAU / 3.0 * (1.0 if casas == 1 else 2.5)
				var peca: Node3D = Pecas.orelhao() if extra < 0.15 else Pecas.carro(Pecas.PAREDES_BR[rng.randi() % Pecas.PAREDES_BR.size()].darkened(0.35))
				peca.position = Vector3(cos(ang_extra), 0, sin(ang_extra)) * 0.6 + Vector3(0, altura, 0)
				peca.rotation.y = -ang_extra + rng.randf_range(-0.3, 0.3)
				raiz.add_child(peca)
			if acesas > 0:   # a luz das janelas no chão da rua (docs/22)
				var luz := OmniLight3D.new()
				luz.light_color = Color("ffa040")
				luz.light_energy = 0.35 + 0.2 * acesas
				luz.omni_range = 1.3
				luz.position = Vector3(0, altura + 0.35, 0)
				Qualidade.luz_extra(luz)   # janelas da cidade: clima, não informação
				raiz.add_child(luz)
		"ruina":
			# Paredes de tijolo que sobraram e uma cruz de madeira (docs/32)
			for p in pontos.call(2):
				var c := Pecas.parede_quebrada(rng.randf_range(0.45, 0.8), rng.randf_range(0.35, 0.5))
				c.position = p
				c.rotation.y = -atan2(p.z, p.x) + PI / 2.0
				raiz.add_child(c)
			var cruz_pos: Vector3 = pontos.call(1)[0]
			var cruz := Node3D.new()
			cruz.add_child(Pecas.cruz(0.7, rng.randf() < 0.5))
			cruz.position = cruz_pos
			cruz.rotation.y = rng.randf() * TAU
			raiz.add_child(cruz)
		"pantano":
			for p in pontos.call(2):
				var c := Pecas.capim(Color("3c5a3f"))
				c.position = p
				raiz.add_child(c)
		"serra":
			var paredao := Pecas.paredao(hash(h))
			paredao.position = Vector3(0, altura, 0)
			raiz.add_child(paredao)


## Miudezas de cada terreno (docs/34): cercas, moitas, tocos, cupinzeiros, marcos de km,
## cruzes de beira de estrada e árvores secas, na borda do hex (o centro é das figuras).
## Na qualidade baixa, só uma peça por hex.
const ENFEITES := {
	"campo": ["cerca", "arbusto", "cupinzeiro", "toco", "pedra", "cerca"],
	"estrada": ["marco_km", "poste", "cruz", "arbusto", "placa"],
	"floresta": ["arbusto", "toco", "arbusto", "pedra"],
	"pantano": ["arvore_seca", "arbusto", "toco"],
	"morro": ["pedra", "arbusto", "cerca"],
	"cidade": ["arbusto", "cerca"],
	"ruina": ["arbusto", "pedra", "toco"],
	"agua": ["arvore_seca"],
	"serra": ["arbusto", "pedra"],
}

func _enfeitar(raiz: Node3D, h: Vector2i, terreno: String, altura: float) -> void:
	var opcoes: Array = ENFEITES.get(terreno, [])
	if opcoes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(h) * 31 + 7
	var qtd := 1 if Qualidade.nivel() == "baixa" else rng.randi_range(2, 3)
	var base := rng.randf() * TAU
	for i in qtd:
		var nome: String = opcoes[rng.randi() % opcoes.size()]
		var peca: Node3D
		match nome:
			"cerca": peca = Pecas.cerca(rng.randf_range(0.4, 0.6))
			"arbusto": peca = Pecas.arbusto(rng.randf_range(0.1, 0.16), Color("2f4f2a") if terreno != "pantano" else Color("34472f"))
			"cupinzeiro": peca = Pecas.cupinzeiro()
			"toco": peca = Pecas.toco()
			"marco_km": peca = Pecas.marco_km()
			"poste": peca = Pecas.poste(rng.randf() < 0.4)
			"cruz": peca = Pecas.cruz(0.32)
			"placa": peca = Pecas.placa_estrada()
			"arvore_seca": peca = Pecas.arvore_seca(rng.randf_range(0.6, 0.95))
			_:
				var pedra := Node3D.new()
				pedra.add_child(Pecas.rocha(rng.randf_range(0.06, 0.12)))
				peca = pedra
		var ang := base + TAU * i / qtd + rng.randf_range(-0.4, 0.4)
		var r := rng.randf_range(0.6, 0.78)
		peca.position = Vector3(cos(ang) * r, altura, sin(ang) * r)
		peca.rotation.y = -ang + PI / 2.0 + rng.randf_range(-0.3, 0.3)
		raiz.add_child(peca)


## Sincroniza a apresentação com o estado da missão.
## Cursor dos controles: um anel amarelo sobre o hex.
func mostrar_cursor(h: Vector2i, visivel: bool) -> void:
	if _cursor == null:
		_cursor = Pecas.anel(RAIO * 0.85, Color("f7dc6f"))
		add_child(_cursor)
	_cursor.visible = visivel and mapa.tem(h)
	if _cursor.visible:
		_cursor.position = posicao_hex(h) + Vector3(0, 0.06, 0)


## Vizinho de `h` na direção pedida na tela (considera o giro da câmera).
func vizinho_na_direcao(h: Vector2i, dir: Vector2i) -> Vector2i:
	var g := rig.giro if rig != null else 0.0
	var direita := Vector3(cos(g), 0, -sin(g))
	var frente := Vector3(-sin(g), 0, -cos(g))
	var desejo := (direita * dir.x - frente * dir.y).normalized()
	var melhor := h
	var melhor_dot := 0.3
	for v in Hex.vizinhos(h):
		if not mapa.tem(v):
			continue
		var delta := posicao_hex(v, 0.0) - posicao_hex(h, 0.0)
		var d := delta.normalized().dot(desejo)
		if d > melhor_dot:
			melhor_dot = d
			melhor = v
	return melhor


func atualizar(missao: Missao, destinos: Dictionary) -> void:
	for h in _tiles:
		var revelado := ver_tudo or mapa.revelado(h)
		_tiles[h].terreno.visible = revelado
		_tiles[h].nevoa.visible = not revelado
		var tipo: String = mapa.conteudo(h).get("tipo", "") if revelado else ""
		if tipo == "encontro" and mapa.conteudo(h).get("cacador", false):
			tipo = "encontro_cacador"   # o caçador da Perseguição (docs/74) tem rótulo
		_atualizar_marcador(h, tipo)
	for filho in _destaques.get_children():
		filho.queue_free()
	var a := missao.agente_atual()
	var sozinho_em := func(h: Vector2i) -> bool:
		return a != null and missao.agentes.size() > 1 and missao.aliados_perto(a, h) == 0
	for h in destinos:
		# Longe do grupo (docs/42): âmbar em vez de azul. Alcance por contorno (docs/57): a borda
		# acesa e só um véu leve por dentro, para o terreno continuar legível.
		var cor := COR_LONGE_DO_GRUPO if sozinho_em.call(h) else COR_DESTAQUE
		var borda := Pecas.contorno_hex(RAIO * 0.9, RAIO * 0.09, Color(cor, 0.95))
		borda.position = posicao_hex(h) + Vector3(0, 0.03, 0)
		_destaques.add_child(borda)
		var veu := Pecas.prisma_hex(RAIO * 0.84, 0.02, Color(cor, 0.12))
		veu.material_override = Pecas.material(Color(cor, 0.12), true)
		veu.position = posicao_hex(h) + Vector3(0, 0.01, 0)
		_destaques.add_child(veu)
	_atualizar_agentes(missao)


func _atualizar_marcador(h: Vector2i, tipo: String) -> void:
	var atual: Node3D = _marcadores.get(h)
	if atual != null and atual.get_meta("tipo") == tipo:
		return
	if atual != null:
		atual.queue_free()
		_marcadores.erase(h)
	if tipo == "":
		return
	var m := Pecas.marco("encontro" if tipo == "encontro_cacador" else tipo)
	m.set_meta("tipo", tipo)
	if tipo == "encontro_cacador":
		var rot := Pecas.rotulo("CAÇADOR", 40, Tema.PERIGO)
		rot.position = Vector3(0, 1.25, 0)
		m.add_child(rot)
	m.position = posicao_hex(h)
	add_child(m)
	_marcadores[h] = m
	# Marcos vivos (docs/08, R6): a peça flutua um pouco e o marco ilumina o hex
	var peca: Node3D = m.get_meta("peca")
	var luz := OmniLight3D.new()
	luz.light_color = m.get_meta("cor") if tipo != "vila" else Color("ffa64d")   # vila: lampião (docs/22)
	luz.light_energy = 1.4 if tipo == "objetivo" else (1.1 if tipo == "vila" else 0.8)
	luz.omni_range = 1.8 if tipo in ["objetivo", "vila"] else 1.2
	luz.position = Vector3(0, 0.6, 0)
	m.add_child(luz)
	if tipo in ["encontro", "encontro_cacador"]:
		return   # o cultista fica parado, em guarda
	var fase := float(hash(h) % 100) / 100.0
	var sobe := m.create_tween().set_loops()
	sobe.tween_property(peca, "position:y", peca.position.y + 0.1, 1.1 + fase * 0.4).set_trans(Tween.TRANS_SINE)
	sobe.tween_property(peca, "position:y", peca.position.y, 1.1 + fase * 0.4).set_trans(Tween.TRANS_SINE)
	if tipo == "objetivo":
		var gira := m.create_tween().set_loops()
		gira.tween_method(func(a: float): peca.rotation.y = a, 0.0, TAU, 8.0)


func _atualizar_agentes(missao: Missao) -> void:
	var por_hex: Dictionary = {}
	for i in missao.agentes_iniciais.size():
		var a: Agente = missao.agentes_iniciais[i]
		var ficha: Node3D = _fichas.get(a)
		var fora := not a in missao.agentes or a.tem(Ser.MORTO)
		if ficha == null:
			ficha = Pecas.do_agente(a, CORES_AGENTES[i % CORES_AGENTES.size()], 0.75)
			var rot := Pecas.rotulo(a.nome, 36)
			rot.position = Vector3(0, 1.0, 0)
			ficha.add_child(rot)
			ficha.set_meta("rotulo", rot)
			add_child(ficha)
			_fichas[a] = ficha
			ficha.set_meta("virar_para_centro", true)
		ficha.set_meta("fora", fora)
		if fora:
			continue
		var h := missao.posicao(a)
		var n: int = por_hex.get(h, 0)
		por_hex[h] = n + 1
		var deslocamento := Vector3(-0.3 + 0.3 * n, 0, 0.18 * (n % 2))
		var destino := posicao_hex(h) + deslocamento
		if _ultima_posicao.get(a) != destino:
			if _ultima_posicao.has(a) and is_inside_tree():
				var tw := create_tween()
				if Vector2(destino.x - ficha.position.x, destino.z - ficha.position.z).length() > 0.05:
					ficha.look_at(Vector3(destino.x, ficha.global_position.y, destino.z), Vector3.UP, true)
				Pecas.animar(ficha, "Walking_A")
				Som.tocar("passo")
				tw.tween_property(ficha, "position", destino, 0.35).set_trans(Tween.TRANS_SINE)
				tw.tween_callback(Pecas.animar.bind(ficha, "Idle"))
			else:
				ficha.position = destino
				if ficha.get_meta("virar_para_centro", false) and Vector2(_centro_mapa.x - destino.x, _centro_mapa.z - destino.z).length() > 0.5:
					# A peça nasce olhando para o território: a 1ª pessoa começa vendo o mapa
					ficha.look_at(Vector3(_centro_mapa.x, destino.y, _centro_mapa.z), Vector3.UP, true)
				ficha.remove_meta("virar_para_centro")
			_ultima_posicao[a] = destino
		if a.esta_fora_de_combate():
			ficha.scale = Vector3(1, 0.5, 1)
	var vez := missao.agente_atual()
	# As peças nascem depois do primeiro foco: sem isto, a 1ª e a 2ª pessoa só pegavam no turno seguinte
	if vez != null and rig.seguir != _fichas.get(vez):
		rig.seguir = _fichas.get(vez)
	_visibilidade_das_pecas()
	_anel_vez.visible = vez != null and rig.modo == "terceira"   # nos modos próximos, o anel atrapalha
	if vez != null:
		_anel_vez.position = posicao_hex(missao.posicao(vez)) + Vector3(0, 0.02, 0)


## Quem sai da missão some. Em 1ª pessoa (docs/19) somem também a peça do agente da vez (a
## câmera está nos olhos dele) e quem divide o hex com ele (ficaria colado na lente).
func _visibilidade_das_pecas() -> void:
	var eu: Node3D = rig.seguir if rig.seguir != null and is_instance_valid(rig.seguir) else null
	var perto_da_camera: bool = eu != null and rig.modo != "terceira"
	for a in _fichas:
		var f: Node3D = _fichas[a]
		# Na 1ª e na 2ª pessoa (docs/30), quem divide o hex com o agente da vez some: ficaria
		# colado na lente ou taparia a vista por cima do ombro
		var junto: bool = perto_da_camera and f != eu and _ultima_posicao.has(a) and 			Vector2(f.position.x - eu.position.x, f.position.z - eu.position.z).length() < 0.8
		f.visible = not bool(f.get_meta("fora", false)) and not junto and not (f == eu and rig.modo == "primeira")
		# Quem divide o hex com outro só mostra o nome se for o da vez (docs/21): sem pilha de nomes
		if f.has_meta("rotulo"):
			var acompanhado := false
			for b in _fichas:
				var g: Node3D = _fichas[b]
				if g != f and not bool(g.get_meta("fora", false)) and Vector2(g.position.x - f.position.x, g.position.z - f.position.z).length() < 0.8:
					acompanhado = true
					break
			# Por cima do ombro, o próprio nome tapa a vista
			(f.get_meta("rotulo") as Label3D).visible = (not acompanhado or f == rig.seguir) and not (f == eu and perto_da_camera)
	# O hex onde o agente da vez está: o marco flutuante (estrela, "?") e, na 1ª pessoa, as
	# casas e árvores dele ficam fora da vista
	for h in _marcadores:
		var m: Node3D = _marcadores[h]
		var aqui: bool = perto_da_camera and Vector2(m.position.x - eu.position.x, m.position.z - eu.position.z).length() < 0.8
		(m.get_meta("peca") as Node3D).visible = not aqui
	for h in _tiles:
		var terreno: Node3D = _tiles[h].terreno
		var aqui: bool = eu != null and rig.modo == "primeira" and Vector2(terreno.global_position.x - eu.global_position.x, terreno.global_position.z - eu.global_position.z).length() < 0.8
		for i in range(1, terreno.get_child_count()):
			terreno.get_child(i).visible = not aqui
		if terreno.get_child_count() > 0 and terreno.get_child(0).get_child_count() > 1:
			for j in range(1, terreno.get_child(0).get_child_count()):   # decoração KayKit dentro do tile
				terreno.get_child(0).get_child(j).visible = not aqui
	if _anel_vez != null:
		_anel_vez.visible = eu != null and rig.modo == "terceira"


## Centraliza a câmera no agente da vez.
func focar_agente(missao: Missao, imediato: bool = false) -> void:
	var a := missao.agente_atual()
	if a != null:
		rig.focar(posicao_hex(missao.posicao(a)), imediato)
		rig.seguir = _fichas.get(a)   # 1ª e 2ª pessoa acompanham o agente da vez
