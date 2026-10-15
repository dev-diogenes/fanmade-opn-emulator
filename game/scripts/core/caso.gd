class_name Caso
extends RefCounted
## A ficha de investigação do grupo (p.89): resumo, objetivo, perguntas e as pistas
## anotadas. O caso é gerado por missão (Sujeito + Ação + Local, como o Gerador de
## Missões do livro, com tabelas próprias em data/jogo/casos.json).

var sujeito: Dictionary = {}
var acao: Dictionary = {}
var local: Dictionary = {}
var resumo := ""
var objetivo := ""
## [{id, texto, pistas_necessarias, encontradas, respondida, efeito}]
var perguntas: Array[Dictionary] = []
## [{texto, responde, cena}]
var pistas: Array[Dictionary] = []


static func gerar(dados: Dados) -> Caso:
	var d := DadosJogo.ler("casos")
	var c := Caso.new()
	c.sujeito = d.sujeitos[dados.rolar(d.sujeitos.size()) - 1]
	c.acao = d.acoes[dados.rolar(d.acoes.size()) - 1]
	c.local = d.locais[dados.rolar(d.locais.size()) - 1]
	c.resumo = d.resumo
	c.objetivo = d.objetivo
	for p in d.perguntas:
		c.perguntas.append({"id": p.id, "texto": p.texto, "pistas_necessarias": int(p.pistas_necessarias),
			"encontradas": 0, "respondida": false, "efeito": p.efeito})
	return c


## Troca {sujeito}, {acao} e {local} pelos elementos deste caso.
func formatar(texto: String) -> String:
	return texto.replace("{sujeito}", sujeito.get("nome", "?")).replace("{acao}", acao.get("texto", "?")).replace("{local}", local.get("nome", "?"))


func pergunta(id: String) -> Dictionary:
	for p in perguntas:
		if p.id == id:
			return p
	return {}


## Anota uma pista. Devolve a pergunta que acabou de ser respondida (ou {}).
func registrar_pista(texto: String, responde: String, cena: String) -> Dictionary:
	pistas.append({"texto": formatar(texto), "responde": responde, "cena": cena})
	var p := pergunta(responde)
	if p.is_empty() or p.respondida:
		return {}
	p.encontradas += 1
	if p.encontradas >= p.pistas_necessarias:
		p.respondida = true
		return p
	return {}


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
	for p in d.get("perguntas", []):
		var copia: Dictionary = p.duplicate(true)
		copia.encontradas = int(copia.get("encontradas", 0))
		copia.pistas_necessarias = int(copia.get("pistas_necessarias", 2))
		c.perguntas.append(copia)
	for p in d.get("pistas", []):
		c.pistas.append(p)
	return c
