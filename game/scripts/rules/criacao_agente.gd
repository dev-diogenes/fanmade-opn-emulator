class_name CriacaoAgente
extends RefCounted
## Cria um agente a partir de uma ficha, validando as regras de criação e
## progressão (cap. 1). Formato da ficha:
## {
##   "nome": "Bianca", "classe": "especialista", "origem": "investigador", "nex": 5,
##   "atributos": {"agi": 2, "for": 0, "int": 3, "pre": 3, "vig": 1},   # distribuição INICIAL
##   "aumentos_atributo": ["int"],          # um por marco (NEX 20/50/80/95)
##   "pericias_origem": [],                 # só para origens com escolha (Amnésico)
##   "pericias_classe": ["luta", "reflexos"],  # escolhas "X ou Y" da classe (Combatente)
##   "pericias_livres": [...],              # base da classe + Intelecto (+1 por sobreposição)
##   "perito": ["ciencias", "investigacao"],   # Especialista
##   "trilha": "medico_de_campo",           # obrigatória a partir de NEX 10%
##   "poderes": ["treinamento_em_pericia"], # um por marco (NEX 15/30/45…)
##   "versatilidade": "poder",              # NEX 50%: "poder" (a opção de trilha alheia é pendente)
##   "treinamentos": [["crime", "tatica"]], # um par por Treinamento em Perícia
##   "graus": [[...], [...]],               # perícias que sobem de grau em NEX 35% e 70%
##   "escolhas": {"ferramenta_de_trabalho": "machado"}
## }
## Simplificação: pré-requisitos de poderes são checados no estado final do agente,
## não no NEX em que cada poder foi escolhido.


## Retorna {"agente": Agente ou null, "erros": Array[String]}.
static func criar(ruleset: Ruleset, ficha: Dictionary) -> Dictionary:
	var erros: Array[String] = []
	var nex := int(ficha.get("nex", 5))
	var classe_id: String = ficha.get("classe", "")
	var origem_id: String = ficha.get("origem", "")
	if not ruleset.tem_classe(classe_id):
		return {"agente": null, "erros": ["Classe desconhecida: %s" % classe_id] as Array[String]}
	if not ruleset.tem_origem(origem_id):
		return {"agente": null, "erros": ["Origem desconhecida: %s" % origem_id] as Array[String]}
	var classe := ruleset.classe(classe_id)
	var origem := ruleset.origem(origem_id)

	# 1. Atributos iniciais + aumentos
	var atributos: Dictionary = ficha.get("atributos", {}).duplicate()
	erros.append_array(ruleset.validar_atributos_iniciais(atributos))
	var aumentos: Array = ficha.get("aumentos_atributo", [])
	var aumentos_esperados := ruleset.quantos_ate("aumento_atributo", nex)
	if aumentos.size() != aumentos_esperados:
		erros.append("NEX %d%% dá %d aumento(s) de atributo (recebeu %d)" % [nex, aumentos_esperados, aumentos.size()])
	var maximo := int(ruleset.dados.classes.progressao.atributo_maximo)
	for attr_id in aumentos:
		atributos[attr_id] = int(atributos.get(attr_id, 0)) + 1
		if atributos[attr_id] > maximo:
			erros.append("Aumento de atributo passa de %d em %s" % [maximo, attr_id])
	var intelecto := int(atributos.get("int", 0))

	# 2. Perícias: origem, classe e livres
	var pericias: Dictionary = {}
	var da_origem: Array = origem.pericias.duplicate()
	if int(origem.get("pericias_escolha", 0)) > 0:
		da_origem = ficha.get("pericias_origem", [])
		if da_origem.size() != int(origem.pericias_escolha):
			erros.append("A origem %s exige escolher %d perícias" % [origem.nome, int(origem.pericias_escolha)])
	var da_classe: Array = classe.get("pericias_fixas", []).duplicate()
	var escolhidas_classe: Array = ficha.get("pericias_classe", [])
	for par in classe.get("pericias_fixas_escolha", []):
		var feitas: Array = escolhidas_classe.filter(func(p): return p in par)
		if feitas.size() != 1:
			erros.append("Escolha exatamente uma entre %s" % " ou ".join(par))
		else:
			da_classe.append(feitas[0])
	var garantidas: Dictionary = {}
	for p in da_origem + da_classe:
		garantidas[p] = true
	var sobreposicao := da_origem.size() + da_classe.size() - garantidas.size()
	var livres: Array = ficha.get("pericias_livres", [])
	var livres_esperadas := int(classe.pericias_livres.base) + intelecto + sobreposicao
	if livres.size() != livres_esperadas:
		erros.append("Escolha %d perícias livres (recebeu %d)" % [livres_esperadas, livres.size()])
	for p in livres:
		if garantidas.has(p):
			erros.append("Perícia livre repetida: %s" % p)
		garantidas[p] = true
	for p in garantidas:
		if not ruleset.tem_pericia(p):
			erros.append("Perícia desconhecida: %s" % p)
		else:
			pericias[p] = "treinado"

	# 3. Trilha
	var trilha_id: String = ficha.get("trilha", "")
	if nex >= 10:
		if not ruleset.tem_trilha(classe_id, trilha_id):
			erros.append("A partir de NEX 10%% é preciso escolher uma trilha de %s" % classe.nome)
	elif trilha_id != "":
		erros.append("Trilha só é escolhida em NEX 10%")
		trilha_id = ""

	# 4. Poderes de classe
	var lista_poderes: Array = ficha.get("poderes", [])
	var poderes_esperados := ruleset.quantos_ate("poder", nex)
	if nex >= 50 and ficha.get("versatilidade", "") == "poder":
		poderes_esperados += 1
	if lista_poderes.size() != poderes_esperados:
		erros.append("NEX %d%% dá %d poder(es) de classe (recebeu %d)" % [nex, poderes_esperados, lista_poderes.size()])
	var vistos: Dictionary = {}
	for poder_id in lista_poderes:
		if not ruleset.tem_poder(classe_id, poder_id):
			erros.append("Poder desconhecido para %s: %s" % [classe.nome, poder_id])
			continue
		if vistos.has(poder_id) and not ruleset.poder(classe_id, poder_id).get("repetivel", false):
			erros.append("Poder não pode repetir: %s" % poder_id)
		vistos[poder_id] = true

	# 5. Treinamento em Perícia
	var treinamentos: Array = ficha.get("treinamentos", [])
	var qtd_treinamento := lista_poderes.count("treinamento_em_pericia")
	if treinamentos.size() != qtd_treinamento:
		erros.append("Informe %d par(es) de perícias para Treinamento em Perícia" % qtd_treinamento)
	for par in treinamentos:
		if par.size() != 2:
			erros.append("Treinamento em Perícia escolhe duas perícias")
			continue
		for p in par:
			var novo := _subir_grau(ruleset, pericias, p, nex, true)
			if novo == "":
				erros.append("Treinamento em Perícia não pode melhorar %s neste NEX" % p)

	# 6. Grau de Treinamento (NEX 35% e 70%)
	var graus: Array = ficha.get("graus", [])
	var marcos_grau := ruleset.quantos_ate("grau_treinamento", nex)
	var regra_grau: Dictionary = ruleset.dados.classes.grau_treinamento_qtd[classe_id]
	if graus.size() != marcos_grau:
		erros.append("NEX %d%% dá %d escolha(s) de Grau de Treinamento" % [nex, marcos_grau])
	for i in graus.size():
		var lista: Array = graus[i]
		var esperado := int(regra_grau.base) + int(atributos.get(regra_grau.soma_atributo, 0))
		if lista.size() != esperado:
			erros.append("Grau de Treinamento: escolha %d perícias (recebeu %d)" % [esperado, lista.size()])
		var nex_marco := int(ruleset.niveis_de("grau_treinamento")[i])
		for p in lista:
			if _subir_grau(ruleset, pericias, p, nex_marco, false) == "":
				erros.append("Grau de Treinamento não pode melhorar %s" % p)

	# 7. Perito (especialista)
	var lista_perito: Array = ficha.get("perito", [])
	var perito_info := ruleset.habilidade_classe("perito")
	if classe_id == perito_info.get("classe", ""):
		if lista_perito.size() != int(perito_info.quantidade_pericias):
			erros.append("Perito exige %d perícias" % int(perito_info.quantidade_pericias))
		for p in lista_perito:
			if p in perito_info.exceto or not pericias.has(p):
				erros.append("Perito precisa de perícia treinada (exceto ataques): %s" % p)
	elif not lista_perito.is_empty():
		erros.append("Só especialistas têm Perito")

	# Monta o agente para checar pré-requisitos no estado final
	var a := Agente.new()
	a.ruleset = ruleset
	a.nome = ficha.get("nome", "Agente")
	a.lado = "agentes"
	a.classe_id = classe_id
	a.origem_id = origem_id
	a.trilha_id = trilha_id
	a.nex = nex
	a.atributos = atributos
	a.pericias = pericias
	for p in lista_poderes:
		a.poderes.append(p)
	for p in lista_perito:
		a.perito.append(p)
	a.escolhas = ficha.get("escolhas", {}).duplicate()

	if trilha_id != "":
		erros.append_array(_checar_pre(ruleset.trilha(classe_id, trilha_id).get("pre", {}), a, "trilha " + trilha_id))
	for poder_id in vistos:
		erros.append_array(_checar_pre(ruleset.poder(classe_id, poder_id).get("pre", {}), a, "poder " + poder_id))
	for h in a.habilidades():
		if h.has("escolha") and not a.escolhas.has(h.id):
			erros.append("%s exige uma escolha (%s)" % [h.nome, h.escolha])

	if not erros.is_empty():
		return {"agente": null, "erros": erros}
	a.recalcular_maximos(true)
	return {"agente": a, "erros": erros}


## Sobe o grau de uma perícia. `pode_treinar`: aceita destreinado -> treinado.
## Veterano exige NEX 35%, expert exige NEX 70%. Retorna o novo grau ou "" se não puder.
static func _subir_grau(ruleset: Ruleset, pericias: Dictionary, pericia_id: String, nex: int, pode_treinar: bool) -> String:
	if not ruleset.tem_pericia(pericia_id):
		return ""
	var atual: String = pericias.get(pericia_id, "destreinado")
	if atual == "destreinado" and not pode_treinar:
		return ""
	var novo := ruleset.proximo_grau(atual)
	if novo == atual or (novo == "veterano" and nex < 35) or (novo == "expert" and nex < 70):
		return ""
	pericias[pericia_id] = novo
	return novo


static func _checar_pre(pre: Dictionary, a: Agente, nome: String) -> Array[String]:
	var erros: Array[String] = []
	for attr_id in pre.get("atributos", {}):
		if a.atributo(attr_id) < int(pre.atributos[attr_id]):
			erros.append("%s exige %s %d" % [nome, attr_id.to_upper(), int(pre.atributos[attr_id])])
	for p in pre.get("treinado", []):
		if not a.treinado_em(p):
			erros.append("%s exige treino em %s" % [nome, p])
	var algum: Array = pre.get("treinado_algum", [])
	if not algum.is_empty() and not algum.any(func(p): return a.treinado_em(p)):
		erros.append("%s exige treino em %s" % [nome, " ou ".join(algum)])
	if a.nex < int(pre.get("nex", 0)):
		erros.append("%s exige NEX %d%%" % [nome, int(pre.nex)])
	if pre.has("poder") and not pre.poder in a.poderes:
		erros.append("%s exige o poder %s" % [nome, pre.poder])
	return erros
