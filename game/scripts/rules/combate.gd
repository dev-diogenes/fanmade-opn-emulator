class_name Combate
extends RefCounted
## Cena de combate sem interface: iniciativa, turnos, ações, ataques, reações,
## poderes de combate e regras opcionais (cap. 1, cap. 4 p.92–99, cap. 6 p.184).
## Com uma `grade` definida, o combate verifica distância, alcance, flanco, cobertura e
## alvo em corpo a corpo automaticamente. Sem grade (testes, cenas abstratas), nada disso é checado.

signal turno_iniciado(ser: Ser)
signal turno_perdido(ser: Ser, motivo: String)
signal ataque_resolvido(resultado: ResultadoAtaque)
signal lesao_sofrida(agente: Agente, atributo_id: String)
signal inspiracao_disponivel(morto: Agente, efeito: String)
signal combate_encerrado(lado_vencedor: String)
signal oportunidade_de_ataque(atacante: Ser, alvo: Ser)
signal ritual_conjurado(resultado: Dictionary)
signal registro(texto: String)

const REACOES := ["bloqueio", "esquiva", "contra_ataque"]
const ORDEM_LESAO := ["agi", "for", "int", "pre", "vig"]   ## 1d6: 1..5; 6 = nenhuma (p.184)
const INSPIRACOES := ["chamas_da_vinganca", "chamas_da_vinganca", "forca_do_odio", "forca_do_odio",
	"mente_em_luto", "mente_em_luto", "resoluto", "resoluto", "loucura_selvagem", "loucura_selvagem"]  ## 1d10 (p.184-185)
const TIPOS_PARANORMAIS := ["paranormal", "sangue", "morte", "conhecimento", "energia", "medo"]

var ruleset: Ruleset
var dados: Dados
var grade: Grade   ## Opcional: posicionamento tático
var membrana: Membrana   ## Opcional: rituais enfraquecem a Membrana
## Regras opcionais ativas nesta run: {"lesoes": true, "inspiracao_resoluta": true}
var regras: Dictionary = {}
var participantes: Array[Ser] = []
var ordem: Array[Ser] = []
var iniciativas: Dictionary = {}   ## Ser -> total de Iniciativa
var rodada := 0
var encerrado := false
## Ações restantes no turno atual de cada ser: {"padrao": int, "movimento": int}
var acoes: Dictionary = {}
## Inspirações sorteadas aguardando o jogador escolher o aliado: [{morto, efeito}]
var inspiracoes_pendentes: Array[Dictionary] = []

var _indice := -1
var _reacoes_declaradas: Dictionary = {}   ## Ser -> {"tipo", "arma", "revidar"}
var _reducoes_declaradas: Dictionary = {}  ## Ser -> habilidade_id (Duro de Matar, Abraçar a Dor)
var _mortos_inspiradores: Array[Agente] = []
var _movimentos_extras: Dictionary = {}    ## Ser -> movimentos extras no PRÓXIMO turno
var _usos_rodada: Dictionary = {}          ## Ser -> {habilidade_id: true} (zera no turno do ser)
var _ataques_no_turno: Dictionary = {}     ## Ser -> quantos ataques fez neste turno
var _ultimo_ataque: Dictionary = {}        ## Ser -> ResultadoAtaque do turno
var _danificados_na_rodada: Dictionary = {}  ## Ser (alvo) -> lado de quem causou dano
var _miras: Dictionary = {}                ## Ser -> {"alvo": Ser, "margem": int, "turnos": int}
var _efeitos_ate_turno: Array[Dictionary] = []  ## {origem: Ser, alvo: Ser, tipo: String}
var _imunes_cai_dentro: Dictionary = {}    ## Ser -> true
## Ataques de oportunidade liberados pelo último movimento: [{atacante, alvo}]
var oportunidades_pendentes: Array[Dictionary] = []
## Rituais sustentados em andamento: [{conjurador, alvo, ritual}]
var _sustentados: Array[Dictionary] = []


func _init(p_ruleset: Ruleset, p_dados: Dados, p_regras: Dictionary = {}) -> void:
	ruleset = p_ruleset
	dados = p_dados
	regras = p_regras


func adicionar(ser: Ser) -> void:
	participantes.append(ser)
	ser.morreu.connect(_ao_morrer)


# --- Iniciativa e turnos ---------------------------------------------------

## Rola Iniciativa e ordena do maior para o menor (p.93).
## - Agentes rolam individualmente; as ameaças fazem UM teste, com o menor bônus entre elas.
## - Empates: maior Agilidade primeiro; persistindo, rolagem de desempate.
## - `surpreendidos`: seres que não perceberam os inimigos (não agem na 1ª rodada).
##   Agentes com a desvantagem Distraído ficam surpreendidos automaticamente.
func iniciar(surpreendidos: Array = []) -> void:
	var ameacas := participantes.filter(func(s): return not s is Agente)
	var total_ameacas := 0
	if not ameacas.is_empty():
		var pior: Ser = ameacas[0]
		for a in ameacas:
			var chave_a: int = a.bonus_pericia("iniciativa") * 100 + a.dados_da_pericia("iniciativa")
			var chave_pior: int = pior.bonus_pericia("iniciativa") * 100 + pior.dados_da_pericia("iniciativa")
			if chave_a < chave_pior:
				pior = a
		total_ameacas = Teste.rolar(dados, pior.dados_da_pericia("iniciativa"), pior.bonus_pericia("iniciativa"), 0).total
	var desempate: Dictionary = {}
	for ser in participantes:
		if ser is Agente:
			iniciativas[ser] = Teste.rolar(dados, ser.dados_da_pericia("iniciativa"), ser.bonus_pericia("iniciativa"), 0).total
		else:
			iniciativas[ser] = total_ameacas
		desempate[ser] = dados.rolar(20)
		var distraido: bool = ser is Agente and not (ser as Agente).efeitos("surpreendido_inicio").is_empty()
		if ser in surpreendidos or distraido:
			ser.condicoes[Ser.SURPREENDIDO] = true
	ordem = participantes.duplicate()
	ordem.sort_custom(func(a: Ser, b: Ser) -> bool:
		if iniciativas[a] != iniciativas[b]:
			return iniciativas[a] > iniciativas[b]
		if a.atributo("agi") != b.atributo("agi"):
			return a.atributo("agi") > b.atributo("agi")
		return desempate[a] > desempate[b])
	rodada = 1
	_indice = -1
	for s in participantes:
		if s is Agente:
			(s as Agente).em_acao = true   # Encarar a Morte vale em cenas de ação


func ser_atual() -> Ser:
	return ordem[_indice] if _indice >= 0 and _indice < ordem.size() else null


## Avança para o próximo ser que pode agir e inicia o turno dele.
## Seres morrendo ou enlouquecendo também "iniciam turno" (é aí que a contagem avança).
func proximo_turno() -> Ser:
	if encerrado:
		return null
	for _tentativa in ordem.size() * 2:
		_indice += 1
		if _indice >= ordem.size():
			_indice = 0
			rodada += 1
			_danificados_na_rodada.clear()
			for s in participantes:
				s.condicoes.erase(Ser.SURPREENDIDO)   # surpresa só vale na 1ª rodada
			_sortear_inspiracoes()
		var ser := ordem[_indice]
		if ser.tem(Ser.MORTO):
			continue
		if ser.tem(Ser.SURPREENDIDO):
			turno_perdido.emit(ser, "surpreendido")
			continue
		if ser.tem(Ser.ATORDOADO) or ser.tem(Ser.PASMO):
			var motivo := "atordoado" if ser.tem(Ser.ATORDOADO) else "pasmo"
			ser.condicoes.erase(Ser.ATORDOADO)
			ser.condicoes.erase(Ser.PASMO)
			ser.duracoes.erase(Ser.ATORDOADO)
			ser.duracoes.erase(Ser.PASMO)
			ser.iniciar_turno()
			turno_perdido.emit(ser, motivo)
			continue
		ser.iniciar_turno()
		_ao_iniciar_turno(ser)
		_processar_hemorragia(ser)
		_manter_sustentados(ser)
		_cura_acelerada(ser)
		_verificar_lesao(ser)
		if _verificar_fim():
			return null
		if ser.esta_fora_de_combate():
			continue
		if _perdeu_turno_por_tosse(ser):
			continue
		turno_iniciado.emit(ser)
		return ser
	_verificar_fim()
	return null


func _ao_iniciar_turno(ser: Ser) -> void:
	_usos_rodada.erase(ser)
	_ataques_no_turno[ser] = 0
	_ultimo_ataque.erase(ser)
	# Efeitos que duram até o início do próximo turno de quem os causou
	for i in range(_efeitos_ate_turno.size() - 1, -1, -1):
		var ef: Dictionary = _efeitos_ate_turno[i]
		if ef.origem == ser:
			_desfazer_efeito(ef)
			_efeitos_ate_turno.remove_at(i)
	if _miras.has(ser):
		_miras[ser].turnos -= 1
		if _miras[ser].turnos <= 0:
			_miras.erase(ser)
	# Ações do turno
	var padrao := 1 + ser.acoes_padrao_extras
	ser.acoes_padrao_extras = 0
	var movimento := 1 + int(_movimentos_extras.get(ser, 0))
	_movimentos_extras.erase(ser)
	movimento += ser.efeito_ritual("movimento_extra")   # Velocidade Mortal
	if rodada == 1 and ser is Agente:
		var ag := ser as Agente
		if ag.tem_habilidade("iniciativa_aprimorada"):
			movimento += 1
		if ag.tem_habilidade("sempre_alerta"):
			padrao += 1
	acoes[ser] = {"padrao": padrao, "movimento": movimento}


func _perdeu_turno_por_tosse(ser: Ser) -> bool:
	if not ser is Agente or (ser as Agente).efeitos("tosse").is_empty():
		return false
	if dados.rolar(6) == 1:
		acoes[ser] = {"padrao": 0, "movimento": 0}
		turno_perdido.emit(ser, "tosse")
		return true
	return false


# --- Ações (p.84) ----------------------------------------------------------

func acoes_restantes(ser: Ser) -> Dictionary:
	return acoes.get(ser, {"padrao": 0, "movimento": 0})


## Gasta uma ação: "padrao", "movimento" (usa a padrão se não houver movimento) ou "completa".
func gastar_acao(ser: Ser, tipo: String) -> bool:
	var a: Dictionary = acoes.get(ser, {})
	if a.is_empty():
		return false
	match tipo:
		"padrao":
			if a.padrao <= 0:
				return false
			a.padrao -= 1
		"movimento":
			if a.movimento > 0:
				a.movimento -= 1
			elif a.padrao > 0:
				a.padrao -= 1   # trocar a ação padrão por uma de movimento
			else:
				return false
		"completa":
			if a.padrao <= 0 or a.movimento <= 0:
				return false
			a.padrao -= 1
			a.movimento -= 1
		_:
			return false
	return true


## Ação Agredir: gasta a ação padrão e ataca.
func agredir(atacante: Ser, alvo: Ser, arma: Dictionary, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoAtaque:
	if not gastar_acao(atacante, "padrao"):
		return _ataque_invalido(atacante, alvo, arma)
	return atacar(atacante, alvo, arma, pe_foco, opcoes)


## Ação de movimento: anda até `destino` dentro do deslocamento (precisa de grade).
## Sair de perto de um inimigo com Ataque de Oportunidade libera o ataque (veja oportunidades_pendentes).
func mover(ser: Ser, destino: Vector2i) -> bool:
	if grade == null or ser.tem(Ser.IMOVEL) or ser.esta_fora_de_combate():
		return false
	var origem := grade.posicao(ser)
	if not grade.alcancaveis(ser, ser.deslocamento_quadrados()).has(destino) or grade.ocupante(destino) != null:
		return false
	if not gastar_acao(ser, "movimento"):
		return false
	var vizinhos_antes: Array[Ser] = []
	for outro in grade.seres():
		if outro.lado != ser.lado and not outro.esta_fora_de_combate() and Grade.adjacentes(origem, grade.posicao(outro)):
			vizinhos_antes.append(outro)
	grade.mover(ser, destino, ser.deslocamento_quadrados())
	oportunidades_pendentes.clear()
	for outro in vizinhos_antes:
		if not grade.estao_adjacentes(ser, outro) and outro is Agente and (outro as Agente).tem_habilidade("ataque_de_oportunidade"):
			oportunidades_pendentes.append({"atacante": outro, "alvo": ser})
			oportunidade_de_ataque.emit(outro, ser)
	return true


## Ataque de Oportunidade (poder de combatente): reação + 1 PE para um ataque corpo a corpo
## contra quem saiu do espaço adjacente (só logo após o movimento que o liberou).
func ataque_de_oportunidade(atacante: Agente, alvo: Ser, arma: Dictionary) -> ResultadoAtaque:
	var idx := -1
	for i in oportunidades_pendentes.size():
		if oportunidades_pendentes[i].atacante == atacante and oportunidades_pendentes[i].alvo == alvo:
			idx = i
	if idx < 0 or arma.get("ataque", "") != "corpo_a_corpo" or not atacante.gastar_pe(1, true):
		return _ataque_invalido(atacante, alvo, arma)
	oportunidades_pendentes.remove_at(idx)
	# O alvo acabou de sair: o ataque acontece antes, então não exige adjacência agora.
	return atacar(atacante, alvo, arma, 0, {"ignorar_distancia": true})


## Usa um item consumível de cura (ex.: Cicatrizante, p.75) em si ou num aliado adjacente.
## Gasta a ação do item. Retorna os PV curados (-1 se não pôde usar).
func usar_item(ser: Agente, item_id: String, alvo: Ser) -> int:
	var info := ruleset.equipamento(item_id)
	var uso: Dictionary = info.get("uso", {})
	if uso.is_empty() or not ser.tem_item(item_id) or alvo.tem(Ser.MORTO):
		return -1
	if alvo != ser and grade != null and grade.tem(ser) and grade.tem(alvo) and not grade.estao_adjacentes(ser, alvo):
		return -1
	if not gastar_acao(ser, uso.get("acao", "padrao")):
		return -1
	ser.consumir_item(item_id)
	var cura := dados.rolar_expressao(uso.get("cura", "0"))
	alvo.curar(cura)
	return cura


## Sem grade, tudo está "perto". Com grade, verifica a categoria de alcance.
func _perto(a: Ser, b: Ser, categoria: String) -> bool:
	return grade == null or not grade.tem(a) or not grade.tem(b) or grade.em_alcance(a, b, categoria)


# --- Rituais (cap. 5, p.127-131) ---------------------------------------------------

## Erro que impede conjurar ("" = pode). Não gasta nada.
func pode_conjurar(conjurador: Agente, ritual_id: String, alvo: Ser, forma: String = "") -> String:
	var r := ruleset.ritual(ritual_id)
	if r.is_empty():
		return "ritual desconhecido"
	if not conjurador.conhece_ritual(ritual_id):
		return "%s não conhece %s" % [conjurador.nome, r.nome]
	if not r.get("implementado", false):
		return "%s ainda não tem efeito no jogo" % r.nome
	if int(r.circulo) > conjurador.circulo_maximo():
		return "círculo acima do permitido pelo NEX"
	if forma != "":
		var f: Dictionary = r.get("formas", {}).get(forma, {})
		if f.is_empty() or int(f.get("circulo", 1)) > conjurador.circulo_maximo():
			return "forma %s indisponível" % forma
	if conjurador.efeito_ritual("ataque_corpo_a_corpo") > 0 and conjurador.rituais_ativos.has("odio_incontrolavel"):
		return "em frenesi, não dá para se concentrar"
	if r.elemento != "medo" and conjurador.afinidade != r.elemento and not conjurador.equipamento.any(func(i): return ruleset.equipamento(i).get("componentes", "") == r.elemento):
		return "faltam componentes ritualísticos de %s" % r.elemento
	var custo := conjurador.custo_ritual(ritual_id, forma)
	if custo > conjurador.limite_pe_rituais():
		return "custo (%d PE) acima do limite de PE" % custo
	if custo > conjurador.pe + conjurador.pe_temporario:
		return "PE insuficientes"
	var alcance := String(r.get("alcance", "pessoal"))
	if alcance.begins_with("pessoal") and alvo != conjurador:
		return "este ritual só afeta o conjurador"
	if alcance.begins_with("toque") and alvo != conjurador and grade != null and grade.tem(conjurador) and grade.tem(alvo) and not grade.estao_adjacentes(conjurador, alvo):
		return "precisa tocar o alvo"
	for cat in ["curto", "medio", "longo"]:
		if alcance.begins_with(cat.replace("medio", "médio")) and not _perto(conjurador, alvo, cat):
			return "alvo fora de alcance"
	if acoes.has(conjurador) and acoes_restantes(conjurador).padrao <= 0:
		return "sem ação padrão"
	return ""


## Conjura um ritual (p.129-131): ação padrão, PE pelo círculo, concentração se estiver de
## proteção, Custo do Paranormal (Ocultismo DT 20 + custo; falha custa SAN), efeito e
## resistência (DT de habilidade com Presença; −2/+2 dados conforme o elemento da criatura).
func conjurar(conjurador: Agente, ritual_id: String, alvo: Ser, forma: String = "") -> Dictionary:
	var erro := pode_conjurar(conjurador, ritual_id, alvo, forma)
	if erro != "":
		return {"ok": false, "erro": erro}
	var r := ruleset.ritual(ritual_id)
	var cfg: Dictionary = ruleset.dados.rituais
	var custo := conjurador.custo_ritual(ritual_id, forma)
	if acoes.has(conjurador):
		gastar_acao(conjurador, "padrao")
	conjurador.gastar_pe(custo, true)
	var res := {"ok": true, "ritual": r, "custo": custo, "alvo": alvo, "conjurador": conjurador, "textos": []}
	# Concentração: proteção leve = condição ruim, pesada = terrível (p.129)
	var prot := conjurador.protecao()
	if not prot.is_empty():
		var dt_conc := int(cfg.concentracao.protecao_pesada_dt if prot.id == "protecao_pesada" else cfg.concentracao.protecao_leve_dt) + custo
		var tc := Teste.rolar(dados, conjurador.dados_da_pericia("vontade"), conjurador.bonus_pericia("vontade"), dt_conc)
		if not tc.sucesso:
			res.ok = false
			res.erro = "perdeu a concentração (Vontade %s)" % tc.descrever()
			_log("%s tenta conjurar %s, mas perde a concentração." % [conjurador.nome, r.nome])
			return res
	# Custo do Paranormal (p.131)
	if r.elemento == "medo":
		conjurador.perder_sanidade(custo + 1)   # o ponto permanente também sai da SAN atual
		conjurador.san_perdida += 1
		conjurador.recalcular_maximos()
		res.textos.append("O Medo cobra seu preço: −%d SAN, uma delas para sempre." % (custo + 1))
	else:
		var dt_custo := int(cfg.custo_paranormal.dt_base) + custo
		var tp := Teste.rolar(dados, conjurador.dados_da_pericia("ocultismo"), conjurador.bonus_pericia("ocultismo"), dt_custo)
		res.teste_custo = tp
		if not tp.sucesso:
			conjurador.perder_sanidade(custo)
			var texto := "Custo do Paranormal: −%d SAN" % custo
			if dt_custo - tp.total >= int(cfg.custo_paranormal.falha_por_permanente):
				conjurador.perder_sanidade(1)   # p.131: perde 1 ponto de Sanidade permanentemente
				conjurador.san_perdida += 1
				conjurador.recalcular_maximos()
				texto += " e mais 1 para sempre"
			res.textos.append(texto + ".")
	if membrana != null:
		membrana.registrar_ritual(int(r.circulo))
	# Efeito (forma básica com as mudanças da forma escolhida)
	var efeito: Dictionary = r.efeitos[0].duplicate(true)
	if forma != "":
		for k in r.formas[forma]:
			if not k in ["custo", "circulo"]:
				efeito[k] = r.formas[forma][k]
	_aplicar_efeito_ritual(conjurador, ritual_id, r, efeito, alvo, res)
	_log("[color=#bb8fce]%s conjura %s em %s (%d PE).[/color] %s" % [conjurador.nome, r.nome, alvo.nome, custo, " ".join(PackedStringArray(res.textos))])
	ritual_conjurado.emit(res)
	_verificar_fim()
	return res


## Teste de resistência do alvo contra o ritual. Criatura do elemento que o ritual oprime:
## −2 dados; do mesmo elemento: +2 dados (p.128).
func _resistir_ritual(conjurador: Agente, ritual_id: String, r: Dictionary, alvo: Ser, pericia: String) -> ResultadoTeste:
	var mod := 0
	if alvo is Ameaca and (alvo as Ameaca).elemento != "":
		var el := (alvo as Ameaca).elemento
		var vantagem: Dictionary = ruleset.dados.rituais.vantagem_elemental
		if vantagem.get(r.elemento, "") == el:
			mod = -int(vantagem.dados)
		elif r.elemento == el:
			mod = int(vantagem.dados)
	var bonus := alvo.bonus_pericia(pericia)
	if alvo is Agente:
		var ag := alvo as Agente
		var cfg_af: Dictionary = ruleset.dados.get("poderes_paranormais", {}).get("afinidade", {})
		var vantagem: Dictionary = ruleset.dados.rituais.vantagem_elemental
		if ag.afinidade != "" and ag.afinidade == r.elemento:
			mod += int(cfg_af.get("dados_resistencia", 2))
		elif ag.afinidade != "" and vantagem.get(r.elemento, "") == ag.afinidade:
			mod -= int(cfg_af.get("dados_resistencia", 2))
		bonus += ag._soma_efeitos("bonus_resistencia_rituais")   # Abascanta
	var t := Teste.rolar(dados, alvo.dados_da_pericia(pericia), bonus, conjurador.dt_ritual(ritual_id), mod)
	if t.sucesso:
		_ao_passar_resistencia(alvo)
	elif alvo is Agente:
		(alvo as Agente).pagar_preco_da_maldicao(ruleset.atributo_da_pericia(pericia))
	return t


## Potencial Reaproveitado (p.115): uma vez por rodada, passar num teste de resistência dá PE temporários.
func _ao_passar_resistencia(ser: Ser) -> void:
	if not ser is Agente or _usou_na_rodada(ser, "potencial_reaproveitado"):
		return
	var ganho := (ser as Agente)._soma_efeitos("potencial_reaproveitado")
	if ganho > 0:
		_marcar_uso_rodada(ser, "potencial_reaproveitado")
		(ser as Agente).ganhar_pe_temporario(ganho)


## Sangue Vivo (p.116): machucado, regenera alguns PV por turno, sem passar da metade.
func _cura_acelerada(ser: Ser) -> void:
	if not ser is Agente or not ser.tem(Ser.MACHUCADO):
		return
	var valor := (ser as Agente)._soma_efeitos("cura_acelerada_machucado")
	var teto := ser.pv_maximo / 2
	if valor > 0 and ser.pv > 0 and ser.pv < teto:
		ser.curar(mini(valor, teto - ser.pv))


## Manipular Entropia (p.115): 2 PE para outro ser em alcance curto rolar de novo um dado do teste.
func manipular_entropia(agente: Agente, alvo: Ser, resultado: ResultadoTeste) -> bool:
	if not agente.tem_habilidade("manipular_entropia") or not _perto(agente, alvo, "curto") or not agente.gastar_pe(2, true):
		return false
	Teste.rerrolar_escolhido(dados, resultado)
	return true


## Surto Temporal (p.115): uma vez por cena, no seu turno, 3 PE por uma ação padrão a mais.
func surto_temporal(agente: Agente) -> bool:
	if not agente.tem_habilidade("surto_temporal") or agente.usos_na_cena.has("surto_temporal"):
		return false
	if not acoes.has(agente) or not agente.gastar_pe(3, true):
		return false
	agente.usos_na_cena["surto_temporal"] = 1
	acoes[agente].padrao += 1
	return true


## Arma de Sangue (p.116): ação de movimento + 2 PE; garras de sangue até o fim da cena.
func criar_arma_de_sangue(agente: Agente) -> bool:
	var ef := agente.efeitos("arma_de_sangue")
	if ef.is_empty() or agente.mods_cena.has("arma_de_sangue") or not gastar_acao(agente, "movimento"):
		return false
	if not agente.gastar_pe(2, true):
		acoes[agente].movimento += 1
		return false
	agente.mods_cena["arma_de_sangue"] = String(ef[ef.size() - 1].dano)
	return true


func arma_de_sangue(agente: Agente) -> Dictionary:
	if not agente.mods_cena.has("arma_de_sangue"):
		return {}
	return {"id": "arma_de_sangue", "nome": "Arma de Sangue", "dano": agente.mods_cena.arma_de_sangue, "margem": 20, "multiplicador": 2,
		"tipo_dano": "sangue", "pericia": "luta", "soma_forca": true, "ataque": "corpo_a_corpo", "leve": true}


## Ataque extra com a Arma de Sangue: uma vez por turno, depois de agredir, 1 PE.
func ataque_arma_de_sangue(agente: Agente, alvo: Ser) -> ResultadoAtaque:
	var arma := arma_de_sangue(agente)
	if arma.is_empty() or int(_ataques_no_turno.get(agente, 0)) == 0 or _usou_na_rodada(agente, "arma_de_sangue_extra"):
		return _ataque_invalido(agente, alvo, arma)
	if not agente.gastar_pe(1, true):
		return _ataque_invalido(agente, alvo, arma)
	_marcar_uso_rodada(agente, "arma_de_sangue_extra")
	return atacar(agente, alvo, arma)


func _aplicar_efeito_ritual(conjurador: Agente, ritual_id: String, r: Dictionary, e: Dictionary, alvo: Ser, res: Dictionary) -> void:
	var passou := false
	if e.has("resistencia") and alvo != conjurador:
		var tr := _resistir_ritual(conjurador, ritual_id, r, alvo, e.resistencia)
		res.teste_resistencia = tr
		passou = tr.sucesso
		res.textos.append("%s resiste (%s): %s." % [alvo.nome, ruleset.pericia(e.resistencia).nome, "passou" if passou else "falhou"])
	match e.tipo:
		"dano":
			var dano := dados.rolar_expressao(e.dados) + conjurador.bonus_ritual_potente()
			if passou and e.get("ao_passar", "") == "metade":
				dano /= 2
			var real := aplicar_dano(alvo, dano, e.get("tipo_dano", r.elemento), 0, conjurador)
			res.dano = real
			res.textos.append("%d de dano." % real)
			if e.has("drena") and real > 0:
				var cura := int(real * float(e.drena))
				conjurador.curar(cura)
				res.textos.append("%s recupera %d PV." % [conjurador.nome, cura])
			if not passou and e.has("condicao"):
				alvo.aplicar_condicao(e.condicao, int(e.get("rodadas", 0)))
				res.textos.append("%s fica %s." % [alvo.nome, e.condicao])
			if not passou and e.has("hemorragia"):
				alvo.hemorragia = {"dados": e.hemorragia, "dt": conjurador.dt_ritual(ritual_id), "sucessos": 0}
				res.textos.append("%s começa a sangrar." % alvo.nome)
		"cura":
			var cura := dados.rolar_expressao(e.dados) + conjurador.bonus_ritual_potente()
			alvo.curar(cura)
			res.cura = cura
			res.textos.append("%s recupera %d PV." % [alvo.nome, cura])
		"pv_temporario":
			var pvt := dados.rolar_expressao(String(e.dados))
			alvo.pv_temporario = maxi(alvo.pv_temporario, pvt)
			res.textos.append("%s recebe %d PV temporários." % [alvo.nome, pvt])
		"transfusao":
			var qtd := mini(int(e.maximo), mini(conjurador.pv - 1, alvo.pv_maximo - alvo.pv))
			if qtd > 0:
				conjurador.pv -= qtd
				conjurador._atualizar_pv()
				alvo.curar(qtd)
			res.textos.append("%s transfere %d PV para %s." % [conjurador.nome, maxi(0, qtd), alvo.nome])
		"condicao":
			if passou and e.has("ao_passar_condicao"):
				alvo.aplicar_condicao(e.ao_passar_condicao, int(e.get("rodadas", 0)))
				res.textos.append("%s fica %s." % [alvo.nome, e.ao_passar_condicao])
			elif not passou:
				alvo.aplicar_condicao(e.condicao, int(e.get("rodadas", 0)))
				res.textos.append("%s fica %s." % [alvo.nome, e.condicao])
		"buff", "debuff", "arma":
			var ativo := e.duplicate()
			if e.get("atributo", "") == "fisico":
				ativo["atributo_" + ("for" if alvo.atributo("for") >= alvo.atributo("agi") else "agi")] = int(e.valor)
			elif e.get("atributo", "") == "mental":
				ativo["atributo_" + ("int" if alvo.atributo("int") >= alvo.atributo("pre") else "pre")] = int(e.valor)
			ativo.conjurador = conjurador
			alvo.rituais_ativos[ritual_id] = ativo
			if e.get("sustentado", false):
				_sustentados = _sustentados.filter(func(s): return s.conjurador != conjurador)   # só um sustentado por vez
				_sustentados.append({"conjurador": conjurador, "alvo": alvo, "ritual": ritual_id})
			res.textos.append("O efeito dura %s." % ("enquanto sustentado" if e.get("sustentado", false) else "até o fim da cena"))


## Sustentado (p.130): 1 PE no início de cada turno do conjurador, ou o ritual termina.
func _manter_sustentados(ser: Ser) -> void:
	for s in _sustentados.duplicate():
		if s.conjurador != ser:
			continue
		if not (ser as Agente).gastar_pe(1, true):
			s.alvo.rituais_ativos.erase(s.ritual)
			_sustentados.erase(s)
			_log("%s não sustenta mais %s." % [ser.nome, ruleset.ritual(s.ritual).nome])


## Hemorragia (Descarnar): no início do turno, Fortitude; falha sofre o dano, dois sucessos seguidos estancam.
func _processar_hemorragia(ser: Ser) -> void:
	if ser.hemorragia.is_empty():
		return
	var h: Dictionary = ser.hemorragia
	var t := Teste.rolar(dados, ser.dados_da_pericia("fortitude"), ser.bonus_pericia("fortitude"), int(h.dt))
	if t.sucesso:
		h.sucessos += 1
		if h.sucessos >= 2:
			ser.hemorragia = {}
			_log("A hemorragia de %s estanca." % ser.nome)
	else:
		h.sucessos = 0
		var dano := aplicar_dano(ser, dados.rolar_expressao(h.dados), "sangue")
		_log("%s sangra: %d de dano." % [ser.nome, dano])


func _log(texto: String) -> void:
	registro.emit(texto)


# --- Reações (p.88) --------------------------------------------------------

## O alvo declara uma reação de defesa contra o PRÓXIMO ataque que sofrer.
## Uma por rodada; exige treino (bloqueio: Fortitude, esquiva: Reflexos, contra-ataque: Luta).
## `arma` é usada no contra-ataque e no Revidar. `revidar`: Guerreiro 40%, ataca após bloquear (2 PE).
func declarar_reacao(ser: Ser, tipo: String, arma: Dictionary = {}, revidar: bool = false) -> bool:
	if not tipo in REACOES or ser.reacao_usada or ser.esta_fora_de_combate():
		return false
	var pericia_exigida: String = {"bloqueio": "fortitude", "esquiva": "reflexos", "contra_ataque": "luta"}[tipo]
	if not ser.treinado_em(pericia_exigida):
		return false
	if tipo == "contra_ataque" and arma.get("ataque", "") != "corpo_a_corpo":
		return false
	if revidar and (tipo != "bloqueio" or not ser is Agente or not (ser as Agente).tem_habilidade("revidar") or arma.get("ataque", "") != "corpo_a_corpo"):
		return false
	_reacoes_declaradas[ser] = {"tipo": tipo, "arma": arma, "revidar": revidar}
	return true


## Duro de Matar (Tropa de Choque 65%) ou Abraçar a Dor (Flagelador 40%): reação + 2 PE para
## reduzir à metade o PRÓXIMO dano não paranormal (Duro de Matar vale para paranormal em NEX 85%).
func declarar_reducao_dano(ser: Ser) -> bool:
	if not ser is Agente:
		return false
	var ag := ser as Agente
	for hab_id in ["duro_de_matar", "abracar_a_dor"]:
		if ag.tem_habilidade(hab_id):
			_reducoes_declaradas[ser] = hab_id
			return true
	return false


# --- Ataque ----------------------------------------------------------------

## Ataque com uma arma (dicionário no formato de armas.json). Não gasta ação: use agredir().
## - `pe_foco`: PE gastos como Foco (+1 d20 cada). Só agentes gastam PE.
## - `opcoes`:
##     "ataque_especial": {"ataque": 5, "dano": 5}  — combatente (custo pelo NEX)
##     "combate_defensivo": true    — −1 dado nos ataques e +5 Defesa até o próximo turno
##     "ataque_furtivo": true       — Infiltrador: 1 PE, dano extra contra desprevenido/flanqueado
##     "flanqueando": true          — +1 dado em corpo a corpo (p.89)
##     "alvo_em_corpo_a_corpo": true — ataque à distância contra alvo engajado: −1 dado (p.85)
func atacar(atacante: Ser, alvo: Ser, arma_base: Dictionary, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoAtaque:
	var res := ResultadoAtaque.new()
	res.atacante = atacante
	res.alvo = alvo
	var arma: Dictionary = (atacante as Agente).arma_efetiva(arma_base) if atacante is Agente else arma_base
	res.arma = arma
	var agente: Agente = atacante as Agente
	var mods := atacante.modificar_ataque(arma, alvo)
	var tipo_ataque: String = arma.get("ataque", "corpo_a_corpo")
	var eh_corpo_a_corpo := tipo_ataque == "corpo_a_corpo"
	var dados_extras := pe_foco + int(mods.dados_extras)
	var bonus_ataque := int(mods.bonus_ataque)
	var bonus_dano := int(mods.bonus_dano)
	var margem_extra := int(mods.margem)
	var custo := pe_foco
	var no_minimo := false   # o gasto é só uma habilidade no custo mínimo (regra da p.33)
	var fontes := 0

	# Situação na grade: distância, alcance, flanco, cobertura (p.85-89, p.99)
	var cobertura_leve := false
	if grade != null and grade.tem(atacante) and grade.tem(alvo) and not opcoes.get("ignorar_distancia", false):
		opcoes = opcoes.duplicate()
		if eh_corpo_a_corpo:
			if not grade.estao_adjacentes(atacante, alvo):
				return _ataque_invalido(atacante, alvo, arma)
			opcoes["flanqueando"] = grade.flanqueando(atacante, alvo)
		else:
			var faixa := grade.faixa_de_alcance(atacante, alvo, arma.get("alcance", "curto"))
			if faixa == "fora":
				return _ataque_invalido(atacante, alvo, arma)
			if faixa == "longe":
				dados_extras -= 1
			var cob := grade.cobertura(atacante, alvo)
			if cob == "total":
				return _ataque_invalido(atacante, alvo, arma)
			cobertura_leve = cob == "leve"
			opcoes["alvo_em_corpo_a_corpo"] = grade.em_corpo_a_corpo(alvo)
	if opcoes.get("flanqueando", false) and eh_corpo_a_corpo:
		dados_extras += 1
	var mira: Dictionary = _miras.get(atacante, {})
	var mirando: bool = not mira.is_empty() and mira.alvo == alvo and not eh_corpo_a_corpo
	if opcoes.get("alvo_em_corpo_a_corpo", false) and not eh_corpo_a_corpo:
		var ignora: bool = mirando or (agente != null and agente.tem_habilidade("tiro_certeiro"))
		if not ignora:
			dados_extras -= 1
	if mirando:
		margem_extra += int(mira.margem)
		_miras.erase(atacante)

	# Opções pagas
	if opcoes.has("ataque_especial"):
		if agente == null:
			return res
		var ae: Dictionary = agente.plano_ataque_especial(int(opcoes.ataque_especial.get("ataque", 0)), int(opcoes.ataque_especial.get("dano", 0)), arma)
		if ae.is_empty():
			return res
		custo += int(ae.custo)
		fontes += 1
		no_minimo = ae.minimo
		bonus_ataque += int(ae.bonus_ataque)
		bonus_dano += int(ae.bonus_dano)
	var combate_defensivo: bool = opcoes.get("combate_defensivo", false)
	if combate_defensivo:
		if agente == null or agente.efeitos("opcao_combate_defensivo").is_empty():
			return res
		dados_extras -= 1
	var furtivo_dados := 0
	if opcoes.get("ataque_furtivo", false):
		furtivo_dados = _dados_ataque_furtivo(agente, alvo, arma, opcoes)
		if furtivo_dados == 0:
			return res
		custo += 1
		fontes += 1
		no_minimo = fontes == 1

	if custo > 0:
		if agente == null or not agente.gastar_pe(custo, no_minimo and fontes == 1 and pe_foco == 0):
			return res
	res.pe_gasto = custo
	if furtivo_dados > 0:
		_marcar_uso_rodada(atacante, "ataque_furtivo")
	if combate_defensivo:
		atacante.defesa_temporaria += 5
		atacante.penalidade_ataque_temporaria += 1

	# Reação declarada pelo alvo
	var reacao: Dictionary = _reacoes_declaradas.get(alvo, {})
	_reacoes_declaradas.erase(alvo)
	var defesa := alvo.defesa() + (5 if cobertura_leve else 0)
	var rd_extra := 0
	if not reacao.is_empty():
		match reacao.tipo:
			"esquiva":
				defesa += alvo.bonus_pericia("reflexos")
				res.reacao = "esquiva"
				if alvo is Agente:
					var campo := (alvo as Agente).efeitos("campo_protetor")
					if not campo.is_empty() and (alvo as Agente).gastar_pe(1, true):
						defesa += int(campo[0].valor)   # Campo Protetor (p.115)
				if alvo is Agente:
					(alvo as Agente).sofrer_dano_por_teste(dados, "agi", true)   # Gota
			"bloqueio":
				if eh_corpo_a_corpo:
					rd_extra = _rd_bloqueio(alvo)
					res.reacao = "bloqueio"
			"contra_ataque":
				if eh_corpo_a_corpo:
					res.reacao = "contra_ataque"
		if res.reacao != "":
			alvo.reacao_usada = true

	var pericia_id: String = arma.get("pericia", "luta")
	res.teste = Teste.rolar(dados, atacante.dados_da_pericia(pericia_id), atacante.bonus_pericia(pericia_id) + bonus_ataque, defesa, dados_extras)
	if agente != null:
		agente.sofrer_dano_por_teste(dados, ruleset.atributo_da_pericia(pericia_id))   # Gota, Pulmão Ruim
	res.acertou = res.teste.sucesso
	if agente != null and not res.acertou:
		agente.pagar_preco_da_maldicao(ruleset.atributo_da_pericia(pericia_id))
	_ataques_no_turno[atacante] = int(_ataques_no_turno.get(atacante, 0)) + 1
	_ultimo_ataque[atacante] = res
	if res.acertou:
		var margem_base := int(arma.get("margem", 20))
		var maldicoes_arma: Array = arma.get("maldicoes", [])
		if maldicoes_arma.any(func(m): return m.get("implementado", false) and m.efeitos.any(func(x): return x.tipo == "arma_margem_dobrada")):
			margem_base = 21 - 2 * (21 - margem_base)   # Predadora: dobra a margem antes dos aumentos
		var margem := margem_base - margem_extra
		res.critico = res.teste.escolhido >= margem
		if res.critico and alvo is Agente:
			var chance := 0
			for ef in (alvo as Agente).efeitos("ignora_critico"):
				var pesada: bool = (alvo as Agente).protecao().get("base", (alvo as Agente).protecao().get("id", "")) == "protecao_pesada"
				chance += int(ef.get("chance_pesada", ef.chance)) if pesada else int(ef.chance)
			if chance > 0 and dados.rolar(100) <= chance:
				res.critico = false   # Anatomia Insana / Letárgica
				res.critico_ignorado = true
		var mult_critico := int(arma.get("multiplicador", 2))
		if agente != null:
			mult_critico += agente._soma_efeitos("multiplicador_critico")
		var mult := mult_critico if res.critico else 1
		var e := Dados.interpretar(arma.get("dano", "1d3"))
		var qtd: int = e.quantidade + int(mods.dados_dano_extra)
		var dano := 0
		if res.critico and tipo_ataque == "fogo" and agente != null and agente.tem_habilidade("atirar_para_matar"):
			dano = qtd * mult * int(e.faces) + int(e.bonus)   # dano máximo, sem rolar
		else:
			dano = dados.rolar_expressao("%dd%d+%d" % [qtd, e.faces, e.bonus], mult)
		dano += bonus_dano
		if arma.get("soma_forca", false):
			dano += atacante.atributo("for")
		if furtivo_dados > 0:
			dano += dados.rolar_expressao("%dd6" % furtivo_dados)   # dados extras não multiplicam
		for expr in String(mods.get("dados_dano_ritual", "")).split("+", false):
			dano += dados.rolar_expressao(expr)   # Amaldiçoar Arma (não multiplica no crítico)
		for m in maldicoes_arma:
			if not m.get("implementado", false):
				continue
			for ef in m.efeitos:
				if ef.tipo == "arma_dano_extra":
					dano += dados.rolar_expressao(ef.dados, mult if ef.get("multiplica", false) else 1)
		res.dano_bruto = maxi(1, dano)
		res.dano = aplicar_dano(alvo, res.dano_bruto, arma.get("tipo_dano", ""), rd_extra, atacante)
		if eh_corpo_a_corpo and agente != null and agente.tem_habilidade("gladiador_paranormal"):
			_gladiador_paranormal(agente)
	if not res.acertou:
		for r in alvo.rituais_ativos.values():
			if int(r.get("embaralhar", 0)) > 0:
				r.embaralhar = maxi(0, int(r.embaralhar) - 2)   # uma cópia ilusória some
				break
	if res.reacao == "contra_ataque" and not res.acertou:
		res.contra_ataque = atacar(alvo, atacante, reacao.arma)
	elif res.reacao == "bloqueio" and reacao.get("revidar", false) and (alvo as Agente).gastar_pe(2):
		res.contra_ataque = atacar(alvo, atacante, reacao.arma)
	ataque_resolvido.emit(res)
	_verificar_fim()
	return res


func _ataque_invalido(atacante: Ser, alvo: Ser, arma: Dictionary) -> ResultadoAtaque:
	var res := ResultadoAtaque.new()
	res.atacante = atacante
	res.alvo = alvo
	res.arma = arma
	return res


## Aplica dano já rolado (p.98, ordem da p.322): metade por habilidades declaradas,
## depois resistência (tipo + `rd_extra`), depois o teste de dano massivo.
## Retorna o dano efetivamente sofrido.
func aplicar_dano(alvo: Ser, dano: int, tipo_dano: String = "", rd_extra: int = 0, atacante: Ser = null) -> int:
	var paranormal: bool = tipo_dano in TIPOS_PARANORMAIS
	if _reducoes_declaradas.has(alvo):
		var hab_id: String = _reducoes_declaradas[alvo]
		var ag := alvo as Agente
		var vale: bool = not paranormal or (hab_id == "duro_de_matar" and ag.nex >= 85)
		if vale and ag.gastar_pe(2):
			_reducoes_declaradas.erase(alvo)
			dano = dano / 2
	var final := maxi(0, dano - alvo.resistencia(tipo_dano) - rd_extra)
	if final <= 0:
		return 0
	alvo.registrar_atacante(atacante)
	if atacante != null:
		_danificados_na_rodada[alvo] = atacante.lado
	alvo.sofrer_dano(final)
	if alvo is Agente and alvo.pv > 0 and final * 2 >= alvo.pv_maximo:
		var dt := 15 + 2 * (final / 10)
		var r := Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), dt)
		if not r.sucesso:
			(alvo as Agente)._dano_massivo = true
			alvo.sofrer_dano(alvo.pv)
			(alvo as Agente)._dano_massivo = false
			(alvo as Agente).pagar_preco_da_maldicao("vig")
		else:
			_ao_passar_resistencia(alvo)
	return final


func _rd_bloqueio(ser: Ser) -> int:
	var rd := ser.bonus_pericia("fortitude")
	if ser is Agente:
		for e in (ser as Agente).efeitos("bloqueio_soma_atributo"):
			rd += ser.atributo(e.atributo)
	return rd


# --- Poderes de combate ----------------------------------------------------

func _usou_na_rodada(ser: Ser, hab_id: String) -> bool:
	return _usos_rodada.get(ser, {}).has(hab_id)


func _marcar_uso_rodada(ser: Ser, hab_id: String) -> void:
	_usos_rodada.get_or_add(ser, {})[hab_id] = true


## Ataque Furtivo (Infiltrador 10%): 1d6 a mais por marco (10/40/65/99), uma vez por rodada,
## contra alvo desprevenido ou flanqueado, em corpo a corpo ou alcance curto. Retorna os d6 (0 = não pode).
func _dados_ataque_furtivo(agente: Agente, alvo: Ser, arma: Dictionary, opcoes: Dictionary) -> int:
	if agente == null or not agente.tem_habilidade("ataque_furtivo") or _usou_na_rodada(agente, "ataque_furtivo"):
		return 0
	var vulneravel: bool = alvo.tem(Ser.DESPREVENIDO) or alvo.tem(Ser.SURPREENDIDO) or alvo.esta_indefeso() or opcoes.get("flanqueando", false)
	var perto: bool = arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo" or _perto(agente, alvo, "curto")
	if not vulneravel or not perto:
		return 0
	return [10, 40, 65, 99].filter(func(n): return agente.nex >= n).size()


## Gladiador Paranormal (Lâmina Paranormal 40%): +2 PE temporários por acerto corpo a corpo,
## até o limite de PE por cena.
func _gladiador_paranormal(agente: Agente) -> void:
	var ganho := int(agente.usos_na_cena.get("gladiador_pe", 0))
	var pode := mini(2, agente.limite_pe() - ganho)
	if pode > 0:
		agente.ganhar_pe_temporario(pode)
		agente.usos_na_cena["gladiador_pe"] = ganho + pode


## Combater com Duas Armas: dois ataques com a ação Agredir; −1 dado em todos os ataques até o próximo turno.
func agredir_com_duas_armas(atacante: Agente, alvo: Ser, arma1: Dictionary, arma2: Dictionary) -> Array[ResultadoAtaque]:
	var resultados: Array[ResultadoAtaque] = []
	if not atacante.tem_habilidade("combater_com_duas_armas"):
		return resultados
	if not (arma1.get("leve", false) or arma2.get("leve", false)):
		return resultados
	if not gastar_acao(atacante, "padrao"):
		return resultados
	atacante.penalidade_ataque_temporaria += 1
	resultados.append(atacar(atacante, alvo, arma1))
	if not encerrado:
		resultados.append(atacar(atacante, alvo, arma2))
	return resultados


## Ataque Extra (Operações Especiais 40%): uma vez por rodada, depois de atacar, 2 PE para outro ataque.
func ataque_extra(atacante: Agente, alvo: Ser, arma: Dictionary, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoAtaque:
	if not atacante.tem_habilidade("ataque_extra") or _usou_na_rodada(atacante, "ataque_extra"):
		return _ataque_invalido(atacante, alvo, arma)
	if int(_ataques_no_turno.get(atacante, 0)) == 0 or not atacante.gastar_pe(2):
		return _ataque_invalido(atacante, alvo, arma)
	_marcar_uso_rodada(atacante, "ataque_extra")
	return atacar(atacante, alvo, arma, pe_foco, opcoes)


## Segurar o Gatilho (poder, NEX 60%): após acertar com arma de fogo, outro ataque na mesma arma e
## alvo, pagando 2 PE por ataque já feito no turno.
func segurar_o_gatilho(atacante: Agente, alvo: Ser, arma: Dictionary) -> ResultadoAtaque:
	var anterior: ResultadoAtaque = _ultimo_ataque.get(atacante)
	if not atacante.tem_habilidade("segurar_o_gatilho") or anterior == null:
		return _ataque_invalido(atacante, alvo, arma)
	if not anterior.acertou or anterior.alvo != alvo or anterior.arma.get("id", "") != arma.get("id", "") or arma.get("ataque", "") != "fogo":
		return _ataque_invalido(atacante, alvo, arma)
	if not atacante.gastar_pe(2 * int(_ataques_no_turno.get(atacante, 0))):
		return _ataque_invalido(atacante, alvo, arma)
	return atacar(atacante, alvo, arma)


## Surto de Adrenalina (Operações Especiais 65%): uma vez por rodada, 5 PE por uma ação extra.
func surto_de_adrenalina(ser: Agente, tipo: String) -> bool:
	if not ser.tem_habilidade("surto_de_adrenalina") or _usou_na_rodada(ser, "surto_de_adrenalina"):
		return false
	if not tipo in ["padrao", "movimento"] or not acoes.has(ser) or not ser.gastar_pe(5):
		return false
	_marcar_uso_rodada(ser, "surto_de_adrenalina")
	acoes[ser][tipo] += 1
	return true


## Posição de Combate (origem Mercenário): no 1º turno da cena, 2 PE por uma ação de movimento extra.
func posicao_de_combate(ser: Agente) -> bool:
	if rodada != 1 or not ser.tem_habilidade("posicao_de_combate") or _usou_na_rodada(ser, "posicao_de_combate"):
		return false
	if not acoes.has(ser) or not ser.gastar_pe(2, true):
		return false
	_marcar_uso_rodada(ser, "posicao_de_combate")
	acoes[ser].movimento += 1
	return true


## Mirar (p.87): ação de movimento, exige Pontaria treinada. Contra o alvo mirado, anula a
## penalidade por alvo em corpo a corpo até o fim do próximo turno. Disparo Letal: +1 PE, margem +2.
func mirar(ser: Ser, alvo: Ser, disparo_letal: bool = false) -> bool:
	if not ser.treinado_em("pontaria"):
		return false
	if disparo_letal and not (ser is Agente and (ser as Agente).tem_habilidade("disparo_letal")):
		return false
	if not gastar_acao(ser, "movimento"):
		return false
	var margem := 0
	if disparo_letal:
		if not (ser as Agente).gastar_pe(1, true):
			acoes[ser].movimento += 1   # devolve a ação
			return false
		margem = 2
	_miras[ser] = {"alvo": alvo, "margem": margem, "turnos": 2}
	return true


## Sentido Tático (poder): ação de movimento + 2 PE: soma Intelecto na Defesa e nos testes de
## resistência até o fim da cena (não acumula consigo mesmo).
func sentido_tatico(ser: Agente) -> bool:
	if not ser.tem_habilidade("sentido_tatico") or ser.mods_cena.has("sentido_tatico"):
		return false
	if not gastar_acao(ser, "movimento"):
		return false
	if not ser.gastar_pe(2, true):
		acoes[ser].movimento += 1
		return false
	var intelecto := ser.atributo("int")
	ser.mods_cena["sentido_tatico"] = true
	ser.mods_cena["defesa"] = int(ser.mods_cena.get("defesa", 0)) + intelecto
	ser.mods_cena["resistencia_testes"] = int(ser.mods_cena.get("resistencia_testes", 0)) + intelecto
	return true


## Tiro de Cobertura (poder): ação padrão + 1 PE; Pontaria contra Vontade do alvo (+5 se o lugar for
## muito perigoso). Vencendo, até o início do próximo turno do atirador o alvo fica imóvel e sofre −5 nos ataques.
func tiro_de_cobertura(atirador: Agente, alvo: Ser, arma: Dictionary, lugar_perigoso: bool = false) -> bool:
	if not atirador.tem_habilidade("tiro_de_cobertura") or arma.get("ataque", "") != "fogo":
		return false
	if not gastar_acao(atirador, "padrao"):
		return false
	if not atirador.gastar_pe(1, true):
		acoes[atirador].padrao += 1
		return false
	var venceu := _teste_oposto(atirador, "pontaria", 0, alvo, "vontade", 5 if lugar_perigoso else 0)
	if venceu:
		_aplicar_efeito_ate_turno({"origem": atirador, "alvo": alvo, "tipo": "cobertura"})
	return venceu


## Estrategista (Comandante de Campo 40%): ação padrão + 1 PE por aliado (até o Intelecto):
## no próximo turno, cada aliado ganha uma ação de movimento extra.
func estrategista(comandante: Agente, aliados: Array) -> bool:
	if not comandante.tem_habilidade("estrategista") or aliados.is_empty() or aliados.size() > comandante.atributo("int"):
		return false
	var alcance := "medio" if comandante.tem_habilidade("brecha_na_guarda") else "curto"
	if aliados.any(func(a): return not _perto(comandante, a, alcance)):
		return false
	if not gastar_acao(comandante, "padrao"):
		return false
	if not comandante.gastar_pe(aliados.size(), aliados.size() == 1):
		acoes[comandante].padrao += 1
		return false
	for aliado in aliados:
		_movimentos_extras[aliado] = int(_movimentos_extras.get(aliado, 0)) + 1
	return true


## Oficial Comandante (Comandante de Campo 99%): ação padrão + 5 PE: cada aliado ganha uma ação
## padrão extra no próximo turno.
func oficial_comandante(comandante: Agente) -> bool:
	if not comandante.tem_habilidade("oficial_comandante") or not gastar_acao(comandante, "padrao"):
		return false
	if not comandante.gastar_pe(5, true):
		acoes[comandante].padrao += 1
		return false
	for s in participantes:
		if s != comandante and s.lado == comandante.lado and not s.esta_fora_de_combate() and _perto(comandante, s, "medio"):
			s.acoes_padrao_extras += 1
	return true


## Inspirar Confiança (Comandante de Campo 10%): reação + 2 PE: um aliado rerrola um teste recém-feito.
func inspirar_confianca(comandante: Agente, resultado: ResultadoTeste, aliado: Ser = null) -> ResultadoTeste:
	var alcance := "medio" if comandante.tem_habilidade("brecha_na_guarda") else "curto"
	if aliado != null and not _perto(comandante, aliado, alcance):
		return null
	if not comandante.tem_habilidade("inspirar_confianca") or not comandante.gastar_pe(2, true):
		return null
	return Teste.rerrolar(dados, resultado)


## Brecha na Guarda (Comandante de Campo 65%): uma vez por rodada, depois que um aliado ferir um
## inimigo, reação + 2 PE para você ou outro aliado atacar esse inimigo.
func brecha_na_guarda(comandante: Agente, atacante: Ser, alvo: Ser, arma: Dictionary) -> ResultadoAtaque:
	if not comandante.tem_habilidade("brecha_na_guarda") or _usou_na_rodada(comandante, "brecha_na_guarda"):
		return _ataque_invalido(atacante, alvo, arma)
	if _danificados_na_rodada.get(alvo, "") != comandante.lado or atacante.lado != comandante.lado:
		return _ataque_invalido(atacante, alvo, arma)
	if not _perto(comandante, alvo, "curto") or (atacante != comandante and not _perto(comandante, atacante, "curto")):
		return _ataque_invalido(atacante, alvo, arma)
	if not comandante.gastar_pe(2, true):
		return _ataque_invalido(atacante, alvo, arma)
	_marcar_uso_rodada(comandante, "brecha_na_guarda")
	return atacar(atacante, alvo, arma)


## Cai Dentro (Tropa de Choque 40%): quando um inimigo vai atacar um aliado, reação + 1 PE; o inimigo
## faz Vontade contra DT Vig. Falhando, deve atacar você (retorna true). Passando, fica imune na cena.
func cai_dentro(tropa: Agente, inimigo: Ser) -> bool:
	if not tropa.tem_habilidade("cai_dentro") or _imunes_cai_dentro.has(inimigo) or tropa.esta_fora_de_combate():
		return false
	if not _perto(tropa, inimigo, "curto"):
		return false
	if not tropa.gastar_pe(1, true):
		return false
	var r := Teste.rolar(dados, inimigo.dados_da_pericia("vontade"), inimigo.bonus_pericia("vontade"), tropa.dt_habilidade("vig"))
	if r.sucesso:
		_imunes_cai_dentro[inimigo] = true
		return false
	return true


func _teste_oposto(a: Ser, pericia_a: String, bonus_a: int, b: Ser, pericia_b: String, bonus_b: int) -> bool:
	for _i in 10:
		var ra := Teste.rolar(dados, a.dados_da_pericia(pericia_a), a.bonus_pericia(pericia_a) + bonus_a, 0)
		var rb := Teste.rolar(dados, b.dados_da_pericia(pericia_b), b.bonus_pericia(pericia_b) + bonus_b, 0)
		if ra.total != rb.total:
			return ra.total > rb.total
	return false


func _aplicar_efeito_ate_turno(ef: Dictionary) -> void:
	match ef.tipo:
		"cobertura":
			ef.alvo.condicoes[Ser.IMOVEL] = true
			ef.alvo.mods_cena["penalidade_ataque"] = int(ef.alvo.mods_cena.get("penalidade_ataque", 0)) + 5
	_efeitos_ate_turno.append(ef)


func _desfazer_efeito(ef: Dictionary) -> void:
	match ef.tipo:
		"cobertura":
			ef.alvo.condicoes.erase(Ser.IMOVEL)
			ef.alvo.mods_cena["penalidade_ataque"] = maxi(0, int(ef.alvo.mods_cena.get("penalidade_ataque", 0)) - 5)


# --- Regras opcionais ------------------------------------------------------

## Lesões (p.184): ao iniciar o turno morrendo pela 2ª vez na cena, teste de Vigor DT 10.
## Falhou: perde 1 ponto permanente num atributo sorteado por 1d6 (6 = nenhum).
func _verificar_lesao(ser: Ser) -> void:
	if not regras.get("lesoes", false) or not ser is Agente:
		return
	if not ser.tem(Ser.MORRENDO) or ser.turnos_morrendo() != 2:
		return
	var agente := ser as Agente
	var r := Teste.rolar(dados, agente.atributo("vig"), 0, 10)
	if r.sucesso:
		return
	var d6 := dados.rolar(6)
	if d6 > ORDEM_LESAO.size():
		return
	var attr_id: String = ORDEM_LESAO[d6 - 1]
	agente.atributos[attr_id] = maxi(0, int(agente.atributos.get(attr_id, 0)) - 1)
	agente.lesoes.append(attr_id)
	agente.recalcular_maximos()
	lesao_sofrida.emit(agente, attr_id)


func _ao_morrer(ser: Ser) -> void:
	if regras.get("inspiracao_resoluta", false) and ser is Agente:
		_mortos_inspiradores.append(ser as Agente)


## Inspiração Resoluta (p.184): no início de cada rodada, cada agente morto na cena rola 1d10.
func _sortear_inspiracoes() -> void:
	for morto in _mortos_inspiradores:
		var efeito: String = INSPIRACOES[dados.rolar(10) - 1]
		inspiracoes_pendentes.append({"morto": morto, "efeito": efeito})
		inspiracao_disponivel.emit(morto, efeito)


## Concede uma inspiração pendente a um aliado vivo.
func aplicar_inspiracao(indice: int, aliado: Agente) -> bool:
	if indice < 0 or indice >= inspiracoes_pendentes.size() or aliado.tem(Ser.MORTO):
		return false
	var insp: Dictionary = inspiracoes_pendentes.pop_at(indice)
	var morto: Agente = insp.morto
	match insp.efeito:
		"chamas_da_vinganca":
			var assassino := morto.ultimo_atacante()
			if assassino != null:
				var contra: Dictionary = aliado.mods_cena.get_or_add("ataque_contra", {})
				contra[assassino] = int(contra.get(assassino, 0)) + 5
		"forca_do_odio":
			var attrs: Dictionary = aliado.mods_cena.get_or_add("atributos", {})
			attrs["for"] = int(attrs.get("for", 0)) + 2
			aliado.acoes_padrao_extras += 1
		"mente_em_luto":
			var res: Dictionary = aliado.mods_cena.get_or_add("resistencias", {})
			res["mental"] = maxi(int(res.get("mental", 0)), 10)
		"resoluto":
			aliado.curar(dados.rolar_expressao("4d8+4"))
			aliado.recuperar_pe(dados.rolar_expressao("2d6"))
		"loucura_selvagem":
			aliado.condicoes.erase(Ser.PARALISADO)
			aliado.acoes_padrao_extras += 1
	return true


# --- Fim -------------------------------------------------------------------

## Lado que ainda tem alguém de pé, ou "" se o combate continua.
func lado_vencedor() -> String:
	var de_pe: Dictionary = {}
	for ser in participantes:
		if not ser.esta_fora_de_combate():
			de_pe[ser.lado] = true
	if de_pe.size() == 1:
		return de_pe.keys()[0]
	if de_pe.is_empty():
		return "nenhum"
	return ""


func _verificar_fim() -> bool:
	if encerrado:
		return true
	var vencedor := lado_vencedor()
	if vencedor != "":
		encerrado = true
		for ef in _efeitos_ate_turno:
			_desfazer_efeito(ef)
		_efeitos_ate_turno.clear()
		for ser in participantes:
			ser.encerrar_cena()
		combate_encerrado.emit(vencedor)
		return true
	return false
