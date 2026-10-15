class_name Agente
extends Ser
## Agente da Ordem controlado por um jogador.
## Para criar com validação completa (origem, classe, poderes, trilha), use CriacaoAgente.

var ruleset: Ruleset
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
## Ex-mundano (regra NEX 0%): bônus recebidos ao virar agente, ex.: {"pv": 12, "pe": 1, "san": 4}
var transicao_mundano: Dictionary = {}
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
	return lista


func tem_habilidade(habilidade_id: String) -> bool:
	return habilidades().any(func(h): return h.id == habilidade_id)


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
	if not efeitos("san_inicial_metade").is_empty():
		san_maximo -= int(ruleset.classe(classe_id).san.inicial) / 2
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
	return int(atributos.get(atributo_id, 0)) + int(mods_cena.get("atributos", {}).get(atributo_id, 0))


func dados_da_pericia(pericia_id: String) -> int:
	var d := atributo(ruleset.atributo_da_pericia(pericia_id))
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
	return bonus


func bonus_testes_resistencia() -> int:
	return super.bonus_testes_resistencia() + _soma_efeitos("bonus_testes_resistencia")


## Bônus extra em testes de resistência contra efeitos paranormais (Mente Sã).
func bonus_resistencia_paranormal() -> int:
	return _soma_efeitos("bonus_resistencia_paranormal")


## DT para resistir às habilidades do agente: 10 + limite de PE + atributo (p.88).
## O bônus de limite da Dedicação não conta para DT.
func dt_habilidade(atributo_id: String) -> int:
	return 10 + ruleset.limite_pe(nex) + atributo(atributo_id)


func pode_usar_pericia(pericia_id: String) -> bool:
	return not ruleset.pericia(pericia_id).somente_treinada or treinado_em(pericia_id)


func defesa() -> int:
	var d := ruleset.defesa_base(atributos) + _soma_efeitos("bonus_defesa") + ajustes_de_defesa()
	if tem(Ser.MACHUCADO) and tem_habilidade("inquebravel"):
		d += 5
	return d


func resistencia(tipo_dano: String) -> int:
	var total := super.resistencia(tipo_dano)
	for e in efeitos("resistencia"):
		if e.dano == tipo_dano:
			total += atributo(e.atributo) if e.has("atributo") else int(e.get("valor", 0))
	if tem(Ser.MACHUCADO) and tem_habilidade("inquebravel"):
		total += 5   # Inquebrável: RD 5 contra qualquer dano enquanto machucado
	return total


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
	return ruleset.limite_pe(nex) + _soma_efeitos("limite_pe")


## PE que ainda podem ser gastos neste turno (PE temporários contam).
func pe_disponivel_no_turno() -> int:
	return mini(pe + pe_temporario, limite_pe() - pe_gasto_no_turno)


## `habilidade_no_minimo`: o gasto é UMA habilidade no seu custo mínimo. Nesse caso,
## o primeiro gasto do turno pode passar do limite (p.33: "sempre pode usar pelo menos
## uma habilidade em seu custo mínimo por turno").
func pode_gastar_pe(quantidade: int, habilidade_no_minimo: bool = false) -> bool:
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
## Todo o PE é verificado antes (tudo ou nada). Retorna null se o teste não puder ser feito.
func testar(dados: Dados, pericia_id: String, dt: int, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoTeste:
	var plano := _planejar_teste(pericia_id, pe_foco, opcoes)
	if plano.is_empty() or not gastar_pe(plano.custo, _uma_habilidade_no_minimo(plano, pe_foco)):
		return null
	for hab_id in plano.usos:
		usos_na_cena[hab_id] = int(usos_na_cena.get(hab_id, 0)) + 1
	var bonus: int = bonus_pericia(pericia_id, plano.grau) + plano.bonus
	var r := Teste.rolar(dados, dados_da_pericia(pericia_id), bonus, dt, int(opcoes.get("dados_extras", 0)) + pe_foco)
	if plano.dado_perito != "":
		var extra := dados.rolar_expressao(plano.dado_perito)
		r.dados_bonus.append(extra)
		r.somar_bonus(extra)
	if pericia_id == "reflexos" and esta_indefeso():
		r.sucesso = false   # indefeso falha automaticamente em Reflexos (p.320)
	sofrer_dano_por_teste(dados, ruleset.atributo_da_pericia(pericia_id))
	return r


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
		"fontes": 0, "no_minimo": true}
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
