class_name Preferencias
extends RefCounted
## Preferências desta máquina, fora do save da carreira (user://preferencias.json): se o jogo
## pergunta sobre o tutorial ao abrir e as estatísticas dos tours (iniciados, concluídos,
## pulados e em que passo), lidas depois dos playtests (docs/07-tutorial.md).

const ARQUIVO := "user://preferencias.json"

## Os testes trocam o caminho para não mexer nas preferências do jogador.
static var caminho := ARQUIVO


static func ler() -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	return d if d is Dictionary else {}


static func gravar(d: Dictionary) -> void:
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d, "  "))


static func perguntar_tutorial() -> bool:
	return bool(ler().get("perguntar_tutorial", true))


static func definir_perguntar_tutorial(valor: bool) -> void:
	var d := ler()
	d["perguntar_tutorial"] = valor
	gravar(d)


## evento: "inicio", "concluido" ou "pulado" (com o passo em que a pessoa pulou, contando de 1).
static func registrar_tour(tela: String, evento: String, passo: int = 0) -> void:
	var d := ler()
	var est: Dictionary = d.get("estatisticas_tutorial", {})
	var t: Dictionary = est.get(tela, {"inicio": 0, "concluido": 0, "pulado": 0, "pulou_no_passo": {}})
	t[evento] = int(t.get(evento, 0)) + 1
	if evento == "pulado":
		var por_passo: Dictionary = t.get("pulou_no_passo", {})
		por_passo[str(passo)] = int(por_passo.get(str(passo), 0)) + 1
		t["pulou_no_passo"] = por_passo
	est[tela] = t
	d["estatisticas_tutorial"] = est
	gravar(d)


static func estatisticas() -> Dictionary:
	return ler().get("estatisticas_tutorial", {})


## Efeitos visuais de terror (docs/10, acessibilidade): "grao" (granulação e vinheta),
## "glitch" (pulsos de VHS e tremor do logo), "transicoes" (estática entre telas).
## Todos ligados por padrão. A leitura é cacheada: os efeitos consultam a cada quadro.
static var _efeitos_cache: Dictionary = {}

static func efeito(nome: String) -> bool:
	if _efeitos_cache.is_empty():
		_efeitos_cache = ler().get("efeitos", {})
	return bool(_efeitos_cache.get(nome, true))


static func definir_efeito(nome: String, valor: bool) -> void:
	var d := ler()
	var e: Dictionary = d.get("efeitos", {})
	e[nome] = valor
	d["efeitos"] = e
	gravar(d)
	_efeitos_cache = e


## Volume geral (0..1), docs/11. O ambiente (drone e sussurros) liga e desliga por efeito("ambiente").
static func volume() -> float:
	return float(ler().get("volume", 0.8))


static func definir_volume(valor: float) -> void:
	var d := ler()
	d["volume"] = clampf(valor, 0.0, 1.0)
	gravar(d)


## Modo de câmera: "terceira", "segunda" ou "primeira" (docs/13).
static func camera() -> String:
	return String(ler().get("camera", "terceira"))


static func definir_camera(modo: String) -> void:
	var d := ler()
	d["camera"] = modo
	gravar(d)


## Leitura (docs/16, A3): velocidade da datilografia ("lenta", "normal", "instantanea") e
## tempo dos resultados na tela ("curto", "normal", "clique" = fica até clicar).
static func velocidade_texto() -> String:
	return String(ler().get("velocidade_texto", "normal"))


static func definir_velocidade_texto(v: String) -> void:
	var d := ler()
	d["velocidade_texto"] = v
	gravar(d)


static func tempo_resultado() -> String:
	return String(ler().get("tempo_resultado", "normal"))


static func definir_tempo_resultado(v: String) -> void:
	var d := ler()
	d["tempo_resultado"] = v
	gravar(d)


## Escala da interface (docs/16, A1): 0.8 a 1.5.
static func escala() -> float:
	return clampf(float(ler().get("escala", 1.0)), 0.8, 1.5)


static func definir_escala(v: float) -> void:
	var d := ler()
	d["escala"] = clampf(v, 0.8, 1.5)
	gravar(d)
