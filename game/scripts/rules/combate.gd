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
signal ser_adicionado(ser: Ser)   ## um ser entrou no meio do combate (cópias do escutado)

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
## Áreas persistentes de rituais (Poeira da Podridão, Purgatório, Tentáculos de Lodo…):
## {conjurador, ritual, efeito, celulas, gatilho ("turno_conjurador"|"turno_ser"|"nenhum"), rodadas, agarrados}
var _zonas: Array[Dictionary] = []
var _melodia_rodada := -10          ## última rodada em que a melodia do escutado tocou
var _melodia_quem: Ser               ## quem toca a melodia (o escutado vai atrás)
var _consumidos: Array[Ser] = []     ## cadáveres que a Dama de Sangue já consumiu


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
	for s in participantes:
		if s is Ameaca and (s as Ameaca).tem_hab("sempre_presente"):
			_escolher_alvo_ocioso(s as Ameaca)
	if regras.get("presenca_perturbadora", false):
		presenca_perturbadora()


## Presença Perturbadora (p.190): ao ver criaturas paranormais, cada agente testa Vontade
## contra a DT da criatura de maior VD; falha sofre o dano mental, sucesso sofre metade.
## Cada criatura a mais na cena soma +1d6. Agentes com o NEX indicado são imunes.
func presenca_perturbadora(fonte: Ameaca = null) -> Array[Dictionary]:
	var resultados: Array[Dictionary] = []
	var criaturas: Array[Ameaca] = []
	for s in participantes:
		if s is Ameaca and not (s as Ameaca).presenca.is_empty() and not s.esta_fora_de_combate() and (fonte == null or s == fonte):
			criaturas.append(s as Ameaca)
	if criaturas.is_empty():
		return resultados
	var pior: Ameaca = criaturas[0]
	for c in criaturas:
		if c.vd > pior.vd:
			pior = c
	var p: Dictionary = pior.presenca
	for s in participantes:
		if not s is Agente or s.esta_fora_de_combate():
			continue
		var ag := s as Agente
		if ag.nex >= int(p.get("nex", 999)):
			resultados.append({"agente": ag, "imune": true, "dano": 0})
			continue
		var dano := dados.rolar_expressao(String(p.dano))
		for _i in criaturas.size() - 1:
			dano += dados.rolar(6)
		var t := ag.testar(dados, "vontade", int(p.dt))
		var passou := t != null and t.sucesso
		if passou:
			dano /= 2
		var san_antes := ag.san
		ag.sofrer_dano_mental(dano)
		resultados.append({"agente": ag, "teste": t, "passou": passou, "dano": san_antes - ag.san})
		_log("[color=#b98ae6]%s encara %s (Vontade DT %d): %s — perde %d de Sanidade.[/color]" % [ag.nome, pior.nome, int(p.dt), "resiste" if passou else "falha", san_antes - ag.san])
	return resultados


func ser_atual() -> Ser:
	return ordem[_indice] if _indice >= 0 and _indice < ordem.size() else null


## Avança para o próximo ser que pode agir e inicia o turno dele.
## Seres morrendo ou enlouquecendo também "iniciam turno" (é aí que a contagem avança).
func proximo_turno() -> Ser:
	if encerrado:
		return null
	if ser_atual() != null:
		_fim_de_turno(ser_atual())
		if encerrado:
			return null
	for _tentativa in ordem.size() * 2:
		_indice += 1
		if _indice >= ordem.size():
			_indice = 0
			rodada += 1
			_danificados_na_rodada.clear()
			_processar_pocas()
			for s in participantes:
				s.condicoes.erase(Ser.SURPREENDIDO)   # surpresa só vale na 1ª rodada
			_sortear_inspiracoes()
		var ser := ordem[_indice]
		if ser.tem(Ser.MORTO):
			continue
		if ser.tem(Ser.SURPREENDIDO):
			turno_perdido.emit(ser, "surpreendido")
			continue
		if ser.tem(Ser.FASCINADO):
			if ser.tem(Ser.AGARRADO):
				ser.iniciar_turno()
				turno_perdido.emit(ser, "fascinado")
				continue
			ser.condicoes.erase(Ser.FASCINADO)
		if ser.tem(Ser.CONFUSO) and not ser.tem(Ser.MORTO):
			if dados.rolar(6) == 6:
				ser.condicoes.erase(Ser.CONFUSO)   # p.320: com 6, a condição termina
			else:
				ser.iniciar_turno()
				turno_perdido.emit(ser, "confuso")
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
		_processar_zonas(ser)
		_inicio_de_turno_ameacas(ser)
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
	if ser.tem(Ser.AGARRADO) and ser.mods_cena.get("agarrado_manobra", false):
		var quem = ser.mods_cena.get("agarrado_por")
		if quem == null or (quem as Ser).esta_fora_de_combate():
			_soltar(ser)
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
	padrao += ser.efeito_ritual("padrao_extra")         # Velocidade Mortal (discente)
	if rodada == 1 and ser is Agente:
		var ag := ser as Agente
		if ag.tem_habilidade("iniciativa_aprimorada"):
			movimento += 1
		if ag.tem_habilidade("sempre_alerta"):
			padrao += 1
	if ser is Ameaca and (ser as Ameaca).tem_hab("senhor_do_tempo"):
		padrao += 1      # Senhor do Tempo: o turno adicional vira ações a mais
		movimento += 1
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
	if ser.tem(Ser.ENJOADO):
		a.padrao = 0   # enjoado: só uma ação padrão ou de movimento por rodada (p.320)
		a.movimento = 0
	if ser.mods_cena.has("acelerado_ativo"):
		# Aceleração (anárquico descontrolado): ação de movimento + padrão (ou completa) no turno = dano
		var gastos: Array = a.get("gastos", [])
		gastos.append(tipo)
		a["gastos"] = gastos
		if "completa" in gastos or ("padrao" in gastos and "movimento" in gastos):
			var ac: Dictionary = ser.mods_cena.acelerado_ativo
			ser.mods_cena.erase("acelerado_ativo")
			var d := aplicar_dano(ser, dados.rolar_expressao(String(ac.dados)), String(ac.tipo_dano))
			_log("%s, acelerado, sofre %d de dano colateral." % [ser.nome, d])
	return true


## Ação Agredir: gasta a ação padrão e ataca.
## Chance (0..1) de um ataque acertar, para a UI (docs/21, C2). Segue `atacar` no que é
## previsível: modificadores do atacante, alcance, flanco, cobertura, alvo em corpo a corpo,
## mira, Foco e Ataque Especial. Não conta a reação que o alvo ainda pode declarar.
## −1 quando o ataque não é possível daqui.
func chance_de_acerto(atacante: Ser, alvo: Ser, arma_base: Dictionary, pe_foco: int = 0, bonus_extra: int = 0) -> float:
	arma_base = arma_em_maos(atacante, arma_base)
	var arma: Dictionary = (atacante as Agente).arma_efetiva(arma_base) if atacante is Agente else arma_base
	var mods := atacante.modificar_ataque(arma, alvo)
	var corpo_a_corpo: bool = arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo"
	var dados_extras := pe_foco + int(mods.dados_extras)
	var defesa := alvo.defesa()
	if grade != null and grade.tem(atacante) and grade.tem(alvo):
		if corpo_a_corpo:
			if not grade.estao_adjacentes(atacante, alvo):
				return -1.0
			if grade.flanqueando(atacante, alvo):
				dados_extras += 1
		if grade.elevado(atacante) and not grade.elevado(alvo):
			dados_extras += 1   # posição elevada (p.89)
		if not corpo_a_corpo:
			var faixa := grade.faixa_de_alcance(atacante, alvo, arma.get("alcance", "curto"))
			var cob := grade.cobertura(atacante, alvo)
			if faixa == "fora" or cob == "total":
				return -1.0
			if faixa == "longe":
				dados_extras -= 1
			if cob == "leve":
				defesa += 5
			var mira: Dictionary = _miras.get(atacante, {})
			var mirando: bool = not mira.is_empty() and mira.alvo == alvo
			if grade.em_corpo_a_corpo(alvo) and not mirando and not (atacante is Agente and (atacante as Agente).tem_habilidade("tiro_certeiro")):
				dados_extras -= 1
	if alvo.tem(Ser.CAIDO):
		defesa += -5 if corpo_a_corpo else 5   # caído (p.310)
	var pericia_id: String = arma.get("pericia", "luta")
	var dados_teste := atacante.dados_da_pericia(pericia_id)
	var bonus_teste := atacante.bonus_pericia(pericia_id)
	if arma.has("teste"):
		dados_teste = int(arma.teste.dados) - atacante.penalidade_dados_atributo(ruleset.atributo_da_pericia(pericia_id))
		bonus_teste = int(arma.teste.bonus)
	var chance := Teste.chance_de_passar(dados_teste, bonus_teste + int(mods.bonus_ataque) + bonus_extra, defesa, dados_extras)
	if grade != null and grade.camuflado(alvo):
		chance *= 0.8   # camuflagem leve: 20% de erro (p.89)
	return chance


func agredir(atacante: Ser, alvo: Ser, arma: Dictionary, pe_foco: int = 0, opcoes: Dictionary = {}) -> ResultadoAtaque:
	if atacante.mods_cena.has("prendendo") or not gastar_acao(atacante, "padrao"):
		return _ataque_invalido(atacante, alvo, arma)
	var res := atacar(atacante, alvo, arma, pe_foco, opcoes)
	var vezes := int(arma.get("vezes", 1))
	if atacante is Ameaca and (atacante as Ameaca).tem_hab("instinto_mortal") and atacante.tem(Ser.MACHUCADO):
		vezes += 1   # Instinto Mortal (carniçal)
	for _i in vezes - 1:   # "Corpo a corpo x2" (p.189): mais ataques na mesma ação
		if encerrado or (alvo.esta_fora_de_combate() and not alvo.tem(Ser.POCA)):
			break
		res.ataques_extras.append(atacar(atacante, alvo, arma))
	if atacante is Ameaca and (atacante as Ameaca).tem_hab("ataque_flexivel") and not encerrado and not alvo.esta_fora_de_combate():
		for outra in (atacante as Ameaca).ataques:   # Kerberos: o quarto ataque com a outra arma
			if outra.id != arma.get("id", ""):
				var r_extra := atacar(atacante, alvo, outra)
				if r_extra.teste != null:
					res.ataques_extras.append(r_extra)
				break
	if atacante.efeito_ritual("ataque_adicional") > 0 and arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo" and not encerrado and not alvo.esta_fora_de_combate():
		res.ataque_adicional = atacar(atacante, alvo, arma)   # Ódio Incontrolável (discente)
	return res


## Ação de movimento: anda até `destino` dentro do deslocamento (precisa de grade).
## Sair de perto de um inimigo com Ataque de Oportunidade libera o ataque (veja oportunidades_pendentes).
func mover(ser: Ser, destino: Vector2i) -> bool:
	if grade == null or ser.tem(Ser.IMOVEL) or ser.tem(Ser.AGARRADO) or ser.esta_fora_de_combate():
		return false
	var origem := grade.posicao(ser)
	var arrastando := _agarrados_por_manobra(ser)
	var limite := ser.deslocamento_quadrados()
	if not arrastando.is_empty():
		limite = maxi(1, limite / 2)   # quem agarra anda metade, arrastando a vítima (p.85)
	if not grade.alcancaveis(ser, limite).has(destino) or grade.ocupante(destino) != null:
		return false
	var purg := _purgatorio_de(ser)
	if not purg.is_empty() and not destino in purg.celulas:
		# Purgatório (p.149): sair dói (6d6 de Sangue) e, falhando em Fortitude, não se move
		var conj: Ser = purg.conjurador
		var dano := aplicar_dano(ser, dados.rolar_expressao(String(purg.efeito.dados)), String(purg.efeito.tipo_dano), 0, conj)
		var t := Teste.rolar(dados, ser.dados_da_pericia("fortitude"), ser.bonus_pericia("fortitude"), conj.dt_ritual(purg.ritual))
		_log("%s tenta sair do Purgatório: %d de dano, Fortitude %s." % [ser.nome, dano, t.descrever()])
		if not t.sucesso:
			gastar_acao(ser, "movimento")
			return false
	if not gastar_acao(ser, "movimento"):
		return false
	var vizinhos_antes: Array[Ser] = []
	for outro in grade.seres():
		if outro.lado != ser.lado and not outro.esta_fora_de_combate() and Grade.adjacentes(origem, grade.posicao(outro)):
			vizinhos_antes.append(outro)
	grade.mover(ser, destino, limite)
	for vitima in arrastando:
		_arrastar(ser, vitima)
	for outro in grade.seres():   # Reflexos Guiados por Corda: quem chega ao lado leva um golpe
		if outro is Ameaca and (outro as Ameaca).tem_hab("reflexos_guiados") and outro.lado != ser.lado and not outro.esta_fora_de_combate():
			if grade.estao_adjacentes(ser, outro) and not outro in vizinhos_antes and not _usou_na_rodada(outro, "reflexos_guiados"):
				_marcar_uso_rodada(outro, "reflexos_guiados")
				atacar(outro, ser, (outro as Ameaca).ataques[0])
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


## Primeiros Socorros (Medicina, DT 20, p.46): um aliado adjacente morrendo perde as condições
## morrendo e inconsciente e fica com 1 PV. Ação padrão. A DT sobe +5 por vez que ele já foi
## estabilizado na cena. Devolve o teste (null se não dá para tentar).
func primeiros_socorros(agente: Agente, alvo: Ser) -> ResultadoTeste:
	if alvo == agente or alvo.tem(Ser.MORTO) or not alvo.tem(Ser.MORRENDO):
		return null
	if grade != null and grade.tem(agente) and grade.tem(alvo) and not grade.estao_adjacentes(agente, alvo):
		return null
	if int(acoes_restantes(agente).get("padrao", 0)) <= 0:
		return null
	var dt := 20 + 5 * alvo.estabilizado_na_cena
	var t := agente.testar(dados, "medicina", dt)
	if t == null:
		return null
	gastar_acao(agente, "padrao")
	if t.sucesso:
		alvo.estabilizar()
		if alvo.pv < 1:
			alvo.curar(1 - alvo.pv)
		alvo.condicoes.erase(Ser.INCONSCIENTE)
		alvo.estabilizado_na_cena += 1
	return t


## Acalmar (Diplomacia treinada, DT 20, p.44; Religião serve no lugar, p.48): um aliado
## adjacente enlouquecendo fica com Sanidade 1. Ação padrão. A DT sobe +5 por vez que ele
## já foi acalmado na cena. `pericia`: "diplomacia" ou "religiao".
func acalmar(agente: Agente, alvo: Ser, pericia: String = "diplomacia") -> ResultadoTeste:
	if not pericia in ["diplomacia", "religiao"] or not agente.treinado_em(pericia):
		return null
	if alvo == agente or not alvo.tem(Ser.ENLOUQUECENDO):
		return null
	if grade != null and grade.tem(agente) and grade.tem(alvo) and not grade.estao_adjacentes(agente, alvo):
		return null
	if int(acoes_restantes(agente).get("padrao", 0)) <= 0:
		return null
	var dt := 20 + 5 * alvo.acalmado_na_cena
	var t := agente.testar(dados, pericia, dt)
	if t == null:
		return null
	gastar_acao(agente, "padrao")
	if t.sucesso:
		if alvo.san < 1:
			alvo.recuperar_sanidade(1 - alvo.san)
		alvo.condicoes.erase(Ser.ENLOUQUECENDO)
		alvo.acalmado_na_cena += 1
	return t


# --- Manobras de combate (p.85-86) ------------------------------------------------

## Agarrar, derrubar, desarmar e empurrar: um ataque corpo a corpo que, em vez de dano, faz
## outra coisa. Teste de manobra (ataque corpo a corpo, Luta) oposto pela Luta do alvo; empate,
## de novo. Gasta a ação padrão. Agarrar quem você já agarra esmaga (dano desarmado).
const MANOBRAS := ["agarrar", "derrubar", "desarmar", "empurrar"]


## "" se a manobra pode ser feita agora, ou o motivo.
func pode_manobrar(atacante: Ser, alvo: Ser, tipo: String) -> String:
	if not tipo in MANOBRAS:
		return "manobra desconhecida"
	if alvo == null or alvo == atacante or alvo.lado == atacante.lado or alvo.esta_fora_de_combate():
		return "alvo inválido"
	if atacante.tem(Ser.AGARRADO) and tipo != "agarrar":
		return "quem está agarrado só se solta ou ataca com arma leve"
	if grade != null and grade.tem(atacante) and grade.tem(alvo) and not grade.estao_adjacentes(atacante, alvo):
		return "a manobra é corpo a corpo: precisa estar ao lado"
	if int(acoes_restantes(atacante).get("padrao", 0)) <= 0:
		return "sem ação padrão"
	match tipo:
		"agarrar":
			if alvo.imune_a_condicao(Ser.AGARRADO):
				return "%s não pode ser agarrado" % alvo.nome
			if alvo.tem(Ser.AGARRADO) and alvo.mods_cena.get("agarrado_por") != atacante:
				return "%s já está agarrado" % alvo.nome
		"derrubar":
			if alvo.imune_a_condicao(Ser.CAIDO):
				return "%s não pode ser derrubado" % alvo.nome
			if alvo.tem(Ser.CAIDO):
				return "%s já está no chão" % alvo.nome
		"desarmar":
			if _arma_de_mao(alvo).is_empty():
				return "%s não segura nenhuma arma" % alvo.nome
	return ""


## Faz a manobra. {ok, erro?, tipo, venceu, diferenca, textos}
func manobra(atacante: Ser, alvo: Ser, tipo: String) -> Dictionary:
	var motivo := pode_manobrar(atacante, alvo, tipo)
	if motivo != "":
		return {"ok": false, "erro": motivo}
	gastar_acao(atacante, "padrao")
	var dif := _teste_de_manobra(atacante, alvo)
	var res := {"ok": true, "tipo": tipo, "venceu": dif > 0, "diferenca": dif, "textos": []}
	if dif <= 0:
		res.textos.append("%s resiste." % alvo.nome)
		return res
	match tipo:
		"agarrar":
			if alvo.tem(Ser.AGARRADO) and alvo.mods_cena.get("agarrado_por") == atacante:
				var desarmado := ruleset.arma("desarmado")
				var golpe := dados.rolar_expressao(String(desarmado.get("dano", "1d3"))) + atacante.atributo("for")
				var real := aplicar_dano(alvo, maxi(1, golpe), "impacto", 0, atacante)
				res.textos.append("%s esmaga %s: %d de dano." % [atacante.nome, alvo.nome, real])
			else:
				alvo.aplicar_condicao(Ser.AGARRADO)
				alvo.mods_cena["agarrado_por"] = atacante
				alvo.mods_cena["agarrado_manobra"] = true
				var lista: Array = atacante.mods_cena.get("agarrando", [])
				lista.append(alvo)
				atacante.mods_cena["agarrando"] = lista
				res.textos.append("%s agarra %s." % [atacante.nome, alvo.nome])
		"derrubar":
			alvo.aplicar_condicao(Ser.CAIDO)
			res.textos.append("%s vai ao chão." % alvo.nome)
			if dif >= 5 and _empurrar(atacante, alvo, 1) > 0:   # com folga, também empurra 1 quadrado
				res.textos.append("O golpe ainda o arrasta 1,5 m.")
		"desarmar":
			var arma := _arma_de_mao(alvo)
			alvo.mods_cena["arma_caida"] = String(arma.get("id", ""))
			res.textos.append("%s derruba %s de %s." % [atacante.nome, String(arma.get("nome", "a arma")).to_lower(), alvo.nome])
		"empurrar":
			var andou := _empurrar(atacante, alvo, 1 + dif / 5)
			res.textos.append("%s empurra %s %s." % [atacante.nome, alvo.nome, ("%s m" % str(andou * 1.5).replace(".", ",")) if andou > 0 else "contra o obstáculo"])
	for t in res.textos:
		_log(t)
	return res


## Teste de manobra (p.85): Luta do atacante, com os modificadores de ataque corpo a corpo
## (flanquear, caído, agarrado…), contra a Luta do alvo. Devolve a diferença (>0: o atacante vence).
func _teste_de_manobra(atacante: Ser, alvo: Ser, dados_bonus: int = 0, bonus: int = 0) -> int:
	var arma := ruleset.arma("desarmado")
	var mods_a := atacante.modificar_ataque(arma, alvo)
	var mods_b := alvo.modificar_ataque(arma, atacante)
	var extra_a := int(mods_a.dados_extras) + dados_bonus
	if grade != null and grade.tem(atacante) and grade.tem(alvo) and grade.flanqueando(atacante, alvo):
		extra_a += 1
	for _i in 10:
		var ra := Teste.rolar(dados, atacante.dados_da_pericia("luta"), atacante.bonus_pericia("luta") + int(mods_a.bonus_ataque) + bonus, 0, extra_a)
		var rb := Teste.rolar(dados, alvo.dados_da_pericia("luta"), alvo.bonus_pericia("luta"), 0, int(mods_b.dados_extras))
		if ra.total != rb.total:
			_log("Manobra: %s %d contra %s %d." % [atacante.nome, ra.total, alvo.nome, rb.total])
			return ra.total - rb.total
	return 0


## Empurra o alvo para longe do atacante, quadrado a quadrado, até `quadrados` ou um obstáculo.
## Devolve quantos quadrados andou.
func _empurrar(atacante: Ser, alvo: Ser, quadrados: int) -> int:
	if grade == null or not grade.tem(atacante) or not grade.tem(alvo):
		return 0
	var dir := grade.posicao(alvo) - grade.posicao(atacante)
	dir = Vector2i(signi(dir.x), signi(dir.y))
	if dir == Vector2i.ZERO:
		return 0
	var andou := 0
	for _i in quadrados:
		var prox := grade.posicao(alvo) + dir
		if not grade.dentro(prox) or grade.bloqueada(prox) or grade.ocupante(prox) != null:
			break
		grade.colocar(alvo, prox)
		andou += 1
	if andou > 0:
		_soltar_agarrados_por_manobra(alvo, "ao ser empurrado")
		if alvo.tem(Ser.AGARRADO) and alvo.mods_cena.get("agarrado_manobra", false):
			_soltar(alvo)
	return andou


## A arma que o ser segura e que pode ser derrubada ({} se nenhuma ou já caída).
## Agentes: a arma equipada (não o desarmado). Ameaças: um ataque que seja arma da tabela.
func _arma_de_mao(ser: Ser) -> Dictionary:
	if ser.mods_cena.has("arma_caida"):
		return {}
	if ser is Agente:
		var a := (ser as Agente).arma()
		return a if String(a.get("id", "desarmado")) != "desarmado" else {}
	if ser is Ameaca:
		for at in (ser as Ameaca).ataques:
			var id := String(at.get("id", ""))
			if id != "" and id != "desarmado" and ruleset.tem_arma(id):
				return at
	return {}


## Fintar (p.86): ação padrão. Enganação contra Reflexos de um ser em alcance curto. Passando,
## ele fica desprevenido contra o seu próximo ataque, até o fim do seu próximo turno.
func fintar(atacante: Ser, alvo: Ser) -> Dictionary:
	if alvo == null or alvo == atacante or alvo.lado == atacante.lado or alvo.esta_fora_de_combate():
		return {"ok": false, "erro": "alvo inválido"}
	if not _perto(atacante, alvo, "curto"):
		return {"ok": false, "erro": "longe demais para fintar"}
	if int(acoes_restantes(atacante).get("padrao", 0)) <= 0:
		return {"ok": false, "erro": "sem ação padrão"}
	gastar_acao(atacante, "padrao")
	var venceu := _teste_oposto(atacante, "enganacao", 0, alvo, "reflexos", 0)
	var texto := "%s finta %s: %s." % [atacante.nome, alvo.nome, "ele baixa a guarda" if venceu else "ele não cai"]
	if venceu:
		alvo.mods_cena["fintado_por"] = {"atacante": atacante, "turnos": 1}
	_log(texto)
	return {"ok": true, "tipo": "fintar", "venceu": venceu, "textos": [texto]}


func _fintado_por(alvo: Ser, atacante: Ser) -> bool:
	var f: Dictionary = alvo.mods_cena.get("fintado_por", {})
	return not f.is_empty() and f.atacante == atacante


## Fim do turno de quem fintou: a finta vale até o fim do próximo turno dele.
func _envelhecer_fintas(ser: Ser) -> void:
	for s in participantes:
		var f: Dictionary = s.mods_cena.get("fintado_por", {})
		if not f.is_empty() and f.atacante == ser:
			f.turnos = int(f.turnos) - 1
			if int(f.turnos) < 0:
				s.mods_cena.erase("fintado_por")


## Rendidos (docs/40): pessoas (não criaturas) postas para dormir com dano não letal.
## Depois do combate, a Ordem pode interrogá-las.
func rendidos() -> Array:
	return participantes.filter(func(s): return s is Ameaca and not (s as Ameaca).criatura and s.mods_cena.get("rendido", false) and not s.tem(Ser.MORTO))


## A arma de verdade no ataque: quem teve a arma derrubada luta desarmado até pegá-la.
func arma_em_maos(atacante: Ser, arma: Dictionary) -> Dictionary:
	var caida := String(atacante.mods_cena.get("arma_caida", ""))
	if caida != "" and String(arma.get("id", "")) == caida:
		return ruleset.arma("desarmado")
	return arma


## Levantar-se do chão: ação de movimento (p.84).
func levantar(ser: Ser) -> bool:
	if not ser.tem(Ser.CAIDO) or not gastar_acao(ser, "movimento"):
		return false
	ser.condicoes.erase(Ser.CAIDO)
	_log("%s se levanta." % ser.nome)
	return true


## Pegar a arma derrubada (ela cai no espaço de quem a segurava): ação de movimento (p.84).
func pegar_arma(ser: Ser) -> bool:
	if not ser.mods_cena.has("arma_caida") or not gastar_acao(ser, "movimento"):
		return false
	ser.mods_cena.erase("arma_caida")
	_log("%s pega a arma de volta." % ser.nome)
	return true


## Quem este ser agarra por manobra.
func _agarrados_por_manobra(ser: Ser) -> Array:
	return ser.mods_cena.get("agarrando", []).filter(func(s): return s.mods_cena.get("agarrado_manobra", false) and s.tem(Ser.AGARRADO))


## Leva a vítima agarrada para a casa livre ao lado de quem agarra, a mais perto de onde ela
## estava. Sem casa livre, ela escapa.
func _arrastar(ser: Ser, vitima: Ser) -> void:
	var antes := grade.posicao(vitima)
	var centro := grade.posicao(ser)
	var melhor := Vector2i(-999, -999)
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var c := centro + Vector2i(dx, dy)
			if c == centro or not grade.dentro(c) or grade.bloqueada(c) or (grade.ocupante(c) != null and grade.ocupante(c) != vitima):
				continue
			if melhor == Vector2i(-999, -999) or Vector2(c - antes).length() < Vector2(melhor - antes).length():
				melhor = c
	if melhor == Vector2i(-999, -999):
		_soltar(vitima)
		_log("%s escapa no tranco." % vitima.nome)
		return
	grade.colocar(vitima, melhor)


## Quem agarra por manobra solta a vítima (ex.: quando ela é empurrada para longe).
func _soltar_agarrados_por_manobra(ser: Ser, motivo: String) -> void:
	for s in ser.mods_cena.get("agarrando", []).duplicate():
		if s.mods_cena.get("agarrado_manobra", false):
			_soltar(s)
			_log("%s solta %s %s." % [ser.nome, s.nome, motivo])


## Sem grade, tudo está "perto". Com grade, verifica a categoria de alcance.
func _perto(a: Ser, b: Ser, categoria: String) -> bool:
	return grade == null or not grade.tem(a) or not grade.tem(b) or grade.em_alcance(a, b, categoria)


# --- Rituais (cap. 5, p.127-131) ---------------------------------------------------

## Efeito do ritual na forma escolhida: a forma básica com as mudanças da forma (p.130).
## Inclui "alcance" (a forma pode mudar).
func efeito_do_ritual(ritual_id: String, forma: String = "") -> Dictionary:
	var r := ruleset.ritual(ritual_id)
	if r.get("efeitos", []).is_empty():
		return {}
	var efeito: Dictionary = r.efeitos[0].duplicate(true)
	efeito["alcance"] = String(r.get("alcance", "pessoal"))
	if forma != "":
		var f: Dictionary = r.get("formas", {}).get(forma, {})
		for k in f:
			if not k in ["custo", "circulo", "afinidade", "descricao"]:
				efeito[k] = f[k]
	return efeito


## Erro que impede conjurar ("" = pode). Não gasta nada.
## `opcoes`: {"celula": Vector2i} (ponto de uma área) ou {"alvos": [Ser, ...]} (vários alvos).
func pode_conjurar(conjurador: Agente, ritual_id: String, alvo: Ser, forma: String = "", opcoes: Dictionary = {}) -> String:
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
		if f.get("afinidade", false) and conjurador.afinidade != r.elemento:
			return "a forma %s exige afinidade com %s" % [forma, r.elemento]
	if conjurador.efeito_ritual("ataque_corpo_a_corpo") > 0 and conjurador.rituais_ativos.has("odio_incontrolavel"):
		return "em frenesi, não dá para se concentrar"
	if r.elemento != "medo" and conjurador.afinidade != r.elemento and not conjurador.equipamento.any(func(i): return ruleset.equipamento(i).get("componentes", "") == r.elemento):
		return "faltam componentes ritualísticos de %s" % r.elemento
	var custo := conjurador.custo_ritual(ritual_id, forma)
	if custo > conjurador.limite_pe_rituais():
		return "custo (%d PE) acima do limite de PE" % custo
	if custo > conjurador.pe + conjurador.pe_temporario:
		return "PE insuficientes"
	var e := efeito_do_ritual(ritual_id, forma)
	var alcance := String(e.alcance)
	if e.has("area"):
		if e.area.forma != "explosao":
			var celula = _celula_da_area(alvo, opcoes)
			if celula == null and opcoes.get("alvos", []).is_empty():
				return "escolha o ponto da área"
			if celula != null and grade != null and grade.tem(conjurador):
				var cat := _categoria(alcance)
				if Grade.ALCANCES.has(cat) and Grade.distancia(grade.posicao(conjurador), celula) > int(Grade.ALCANCES[cat]):
					return "ponto fora de alcance"
	else:
		var lista := _alvos_escolhidos(alvo, e, opcoes)
		if lista.is_empty():
			return "escolha o alvo"
		if e.get("alvos", 1) is float or e.get("alvos", 1) is int:
			if lista.size() > int(e.get("alvos", 1)):
				return "no máximo %d alvo(s)" % int(e.get("alvos", 1))
		for x in lista:
			var erro := _erro_de_alcance(conjurador, x, alcance)
			if erro != "":
				return erro
	if acoes.has(conjurador):
		var restantes := acoes_restantes(conjurador)
		if String(r.get("execucao", "")).begins_with("completa"):
			if restantes.padrao <= 0 or restantes.movimento <= 0:
				return "precisa de uma ação completa"
		elif restantes.padrao <= 0:
			return "sem ação padrão"
	return ""


func _categoria(alcance: String) -> String:
	for cat in ["pessoal", "toque", "curto", "medio", "longo", "extremo"]:
		if alcance.begins_with(cat.replace("medio", "médio")):
			return cat
	return ""


func _erro_de_alcance(conjurador: Ser, alvo: Ser, alcance: String) -> String:
	if alvo == null:
		return "escolha o alvo"
	var cat := _categoria(alcance)
	if cat == "pessoal" and alvo != conjurador:
		return "este ritual só afeta o conjurador"
	if cat == "toque" and alvo != conjurador and grade != null and grade.tem(conjurador) and grade.tem(alvo) and not grade.estao_adjacentes(conjurador, alvo):
		return "precisa tocar o alvo"
	if cat in ["curto", "medio", "longo"] and not _perto(conjurador, alvo, cat):
		return "alvo fora de alcance"
	return ""


## Ponto central de uma área: a célula escolhida ou a do alvo clicado.
func _celula_da_area(alvo: Ser, opcoes: Dictionary):
	if opcoes.has("celula"):
		return opcoes.celula
	if alvo != null and grade != null and grade.tem(alvo):
		return grade.posicao(alvo)
	return null


func _alvos_escolhidos(alvo: Ser, e: Dictionary, opcoes: Dictionary) -> Array[Ser]:
	var lista: Array[Ser] = []
	var fonte: Array = opcoes.get("alvos", []) if e.has("alvos") and not opcoes.get("alvos", []).is_empty() else [alvo]
	for x in fonte:
		if x != null and not x in lista:
			lista.append(x)
	return lista


## Seres atingidos: os da área (sem o conjurador numa explosão; só inimigos se a forma pedir)
## ou os alvos escolhidos.
func _alvos_do_efeito(conjurador: Ser, e: Dictionary, alvo: Ser, opcoes: Dictionary, celulas: Array) -> Array[Ser]:
	var lista: Array[Ser] = []
	if not e.has("area"):
		return _alvos_escolhidos(alvo, e, opcoes)
	var candidatos: Array = []
	if grade != null and grade.tem(conjurador):
		candidatos = grade.seres_em(celulas)
	else:
		candidatos = opcoes.get("alvos", [])
	for x in candidatos:
		if x == null or (x.esta_fora_de_combate() and not x.tem(Ser.POCA)) or x in lista:
			continue
		if e.area.forma == "explosao" and x == conjurador:
			continue
		if e.get("so_inimigos", false) and x.lado == conjurador.lado:
			continue
		lista.append(x)
	return lista


func _celulas_do_efeito(conjurador: Ser, e: Dictionary, alvo: Ser, opcoes: Dictionary) -> Array[Vector2i]:
	var vazio: Array[Vector2i] = []
	if not e.has("area") or grade == null or not grade.tem(conjurador):
		return vazio
	var origem := grade.posicao(conjurador)
	var ponto = _celula_da_area(alvo, opcoes)
	var metros := float(e.area.get("raio", e.area.get("comprimento", 1.5)))
	return grade.celulas_da_area(String(e.area.forma), origem, ponto if ponto != null else origem, metros)


## Conjura um ritual (p.129-131): ação padrão (ou completa), PE pelo círculo e pela forma,
## concentração se estiver de proteção, Custo do Paranormal (Ocultismo DT 20 + custo; falha custa
## SAN), efeito e resistência (DT de habilidade com Presença; −2/+2 dados conforme o elemento da
## criatura). Áreas atingem todos na área com uma só rolagem de dano; vários alvos rolam cada um.
func conjurar(conjurador: Agente, ritual_id: String, alvo: Ser, forma: String = "", opcoes: Dictionary = {}) -> Dictionary:
	var erro := pode_conjurar(conjurador, ritual_id, alvo, forma, opcoes)
	if erro != "":
		return {"ok": false, "erro": erro}
	var r := ruleset.ritual(ritual_id)
	var cfg: Dictionary = ruleset.dados.rituais
	var custo := conjurador.custo_ritual(ritual_id, forma)
	if acoes.has(conjurador):
		gastar_acao(conjurador, "completa" if String(r.get("execucao", "")).begins_with("completa") else "padrao")
	conjurador.gastar_pe(custo, true)
	var res := {"ok": true, "ritual": r, "forma": forma, "custo": custo, "alvo": alvo, "conjurador": conjurador, "textos": [], "danos": {}, "dano_total": 0}
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
	var efeito := efeito_do_ritual(ritual_id, forma)
	var celulas := _celulas_do_efeito(conjurador, efeito, alvo, opcoes)
	var alvos := _alvos_do_efeito(conjurador, efeito, alvo, opcoes, celulas)
	res.celulas = celulas
	res.alvos = alvos
	if efeito.has("zona"):
		res.zona = _criar_zona(conjurador, ritual_id, efeito, celulas)
	if efeito.tipo == "dano" and efeito.has("area") and not efeito.get("ataque_arma", false):
		res.dano_area = _rolar_dano_ritual(conjurador, efeito)   # uma rolagem para toda a área
	for x in alvos:
		_aplicar_efeito_ritual(conjurador, ritual_id, r, efeito, x, res)
	if efeito.get("pv_temporario_do_dano", false) and int(res.dano_total) > 0:
		conjurador.pv_temporario = maxi(conjurador.pv_temporario, int(res.dano_total))   # Consumir Manancial (verdadeiro)
		res.textos.append("%s recebe %d PV temporários." % [conjurador.nome, int(res.dano_total)])
	var em := alvo.nome if alvos.size() == 1 and alvo != null and alvos[0] == alvo else ("%d alvo(s)" % alvos.size() if not efeito.has("area") else "uma área (%d atingido(s))" % alvos.size())
	_log("[color=#b98ae6]%s conjura %s%s em %s (%d PE).[/color] %s" % [conjurador.nome, r.nome, "" if forma == "" else " " + forma, em, custo, " ".join(PackedStringArray(res.textos))])
	ritual_conjurado.emit(res)
	_verificar_fim()
	return res


func _rolar_dano_ritual(conjurador: Ser, e: Dictionary) -> int:
	return dados.rolar_expressao(String(e.dados)) * int(e.get("multiplicador", 1)) + conjurador.bonus_ritual_potente()


## Teste de resistência do alvo contra o ritual. Criatura do elemento que o ritual oprime:
## −2 dados; do mesmo elemento: +2 dados (p.128).
func _resistir_ritual(conjurador: Ser, ritual_id: String, r: Dictionary, alvo: Ser, pericia: String) -> ResultadoTeste:
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


func _aplicar_efeito_ritual(conjurador: Ser, ritual_id: String, r: Dictionary, e: Dictionary, alvo: Ser, res: Dictionary) -> void:
	if e.get("ataque_arma", false):
		_ritual_com_ataque(conjurador as Agente, e, alvo, res)
		return
	var passou := false
	if String(e.get("resistencia", "")) != "" and alvo != conjurador and not e.tipo in ["purgatorio", "tentaculos"]:
		var tr := _resistir_ritual(conjurador, ritual_id, r, alvo, e.resistencia)
		res.teste_resistencia = tr
		passou = tr.sucesso
		res.textos.append("%s resiste (%s): %s." % [alvo.nome, ruleset.pericia(e.resistencia).nome, "passou" if passou else "falhou"])
	match e.tipo:
		"dano":
			if passou and e.get("ao_passar", "") == "anula":
				return
			var dano: int = int(res.dano_area) if res.has("dano_area") else _rolar_dano_ritual(conjurador, e)
			if passou and e.get("ao_passar", "") == "metade":
				dano = 0 if _tem_evasao(alvo, String(e.get("resistencia", ""))) else dano / 2
			if res.has("dano_area") and alvo is Ameaca and (alvo as Ameaca).tem_hab("enxame"):
				dano = dano * 3 / 2   # enxames sofrem 50% a mais de efeitos de área
			var real := aplicar_dano(alvo, dano, e.get("tipo_dano", r.elemento), 0, conjurador)
			res.dano = real
			res.danos[alvo] = real
			res.dano_total = int(res.dano_total) + real
			res.textos.append("%s sofre %d de dano." % [alvo.nome, real])
			if e.has("drena") and real > 0:
				var cura := int(real * float(e.drena))
				conjurador.curar(cura)
				res.textos.append("%s recupera %d PV." % [conjurador.nome, cura])
			if not passou and String(e.get("condicao", "")) != "":
				alvo.aplicar_condicao(e.condicao, int(e.get("rodadas", 0)))
				res.textos.append("%s fica %s." % [alvo.nome, e.condicao])
			if not passou and e.has("condicao_na_falha"):
				alvo.aplicar_condicao(e.condicao_na_falha, int(e.get("rodadas", 0)))
			if not passou and e.has("hemorragia"):
				alvo.hemorragia = {"dados": e.hemorragia, "dt": conjurador.dt_ritual(ritual_id), "sucessos": 0}
				res.textos.append("%s começa a sangrar." % alvo.nome)
			if e.get("desintegra", false) and alvo.pv == 0 and not alvo.tem(Ser.MORTO):
				var tf := Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), conjurador.dt_ritual(ritual_id))
				if not tf.sucesso:
					alvo._morrer()   # Paradoxo (verdadeiro): reduzido a cinzas
					res.textos.append("%s vira cinzas." % alvo.nome)
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
				if not res.get("_sustentado_lote", false):
					_encerrar_sustentados_de(conjurador)   # um sustentado por vez (os alvos do mesmo ritual contam juntos)
					res._sustentado_lote = true
				_sustentados.append({"conjurador": conjurador, "alvo": alvo, "ritual": ritual_id})
			res.textos.append("%s: o efeito dura %s." % [alvo.nome, "enquanto sustentado" if e.get("sustentado", false) else "até o fim da cena"])
		"purgatorio":
			res.textos.append("%s está na poça de sangue." % alvo.nome)
		"tentaculos":
			_tentaculos(conjurador, e, alvo, res)


## Decadência/Hemofagia discente: o ritual vai na arma; um ataque corpo a corpo soma os danos.
func _ritual_com_ataque(conjurador: Agente, e: Dictionary, alvo: Ser, res: Dictionary) -> void:
	var arma := conjurador.arma()
	if arma.get("ataque", "corpo_a_corpo") != "corpo_a_corpo":
		arma = ruleset.arma("desarmado")
	var ra := atacar(conjurador, alvo, arma, 0, {"dados_dano_ritual": String(e.dados)})
	res.ataque = ra
	if ra.teste == null:
		res.textos.append("O ataque não foi possível.")
		return
	res.dano = ra.dano
	res.danos[alvo] = ra.dano
	res.dano_total = int(res.dano_total) + ra.dano
	res.textos.append("%s: %s." % [alvo.nome, "acerta, %d de dano" % ra.dano if ra.acertou else "erra"])
	if ra.acertou and e.has("drena") and ra.dano > 0:
		var cura := int(ra.dano * float(e.drena))
		conjurador.curar(cura)
		res.textos.append("%s recupera %d PV." % [conjurador.nome, cura])


## Tentáculos de Lodo (p.151): manobra agarrar com Ocultismo contra Atletismo ou Acrobacia
## (o melhor do alvo); quem já está agarrado é esmagado.
func _tentaculos(conjurador: Ser, e: Dictionary, alvo: Ser, res: Dictionary) -> void:
	if alvo.tem(Ser.AGARRADO):
		var real := aplicar_dano(alvo, _rolar_dano_ritual(conjurador, e), String(e.get("tipo_dano", "morte")), 0, conjurador)
		res.danos[alvo] = real
		res.dano_total = int(res.dano_total) + real
		res.textos.append("Os tentáculos esmagam %s: %d de dano." % [alvo.nome, real])
		return
	var pericia := "atletismo"
	if alvo.dados_da_pericia("acrobacia") * 100 + alvo.bonus_pericia("acrobacia") > alvo.dados_da_pericia("atletismo") * 100 + alvo.bonus_pericia("atletismo"):
		pericia = "acrobacia"
	if _teste_oposto(conjurador, "ocultismo", 0, alvo, pericia, 0):
		alvo.aplicar_condicao(Ser.AGARRADO)
		if res.has("zona"):
			res.zona.agarrados.append(alvo)
		res.textos.append("%s é agarrado pelos tentáculos." % alvo.nome)
	else:
		res.textos.append("%s escapa dos tentáculos." % alvo.nome)


## Ação padrão para se soltar dos tentáculos: Atletismo ou Acrobacia contra a DT do ritual.
func escapar(ser: Ser) -> bool:
	if not ser.tem(Ser.AGARRADO):
		return false
	if ser.mods_cena.has("prisao_pv"):
		if acoes.has(ser) and not gastar_acao(ser, "padrao"):
			return false
		var arma_s: Dictionary = (ser as Agente).arma() if ser is Agente else ruleset.arma("desarmado")
		var golpe := dados.rolar_expressao(String(arma_s.get("dano", "1d3"))) + (ser.atributo("for") if arma_s.get("soma_forca", false) else 0)
		ser.mods_cena["prisao_pv"] = int(ser.mods_cena.prisao_pv) - golpe   # os tentáculos são acertados automaticamente
		_log("%s golpeia os tentáculos (%d)." % [ser.nome, golpe])
		if int(ser.mods_cena.prisao_pv) <= 0:
			ser.mods_cena.erase("prisao_pv")
			_soltar(ser)
			return true
		return false
	if ser.mods_cena.get("agarrado_manobra", false):
		if acoes.has(ser) and not gastar_acao(ser, "padrao"):
			return false
		var quem: Ser = ser.mods_cena.get("agarrado_por")
		if quem == null or _teste_de_manobra(ser, quem) > 0:
			_log("%s se solta." % ser.nome)
			_soltar(ser)
			return true
		_log("%s não consegue se soltar." % ser.nome)
		return false
	if ser.mods_cena.has("agarrado_por"):
		if acoes.has(ser) and not gastar_acao(ser, "padrao"):
			return false
		var t_alvo := _teste_melhor(ser, ["atletismo", "acrobacia"])
		var teste_agarrar: Dictionary = ser.mods_cena.get("agarrado_teste", {"dados": 1, "bonus": 0})
		var t_amea := Teste.rolar(dados, int(teste_agarrar.dados), int(teste_agarrar.bonus), 0)
		_log("%s tenta se soltar: %d contra %d." % [ser.nome, t_alvo.total, t_amea.total])
		if t_alvo.total > t_amea.total:
			_soltar(ser)
			return true
		return false
	var zona: Dictionary = {}
	for z in _zonas:
		if ser in z.agarrados:
			zona = z
	if zona.is_empty() or (acoes.has(ser) and not gastar_acao(ser, "padrao")):
		return false
	var pericia := "acrobacia" if ser.dados_da_pericia("acrobacia") > ser.dados_da_pericia("atletismo") else "atletismo"
	var t := Teste.rolar(dados, ser.dados_da_pericia(pericia), ser.bonus_pericia(pericia), (zona.conjurador as Ser).dt_ritual(zona.ritual))
	_log("%s tenta se soltar (%s): %s." % [ser.nome, ruleset.pericia(pericia).nome, t.descrever()])
	if t.sucesso:
		ser.condicoes.erase(Ser.AGARRADO)
		zona.agarrados.erase(ser)
	return t.sucesso


# --- Zonas de rituais ------------------------------------------------------

func zonas() -> Array[Dictionary]:
	return _zonas


func _criar_zona(conjurador: Ser, ritual_id: String, e: Dictionary, celulas: Array) -> Dictionary:
	var cfg: Dictionary = e.zona
	var z := {"conjurador": conjurador, "ritual": ritual_id, "efeito": e, "celulas": celulas,
		"gatilho": String(cfg.get("gatilho", "nenhum")), "rodadas": int(cfg.get("rodadas", 0)), "agarrados": []}
	if cfg.get("sustentado", false):
		_encerrar_sustentados_de(conjurador)
		_sustentados.append({"conjurador": conjurador, "alvo": null, "ritual": ritual_id, "zona": z})
	_zonas.append(z)
	if cfg.get("terreno_dificil", false) and grade != null:
		grade.marcar_dificil(celulas, true)
	return z


func _remover_zona(z: Dictionary) -> void:
	_zonas.erase(z)
	if z.efeito.zona.get("terreno_dificil", false) and grade != null:
		grade.marcar_dificil(z.celulas, false)
	for s in z.agarrados:
		s.condicoes.erase(Ser.AGARRADO)
	_log("%s se desfaz." % ruleset.ritual(z.ritual).nome)


## No início do turno: zonas do conjurador agem em quem está nelas (e contam as rodadas);
## zonas "turno_ser" atingem quem começa o turno dentro delas.
func _processar_zonas(ser: Ser) -> void:
	for z in _zonas.duplicate():
		if not z in _zonas:
			continue
		if z.conjurador == ser:
			if z.gatilho == "turno_conjurador" and grade != null:
				_disparar_zona(z, grade.seres_em(z.celulas))
			if z.rodadas > 0:
				z.rodadas -= 1
				if z.rodadas == 0:
					_remover_zona(z)
					continue
		if z.gatilho == "turno_ser" and grade != null and grade.tem(ser) and grade.posicao(ser) in z.celulas:
			_disparar_zona(z, [ser])


func _disparar_zona(z: Dictionary, atingidos: Array) -> void:
	var e: Dictionary = z.efeito
	var r := ruleset.ritual(z.ritual)
	var res := {"textos": [], "danos": {}, "dano_total": 0, "zona": z}
	if e.tipo == "dano":
		res.dano_area = _rolar_dano_ritual(z.conjurador, e)
	for x in atingidos:
		if not x.esta_fora_de_combate():
			_aplicar_efeito_ritual(z.conjurador, z.ritual, r, e, x, res)
	if not res.textos.is_empty():
		_log("[color=#b98ae6]%s:[/color] %s" % [r.nome, " ".join(PackedStringArray(res.textos))])
	_verificar_fim()


## Purgatório em que o ser está como inimigo do conjurador ({} se não estiver).
func _purgatorio_de(ser: Ser) -> Dictionary:
	if grade == null or not grade.tem(ser):
		return {}
	for z in _zonas:
		if z.efeito.tipo == "purgatorio" and ser.lado != z.conjurador.lado and grade.posicao(ser) in z.celulas:
			return z
	return {}


# --- Ameaças: habilidades das fichas (cap. 7) ---------------------------------

## Melhor teste entre perícias (Atletismo ou Acrobacia para escapar de agarrões…).
func _teste_melhor(ser: Ser, pericias: Array, dt: int = 0) -> ResultadoTeste:
	var melhor: String = pericias[0]
	for p_id in pericias:
		if ser.dados_da_pericia(p_id) * 100 + ser.bonus_pericia(p_id) > ser.dados_da_pericia(melhor) * 100 + ser.bonus_pericia(melhor):
			melhor = p_id
	return Teste.rolar(dados, ser.dados_da_pericia(melhor), ser.bonus_pericia(melhor), dt)


## Efeitos de quando um ataque de ameaça acerta ("ao_acertar" da arma).
func _ao_acertar(atacante: Ser, alvo: Ser, arma: Dictionary, res: ResultadoAtaque) -> void:
	var aa: Dictionary = arma.get("ao_acertar", {})
	if aa.is_empty() or alvo.tem(Ser.MORTO):
		return
	if aa.has("condicao") and res.dano > 0:
		alvo.aplicar_condicao(String(aa.condicao.condicao), int(aa.condicao.get("rodadas", 0)))
	if aa.has("contra_perturbado") and alvo.tem(Ser.PERTURBADO):   # Destruir Mente (bicho-papão)
		alvo.sofrer_dano_mental(dados.rolar_expressao(String(aa.contra_perturbado.dano)))
	if aa.has("explodir") and res.dano > 0 and int(_usos_rodada.get(atacante, {}).get("explodir", 0)) < int(aa.explodir.get("por_turno", 1)):
		var usos_r: Dictionary = _usos_rodada.get(atacante, {})
		usos_r["explodir"] = int(usos_r.get("explodir", 0)) + 1   # Explodir em Sangue: duas vezes por turno
		_usos_rodada[atacante] = usos_r
		res.dano += aplicar_dano(alvo, dados.rolar_expressao(String(aa.explodir.dano)), String(aa.explodir.tipo_dano), 0, atacante)
	if aa.has("vulnerabilidade") and res.dano > 0:   # o chifre do Diabo fica preso: vulnerável a Sangue
		var vul_c: Array = alvo.mods_cena.get("vulnerabilidades", [])
		if not aa.vulnerabilidade in vul_c:
			vul_c.append(aa.vulnerabilidade)
		alvo.mods_cena["vulnerabilidades"] = vul_c
	if aa.has("comandar") and res.dano > 0 and alvo.atributo("int") < int(aa.comandar.get("int_imune", 99)):
		if not Teste.rolar(dados, alvo.dados_da_pericia("vontade"), alvo.bonus_pericia("vontade"), int(aa.comandar.dt)).sucesso:
			_hipnotizar(atacante as Ameaca, alvo, int(aa.comandar.dt), true)   # Comandar: ataca um aliado no próximo turno
	if aa.has("envelhecer") and res.dano > 0:
		_envelhecer(alvo, dados.rolar_expressao(String(aa.envelhecer.dados)))
	# Derrubar de graça ao acertar (Cão de Guarda, p.288): manobra livre com bônus próprio
	if aa.has("derrubar_ao_acertar") and not alvo.tem(Ser.CAIDO) and not alvo.imune_a_condicao(Ser.CAIDO) and not alvo.esta_fora_de_combate():
		var dd: Dictionary = aa.derrubar_ao_acertar
		if _teste_de_manobra(atacante, alvo, int(dd.get("dados", 0)), int(dd.get("bonus", 0))) > 0:
			alvo.aplicar_condicao(Ser.CAIDO)
			_log("%s derruba %s." % [atacante.nome, alvo.nome])
	if aa.has("agarrar") and not alvo.tem(Ser.AGARRADO) and not alvo.imune_a_condicao(Ser.AGARRADO):
		var lista: Array = atacante.mods_cena.get("agarrando", [])
		if lista.size() < int(aa.agarrar.get("maximo", 1)):
			var t: Dictionary = aa.agarrar.teste
			var r_amea := Teste.rolar(dados, int(t.dados), int(t.bonus), 0)
			if r_amea.total > _teste_melhor(alvo, ["atletismo", "acrobacia"]).total:
				alvo.aplicar_condicao(Ser.AGARRADO)
				alvo.mods_cena["agarrado_por"] = atacante
				alvo.mods_cena["agarrado_teste"] = t
				lista.append(alvo)
				atacante.mods_cena["agarrando"] = lista
				if aa.agarrar.has("condicao"):
					alvo.aplicar_condicao(String(aa.agarrar.condicao))   # Faixas Detentoras: fascinado
				_log("%s agarra %s." % [atacante.nome, alvo.nome])
	if aa.has("cravar") and not alvo.tem(Ser.AGARRADO) and not alvo.imune_a_condicao(Ser.AGARRADO):
		alvo.aplicar_condicao(Ser.AGARRADO)   # Cravar Chifres (minotauro)
		alvo.mods_cena["agarrado_por"] = atacante
		alvo.mods_cena["agarrado_teste"] = aa.cravar.teste
		alvo.mods_cena["cravado"] = {"por": atacante, "dano": aa.cravar.dano, "tipo_dano": aa.cravar.tipo_dano}
		var lista_c: Array = atacante.mods_cena.get("agarrando", [])
		lista_c.append(alvo)
		atacante.mods_cena["agarrando"] = lista_c
		_log("[color=#e0574a]%s crava os chifres em %s![/color]" % [atacante.nome, alvo.nome])
	if aa.has("devorar") and alvo.pv == 0 and not alvo.tem(Ser.MORTO) and not (atacante as Ameaca).usos.has("devorar"):
		(atacante as Ameaca).usos["devorar"] = 1   # Devorar (kerberos): uma vez por cena
		if not Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), int(aa.devorar.dt)).sucesso:
			var pv_total := alvo.pv_maximo
			alvo._morrer()
			atacante.curar(pv_total / 2)
			_log("[color=#e0574a]%s devora %s.[/color]" % [atacante.nome, alvo.nome])
	if aa.has("veneno") and not alvo.mods_cena.has("veneno_na_cena"):
		alvo.mods_cena["veneno_na_cena"] = true   # só a primeira vez na cena
		alvo.mods_cena["veneno"] = aa.veneno
		_log("%s fica envenenado." % alvo.nome)
	if aa.has("succao") and not atacante.mods_cena.has("prendendo"):
		var tf := Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), int(aa.succao.dt))
		if not tf.sucesso:
			alvo.aplicar_condicao(Ser.INCONSCIENTE)
			atacante.mods_cena["prendendo"] = alvo
			atacante.mods_cena["dano_prendendo"] = 0
			atacante.mods_cena["solta_com_dano"] = int(aa.succao.get("solta_com_dano", 10))
			_log("[color=#e0574a]%s prende os dentes no rosto de %s e lhe tira o ar![/color]" % [atacante.nome, alvo.nome])
	if aa.has("implantar_confusao") and res.dano > 0 and not _usou_na_rodada(atacante, "implantar_confusao"):
		_marcar_uso_rodada(atacante, "implantar_confusao")
		var ic: Dictionary = aa.implantar_confusao
		if Teste.rolar(dados, int(ic.teste.dados), int(ic.teste.bonus), 0).total > _teste_melhor(alvo, ["atletismo", "acrobacia"]).total:
			var d := dados.rolar_expressao(String(ic.dano_mental))
			if Teste.rolar(dados, alvo.dados_da_pericia("vontade"), alvo.bonus_pericia("vontade"), int(ic.dt)).sucesso:
				d /= 2
			alvo.sofrer_dano_mental(d)
			var vul: Array = alvo.mods_cena.get("vulnerabilidades", [])
			if not ic.vulnerabilidade in vul:
				vul.append(ic.vulnerabilidade)
			alvo.mods_cena["vulnerabilidades"] = vul
			_log("%s revive um trauma: %d de dano mental e fica vulnerável a %s." % [alvo.nome, d, ic.vulnerabilidade])
	if aa.has("aceleracao") and res.dano > 0:
		alvo.mods_cena["acelerado"] = aa.aceleracao
	if aa.has("desespero") and res.dano > 0:   # Desespero: o mesmo dano, agora na mente
		var dm := res.dano
		if Teste.rolar(dados, alvo.dados_da_pericia("vontade"), alvo.bonus_pericia("vontade"), int(aa.desespero.dt)).sucesso:
			dm /= 2
		alvo.sofrer_dano_mental(dm)
	if aa.has("efeito_extra"):   # Estraçalhar (titã)
		var ex: Dictionary = aa.efeito_extra
		var passou := ex.has("resistencia") and Teste.rolar(dados, alvo.dados_da_pericia(ex.resistencia), alvo.bonus_pericia(ex.resistencia), int(ex.dt)).sucesso
		if ex.has("dano"):
			var d := dados.rolar_expressao(String(ex.dano))
			res.dano += aplicar_dano(alvo, d / 2 if passou else d, String(ex.tipo_dano), 0, atacante)
		if not passou:
			for cond in ([ex.condicao] if ex.has("condicao") else []) + ex.get("condicoes", []):
				alvo.aplicar_condicao(cond)
				_log("%s fica %s." % [alvo.nome, cond])


func _tem_evasao(ser: Ser, resistencia: String) -> bool:
	return resistencia == "reflexos" and ser is Ameaca and (ser as Ameaca).tem_hab("evasao")


## Fim do turno: enxames ferem quem está junto deles; a múmia a 0 PV morre se não se recuperou.
func _fim_de_turno(ser: Ser) -> void:
	_envelhecer_fintas(ser)
	if ser is Ameaca and not ser.esta_fora_de_combate():
		var amea := ser as Ameaca
		var enx := amea.habilidade("enxame")
		if not enx.is_empty():
			for x in participantes:
				if x.lado == amea.lado or x.esta_fora_de_combate():
					continue
				if grade != null and grade.tem(amea) and grade.tem(x) and not grade.estao_adjacentes(amea, x):
					continue
				var d := aplicar_dano(x, dados.rolar_expressao(String(enx.dano)), String(enx.tipo_dano), 0, amea)
				_log("%s envolve %s: %d de dano." % [amea.nome, x.nome, d])
				if d > 0 and enx.has("ao_ferir"):
					var af: Dictionary = enx.ao_ferir
					if not Teste.rolar(dados, x.dados_da_pericia(af.resistencia), x.bonus_pericia(af.resistencia), int(af.dt)).sucesso:
						x.aplicar_condicao(af.condicao, int(af.get("rodadas", 0)))
	if ser.mods_cena.has("cravado"):
		var cv: Dictionary = ser.mods_cena.cravado
		if ser.tem(Ser.AGARRADO) and ser.mods_cena.get("agarrado_por") == cv.por:
			var d := aplicar_dano(ser, dados.rolar_expressao(String(cv.dano)), String(cv.tipo_dano), 0, cv.por)
			_log("Os chifres cravados rasgam %s: %d de dano." % [ser.nome, d])
		else:
			ser.mods_cena.erase("cravado")
	if ser.mods_cena.get("hipnose_um_turno", false):
		_libertar_hipnose(ser)
	elif ser.mods_cena.has("hipnotizado_por"):
		var tentativas := int(ser.mods_cena.get("hipnose_testes", 0))
		ser.mods_cena["hipnose_testes"] = tentativas + 1
		var dt_h := int(ser.mods_cena.get("hipnose_dt", 29))
		if Teste.rolar(dados, ser.dados_da_pericia("vontade"), ser.bonus_pericia("vontade") + tentativas, dt_h).sucesso:
			_libertar_hipnose(ser)
			_log("[color=#7fd3c7]%s recobra o controle da própria mente.[/color]" % ser.nome)
	if ser.mods_cena.get("permanencia", "") == "neste_turno":
		if ser.pv <= 0:
			ser._morrer()
			_log("%s finalmente se desfaz." % ser.nome)
		else:
			ser.mods_cena.erase("permanencia")
	_verificar_fim()


func _soltar(ser: Ser) -> void:
	ser.condicoes.erase(Ser.AGARRADO)
	ser.mods_cena.erase("agarrado_manobra")
	var quem = ser.mods_cena.get("agarrado_por")
	if quem != null:
		var lista: Array = quem.mods_cena.get("agarrando", [])
		lista.erase(ser)
	ser.mods_cena.erase("agarrado_por")
	ser.mods_cena.erase("agarrado_teste")


func _soltar_todos(ameaca: Ser) -> void:
	for s in ameaca.mods_cena.get("agarrando", []).duplicate():
		_soltar(s)
	if ameaca.mods_cena.has("prendendo"):
		_soltar_succao(ameaca)


func _soltar_succao(succ: Ser) -> void:
	var vitima = succ.mods_cena.get("prendendo")
	succ.mods_cena.erase("prendendo")
	succ.mods_cena.erase("dano_prendendo")
	if vitima != null and vitima.pv > 0:
		vitima.condicoes.erase(Ser.INCONSCIENTE)
		_log("%s solta %s." % [succ.nome, vitima.nome])


## Início do turno: veneno de qualquer ser; constrição, sucção e aceleração.
func _inicio_de_turno_ameacas(ser: Ser) -> void:
	ser.mods_cena.erase("resistencia_extra")
	ser.mods_cena.erase("penalidade_aura")
	for outro in participantes:   # Aura Manifestada (lembrado): −2 dados em alcance curto
		if outro is Ameaca and outro.lado != ser.lado and not outro.esta_fora_de_combate():
			var ap := (outro as Ameaca).habilidade("aura_manifestada")
			if not ap.is_empty() and _perto(outro, ser, String(ap.get("alcance", "curto"))):
				ser.mods_cena["penalidade_aura"] = maxi(int(ser.mods_cena.get("penalidade_aura", 0)), int(ap.dados))
	if ser is Ameaca and (ser as Ameaca).tem_hab("controlar_relogio"):
		var removidas := 0
		for cond in [Ser.ATORDOADO, Ser.PASMO, Ser.AGARRADO, Ser.ENJOADO, Ser.FRACO, Ser.DEBILITADO, Ser.VULNERAVEL, Ser.EM_CHAMAS, Ser.SANGRANDO, Ser.LENTO]:
			if removidas < 2 and ser.tem(cond):
				ser.condicoes.erase(cond)
				removidas += 1
	ser.mods_cena.erase("queimada")
	if ser.tem(Ser.EM_CHAMAS):
		var fogo := aplicar_dano(ser, dados.rolar(6), "fogo")
		_log("%s queima: %d de dano." % [ser.nome, fogo])
	for outro in participantes:   # a foto do viajante vale até o início do próximo turno de quem fotografou
		if outro.mods_cena.get("visivel_ate") == ser:
			outro.mods_cena.erase("visivel_ate")
	if ser.tem(Ser.ASFIXIADO):
		var afog: Dictionary = ser.mods_cena.get("asfixia", {})
		var quem = ser.mods_cena.get("asfixiado_por")
		if Teste.rolar(dados, ser.dados_da_pericia("fortitude"), ser.bonus_pericia("fortitude"), int(afog.get("dt", 20))).sucesso:
			ser.condicoes.erase(Ser.ASFIXIADO)
			ser.mods_cena.erase("asfixiado_por")
			if afog.has("arrancar"):   # Arrancar Sangue: ao ser expelida, leva sangue da vítima
				var ar: Dictionary = afog.arrancar
				var d := aplicar_dano(ser, dados.rolar_expressao(String(ar.dano)), String(ar.tipo_dano), 0, quem)
				ser.aplicar_condicao(String(ar.get("condicao", "")))
				_log("%s expulsa o Sangue, que arranca %d de dano ao sair." % [ser.nome, d])
		else:
			var perda := dados.rolar_expressao(String(afog.get("dano_afogando", "1d6")))
			ser.sofrer_dano(perda)
			_log("%s se afoga em Sangue: −%d PV." % [ser.nome, perda])
	if ser is Ameaca:
		var am := ser as Ameaca
		var cura := am.habilidade("cura_acelerada")
		var valor := 0
		if not cura.is_empty() and not am.mods_cena.get("cura_desligada", false) and not am.tem(Ser.INCONSCIENTE):
			valor = int(cura.valor)
		if am.na_forma_de_sangue():
			valor = maxi(valor, int(am.forma_de_sangue.get("cura_acelerada", 0)))
		if valor > 0 and am.pv > 0 and am.pv < am.pv_maximo:
			am.curar(valor)
		_multiplicacao_melodica(am)
	if ser.mods_cena.get("permanencia", "") == "aguardando":
		ser.mods_cena["permanencia"] = "neste_turno"
	if ser.tem(Ser.SANGRANDO):
		if Teste.rolar(dados, ser.atributo("vig"), 0, 20).sucesso:
			ser.condicoes.erase(Ser.SANGRANDO)
		else:
			var perda := dados.rolar(6)
			ser.sofrer_dano(perda)
			_log("%s sangra: −%d PV." % [ser.nome, perda])
	for outro in participantes:   # auras (Sukkalgir) e drenagem de quem agarra (Múmia)
		if not outro is Ameaca or outro == ser or outro.lado == ser.lado or outro.esta_fora_de_combate():
			continue
		for h in (outro as Ameaca).habilidades:
			if h.get("tipo", "") == "aura":
				var perto: bool = grade == null or not grade.tem(outro) or not grade.tem(ser) or grade.em_alcance(outro, ser, String(h.get("alcance", "curto")))
				if perto:
					var d := dados.rolar_expressao(String(h.dano))
					if Teste.rolar(dados, ser.dados_da_pericia(h.resistencia), ser.bonus_pericia(h.resistencia), int(h.dt)).sucesso:
						d /= 2
					var real := aplicar_dano(ser, d, String(h.tipo_dano), 0, outro)
					_log("A presença de %s fere %s: %d." % [outro.nome, ser.nome, real])
			elif h.get("tipo", "") == "drenar" and ser.mods_cena.get("agarrado_por") == outro:
				var real := aplicar_dano(ser, dados.rolar_expressao(String(h.dano)), String(h.tipo_dano), 0, outro)
				outro.curar(real)
				if outro.mods_cena.get("permanencia", "") != "" and outro.pv > 0:
					outro.mods_cena.erase("permanencia")
				_log("%s drena %s: %d de dano, e recupera o mesmo." % [outro.nome, ser.nome, real])
	ser.mods_cena.erase("acelerado_ativo")
	if ser.mods_cena.has("acelerado"):
		ser.mods_cena["acelerado_ativo"] = ser.mods_cena.acelerado
		ser.mods_cena.erase("acelerado")
	if ser.mods_cena.has("veneno"):
		var v: Dictionary = ser.mods_cena.veneno
		if Teste.rolar(dados, ser.dados_da_pericia("fortitude"), ser.bonus_pericia("fortitude"), int(v.dt)).sucesso:
			ser.mods_cena.erase("veneno")
			_log("%s se livra do veneno." % ser.nome)
		else:
			var d := aplicar_dano(ser, dados.rolar_expressao(String(v.dados)), String(v.tipo_dano))
			_log("O veneno corrói %s: %d de dano." % [ser.nome, d])
	if not ser is Ameaca:
		return
	var amea := ser as Ameaca
	for h in amea.habilidades:
		if h.get("tipo", "") != "constricao":
			continue
		for vit in amea.mods_cena.get("agarrando", []).duplicate():
			var d := dados.rolar_expressao(String(h.dano))
			if h.has("resistencia") and Teste.rolar(dados, vit.dados_da_pericia(h.resistencia), vit.bonus_pericia(h.resistencia), int(h.dt)).sucesso:
				d /= 2
			var real := aplicar_dano(vit, d, String(h.tipo_dano), 0, amea)
			_log("%s esmaga %s: %d de dano." % [amea.nome, vit.nome, real])
	if amea.mods_cena.has("prendendo"):
		var vitima: Ser = amea.mods_cena.prendendo
		if vitima.pv > 0:
			vitima.sofrer_dano(vitima.pv)   # Sucção: a vítima vai a 0 PV e fica morrendo
			_log("[color=#e0574a]%s fica sem ar: 0 PV.[/color]" % vitima.nome)
		amea.mods_cena.erase("prendendo")
		amea.mods_cena.erase("dano_prendendo")


## Imortalidade (esqueleto de Lodo, enraizado): a 0 PV vira poça e volta depois de algumas rodadas.
func _virar_poca(amea: Ameaca) -> void:
	var imo := amea.habilidade("imortalidade")
	amea.condicoes.erase(Ser.MORRENDO)
	amea.condicoes[Ser.POCA] = true
	amea.condicoes[Ser.INCONSCIENTE] = true
	amea.mods_cena["retorno_poca"] = dados.rolar_expressao(String(imo.get("rodadas", "1d3")))
	amea.mods_cena["dano_poca"] = 0
	_soltar_todos(amea)
	_log("[color=#a69b88]%s se desfaz numa poça de Lodo... mas ainda pulsa.[/color]" % amea.nome)


func _danificar_poca(amea: Ameaca, dano: int, tipo_dano: String) -> int:
	var imo := amea.habilidade("imortalidade")
	if not tipo_dano in imo.get("destruido_por", []):
		return 0
	amea.mods_cena["dano_poca"] = int(amea.mods_cena.get("dano_poca", 0)) + dano
	if int(amea.mods_cena.dano_poca) >= int(imo.get("dano_para_destruir", 1)):
		amea._morrer()
		_log("[color=#eda64a]A poça de %s é destruída de vez.[/color]" % amea.nome)
		_verificar_fim()
	return dano


func _processar_pocas() -> void:
	for s in participantes:
		if not s.tem(Ser.POCA) or s.tem(Ser.MORTO):
			continue
		s.mods_cena["retorno_poca"] = int(s.mods_cena.get("retorno_poca", 1)) - 1
		if int(s.mods_cena.retorno_poca) <= 0:
			var imo := (s as Ameaca).habilidade("imortalidade")
			for c in [Ser.POCA, Ser.INCONSCIENTE, Ser.MORRENDO]:
				s.condicoes.erase(c)
			s.pv = mini(s.pv_maximo, int(imo.get("pv", 1)))
			s._atualizar_pv()
			_log("[color=#e0574a]%s se refaz da poça![/color]" % s.nome)


## Usa uma habilidade ativa da ficha (área, condição ou fortalecimento). Retorna {ok, atingidos, ...}.
## `celula`: ponto de uma esfera; linhas usam o alvo como direção.
func usar_habilidade(amea: Ameaca, hab_id: String, alvo: Ser = null, celula = null, livre: bool = false) -> Dictionary:
	var h := amea.habilidade(hab_id)
	if h.is_empty() or amea.esta_fora_de_combate() or not h.has("acao"):
		return {"ok": false, "erro": "sem esta habilidade"}
	if int(h.get("por_rodada", 0)) > 0 and _usou_na_rodada(amea, hab_id):
		return {"ok": false, "erro": "já usou nesta rodada"}
	if int(h.get("por_cena", 0)) > 0 and int(amea.usos.get(hab_id, 0)) >= int(h.por_cena):
		return {"ok": false, "erro": "já usou nesta cena"}
	if h.has("requer") and not amea.mods_cena.get("efeito_" + String(h.requer), false):
		return {"ok": false, "erro": "requer %s" % h.requer}
	if h.has("flor"):
		if int(h.ordem) > int(amea.mods_cena.get("flores", 0)):
			return {"ok": false, "erro": "a flor %s ainda não desabrochou" % h.flor}
		if h.id in amea.mods_cena.get("murchas", []):
			return {"ok": false, "erro": "a flor %s murchou" % h.flor}
	if String(h.get("tipo", "")) == "consumir":
		var cadaver := _cadaver_adjacente(amea)
		if cadaver == null or int(amea.mods_cena.get("flores", 0)) >= 7:
			return {"ok": false, "erro": "nenhum corpo ao alcance"}
		if acoes.has(amea) and not gastar_acao(amea, h.acao):
			return {"ok": false, "erro": "sem ação"}
		_consumidos.append(cadaver)
		amea.mods_cena["flores"] = int(amea.mods_cena.get("flores", 0)) + 1
		_log("[color=#e0574a]%s consome o corpo de %s: desabrocha mais uma flor (%d/7).[/color]" % [amea.nome, cadaver.nome, int(amea.mods_cena.flores)])
		return {"ok": true, "atingidos": []}
	if h.get("requer_forma", false) and not amea.na_forma_de_sangue():
		return {"ok": false, "erro": "só na forma de Sangue"}
	if h.get("so_copia", false) and not amea.mods_cena.get("copia", false):
		return {"ok": false, "erro": "só as cópias"}
	if String(h.get("tipo", "")) in ["alvo", "marcar", "manobra_ataques"]:
		if alvo == null or alvo.esta_fora_de_combate() or (h.has("alcance") and not _alcance_hab(amea, alvo, String(h.alcance))):
			return {"ok": false, "erro": "alvo inválido"}
		if h.get("requer_adjacente", false) and grade != null and grade.tem(amea) and grade.tem(alvo) and not grade.estao_adjacentes(amea, alvo):
			return {"ok": false, "erro": "precisa estar ao lado"}
		if h.get("so_alvo_proprio", false) and amea.mods_cena.get("alvo_ocioso") != alvo:
			return {"ok": false, "erro": "só contra o seu alvo"}
		if h.has("requer_condicao") and (not alvo.tem(h.requer_condicao) or alvo.mods_cena.get("asfixiado_por") != amea):
			return {"ok": false, "erro": "o alvo precisa estar %s" % h.requer_condicao}
		if h.has("hipnose") and _hipnotizados_por(amea).size() >= int(h.hipnose.get("maximo", 3)):
			return {"ok": false, "erro": "já controla o máximo de mentes"}
		if h.get("requer_agarrado", false) and alvo.mods_cena.get("agarrado_por") != amea:
			return {"ok": false, "erro": "precisa estar agarrando o alvo"}
	if h.acao != "livre" and not livre and acoes.has(amea) and not gastar_acao(amea, h.acao):
		return {"ok": false, "erro": "sem ação"}
	_marcar_uso_rodada(amea, hab_id)
	amea.usos[hab_id] = int(amea.usos.get(hab_id, 0)) + 1
	var nome := String(hab_id).capitalize()
	var tipo_h := String(h.get("tipo", ""))
	if tipo_h == "aliados":   # Ordens: buff nos aliados em alcance
		var lista: Array[Ser] = []
		for x in participantes:
			if x != amea and x.lado == amea.lado and not x.esta_fora_de_combate() and _perto(amea, x, String(h.get("alcance", "medio"))):
				x.rituais_ativos[hab_id] = h.buff.duplicate()
				lista.append(x)
		_log("[color=#e0574a]%s usa %s (%d aliado(s)).[/color]" % [amea.nome, nome, lista.size()])
		return {"ok": true, "atingidos": lista}
	if h.has("buff"):
		amea.rituais_ativos[hab_id] = h.buff.duplicate()
		_log("[color=#e0574a]%s usa %s.[/color]" % [amea.nome, nome])
		return {"ok": true, "atingidos": []}
	if tipo_h == "invocar":   # Senhor do Sangue: chama criaturas que agem junto com ele
		var novos: Array[Ser] = []
		for id_inv in h.ameacas:
			var info := DadosJogo.ameaca(ruleset, id_inv)
			var inv := Ameaca.criar(ruleset, info.nome, info.ficha)
			inv.lado = amea.lado
			adicionar_durante(inv, amea)
			novos.append(inv)
		_log("[color=#e0574a]%s invoca %d criatura(s)![/color]" % [amea.nome, novos.size()])
		return {"ok": true, "atingidos": novos}
	if tipo_h == "dois_ataques_agarra":   # Ironia do Destino (marionete)
		var arma_d: Dictionary = amea.ataques[0].duplicate()
		arma_d.erase("vezes")
		atacar(amea, alvo, arma_d, 0, {"ignorar_distancia": true})
		var segundo := atacar(amea, alvo, arma_d, 0, {"ignorar_distancia": true})
		if segundo.acertou and not alvo.esta_fora_de_combate() and not alvo.imune_a_condicao(Ser.AGARRADO):
			alvo.aplicar_condicao(Ser.AGARRADO)
			alvo.mods_cena["agarrado_por"] = amea
			alvo.mods_cena["agarrado_teste"] = {"dados": 5, "bonus": 30}
			var lista_m: Array = amea.mods_cena.get("agarrando", [])
			lista_m.append(alvo)
			amea.mods_cena["agarrando"] = lista_m
			amea.mods_cena["divide_dano"] = alvo
			_log("[color=#e0574a]%s prende %s na foice.[/color]" % [amea.nome, alvo.nome])
		return {"ok": true, "atingidos": [alvo]}
	if h.has("envelhecer") and tipo_h == "alvo":   # Espiral Descendente: 1 de dano mental por ano
		var anos := dados.rolar_expressao(String(h.envelhecer))
		alvo.sofrer_dano_mental(anos)
		_envelhecer(alvo, anos)
		_log("[color=#e0574a]%s envelhece %d anos em segundos.[/color]" % [alvo.nome, anos])
		return {"ok": true, "atingidos": [alvo]}
	if tipo_h == "manobra_ataques":   # Derrubar e Devorar (kerberos)
		var t: Dictionary = h.teste
		var venceu := Teste.rolar(dados, int(t.dados), int(t.bonus), 0).total > _teste_melhor(alvo, ["atletismo", "acrobacia"]).total
		var resultados: Array = []
		if venceu:
			var arma_m: Dictionary = {}
			for a in amea.ataques:
				if a.id == h.arma:
					arma_m = a.duplicate()
			arma_m["dano"] = h.dano
			arma_m.erase("vezes")
			for _k in int(h.ataques):
				if alvo.esta_fora_de_combate():
					break
				resultados.append(atacar(amea, alvo, arma_m, 0, {"ignorar_distancia": true}))
		_log("[color=#e0574a]%s %s %s.[/color]" % [amea.nome, "derruba e morde" if venceu else "tenta derrubar", alvo.nome])
		return {"ok": true, "atingidos": [alvo] if venceu else [], "ataques": resultados}
	if tipo_h == "teleporte":   # Correr pelas Frestas: reaparece perto do alvo
		if alvo != null and grade != null:
			_teleportar_para_perto(amea, alvo)
		return {"ok": true, "atingidos": []}
	if tipo_h == "teleporte_alvo":   # Permanecer Próximo (ocioso)
		var dele = amea.mods_cena.get("alvo_ocioso")
		if dele != null and grade != null:
			_teleportar_para_perto(amea, dele)
		return {"ok": true, "atingidos": []}
	if tipo_h == "marcar":   # Assassinar
		amea.mods_cena[hab_id] = alvo
		_log("[color=#e0574a]%s estuda %s.[/color]" % [amea.nome, alvo.nome if alvo != null else "?"])
		return {"ok": true, "atingidos": [alvo]}
	var atingidos: Array[Ser] = []
	if tipo_h == "alvo":
		if alvo != null and not alvo.esta_fora_de_combate() and (not h.get("requer_agarrado", false) or alvo.mods_cena.get("agarrado_por") == amea):
			atingidos.append(alvo)
	elif grade != null and grade.tem(amea):
		var origem := grade.posicao(amea)
		var ponto = celula if celula != null else (grade.posicao(alvo) if alvo != null and grade.tem(alvo) else origem)
		var metros := float(h.area.get("raio", h.area.get("comprimento", 1.5)))
		for x in grade.seres_em(grade.celulas_da_area(String(h.area.forma), origem, ponto, metros)):
			if x.lado != amea.lado and not x.esta_fora_de_combate():
				atingidos.append(x)
		if h.has("max_alvos"):
			atingidos = atingidos.slice(0, int(h.max_alvos))
	else:
		for x in participantes:
			if x.lado != amea.lado and not x.esta_fora_de_combate():
				atingidos.append(x)
	var rolagem := dados.rolar_expressao(String(h.dano)) if h.has("dano") else 0
	var textos := PackedStringArray()
	for x in atingidos:
		var pen := 0
		if grade != null and grade.estao_adjacentes(amea, x):
			pen = int(h.get("penalidade_adjacente", 0))
		var passou := false
		if h.has("resistencia"):
			passou = Teste.rolar(dados, x.dados_da_pericia(h.resistencia), x.bonus_pericia(h.resistencia), int(h.dt), -pen).sucesso
		if h.has("dano"):
			var d := rolagem
			if passou:
				d = d / 2 if h.get("ao_passar", "metade") == "metade" else 0
			if passou and _tem_evasao(x, String(h.resistencia)):
				d = 0
			if x is Ameaca and (x as Ameaca).tem_hab("enxame") and tipo_h != "alvo":
				d = d * 3 / 2
			if h.tipo_dano == "mental":
				var antes := x.san
				x.sofrer_dano_mental(d)
				if antes > x.san:
					amea.mods_cena["efeito_" + hab_id] = true
				textos.append("%s −%d SAN" % [x.nome, antes - x.san])
			else:
				var estava_machucado := x.tem(Ser.MACHUCADO)
				textos.append("%s %d" % [x.nome, aplicar_dano(x, d, String(h.tipo_dano), 0, amea)])
				if h.has("vulneravel_se_machucado") and not estava_machucado and x.tem(Ser.MACHUCADO):
					var vul_m: Array = x.mods_cena.get("vulnerabilidades", [])
					vul_m.append(h.vulneravel_se_machucado)
					x.mods_cena["vulnerabilidades"] = vul_m
				if h.get("desintegra", false) and x.pv <= 0 and not x.tem(Ser.MORTO):
					x._morrer()
					textos.append("%s é desintegrado" % x.nome)
		if h.get("furia", false) and not passou:
			_hipnotizar(amea, x, int(h.dt), true)   # Desejos de Sangue: no próximo turno, ataca os aliados
			textos.append("%s entra em fúria" % x.nome)
			continue
		if h.has("hipnose") and not passou:
			_hipnotizar(amea, x, int(h.dt))
			textos.append("%s é hipnotizado" % x.nome)
			continue
		if h.has("prisao"):   # Prisão de Tentáculos: preso até os tentáculos caírem
			x.aplicar_condicao(Ser.AGARRADO)
			x.mods_cena["agarrado_por"] = amea
			x.mods_cena["prisao_pv"] = int(h.prisao.pv)
			textos.append("%s fica preso" % x.nome)
		if h.has("condicao") and (not passou or h.get("ao_passar", "") == "reduz"):
			var rod: int = dados.rolar_expressao(str(h.rodadas)) if str(h.get("rodadas", "")).contains("d") else int(h.get("rodadas", 0))
			if passou:
				rod = 1   # Miasma Fétido: passar reduz para 1 rodada
			x.aplicar_condicao(h.condicao, rod)
			if h.has("asfixia"):
				x.mods_cena["asfixia"] = h.asfixia
				x.mods_cena["asfixiado_por"] = amea
			if h.get("abraco", false):
				amea.mods_cena["abracando"] = x
			textos.append("%s fica %s" % [x.nome, x.condicoes.keys()[-1] if not x.condicoes.is_empty() else h.condicao])
	_log("[color=#e0574a]%s usa %s:[/color] %s" % [amea.nome, nome, ", ".join(textos) if not textos.is_empty() else "ninguém é atingido"])
	if h.get("morre", false):
		amea._morrer()
	_verificar_fim()
	return {"ok": true, "atingidos": atingidos}


## Cultistas (p.296) conjuram os rituais da ficha sem gastar PE, até o limite, com DT fixa.
func conjurar_ameaca(amea: Ameaca, ritual_id: String, alvo: Ser, opcoes: Dictionary = {}) -> Dictionary:
	var r := ruleset.ritual(ritual_id)
	if not amea.conhece_ritual(ritual_id) or not r.get("implementado", false):
		return {"ok": false, "erro": "não conhece o ritual"}
	if ruleset.custo_base_ritual(int(r.circulo)) > int(amea.conjurador.get("limite_pe", 3)):
		return {"ok": false, "erro": "acima do limite de PE"}
	var e := efeito_do_ritual(ritual_id)
	if not e.has("area"):
		var erro := _erro_de_alcance(amea, alvo, String(e.alcance))
		if erro != "":
			return {"ok": false, "erro": erro}
	if acoes.has(amea) and not gastar_acao(amea, "completa" if String(r.get("execucao", "")).begins_with("completa") else "padrao"):
		return {"ok": false, "erro": "sem ação"}
	if membrana != null:
		membrana.registrar_ritual(int(r.circulo))
	var res := {"ok": true, "ritual": r, "forma": "", "custo": 0, "alvo": alvo, "conjurador": amea, "textos": [], "danos": {}, "dano_total": 0}
	var celulas := _celulas_do_efeito(amea, e, alvo, opcoes)
	var alvos := _alvos_do_efeito(amea, e, alvo, opcoes, celulas)
	res.celulas = celulas
	res.alvos = alvos
	if e.has("zona"):
		res.zona = _criar_zona(amea, ritual_id, e, celulas)
	if e.tipo == "dano" and e.has("area"):
		res.dano_area = _rolar_dano_ritual(amea, e)
	for x in alvos:
		_aplicar_efeito_ritual(amea, ritual_id, r, e, x, res)
	_log("[color=#e0574a]%s conjura %s em %s.[/color] %s" % [amea.nome, r.nome, alvo.nome if alvo != null else "uma área", " ".join(PackedStringArray(res.textos))])
	ritual_conjurado.emit(res)
	_verificar_fim()
	return res


# --- Enigma de Medo (p.190) ------------------------------------------------

## Ação padrão: um agente tenta decifrar o enigma da criatura de Medo. Pistas da missão
## (regras.bonus_enigma) reduzem a DT. Resolvido, a criatura perde a imunidade a dano.
func decifrar_enigma(agente: Agente, criatura: Ameaca, pericia: String = "") -> ResultadoTeste:
	if not criatura.enigma_pendente():
		return null
	if criatura.enigma.get("tipo", "") == "melodia":
		return tocar_melodia(agente)
	if criatura.enigma.get("tipo", "") == "acumular_dano":
		_log("O enigma de %s não se resolve com testes: %s" % [criatura.nome, criatura.enigma.get("texto", "")])
		return null
	var etapa := criatura.etapa_atual()
	var pericias: Array = etapa.get("pericias", ["ocultismo"])
	if pericia == "":
		pericia = pericias[0]
		for p_id in pericias:
			if agente.dados_da_pericia(p_id) * 100 + agente.bonus_pericia(p_id) > agente.dados_da_pericia(pericia) * 100 + agente.bonus_pericia(pericia):
				pericia = p_id
	if not pericia in pericias or (acoes.has(agente) and not gastar_acao(agente, "padrao")):
		return null
	var dt := int(etapa.get("dt", 20)) - int(regras.get("bonus_enigma", 0))
	if criatura.enigma.has("pergunta") and criatura.enigma.pergunta in regras.get("perguntas_respondidas", []):
		dt -= 5   # a investigação já respondeu a pergunta ligada ao enigma
	var t := agente.testar(dados, pericia, dt)
	if t == null or not t.sucesso:
		_log("%s tenta: %s (%s), sem sucesso." % [agente.nome, etapa.get("texto", "decifrar o enigma"), ruleset.pericia(pericia).nome])
		return t
	if criatura.enigma.get("tipo", "") == "temporario":
		criatura.mods_cena["visivel_ate"] = agente   # Viajante: fotografado, fica visível até o próximo turno de quem fotografou
		_log("[color=#eda64a]%s consegue: %s. %s fica à vista por um instante![/color]" % [agente.nome, etapa.get("texto", ""), criatura.nome])
		return t
	criatura.enigma["etapa"] = int(criatura.enigma.get("etapa", 0)) + 1
	if criatura.etapa_atual().is_empty():
		_resolver_enigma(criatura, agente)
	else:
		_log("[color=#eda64a]%s consegue: %s. Próximo passo: %s.[/color]" % [agente.nome, etapa.get("texto", ""), criatura.etapa_atual().get("texto", "")])
	return t


func _resolver_enigma(criatura: Ameaca, agente: Ser = null) -> void:
	criatura.enigma.resolvido = true
	var ef = criatura.enigma.get("efeito", "remove_imunidade")
	if ef is Dictionary:
		if ef.get("remove_imunidade", true):
			criatura.imunidades.erase("dano")
			for t in ef.get("mantem_imunidade", []):
				if not t in criatura.imunidades:
					criatura.imunidades.append(t)
		if ef.get("remove_resistencia_dano", false):
			criatura.resistencias_base = criatura.resistencias_base.duplicate()
			criatura.resistencias_base.erase("dano")
		var tirar: Array = ef.get("remove_habilidades", [])
		criatura.habilidades = criatura.habilidades.filter(func(h): return not h.id in tirar)
		var pen: Dictionary = ef.get("penalidades", {})
		if pen.has("menos_defesa"):
			criatura.mods_cena["menos_defesa"] = int(criatura.mods_cena.get("menos_defesa", 0)) + int(pen.menos_defesa)
		for per in pen.get("menos_dados", {}):
			var md: Dictionary = criatura.mods_cena.get("menos_dados", {})
			md[per] = int(md.get(per, 0)) + int(pen.menos_dados[per])
			criatura.mods_cena["menos_dados"] = md
		_log("[color=#eda64a]O enigma de %s foi resolvido: ele enfraquece![/color]" % criatura.nome)
		return
	match String(ef):
		"remove_imunidade":
			criatura.imunidades.erase("dano")
			_log("[color=#eda64a]%s decifra o enigma: %s perde a proteção![/color]" % [agente.nome if agente != null else "O grupo", criatura.nome])
		"forma_fisica":
			_log("[color=#eda64a]%s é forçada à forma física: agora pode ser vencida![/color]" % criatura.nome)


## Escutado: ação padrão e Artes (DT 25) para tocar a melodia nesta rodada.
func tocar_melodia(agente: Agente) -> ResultadoTeste:
	var escutado: Ameaca = null
	for s in participantes:
		if s is Ameaca and (s as Ameaca).enigma.get("tipo", "") == "melodia" and (s as Ameaca).enigma_pendente():
			escutado = s
	if escutado == null or (acoes.has(agente) and not gastar_acao(agente, "padrao")):
		return null
	var t := agente.testar(dados, String(escutado.enigma.get("pericia", "artes")), int(escutado.enigma.get("dt", 25)))
	if t != null and t.sucesso:
		_melodia_rodada = rodada
		_melodia_quem = agente
		_log("[color=#eda64a]%s toca a melodia proibida.[/color]" % agente.nome)
	else:
		_log("%s erra as notas da melodia." % agente.nome)
	return t


## No início do turno do escutado (e das cópias): se a melodia tocou desde o turno anterior,
## surge uma cópia; o original conta as rodadas seguidas e, com 4, perde a imunidade.
func _multiplicacao_melodica(am: Ameaca) -> void:
	var h := am.habilidade("multiplicacao_melodica")
	if h.is_empty():
		return
	var ouviu := _melodia_rodada >= rodada - 1
	if am.enigma.get("tipo", "") == "melodia" and am.enigma_pendente():
		am.enigma["rodadas"] = int(am.enigma.get("rodadas", 0)) + 1 if ouviu else 0
	if not ouviu:
		return
	var ficha: Dictionary = am.ficha_original.duplicate(true)
	ficha.pv = int(h.get("pv_copia", 145))
	ficha.erase("imunidades")
	ficha.erase("enigma")
	ficha.erase("presenca_perturbadora")
	var copia := Ameaca.criar(ruleset, "%s (cópia)" % am.nome.trim_suffix(" (cópia)"), ficha)
	copia.mods_cena["copia"] = true
	adicionar_durante(copia, am)
	_log("[color=#e0574a]A melodia faz surgir outra cópia do %s![/color]" % am.nome.trim_suffix(" (cópia)"))
	if am.enigma.get("tipo", "") == "melodia" and int(am.enigma.get("rodadas", 0)) >= int(am.enigma.get("rodadas_necessarias", 4)):
		_resolver_enigma(am, _melodia_quem)


## Coloca um ser no meio do combate: age logo depois de `perto_de`, numa célula livre próxima.
func adicionar_durante(ser: Ser, perto_de: Ser) -> void:
	adicionar(ser)
	iniciativas[ser] = iniciativas.get(perto_de, 0)
	var i := ordem.find(perto_de)
	ordem.insert(i + 1 if i >= 0 else ordem.size(), ser)
	if i >= 0 and i < _indice:
		_indice += 1
	if grade != null and grade.tem(perto_de):
		_teleportar_para_perto(ser, perto_de, true)
	ser_adicionado.emit(ser)


## Põe o ser na célula livre mais próxima de `alvo` (teleporte; não gasta deslocamento).
func _teleportar_para_perto(ser: Ser, alvo: Ser, novo: bool = false) -> void:
	if grade == null or not grade.tem(alvo):
		return
	var centro := grade.posicao(alvo)
	var melhor := Vector2i(-1, -1)
	for raio in range(1, 8):
		for dx in range(-raio, raio + 1):
			for dy in range(-raio, raio + 1):
				var c := centro + Vector2i(dx, dy)
				if grade.dentro(c) and not grade.bloqueada(c) and grade.ocupante(c) == null:
					if melhor == Vector2i(-1, -1) or Grade.distancia(c, centro) < Grade.distancia(melhor, centro):
						melhor = c
		if melhor != Vector2i(-1, -1):
			break
	if melhor == Vector2i(-1, -1):
		return
	if not novo and grade.tem(ser):
		grade.remover(ser)
	grade.colocar(ser, melhor)


func _alcance_hab(amea: Ser, alvo: Ser, alcance: String) -> bool:
	if alcance == "adjacente":
		return grade == null or not grade.tem(amea) or not grade.tem(alvo) or grade.estao_adjacentes(amea, alvo)
	return _perto(amea, alvo, alcance)


# --- Dama de Sangue (p.200) ----------------------------------------------------

## Uma flor murcha: a Dama perde a habilidade e sofre a penalidade da flor.
func _murchar(dama: Ameaca, h: Dictionary) -> void:
	var murchas: Array = dama.mods_cena.get("murchas", [])
	if h.id in murchas:
		return
	murchas.append(h.id)
	dama.mods_cena["murchas"] = murchas
	var pen: Dictionary = h.get("penalidade", {})
	for pericia in pen.get("menos_dados", {}):
		var md: Dictionary = dama.mods_cena.get("menos_dados", {})
		md[pericia] = int(md.get(pericia, 0)) + int(pen.menos_dados[pericia])
		dama.mods_cena["menos_dados"] = md
	for k in ["menos_resistencia", "menos_defesa", "menos_deslocamento"]:
		if pen.has(k):
			dama.mods_cena[k] = int(dama.mods_cena.get(k, 0)) + int(pen[k])
	if pen.has("menos_pv"):
		dama.pv_maximo = maxi(1, dama.pv_maximo - int(pen.menos_pv))
		dama.pv = mini(dama.pv, dama.pv_maximo)
	_log("[color=#eda64a]A flor %s da %s murcha![/color]" % [h.flor, dama.nome])


func _cadaver_adjacente(amea: Ser) -> Ser:
	for x in participantes:
		if x.tem(Ser.MORTO) and not x in _consumidos and (grade == null or not grade.tem(x) or not grade.tem(amea) or grade.estao_adjacentes(amea, x)):
			return x
	return null


## Usa um item contra uma ameaça adjacente (fertilizante, agrotóxico… contra a Dama de Sangue).
func usar_contra(agente: Agente, alvo: Ameaca, item_id: String) -> bool:
	var info := ruleset.equipamento(item_id)
	if not agente.tem_item(item_id) or info.get("contra", "") == "":
		return false
	if grade != null and grade.tem(agente) and grade.tem(alvo) and not grade.estao_adjacentes(agente, alvo):
		return false
	if acoes.has(agente) and not gastar_acao(agente, "padrao"):
		return false
	agente.consumir_item(item_id)
	var murchou := false
	for h in alvo.habilidades:
		if h.get("murcha", {}).get("item", "") == item_id and int(h.get("ordem", 0)) <= int(alvo.mods_cena.get("flores", 0)):
			_murchar(alvo, h)
			murchou = true
	if not murchou:
		_log("%s usa %s em %s, sem efeito." % [agente.nome, info.nome, alvo.nome])
	return murchou


# --- Granadas (p.74) ---------------------------------------------------------------

## Ação padrão: arremessa a granada num ponto em alcance médio; atinge todos a 6 m (aliados também).
func usar_granada(agente: Agente, item_id: String, celula: Vector2i) -> Dictionary:
	var info := ruleset.equipamento(item_id)
	var ex: Dictionary = info.get("explosivo", {})
	if ex.is_empty() or not agente.tem_item(item_id):
		return {"ok": false, "erro": "sem esta granada"}
	if grade != null and grade.tem(agente) and Grade.distancia(grade.posicao(agente), celula) > int(Grade.ALCANCES.get(ex.get("alcance", "medio"), 12)):
		return {"ok": false, "erro": "fora de alcance"}
	if acoes.has(agente) and not gastar_acao(agente, "padrao"):
		return {"ok": false, "erro": "sem ação padrão"}
	agente.consumir_item(item_id)
	var atingidos: Array[Ser] = []
	if grade != null and grade.tem(agente):
		for x in grade.seres_em(grade.celulas_da_area("esfera", grade.posicao(agente), celula, float(ex.get("raio", 6)))):
			if not x.esta_fora_de_combate() or x.tem(Ser.POCA):
				atingidos.append(x)
	var dt := agente.dt_habilidade(String(ex.get("dt_atributo", "agi")))
	var rolagem := dados.rolar_expressao(String(ex.dano)) if ex.has("dano") else 0
	var textos := PackedStringArray()
	for x in atingidos:
		var passou := Teste.rolar(dados, x.dados_da_pericia(ex.resistencia), x.bonus_pericia(ex.resistencia), dt).sucesso
		if ex.has("dano"):
			var d := rolagem
			if passou:
				d = 0 if _tem_evasao(x, String(ex.resistencia)) else d / 2
			if x is Ameaca and (x as Ameaca).tem_hab("enxame"):
				d = d * 3 / 2
			textos.append("%s %d" % [x.nome, aplicar_dano(x, d, String(ex.tipo_dano), 0, agente)])
		if ex.has("condicao") and not passou:
			x.aplicar_condicao(String(ex.condicao), int(ex.get("rodadas", 0)))
			textos.append("%s fica %s" % [x.nome, ex.condicao])
		elif passou and ex.has("ao_passar_condicao"):
			x.aplicar_condicao(String(ex.ao_passar_condicao), 1)
	_log("[color=#eda64a]%s arremessa %s:[/color] %s" % [agente.nome, info.nome, ", ".join(textos) if not textos.is_empty() else "ninguém é atingido"])
	_verificar_fim()
	return {"ok": true, "atingidos": atingidos}


## Ação padrão para apagar as chamas (p.320).
func apagar_chamas(ser: Ser) -> bool:
	if not ser.tem(Ser.EM_CHAMAS) or (acoes.has(ser) and not gastar_acao(ser, "padrao")):
		return false
	ser.condicoes.erase(Ser.EM_CHAMAS)
	_log("%s apaga as chamas." % ser.nome)
	return true


## Toque Acelerador (sempiternal): envelhecer 20+ anos deixa fraco, 40+ debilitado, 60+ mata.
func _envelhecer(ser: Ser, anos: int) -> void:
	if ser is Agente and (ser as Agente).afinidade == "morte":
		return   # afinidade com a Morte protege
	var total := int(ser.mods_cena.get("anos_envelhecidos", 0)) + anos
	ser.mods_cena["anos_envelhecidos"] = total
	if total >= 60:
		ser._morrer()
		_log("[color=#e0574a]%s envelhece até virar pó.[/color]" % ser.nome)
	elif total >= 40:
		ser.aplicar_condicao(Ser.DEBILITADO)
	elif total >= 20:
		ser.condicoes[Ser.FRACO] = true


## Comportamento Errático (anárquico, p.267): uma rolagem de 1d6 no começo do turno.
## Se não puder agir, fica se contorcendo com resistência a dano 5 até o próximo turno.
func comportamento_anarquico(amea: Ameaca) -> int:
	var r := dados.rolar(6)
	var inimigos: Array[Ser] = []
	for x in participantes:
		if x.lado != amea.lado and not x.esta_fora_de_combate():
			inimigos.append(x)
	if inimigos.is_empty():
		return r
	var perto: Ser = inimigos[0]
	if grade != null and grade.tem(amea):
		for x in inimigos:
			if grade.tem(x) and grade.distancia_entre(amea, x) < grade.distancia_entre(amea, perto):
				perto = x
	var agiu := true
	match r:
		1, 2, 6:
			if grade != null and grade.tem(amea) and not grade.estao_adjacentes(amea, perto):
				var destino := grade.aproximar(amea, perto, amea.deslocamento_quadrados())
				if destino != grade.posicao(amea):
					grade.remover(amea)
					grade.colocar(amea, destino)
			if grade == null or grade.estao_adjacentes(amea, perto):
				atacar(amea, perto, amea.ataques[0])
			else:
				agiu = false
			if r == 6:
				amea.aplicar_condicao(Ser.DESPREVENIDO, 1)
		3, 4:
			if _perto(amea, perto, "medio"):
				var d := dados.rolar_expressao("2d8")
				if Teste.rolar(dados, perto.dados_da_pericia("fortitude"), perto.bonus_pericia("fortitude"), 14).sucesso:
					d /= 2
				else:
					perto.aplicar_condicao(Ser.ATORDOADO, 1)
				_log("%s dispara luz prismática em %s: %d." % [amea.nome, perto.nome, aplicar_dano(perto, d, "energia", 0, amea)])
			else:
				agiu = false
		5:
			var textos := PackedStringArray()
			for x in inimigos:
				if not _perto(amea, x, "curto"):
					continue
				var d := dados.rolar_expressao("2d6")
				if grade != null and grade.estao_adjacentes(amea, x):
					d += dados.rolar(6)
				if Teste.rolar(dados, x.dados_da_pericia("reflexos"), x.bonus_pericia("reflexos"), 14).sucesso:
					d /= 2
				textos.append("%s %d" % [x.nome, aplicar_dano(x, d, "energia", 0, amea)])
			_log("%s explode em Energia: %s" % [amea.nome, ", ".join(textos)])
			agiu = not textos.is_empty()
	if not agiu:
		amea.mods_cena["resistencia_extra"] = 5
		_log("%s se contorce." % amea.nome)
	_verificar_fim()
	return r


# --- Hipnose (carniçal) --------------------------------------------------------

func _hipnotizar(amea: Ameaca, ser: Ser, dt: int, um_turno: bool = false) -> void:
	if ser.mods_cena.has("hipnotizado_por"):
		return
	ser.mods_cena["hipnose_um_turno"] = um_turno
	ser.mods_cena["hipnotizado_por"] = amea
	ser.mods_cena["lado_original"] = ser.lado
	ser.mods_cena["hipnose_dt"] = dt
	ser.mods_cena["hipnose_testes"] = 0
	ser.lado = amea.lado
	_log("[color=#e0574a]%s cai sob o controle de %s![/color]" % [ser.nome, amea.nome])


func _libertar_hipnose(ser: Ser) -> void:
	if not ser.mods_cena.has("hipnotizado_por"):
		return
	ser.lado = ser.mods_cena.lado_original
	for k in ["hipnotizado_por", "lado_original", "hipnose_dt", "hipnose_testes", "hipnose_um_turno"]:
		ser.mods_cena.erase(k)


func _hipnotizados_por(amea: Ameaca) -> Array:
	return participantes.filter(func(s): return s.mods_cena.get("hipnotizado_por") == amea)


# --- Transformação, retaliação e comportamento errático ------------------------

## Enpap-X: a 0 PV, em vez de cair, assume a outra ficha com todos os PV e mostra sua presença.
func _transformar(amea: Ameaca) -> void:
	var t: Dictionary = amea.transformacao
	amea.aplicar_ficha(t.ficha)
	amea.transformacao = {}
	amea.nome = String(t.get("nome", amea.nome))
	for c in [Ser.INCONSCIENTE, Ser.MORRENDO, Ser.MACHUCADO]:
		amea.condicoes.erase(c)
	amea.pv = amea.pv_maximo
	_log("[color=#e0574a][b]As correntes se partem: surge o %s![/b][/color]" % amea.nome)
	if regras.get("presenca_perturbadora", false):
		presenca_perturbadora(amea)


func _escolher_alvo_ocioso(amea: Ameaca) -> void:
	for s in participantes:
		if s.lado != amea.lado and s is Agente and not s.esta_fora_de_combate():
			amea.mods_cena["alvo_ocioso"] = s
			_log("[color=#b98ae6]Só %s enxerga %s.[/color]" % [s.nome, amea.nome])
			return


## Retaliação (ocioso): atacado, aparece ao lado de quem atacou e golpeia.
func _retaliar(amea: Ameaca, atacante: Ser) -> void:
	if amea.esta_fora_de_combate() or atacante.esta_fora_de_combate() or _usou_na_rodada(amea, "retaliando"):
		return
	_marcar_uso_rodada(amea, "retaliando")
	_teleportar_para_perto(amea, atacante)
	var arma: Dictionary = amea.ataques[0] if not amea.ataques.is_empty() else ruleset.arma("desarmado")
	_log("[color=#e0574a]%s está de repente ao lado de %s.[/color]" % [amea.nome, atacante.nome])
	atacar(amea, atacante, arma, 0, {"ignorar_distancia": true, "nao_letal": true, "nao_letal_natural": true})   # retaliação não letal (p.254)
	_usos_rodada.get(amea, {}).erase("retaliando")


## Comportamento Errático (anomiático, p.273): três rolagens de 1d6, executadas em ordem.
## Cada ação que não puder fazer dá +10 de resistência a dano até o próximo turno.
func comportamento_erratico(amea: Ameaca) -> Array[int]:
	var rolagens: Array[int] = []
	var perdidas := 0
	for _i in 3:
		if encerrado or amea.esta_fora_de_combate():
			break
		var r := dados.rolar(6)
		rolagens.append(r)
		var inimigos: Array[Ser] = []
		for x in participantes:
			if x.lado != amea.lado and not x.esta_fora_de_combate():
				inimigos.append(x)
		if inimigos.is_empty():
			break
		var adjacentes: Array[Ser] = []
		for x in inimigos:
			if grade == null or not grade.tem(amea) or not grade.tem(x) or grade.estao_adjacentes(amea, x):
				adjacentes.append(x)
		match r:
			1, 2:   # salta até 18 m na direção do mais próximo e ataca se chegar
				var perto: Ser = inimigos[0]
				if grade != null and grade.tem(amea):
					for x in inimigos:
						if grade.tem(x) and grade.distancia_entre(amea, x) < grade.distancia_entre(amea, perto):
							perto = x
					var destino := grade.aproximar(amea, perto, 12)
					if destino != grade.posicao(amea):
						grade.remover(amea)
						grade.colocar(amea, destino)
				if grade == null or grade.estao_adjacentes(amea, perto):
					for _k in int(amea.ataques[0].get("vezes", 1)):
						atacar(amea, perto, amea.ataques[0])
				else:
					perdidas += 1
			3:   # vira um facho de Energia e aparece ao lado de alguém sorteado
				_teleportar_para_perto(amea, inimigos[dados.rolar(inimigos.size()) - 1])
			4:   # parte do corpo explode
				var textos := PackedStringArray()
				for x in inimigos:
					var faixa := "curto"
					if grade != null and grade.tem(amea) and grade.tem(x):
						faixa = "adjacente" if grade.estao_adjacentes(amea, x) else ("curto" if grade.em_alcance(amea, x, "curto") else ("medio" if grade.em_alcance(amea, x, "medio") else "fora"))
					if faixa == "fora":
						continue
					var d := dados.rolar_expressao({"adjacente": "8d12+20", "curto": "6d12+20", "medio": "4d12+20"}[faixa])
					if faixa != "adjacente" and Teste.rolar(dados, x.dados_da_pericia("reflexos"), x.bonus_pericia("reflexos"), 30).sucesso:
						d /= 2
					textos.append("%s %d" % [x.nome, aplicar_dano(x, d, "energia", 0, amea)])
				amea.sofrer_dano(50)
				_log("[color=#e0574a]%s explode em parte:[/color] %s (e perde 50 PV)" % [amea.nome, ", ".join(textos)])
			5:   # gargalhada: fica desprevenido
				amea.aplicar_condicao(Ser.DESPREVENIDO, 1)
				_log("%s gargalha, descontrolado." % amea.nome)
			6:   # toque de Energia pura
				if adjacentes.is_empty():
					perdidas += 1
				else:
					var alvo: Ser = adjacentes[0]
					var d := dados.rolar_expressao("10d12+20")
					if Teste.rolar(dados, alvo.dados_da_pericia("fortitude"), alvo.bonus_pericia("fortitude"), 30).sucesso:
						d /= 2
					_log("[color=#e0574a]%s toca %s com Energia pura: %d de dano.[/color]" % [amea.nome, alvo.nome, aplicar_dano(alvo, d, "energia", 0, amea)])
	if perdidas > 0:
		amea.mods_cena["resistencia_extra"] = 10 * perdidas
		_log("%s se contorce (+%d de resistência)." % [amea.nome, 10 * perdidas])
	_verificar_fim()
	return rolagens


## Sustentado (p.130): 1 PE no início de cada turno do conjurador, ou o ritual termina.
## Um ritual com vários alvos custa 1 PE por turno, não 1 por alvo.
func _manter_sustentados(ser: Ser) -> void:
	var pagos := {}
	for s in _sustentados.duplicate():
		if s.conjurador != ser or pagos.has(s.ritual) or not s in _sustentados:
			continue
		if not ser is Agente:
			continue   # cultistas sustentam sem PE (p.296)
		if (ser as Agente).gastar_pe(1, true):
			pagos[s.ritual] = true
		else:
			for outro in _sustentados.duplicate():
				if outro.conjurador == ser and outro.ritual == s.ritual:
					_encerrar_sustentado(outro)
			_log("%s não sustenta mais %s." % [ser.nome, ruleset.ritual(s.ritual).nome])


func _encerrar_sustentado(s: Dictionary) -> void:
	_sustentados.erase(s)
	if s.get("zona") != null:
		_remover_zona(s.zona)
	elif s.alvo != null:
		s.alvo.rituais_ativos.erase(s.ritual)


func _encerrar_sustentados_de(conjurador: Ser) -> void:
	for s in _sustentados.duplicate():
		if s.conjurador == conjurador:
			_encerrar_sustentado(s)


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
	arma_base = arma_em_maos(atacante, arma_base)
	if _fintado_por(alvo, atacante):
		opcoes["fintado"] = true   # Fintar (p.86): desprevenido contra este ataque
	var res := ResultadoAtaque.new()
	res.atacante = atacante
	res.alvo = alvo
	var arma: Dictionary = (atacante as Agente).arma_efetiva(arma_base) if atacante is Agente else arma_base
	res.arma = arma
	var agente: Agente = atacante as Agente
	var mods := atacante.modificar_ataque(arma, alvo)
	if opcoes.has("dados_dano_ritual"):   # Decadência/Hemofagia discente: o ritual vai na arma
		mods["dados_dano_ritual"] = String(mods.get("dados_dano_ritual", "")) + ("+" if mods.has("dados_dano_ritual") else "") + String(opcoes.dados_dano_ritual)
	var tipo_ataque: String = arma.get("ataque", "corpo_a_corpo")
	var eh_corpo_a_corpo := tipo_ataque == "corpo_a_corpo"
	var dados_extras := pe_foco + int(mods.dados_extras)
	var bonus_ataque := int(mods.bonus_ataque)
	# Dano não letal (p.88): o desarmado já é não letal; trocar o padrão da arma custa −5.
	# Só corpo a corpo.
	# Design do jogo: criaturas paranormais não desmaiam (golpe sempre letal, sem penalidade);
	# ataques que carregam um ritual também são letais.
	var pode_render: bool = eh_corpo_a_corpo and not opcoes.has("dados_dano_ritual") and not (alvo is Ameaca and (alvo as Ameaca).criatura)
	var padrao_nao_letal: bool = pode_render and String(arma.get("id", "")) == "desarmado"
	var nao_letal := padrao_nao_letal
	if pode_render and opcoes.has("nao_letal"):
		nao_letal = bool(opcoes.nao_letal)
	if nao_letal != padrao_nao_letal and not opcoes.get("nao_letal_natural", false):
		bonus_ataque -= 5   # o golpe que já é não letal por natureza (retaliação do ocioso) não paga
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
	if grade != null and grade.elevado(atacante) and not grade.elevado(alvo):
		dados_extras += 1   # posição elevada (p.89)
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
	if opcoes.get("fintado", false):
		alvo.mods_cena.erase("fintado_por")
		if not (alvo.tem(Ser.DESPREVENIDO) or alvo.tem(Ser.SURPREENDIDO) or alvo.tem(Ser.AGARRADO) or alvo.esta_indefeso()):
			defesa -= 5   # desprevenido contra este ataque
	if alvo.tem(Ser.CAIDO):
		defesa += -5 if eh_corpo_a_corpo else 5   # caído (p.310)
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

	# Ameaças (cap. 7): ferocidade, furtivo e letal, ataque furtivo
	var amea := atacante as Ameaca
	var furtivo_amea := ""
	if amea != null:
		var desprevenido: bool = alvo.tem(Ser.DESPREVENIDO) or alvo.tem(Ser.SURPREENDIDO) or alvo.tem(Ser.AGARRADO) or alvo.esta_indefeso()
		if amea.tem_hab("ferocidade") and amea.mods_cena.get("ferocidade", false):
			dados_extras += 1
			mods.dados_dano_extra = int(mods.dados_dano_extra) + 1
		if amea.tem_hab("sadismo") and amea.mods_cena.get("sadismo", false):
			amea.mods_cena.erase("sadismo")   # Sadismo: +1 dado e um dado de dano depois de ferir
			dados_extras += 1
			mods.dados_dano_extra = int(mods.dados_dano_extra) + 1
		if amea.tem_hab("invisivel") and not amea.mods_cena.has("visivel_ate"):
			desprevenido = true   # quem não vê o atacante fica desprevenido contra ele
			defesa -= 5
		if amea.tem_hab("furtivo_e_letal") and desprevenido:
			dados_extras += 1
			mods.dados_dano_extra = int(mods.dados_dano_extra) + 2
		var af := amea.habilidade("ataque_furtivo")
		var perto: bool = eh_corpo_a_corpo or grade == null or not grade.tem(atacante) or not grade.tem(alvo) or grade.em_alcance(atacante, alvo, "curto")
		if not af.is_empty() and perto and (desprevenido or opcoes.get("flanqueando", false)) and not _usou_na_rodada(amea, "ataque_furtivo"):
			furtivo_amea = String(af.dados)
			_marcar_uso_rodada(amea, "ataque_furtivo")
			if amea.mods_cena.get("assassinar") == alvo:   # Assassinar: dados extras dobrados
				var ef := Dados.interpretar(furtivo_amea)
				furtivo_amea = "%dd%d" % [int(ef.quantidade) * 2, int(ef.faces)]
				amea.mods_cena.erase("assassinar")
	var pericia_id: String = arma.get("pericia", "luta")
	var dados_teste := atacante.dados_da_pericia(pericia_id)
	var bonus_teste := atacante.bonus_pericia(pericia_id)
	if arma.has("teste"):   # ataque de ficha de ameaça: "TESTE 2O+5" já inclui tudo
		dados_teste = int(arma.teste.dados) - atacante.penalidade_dados_atributo(ruleset.atributo_da_pericia(pericia_id)) + atacante.efeito_ritual("dados_testes") - int(atacante.mods_cena.get("menos_dados", {}).get(pericia_id, 0))
		bonus_teste = int(arma.teste.bonus) + atacante.efeito_ritual("pericias")
	res.teste = Teste.rolar(dados, dados_teste, bonus_teste + bonus_ataque, defesa, dados_extras)
	if agente != null:
		agente.sofrer_dano_por_teste(dados, ruleset.atributo_da_pericia(pericia_id))   # Gota, Pulmão Ruim
	res.acertou = res.teste.sucesso
	if res.acertou and grade != null and grade.camuflado(alvo) and dados.rolar(10) <= 2:
		res.acertou = false   # camuflagem leve: 1 ou 2 no d10 (p.89)
		_log("O golpe de %s se perde: %s está encoberto." % [atacante.nome, alvo.nome])
	var invisivel_para_ele := false
	if alvo is Ameaca:
		var aa_ := alvo as Ameaca
		invisivel_para_ele = (aa_.tem_hab("invisivel") and not aa_.mods_cena.has("visivel_ate")) or (aa_.tem_hab("sempre_presente") and aa_.mods_cena.get("alvo_ocioso") != atacante)
	if res.acertou and invisivel_para_ele:
		var hab_inv := (alvo as Ameaca).habilidade("invisivel") if (alvo as Ameaca).tem_hab("invisivel") else (alvo as Ameaca).habilidade("sempre_presente")
		if dados.rolar(100) <= int(hab_inv.get("chance_erro", 50)):
			res.acertou = false   # camuflagem total: o golpe passa pelo vazio
			_log("%s ataca o vazio: %s é invisível." % [atacante.nome, alvo.nome])
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
		var fortificado := false
		if alvo is Ameaca and (alvo as Ameaca).tem_hab("fortificacao"):
			fortificado = dados.rolar(100) <= int((alvo as Ameaca).habilidade("fortificacao").get("chance", 50)) and (res.critico or furtivo_amea != "")
			if fortificado and res.critico:
				res.critico = false   # Fortificação (policial de elite)
				res.critico_ignorado = true
		if fortificado:
			furtivo_amea = ""
		var mult_critico := int(arma.get("multiplicador", 2))
		if agente != null:
			mult_critico += agente._soma_efeitos("multiplicador_critico")
		if eh_corpo_a_corpo:
			mult_critico += atacante.efeito_ritual("multiplicador")   # Arma Atroz (verdadeiro)
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
		if furtivo_amea != "":
			dano += dados.rolar_expressao(furtivo_amea)   # ataque furtivo de ameaça (p.294)
		for m in maldicoes_arma:
			if not m.get("implementado", false):
				continue
			for ef in m.efeitos:
				if ef.tipo == "arma_dano_extra":
					dano += dados.rolar_expressao(ef.dados, mult if ef.get("multiplica", false) else 1)
		res.dano_bruto = maxi(1, dano)
		if alvo is Ameaca and (alvo as Ameaca).tem_hab("enxame"):
			res.dano_bruto = maxi(1, res.dano_bruto / 2)   # enxames sofrem metade do dano de armas
		res.dano = aplicar_dano(alvo, res.dano_bruto, arma.get("tipo_dano", ""), rd_extra, atacante, nao_letal)
		res.nao_letal = nao_letal
		if arma.has("dano_extra") and not alvo.tem(Ser.MORTO):   # "2d8+8 impacto mais 2d12 Morte": cada tipo com sua resistência
			res.dano += aplicar_dano(alvo, dados.rolar_expressao(String(arma.dano_extra.dados)), String(arma.dano_extra.tipo_dano), 0, atacante)
		if amea != null:
			for h in amea.habilidades:   # Aura Tangível, Sede de Sangue: dano a mais contra certas condições
				if h.has("contra_condicoes") and not alvo.tem(Ser.MORTO) and h.contra_condicoes.any(func(cond): return alvo.tem(cond)):
					res.dano += aplicar_dano(alvo, dados.rolar_expressao(String(h.dano)), String(h.tipo_dano), 0, atacante)
		_ao_acertar(atacante, alvo, arma, res)
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
	if res.acertou and amea != null and amea.tem_hab("julgamento") and String(arma.get("tipo_dano", "")) == "conhecimento" and res.dano > 0 and alvo.tem_sanidade:
		alvo.sofrer_dano_mental(res.dano / 2)   # Julgamento: metade também fere a mente
		if alvo.san <= 0 and not alvo.tem(Ser.MORTO):
			alvo._morrer()
			_log("[color=#eda64a]%s é julgado e deixa de existir.[/color]" % alvo.nome)
	if alvo is Ameaca and (alvo as Ameaca).tem_hab("aura_de_toque") and eh_corpo_a_corpo and not _usou_na_rodada(atacante, "toque_silhueta"):
		_marcar_uso_rodada(atacante, "toque_silhueta")   # tocar a silhueta apaga quem toca
		var aura := (alvo as Ameaca).habilidade("aura_de_toque")
		var d_aura := dados.rolar_expressao(String(aura.dano))
		if Teste.rolar(dados, atacante.dados_da_pericia(aura.resistencia), atacante.bonus_pericia(aura.resistencia), int(aura.dt)).sucesso:
			d_aura /= 2
		_log("%s toca a silhueta: %d de dano." % [atacante.nome, aplicar_dano(atacante, d_aura, String(aura.tipo_dano), 0, alvo)])
		if atacante.pv <= 0 and aura.get("desintegra", false) and not atacante.tem(Ser.MORTO):
			atacante._morrer()
			_log("[color=#e0574a]%s é desintegrado.[/color]" % atacante.nome)
	ataque_resolvido.emit(res)
	if alvo is Ameaca and (alvo as Ameaca).tem_hab("retaliacao") and atacante.lado != alvo.lado:
		_retaliar(alvo as Ameaca, atacante)
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
func aplicar_dano(alvo: Ser, dano: int, tipo_dano: String = "", rd_extra: int = 0, atacante: Ser = null, nao_letal: bool = false) -> int:
	if alvo.tem(Ser.POCA):
		return _danificar_poca(alvo as Ameaca, dano, tipo_dano)
	if alvo is Ameaca and (alvo as Ameaca).enigma_pendente() and (alvo as Ameaca).enigma.get("tipo", "") == "acumular_dano" and tipo_dano == (alvo as Ameaca).enigma.get("tipo_dano", ""):
		var en: Dictionary = (alvo as Ameaca).enigma
		en["acumulado"] = int(en.get("acumulado", 0)) + dano   # a força oposta se acumula mesmo sem ferir
		_log("O %s sente a %s (%d/%d)." % [alvo.nome, tipo_dano.capitalize(), int(en.acumulado), int(en.limite)])
		if int(en.acumulado) >= int(en.limite):
			_resolver_enigma(alvo as Ameaca, atacante)
	if alvo.mods_cena.has("divide_dano"):   # Ironia do Destino: a marionete divide a dor com quem agarra
		var vitima: Ser = alvo.mods_cena.divide_dano
		if vitima.tem(Ser.AGARRADO) and vitima.mods_cena.get("agarrado_por") == alvo and not vitima.tem(Ser.MORTO):
			var metade := dano / 2
			dano -= metade
			alvo.mods_cena.erase("divide_dano")
			aplicar_dano(vitima, metade, tipo_dano, 0, atacante)
			alvo.mods_cena["divide_dano"] = vitima
		else:
			alvo.mods_cena.erase("divide_dano")
	if tipo_dano == "mental":   # dano mental de ataques e habilidades vai para a Sanidade (p.82)
		var san_antes := alvo.san
		var pv_antes := alvo.pv
		alvo.sofrer_dano_mental(dano)
		return (san_antes - alvo.san) + (pv_antes - alvo.pv)
	var paranormal: bool = tipo_dano in TIPOS_PARANORMAIS
	if _reducoes_declaradas.has(alvo):
		var hab_id: String = _reducoes_declaradas[alvo]
		var ag := alvo as Agente
		var vale: bool = not paranormal or (hab_id == "duro_de_matar" and ag.nex >= 85)
		if vale and ag.gastar_pe(2):
			_reducoes_declaradas.erase(alvo)
			dano = dano / 2
	if tipo_dano in Ser.DANO_FISICO:
		if alvo.efeito_ritual("metade_fisico") > 0:
			dano = dano / 2   # Ódio Incontrolável (verdadeiro)
		if not _purgatorio_de(alvo).is_empty():
			dano *= 2         # Purgatório: inimigos na poça são vulneráveis a dano físico
	if alvo.vulneravel_a(tipo_dano):
		dano *= 2             # Vulnerabilidade (p.190)
	var final := maxi(0, dano - alvo.resistencia(tipo_dano) - rd_extra)
	if final <= 0:
		return 0
	var amea_alvo := alvo as Ameaca
	if amea_alvo != null and amea_alvo.tem_hab("teimoso") and not amea_alvo.usos.has("teimoso") and final >= 15:
		amea_alvo.usos["teimoso"] = 1   # Teimoso (chefe de polícia): uma vez por cena, metade
		final /= 2
		_log("%s, teimoso, aguenta o golpe." % alvo.nome)
	alvo.registrar_atacante(atacante)
	if atacante != null:
		_danificados_na_rodada[alvo] = atacante.lado
	if nao_letal:
		alvo.sofrer_dano_nao_letal(final)
		if alvo.tem(Ser.INCONSCIENTE):
			_log("%s desaba, desacordado." % alvo.nome)
		return final
	alvo.sofrer_dano(final)
	if atacante is Ameaca and (atacante as Ameaca).tem_hab("sadismo"):
		atacante.mods_cena["sadismo"] = true
	if amea_alvo != null:
		if tipo_dano == "fogo" and amea_alvo.tem_hab("lodo_protetor"):
			amea_alvo.mods_cena["queimada"] = true   # perde a imunidade até o próximo turno
		for h in amea_alvo.habilidades:
			var mu: Dictionary = h.get("murcha", {})
			if mu.has("dano") and tipo_dano in mu.dano and final >= int(mu.get("minimo", 1)):
				_murchar(amea_alvo, h)
		var cura := amea_alvo.habilidade("cura_acelerada")
		if not cura.is_empty() and tipo_dano in cura.get("desliga_com", []):
			amea_alvo.mods_cena["cura_desligada"] = true   # Regeneração de Sangue para até o fim da cena
		if tipo_dano == "energia" and amea_alvo.mods_cena.has("abracando"):
			var abracado: Ser = amea_alvo.mods_cena.abracando
			abracado.condicoes.erase(Ser.PARALISADO)
			amea_alvo.mods_cena.erase("abracando")
			_log("%s solta %s." % [amea_alvo.nome, abracado.nome])
		if amea_alvo.pv == 0 and not amea_alvo.transformacao.is_empty() and not amea_alvo.tem(Ser.MORTO):
			_transformar(amea_alvo)
	if amea_alvo != null and amea_alvo.tem_hab("faixas_da_permanencia") and amea_alvo.pv == 0 and not amea_alvo.tem(Ser.MORTO):
		amea_alvo.condicoes.erase(Ser.INCONSCIENTE)   # Faixas da Permanência: ainda age até o fim do próximo turno
		amea_alvo.condicoes.erase(Ser.MORRENDO)
		if not amea_alvo.mods_cena.has("permanencia"):
			amea_alvo.mods_cena["permanencia"] = "aguardando"
			_log("[color=#e0574a]%s cai a 0 PV... e continua de pé.[/color]" % amea_alvo.nome)
	if amea_alvo != null:
		if amea_alvo.tem_hab("ferocidade"):
			amea_alvo.mods_cena["ferocidade"] = true
		if amea_alvo.mods_cena.has("prendendo"):
			amea_alvo.mods_cena["dano_prendendo"] = int(amea_alvo.mods_cena.get("dano_prendendo", 0)) + final
			if int(amea_alvo.mods_cena.dano_prendendo) >= int(amea_alvo.mods_cena.get("solta_com_dano", 10)):
				_soltar_succao(amea_alvo)
		if amea_alvo.pv == 0 and amea_alvo.tem_hab("imortalidade") and not amea_alvo.tem(Ser.MORTO):
			_virar_poca(amea_alvo)
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
	var vulneravel: bool = alvo.tem(Ser.DESPREVENIDO) or alvo.tem(Ser.SURPREENDIDO) or alvo.esta_indefeso() or opcoes.get("flanqueando", false) or opcoes.get("fintado", false)
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
	_soltar_todos(ser)
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
		for ser in participantes:
			_libertar_hipnose(ser)
		for ef in _efeitos_ate_turno:
			_desfazer_efeito(ef)
		_efeitos_ate_turno.clear()
		for ser in participantes:
			ser.encerrar_cena()
		combate_encerrado.emit(vencedor)
		return true
	return false
