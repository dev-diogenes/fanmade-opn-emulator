class_name Agente
extends Ser
## Agente da Ordem controlado por um jogador.
## Para criar com validação completa (origem, classe, poderes, trilha), use CriacaoAgente.

var ruleset: Ruleset
var id := ""                     ## Identificador único na carreira (para salvar)
var classe_id := ""
var origem_id := ""
var trilha_id := ""
var nex := 5
var atributos: Dictionary = {}   ## {"agi": 2, "for": 1, ...} — já com aumentos e lesões
var pericias: Dictionary = {}    ## {"luta": "treinado", ...}
var poderes: Array[String] = []  ## Poderes de classe escolhidos (podem repetir se "repetivel")
var perito: Array[String] = []   ## Perícias da habilidade Perito (especialista)
var escolhas: Dictionary = {}    ## Escolhas de poderes, ex.: {"ferramenta_de_trabalho": "machado"}
var lesoes: Array[String] = []   ## Atributos perdidos por Lesões (regra opcional)
var idade := ""                  ## Faixa etária (regra opcional Idade Variada); "" = sem a regra
var desvantagens_idade: Array[String] = []
var trilha_versatil := ""        ## Versatilidade (NEX 50%): trilha alheia da qual recebe o 1º poder
var sem_poder_origem := false    ## Criança/adolescente que não escolheu o poder da origem
## Aparência (docs/19), só apresentação: modelo da miniatura e da foto ("" = o da classe)
## e tom da roupa (índice em Pecas.TONS). As regras não leem.
var aparencia := ""
var tom := 0
## Descrição da ficha oficial (docs/26), texto livre do jogador; as regras não leem.
var personalidade := ""
var historico := ""
var objetivo := ""
## Conceito e toques finais do livro (p.23-24 e p.46-47; docs/27): só apresentação.
var conceito := ""
var genero := ""
var idade_anos := 0        ## idade em anos (a faixa da regra opcional fica em `idade`)
var aparencia_texto := ""   ## a frase de aparência (o modelo da foto fica em `aparencia`)
## Ex-mundano (regra NEX 0%): bônus recebidos ao virar agente, ex.: {"pv": 12, "pe": 1, "san": 4}
var transicao_mundano: Dictionary = {}
var pp := 0                      ## Pontos de Prestígio (definem a patente)
var aumentos: Array[String] = [] ## Aumentos de atributo já feitos (NEX 20/50/80/95)
var graus_feitos := 0            ## Escolhas de Grau de Treinamento já feitas (NEX 35/70)
var versatilidade := ""          ## "", "poder" ou "trilha:<id>" (NEX 50%)
var rituais: Array[String] = []  ## Rituais conhecidos
## Poderes paranormais (Transcender, Cultista Arrependido): [{"id": ..., "escolha": ...}]
var poderes_paranormais: Array[Dictionary] = []
var afinidade := ""              ## Elemento de afinidade (NEX 50%, p.114)
var em_acao := false             ## Dentro de uma cena de ação (Encarar a Morte)
var _dano_massivo := false       ## Escapar da Morte não vale contra dano massivo
var san_perdida := 0             ## Sanidade máxima perdida para sempre (Custo do Paranormal, Medo)
var arma_id := ""                ## Arma empunhada ("" = desarmado)
var equipamento: Array[String] = []   ## Ids requisitados para a missão (armas, proteção, itens)
var pe := 0
var pe_temporario := 0           ## Gastos antes dos PE normais; somem no fim da cena
var pe_maximo := 0
var pe_gasto_no_turno := 0
var usos_na_cena: Dictionary = {}   ## habilidade_id -> vezes usada nesta cena


static func criar(p_ruleset: Ruleset, p_nome: String, p_classe: String, p_atributos: Dictionary, p_pericias: Dictionary = {}, p_nex: int = 5) -> Agente:
	var a := Agente.new()
	a.ruleset = p_ruleset
	a.nome = p_nome
	a.lado = "agentes"
	a.classe_id = p_classe
	a.atributos = p_atributos.duplicate()
	a.pericias = p_pericias.duplicate()
	a.nex = p_nex
	a.recalcular_maximos(true)
	return a


# --- Habilidades e efeitos -------------------------------------------------

## Todas as habilidades que o agente possui agora: poder da origem, poderes de classe
## e habilidades de trilha já alcançadas pelo NEX.
func habilidades() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for h in ruleset.classe(classe_id).get("habilidades", []):
		lista.append(h)
	if origem_id != "" and ruleset.tem_origem(origem_id) and not sem_poder_origem:
		lista.append(ruleset.origem(origem_id).poder)
	if idade != "" and ruleset.tem_faixa_idade(idade):
		lista.append(ruleset.faixa_idade(idade).habilidade)
	for dv in desvantagens_idade:
		if ruleset.tem_desvantagem_idade(dv):
			lista.append(ruleset.desvantagem_idade(dv))
	for poder_id in poderes:
		if ruleset.tem_poder(classe_id, poder_id):
			lista.append(ruleset.poder(classe_id, poder_id))
	if trilha_id != "" and ruleset.tem_trilha(classe_id, trilha_id):
		var hab: Dictionary = ruleset.trilha(classe_id, trilha_id).habilidades
		for nivel in hab:
			if int(nivel) <= nex:
				lista.append(hab[nivel])
	if trilha_versatil != "" and ruleset.tem_trilha(classe_id, trilha_versatil):
		lista.append(ruleset.trilha(classe_id, trilha_versatil).habilidades["10"])
	lista.append_array(_habilidades_paranormais())
	var mald := _habilidade_das_maldicoes()
	if not mald.is_empty():
		lista.append(mald)
	return lista


## Poderes paranormais viram habilidades; a 2ª escolha de um poder do elemento de afinidade
## soma o efeito "afinidade". "{escolha}" nos efeitos é trocado pela escolha do agente.
func _habilidades_paranormais() -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	var vistos: Dictionary = {}
	for entrada in poderes_paranormais:
		var p := ruleset.poder_paranormal(entrada.id)
		if p.is_empty():
			continue
		var escolha := String(entrada.get("escolha", ""))
		var h := {"id": p.id, "nome": p.nome, "implementado": p.get("implementado", false), "efeitos": _com_escolha(p.get("efeitos", []), escolha)}
		if vistos.has(p.id) and afinidade != "" and elemento_do_poder(entrada) == afinidade and p.has("afinidade"):
			h.id = p.id + "_afinidade"
			h.nome = p.nome + " (afinidade)"
			h.efeitos = _com_escolha(p.afinidade, escolha)
		vistos[p.id] = true
		lista.append(h)
		if p.id == "expansao_de_conhecimento" and escolha.contains(":"):
			var partes := escolha.split(":")
			if ruleset.tem_poder(partes[0], partes[1]):
				lista.append(ruleset.poder(partes[0], partes[1]))
	return lista


static func _com_escolha(efeitos_brutos: Array, escolha: String) -> Array:
	var lista: Array = []
	for e in efeitos_brutos:
		var c: Dictionary = e.duplicate()
		for k in c:
			if c[k] is String and c[k] == "{escolha}":
				c[k] = escolha
		lista.append(c)
	return lista


## Elemento que o poder paranormal conta (Aprender Ritual: o do ritual; Resistir: o escolhido).
func elemento_do_poder(entrada: Dictionary) -> String:
	var p := ruleset.poder_paranormal(entrada.id)
	match String(p.get("elemento", "")):
		"ritual":
			return ruleset.ritual(entrada.get("escolha", "")).get("elemento", "")
		"escolha":
			return entrada.get("escolha", "")
	return p.get("elemento", "")


func contagem_elemento(elemento: String) -> int:
	return poderes_paranormais.filter(func(e): return elemento_do_poder(e) == elemento).size()


## Maldições dos itens em uso (arma empunhada, proteção vestida e acessórios) como uma
## habilidade. Bônus de itens amaldiçoados não acumulam entre si: vale o maior (p.155).
func _habilidade_das_maldicoes() -> Dictionary:
	var melhores: Dictionary = {}
	for m in maldicoes_em_uso():
		if not m.get("implementado", false):
			continue
		for e in m.get("efeitos", []):
			var chave := "%s|%s|%s|%s" % [e.tipo, e.get("atributo", ""), e.get("pericia", ""), e.get("dano", "")]
			if not melhores.has(chave) or int(e.get("valor", 0)) > int(melhores[chave].get("valor", 0)):
				melhores[chave] = e
	if melhores.is_empty():
		return {}
	return {"id": "maldicoes", "nome": "Itens amaldiçoados", "implementado": true, "efeitos": melhores.values()}


## Maldições ativas: da arma empunhada, da proteção e dos acessórios equipados.
func maldicoes_em_uso() -> Array:
	var lista: Array = []
	for item_id in equipamento:
		var e := ruleset.equipamento(item_id)
		if not e.has("maldicoes"):
			continue
		if e.tipo == "arma" and item_id != arma_id:
			continue
		lista.append_array(e.maldicoes)
	return lista


## Preço da maldição (p.155): falhar num teste do atributo ligado ao elemento custa 2 SAN
## por maldição desse elemento nos itens em uso.
func pagar_preco_da_maldicao(atributo_base: String) -> int:
	var cfg := ruleset.cfg_maldicoes()
	var total := 0
	for m in maldicoes_em_uso():
		if atributo_base in cfg.get("atributo_do_preco", {}).get(m.elemento, []):
			total += int(cfg.get("preco_san", 2))
	if total > 0:
		perder_sanidade(total)
	return total


func tem_habilidade(habilidade_id: String) -> bool:
	var hs := habilidades()
	if hs.any(func(h): return h.id == habilidade_id):
		return true
	for h in hs:
		for e in h.get("efeitos", []):
			if e.tipo == "concede_habilidade" and e.habilidade == habilidade_id:
				return true
	return false


## Efeitos implementados de um tipo, vindos de todas as habilidades.
func efeitos(tipo: String) -> Array[Dictionary]:
	var lista: Array[Dictionary] = []
	for h in habilidades():
		if not h.get("implementado", false):
			continue
		for e in h.get("efeitos", []):
			if e.tipo == tipo:
				var copia: Dictionary = e.duplicate()
				copia["_habilidade"] = h.id
				lista.append(copia)
	return lista


func _soma_efeitos(tipo: String, filtro: Callable = func(_e): return true) -> int:
	var total := 0
	for e in efeitos(tipo):
		if filtro.call(e):
			total += int(e.get("valor", 0))
	return total


# --- Características derivadas --------------------------------------------

## Recalcula PV/PE/SAN máximos (após NEX ou atributo mudar). `encher` restaura os valores atuais.
func recalcular_maximos(encher: bool = false) -> void:
	var niveis := ruleset.niveis_de_exposicao(nex)
	if transicao_mundano.is_empty():
		pv_maximo = ruleset.pv_max(classe_id, nex, atributos)
		pe_maximo = ruleset.pe_max(classe_id, nex, atributos)
		san_maximo = ruleset.san_max(classe_id, nex, atributos)
	else:
		# Ex-mundano (p.182): base do Mundano + bônus da promoção + progressão da nova classe.
		var m := ruleset.classe("mundano")
		var c := ruleset.classe(classe_id)
		var vig := int(atributos.get("vig", 0))
		var pre := int(atributos.get("pre", 0))
		pv_maximo = int(m.pv.inicial) + vig + int(transicao_mundano.pv) + (niveis - 1) * (int(c.pv.por_nex) + vig)
		pe_maximo = int(m.pe.inicial) + pre + int(transicao_mundano.pe) + (niveis - 1) * (int(c.pe.por_nex) + pre)
		san_maximo = int(m.san.inicial) + int(transicao_mundano.san) + (niveis - 1) * int(c.san.por_nex)
	pv_maximo += _soma_efeitos("pv_por_nex") * niveis
	pe_maximo += _soma_efeitos("pe_por_nex") * niveis + _soma_efeitos("pe_fixo")
	if not efeitos("pe_dedicacao").is_empty():
		pe_maximo += 1 + (niveis - 1) / 2   # +1 PE, e +1 a cada NEX "ímpar" (15%, 25%…)
	san_maximo += _soma_efeitos("san_por_nex") * niveis
	san_maximo -= san_perdida
	if not efeitos("san_inicial_metade").is_empty():
		san_maximo -= int(ruleset.classe(classe_id).san.inicial) / 2
	pv_maximo += _soma_efeitos("pv_fixo")
	# Transcender: não recebe a Sanidade daquele NEX (p.114)
	if classe_id != "mundano" and ruleset.tem_classe(classe_id):
		san_maximo -= poderes.count("transcender") * int(ruleset.classe(classe_id).san.get("por_nex", 0))
	pv_maximo = maxi(1, pv_maximo)
	pe_maximo = maxi(0, pe_maximo)
	if encher:
		pv = pv_maximo
		pe = pe_maximo
		san = san_maximo
	else:
		pv = mini(pv, pv_maximo)
		pe = mini(pe, pe_maximo)
		san = mini(san, san_maximo)


func atributo(atributo_id: String) -> int:
	var v := int(atributos.get(atributo_id, 0)) + int(mods_cena.get("atributos", {}).get(atributo_id, 0)) + efeito_ritual("atributo_" + atributo_id)
	v += _soma_efeitos("atributo_item", func(e): return e.atributo == atributo_id)
	if tem(Ser.MACHUCADO) and atributo_id in ["for", "agi"]:
		var maior := "for" if int(atributos.get("for", 0)) >= int(atributos.get("agi", 0)) else "agi"
		if atributo_id == maior:
			v += _soma_efeitos("sangue_fervente")   # Sangue Fervente (p.116)
	return v


func dados_da_pericia(pericia_id: String) -> int:
	var attr_base := ruleset.atributo_da_pericia(pericia_id)
	var d := atributo(attr_base) - penalidade_dados_atributo(attr_base)
	var prot := protecao()
	if not prot.is_empty() and attr_base in ["for", "agi"] and not tem_proficiencia(prot.get("proficiencia", "")):
		d -= 2   # proteção sem proficiência: −2 dados em Força e Agilidade (p.72)
	if pericia_id == "reflexos" and (tem(Ser.DESPREVENIDO) or tem(Ser.SURPREENDIDO)):
		d -= 1   # desprevenido: −1 dado em Reflexos (p.320)
	return d


func grau(pericia_id: String) -> String:
	return pericias.get(pericia_id, "destreinado")


func treinado_em(pericia_id: String) -> bool:
	return grau(pericia_id) != "destreinado"


## Bônus total numa perícia. `grau_usado` sobrescreve o grau (Eclético, Engenhosidade).
func bonus_pericia(pericia_id: String, grau_usado: String = "") -> int:
	var bonus := ruleset.bonus_grau(grau_usado if grau_usado != "" else grau(pericia_id))
	bonus += _soma_efeitos("bonus_pericia", func(e): return e.pericia == pericia_id)
	var attr := ruleset.atributo_da_pericia(pericia_id)
	bonus += _soma_efeitos("bonus_pericia_por_atributo", func(e): return e.atributo == attr and not pericia_id in e.get("exceto", []))
	if pericia_id == "furtividade":
		for e in efeitos("tamanho_pequeno"):
			bonus += int(e.get("furtividade", 0))
	if ruleset.eh_teste_de_resistencia(pericia_id):
		bonus += bonus_testes_resistencia()
	bonus += _bonus_de_equipamento(pericia_id)
	bonus += efeito_ritual("pericias")   # Coincidência Forçada
	return bonus


## Itens (p.63, p.73): bônus de itens não acumulam (vale o maior); kit faltando dá −5;
## proteção pesada e sobrecarga pesam nas perícias de carga.
func _bonus_de_equipamento(pericia_id: String) -> int:
	var info := ruleset.pericia(pericia_id)
	var total := 0
	var melhor_item := 0
	for item_id in equipamento:
		var e := ruleset.equipamento(item_id)
		melhor_item = maxi(melhor_item, int(e.get("bonus_pericia", {}).get(pericia_id, 0)))
	total += melhor_item
	if info.get("kit", false) and not equipamento.any(func(i): return ruleset.equipamento(i).get("kit", "") == pericia_id):
		total += int(ruleset.dados.pericias.get("penalidade_sem_kit", -5))
	if info.get("carga", false):
		total += int(protecao().get("penalidade_carga", 0))
		if sobrecarregado():
			total += int(ruleset.regra_carga().get("sobrecarga", {}).get("pericias_de_carga", 0))
	return total


func bonus_testes_resistencia() -> int:
	return super.bonus_testes_resistencia() + _soma_efeitos("bonus_testes_resistencia")


## Bônus extra em testes de resistência contra efeitos paranormais (Mente Sã).
func bonus_resistencia_paranormal() -> int:
	return _soma_efeitos("bonus_resistencia_paranormal")


## DT para resistir às habilidades do agente: 10 + limite de PE + atributo (p.88).
## O bônus de limite da Dedicação não conta para DT.
func dt_habilidade(atributo_id: String) -> int:
	return 10 + ruleset.limite_pe(nex) + atributo(atributo_id) + _soma_efeitos("dt_bonus")


## Deslocamento: 9 m, ou o fixado por efeitos (criança: 6 m), mais modificadores ("Devagar, Jovem!").
func deslocamento_m() -> float:
	var base := 9.0
	for e in efeitos("deslocamento"):
		base = float(e.valor)
	for e in efeitos("deslocamento_mod"):
		base += float(e.valor)
	if sobrecarregado():
		base += float(ruleset.regra_carga().get("sobrecarga", {}).get("deslocamento_m", 0))
	return maxf(1.5, base)


# --- Rituais (cap. 5) -----------------------------------------------------------

func conhece_ritual(ritual_id: String) -> bool:
	return ritual_id in rituais


func circulo_maximo() -> int:
	return ruleset.circulo_maximo(nex)


## Limite de PE para conjurar: Presença Poderosa (Intuitivo 40%) soma a Presença.
func limite_pe_rituais() -> int:
	var l := limite_pe()
	if tem_habilidade("presenca_poderosa"):
		l += atributo("pre")
	return l


## Custo do ritual (com forma), aplicadas as reduções de poderes. Mínimo 1 PE.
func custo_ritual(ritual_id: String, forma: String = "") -> int:
	var r := ruleset.ritual(ritual_id)
	var custo := ruleset.custo_base_ritual(int(r.circulo))
	if forma != "":
		custo += int(r.get("formas", {}).get(forma, {}).get("custo", 0))
	if tem_habilidade("mestre_em_elemento") and escolhas.get("especialista_em_elemento", "") == r.elemento:
		custo -= 1
	if tem_habilidade("ritual_predileto") and escolhas.get("ritual_predileto", "") == ritual_id:
		custo -= 1
	if tem_habilidade("tatuagem_ritualistica") and String(r.get("alcance", "")).begins_with("pessoal"):
		custo -= 1
	return maxi(1, custo)


## DT para resistir aos rituais: DT de habilidade com Presença (p.131) e bônus de poderes.
func dt_ritual(ritual_id: String) -> int:
	var r := ruleset.ritual(ritual_id)
	var dt := dt_habilidade("pre")
	if tem_habilidade("especialista_em_elemento") and escolhas.get("especialista_em_elemento", "") == r.elemento:
		dt += 2
	if tem_habilidade("rituais_eficientes"):
		dt += 5
	return dt


## Bônus de Ritual Potente (somar Intelecto em dano e cura de rituais).
func bonus_ritual_potente() -> int:
	return atributo("int") if tem_habilidade("ritual_potente") else 0


## Quantos rituais o agente deveria conhecer pela classe (ocultista: 3 + 1 por NEX acima de 5%;
## Graduado: +1 por círculo acessível). Outras classes aprendem por poderes (pendente).
func rituais_esperados() -> int:
	if classe_id != "ocultista":
		return 0
	var hab := ruleset.habilidade_classe("escolhido_pelo_outro_lado")
	var total := int(hab.get("rituais_iniciais", 3)) + ruleset.niveis_de_exposicao(nex) - 1
	if trilha_id == "graduado" and nex >= 10:
		total += circulo_maximo()
	return total


# --- Equipamento e patente --------------------------------------------------

func patente() -> Dictionary:
	return ruleset.patente_por_pp(pp)


## Arma empunhada (ou ataque desarmado).
func arma() -> Dictionary:
	if arma_id != "" and arma_id in equipamento:
		var e := ruleset.equipamento(arma_id)
		if e.get("tipo", "") == "arma":
			return e
	return ruleset.arma("desarmado")


func protecao() -> Dictionary:
	for item_id in equipamento:
		var e := ruleset.equipamento(item_id)
		if e.get("tipo", "") == "protecao":
			return e
	return {}


## Espaços de carga: 5 por ponto de Força (2 com Força 0), p.63.
func capacidade_carga() -> int:
	var regra := ruleset.regra_carga()
	var forca := atributo("for")
	for e in efeitos("carga_soma_atributo"):
		forca += atributo(e.atributo)
	return int(regra.get("espacos_com_forca_zero", 2)) if forca <= 0 else forca * int(regra.get("espacos_por_forca", 5))


func espacos_usados() -> int:
	var total := 0
	for item_id in equipamento:
		total += int(ruleset.equipamento(item_id).get("espacos", 1))
	return total


func sobrecarregado() -> bool:
	return espacos_usados() > capacidade_carga()


func tem_item(item_id: String) -> bool:
	return item_id in equipamento


## Gasta um item consumível (remove uma unidade do equipamento).
func consumir_item(item_id: String) -> bool:
	if not tem_item(item_id) or not ruleset.equipamento(item_id).get("consumivel", false):
		return false
	equipamento.erase(item_id)
	return true


## Erros de uma requisição de equipamento para a patente atual (p.61-63).
func validar_equipamento(lista: Array) -> Array[String]:
	var erros: Array[String] = []
	var limites: Dictionary = patente().get("itens_por_categoria", {})
	var por_categoria: Dictionary = {}
	var espacos := 0
	var protecoes := 0
	for item_id in lista:
		var e := ruleset.equipamento(item_id)
		if e.is_empty():
			erros.append("Item desconhecido: %s" % item_id)
			continue
		var cat := int(e.get("categoria", 0))
		if cat > 0:
			por_categoria[cat] = int(por_categoria.get(cat, 0)) + 1
		espacos += int(e.get("espacos", 1))
		if e.tipo == "protecao":
			protecoes += 1
		if e.has("maldicoes") and pp < int(ruleset.cfg_maldicoes().get("patente_minima_pp", 50)):
			erros.append("Itens amaldiçoados só são liberados a partir de Agente Especial: %s" % e.nome)
	for cat in por_categoria:
		var limite := int(limites.get(str(cat), 0))
		if por_categoria[cat] > limite:
			erros.append("A patente %s libera %d item(ns) de categoria %s (pediu %d)" % [patente().get("nome", "?"), limite, ["0", "I", "II", "III", "IV"][cat], por_categoria[cat]])
	if protecoes > 1:
		erros.append("Só dá para vestir uma proteção")
	var maximo := capacidade_carga() * int(ruleset.regra_carga().get("maximo_multiplicador", 2))
	if espacos > maximo:
		erros.append("Carga máxima é %d espaços (pediu %d)" % [maximo, espacos])
	return erros


# --- Salvar / carregar ------------------------------------------------------

func para_dicionario() -> Dictionary:
	return {
		"id": id, "aumentos": Array(aumentos), "graus_feitos": graus_feitos, "versatilidade": versatilidade,
		"nome": nome, "classe": classe_id, "origem": origem_id, "trilha": trilha_id, "nex": nex,
		"atributos": atributos.duplicate(), "pericias": pericias.duplicate(),
		"poderes": Array(poderes), "perito": Array(perito), "escolhas": escolhas.duplicate(),
		"lesoes": Array(lesoes), "idade": idade, "desvantagens_idade": Array(desvantagens_idade),
		"trilha_versatil": trilha_versatil, "sem_poder_origem": sem_poder_origem,
		"transicao_mundano": transicao_mundano.duplicate(),
		"pp": pp, "arma": arma_id, "equipamento": Array(equipamento),
		"rituais": Array(rituais), "san_perdida": san_perdida,
		"poderes_paranormais": poderes_paranormais.duplicate(true), "afinidade": afinidade,
		"pv": pv, "pe": pe, "san": san, "condicoes": condicoes.keys(),
		"aparencia": aparencia, "tom": tom,
		"personalidade": personalidade, "historico": historico, "objetivo": objetivo,
		"conceito": conceito, "genero": genero, "idade_anos": idade_anos, "aparencia_texto": aparencia_texto,
	}


static func de_dicionario(p_ruleset: Ruleset, d: Dictionary) -> Agente:
	var a := Agente.new()
	a.ruleset = p_ruleset
	a.lado = "agentes"
	a.nome = d.get("nome", "Agente")
	a.id = d.get("id", "")
	for x in d.get("aumentos", []):
		a.aumentos.append(x)
	a.graus_feitos = int(d.get("graus_feitos", 0))
	a.versatilidade = d.get("versatilidade", "")
	a.classe_id = d.get("classe", "combatente")
	a.origem_id = d.get("origem", "")
	a.trilha_id = d.get("trilha", "")
	a.nex = int(d.get("nex", 5))
	for k in d.get("atributos", {}):
		a.atributos[k] = int(d.atributos[k])
	a.pericias = d.get("pericias", {}).duplicate()
	for x in d.get("poderes", []):
		a.poderes.append(x)
	for x in d.get("perito", []):
		a.perito.append(x)
	a.escolhas = d.get("escolhas", {}).duplicate()
	for x in d.get("lesoes", []):
		a.lesoes.append(x)
	a.idade = d.get("idade", "")
	for x in d.get("desvantagens_idade", []):
		a.desvantagens_idade.append(x)
	a.trilha_versatil = d.get("trilha_versatil", "")
	a.sem_poder_origem = d.get("sem_poder_origem", false)
	var trans: Dictionary = d.get("transicao_mundano", {})
	for k in trans:
		a.transicao_mundano[k] = int(trans[k])
	a.pp = int(d.get("pp", 0))
	for x in d.get("rituais", []):
		a.rituais.append(x)
	a.san_perdida = int(d.get("san_perdida", 0))
	for x in d.get("poderes_paranormais", []):
		a.poderes_paranormais.append(x)
	a.afinidade = d.get("afinidade", "")
	a.aparencia = String(d.get("aparencia", ""))
	a.tom = int(d.get("tom", 0))
	a.personalidade = String(d.get("personalidade", ""))
	a.historico = String(d.get("historico", ""))
	a.objetivo = String(d.get("objetivo", ""))
	a.conceito = String(d.get("conceito", ""))
	a.genero = String(d.get("genero", ""))
	a.idade_anos = int(d.get("idade_anos", 0))
	a.aparencia_texto = String(d.get("aparencia_texto", ""))
	a.arma_id = d.get("arma", "")
	for x in d.get("equipamento", []):
		a.equipamento.append(x)
	a.recalcular_maximos(true)
	a.pv = int(d.get("pv", a.pv_maximo))
	a.pe = int(d.get("pe", a.pe_maximo))
	a.san = int(d.get("san", a.san_maximo))
	for c in d.get("condicoes", []):
		a.condicoes[c] = true
	return a


func pode_usar_pericia(pericia_id: String) -> bool:
	return not ruleset.pericia(pericia_id).somente_treinada or treinado_em(pericia_id)


func defesa() -> int:
	var d := ruleset.defesa_base(atributos) + _soma_efeitos("bonus_defesa") + ajustes_de_defesa()
	# Armadura de Sangue não acumula com proteção: vale a maior (p.135)
	d += maxi(int(protecao().get("defesa", 0)), efeito_ritual("defesa_ritual"))
	if sobrecarregado():
		d += int(ruleset.regra_carga().get("sobrecarga", {}).get("defesa", 0))
	if tem(Ser.MACHUCADO) and tem_habilidade("inquebravel"):
		d += 5
	if not efeitos("imune_desprevenido").is_empty() and (tem(Ser.DESPREVENIDO) or tem(Ser.SURPREENDIDO)) and not esta_indefeso():
		d += 5   # Precognição com afinidade
	return d


func resistencia(tipo_dano: String) -> int:
	var total := super.resistencia(tipo_dano)
	for e in efeitos("resistencia"):
		if e.dano == tipo_dano:
			total += atributo(e.atributo) if e.has("atributo") else int(e.get("valor", 0))
	if tem(Ser.MACHUCADO) and tem_habilidade("inquebravel"):
		total += 5   # Inquebrável: RD 5 contra qualquer dano enquanto machucado
	total += int(protecao().get("resistencias", {}).get(tipo_dano, 0))
	for e in efeitos("resistencia_todas"):
		total += int(e.get("valor_pesada", e.valor)) if protecao().get("id", "") == "protecao_pesada" or protecao().get("base", "") == "protecao_pesada" else int(e.valor)
	return total


## Escapar da Morte (p.115): uma vez por cena, um dano que o deixaria a 0 PV o deixa com 1
## (com afinidade, evita o dano todo). Não funciona contra dano massivo.
func sofrer_dano(quantidade: int) -> void:
	var antes := pv
	super.sofrer_dano(quantidade)
	if pv == 0 and antes > 0 and not _dano_massivo and tem_habilidade("escapar_da_morte") and not usos_na_cena.has("escapar_da_morte"):
		usos_na_cena["escapar_da_morte"] = 1
		pv = antes if tem_habilidade("escapar_da_morte_afinidade") else 1
		condicoes.erase(Ser.INCONSCIENTE)
		condicoes.erase(Ser.MORRENDO)
		_atualizar_pv()


## Inquebrável (Tropa de Choque 99%): morrendo, o agente não cai inconsciente.
func _atualizar_pv() -> void:
	super._atualizar_pv()
	if pv == 0 and tem_habilidade("inquebravel"):
		condicoes.erase(Ser.INCONSCIENTE)


func tem_proficiencia(prof: String) -> bool:
	if prof in ruleset.classe(classe_id).get("proficiencias", []):
		return true
	return efeitos("proficiencia").any(func(e): return e.valor == prof)


# --- PE --------------------------------------------------------------------

func limite_pe() -> int:
	var l := ruleset.limite_pe(nex) + _soma_efeitos("limite_pe")
	if em_acao:
		l += _soma_efeitos("limite_pe_acao")   # Encarar a Morte
	return l


## PE que ainda podem ser gastos neste turno (PE temporários contam).
func pe_disponivel_no_turno() -> int:
	return mini(pe + pe_temporario, limite_pe() - pe_gasto_no_turno)


## `habilidade_no_minimo`: o gasto é UMA habilidade no seu custo mínimo. Nesse caso,
## o primeiro gasto do turno pode passar do limite (p.33: "sempre pode usar pelo menos
## uma habilidade em seu custo mínimo por turno").
func pode_gastar_pe(quantidade: int, habilidade_no_minimo: bool = false) -> bool:
	if quantidade == 0:
		return true   # nada a gastar (mesmo que o limite do turno já tenha sido passado)
	if quantidade < 0 or quantidade > pe + pe_temporario:
		return false
	if habilidade_no_minimo and pe_gasto_no_turno == 0:
		return true
	return quantidade <= pe_disponivel_no_turno()


func gastar_pe(quantidade: int, habilidade_no_minimo: bool = false) -> bool:
	if not pode_gastar_pe(quantidade, habilidade_no_minimo):
		return false
	var do_temporario := mini(pe_temporario, quantidade)
	pe_temporario -= do_temporario
	pe -= quantidade - do_temporario
	pe_gasto_no_turno += quantidade
	return true


func recuperar_pe(quantidade: int) -> void:
	pe = mini(pe_maximo, pe + maxi(0, quantidade))


func iniciar_turno() -> void:
	pe_gasto_no_turno = 0
	super.iniciar_turno()


func ganhar_pe_temporario(quantidade: int) -> void:
	pe_temporario += maxi(0, quantidade)


func encerrar_cena() -> void:
	usos_na_cena.clear()
	pe_temporario = 0
	em_acao = false
	super.encerrar_cena()


# --- Testes ----------------------------------------------------------------

## Teste de perícia.
## - `pe_foco`: PE gastos como Foco, cada um soma +1 d20 (brainstorm §2).
## - `opcoes`:
##     "habilidades": [ids]  — poderes "gasto_pe_bonus_teste" a ativar (Saber é Poder, 110%…)
##     "contexto": String    — ex.: "procurar_pistas", "teste_estendido"
##     "ecletico": true      — Eclético: testa como treinado (2 PE)
##     "engenhosidade": "veterano"|"expert" — junto com Eclético
##     "perito": true        — Perito: soma o dado do nível atual (PE conforme o NEX)
##     "dados_extras": int, "bonus_extra": int
##     "atributo_base": "for"|"agi"|...  — troca o atributo-base (Incansável, Presteza Atlética)
##     "conhecimento_aplicado": true      — poder do especialista: usa Intelecto (2 PE)
## Todo o PE é verificado antes (tudo ou nada). Retorna null se o teste não puder ser feito.
func testar(dados: Dados, pericia_id: String, dt: int, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoTeste:
	var plano := _planejar_teste(pericia_id, pe_foco, opcoes)
	if plano.is_empty() or not gastar_pe(plano.custo, _uma_habilidade_no_minimo(plano, pe_foco)):
		return null
	for hab_id in plano.usos:
		usos_na_cena[hab_id] = int(usos_na_cena.get(hab_id, 0)) + 1
	var bonus: int = bonus_pericia(pericia_id, plano.grau) + plano.bonus
	var reserva := dados_da_pericia(pericia_id)
	if plano.atributo_base != "":
		reserva = atributo(plano.atributo_base)
	var r := Teste.rolar(dados, reserva, bonus, dt, int(opcoes.get("dados_extras", 0)) + pe_foco)
	if plano.dado_perito != "":
		var extra := dados.rolar_expressao(plano.dado_perito)
		r.dados_bonus.append(extra)
		r.somar_bonus(extra)
	if pericia_id == "reflexos" and esta_indefeso():
		r.sucesso = false   # indefeso falha automaticamente em Reflexos (p.320)
	# Percepção Paranormal: ao procurar pistas, sem nenhum dado acima de 9, rola de novo o pior
	if opcoes.get("contexto", "") == "procurar_pistas" and r.escolhido < 10 and not r.usa_pior:
		var n := _soma_efeitos("rerrolar_procurar_pistas")
		if n > 0:
			Teste.rerrolar_piores(dados, r, n)
	sofrer_dano_por_teste(dados, ruleset.atributo_da_pericia(pericia_id))
	if not r.sucesso:
		pagar_preco_da_maldicao(plano.atributo_base if plano.atributo_base != "" else ruleset.atributo_da_pericia(pericia_id))
	return r


## Previsão de um teste de perícia, com as contas de `testar` mas sem gastar PE nem rolar
## (docs/21, C2): {"chance": 0..1, "dados": reserva de d20, "bonus": total}. O dado do Perito
## e as rerrolagens ficam de fora: a chance é um piso. Sem poder usar a perícia, chance 0.
func prever_teste(pericia_id: String, dt: int, pe_foco: int = 0, opcoes: Dictionary = {}) -> Dictionary:
	if not pode_usar_pericia(pericia_id):
		return {"chance": 0.0, "dados": 0, "bonus": 0, "exige_treino": true}
	var plano := _planejar_teste(pericia_id, pe_foco, opcoes)
	if plano.is_empty():
		return {"chance": 0.0, "dados": 0, "bonus": 0}
	var bonus: int = bonus_pericia(pericia_id, plano.grau) + int(plano.bonus)
	var reserva := dados_da_pericia(pericia_id)
	if plano.atributo_base != "":
		reserva = atributo(plano.atributo_base)
	var extras := int(opcoes.get("dados_extras", 0)) + pe_foco
	return {"chance": Teste.chance_de_passar(reserva, bonus, dt, extras), "dados": reserva + extras, "bonus": bonus}


## Gota / Pulmão Ruim: dano ao testar certos atributos (ou ao se esquivar).
func sofrer_dano_por_teste(dados: Dados, atributo_id: String, eh_esquiva: bool = false) -> void:
	for e in efeitos("dano_ao_testar"):
		if atributo_id in e.atributos or (eh_esquiva and e.get("inclui_esquiva", false)):
			sofrer_dano(dados.rolar_expressao(e.dano))


## Custo total em PE das opções de um teste, ou -1 se alguma opção for inválida (para a UI).
func custo_do_teste(pericia_id: String, pe_foco: int = 0, opcoes: Dictionary = {}) -> int:
	var plano := _planejar_teste(pericia_id, pe_foco, opcoes)
	return -1 if plano.is_empty() else int(plano.custo)


func _planejar_teste(pericia_id: String, pe_foco: int, opcoes: Dictionary) -> Dictionary:
	var plano := {"custo": pe_foco, "bonus": int(opcoes.get("bonus_extra", 0)), "grau": grau(pericia_id), "dado_perito": "", "usos": [],
		"fontes": 0, "no_minimo": true, "atributo_base": String(opcoes.get("atributo_base", ""))}
	if opcoes.get("conhecimento_aplicado", false):
		if not tem_habilidade("conhecimento_aplicado") or pericia_id in ["luta", "pontaria"]:
			return {}
		plano.custo += 2
		plano.fontes += 1
		plano.atributo_base = "int"
	var info := ruleset.pericia(pericia_id)
	# Eclético (+ Engenhosidade)
	if opcoes.get("ecletico", false):
		var ecl := ruleset.habilidade_classe("ecletico")
		if classe_id != ecl.get("classe", ""):
			return {}
		plano.custo += int(ecl.custo)
		plano.fontes += 1
		var alvo_grau := "treinado"
		var eng_pedida: String = opcoes.get("engenhosidade", "")
		if eng_pedida != "":
			var eng := ruleset.habilidade_classe("engenhosidade")
			var nivel: Dictionary = {}
			for n in eng.niveis:
				if n.grau == eng_pedida and int(n.nex) <= nex:
					nivel = n
			if nivel.is_empty():
				return {}
			plano.custo += int(nivel.custo_extra)
			plano.no_minimo = false
			alvo_grau = eng_pedida
		if ruleset.bonus_grau(alvo_grau) > ruleset.bonus_grau(plano.grau):
			plano.grau = alvo_grau
	elif info.somente_treinada and plano.grau == "destreinado":
		return {}
	# Perito
	if opcoes.get("perito", false):
		var per := ruleset.habilidade_classe("perito")
		if classe_id != per.get("classe", "") or not pericia_id in perito:
			return {}
		var nivel := ruleset.nivel_alcancado(per.niveis, nex)
		plano.custo += int(nivel.custo)
		plano.dado_perito = nivel.dado
		plano.fontes += 1
		if int(nivel.custo) > int(per.niveis[0].custo):
			plano.no_minimo = false
	# Poderes de origem/classe do tipo "gasto PE -> bônus no teste"
	var pedidas: Array = opcoes.get("habilidades", [])
	for e in efeitos("gasto_pe_bonus_teste"):
		if not e._habilidade in pedidas:
			continue
		if not _efeito_se_aplica(e, pericia_id, opcoes.get("contexto", "")):
			return {}
		plano.custo += int(e.custo)
		plano.bonus += int(e.bonus)
		plano.usos.append(e._habilidade)
		plano.fontes += 1
	for hab_id in pedidas:
		if not hab_id in plano.usos:
			return {}  # habilidade pedida que o agente não tem (ou não é desse tipo)
	return plano


func _uma_habilidade_no_minimo(plano: Dictionary, pe_foco: int) -> bool:
	return pe_foco == 0 and int(plano.fontes) == 1 and plano.no_minimo


func _efeito_se_aplica(e: Dictionary, pericia_id: String, contexto: String) -> bool:
	if e.has("atributos") and not ruleset.atributo_da_pericia(pericia_id) in e.atributos:
		return false
	if e.has("pericias") and not pericia_id in e.pericias:
		return false
	if pericia_id in e.get("exceto", []):
		return false
	if e.has("contextos") and not contexto in e.contextos:
		return false
	if e.get("uso", "") == "cena" and int(usos_na_cena.get(e._habilidade, 0)) >= 1:
		return false
	return true


# --- Ataques ---------------------------------------------------------------

func modificar_ataque(arma: Dictionary, alvo: Ser) -> Dictionary:
	var mods := super.modificar_ataque(arma, alvo)
	var tipo_ataque: String = arma.get("ataque", "corpo_a_corpo")
	var aplica := func(e): return tipo_ataque in e.get("ataques", [])
	mods.bonus_dano += _soma_efeitos("bonus_dano", aplica)
	mods.margem += _soma_efeitos("margem_ameaca", aplica)
	var atributos_somados: Dictionary = {}   # o mesmo atributo só soma uma vez (p.322)
	for e in efeitos("bonus_dano_atributo"):
		var por_ataque: bool = e.has("ataques") and aplica.call(e)
		var por_municao: bool = e.has("municao") and arma.get("municao", "") == e.municao
		if (por_ataque or por_municao) and not atributos_somados.has(e.atributo):
			atributos_somados[e.atributo] = true
			mods.bonus_dano += atributo(e.atributo)
	for e in efeitos("dado_dano_extra"):
		if aplica.call(e):
			mods.dados_dano_extra += 1
	for e in efeitos("arma_preferida"):
		if escolhas.get(e._habilidade, "") == arma.get("id", ""):
			mods.bonus_ataque += int(e.ataque)
			mods.bonus_dano += int(e.dano)
			mods.margem += int(e.margem)
	return mods


## Arma ajustada por poderes (ex.: Artista Marcial muda o ataque desarmado).
func arma_efetiva(arma: Dictionary) -> Dictionary:
	if arma.get("id", "") == "desarmado" and not efeitos("artista_marcial").is_empty():
		var a := arma.duplicate()
		a.dano = "1d10" if nex >= 70 else ("1d8" if nex >= 35 else "1d6")
		a.nao_letal = false
		return a
	return arma


## Custo e bônus do Ataque Especial (combatente) para `bonus_ataque` + `bonus_dano`.
## Retorna {} se inválido (não é combatente, não é múltiplo de 5 ou acima do nível do NEX).
func plano_ataque_especial(bonus_ataque: int, bonus_dano: int, arma: Dictionary) -> Dictionary:
	var ae := ruleset.habilidade_classe("ataque_especial")
	if classe_id != ae.get("classe", ""):
		return {}
	var total := bonus_ataque + bonus_dano
	var nivel := ruleset.nivel_alcancado(ae.niveis, nex)
	if nivel.is_empty() or total <= 0 or total % 5 != 0 or bonus_ataque < 0 or bonus_dano < 0 or total > int(nivel.bonus_total):
		return {}
	var custo := 1 + total / 5   # +5 = 2 PE, +10 = 3 PE, +15 = 4 PE, +20 = 5 PE
	var mult := 1
	for e in efeitos("ataque_especial_dobrado"):
		if arma.get("ataque", "corpo_a_corpo") in e.get("ataques", []):
			mult = 2
	var minimo := int(ae.niveis[0].custo)
	return {"custo": custo, "minimo": custo == minimo, "bonus_ataque": bonus_ataque * mult, "bonus_dano": bonus_dano * mult}


# --- Mundano (regra opcional NEX 0%) ---------------------------------------

## Promove um Mundano a agente em NEX 5% (p.182). `pericias_novas`: as perícias que a
## classe dá (respeitando as escolhas "X ou Y" e a quantidade livre). Retorna os erros.
func promover_de_mundano(nova_classe: String, atributo_bonus: String, pericias_novas: Array) -> Array[String]:
	var erros: Array[String] = []
	if classe_id != "mundano":
		erros.append("Só um Mundano pode ser promovido")
		return erros
	var promo: Dictionary = ruleset.classe("mundano").promocao
	if not promo.classes.has(nova_classe):
		erros.append("Classe inválida para a promoção: %s" % nova_classe)
		return erros
	var regra: Dictionary = promo.classes[nova_classe]
	if int(atributos.get(atributo_bonus, 0)) + int(promo.atributo_bonus) > int(promo.atributo_maximo):
		erros.append("O ponto de atributo da promoção não pode passar de %d" % int(promo.atributo_maximo))
	var restantes := pericias_novas.duplicate()
	for p in regra.get("pericias_fixas", []):
		if not p in restantes:
			erros.append("A promoção para %s inclui %s" % [nova_classe, p])
		restantes.erase(p)
	for par in regra.get("pericias_fixas_escolha", []):
		var feitas: Array = restantes.filter(func(x): return x in par)
		if feitas.size() != 1:
			erros.append("Escolha uma entre %s" % " ou ".join(par))
		else:
			restantes.erase(feitas[0])
	if restantes.size() != int(regra.pericias_livres):
		erros.append("A promoção para %s dá %d perícia(s) livre(s)" % [nova_classe, int(regra.pericias_livres)])
	if not erros.is_empty():
		return erros
	atributos[atributo_bonus] = int(atributos.get(atributo_bonus, 0)) + int(promo.atributo_bonus)
	for p in pericias_novas:
		if grau(p) == "destreinado":
			pericias[p] = "treinado"
	classe_id = nova_classe
	nex = int(promo.nex)
	transicao_mundano = {"pv": int(regra.pv), "pe": int(regra.pe), "san": int(regra.san)}
	recalcular_maximos(true)
	return erros
