class_name EditorMissao
extends RefCounted
## Lógica do editor de missões (Fase 6), sem interface: edita uma definição mission.json v1
## (terreno letra a letra, início, objetivo, conteúdo, eventos e covil). A cena do editor só
## desenha a definição e chama estes métodos.

var definicao: Dictionary = {}


static func nova(colunas: int = 12, linhas: int = 8) -> EditorMissao:
	var e := EditorMissao.new()
	var terreno: Array = []
	for _l in linhas:
		terreno.append("c".repeat(colunas))
	e.definicao = {
		"formato": MissaoComunidade.FORMATO, "versao": MissaoComunidade.VERSAO, "id": "", "titulo": "Nova missão", "autor": "",
		"descricao": "", "briefing": "", "nex_recomendado": 5,
		"mapa": {"terreno": terreno, "inicio": [0, linhas / 2], "objetivo": [colunas - 1, linhas / 2], "conteudo": []},
		"eventos": [], "encontros": [], "ameacas": {},
		"covil": {"nome": "O covil", "ameacas": ["horror_carmesim"]},
		"opcoes": {"surgimentos": "padrao"},
	}
	return e


## Abre uma definição existente. Mapas gerados por seed viram terreno desenhado.
static func de_definicao(d: Dictionary) -> EditorMissao:
	var e := EditorMissao.new()
	e.definicao = d.duplicate(true)
	var md: Dictionary = e.definicao.get("mapa", {})
	if not md.has("terreno") and md.has("semente"):
		var mapa := MissaoComunidade.montar_mapa(e.definicao)
		var linhas: Array = []
		for lin in mapa.linhas:
			var texto := ""
			for col in mapa.colunas:
				texto += MissaoComunidade.letra_de(mapa.terreno(Hex.de_offset(col, lin)))
			linhas.append(texto)
		md.terreno = linhas
		md.inicio = _offset_de(mapa.encontrar("inicio"))
		md.objetivo = _offset_de(mapa.encontrar("objetivo"))
		md.erase("semente")
		md.erase("conteudo_procedural")
	md["conteudo"] = md.get("conteudo", [])
	e.definicao.mapa = md
	return e


static func _em(p: Array, col: int, lin: int) -> bool:
	return int(p[0]) == col and int(p[1]) == lin


static func _offset_de(h: Vector2i) -> Array:
	var o := Hex.para_offset(h)
	return [o.x, o.y]


func colunas() -> int:
	var maior := 0
	for l in definicao.mapa.terreno:
		maior = maxi(maior, String(l).length())
	return maior


func linhas() -> int:
	return definicao.mapa.terreno.size()


func terreno_em(col: int, lin: int) -> String:
	if lin < 0 or lin >= linhas() or col < 0 or col >= String(definicao.mapa.terreno[lin]).length():
		return ""
	return MissaoComunidade.LETRAS.get(String(definicao.mapa.terreno[lin])[col], "campo")


func pintar(col: int, lin: int, terreno: String) -> void:
	if terreno_em(col, lin) == "":
		return
	var texto := String(definicao.mapa.terreno[lin])
	definicao.mapa.terreno[lin] = texto.substr(0, col) + MissaoComunidade.letra_de(terreno) + texto.substr(col + 1)


## "inicio", "objetivo" ou o conteúdo ({tipo, ...}) que está no hex; {} se vazio.
func conteudo_em(col: int, lin: int) -> Dictionary:
	if _em(definicao.mapa.inicio, col, lin):
		return {"tipo": "inicio"}
	if _em(definicao.mapa.objetivo, col, lin):
		return {"tipo": "objetivo"}
	for c in definicao.mapa.conteudo:
		if int(c.em[0]) == col and int(c.em[1]) == lin:
			return c
	return {}


## Põe conteúdo num hex (tira o que havia). `conteudo`: {"tipo": "inicio"|"objetivo"|"vila"|"encontro"|"evento"|"investigacao", ...}
func colocar(col: int, lin: int, conteudo: Dictionary) -> void:
	if terreno_em(col, lin) == "":
		return
	apagar(col, lin)
	match String(conteudo.tipo):
		"inicio":
			definicao.mapa.inicio = [col, lin]
		"objetivo":
			definicao.mapa.objetivo = [col, lin]
		_:
			var novo := conteudo.duplicate()
			novo.em = [col, lin]
			definicao.mapa.conteudo.append(novo)


## Tira o conteúdo do hex (início e objetivo não somem: só mudam de lugar).
func apagar(col: int, lin: int) -> void:
	definicao.mapa.conteudo = definicao.mapa.conteudo.filter(func(c): return not (int(c.em[0]) == col and int(c.em[1]) == lin))


## Muda o tamanho do mapa, preenchendo com campo e tirando o que sair dele.
func redimensionar(novas_colunas: int, novas_linhas: int) -> void:
	novas_colunas = clampi(novas_colunas, 4, MissaoComunidade.MAX_COLUNAS)
	novas_linhas = clampi(novas_linhas, 3, MissaoComunidade.MAX_LINHAS)
	var t: Array = []
	for lin in novas_linhas:
		var texto := String(definicao.mapa.terreno[lin]) if lin < linhas() else ""
		texto = texto.substr(0, novas_colunas)
		texto += "c".repeat(novas_colunas - texto.length())
		t.append(texto)
	definicao.mapa.terreno = t
	definicao.mapa.conteudo = definicao.mapa.conteudo.filter(func(c): return int(c.em[0]) < novas_colunas and int(c.em[1]) < novas_linhas)
	for chave in ["inicio", "objetivo"]:
		var p: Array = definicao.mapa[chave]
		definicao.mapa[chave] = [mini(int(p[0]), novas_colunas - 1), mini(int(p[1]), novas_linhas - 1)]


## Terreno por ruído, como o gerador procedural (mantém o conteúdo).
func gerar_terreno(semente: int) -> void:
	var cfg := DadosJogo.ler("mapa")
	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = 0.12
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var t: Array = []
	for lin in linhas():
		var texto := ""
		for col in colunas():
			var v := ruido.get_noise_2d(col * 1.0, lin * 1.0)
			var ter := "campo"
			for l in cfg.geracao.limiares_ruido:
				if v <= float(l.ate):
					ter = l.terreno
					break
			texto += MissaoComunidade.letra_de(ter)
		t.append(texto)
	definicao.mapa.terreno = t
	for chave in ["inicio", "objetivo"]:   # início e objetivo ficam em terra firme
		var p: Array = definicao.mapa[chave]
		if terreno_em(int(p[0]), int(p[1])) == "agua":
			pintar(int(p[0]), int(p[1]), "campo")


## Adiciona um evento próprio (gera um id se faltar). Retorna o id.
func adicionar_evento(ev: Dictionary) -> String:
	var novo := ev.duplicate(true)
	var base := MissaoComunidade.id_de(String(novo.get("id", novo.get("titulo", "evento"))))
	var id := base
	var n := 2
	while definicao.eventos.any(func(e): return e.id == id):
		id = "%s_%d" % [base, n]
		n += 1
	novo.id = id
	definicao.eventos.append(novo)
	return id


func remover_evento(id: String) -> void:
	definicao.eventos = definicao.eventos.filter(func(e): return e.id != id)
	apagar_conteudo_que_usa("evento", id)


func apagar_conteudo_que_usa(tipo: String, id: String) -> void:
	definicao.mapa.conteudo = definicao.mapa.conteudo.filter(func(c): return not (c.tipo == tipo and c.get(tipo, "") == id))


func validar(ruleset: Ruleset) -> Array[String]:
	return MissaoComunidade.validar(definicao, ruleset)


func salvar() -> String:
	definicao.id = MissaoComunidade.id_de(String(definicao.get("titulo", "missao")))
	return MissaoComunidade.salvar(definicao)
