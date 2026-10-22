extends GutTest
## Modificações do livro (docs/68, p.70-74): armas, munições, proteções e acessórios. Cada uma
## sobe a categoria em I, não se repete e só serve para o seu tipo de item (ADR 0013).

var rs: RulesetOp2022

const ATTRS := {"agi": 2, "for": 2, "int": 2, "pre": 2, "vig": 2}


func before_all():
	rs = RulesetOp2022.carregar_padrao()


func _agente() -> Agente:
	return Agente.criar(rs, "Agente", "combatente", ATTRS, {"luta": "treinado", "pontaria": "treinado"})


func _alvo() -> Ameaca:
	return Ameaca.criar(rs, "Alvo", {"pv": 100, "defesa": 10, "atributos": {"agi": 1}})


func test_tabela_de_modificacoes():
	assert_eq(rs.lista_modificacoes().size(), 22, "Tabelas 3.5, 3.7 e 3.9")
	for m in rs.lista_modificacoes():
		assert_true(String(m.get("ref", "")).begins_with("p.") and not Array(m.aplica).is_empty(), m.id)


func test_katana_certeira_e_perigosa_e_categoria_tres():
	var k := rs.equipamento("katana+certeira+perigosa")
	assert_eq(int(k.categoria), 3, "o exemplo do livro (p.70)")
	assert_eq(int(k.bonus_ataque), 2)
	assert_eq(int(k.margem), 17, "19 com +2 de margem de ameaça")
	assert_eq(k.nome, "Katana certeira, perigosa")
	assert_eq(k.base, "katana")


func test_modificacao_nao_repete_e_tem_tipo():
	assert_true(rs.equipamento("pistola+certeira+certeira").is_empty(), "a mesma não se repete")
	assert_true(rs.equipamento("pistola+cruel").is_empty(), "cruel é de corpo a corpo e disparo")
	assert_true(rs.equipamento("faca+mira_laser").is_empty(), "mira laser é de arma de fogo")
	assert_true(rs.equipamento("protecao_leve+blindada").is_empty(), "blindada só na pesada")


func test_compensador_pede_arma_automatica():
	assert_true(rs.equipamento("pistola+compensador").is_empty())
	var p := rs.equipamento("pistola+compensador+ferrolho_automatico")
	assert_true(p.automatica and p.compensador, "em qualquer ordem")
	assert_true(rs.equipamento("submetralhadora+ferrolho_automatico").is_empty(), "já é automática")
	assert_false(rs.modificacoes_possiveis("submetralhadora").any(func(m): return m.id == "ferrolho_automatico"))


func test_calibre_grosso_e_mira_telescopica():
	assert_eq(rs.equipamento("revolver+calibre_grosso").dano, "3d6", "o exemplo do livro")
	assert_eq(rs.equipamento("fuzil_de_precisao+calibre_grosso").dano, "3d10")
	assert_eq(rs.equipamento("pistola+mira_telescopica").alcance, "medio")


func test_protecoes_modificadas():
	assert_eq(int(rs.equipamento("protecao_leve+discreta").espacos), 1)
	assert_eq(int(rs.equipamento("protecao_leve+reforcada").defesa), 7)
	assert_true(rs.equipamento("protecao_leve+discreta+reforcada").is_empty(), "discreta ou reforçada")
	var blindada := rs.equipamento("protecao_pesada+blindada")
	assert_eq(int(blindada.resistencias.corte), 5)
	assert_eq(int(blindada.espacos), 6)
	var a := _agente()
	a.pp = 50
	a.equipamento.append("protecao_pesada+antibombas")
	assert_eq(a.bonus_contra(["area"], "reflexos"), 5)
	assert_eq(a.resistencia("corte"), 2)
	assert_eq(a.protecao().get("base"), "protecao_pesada", "habilidades que pedem proteção pesada ainda a reconhecem")


func test_arma_certeira_e_cruel_no_ataque():
	var a := _agente()
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([5, 5, 3])
	var r := c.atacar(a, _alvo(), rs.equipamento("machete+cruel"))
	assert_eq(r.dano, 3 + 2 + 2, "1d6 + Força + 2 da cruel")
	c.dados.forcar([5, 5])
	var r2 := c.atacar(a, _alvo(), rs.equipamento("machete+certeira"))
	assert_eq(r2.teste.total, 5 + 5 + 2, "treinado +5 e certeira +2")


func test_municao_explosiva_e_dum_dum():
	var a := _agente()
	a.equipamento.append_array(["pistola", "balas_curtas", "balas_curtas+explosiva"])
	a.arma_id = "pistola"
	assert_eq(a.pacote_de_municao(rs.arma("pistola")), "balas_curtas+explosiva", "a modificada vai primeiro")
	assert_eq(int(rs.equipamento("balas_curtas+explosiva").categoria), 1)
	var c := Combate.new(rs, Dados.new(1))
	c.dados.forcar([5, 5, 4, 2, 3])
	var r := c.atacar(a, _alvo(), a.arma())
	assert_eq(r.dano, 4 + 2 + 3, "1d12 + 2d6 da explosiva")
	a.equipamento.erase("balas_curtas+explosiva")
	a.equipamento.append("balas_curtas+dum_dum")
	assert_eq(int(a.arma_efetiva(a.arma()).multiplicador), 3)


func test_acessorios_modificados():
	assert_eq(int(rs.equipamento("notebook+aprimorado").bonus_pericia.tecnologia), 5)
	assert_eq(int(rs.equipamento("notebook+funcao:investigacao").bonus_pericia.investigacao), 2)
	assert_true(rs.equipamento("notebook+funcao:luta").is_empty(), "função adicional não vale para Luta")
	var a := Agente.criar(rs, "Hacker", "especialista", ATTRS, {"tecnologia": "treinado"})
	var sem_kit := a.bonus_pericia("tecnologia")
	a.equipamento.append("smartphone+instrumental:tecnologia")
	assert_eq(a.bonus_pericia("tecnologia"), sem_kit + 5, "serve de kit: some o −5")
	assert_string_contains(rs.equipamento("smartphone+instrumental:tecnologia").nome, "instrumental (Tecnologia)")


func test_patente_decide_a_arma_modificada():
	var a := _agente()
	assert_string_contains(a.motivo_bloqueio("pistola+alongada", []), "categoria II", "Recruta: só até a I")
	a.pp = 20
	assert_eq(a.motivo_bloqueio("pistola+alongada", []), "")
	a.equipamento.append_array(["pistola+alongada", "balas_curtas"])
	a.arma_id = "pistola+alongada"
	assert_eq(a.arma().id, "pistola+alongada", "a munição da base serve na modificada")
