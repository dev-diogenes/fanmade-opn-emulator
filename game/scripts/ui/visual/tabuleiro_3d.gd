class_name Tabuleiro3D
extends Node3D
## Tabuleiro tático em 3D low poly: chão em quadrados, paredes, caixotes (cobertura),
## terreno difícil e as figuras com nome e PV. Só apresenta: as regras ficam em Combate/Grade.

const COR_CHAO_A := Color("2b2f38")
const COR_CHAO_B := Color("262a32")
const COR_DIFICIL := Color("22352a")
## O combate acontece no hex do encontro (docs/22): chão (xadrez), terreno difícil, parede,
## cobertura e o que cerca o tabuleiro. "" = a sala da demonstração.
const CLAREAR_CHAO := 0.3
const ESTILO_TERRENO := {
	"floresta": {"chao": ["1f2a1d", "1b2519"], "dificil": "223d24", "parede": "3a3128", "cobertura": "rocha",
		"borda": ["trees_A_large", "trees_B_large", "trees_A_medium", "trees_B_medium"]},
	"campo": {"chao": ["2b2e1f", "27291c"], "dificil": "2c3d22", "parede": "5a4d3a", "cobertura": "rocha",
		"borda": ["tree_single_A", "tree_single_B", "rock_single_A", ""]},
	"estrada": {"chao": ["342d24", "2e2820"], "dificil": "2c3d22", "parede": "5a4d3a", "cobertura": "caixote",
		"borda": ["tree_single_A", "rock_single_A", "", ""]},
	"cidade": {"chao": ["2c2b30", "27262b"], "dificil": "30302a", "parede": "4f4a52", "cobertura": "caixote",
		"borda": ["casa", "casa", "casa", "poste", "carro", "carro", "orelhao", ""]},
	"ruina": {"chao": ["2e2a2c", "282426"], "dificil": "2a3326", "parede": "5a5260", "cobertura": "rocha",
		"borda": ["rock_single_C", "parede", "parede", "cruz", ""]},
	"morro": {"chao": ["2f2c28", "2a2723"], "dificil": "333a28", "parede": "5e574d", "cobertura": "rocha",
		"borda": ["hill_single_A", "rock_single_C", "mountain_A_grass_trees", ""]},
	"serra": {"chao": ["2b2826", "262321"], "dificil": "333a28", "parede": "5b544c", "cobertura": "rocha",
		"borda": ["rock_single_C", "rock_single_E", "mountain_A_grass_trees", "rock_single_C"]},
	"pantano": {"chao": ["1e2621", "1a211d"], "dificil": "1f3328", "parede": "33352d", "cobertura": "rocha",
		"borda": ["waterplant_A", "waterplant_B", "waterlily_A", "trees_B_medium"]},
	"agua": {"chao": ["1c2329", "182026"], "dificil": "1f3328", "parede": "33352d", "cobertura": "rocha",
		"borda": ["waterplant_A", "waterlily_A", "", ""]},
}
## Props por código no combate: a figura aqui tem escala 1 (no mapa, 0,75), então as peças
## crescem na mesma proporção que a miniatura (docs/32).
const ESCALA_PROPS := 1.35
const COR_MOVER := Color(0.3, 0.6, 1.0, 0.45)
const COR_AGENTE := Color("3d7bd9")
const COR_AMEACA := Color("b03a2e")
## Cor das áreas de rituais por elemento
const COR_ZONA := {"sangue": Color(0.75, 0.1, 0.15, 0.4), "morte": Color(0.35, 0.3, 0.3, 0.45),
	"energia": Color(0.6, 0.2, 0.9, 0.4), "conhecimento": Color(0.95, 0.75, 0.2, 0.4), "medo": Color(0.9, 0.9, 0.95, 0.35)}

var rig: CameraRig
var grade: Grade
var _unidades: Dictionary = {}    ## Ser -> Node3D
var _rotulos: Dictionary = {}     ## Ser -> Label3D
## Chance de acerto por alvo marcado (docs/21, C2): aparece embaixo do nome e dos PV.
var chances: Dictionary = {}
var _posicoes: Dictionary = {}    ## Ser -> Vector3
var _pv: Dictionary = {}          ## Ser -> PV na última atualização (para a animação de dano)
var _destaques: Node3D
var _anel_vez: MeshInstance3D
var _anel_sel: MeshInstance3D
var _cursor: MeshInstance3D   ## cursor do controle (co-op local)


var _env: Environment
var terreno := ""   ## terreno do hex do encontro (docs/22)


## A Membrana pesa no clima do combate (docs/22).
func clima_membrana(valor: int) -> void:
	Pecas.clima_membrana(_env, valor)


func construir(p_grade: Grade, p_terreno: String = "") -> void:
	grade = p_grade
	terreno = p_terreno
	_env = Pecas.ambiente(self, Color("0b0d18"))
	var estilo: Dictionary = ESTILO_TERRENO.get(terreno, {})
	rig = CameraRig.new()
	add_child(rig)
	for x in grade.largura:
		for y in grade.altura:
			var c := Vector2i(x, y)
			var t: String = grade.terreno.get(c, "")
			var cor := COR_DIFICIL if t == Grade.DIFICIL else (COR_CHAO_A if (x + y) % 2 == 0 else COR_CHAO_B)
			if not estilo.is_empty():
				# A paleta é a do terreno à noite; clareada para o chão ler bem sob o foco da clareira
				cor = Color(estilo.dificil) if t == Grade.DIFICIL else Color(estilo.chao[(x + y) % 2])
			cor = cor.lightened(CLAREAR_CHAO)
			var piso := BoxMesh.new()
			piso.size = Vector3(0.98, 0.1, 0.98)
			var mi := MeshInstance3D.new()
			mi.mesh = piso
			mi.material_override = Pecas.material(cor)
			mi.position = posicao(c) + Vector3(0, -0.05, 0)
			add_child(mi)
			var deco: Node3D = null
			match t:
				Grade.PAREDE: deco = Pecas.parede(1.4, Color(estilo.get("parede", "4a4f5c")).lightened(0.15))
				Grade.COBERTURA: deco = Pecas.rocha(0.36) if estilo.get("cobertura", "") == "rocha" else Pecas.caixote()
				Grade.DIFICIL: deco = Pecas.capim(Color(estilo.get("dificil", "2f5a2a")).lightened(0.25))
			if deco != null:
				deco.position = posicao(c)
				add_child(deco)
	if not estilo.is_empty():
		_cercar(estilo)
	_clareira()
	_destaques = Node3D.new()
	add_child(_destaques)
	_anel_vez = Pecas.anel(0.46, Color("f1c40f"))
	_anel_sel = Pecas.anel(0.52, Color("ecf0f1"))
	add_child(_anel_vez)
	add_child(_anel_sel)
	var centro := Vector3(grade.largura / 2.0, 0, grade.altura / 2.0)
	rig.limites = AABB(Vector3.ZERO, Vector3(grade.largura, 0, grade.altura))
	rig.distancia = 14.5
	rig.focar(centro, true)


func posicao(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5)


## Célula sob o ponteiro, ou Vector2i(-1, -1).
func celula_em(pos_tela: Vector2) -> Vector2i:
	var ponto = rig.ponto_no_chao(pos_tela, 0.0)
	if ponto == null:
		return Vector2i(-1, -1)
	var c := Vector2i(floori(ponto.x), floori(ponto.z))
	return c if grade.dentro(c) else Vector2i(-1, -1)


func mostrar_cursor(c: Vector2i, visivel: bool) -> void:
	if _cursor == null:
		_cursor = Pecas.anel(0.48, Color("f7dc6f"))
		add_child(_cursor)
	_cursor.visible = visivel and grade != null and grade.dentro(c)
	if _cursor.visible:
		_cursor.position = posicao(c) + Vector3(0, 0.03, 0)


## Célula vizinha na direção pedida na tela (o giro da câmera é arredondado a 90°).
func celula_na_direcao(c: Vector2i, dir: Vector2i) -> Vector2i:
	var g := rig.giro if rig != null else 0.0
	var quartos := posmod(roundi(g / (PI / 2.0)), 4)
	var d := dir
	for _i in quartos:
		d = Vector2i(d.y, -d.x)
	var nova := c + d
	return nova if grade.dentro(nova) else c


func atualizar(destinos: Array, alvos: Array, atual: Ser, selecionado: Ser, zonas: Array = []) -> void:
	for s in grade.seres():
		_atualizar_unidade(s)
	for filho in _destaques.get_children():
		filho.queue_free()
	for z in zonas:
		for c in z.celulas:
			var bz := BoxMesh.new()
			bz.size = Vector3(0.96, 0.02, 0.96)
			var mz := MeshInstance3D.new()
			mz.mesh = bz
			mz.material_override = Pecas.material(COR_ZONA.get(z.elemento, Color(1, 1, 1, 0.3)), true)
			mz.position = posicao(c) + Vector3(0, 0.012, 0)
			_destaques.add_child(mz)
	for c in destinos:
		var b := BoxMesh.new()
		b.size = Vector3(0.9, 0.02, 0.9)
		var mi := MeshInstance3D.new()
		mi.mesh = b
		mi.material_override = Pecas.material(COR_MOVER, true)
		mi.position = posicao(c) + Vector3(0, 0.02, 0)
		_destaques.add_child(mi)
	for s in alvos:
		var anel := Pecas.anel(0.5, Color("ff4d4d"))
		anel.position = posicao(grade.posicao(s)) + Vector3(0, 0.02, 0)
		_destaques.add_child(anel)
	_anel_vez.visible = atual != null and grade.tem(atual)
	if _anel_vez.visible:
		_anel_vez.position = posicao(grade.posicao(atual)) + Vector3(0, 0.01, 0)
	var figura_vez: Node3D = _unidades.get(atual) if atual is Agente else null
	if rig.seguir != figura_vez:
		rig.seguir = figura_vez   # 1ª e 2ª pessoa acompanham o agente da vez
	_anel_sel.visible = selecionado != null and selecionado != atual and grade.tem(selecionado)
	if _anel_sel.visible:
		_anel_sel.position = posicao(grade.posicao(selecionado)) + Vector3(0, 0.015, 0)


func _atualizar_unidade(s: Ser) -> void:
	var no: Node3D = _unidades.get(s)
	if no == null:
		if s is Agente:
			no = Pecas.do_agente(s, COR_AGENTE)
		elif s is Ameaca:
			no = Pecas.ameaca(s)
		else:
			no = Pecas.figura(COR_AMEACA)
		var rot := Pecas.rotulo("", 44)
		rot.position = Vector3(0, 1.55 if s.pv_maximo >= 25 and not s is Agente else 1.25, 0)
		no.add_child(rot)
		add_child(no)
		_unidades[s] = no
		_rotulos[s] = rot
	var destino := posicao(grade.posicao(s))
	if _posicoes.get(s) != destino:
		if _posicoes.has(s) and is_inside_tree():
			var tw := create_tween()
			tw.tween_property(no, "position", destino, 0.3).set_trans(Tween.TRANS_SINE)
		else:
			no.position = destino
		_posicoes[s] = destino
	var rot: Label3D = _rotulos[s]
	# Animações de dano e queda (quando o modelo tem)
	var pv_antes: int = _pv.get(s, s.pv)
	_pv[s] = s.pv
	if no.has_meta("anim") and is_inside_tree():
		if s.esta_fora_de_combate() or s.tem(Ser.MORTO):
			if not no.get_meta("caido", false):
				no.set_meta("caido", true)
				Pecas.animar(no, "Death_A")
			no.rotation.z = 0.0
			rot.text = "%s (morto)" % s.nome if s.tem(Ser.MORTO) else "%s — caído" % s.nome
			rot.modulate = Color("7f8c8d") if s.tem(Ser.MORTO) else Color("e67e22")
			return
		if no.get_meta("caido", false):   # levantou (cura, Inspiração Resoluta…)
			no.set_meta("caido", false)
			Pecas.animar(no, "Idle")
		if s.pv < pv_antes:
			Pecas.animar(no, "Hit_A", 0.05)
			# Tween preso à figura: se a cena for liberada antes, ele morre junto
			no.create_tween().tween_callback(_voltar_a_ficar_parado.bind(no)).set_delay(0.6)
	if s.tem(Ser.MORTO):
		no.rotation.z = PI / 2.0
		no.position.y = 0.2
		rot.text = "%s (morto)" % s.nome
		rot.modulate = Color("7f8c8d")
	elif s.esta_fora_de_combate() or s.tem(Ser.MORRENDO):
		no.rotation.z = PI / 2.5
		rot.text = "%s — caído" % s.nome
		rot.modulate = Color("e67e22")
	else:
		no.rotation.z = 0.0
		rot.text = "%s  %d/%d" % [s.nome, s.pv, s.pv_maximo]
		if chances.has(s):
			rot.text += "\nacerto " + LinhaTeste.chance(float(chances[s]))
		rot.modulate = Color("ecf0f1") if float(s.pv) / s.pv_maximo > 0.5 else Color("f5b041")


## Clareira ao luar (docs/22): um foco frio de cima ilumina o tabuleiro e deixa o entorno no
## escuro. A noite fica na moldura; a luta continua legível.
func _clareira() -> void:
	var centro := (posicao(Vector2i(0, 0)) + posicao(Vector2i(grade.largura - 1, grade.altura - 1))) / 2.0
	var foco := SpotLight3D.new()
	foco.light_color = Color("d2dcff")
	foco.light_energy = 3.0
	foco.spot_range = 22.0
	foco.spot_angle = 46.0
	foco.spot_angle_attenuation = 0.5
	foco.shadow_enabled = true
	Qualidade.sombra(foco)
	foco.position = centro + Vector3(0, 11, 1.5)
	foco.rotation = Vector3(-PI / 2.0 + 0.12, 0, 0)   # quase a pino
	add_child(foco)
	if _env != null:
		_env.ambient_light_energy = 0.75
		_env.tonemap_exposure = 1.0


## O que cerca o tabuleiro (docs/22): duas faixas de peças do terreno em volta, sorteadas
## pela posição (o mesmo encontro sempre tem a mesma moldura). Cidades ganham casas acesas.
func _cercar(estilo: Dictionary) -> void:
	var opcoes: Array = estilo.get("borda", [])
	if opcoes.is_empty():
		return
	var acesas := 0
	for x in range(-2, grade.largura + 2):
		for y in range(-2, grade.altura + 2):
			if x >= 0 and x < grade.largura and y >= 0 and y < grade.altura:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(Vector2i(x, y)) + hash(terreno)
			if rng.randf() < 0.35:
				continue
			var nome: String = opcoes[rng.randi() % opcoes.size()]
			var peca: Node3D = null
			match nome:
				"":
					continue
				"casa":
					peca = Pecas.casa_br(rng.randi())
					peca.scale = Vector3.ONE * ESCALA_PROPS
					if peca.get_meta("acesa", false):
						acesas += 1
						if acesas % 3 == 1:
							var luz := OmniLight3D.new()
							luz.light_color = Color("ffa040")
							luz.light_energy = 0.9
							luz.omni_range = 2.6
							luz.position = Vector3(0, 0.4, 0.35)   # na frente da porta
							Qualidade.luz_extra(luz)
							peca.add_child(luz)
				"poste", "carro", "orelhao", "parede", "cruz":
					# Props brasileiros (docs/32), na escala da miniatura do combate
					match nome:
						"poste": peca = Pecas.poste(rng.randf() < 0.6)
						"carro": peca = Pecas.carro(Pecas.PAREDES_BR[rng.randi() % Pecas.PAREDES_BR.size()].darkened(0.35))
						"orelhao": peca = Pecas.orelhao()
						"parede": peca = Pecas.parede_quebrada(rng.randf_range(0.4, 0.75), rng.randf_range(0.35, 0.55))
						_: peca = Pecas.cruz(0.6, rng.randf() < 0.5)
					var suporte := Node3D.new()   # a cruz caída já vem girada: a escala vai num nó acima
					suporte.add_child(peca)
					suporte.scale = Vector3.ONE * ESCALA_PROPS
					peca = suporte
				_:
					peca = Pecas.modelo(Pecas.DIR_HEX + nome + ".gltf")
					if peca == null and (nome.begins_with("rock") or nome.begins_with("hill")):
						peca = Pecas.rocha(0.3)   # sem os modelos KayKit: peças por código
					elif peca == null:
						peca = Pecas.arvore(rng.randf_range(0.8, 1.2))
					else:
						peca.scale = Vector3.ONE * rng.randf_range(0.7, 1.0)
			peca.position = posicao(Vector2i(x, y)) + Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
			peca.rotation.y = rng.randf() * TAU
			add_child(peca)
	# Chão do entorno: um pano escuro do tom do terreno, para as peças não flutuarem no vazio
	var pano := PlaneMesh.new()
	pano.size = Vector2(grade.largura + 8, grade.altura + 8)
	var chao := MeshInstance3D.new()
	chao.mesh = pano
	chao.material_override = Pecas.material(Color(estilo.chao[1]).darkened(0.35))
	chao.position = (posicao(Vector2i(0, 0)) + posicao(Vector2i(grade.largura - 1, grade.altura - 1))) / 2.0 + Vector3(0, -0.11, 0)
	add_child(chao)


## Texto que sobe e some sobre um ser: dano, "ERROU", "CRÍTICO" (docs/12).
func texto_flutuante(s: Ser, texto: String, cor: Color, grande: bool = false) -> void:
	var no: Node3D = _unidades.get(s)
	if no == null or not is_inside_tree():
		return
	var l := Pecas.rotulo(texto, 72 if grande else 54, cor)
	l.outline_size = 16
	var fonte := Tema.fonte_titulo()
	if fonte != null:
		l.font = fonte
	l.position = no.position + Vector3(randf_range(-0.2, 0.2), 1.5, 0)
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 0.9, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.6)
	tw.chain().tween_callback(l.queue_free)


## Animação de ataque em quem bate (quando o modelo tem).
func animar_ataque(s: Ser, ritual: bool = false) -> void:
	var no: Node3D = _unidades.get(s)
	if no == null or not no.has_meta("anim") or not is_inside_tree():
		return
	var anim: AnimationPlayer = no.get_meta("anim")
	for nome in (["Spellcast_Shoot", "Spellcasting"] if ritual else ["1H_Melee_Attack_Chop", "Unarmed_Melee_Attack_Punch_A", "2H_Melee_Attack_Chop"]):
		if anim.has_animation(nome):
			Pecas.animar(no, nome, 0.05)
			no.create_tween().tween_callback(_voltar_a_ficar_parado.bind(no)).set_delay(0.7)
			return


func _voltar_a_ficar_parado(no: Node3D) -> void:
	if not no.get_meta("caido", false):
		Pecas.animar(no, "Idle")
