class_name Ruleset
extends RefCounted
## Base de um conjunto de regras (ADR 0002). Os dados vêm de
## `res://data/rulesets/<id>/` e as fórmulas que mudam entre versões
## ficam em métodos que as subclasses sobrescrevem.

const RAIZ_PADRAO := "res://data/rulesets"

var id := ""
var nome := ""
## Conteúdo bruto de cada arquivo, indexado pelo nome sem extensão ("pericias", "classes"…).
var dados: Dictionary = {}

var _pericias: Dictionary = {}
var _classes: Dictionary = {}
var _armas: Dictionary = {}
var _graus: Dictionary = {}
var _origens: Dictionary = {}
var _poderes: Dictionary = {}   ## classe_id -> {poder_id -> poder}
var _trilhas: Dictionary = {}   ## classe_id -> {trilha_id -> trilha}
var _faixas_idade: Dictionary = {}
var _desvantagens_idade: Dictionary = {}


## Carrega o manifesto e os arquivos listados. Retorna OK ou um código de erro.
func carregar(pasta: String) -> Error:
	var manifesto = _ler_json(pasta.path_join("ruleset.json"))
	if manifesto == null:
		return ERR_FILE_NOT_FOUND
	id = manifesto.get("id", "")
	nome = manifesto.get("nome", "")
	for arquivo in manifesto.get("arquivos", []):
		var conteudo = _ler_json(pasta.path_join(arquivo))
		if conteudo == null:
			return ERR_PARSE_ERROR
		dados[String(arquivo).get_basename()] = conteudo
	_indexar()
	return OK


func _indexar() -> void:
	for p in dados.get("pericias", {}).get("pericias", []):
		_pericias[p.id] = p
	for g in dados.get("pericias", {}).get("graus", []):
		_graus[g.id] = int(g.bonus)
	for c in dados.get("classes", {}).get("classes", []):
		_classes[c.id] = c
	for a in dados.get("armas", {}).get("armas", []):
		_armas[a.id] = a
	for o in dados.get("origens", {}).get("origens", []):
		_origens[o.id] = o
	var poderes_por_classe: Dictionary = dados.get("poderes_classe", {}).get("poderes", {})
	for classe_id in poderes_por_classe:
		_poderes[classe_id] = {}
		for p in poderes_por_classe[classe_id]:
			_poderes[classe_id][p.id] = p
	for f in dados.get("idades", {}).get("faixas", []):
		_faixas_idade[f.id] = f
	for dv in dados.get("idades", {}).get("desvantagens", []):
		_desvantagens_idade[dv.id] = dv
	var trilhas_por_classe: Dictionary = dados.get("trilhas", {}).get("trilhas", {})
	for classe_id in trilhas_por_classe:
		_trilhas[classe_id] = {}
		for t in trilhas_por_classe[classe_id]:
			_trilhas[classe_id][t.id] = t


static func _ler_json(caminho: String) -> Variant:
	if not FileAccess.file_exists(caminho):
		push_error("Arquivo de ruleset não encontrado: %s" % caminho)
		return null
	var texto := FileAccess.get_file_as_string(caminho)
	var json := JSON.new()
	if json.parse(texto) != OK:
		push_error("JSON inválido em %s (linha %d): %s" % [caminho, json.get_error_line(), json.get_error_message()])
		return null
	return json.data


# --- Consultas -------------------------------------------------------------

func pericia(pericia_id: String) -> Dictionary:
	assert(_pericias.has(pericia_id), "Perícia desconhecida: %s" % pericia_id)
	return _pericias[pericia_id]


func tem_pericia(pericia_id: String) -> bool:
	return _pericias.has(pericia_id)


func tem_classe(classe_id: String) -> bool:
	return _classes.has(classe_id)


func classe(classe_id: String) -> Dictionary:
	assert(_classes.has(classe_id), "Classe desconhecida: %s" % classe_id)
	return _classes[classe_id]


func arma(arma_id: String) -> Dictionary:
	assert(_armas.has(arma_id), "Arma desconhecida: %s" % arma_id)
	return _armas[arma_id]


func tem_origem(origem_id: String) -> bool:
	return _origens.has(origem_id)


func origem(origem_id: String) -> Dictionary:
	assert(_origens.has(origem_id), "Origem desconhecida: %s" % origem_id)
	return _origens[origem_id]


func tem_poder(classe_id: String, poder_id: String) -> bool:
	return _poderes.get(classe_id, {}).has(poder_id)


func poder(classe_id: String, poder_id: String) -> Dictionary:
	assert(tem_poder(classe_id, poder_id), "Poder desconhecido: %s/%s" % [classe_id, poder_id])
	return _poderes[classe_id][poder_id]


func tem_trilha(classe_id: String, trilha_id: String) -> bool:
	return _trilhas.get(classe_id, {}).has(trilha_id)


func trilha(classe_id: String, trilha_id: String) -> Dictionary:
	assert(tem_trilha(classe_id, trilha_id), "Trilha desconhecida: %s/%s" % [classe_id, trilha_id])
	return _trilhas[classe_id][trilha_id]


func tem_faixa_idade(faixa_id: String) -> bool:
	return _faixas_idade.has(faixa_id)


func faixa_idade(faixa_id: String) -> Dictionary:
	assert(_faixas_idade.has(faixa_id), "Faixa etária desconhecida: %s" % faixa_id)
	return _faixas_idade[faixa_id]


func tem_desvantagem_idade(desvantagem_id: String) -> bool:
	return _desvantagens_idade.has(desvantagem_id)


func desvantagem_idade(desvantagem_id: String) -> Dictionary:
	assert(_desvantagens_idade.has(desvantagem_id), "Desvantagem de idade desconhecida: %s" % desvantagem_id)
	return _desvantagens_idade[desvantagem_id]


func tem_ritual(ritual_id: String) -> bool:
	return not ritual(ritual_id).is_empty()


func ritual(ritual_id: String) -> Dictionary:
	for r in dados.get("rituais", {}).get("rituais", []):
		if r.id == ritual_id:
			return r
	return {}


func lista_rituais() -> Array:
	return dados.get("rituais", {}).get("rituais", [])


## Maior círculo de ritual acessível no NEX (p.42: Escolhido pelo Outro Lado).
func circulo_maximo(nex: int) -> int:
	var c := 0
	for n in dados.get("rituais", {}).get("circulo_por_nex", []):
		if nex >= int(n.nex):
			c = int(n.circulo)
	return c


func custo_base_ritual(circulo: int) -> int:
	return int(dados.get("rituais", {}).get("custo_por_circulo", {}).get(str(circulo), 1))


func habilidade_classe(habilidade_id: String) -> Dictionary:
	return dados.classes.habilidades_classe.get(habilidade_id, {})


## Lista de NEX em que a classe ganha algo (trilha, poder, aumento de atributo…).
func niveis_de(chave_progressao: String) -> Array:
	return dados.classes.progressao.get(chave_progressao, [])


## Quantas vezes um marco da progressão já foi alcançado no NEX dado.
func quantos_ate(chave_progressao: String, nex: int) -> int:
	return niveis_de(chave_progressao).filter(func(n): return int(n) <= nex).size()


## Último nível (dicionário) de uma lista {"nex": N, ...} já alcançado. Vazio se nenhum.
func nivel_alcancado(niveis: Array, nex: int) -> Dictionary:
	var melhor: Dictionary = {}
	for n in niveis:
		if int(n.nex) <= nex:
			melhor = n
	return melhor


func bonus_grau(grau: String) -> int:
	return _graus.get(grau, 0)


# --- Patente e equipamento (cap. 3) -----------------------------------------

func patentes() -> Array:
	return dados.get("patentes", {}).get("patentes", [])


## Patente correspondente a um total de Pontos de Prestígio (p.61).
func patente_por_pp(pp: int) -> Dictionary:
	var atual: Dictionary = {}
	for p in patentes():
		if pp >= int(p.pp):
			atual = p
	return atual


func pp_por_evento(evento: String) -> int:
	return int(dados.get("patentes", {}).get("pp_por_missao", {}).get(evento, 0))


func regra_carga() -> Dictionary:
	return dados.get("patentes", {}).get("carga", {})


func protecoes() -> Array:
	return dados.get("equipamentos", {}).get("protecoes", [])


func itens_gerais() -> Array:
	return dados.get("equipamentos", {}).get("itens", [])


func lista_armas() -> Array:
	return dados.get("armas", {}).get("armas", []).filter(func(a): return a.id != "desarmado")


func lista_poderes_paranormais() -> Array:
	return dados.get("poderes_paranormais", {}).get("poderes", [])


func poder_paranormal(poder_id: String) -> Dictionary:
	for p in lista_poderes_paranormais():
		if p.id == poder_id:
			return p
	return {}


func cfg_maldicoes() -> Dictionary:
	return dados.get("equipamentos", {}).get("maldicoes", {})


func maldicao(maldicao_id: String) -> Dictionary:
	for m in cfg_maldicoes().get("lista", []):
		if m.id == maldicao_id:
			return m
	return {}


func lista_amaldicoados() -> Array:
	return dados.get("equipamentos", {}).get("amaldicoados", [])


## Qualquer equipamento pelo id, com "tipo": "arma" | "protecao" | "item". {} se não existir.
## Itens amaldiçoados (p.154) são montados a partir da base: a primeira maldição soma II à
## categoria e as seguintes, I; o item recebe a lista "maldicoes".
func equipamento(item_id: String) -> Dictionary:
	for am in lista_amaldicoados():
		if am.id == item_id:
			var base := equipamento(am.base)
			if base.is_empty():
				return {}
			base = base.duplicate(true)
			base.id = am.id
			base.base = am.base
			base.nome = am.nome
			var lista: Array = []
			for mid in am.maldicoes:
				var m := maldicao(mid)
				if not m.is_empty():
					lista.append(m)
			base.maldicoes = lista
			if not lista.is_empty():
				base.categoria = int(base.get("categoria", 0)) + 2 + (lista.size() - 1)
			return base
	for ac in dados.get("equipamentos", {}).get("acessorios_base", []):
		if ac.id == item_id:
			var d: Dictionary = ac.duplicate()
			d["tipo"] = "item"
			return d
	if _armas.has(item_id):
		var a: Dictionary = _armas[item_id].duplicate()
		a["tipo"] = "arma"
		return a
	for p in protecoes():
		if p.id == item_id:
			var d: Dictionary = p.duplicate()
			d["tipo"] = "protecao"
			return d
	for i in itens_gerais():
		if i.id == item_id:
			var d: Dictionary = i.duplicate()
			d["tipo"] = "item"
			return d
	return {}


## Próximo grau de treinamento ("treinado" -> "veterano" -> "expert").
func proximo_grau(grau: String) -> String:
	var ordem := ["destreinado", "treinado", "veterano", "expert"]
	var i := ordem.find(grau)
	return ordem[mini(i + 1, ordem.size() - 1)]


func dt_regra(chave: String) -> int:
	return int(dados.get("dificuldades", {}).get("regras", {}).get(chave, 0))


# --- Fórmulas (sobrescrever em rulesets que mudam a regra) ----------------

## Atributo-base de uma perícia.
func atributo_da_pericia(pericia_id: String) -> String:
	return pericia(pericia_id).atributo


## Limite de PE gastos por turno para um NEX.
func limite_pe(nex: int) -> int:
	var tabela: Dictionary = dados.progressao_nex.limite_pe_por_turno
	var melhor := 0
	for chave in tabela:
		if int(chave) <= nex:
			melhor = maxi(melhor, int(tabela[chave]))
	return melhor


## Quantos "níveis de exposição" o NEX representa (5% = 1, 10% = 2… 99% = 20).
func niveis_de_exposicao(nex: int) -> int:
	return 20 if nex >= 99 else maxi(1, nex / 5)


func pv_max(classe_id: String, nex: int, atributos: Dictionary) -> int:
	return _progressao(classe(classe_id).pv, nex, atributos)


func pe_max(classe_id: String, nex: int, atributos: Dictionary) -> int:
	return _progressao(classe(classe_id).pe, nex, atributos)


func san_max(classe_id: String, nex: int, _atributos: Dictionary) -> int:
	var s: Dictionary = classe(classe_id).san
	return int(s.inicial) + (niveis_de_exposicao(nex) - 1) * int(s.por_nex)


## inicial + atributo, e (por_nex + atributo) a cada nível de exposição após o primeiro (p.35).
func _progressao(regra: Dictionary, nex: int, atributos: Dictionary) -> int:
	var attr := int(atributos.get(regra.get("atributo", ""), 0))
	var extras := niveis_de_exposicao(nex) - 1
	return int(regra.inicial) + attr + extras * (int(regra.por_nex) + attr)


func defesa_base(atributos: Dictionary) -> int:
	var d: Dictionary = dados.classes.derivadas
	return int(d.defesa_base) + int(atributos.get(d.defesa_atributo, 0))


## Testes de resistência (recebem bônus como o de Reflexos Defensivos).
func eh_teste_de_resistencia(pericia_id: String) -> bool:
	return pericia_id in ["fortitude", "reflexos", "vontade"]


## Valida a distribuição inicial de atributos (p.24). Retorna a lista de erros (vazia = válido).
## - `pontos`: pontos a distribuir (-1 = padrão do livro; Mundano usa 3).
## - `zerados_obrigatorios`: atributos que começam em 0 por regra (Idade Variada) — não rendem ponto extra.
## - `maximos`: máximos específicos por atributo (Idade Variada).
func validar_atributos_iniciais(atributos: Dictionary, pontos: int = -1, zerados_obrigatorios: Array = [], maximos: Dictionary = {}) -> Array[String]:
	var erros: Array[String] = []
	var regra: Dictionary = dados.atributos.criacao
	var ids: Array = dados.atributos.atributos.map(func(a): return a.id)
	var inicial := int(regra.valor_inicial)
	var esperado := int(regra.pontos_para_distribuir) if pontos < 0 else pontos
	var gasto := 0
	var zerados := 0
	for attr_id in ids:
		if not atributos.has(attr_id):
			erros.append("Falta o atributo %s" % attr_id)
			continue
		var v := int(atributos[attr_id])
		var maximo := int(maximos.get(attr_id, regra.maximo_inicial))
		if v > maximo:
			erros.append("%s acima do máximo inicial (%d)" % [attr_id, maximo])
		if v < 0:
			erros.append("%s negativo" % attr_id)
		if attr_id in zerados_obrigatorios:
			if v != 0:
				erros.append("%s começa em 0 nesta faixa etária" % attr_id)
			continue
		if v == 0:
			zerados += 1
		gasto += v - inicial
	if zerados > 1 or (zerados == 1 and not regra.pode_reduzir_um_para_zero):
		erros.append("Só um atributo pode ser reduzido a 0")
	if gasto != esperado:
		erros.append("Distribuição deve somar %d pontos (somou %d)" % [esperado, gasto])
	return erros
