class_name Tabuleiro3D
extends Node3D
## Tabuleiro tático em 3D low poly: chão em quadrados, paredes, caixotes (cobertura),
## terreno difícil e as figuras com nome e PV. Só apresenta: as regras ficam em Combate/Grade.

const COR_CHAO_A := Color("2b2f38")
const COR_CHAO_B := Color("262a32")
const COR_DIFICIL := Color("22352a")
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
var _posicoes: Dictionary = {}    ## Ser -> Vector3
var _pv: Dictionary = {}          ## Ser -> PV na última atualização (para a animação de dano)
var _destaques: Node3D
var _anel_vez: MeshInstance3D
var _anel_sel: MeshInstance3D
var _cursor: MeshInstance3D   ## cursor do controle (co-op local)


func construir(p_grade: Grade) -> void:
	grade = p_grade
	Pecas.ambiente(self, Color("15141c"))
	rig = CameraRig.new()
	add_child(rig)
	for x in grade.largura:
		for y in grade.altura:
			var c := Vector2i(x, y)
			var t: String = grade.terreno.get(c, "")
			var cor := COR_DIFICIL if t == Grade.DIFICIL else (COR_CHAO_A if (x + y) % 2 == 0 else COR_CHAO_B)
			var piso := BoxMesh.new()
			piso.size = Vector3(0.98, 0.1, 0.98)
			var mi := MeshInstance3D.new()
			mi.mesh = piso
			mi.material_override = Pecas.material(cor)
			mi.position = posicao(c) + Vector3(0, -0.05, 0)
			add_child(mi)
			var deco: Node3D = null
			match t:
				Grade.PAREDE: deco = Pecas.parede()
				Grade.COBERTURA: deco = Pecas.caixote()
				Grade.DIFICIL: deco = Pecas.capim()
			if deco != null:
				deco.position = posicao(c)
				add_child(deco)
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
			no = Pecas.agente(s.classe_id, COR_AGENTE)
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
		rot.modulate = Color("ecf0f1") if float(s.pv) / s.pv_maximo > 0.5 else Color("f5b041")


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
