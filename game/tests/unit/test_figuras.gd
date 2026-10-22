extends GutTest
## Gente de hoje (docs/55): agentes, cultistas, polícia, bichos e criaturas sem cara de fantasia.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _visiveis(n: Node3D) -> Array:
	return n.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.is_visible_in_tree() or m.visible).map(func(m): return String(m.name))


func _malha(n: Node3D, nome: String) -> MeshInstance3D:
	for m in n.find_children("*", "MeshInstance3D", true, false):
		if String(m.name) == nome:
			return m
	return null


func test_agente_sem_elmo_chapeu_nem_capa():
	if not ResourceLoader.exists(Pecas.DIR_PERSONAGENS + "Knight.glb"):
		pass_test("sem os modelos, a peça é por código")
		return
	var k := Pecas.agente("combatente", Color.WHITE, 1.0, "Knight", 0, 3)
	assert_false(_malha(k, "Knight_Helmet").visible, "elmo some")
	assert_false(_malha(k, "Knight_Cape").visible, "capa some")
	assert_true(_malha(k, "Knight_Body").material_override is ShaderMaterial, "a armadura vira roupa pelo shader")
	var b := Pecas.agente("combatente", Color.WHITE, 1.0, "Barbarian", 0, 3)
	assert_false(_malha(b, "Barbarian_Hat").visible)
	assert_false(_malha(b, "Barbarian_Round_Shield").visible, "escudo some")
	var mg := Pecas.agente("ocultista", Color.WHITE, 1.0, "Mage", 0, 3)
	assert_false(_malha(mg, "Mage_Hat").visible)
	assert_true(_malha(mg, "Mage_Cape").visible, "a capa do mago vira a aba do sobretudo")
	for n in [k, b, mg]:
		n.free()


func test_moletom_ganha_rosto_e_acessorios():
	if not ResourceLoader.exists(Pecas.DIR_PERSONAGENS + "Rogue_Hooded.glb"):
		pass_test("sem os modelos")
		return
	var r := Pecas.agente("especialista", Color.WHITE, 1.0, "Rogue_Hooded", 0, 5)
	assert_false(_malha(r, "Rogue_Capuz_Oculto").visible, "o capuz com pano no rosto fica para os cultistas")
	assert_not_null(_malha(r, "Rogue_Head"), "a cabeça trocada")
	var ossos: Array = r.find_children("*", "BoneAttachment3D", true, false).filter(func(a): return a.get_child_count() > 0 and a.get_child(0) is MeshInstance3D and not String(a.get_child(0).name).begins_with("Knife")).map(func(a): return String(a.bone_name))
	assert_true("chest" in ossos, "a mochila presa ao peito")
	assert_true("handslot.r" in ossos, "a lanterna na mão")
	r.free()


func test_o_tom_de_pele_vem_da_semente():
	if not ResourceLoader.exists(Pecas.DIR_PERSONAGENS + "Knight.glb"):
		pass_test("sem os modelos")
		return
	var a := Pecas.agente("combatente", Color.WHITE, 1.0, "Knight", 0, 0)
	var b := Pecas.agente("combatente", Color.WHITE, 1.0, "Knight", 0, 1)
	var pa: Color = (_malha(a, "Knight_Head").material_override as ShaderMaterial).get_shader_parameter("pele")
	var pb: Color = (_malha(b, "Knight_Head").material_override as ShaderMaterial).get_shader_parameter("pele")
	assert_ne(pa, pb)
	a.free()
	b.free()


func _ameaca(id: String) -> Node3D:
	var info := DadosJogo.ameaca(rs, id)
	return Pecas.ameaca(Ameaca.criar(rs, info.nome, info.ficha))


func test_quem_e_quem_nas_ameacas():
	assert_eq(Pecas.visual_de_pessoa("Cultista Iniciado"), "cultista")
	assert_eq(Pecas.visual_de_pessoa("Policial de Elite"), "policia")
	assert_eq(Pecas.visual_de_pessoa("Cão de Guarda"), "cao")
	assert_eq(Pecas.visual_de_pessoa("Enxame de Ratos"), "enxame")
	assert_eq(Pecas.visual_de_pessoa("Bandido"), "crime")
	var cao := _ameaca("cao_de_guarda")
	assert_true(cao.find_children("*", "Skeleton3D", true, false).is_empty(), "o cão é um bicho, não gente encapuzada")
	cao.free()
	if not ResourceLoader.exists(Pecas.DIR_PERSONAGENS + "Rogue_Hooded.glb"):
		return
	var cult := _ameaca("iniciado")
	var cabeca: Array = cult.find_children("*", "BoneAttachment3D", true, false).filter(func(a): return a.bone_name == "head")
	assert_false(cabeca.is_empty(), "o cultista tem o pano preto nos olhos")
	cult.free()


func test_criaturas_sem_elmo_de_chifres():
	if not ResourceLoader.exists(Pecas.DIR_ESQUELETOS + "Skeleton_Warrior.glb"):
		pass_test("sem os modelos")
		return
	var z := _ameaca("aberracao_de_carne")
	for m in z.find_children("*", "MeshInstance3D", true, false):
		if String(m.name).ends_with("Helmet"):
			assert_false(m.visible)
	z.free()
