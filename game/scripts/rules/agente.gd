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
var pe := 0
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
	if origem_id != "" and ruleset.tem_origem(origem_id):
		lista.append(ruleset.origem(origem_id).poder)
	for poder_id in poderes:
		if ruleset.tem_poder(classe_id, poder_id):
			lista.append(ruleset.poder(classe_id, poder_id))
	if trilha_id != "" and ruleset.tem_trilha(classe_id, trilha_id):
		var hab: Dictionary = ruleset.trilha(classe_id, trilha_id).habilidades
		for nivel in hab:
			if int(nivel) <= nex:
				lista.append(hab[nivel])
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
	pv_maximo = ruleset.pv_max(classe_id, nex, atributos) + _soma_efeitos("pv_por_nex") * niveis
	pe_maximo = ruleset.pe_max(classe_id, nex, atributos)
	if not efeitos("pe_dedicacao").is_empty():
		pe_maximo += 1 + (niveis - 1) / 2   # +1 PE, e +1 a cada NEX "ímpar" (15%, 25%…)
	san_maximo = ruleset.san_max(classe_id, nex, atributos) + _soma_efeitos("san_por_nex") * niveis
	if not efeitos("san_inicial_metade").is_empty():
		san_maximo -= int(ruleset.classe(classe_id).san.inicial) / 2
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
	return atributo(ruleset.atributo_da_pericia(pericia_id))


func grau(pericia_id: String) -> String:
	return pericias.get(pericia_id, "destreinado")


func treinado_em(pericia_id: String) -> bool:
	return grau(pericia_id) != "destreinado"


func bonus_pericia(pericia_id: String) -> int:
	var bonus := ruleset.bonus_grau(grau(pericia_id))
	bonus += _soma_efeitos("bonus_pericia", func(e): return e.pericia == pericia_id)
	if ruleset.eh_teste_de_resistencia(pericia_id):
		bonus += bonus_testes_resistencia()
	return bonus


func bonus_testes_resistencia() -> int:
	return _soma_efeitos("bonus_testes_resistencia")


func pode_usar_pericia(pericia_id: String) -> bool:
	return not ruleset.pericia(pericia_id).somente_treinada or treinado_em(pericia_id)


func defesa() -> int:
	return ruleset.defesa_base(atributos) + _soma_efeitos("bonus_defesa") + defesa_temporaria


func resistencia(tipo_dano: String) -> int:
	var total := super.resistencia(tipo_dano)
	for e in efeitos("resistencia"):
		if e.dano == tipo_dano:
			total += atributo(e.atributo) if e.has("atributo") else int(e.get("valor", 0))
	return total


func tem_proficiencia(prof: String) -> bool:
	if prof in ruleset.classe(classe_id).get("proficiencias", []):
		return true
	return efeitos("proficiencia").any(func(e): return e.valor == prof)


# --- PE --------------------------------------------------------------------

func limite_pe() -> int:
	return ruleset.limite_pe(nex) + _soma_efeitos("limite_pe")


## PE que ainda podem ser gastos neste turno.
func pe_disponivel_no_turno() -> int:
	return mini(pe, limite_pe() - pe_gasto_no_turno)


## `habilidade_no_minimo`: o gasto é UMA habilidade no seu custo mínimo. Nesse caso,
## o primeiro gasto do turno pode passar do limite (p.33: "sempre pode usar pelo menos
## uma habilidade em seu custo mínimo por turno").
func pode_gastar_pe(quantidade: int, habilidade_no_minimo: bool = false) -> bool:
	if quantidade < 0 or quantidade > pe:
		return false
	if habilidade_no_minimo and pe_gasto_no_turno == 0:
		return true
	return quantidade <= pe_disponivel_no_turno()


func gastar_pe(quantidade: int, habilidade_no_minimo: bool = false) -> bool:
	if not pode_gastar_pe(quantidade, habilidade_no_minimo):
		return false
	pe -= quantidade
	pe_gasto_no_turno += quantidade
	return true


func recuperar_pe(quantidade: int) -> void:
	pe = mini(pe_maximo, pe + maxi(0, quantidade))


func iniciar_turno() -> void:
	pe_gasto_no_turno = 0
	super.iniciar_turno()


func encerrar_cena() -> void:
	usos_na_cena.clear()
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
	var bonus: int = ruleset.bonus_grau(plano.grau) + plano.bonus
	bonus += _soma_efeitos("bonus_pericia", func(e): return e.pericia == pericia_id)
	if ruleset.eh_teste_de_resistencia(pericia_id):
		bonus += bonus_testes_resistencia()
	var r := Teste.rolar(dados, dados_da_pericia(pericia_id), bonus, dt, int(opcoes.get("dados_extras", 0)) + pe_foco)
	if plano.dado_perito != "":
		var extra := dados.rolar_expressao(plano.dado_perito)
		r.dados_bonus.append(extra)
		r.somar_bonus(extra)
	return r


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
	for e in efeitos("bonus_dano_atributo"):
		if aplica.call(e):
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
