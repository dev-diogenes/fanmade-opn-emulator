class_name Alucinacoes
extends Node
## Sanidade com consequência visual (docs/17, E6). Quando o agente da vez está perturbado
## (SAN abaixo da metade), a cena enlouquece com ele:
## - a imagem respira, ondula e ganha um "fantasma" (shader do véu, `loucura`);
## - os sussurros do ambiente sobem;
## - de tempos em tempos, um vulto aparece perto do grupo e some;
## - frases soltas surgem datilografadas e se apagam.
## A intensidade vai de 0 (SAN na metade) a 1 (SAN zerada). Só apresenta: as regras não mudam.
##   var al := Alucinacoes.criar(_vista, _mapa3d, func(): return missao.agente_atual(), func(): return centro_3d)

const FRASES := ["Você não devia ter aberto aquela porta.", "Eles sabem o seu nome.", "Olhe para trás.",
	"Isso não é real. É?", "Alguém está contando os seus passos.", "Volte. Volte. Volte.",
	"A Membrana está fina aqui.", "Você já esteve neste lugar.", "Não confie no reflexo.",
	"Quem está do seu lado?"]

var vista: SubViewportContainer
var raiz3d: Node3D
var obter_agente: Callable    ## -> Agente (ou null)
var obter_centro: Callable    ## -> Vector3 (onde o vulto aparece em volta)
var loucura := 0.0
var _proximo_vulto := 4.0
var _proxima_frase := 6.0
var _camada: CanvasLayer
var _frase: Label


static func criar(p_vista: SubViewportContainer, p_raiz3d: Node3D, p_agente: Callable, p_centro: Callable) -> Alucinacoes:
	var a := Alucinacoes.new()
	a.name = "Alucinacoes"
	a.vista = p_vista
	a.raiz3d = p_raiz3d
	a.obter_agente = p_agente
	a.obter_centro = p_centro
	return a


## 0 com SAN na metade ou mais; 1 com SAN zerada. Enlouquecendo ou insano: 1.
static func intensidade(ag: Agente) -> float:
	if ag == null or not ag.tem_sanidade or ag.san_maximo <= 0:
		return 0.0
	if ag.tem(Ser.ENLOUQUECENDO) or ag.tem(Ser.INSANO):
		return 1.0
	return clampf((0.5 - float(ag.san) / ag.san_maximo) / 0.5, 0.0, 1.0)


func _ready() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 60
	add_child(_camada)
	_frase = Label.new()
	_frase.anchor_left = 0.5
	_frase.anchor_right = 0.5
	_frase.anchor_top = 0.35
	_frase.anchor_bottom = 0.35
	_frase.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_frase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_frase.add_theme_color_override("font_color", Color(Tema.SANGUE_CLARO, 0.85))
	_frase.add_theme_font_size_override("font_size", Tema.FONTE_G + 4)
	_frase.add_theme_constant_override("outline_size", 8)
	_frase.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_frase.add_theme_font_override("font", maquina)
	_frase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frase.modulate.a = 0.0
	_camada.add_child(_frase)


func _process(delta: float) -> void:
	var ag: Agente = obter_agente.call() if obter_agente.is_valid() else null
	var alvo := intensidade(ag)
	loucura = move_toward(loucura, alvo, delta * 0.5)   # entra e sai devagar
	var m := vista.material as ShaderMaterial if vista != null else null
	if m != null:
		# Sem "glitch" nas preferências, sem ondulação (sensibilidade a movimento)
		m.set_shader_parameter("loucura", loucura if Preferencias.efeito("glitch") else loucura * 0.25)
	if loucura <= 0.05:
		return
	Som.ambiente(maxf(loucura, 0.4))   # os sussurros sobem com a loucura
	_proximo_vulto -= delta * (0.5 + loucura)
	_proxima_frase -= delta * (0.5 + loucura)
	if _proximo_vulto <= 0.0:
		_proximo_vulto = randf_range(5.0, 10.0)
		_vulto()
	if _proxima_frase <= 0.0:
		_proxima_frase = randf_range(7.0, 14.0)
		_sussurrar()


## Um vulto escuro aparece perto do grupo, olhando para ele, e some.
func _vulto() -> void:
	if raiz3d == null or not raiz3d.is_inside_tree():
		return
	var v := Pecas.cultista_miniatura(0.9)
	if v == null:
		v = Pecas.figura(Color(0.02, 0.02, 0.03), 0.9)
	Pecas.tingir(v, Color(0.05, 0.03, 0.06))
	if v.get_child_count() > 1 and v.get_child(0) is MeshInstance3D:
		v.get_child(0).visible = false   # sem a base de peça: o vulto está "no mundo", não no tabuleiro
	var centro: Vector3 = obter_centro.call() if obter_centro.is_valid() else Vector3.ZERO
	var ang := randf() * TAU
	v.position = centro + Vector3(cos(ang), 0, sin(ang)) * randf_range(1.4, 2.4)
	v.look_at(Vector3(centro.x, v.position.y, centro.z), Vector3.UP, true)
	raiz3d.add_child(v)
	Som.tocar("glitch")
	Tema.pulso_vhs(vista, 0.35 * loucura, 0.3)
	var tw := v.create_tween()
	tw.tween_interval(randf_range(0.5, 0.9))
	tw.tween_callback(v.queue_free)


func _sussurrar() -> void:
	_frase.text = FRASES[randi() % FRASES.size()]
	_frase.modulate.a = 1.0
	_frase.position.x += randf_range(-30, 30)
	Tema.datilografar(_frase, 0.05, 2.0)
	var tw := _frase.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(_frase, "modulate:a", 0.0, 1.2)
