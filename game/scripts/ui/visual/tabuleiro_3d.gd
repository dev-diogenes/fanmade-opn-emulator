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

var rig: CameraRig
var grade: Grade
var _unidades: Dictionary = {}    ## Ser -> Node3D
var _rotulos: Dictionary = {}     ## Ser -> Label3D
var _posicoes: Dictionary = {}    ## Ser -> Vector3
var _destaques: Node3D
var _anel_vez: MeshInstance3D
var _anel_sel: MeshInstance3D


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


func atualizar(destinos: Array, alvos: Array, atual: Ser, selecionado: Ser) -> void:
	for s in grade.seres():
		_atualizar_unidade(s)
	for filho in _destaques.get_children():
		filho.queue_free()
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
	_anel_sel.visible = selecionado != null and selecionado != atual and grade.tem(selecionado)
	if _anel_sel.visible:
		_anel_sel.position = posicao(grade.posicao(selecionado)) + Vector3(0, 0.015, 0)


func _atualizar_unidade(s: Ser) -> void:
	var no: Node3D = _unidades.get(s)
	if no == null:
		if s is Agente:
			no = Pecas.figura(COR_AGENTE)
		elif s.pv_maximo >= 25:
			no = Pecas.criatura(COR_AMEACA, 1.2)
		else:
			no = Pecas.figura(COR_AMEACA)
		var rot := Pecas.rotulo("", 44)
		rot.position = Vector3(0, 1.05, 0)
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
