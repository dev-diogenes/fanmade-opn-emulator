class_name Mapa3D
extends Node3D
## Mapa-múndi em 3D low poly: tiles hexagonais com altura e decoração por terreno,
## névoa nos hexes não revelados, marcadores de conteúdo e as figuras dos agentes.
## Só apresenta: quem decide o que acontece é a Missao.

const RAIO := 1.0
const ALTURAS := {"agua": 0.08, "pantano": 0.12, "campo": 0.2, "estrada": 0.2, "cidade": 0.22,
	"ruina": 0.22, "floresta": 0.24, "morro": 0.5}
const COR_NEVOA := Color("1c1b24")
const COR_DESTAQUE := Color(0.35, 0.65, 1.0, 0.45)
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


func construir(p_mapa: MapaHex, terrenos: Dictionary) -> void:
	mapa = p_mapa
	_terrenos = terrenos
	Pecas.ambiente(self)
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
			if t in ["cidade", "ruina"]:   # casas e pilares continuam por código
				_decorar(terreno, h, t, altura)
		else:
			terreno.add_child(Pecas.tile_hex(RAIO, altura, cor))
			_decorar(terreno, h, t, altura)
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
	var pontos := func(qtd: int) -> Array:
		var lista: Array = []
		for i in qtd:
			var ang := rng.randf() * TAU
			var r := rng.randf_range(0.15, 0.6)
			lista.append(Vector3(cos(ang) * r, altura, sin(ang) * r))
		return lista
	match terreno:
		"floresta":
			for p in pontos.call(4):
				var a := Pecas.arvore(rng.randf_range(0.5, 0.8))
				a.position = p
				raiz.add_child(a)
		"campo":
			if rng.randf() < 0.35:
				var a := Pecas.arvore(rng.randf_range(0.35, 0.5), Color("3f6b33"))
				a.position = pontos.call(1)[0]
				raiz.add_child(a)
		"morro":
			for p in pontos.call(2):
				var r := Pecas.rocha(rng.randf_range(0.12, 0.22))
				r.position = p
				raiz.add_child(r)
		"cidade":
			for p in pontos.call(3):
				var c := Pecas.casa_br(hash(p) + hash(h))
				c.position = p
				c.rotation.y = rng.randf() * TAU
				raiz.add_child(c)
		"ruina":
			for p in pontos.call(3):
				var c := Pecas.pilar_quebrado(rng.randf_range(0.15, 0.45))
				c.position = p
				raiz.add_child(c)
		"pantano":
			for p in pontos.call(2):
				var c := Pecas.capim(Color("3c5a3f"))
				c.position = p
				raiz.add_child(c)


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
		_atualizar_marcador(h, mapa.conteudo(h).get("tipo", "") if revelado else "")
	for filho in _destaques.get_children():
		filho.queue_free()
	for h in destinos:
		var d := Pecas.prisma_hex(RAIO * 0.9, 0.04, COR_DESTAQUE)
		d.material_override = Pecas.material(COR_DESTAQUE, true)
		d.position = posicao_hex(h) + Vector3(0, 0.01, 0)
		_destaques.add_child(d)
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
	var m := Pecas.marco(tipo)
	m.set_meta("tipo", tipo)
	m.position = posicao_hex(h)
	add_child(m)
	_marcadores[h] = m
	# Marcos vivos (docs/08, R6): a peça flutua um pouco e o marco ilumina o hex
	var peca: Node3D = m.get_meta("peca")
	var luz := OmniLight3D.new()
	luz.light_color = m.get_meta("cor")
	luz.light_energy = 1.4 if tipo == "objetivo" else 0.8
	luz.omni_range = 1.8 if tipo in ["objetivo", "vila"] else 1.2
	luz.position = Vector3(0, 0.6, 0)
	m.add_child(luz)
	if tipo == "encontro":
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
			ficha = Pecas.agente(a.classe_id, CORES_AGENTES[i % CORES_AGENTES.size()], 0.75)
			var rot := Pecas.rotulo(a.nome, 36)
			rot.position = Vector3(0, 1.0, 0)
			ficha.add_child(rot)
			add_child(ficha)
			_fichas[a] = ficha
		ficha.visible = not fora
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
			_ultima_posicao[a] = destino
		if a.esta_fora_de_combate():
			ficha.scale = Vector3(1, 0.5, 1)
	var vez := missao.agente_atual()
	_anel_vez.visible = vez != null
	if vez != null:
		_anel_vez.position = posicao_hex(missao.posicao(vez)) + Vector3(0, 0.02, 0)


## Centraliza a câmera no agente da vez.
func focar_agente(missao: Missao, imediato: bool = false) -> void:
	var a := missao.agente_atual()
	if a != null:
		rig.focar(posicao_hex(missao.posicao(a)), imediato)
		rig.seguir = _fichas.get(a)   # 1ª e 2ª pessoa acompanham o agente da vez
