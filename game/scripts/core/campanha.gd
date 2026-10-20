class_name Campanha
extends RefCounted
## Campanha (Fase 7): uma sequência fixa de missões no formato mission.json v1, com textos
## entre elas, marcas que uma missão deixa para as seguintes e recrutas que entram na Base.
## Formato em docs/05-campanha.md; decisão no ADR 0006.

const FORMATO := "opn-campanha"
const VERSAO := 1
const PASTA := "res://data/campanhas"
const ARQUIVO := "campanha.json"
## O que uma marca pode fazer no começo de uma missão posterior
const EFEITOS := ["membrana", "chefe_enfraquecido", "revelar_objetivo"]


# --- Arquivos ----------------------------------------------------------------------

## Campanhas que vêm com o jogo: [{pasta, definicao, erros}], uma por subpasta de PASTA.
static func listar(ruleset: Ruleset) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var dir := DirAccess.open(PASTA)
	if dir == null:
		return lista
	for sub in dir.get_directories():
		var pasta: String = PASTA.path_join(sub)
		if FileAccess.file_exists(pasta.path_join(ARQUIVO)):
			lista.append(ler_pasta(pasta, ruleset))
	return lista


static func carregar(id: String, ruleset: Ruleset) -> Dictionary:
	return ler_pasta(PASTA.path_join(id), ruleset)


## Lê o campanha.json e o arquivo de cada missão, que passa a ficar em "definicao" da etapa.
static func ler_pasta(pasta: String, ruleset: Ruleset) -> Dictionary:
	var res := {"pasta": pasta, "definicao": {}, "erros": [] as Array[String]}
	var lido := _ler_json(pasta.path_join(ARQUIVO))
	if lido.erro != "":
		res.erros.append(lido.erro)
		return res
	var d: Dictionary = lido.dados
	for etapa in d.get("missoes", []):
		if etapa is Dictionary and String(etapa.get("arquivo", "")) != "" and not etapa.has("definicao"):
			var m := _ler_json(pasta.path_join(String(etapa.arquivo)))
			if m.erro == "":
				etapa["definicao"] = m.dados
			else:
				etapa["erro_arquivo"] = m.erro
	res.definicao = d
	res.erros = validar(d, ruleset)
	return res


static func _ler_json(caminho: String) -> Dictionary:
	if not FileAccess.file_exists(caminho):
		return {"dados": {}, "erro": "Arquivo não encontrado: %s" % caminho}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(caminho)) != OK:
		return {"dados": {}, "erro": "%s: JSON inválido na linha %d (%s)" % [caminho.get_file(), json.get_error_line(), json.get_error_message()]}
	if not json.data is Dictionary:
		return {"dados": {}, "erro": "%s precisa ser um objeto JSON" % caminho.get_file()}
	return {"dados": json.data, "erro": ""}


# --- Validação ---------------------------------------------------------------------

## Erros em português; lista vazia = campanha jogável. Valida também cada missão.
static func validar(d: Dictionary, ruleset: Ruleset) -> Array[String]:
	var erros: Array[String] = []
	if d.get("formato", "") != FORMATO:
		erros.append("\"formato\" deve ser \"%s\"" % FORMATO)
	if int(d.get("versao", 0)) != VERSAO:
		erros.append("\"versao\" deve ser %d" % VERSAO)
	for campo in ["id", "titulo"]:
		if String(d.get(campo, "")).strip_edges() == "":
			erros.append("Falta o \"%s\" da campanha" % campo)
	var missoes = d.get("missoes", [])
	if not missoes is Array or missoes.is_empty():
		erros.append("A campanha precisa de \"missoes\"")
		return erros
	var recrutas := {}
	for r in d.get("recrutas", []):
		var nome := String(r.get("nome", ""))
		if nome == "":
			erros.append("Recruta sem \"nome\"")
			continue
		recrutas[nome] = true
		var criado := CriacaoAgente.criar(ruleset, r)
		if criado.agente == null:
			erros.append("Recruta \"%s\": %s" % [nome, "; ".join(PackedStringArray(criado.erros))])
		else:
			for e in (criado.agente as Agente).validar_equipamento(r.get("equipamento", [])):
				erros.append("Recruta \"%s\": %s" % [nome, e])
	var perguntas: Array = DadosJogo.ler("casos").perguntas.map(func(p): return p.id)
	var marcas := {}
	for i in missoes.size():
		var etapa = missoes[i]
		var rotulo := "Missão %d" % (i + 1)
		if not etapa is Dictionary:
			erros.append("%s: cada missão é um objeto com \"arquivo\"" % rotulo)
			continue
		if etapa.has("erro_arquivo"):
			erros.append("%s: %s" % [rotulo, etapa.erro_arquivo])
			continue
		if not etapa.get("definicao") is Dictionary:
			erros.append("%s: falta \"arquivo\"" % rotulo)
			continue
		for e in MissaoComunidade.validar(etapa.definicao, ruleset):
			erros.append("%s (%s): %s" % [rotulo, etapa.definicao.get("titulo", "?"), e])
		for nome in etapa.get("recompensas", {}).get("recrutas", []):
			if not recrutas.has(nome):
				erros.append("%s: recruta desconhecido \"%s\" (declare em \"recrutas\")" % [rotulo, nome])
		for ef in etapa.get("efeitos_de_marcas", []):
			if not marcas.has(String(ef.get("marca", ""))):
				erros.append("%s: a marca \"%s\" não vem de nenhuma missão anterior" % [rotulo, ef.get("marca", "")])
			if not String(ef.get("tipo", "")) in EFEITOS:
				erros.append("%s: efeito de marca desconhecido \"%s\" (use %s)" % [rotulo, ef.get("tipo", ""), ", ".join(PackedStringArray(EFEITOS))])
		var deixa: Dictionary = etapa.get("marcas", {})
		for pergunta in deixa:
			if not pergunta in perguntas:
				erros.append("%s: marca ligada a uma pergunta desconhecida \"%s\" (use %s)" % [rotulo, pergunta, ", ".join(PackedStringArray(perguntas))])
			if String(deixa[pergunta].get("id", "")) == "":
				erros.append("%s: a marca da pergunta \"%s\" precisa de \"id\"" % [rotulo, pergunta])
			marcas[String(deixa[pergunta].get("id", ""))] = true
	return erros


# --- Durante a campanha ----------------------------------------------------------------

## O que a missão leva da campanha (vai no save junto com ela): textos, recrutas e marcas.
static func extras_da_etapa(d: Dictionary, i: int) -> Dictionary:
	var etapa: Dictionary = d.missoes[i]
	var recrutas: Array = []
	for nome in etapa.get("recompensas", {}).get("recrutas", []):
		for r in d.get("recrutas", []):
			if r.nome == nome:
				recrutas.append(r.duplicate(true))
	var ultima: bool = i == d.missoes.size() - 1
	return {"id": String(d.id), "titulo": String(d.titulo), "etapa": i, "total": d.missoes.size(),
		"depois": String(etapa.get("depois", "")), "falha": String(etapa.get("falha", "")),
		"recrutas": recrutas, "marcas": etapa.get("marcas", {}).duplicate(true),
		"epilogo": String(d.get("epilogo", "")) if ultima else ""}


## No começo da missão, aplica os efeitos das marcas que o grupo trouxe das anteriores.
## Devolve quantos efeitos valeram.
static func aplicar_marcas(m: Missao, etapa: Dictionary, marcas: Array) -> int:
	var aplicados := 0
	for ef in etapa.get("efeitos_de_marcas", []):
		if not String(ef.get("marca", "")) in marcas:
			continue
		aplicados += 1
		m._log("[color=#e3c27a]%s[/color]" % ef.get("texto", ""))
		match String(ef.tipo):
			"membrana":
				m.membrana.alterar(int(ef.get("valor", 0)), "campanha")
			"chefe_enfraquecido":
				m.modificador_chefe -= float(ef.get("valor", 0.2))
			"revelar_objetivo":
				m.mapa.revelar(m.mapa.encontrar("objetivo"), 1)
	return aplicados


## Marcas que a missão deixa: as ligadas às perguntas do caso que o grupo respondeu.
static func marcas_ganhas(m: Missao) -> Array:
	var ganhas: Array = []
	var marcas: Dictionary = m.extras.get("campanha", {}).get("marcas", {})
	if m.caso == null:
		return ganhas
	for p in m.caso.respondidas():
		if marcas.has(p.id):
			ganhas.append(marcas[p.id])
	return ganhas


## Texto do ponto em que a campanha está, para a Base: "Missão 2 de 4: A Estrada que Desce".
static func descrever_etapa(d: Dictionary, progresso: Dictionary) -> String:
	var total: int = d.get("missoes", []).size()
	if progresso.get("concluida", false):
		return "Campanha concluída"
	var i := clampi(int(progresso.get("etapa", 0)), 0, maxi(0, total - 1))
	var md: Dictionary = d.missoes[i].get("definicao", {}) if total > 0 else {}
	return "Missão %d de %d: %s" % [i + 1, total, md.get("titulo", "?")]
