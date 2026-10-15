class_name Progressao
extends RefCounted
## Escolhas que ficam pendentes quando um agente sobe de NEX (cap. 1):
## trilha (10%), poderes (15/30/45…), aumento de atributo (20/50/80/95),
## grau de treinamento (35/70) e versatilidade (50%).


## Lista de pendências: [{"tipo": "trilha"|"poder"|"aumento"|"grau"|"versatilidade", "opcoes": [...], "quantidade": int}]
static func pendencias(a: Agente) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var rs := a.ruleset
	if a.classe_id == "mundano":
		return lista
	if a.nex >= 10 and a.trilha_id == "":
		lista.append({"tipo": "trilha", "opcoes": trilhas_possiveis(a)})
	if a.nex >= 50 and a.versatilidade == "":
		var opcoes: Array = ["poder"]
		for t in trilhas_possiveis(a):
			if t != a.trilha_id:
				opcoes.append("trilha:" + t)
		lista.append({"tipo": "versatilidade", "opcoes": opcoes})
	var poderes_esperados := rs.quantos_ate("poder", a.nex)
	if a.versatilidade == "poder":
		poderes_esperados += 1
	if a.idade != "" and rs.tem_faixa_idade(a.idade) and rs.faixa_idade(a.idade).get("poder_extra", false):
		poderes_esperados += 1
	for i in maxi(0, poderes_esperados - a.poderes.size()):
		lista.append({"tipo": "poder", "opcoes": poderes_possiveis(a)})
	for i in maxi(0, rs.quantos_ate("aumento_atributo", a.nex) - a.aumentos.size()):
		lista.append({"tipo": "aumento", "opcoes": atributos_aumentaveis(a)})
	for i in maxi(0, a.rituais_esperados() - rituais_de_classe(a)):
		lista.append({"tipo": "ritual", "opcoes": rituais_possiveis(a)})
	for i in maxi(0, paranormais_esperados(a) - a.poderes_paranormais.size()):
		lista.append({"tipo": "poder_paranormal", "opcoes": poderes_paranormais_possiveis(a)})
	if a.nex >= int(rs.dados.get("poderes_paranormais", {}).get("afinidade", {}).get("nex", 50)) and a.afinidade == "":
		lista.append({"tipo": "afinidade", "opcoes": ["conhecimento", "energia", "morte", "sangue"]})
	for i in maxi(0, rs.quantos_ate("grau_treinamento", a.nex) - a.graus_feitos):
		var regra: Dictionary = rs.dados.classes.grau_treinamento_qtd.get(a.classe_id, {"base": 0, "soma_atributo": "int"})
		lista.append({"tipo": "grau", "quantidade": int(regra.base) + a.atributo(regra.soma_atributo), "opcoes": pericias_para_subir(a)})
	return lista


static func trilhas_possiveis(a: Agente) -> Array:
	var lista: Array = []
	for t in a.ruleset.dados.trilhas.trilhas.get(a.classe_id, []):
		if CriacaoAgente._checar_pre(t.get("pre", {}), a, t.id).is_empty():
			lista.append(t.id)
	return lista


## Poderes de classe cujos pré-requisitos o agente cumpre (sem repetir os não repetíveis).
static func poderes_possiveis(a: Agente) -> Array:
	var lista: Array = []
	for p in a.ruleset.dados.poderes_classe.poderes.get(a.classe_id, []):
		if p.id in a.poderes and not p.get("repetivel", false):
			continue
		if CriacaoAgente._checar_pre(p.get("pre", {}), a, p.id).is_empty():
			lista.append(p.id)
	return lista


## Rituais aprendidos pela classe (sem contar os de Aprender Ritual).
static func rituais_de_classe(a: Agente) -> int:
	return a.rituais.size() - a.poderes_paranormais.filter(func(e): return e.id == "aprender_ritual").size()


## Poderes paranormais esperados: um por Transcender e um da origem Cultista Arrependido.
static func paranormais_esperados(a: Agente) -> int:
	var n := a.poderes.count("transcender")
	if a.origem_id == "cultista_arrependido" and not a.sem_poder_origem:
		n += 1
	return n


static func poderes_paranormais_possiveis(a: Agente) -> Array:
	var lista: Array = []
	for p in a.ruleset.lista_poderes_paranormais():
		if validar_poder_paranormal(a, p.id, "", true).is_empty():
			lista.append(p.id)
	return lista


## Valida um poder paranormal (p.114). `sem_escolha`: só os pré-requisitos (para montar listas).
static func validar_poder_paranormal(a: Agente, poder_id: String, escolha: String, sem_escolha: bool = false) -> Array[String]:
	var erros: Array[String] = []
	var rs := a.ruleset
	var p := rs.poder_paranormal(poder_id)
	if p.is_empty():
		erros.append("Poder paranormal desconhecido: %s" % poder_id)
		return erros
	var ja_tem := a.poderes_paranormais.filter(func(e): return e.id == poder_id).size()
	if ja_tem > 0 and not p.get("repetivel", false):
		var el := String(p.get("elemento", ""))
		var segunda_por_afinidade: bool = ja_tem == 1 and p.has("afinidade") and a.afinidade != "" and (el == a.afinidade or el == "escolha")
		if not segunda_por_afinidade:
			erros.append("%s não pode ser escolhido de novo" % p.nome)
	var pre: Dictionary = p.get("pre", {})
	for el in pre.get("elementos", {}):
		if a.contagem_elemento(el) < int(pre.elementos[el]):
			erros.append("%s exige %d poder(es) de %s" % [p.nome, int(pre.elementos[el]), el])
	if sem_escolha:
		return erros
	match String(p.get("escolha", "")):
		"ritual":
			var r := rs.ritual(escolha)
			var max_c := 3 if a.nex >= 75 else (2 if a.nex >= 45 else 1)
			if r.is_empty():
				erros.append("Escolha um ritual para Aprender Ritual")
			elif int(r.circulo) > max_c:
				erros.append("Aprender Ritual neste NEX vai até o %dº círculo" % max_c)
			elif escolha in a.rituais:
				erros.append("Já conhece %s" % r.nome)
		"elemento":
			if not escolha in ["conhecimento", "energia", "morte", "sangue"]:
				erros.append("Escolha um elemento (conhecimento, energia, morte ou sangue)")
		"poder_de_outra_classe":
			var partes := escolha.split(":")
			if partes.size() != 2 or partes[0] == a.classe_id or not rs.tem_poder(partes[0], partes[1]):
				erros.append("Escolha um poder de outra classe no formato classe:poder")
			elif not CriacaoAgente._checar_pre(rs.poder(partes[0], partes[1]).get("pre", {}), a, partes[1]).is_empty():
				erros.append("Pré-requisitos de %s não cumpridos" % partes[1])
	return erros


static func adicionar_poder_paranormal(a: Agente, poder_id: String, escolha: String) -> Array[String]:
	var erros := validar_poder_paranormal(a, poder_id, escolha)
	if erros.is_empty():
		a.poderes_paranormais.append({"id": poder_id, "escolha": escolha})
		if poder_id == "aprender_ritual":
			a.rituais.append(escolha)
		a.recalcular_maximos()
	return erros


## Rituais que o agente pode aprender agora (círculo acessível, ainda não conhecidos).
static func rituais_possiveis(a: Agente) -> Array:
	var lista: Array = []
	for r in a.ruleset.lista_rituais():
		if int(r.circulo) <= a.circulo_maximo() and not r.id in a.rituais and not (r.elemento == "medo" and int(r.circulo) == 4):
			lista.append(r.id)
	return lista


static func atributos_aumentaveis(a: Agente) -> Array:
	var maximo := int(a.ruleset.dados.classes.progressao.atributo_maximo)
	var proibidos: Array = []
	if a.idade != "" and a.ruleset.tem_faixa_idade(a.idade):
		proibidos = a.ruleset.faixa_idade(a.idade).get("sem_aumento", [])
	var lista: Array = []
	for attr_id in ["agi", "for", "int", "pre", "vig"]:
		if int(a.atributos.get(attr_id, 0)) < maximo and not attr_id in proibidos:
			lista.append(attr_id)
	return lista


## Perícias treinadas que podem subir um grau no NEX atual.
static func pericias_para_subir(a: Agente) -> Array:
	var lista: Array = []
	for p in a.pericias:
		var g: String = a.pericias[p]
		if (g == "treinado" and a.nex >= 35) or (g == "veterano" and a.nex >= 70):
			lista.append(p)
	return lista


## Aplica uma escolha. `escolha`: id (trilha/poder/atributo/versatilidade) ou Array (grau).
## Para Treinamento em Perícia, passe `extra` = [pericia1, pericia2]. Retorna os erros.
static func aplicar(a: Agente, tipo: String, escolha, extra: Array = []) -> Array[String]:
	var erros: Array[String] = []
	var pend := pendencias(a).filter(func(p): return p.tipo == tipo)
	if pend.is_empty():
		erros.append("Nada pendente do tipo %s" % tipo)
		return erros
	var p: Dictionary = pend[0]
	match tipo:
		"trilha":
			if not escolha in p.opcoes:
				erros.append("Trilha indisponível: %s" % escolha)
			else:
				a.trilha_id = escolha
		"versatilidade":
			if not escolha in p.opcoes:
				erros.append("Opção de versatilidade inválida: %s" % escolha)
			else:
				a.versatilidade = escolha
				if String(escolha).begins_with("trilha:"):
					a.trilha_versatil = String(escolha).trim_prefix("trilha:")
		"poder":
			if not escolha in p.opcoes:
				erros.append("Poder indisponível: %s" % escolha)
			elif escolha == "transcender":
				if extra.is_empty():
					erros.append("Transcender exige escolher um poder paranormal")
				else:
					a.poderes.append(escolha)
					var e2 := adicionar_poder_paranormal(a, extra[0], extra[1] if extra.size() > 1 else "")
					if not e2.is_empty():
						a.poderes.erase(escolha)
						erros.append_array(e2)
			elif escolha == "treinamento_em_pericia":
				if extra.size() != 2:
					erros.append("Treinamento em Perícia exige escolher 2 perícias")
				else:
					var copia := a.pericias.duplicate()
					for per in extra:
						if CriacaoAgente._subir_grau(a.ruleset, copia, per, a.nex, true) == "":
							erros.append("Não dá para melhorar %s" % per)
					if erros.is_empty():
						a.pericias = copia
						a.poderes.append(escolha)
			else:
				a.poderes.append(escolha)
		"poder_paranormal":
			erros.append_array(adicionar_poder_paranormal(a, escolha, extra[0] if not extra.is_empty() else ""))
		"afinidade":
			if not escolha in p.opcoes:
				erros.append("Elemento inválido: %s" % escolha)
			else:
				a.afinidade = escolha
		"ritual":
			if not escolha in p.opcoes:
				erros.append("Ritual indisponível: %s" % escolha)
			else:
				a.rituais.append(escolha)
		"aumento":
			if not escolha in p.opcoes:
				erros.append("Atributo não pode aumentar: %s" % escolha)
			else:
				a.atributos[escolha] = int(a.atributos.get(escolha, 0)) + 1
				a.aumentos.append(escolha)
		"grau":
			var lista: Array = escolha
			if lista.size() != int(p.quantidade):
				erros.append("Escolha %d perícias" % int(p.quantidade))
			elif lista.any(func(x): return not x in p.opcoes):
				erros.append("Perícia não pode subir de grau agora")
			else:
				for per in lista:
					a.pericias[per] = a.ruleset.proximo_grau(a.pericias[per])
				a.graus_feitos += 1
	if erros.is_empty():
		a.recalcular_maximos()
	return erros
