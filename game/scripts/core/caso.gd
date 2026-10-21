class_name Caso
extends RefCounted
## A ficha de investigação do grupo (p.89): resumo, objetivo, perguntas e as pistas
## anotadas. O caso é gerado por missão (Sujeito + Ação + Local, como o Gerador de
## Missões do livro, com tabelas próprias em data/jogo/casos.json).
##
## Dedução por indícios (docs/32): cada candidato tem 3 traços. Cada pista revela um traço
## do culpado verdadeiro, e a pergunta só se resolve quando o grupo ACUSA um candidato
## (`deduzir`). Errar custa Membrana e risca o candidato.
##
## Investigação ampliada (p.79, docs/36): cada caso guarda uma reviravolta sorteada. A primeira
## acusação certa a revela e põe uma pergunta nova na ficha, com candidatos e traços próprios.
## Pistas de pontos cuja pergunta já foi resolvida passam a responder a pergunta nova.

const PERGUNTA_GRUPO := {"quem": "sujeitos", "oque": "acoes", "onde": "locais"}

var sujeito: Dictionary = {}
var acao: Dictionary = {}
var local: Dictionary = {}
var resumo := ""
var objetivo := ""
## [{id, texto, pistas_necessarias, encontradas, respondida, efeito, ordem, descartados}]
## `ordem`: os traços do culpado verdadeiro na ordem em que as pistas os revelam.
## `descartados`: candidatos acusados por engano (riscados na ficha de suspeitos).
var perguntas: Array[Dictionary] = []
## [{texto, responde, cena, indicio}]
var pistas: Array[Dictionary] = []
var ampliacao_id := ""        ## a reviravolta deste caso (casos.json, "ampliacoes"); "" = nenhuma
var ampliacao_verdade := ""   ## o candidato verdadeiro da pergunta nova
var ampliada := false         ## a reviravolta já foi revelada


static func gerar(dados: Dados) -> Caso:
	var d := DadosJogo.ler("casos")
	var c := Caso.new()
	c.sujeito = d.sujeitos[dados.rolar(d.sujeitos.size()) - 1].duplicate(true)   # cópia: não mexer no cache dos dados
	c.acao = d.acoes[dados.rolar(d.acoes.size()) - 1].duplicate(true)
	c.local = d.locais[dados.rolar(d.locais.size()) - 1].duplicate(true)
	c.resumo = d.resumo
	c.objetivo = d.objetivo
	for p in d.perguntas:
		c.perguntas.append({"id": p.id, "texto": p.texto, "pistas_necessarias": int(p.pistas_necessarias),
			"encontradas": 0, "respondida": false, "efeito": p.efeito, "descartados": [],
			"ordem": c._embaralhar_tracos(String(p.id))})
	c._sortear_ampliacao()
	return c


## Sorteia a reviravolta e o culpado dela, com a semente do próprio caso (sem gastar os Dados).
func _sortear_ampliacao() -> void:
	var lista: Array = DadosJogo.ler("casos").get("ampliacoes", [])
	if lista.is_empty():
		return
	var semente := absi(hash("%s|%s|%s|ampliacao" % [sujeito.get("id", ""), acao.get("id", ""), local.get("id", "")]))
	var a: Dictionary = lista[semente % lista.size()]
	ampliacao_id = String(a.id)
	ampliacao_verdade = String(a.candidatos[(semente / 7) % a.candidatos.size()].id)


## A definição da reviravolta deste caso ({} sem nenhuma).
func ampliacao() -> Dictionary:
	for a in DadosJogo.ler("casos").get("ampliacoes", []):
		if a.id == ampliacao_id:
			return a
	return {}


## Revela a reviravolta: a pergunta nova entra na ficha. Devolve {revelacao, pergunta}, ou {}.
func ampliar() -> Dictionary:
	var a := ampliacao()
	if ampliada or a.is_empty():
		return {}
	ampliada = true
	var q: Dictionary = a.pergunta
	var nova := {"id": String(q.id), "texto": q.texto, "curto": q.get("curto", ""), "pistas_necessarias": int(q.get("pistas_necessarias", 2)),
		"encontradas": 0, "respondida": false, "efeito": q.efeito, "descartados": [], "ampliacao": true}
	perguntas.append(nova)
	nova.ordem = _embaralhar_tracos(nova.id)
	return {"revelacao": String(a.revelacao), "pergunta": nova}


## A pergunta nova ainda aberta, se a reviravolta já veio ("" se não).
func pergunta_ampliada_aberta() -> String:
	for q in perguntas:
		if q.get("ampliacao", false) and not q.respondida:
			return String(q.id)
	return ""


## Os traços do culpado verdadeiro, embaralhados. A semente sai do próprio caso (e não dos
## Dados da missão): sai igual nas duas máquinas do online sem gastar rolagens.
func _embaralhar_tracos(pergunta_id: String) -> Array:
	var tracos: Array = verdadeiro(pergunta_id).get("indicios", []).duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%s|%s" % [sujeito.get("id", ""), acao.get("id", ""), local.get("id", ""), pergunta_id])
	for i in range(tracos.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = tracos[i]
		tracos[i] = tracos[j]
		tracos[j] = t
	return tracos


## Troca {sujeito}, {acao} e {local} pelos elementos deste caso.
func formatar(texto: String) -> String:
	return texto.replace("{sujeito}", sujeito.get("nome", "?")).replace("{acao}", acao.get("texto", "?")).replace("{local}", local.get("nome", "?"))


## O elemento verdadeiro de uma pergunta (o sujeito, a ação ou o local sorteado; na pergunta
## da reviravolta, o candidato sorteado dela).
func verdadeiro(pergunta_id: String) -> Dictionary:
	match pergunta_id:
		"quem": return sujeito
		"oque": return acao
		"onde": return local
	var a := ampliacao()
	if not a.is_empty() and pergunta_id == String(a.pergunta.id):
		for c in a.candidatos:
			if c.id == ampliacao_verdade:
				return c
	return {}


## Os candidatos de uma pergunta (todos os da tabela, o verdadeiro entre eles):
## [{id, nome, indicios}]. O nome da ação é o texto dela.
func candidatos(pergunta_id: String) -> Array[Dictionary]:
	var fonte: Array = DadosJogo.ler("casos").get(PERGUNTA_GRUPO.get(pergunta_id, ""), [])
	var a := ampliacao()
	if fonte.is_empty() and not a.is_empty() and pergunta_id == String(a.pergunta.id):
		fonte = a.candidatos
	var lista: Array[Dictionary] = []
	for c in fonte:
		lista.append({"id": String(c.id), "nome": String(c.get("nome", c.get("texto", c.id))), "indicios": c.get("indicios", [])})
	return lista


## Caso solucionado (p.79, docs/37): a ficha responde as perguntas que o objetivo exige
## (casos.json, "solucao": quem e o quê). Só vale o que está na ficha.
func solucionado() -> bool:
	for pid in DadosJogo.ler("casos").get("solucao", {}).get("exige", ["quem", "oque"]):
		if not pergunta(String(pid)).get("respondida", false):
			return false
	return true


## As perguntas que faltam para solucionar o caso (textos).
func faltam_para_solucao() -> Array[String]:
	var lista: Array[String] = []
	for pid in DadosJogo.ler("casos").get("solucao", {}).get("exige", ["quem", "oque"]):
		var q := pergunta(String(pid))
		if not q.is_empty() and not q.respondida:
			lista.append(String(q.texto))
	return lista


## Quanto a Membrana cai numa acusação errada (negativo).
static func penalidade_palpite() -> int:
	return int(DadosJogo.ler("casos").get("penalidade_palpite", {}).get("membrana", -5))


## Rótulo e texto de um traço: {rotulo, texto}.
static func indicio(id: String) -> Dictionary:
	return DadosJogo.ler("casos").get("indicios", {}).get(id, {"rotulo": id, "texto": ""})


## Os traços FIRMES de uma pergunta (sem os depoimentos incertos), sem repetir, na ordem
## em que apareceram.
func indicios_encontrados(pergunta_id: String) -> Array:
	var lista: Array = []
	for p in pistas:
		var t := String(p.get("indicio", ""))
		if p.get("responde", "") == pergunta_id and t != "" and not p.get("duvidosa", false) and not t in lista:
			lista.append(t)
	return lista


## Traços que só vieram de depoimentos incertos (docs/35): podem ser verdade ou não.
func indicios_duvidosos(pergunta_id: String) -> Array:
	var firmes := indicios_encontrados(pergunta_id)
	var lista: Array = []
	for p in pistas:
		var t := String(p.get("indicio", ""))
		if p.get("responde", "") == pergunta_id and t != "" and p.get("duvidosa", false) and not t in firmes and not t in lista:
			lista.append(t)
	return lista


## Candidatos que batem com todos os traços revelados e ainda não foram descartados.
func compativeis(pergunta_id: String) -> Array[Dictionary]:
	var achados := indicios_encontrados(pergunta_id)
	var descartados: Array = pergunta(pergunta_id).get("descartados", [])
	var lista: Array[Dictionary] = []
	for c in candidatos(pergunta_id):
		if c.id in descartados:
			continue
		if achados.all(func(t): return t in c.indicios):
			lista.append(c)
	return lista


## O grupo acusa um candidato. Precisa de ao menos uma pista da pergunta.
## Devolve {ok, acertou, pergunta, candidato}. `ok` é false com a pergunta já resolvida,
## sem pista, ou com o candidato já riscado ou inexistente.
func deduzir(pergunta_id: String, candidato_id: String) -> Dictionary:
	var p := pergunta(pergunta_id)
	if p.is_empty() or p.respondida or int(p.encontradas) < 1:
		return {"ok": false}
	var cand: Dictionary = {}
	for c in candidatos(pergunta_id):
		if c.id == candidato_id:
			cand = c
	if cand.is_empty() or candidato_id in p.get("descartados", []):
		return {"ok": false}
	var acertou := candidato_id == String(verdadeiro(pergunta_id).get("id", ""))
	var r := {"ok": true, "acertou": acertou, "pergunta": p, "candidato": cand}
	if acertou:
		p.respondida = true
		r.ampliacao = ampliar()   # a primeira descoberta amplia a investigação (p.79)
	else:
		if not p.has("descartados"):
			p.descartados = []
		p.descartados.append(candidato_id)
	return r


func pergunta(id: String) -> Dictionary:
	for p in perguntas:
		if p.id == id:
			return p
	return {}


## Anota uma pista: ela revela o próximo traço do culpado verdadeiro (no texto, {indicio}).
## A pergunta não se resolve sozinha: o grupo precisa deduzir (docs/32).
## Devolve a pista anotada: {texto, responde, cena, indicio, duvidosa}.
##
## `incerta` (docs/35, design do jogo): um depoimento dado aos tropeços. A `sorte` (um inteiro
## determinístico, igual nas duas máquinas do online, sem gastar a fila dos Dados) decide se a
## testemunha está certa (ímpar: enganada) e, se enganada, qual traço de outro candidato ela dá.
## A pista fica marcada como duvidosa e não entra na conta de "duas pistas firmes, um suspeito".
func registrar_pista(texto: String, responde: String, cena: String, incerta: bool = false, sorte: int = 0) -> Dictionary:
	# Ponto de uma pergunta já resolvida: o que se acha ali agora serve à pergunta nova (docs/36)
	if pergunta(responde).get("respondida", false) and pergunta_ampliada_aberta() != "":
		responde = pergunta_ampliada_aberta()
	var p := pergunta(responde)
	var traco := ""
	if not p.is_empty():
		var ordem: Array = p.get("ordem", [])
		if ordem.is_empty():
			ordem = verdadeiro(responde).get("indicios", [])
		var enganada := incerta and absi(sorte) % 2 == 1
		if enganada:
			var falsos := _tracos_de_outros(responde)
			if not falsos.is_empty():
				traco = String(falsos[(absi(sorte) / 2) % falsos.size()])
		elif not ordem.is_empty():
			var reveladas := int(p.get("reveladas", p.encontradas))
			traco = String(ordem[reveladas % ordem.size()])
			p.reveladas = reveladas + 1
		p.encontradas += 1
	var final := formatar(texto)
	if traco != "":
		final = final.replace("{indicio}", String(indicio(traco).get("texto", "")))
	else:
		final = final.replace(" {indicio}", "").replace("{indicio}", "")
	var pista := {"texto": final, "responde": responde, "cena": cena, "indicio": traco, "duvidosa": incerta}
	pistas.append(pista)
	return pista


## Traços dos outros candidatos que o culpado verdadeiro não tem (o que uma testemunha
## enganada pode dizer).
func _tracos_de_outros(pergunta_id: String) -> Array:
	var verdadeiros: Array = verdadeiro(pergunta_id).get("indicios", [])
	var lista: Array = []
	for c in candidatos(pergunta_id):
		for t in c.indicios:
			if not t in verdadeiros and not t in lista:
				lista.append(t)
	return lista


func respondidas() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for p in perguntas:
		if p.respondida:
			lista.append(p)
	return lista


## Resposta da pergunta, se já respondida.
func resposta(id: String) -> String:
	if not pergunta(id).get("respondida", false):
		return ""
	match id:
		"quem": return sujeito.get("nome", "")
		"oque": return acao.get("texto", "")
		"onde": return local.get("nome", "")
	return String(verdadeiro(id).get("nome", ""))


func para_dicionario() -> Dictionary:
	return {"sujeito": sujeito, "acao": acao, "local": local, "resumo": resumo, "objetivo": objetivo,
		"perguntas": perguntas.duplicate(true), "pistas": pistas.duplicate(true),
		"ampliacao_id": ampliacao_id, "ampliacao_verdade": ampliacao_verdade, "ampliada": ampliada}


static func de_dicionario(d: Dictionary) -> Caso:
	var c := Caso.new()
	c.sujeito = d.get("sujeito", {})
	c.acao = d.get("acao", {})
	c.local = d.get("local", {})
	c.resumo = d.get("resumo", "")
	c.objetivo = d.get("objetivo", "")
	c.ampliacao_id = String(d.get("ampliacao_id", ""))
	c.ampliacao_verdade = String(d.get("ampliacao_verdade", ""))
	c.ampliada = bool(d.get("ampliada", false))
	if not d.has("ampliacao_id"):   # save de antes da investigação ampliada (docs/36)
		c._sortear_ampliacao()
	# Save de antes da dedução: o sujeito, a ação e o local vêm sem os traços
	for pid in PERGUNTA_GRUPO:
		var elem := c.verdadeiro(pid)
		if not elem.has("indicios"):
			for cand in c.candidatos(pid):
				if cand.id == String(elem.get("id", "")):
					elem.indicios = cand.indicios
	for p in d.get("perguntas", []):
		var copia: Dictionary = p.duplicate(true)
		copia.encontradas = int(copia.get("encontradas", 0))
		copia.pistas_necessarias = int(copia.get("pistas_necessarias", 2))
		if not copia.has("descartados"):
			copia.descartados = []
		if not copia.has("ordem"):   # save de antes da dedução (docs/32)
			copia.ordem = c._embaralhar_tracos(String(copia.id))
		c.perguntas.append(copia)
	for p in d.get("pistas", []):
		c.pistas.append(p)
	return c
