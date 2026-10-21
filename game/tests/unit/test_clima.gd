extends GutTest
## Clima de terror no mundo 3D (docs/22): noite, Membrana no clima, casas acesas e o combate
## no terreno do encontro.


func test_ambiente_noturno():
	var raiz := Node3D.new()
	add_child_autofree(raiz)
	var env := Pecas.ambiente(raiz)
	assert_not_null(env, "devolve o Environment para a cena reagir à Membrana")
	assert_almost_eq(env.adjustment_saturation, float(Pecas.NOITE.saturacao), 0.001, "cores lavadas")
	assert_gt(env.fog_height_density, 0.0, "névoa rasteira")
	var luas := raiz.find_children("*", "DirectionalLight3D", false, false)
	assert_eq(luas.size(), 2, "lua e brasa")
	assert_lt((luas[0] as DirectionalLight3D).light_energy, 1.0, "a lua é mais fraca que o antigo sol")


func test_membrana_pesa_a_partir_de_75():
	assert_eq(Pecas.intensidade_membrana(100), 0.0)
	assert_almost_eq(Pecas.intensidade_membrana(75), 0.15, 0.001, "quase nada até 75")
	assert_almost_eq(Pecas.intensidade_membrana(25), 1.0, 0.001)
	assert_eq(Pecas.intensidade_membrana(0), 1.0)
	assert_gt(Pecas.intensidade_membrana(50), Pecas.intensidade_membrana(75))
	var raiz := Node3D.new()
	add_child_autofree(raiz)
	var env := Pecas.ambiente(raiz)
	Pecas.clima_membrana(env, 100)
	var densidade := env.fog_density
	var saturacao := env.adjustment_saturation
	Pecas.clima_membrana(env, 30)
	assert_gt(env.fog_density, densidade, "a névoa engrossa")
	assert_lt(env.adjustment_saturation, saturacao, "as cores se lavam")
	assert_gt(env.fog_light_color.r, env.fog_light_color.b, "a névoa puxa para o vermelho")


func test_casas_acesas_e_apagadas():
	var acesa := Pecas.casa(Color.WHITE, Color.RED, true)
	var apagada := Pecas.casa(Color.WHITE, Color.RED, false)
	add_child_autofree(acesa)
	add_child_autofree(apagada)
	var brilha := func(n: Node3D) -> bool:
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).material_override as StandardMaterial3D
			if m == null:
				m = (mi as MeshInstance3D).get_surface_override_material(0) as StandardMaterial3D
			if m != null and m.emission_enabled:
				return true
		return false
	assert_true(brilha.call(acesa), "janelas quentes")
	assert_false(brilha.call(apagada))
	var acesas := 0
	for i in 40:
		if Pecas.casa_br(i).get_meta("acesa", false):
			acesas += 1
	assert_between(acesas, 10, 39, "nem toda casa tem alguém acordado")


func test_combate_no_terreno_do_encontro():
	var g := Grade.new(6, 4)
	var sala := Tabuleiro3D.new()
	add_child_autofree(sala)
	sala.construir(g)
	var mata := Tabuleiro3D.new()
	add_child_autofree(mata)
	mata.construir(Grade.new(6, 4), "floresta")
	assert_eq(mata.terreno, "floresta")
	assert_gt(mata.get_child_count(), sala.get_child_count(), "a floresta cerca o tabuleiro")
	assert_eq(sala.find_children("*", "SpotLight3D", false, false).size(), 1, "clareira ao luar também na sala")
	assert_eq(mata.find_children("*", "SpotLight3D", false, false).size(), 1)
	# O chão da floresta não é o cinza da sala
	var chao_sala: Color = Color(Tabuleiro3D.COR_CHAO_A).lightened(Tabuleiro3D.CLAREAR_CHAO)
	var chao_mata: Color = Color(Tabuleiro3D.ESTILO_TERRENO.floresta.chao[0]).lightened(Tabuleiro3D.CLAREAR_CHAO)
	assert_ne(chao_sala, chao_mata)
