extends GutTest
## Qualidade gráfica (docs/24): três níveis, aplicados na hora a tudo que está registrado.

var _antes := ""


func before_each():
	_antes = Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_qualidade.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))


func after_each():
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = _antes


func test_niveis_aplicam_e_voltam():
	assert_eq(Qualidade.nivel(), "alta", "alta por padrão")
	var raiz := Node3D.new()
	add_child_autofree(raiz)
	var env := Pecas.ambiente(raiz)
	var vp := SubViewport.new()
	add_child_autofree(vp)
	Qualidade.vista(vp)
	var extra := OmniLight3D.new()
	raiz.add_child(extra)
	Qualidade.luz_extra(extra)
	var lua: DirectionalLight3D = raiz.find_children("*", "DirectionalLight3D", false, false)[0]
	assert_true(env.ssao_enabled)
	assert_eq(vp.msaa_3d, Viewport.MSAA_4X)
	Preferencias.definir_qualidade("media")
	Qualidade.aplicar(get_tree())
	assert_false(env.ssao_enabled, "média tira o SSAO")
	assert_true(env.glow_enabled)
	assert_eq(vp.msaa_3d, Viewport.MSAA_2X)
	Preferencias.definir_qualidade("baixa")
	Qualidade.aplicar(get_tree())
	assert_false(env.glow_enabled)
	assert_eq(env.fog_height_density, 0.0, "sem névoa rasteira")
	assert_false(lua.shadow_enabled, "sem sombras")
	assert_false(extra.visible, "sem luzes de clima")
	assert_almost_eq(vp.scaling_3d_scale, Qualidade.ESCALA_BAIXA, 0.001)
	Preferencias.definir_qualidade("alta")
	Qualidade.aplicar(get_tree())
	assert_true(env.ssao_enabled and env.glow_enabled and lua.shadow_enabled and extra.visible, "volta tudo")
	assert_gt(env.fog_height_density, 0.0)


func test_qualidade_nao_liga_o_que_a_cena_nao_usa():
	var amb := WorldEnvironment.new()
	amb.environment = Environment.new()
	amb.environment.glow_enabled = false
	add_child_autofree(amb)
	Qualidade.ambiente(amb)
	assert_false(amb.environment.glow_enabled, "a investigação não usa glow: a alta não liga")
