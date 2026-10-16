class_name MissaoComunidade
extends RefCounted
## Missões da comunidade (Fase 6): o formato mission.json v1 (docs/04-missoes-da-comunidade.md),
## a leitura das pastas, a validação e a montagem da Missao a partir da definição.

const FORMATO := "opn-missao"
const VERSAO := 1
const PASTA_JOGO := "res://data/missoes"
const PASTA_USUARIO := "user://missoes"
const MAX_COLUNAS := 30
const MAX_LINHAS := 20
## Uma letra por terreno nas linhas de "terreno"
const LETRAS := {"c": "campo", "e": "estrada", "f": "floresta", "p": "pantano", "m": "morro", "u": "cidade", "r": "ruina", "a": "agua"}
const TIPOS_CONTEUDO := ["encontro", "evento", "investigacao", "vila"]
const SURGIMENTOS := ["padrao", "proprios", "nenhum"]


static func letra_de(terreno: String) -> String:
	for l in LETRAS:
		if LETRAS[l] == terreno:
			return l
	return "c"


# --- Arquivos ----------------------------------------------------------------------

## Missões das duas pastas (as que vêm com o jogo e as do jogador): [{caminho, definicao, erros}].
static func listar(ruleset: Ruleset) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	DirAccess.make_dir_recursive_absolute(PASTA_USUARIO)
	for pasta in [PASTA_JOGO, PASTA_USUARIO]:
		var dir := DirAccess.open(pasta)
		if dir == null:
			continue
		for arquivo in dir.get_files():
			if arquivo.get_extension().to_lower() == "json":
				var caminho: String = pasta.path_join(arquivo)
				var lido := ler_arquivo(caminho, ruleset)
				lido["caminho"] = caminho
				lista.append(lido)
	return lista


static func ler_arquivo(caminho: String, ruleset: Ruleset) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {"definicao": {}, "erros": ["Arquivo não encontrado: %s" % caminho] as Array[String]}
	var texto := FileAccess.get_file_as_string(caminho)
	var json := JSON.new()
	if json.parse(texto) != OK:
		return {"definicao": {}, "erros": ["JSON inválido na linha %d: %s" % [json.get_error_line(), json.get_error_message()]] as Array[String]}
	if not json.data is Dictionary:
		return {"definicao": {}, "erros": ["O arquivo precisa ser um objeto JSON"] as Array[String]}
	return {"definicao": json.data, "erros": validar(json.data, ruleset)}


## Salva na pasta do jogador (user://missoes/<id>.json). Retorna o caminho.
static func salvar(definicao: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(PASTA_USUARIO)
	if String(definicao.get("id", "")) == "":
		definicao["id"] = id_de(String(definicao.get("titulo", "missao")))
	var caminho := PASTA_USUARIO.path_join(String(definicao.id) + ".json")
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(JSON.stringify(definicao, "  "))
	f.close()
	return caminho


## "A Capela do Morro!" -> "a_capela_do_morro"
static func id_de(titulo: String) -> String:
	var t := titulo.to_lower().strip_edges()
	var trocas := {"á": "a", "à": "a", "â": "a", "ã": "a", "é": "e", "ê": "e", "í": "i", "ó": "o", "ô": "o", "õ": "o", "ú": "u", "ç": "c"}
	for k in trocas:
		t = t.replace(k, trocas[k])
	var saida := ""
	for ch in t:
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			saida += ch
		elif not saida.ends_with("_") and saida != "":
			saida += "_"
	return saida.trim_suffix("_") if saida != "" else "missao"


# --- Validação ---------------------------------------------------------------------

## Erros em português, prontos para mostrar ao autor. Lista vazia = missão jogável.
static func validar(d: Dictionary, ruleset: Ruleset) -> Array[String]:
	var erros: Array[String] = []
	if d.get("formato", "") != FORMATO:
		erros.append("\"formato\" deve ser \"%s\"" % FORMATO)
	if int(d.get("versao", 0)) != VERSAO:
		erros.append("\"versao\" deve ser %d" % VERSAO)
	if String(d.get("titulo", "")).strip_edges() == "":
		erros.append("Falta o \"titulo\" da missão")
	var md = d.get("mapa")
	if not md is Dictionary:
		erros.append("Falta o \"mapa\"")
		return erros
	if md.has("terreno"):
		if not md.terreno is Array or md.terreno.is_empty():
			erros.append("\"mapa.terreno\" deve ser uma lista de linhas de letras")
			return erros
		if md.terreno.size() > MAX_LINHAS:
			erros.append("O mapa tem mais de %d linhas" % MAX_LINHAS)
		for i in md.terreno.size():
			var linha := String(md.terreno[i])
			if linha.length() > MAX_COLUNAS:
				erros.append("A linha %d do terreno tem mais de %d colunas" % [i + 1, MAX_COLUNAS])
			for ch in linha:
				if not LETRAS.has(ch.to_lower()):
					erros.append("Letra de terreno desconhecida \"%s\" na linha %d (use %s)" % [ch, i + 1, ", ".join(PackedStringArray(LETRAS.keys()))])
					break
		for chave in ["inicio", "objetivo"]:
			if not md.has(chave):
				erros.append("Falta \"mapa.%s\" ([coluna, linha])" % chave)
	elif not md.has("semente"):
		erros.append("O mapa precisa de \"terreno\" (desenhado) ou de \"semente\" (gerado)")
	for chave in ["inicio", "objetivo"]:
		if md.has(chave) and not _coord_valida(md[chave]):
			erros.append("\"mapa.%s\" deve ser [coluna, linha]" % chave)
	if not erros.is_empty():
		return erros
	var mapa := montar_mapa(d)
	var inicio := mapa.encontrar("inicio")
	var objetivo := mapa.encontrar("objetivo")
	for par in [["inicio", inicio], ["objetivo", objetivo]]:
		if not mapa.tem(par[1]):
			erros.append("O %s está fora do mapa" % par[0])
		elif not mapa.passavel(par[1]):
			erros.append("O %s está em água (terreno intransponível)" % par[0])
	if erros.is_empty() and mapa.caminho(inicio, objetivo, false).is_empty():
		erros.append("Não há caminho por terra do início até o objetivo")
	# Conteúdo próprio
	var ids_encontros := {}
	for e in d.get("encontros", []):
		if String(e.get("id", "")) == "" or e.get("ameacas", []).is_empty():
			erros.append("Encontro sem \"id\" ou sem \"ameacas\": %s" % str(e.get("nome", e)))
			continue
		ids_encontros[e.id] = true
		for am in e.ameacas:
			if not _ameaca_existe(String(am), d, ruleset):
				erros.append("Encontro \"%s\": ameaça desconhecida \"%s\"" % [e.id, am])
	var covil: Dictionary = d.get("covil", {})
	if not covil.is_empty():
		if covil.get("ameacas", []).is_empty():
			erros.append("O covil precisa de \"ameacas\" (a primeira é o chefe)")
		for am in covil.get("ameacas", []):
			if not _ameaca_existe(String(am), d, ruleset):
				erros.append("Covil: ameaça desconhecida \"%s\"" % am)
	var ids_eventos := {}
	var efeitos_ok: Array = DadosJogo.ler("eventos").efeitos_possiveis
	for ev in d.get("eventos", []):
		var nome := String(ev.get("id", "?"))
		for campo in ["id", "titulo", "texto", "pericia", "dt", "sucesso", "falha"]:
			if not ev.has(campo):
				erros.append("Evento \"%s\": falta \"%s\"" % [nome, campo])
		if ev.has("pericia") and not ruleset.tem_pericia(String(ev.pericia)):
			erros.append("Evento \"%s\": perícia desconhecida \"%s\"" % [nome, ev.pericia])
		for lado in ["sucesso", "falha"]:
			for ef in ev.get(lado, {}).get("efeitos", []):
				if not String(ef.get("tipo", "")) in efeitos_ok:
					erros.append("Evento \"%s\": efeito desconhecido \"%s\" (use %s)" % [nome, ef.get("tipo", ""), ", ".join(PackedStringArray(efeitos_ok))])
		ids_eventos[nome] = true
	for amea_id in d.get("ameacas", {}):
		var info: Dictionary = d.ameacas[amea_id]
		var ficha: Dictionary = info.get("ficha", {})
		if not ficha.has("pv") or not ficha.has("defesa"):
			erros.append("Ameaça \"%s\": a ficha precisa de \"pv\" e \"defesa\"" % amea_id)
		if ficha.get("ataques", []).is_empty() and not info.get("arma") is Dictionary:
			var arma_id := String(info.get("arma", ""))
			if not ruleset.tem_arma(arma_id) and not DadosJogo.ler("ameacas").armas_extras.has(arma_id):
				erros.append("Ameaça \"%s\": arma desconhecida \"%s\"" % [amea_id, arma_id])
	# Conteúdo posicionado no mapa
	var eventos_jogo := {}
	var ev_jogo := DadosJogo.ler("eventos")
	for ev in ev_jogo.eventos + ev_jogo.get("eventos_medo", []):
		eventos_jogo[ev.id] = true
	var encontros_jogo := {}
	for e in DadosJogo.ler("encontros").encontros:
		encontros_jogo[e.id] = true
	var cenas := {}
	for cn in DadosJogo.ler("cenas_investigacao").cenas:
		cenas[cn.id] = true
	for c in md.get("conteudo", []):
		var tipo := String(c.get("tipo", ""))
		if not tipo in TIPOS_CONTEUDO:
			erros.append("Conteúdo com tipo desconhecido \"%s\" (use %s)" % [tipo, ", ".join(PackedStringArray(TIPOS_CONTEUDO))])
			continue
		if not _coord_valida(c.get("em")):
			erros.append("Conteúdo \"%s\" sem \"em\": [coluna, linha]" % tipo)
			continue
		var h := Hex.de_offset(int(c.em[0]), int(c.em[1]))
		if not mapa.tem(h) or not mapa.passavel(h):
			erros.append("%s em [%d, %d] fora do mapa ou na água" % [tipo.capitalize(), int(c.em[0]), int(c.em[1])])
		match tipo:
			"encontro":
				if not ids_encontros.has(c.get("encontro", "")) and not encontros_jogo.has(c.get("encontro", "")):
					erros.append("Encontro desconhecido \"%s\" em [%d, %d]" % [c.get("encontro", ""), int(c.em[0]), int(c.em[1])])
			"evento":
				if not ids_eventos.has(c.get("evento", "")) and not eventos_jogo.has(c.get("evento", "")):
					erros.append("Evento desconhecido \"%s\" em [%d, %d]" % [c.get("evento", ""), int(c.em[0]), int(c.em[1])])
			"investigacao":
				if not cenas.has(c.get("cena", "")):
					erros.append("Cena de investigação desconhecida \"%s\" (use %s)" % [c.get("cena", ""), ", ".join(PackedStringArray(cenas.keys()))])
	var surg := String(d.get("opcoes", {}).get("surgimentos", "padrao"))
	if not surg in SURGIMENTOS:
		erros.append("\"opcoes.surgimentos\" deve ser %s" % " ou ".join(PackedStringArray(SURGIMENTOS)))
	if surg == "proprios" and d.get("encontros", []).is_empty():
		erros.append("Com \"surgimentos\": \"proprios\", a missão precisa de \"encontros\" próprios")
	return erros


static func _coord_valida(v) -> bool:
	return v is Array and v.size() == 2 and (v[0] is int or v[0] is float) and (v[1] is int or v[1] is float)


static func _ameaca_existe(id: String, d: Dictionary, ruleset: Ruleset) -> bool:
	return d.get("ameacas", {}).has(id) or DadosJogo.ler("ameacas").ameacas.has(id) or not ruleset.ameaca(id).is_empty()


# --- Montagem -----------------------------------------------------------------------

## Mapa da definição: desenhado letra a letra, ou gerado pela seed (com ou sem o conteúdo procedural).
static func montar_mapa(d: Dictionary) -> MapaHex:
	var cfg := DadosJogo.ler("mapa")
	var md: Dictionary = d.mapa
	var mapa: MapaHex
	if md.has("terreno"):
		mapa = MapaHex.new(cfg.terrenos)
		mapa.linhas = md.terreno.size()
		for lin in md.terreno.size():
			var texto := String(md.terreno[lin])
			mapa.colunas = maxi(mapa.colunas, texto.length())
			for col in texto.length():
				mapa.celulas[Hex.de_offset(col, lin)] = {"terreno": LETRAS.get(texto[col].to_lower(), "campo"), "conteudo": {}, "revelado": false}
	else:
		mapa = GeradorMapa.gerar(int(md.semente))
		for h in mapa.celulas:
			mapa.celulas[h].revelado = false
			var tipo: String = mapa.conteudo(h).get("tipo", "")
			var limpar: bool = not md.get("conteudo_procedural", false) and not tipo in ["inicio", "objetivo"]
			if limpar or (tipo == "inicio" and md.has("inicio")) or (tipo == "objetivo" and md.has("objetivo")):
				mapa.limpar_conteudo(h)
	if md.has("inicio"):
		mapa.definir_conteudo(Hex.de_offset(int(md.inicio[0]), int(md.inicio[1])), {"tipo": "inicio", "nome": String(md.get("nome_inicio", "Ponto de encontro"))})
	if md.has("objetivo"):
		mapa.definir_conteudo(Hex.de_offset(int(md.objetivo[0]), int(md.objetivo[1])), {"tipo": "objetivo", "encontro": "covil"})
	for c in md.get("conteudo", []):
		var h := Hex.de_offset(int(c.em[0]), int(c.em[1]))
		match String(c.tipo):
			"encontro": mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": c.encontro})
			"evento": mapa.definir_conteudo(h, {"tipo": "evento", "evento": c.evento})
			"investigacao": mapa.definir_conteudo(h, {"tipo": "investigacao", "cena": c.cena})
			"vila": mapa.definir_conteudo(h, {"tipo": "vila", "nome": String(c.get("nome", "Vila"))})
	var inicio := mapa.encontrar("inicio")
	if mapa.tem(inicio):
		mapa.revelar(inicio, int(cfg.visao))
	return mapa


## Monta a missão: grupo no início, conteúdo próprio, caso, Membrana e briefing.
static func criar_missao(d: Dictionary, ruleset: Ruleset, grupo: Array, opcoes: Dictionary, semente: int) -> Missao:
	var m := Missao.nova(semente, ruleset, grupo, opcoes)
	m.mapa = montar_mapa(d)
	m.extras = {"id": String(d.get("id", id_de(String(d.get("titulo", ""))))), "titulo": String(d.get("titulo", "")), "autor": String(d.get("autor", "")),
		"encontros": d.get("encontros", []).duplicate(true), "eventos": d.get("eventos", []).duplicate(true),
		"ameacas": d.get("ameacas", {}).duplicate(true), "covil": d.get("covil", {}).duplicate(true),
		"surgimentos": String(d.get("opcoes", {}).get("surgimentos", "padrao"))}
	var inicio := m.mapa.encontrar("inicio")
	for a in m.agentes:
		m.posicoes[a] = inicio
	var caso: Dictionary = d.get("caso", {})
	for parte in ["sujeito", "acao", "local"]:
		if caso.has(parte):
			m.caso.set(parte, caso[parte].duplicate(true))
	if caso.has("objetivo"):
		m.caso.objetivo = String(caso.objetivo)
	if d.has("membrana_inicial"):
		m.membrana.valor = clampi(int(d.membrana_inicial), 1, 100)
	m._log("[b]%s[/b]%s" % [d.get("titulo", "Missão da comunidade"), "" if String(d.get("autor", "")) == "" else " — por %s" % d.autor])
	if String(d.get("briefing", "")) != "":
		m._log(String(d.briefing))
	return m
