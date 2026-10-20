class_name Som
extends Node
## Áudio procedural (docs/11): todos os sons são sintetizados em código na primeira vez
## que tocam (sem arquivos de áudio no repositório) e ficam em cache.
##   Som.tocar("tecla")              efeito curto
##   Som.ambiente(intensidade)       drone + sussurros (0 = calmo, 1 = Membrana rompendo)
## O autoload Jogo cria a instância. Sem ela (testes de regras), as chamadas não fazem nada.

const TAXA := 22050
const VOZES := 8
## Efeito -> [volume em dB, variação de altura]
const EFEITOS := {"estatica": [-14.0, 0.0], "tecla": [-16.0, 0.12], "carimbo": [-6.0, 0.05], "papel": [-14.0, 0.15],
	"hover": [-26.0, 0.1], "clique": [-18.0, 0.08], "pista": [-10.0, 0.0], "glitch": [-14.0, 0.2]}

static var _instancia: Som
static var _cache: Dictionary = {}

var _vozes: Array[AudioStreamPlayer] = []
var _proxima := 0
var _drone: AudioStreamPlayer
var _sussurro: AudioStreamPlayer
var _intensidade := 0.0


func _ready() -> void:
	_instancia = self
	_configurar_barramentos()
	for i in VOZES:
		var p := AudioStreamPlayer.new()
		p.bus = "Efeitos"
		add_child(p)
		_vozes.append(p)
	_drone = AudioStreamPlayer.new()
	_drone.bus = "Ambiente"
	add_child(_drone)
	_sussurro = AudioStreamPlayer.new()
	_sussurro.bus = "Ambiente"
	add_child(_sussurro)
	aplicar_volume()


func _exit_tree() -> void:
	if _instancia == self:
		_instancia = null


static func _configurar_barramentos() -> void:
	for nome in ["Efeitos", "Ambiente"]:
		if AudioServer.get_bus_index(nome) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, nome)
			AudioServer.set_bus_send(i, "Master")


## Volume geral e ambiente ligado/desligado, das preferências.
static func aplicar_volume() -> void:
	var v := clampf(Preferencias.volume(), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(0, v <= 0.001)
	var amb := AudioServer.get_bus_index("Ambiente")
	if amb >= 0:
		AudioServer.set_bus_mute(amb, not Preferencias.efeito("ambiente"))


static func tocar(nome: String) -> void:
	if _instancia == null or not EFEITOS.has(nome):
		return
	_instancia._tocar(nome)


func _tocar(nome: String) -> void:
	var p := _vozes[_proxima]
	_proxima = (_proxima + 1) % VOZES
	p.stream = gerar(nome)
	p.volume_db = EFEITOS[nome][0]
	p.pitch_scale = 1.0 + randf_range(-1.0, 1.0) * EFEITOS[nome][1]
	p.play()


## 0 = calmo (só o drone baixo), 1 = Membrana rompendo (drone alto e sussurros).
static func ambiente(intensidade: float) -> void:
	if _instancia == null:
		return
	_instancia._ambiente(clampf(intensidade, 0.0, 1.0))


func _ambiente(intensidade: float) -> void:
	_intensidade = intensidade
	if _drone.stream == null:
		_drone.stream = gerar("drone")
	if not _drone.playing:
		_drone.play()
	_drone.volume_db = lerpf(-30.0, -16.0, intensidade)
	_drone.pitch_scale = lerpf(1.0, 0.85, intensidade)
	var sussurrar := intensidade > 0.35
	if sussurrar and _sussurro.stream == null:
		_sussurro.stream = gerar("sussurro")
	if sussurrar and not _sussurro.playing:
		_sussurro.play()
	elif not sussurrar and _sussurro.playing:
		_sussurro.stop()
	_sussurro.volume_db = lerpf(-34.0, -14.0, (intensidade - 0.35) / 0.65)


# --- Síntese --------------------------------------------------------------------

## AudioStreamWAV do som pedido (cache).
static func gerar(nome: String) -> AudioStreamWAV:
	if _cache.has(nome):
		return _cache[nome]
	var amostras: PackedFloat32Array
	var laco := false
	match nome:
		"estatica": amostras = _ruido(0.7, 0.55, func(t, d): return pow(1.0 - t / d, 0.6))
		"tecla": amostras = _tecla()
		"carimbo": amostras = _carimbo()
		"papel": amostras = _papel()
		"hover": amostras = _clique(0.012, 3200.0, 0.5)
		"clique": amostras = _clique(0.03, 1400.0, 0.8)
		"pista": amostras = _pista()
		"glitch": amostras = _glitch()
		"drone":
			amostras = _drone_laco()
			laco = true
		"sussurro":
			amostras = _sussurro_laco()
			laco = true
		_: amostras = PackedFloat32Array([0.0])
	var w := _para_wav(amostras, laco)
	_cache[nome] = w
	return w


static func _para_wav(amostras: PackedFloat32Array, laco: bool) -> AudioStreamWAV:
	var dados := PackedByteArray()
	dados.resize(amostras.size() * 2)
	for i in amostras.size():
		dados.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.data = dados
	if laco:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = amostras.size()
	return w


## Ruído com passa-baixa simples; `envelope(t, duracao)` dá a amplitude.
static func _ruido(duracao: float, filtro: float, envelope: Callable) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	for i in n:
		y += filtro * (randf_range(-1.0, 1.0) - y)
		a[i] = y * float(envelope.call(float(i) / TAXA, duracao))
	return a


static func _clique(duracao: float, freq: float, ganho: float) -> PackedFloat32Array:
	var n := int(duracao * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var env := exp(-t / (duracao * 0.25))
		a[i] = ganho * env * (0.6 * sin(TAU * freq * t) + 0.4 * randf_range(-1.0, 1.0))
	return a


## Tecla de máquina de escrever: estalo metálico + batida curta.
static func _tecla() -> PackedFloat32Array:
	var n := int(0.06 * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var estalo := randf_range(-1.0, 1.0) * exp(-t / 0.004)
		var metal := sin(TAU * 2350.0 * t) * exp(-t / 0.012) * 0.5
		var batida := sin(TAU * 180.0 * t) * exp(-t / 0.02) * 0.6
		a[i] = 0.42 * (estalo + metal + batida)
	return a


## Carimbo: baque grave com o "tapa" da borracha no papel.
static func _carimbo() -> PackedFloat32Array:
	var n := int(0.35 * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / TAXA
		y += 0.3 * (randf_range(-1.0, 1.0) - y)
		var baque := sin(TAU * (70.0 - 30.0 * t) * t) * exp(-t / 0.09)
		a[i] = 0.6 * baque + 0.35 * y * exp(-t / 0.02)
	return a


## Papel: farfalhar (ruído filtrado com amplitude irregular).
static func _papel() -> PackedFloat32Array:
	var n := int(0.4 * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	var amp := 0.0
	for i in n:
		var t := float(i) / TAXA
		if i % 300 == 0:
			amp = randf_range(0.2, 1.0)
		y += 0.45 * (randf_range(-1.0, 1.0) - y)
		a[i] = 1.2 * y * amp * sin(PI * t / 0.4)
	return a


## Pista: duas notas agudas desafinadas que crescem e tremem (o Outro Lado "responde").
static func _pista() -> PackedFloat32Array:
	var d := 1.4
	var n := int(d * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / TAXA
		var env := sin(PI * t / d) * (0.75 + 0.25 * sin(TAU * 7.0 * t))
		a[i] = 0.35 * env * (sin(TAU * 880.0 * t) + sin(TAU * 932.3 * t) + 0.5 * sin(TAU * 220.0 * t))
	return a


## Falha de fita: ruído quantizado em degraus (bitcrush) com cortes.
static func _glitch() -> PackedFloat32Array:
	var n := int(0.22 * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var v := 0.0
	for i in n:
		if i % 40 == 0:
			v = snappedf(randf_range(-1.0, 1.0), 0.25) * (0.0 if randf() < 0.2 else 1.0)
		a[i] = 0.5 * v * (1.0 - float(i) / n)
	return a


## Drone de 4 s em laço perfeito: senos graves com batimento e vento filtrado.
## As frequências fecham ciclos inteiros em 4 s, então o laço não estala.
static func _drone_laco() -> PackedFloat32Array:
	var d := 4.0
	var n := int(d * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / TAXA
		y += 0.02 * (randf_range(-1.0, 1.0) - y)
		var vento := y * (0.6 + 0.4 * sin(TAU * 0.25 * t))
		a[i] = 0.32 * (sin(TAU * 55.0 * t) + 0.8 * sin(TAU * 55.25 * t) + 0.35 * sin(TAU * 82.5 * t)) + 1.6 * vento
	return a


## Sussurros: ruído em faixa média com "respiração" lenta e sílabas irregulares.
static func _sussurro_laco() -> PackedFloat32Array:
	var d := 4.0
	var n := int(d * TAXA)
	var a := PackedFloat32Array()
	a.resize(n)
	var baixo := 0.0
	var alto := 0.0
	var silaba := 0.0
	for i in n:
		var t := float(i) / TAXA
		var r := randf_range(-1.0, 1.0)
		baixo += 0.35 * (r - baixo)
		alto += 0.08 * (r - alto)
		if i % 1800 == 0:
			silaba = randf_range(0.0, 1.0) if randf() < 0.7 else 0.0
		var respira := 0.5 - 0.5 * cos(TAU * t / d)
		a[i] = 1.6 * (baixo - alto) * respira * silaba
	return a
