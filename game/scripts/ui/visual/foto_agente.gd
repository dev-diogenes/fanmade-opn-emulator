class_name FotoAgente
extends Control
## Foto 3x4 do agente (docs/19): a miniatura com a aparência escolhida, fotografada num
## estúdio pequeno (SubViewport próprio), revelada em sépia e presa com um clipe numa moldura
## de papel branco, com o nome datilografado embaixo. Usada no dossiê de criação e na ficha.
##   var f := FotoAgente.new(); f.mostrar("ocultista", "", 2); f.legenda = "Helena"

const TAMANHO := Vector2(150, 196)
const QUADRO := Rect2(10, 12, 130, 150)   ## onde fica a imagem dentro da moldura

var legenda := "":
	set(v):
		legenda = v
		if _nome != null:
			_nome.text = v if v != "" else "sem nome"
var chave := ""          ## modelo|tom da figura na foto (troca só quando muda)
var figura: Node3D

var _vp: SubViewport
var _palco: Node3D
var _nome: Label


func _init() -> void:
	custom_minimum_size = TAMANHO
	rotation_degrees = 2.0
	pivot_offset = TAMANHO / 2.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vista := SubViewportContainer.new()
	vista.position = QUADRO.position
	vista.size = QUADRO.size
	vista.stretch = true
	vista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caminho := "res://assets/shaders/foto.gdshader"
	if ResourceLoader.exists(caminho):
		var m := ShaderMaterial.new()
		m.shader = load(caminho)
		vista.material = m
	add_child(vista)
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.size = Vector2i(QUADRO.size)
	vista.add_child(_vp)
	_palco = Node3D.new()
	_vp.add_child(_palco)
	var amb := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("6a645c")   # parede clara de estúdio de foto de documento
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.72, 0.68)
	env.ambient_light_energy = 0.6
	amb.environment = env
	_palco.add_child(amb)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-30, 35, 0)
	luz.light_energy = 1.2
	_palco.add_child(luz)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var olho := Vector3(0, 0.6, 1.45)
	cam.transform = Transform3D(Basis.looking_at(Vector3(0, 0.52, 0) - olho, Vector3.UP), olho)   # fora da árvore ainda
	_palco.add_child(cam)
	_nome = Label.new()
	_nome.position = Vector2(8, QUADRO.end.y + 4)
	_nome.size = Vector2(TAMANHO.x - 16, 24)
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.clip_text = true
	_nome.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_nome.add_theme_color_override("font_color", Tema.TINTA)
	_nome.add_theme_font_size_override("font_size", 14)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_nome.add_theme_font_override("font", maquina)
	_nome.text = "sem nome"
	add_child(_nome)


## Fotografa a figura com esta aparência. Não refaz se nada mudou.
func mostrar(classe_id: String, aparencia: String = "", tom: int = 0, semente: int = 0) -> void:
	var nova := "%s|%d|%d" % [Pecas.modelo_do_agente(classe_id, aparencia), tom, semente]
	if nova == chave:
		return
	chave = nova
	if figura != null:
		figura.queue_free()
	figura = Pecas.agente(classe_id, Color("3a3530"), 1.0, aparencia, tom, semente)   # semente: o tom de pele (docs/55)
	if figura.get_child_count() > 1 and figura.get_child(0) is MeshInstance3D:
		figura.get_child(0).visible = false   # sem a base de peça: é um retrato, não o tabuleiro
	figura.rotation.y = 0.35
	_palco.add_child(figura)
	# Uma foto não se mexe: congela a pose parada
	if figura.has_meta("anim"):
		var anim: AnimationPlayer = figura.get_meta("anim")
		anim.seek(0.5, true)
		anim.pause()


func _draw() -> void:
	# Sombra, moldura de papel fotográfico e o clipe no alto
	draw_rect(Rect2(Vector2(4, 5), TAMANHO), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(Vector2.ZERO, TAMANHO), Color("efe8da"))
	draw_rect(QUADRO.grow(1), Color("2a2622"), false, 1.0)
	var clipe := Color("9a9a9e")
	var x := TAMANHO.x * 0.62
	draw_line(Vector2(x, -10), Vector2(x, 22), clipe, 2.0, true)
	draw_line(Vector2(x + 9, -10), Vector2(x + 9, 30), clipe, 2.0, true)
	draw_arc(Vector2(x + 4.5, -10), 4.5, PI, TAU, 10, clipe, 2.0, true)
	draw_arc(Vector2(x + 4.5, 22), 4.5, 0, PI, 10, clipe, 2.0, true)
