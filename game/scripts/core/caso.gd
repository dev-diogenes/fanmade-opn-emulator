class_name Caso
extends RefCounted
## A ficha de investigação do grupo (p.89): resumo, objetivo, perguntas e as pistas
## anotadas. O caso é gerado por missão (Sujeito + Ação + Local, como o Gerador de
## Missões do livro, com tabelas próprias em data/jogo/casos.json).
##
## Dedução por indícios (docs/32): cada candidato tem 3 traços. Cada pista revela um traço
## do culpado verdadeiro, e a pergunta só se resolve quando o grupo ACUSA um candidato
## (`deduzir`). Errar custa Membrana e risca o candidato.

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
	return c


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


## O elemento verdadeiro de uma pergunta (o sujeito, a ação ou o local sorteado).
func verdadeiro(pergunta_id: String) -> Dictionary:
	match pergunta_id:
		"quem": return sujeito
		"oque": return acao
		"onde": return local
	return {}


## Os candidatos de uma pergunta (todos os da tabela, o verdadeiro entre eles):
## [{id, nome, indicios}]. O nome da ação é o texto dela.
static func candidatos(pergunta_id: String) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var d := DadosJogo.ler("casos")
	for c in d.get(PERGUNTA_GRUPO.get(pergunta_id, ""), []):
		lista.append({"id": String(c.id), "nome": String(c.get("nome", c.get("texto", c.id))), "indicios": c.get("indicios", [])})
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
	if acertou:
		p.respondida = true
	else:
		if not p.has("descartados"):
			p.descartados = []
		p.descartados.append(candidato_id)
	return {"ok": true, "acertou": acertou, "pergunta": p, "candidato": cand}


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
	return ""


func para_dicionario() -> Dictionary:
	return {"sujeito": sujeito, "acao": acao, "local": local, "resumo": resumo, "objetivo": objetivo,
		"perguntas": perguntas.duplicate(true), "pistas": pistas.duplicate(true)}


static func de_dicionario(d: Dictionary) -> Caso:
	var c := Caso.new()
	c.sujeito = d.get("sujeito", {})
	c.acao = d.get("acao", {})
	c.local = d.get("local", {})
	c.resumo = d.get("resumo", "")
	c.objetivo = d.get("objetivo", "")
	# Save de antes da dedução: o sujeito, a ação e o local vêm sem os traços
	for pid in PERGUNTA_GRUPO:
		var elem := c.verdadeiro(pid)
		if not elem.has("indicios"):
			for cand in candidatos(pid):
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
