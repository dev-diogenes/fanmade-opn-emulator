extends GutTest
## Pendências visuais (docs/19): foto 3x4 e aparência do agente, cartas maiores e a 1ª
## pessoa no mapa.


func _ficha_valida(nome: String) -> Dictionary:
	return {"nome": nome, "classe": "especialista", "origem": "academico", "nex": 5,
		"atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},
		"pericias_livres": ["percepcao", "intuicao", "furtividade", "tecnologia", "medicina", "atualidades", "diplomacia", "reflexos", "vontade", "ocultismo"],
		"perito": ["investigacao", "ciencias"]}


func test_aparencia_vai_do_dossie_ao_save():
	var c := Carreira.nova()
	var ficha := _ficha_valida("Helena")
	ficha["aparencia"] = "Mage"
	ficha["tom"] = 2
	var a: Agente = c.recrutar_ficha(ficha).agente
	assert_eq(a.aparencia, "Mage")
	assert_eq(a.tom, 2)
	var volta := Agente.de_dicionario(a.ruleset, a.para_dicionario())
	assert_eq(volta.aparencia, "Mage", "o save guarda a aparência")
	assert_eq(volta.tom, 2)
	var antigo := a.para_dicionario()
	antigo.erase("aparencia")
	antigo.erase("tom")
	var sem := Agente.de_dicionario(a.ruleset, antigo)
	assert_eq(sem.aparencia, "", "saves antigos ficam com o modelo da classe")


func test_modelo_da_classe_ou_o_escolhido():
	assert_eq(Pecas.modelo_do_agente("ocultista"), "Mage")
	assert_eq(Pecas.modelo_do_agente("ocultista", "Barbarian"), "Barbarian")
	assert_eq(Pecas.modelo_do_agente("ocultista", "inexistente"), "Mage")
	var f := Pecas.agente("combatente", Color.BLUE, 1.0, "Mage", 3)
	add_child_autofree(f)
	assert_gt(f.get_child_count(), 0)


func test_foto_so_refaz_quando_muda():
	var foto := FotoAgente.new()
	add_child_autofree(foto)
	foto.mostrar("ocultista")
	var primeira := foto.figura
	assert_not_null(primeira)
	foto.mostrar("ocultista", "Mage", 0)   # o Mage já é o da classe: mesma foto
	assert_eq(foto.figura, primeira)
	foto.mostrar("ocultista", "", 1)
	assert_ne(foto.figura, primeira, "outro tom, outra foto")
	foto.legenda = "Helena"
	assert_eq(foto._nome.text, "Helena")


func test_dossie_troca_aparencia_e_tom():
	var c := Carreira.nova()
	var d := CriacaoDossie.abrir(self, c)
	assert_not_null(d._foto)
	assert_eq(d.ficha.aparencia, "", "começa com a da classe")
	d._trocar_aparencia(1)
	assert_ne(d.ficha.aparencia, "")
	var lista: Array = Pecas.APARENCIAS.keys()
	for i in lista.size():
		d._trocar_aparencia(1)
	assert_true(d.ficha.aparencia in lista, "dá a volta na lista")
	d._trocar_tom(1)
	assert_eq(d.ficha.tom, 1)
	d._trocar_tom(Pecas.TONS.size())
	assert_eq(d.ficha.tom, 1, "o tom também dá a volta")
	assert_true(d._lbl_aparencia.text.contains(Pecas.TONS[1][0]))
	d.free()


func test_cartas_com_texto_maior():
	var c := CartaAcao.criar("Mover", "Até uma célula azul", 1, 3, Tema.INFO)
	add_child_autofree(c)
	var rotulos := c.find_children("*", "Label", true, false)
	var tamanhos := rotulos.map(func(l): return l.get_theme_font_size("font_size"))
	assert_true(tamanhos.all(func(t): return t >= 14), "nada abaixo de 14 px: %s" % [tamanhos])


func test_primeira_pessoa_vira_para_o_centro_e_esconde_vizinhos():
	var antes := Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_primeira.json"
	var rig := CameraRig.new()
	add_child_autofree(rig)
	var fig := Node3D.new()
	fig.position = Vector3(5, 0, 0)
	add_child_autofree(fig)
	rig.centro_olhar = Vector3.ZERO
	rig.seguir = fig
	rig.definir_modo("primeira")
	var frente := Vector3(-sin(rig.giro), 0, -cos(rig.giro))
	assert_almost_eq(frente.x, -1.0, 0.01, "olha do agente para o centro do mapa")
	rig.definir_modo("terceira")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = antes
