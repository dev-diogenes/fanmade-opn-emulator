class_name Qualidade
extends RefCounted
## Qualidade gráfica (docs/24) para máquinas mais fracas, nas preferências. Três níveis:
##   alta  — tudo: SSAO, desfoque de maquete, glow, névoa rasteira, sombras, MSAA 4x e as
##           luzes de clima (janelas de cidade, casas em volta do combate, velas, fogueira);
##   média — sem SSAO e sem desfoque; MSAA 2x. O resto continua;
##   baixa — também sem glow, sem névoa rasteira, sem sombras, sem as luzes de clima, sem
##           MSAA e com a cena 3D renderizada a 75% (a interface continua nítida).
## As cenas registram o que pode mudar; trocar o nível aplica na hora em tudo que está aberto.
##   Qualidade.ambiente(world_env); Qualidade.vista(sub_viewport)
##   Qualidade.sombra(luz_com_sombra); Qualidade.luz_extra(luz_de_clima)

const NIVEIS := ["alta", "media", "baixa"]
const NOMES := {"alta": "alta", "media": "média", "baixa": "baixa"}
const GRUPO_AMBIENTE := "qualidade_ambiente"
const GRUPO_VISTA := "qualidade_vista"
const GRUPO_SOMBRA := "qualidade_sombra"
const GRUPO_LUZ_EXTRA := "qualidade_luz_extra"
## Escala da cena 3D no nível baixo (menos pixels a calcular; a interface não muda).
const ESCALA_BAIXA := 0.75


static func nivel() -> String:
	var n := Preferencias.qualidade()
	return n if n in NIVEIS else "alta"


static func ambiente(amb: WorldEnvironment) -> void:
	amb.add_to_group(GRUPO_AMBIENTE)
	# O que a cena ligou é o teto: a qualidade só desliga, nunca liga o que a cena não usa
	var env := amb.environment
	if env != null and not env.has_meta("fog_altura"):
		env.set_meta("fog_altura", env.fog_height_density)
		env.set_meta("ssao", env.ssao_enabled)
		env.set_meta("glow", env.glow_enabled)
	var attr := amb.camera_attributes as CameraAttributesPractical
	if attr != null and not attr.has_meta("dof"):
		attr.set_meta("dof", attr.dof_blur_far_enabled)
	_aplicar_ambiente(amb)


static func vista(vp: SubViewport) -> void:
	vp.add_to_group(GRUPO_VISTA)
	_aplicar_vista(vp)


## Luz com sombra: a sombra sai no nível baixo (a luz fica).
static func sombra(luz: Light3D) -> void:
	luz.add_to_group(GRUPO_SOMBRA)
	luz.set_meta("sombra", luz.shadow_enabled)
	_aplicar_sombra(luz)


## Luz de clima, decorativa: some no nível baixo.
static func luz_extra(luz: Light3D) -> void:
	luz.add_to_group(GRUPO_LUZ_EXTRA)
	_aplicar_luz_extra(luz)


## Reaplica o nível atual a tudo que está registrado na árvore.
static func aplicar(arvore: SceneTree) -> void:
	if arvore == null:
		return
	for n in arvore.get_nodes_in_group(GRUPO_AMBIENTE):
		_aplicar_ambiente(n)
	for n in arvore.get_nodes_in_group(GRUPO_VISTA):
		_aplicar_vista(n)
	for n in arvore.get_nodes_in_group(GRUPO_SOMBRA):
		_aplicar_sombra(n)
	for n in arvore.get_nodes_in_group(GRUPO_LUZ_EXTRA):
		_aplicar_luz_extra(n)


static func _aplicar_ambiente(amb: WorldEnvironment) -> void:
	var env := amb.environment
	var n := nivel()
	if env != null:
		env.ssao_enabled = bool(env.get_meta("ssao", true)) and n == "alta"
		env.glow_enabled = bool(env.get_meta("glow", true)) and n != "baixa"
		env.fog_height_density = float(env.get_meta("fog_altura", env.fog_height_density)) if n != "baixa" else 0.0
	var attr := amb.camera_attributes as CameraAttributesPractical
	if attr != null:
		attr.dof_blur_far_enabled = bool(attr.get_meta("dof", true)) and n == "alta"


static func _aplicar_vista(vp: SubViewport) -> void:
	match nivel():
		"alta": vp.msaa_3d = Viewport.MSAA_4X
		"media": vp.msaa_3d = Viewport.MSAA_2X
		_: vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.scaling_3d_scale = ESCALA_BAIXA if nivel() == "baixa" else 1.0


static func _aplicar_sombra(luz: Light3D) -> void:
	luz.shadow_enabled = bool(luz.get_meta("sombra", true)) and nivel() != "baixa"


static func _aplicar_luz_extra(luz: Light3D) -> void:
	luz.visible = nivel() != "baixa"
