class_name Missao
extends RefCounted
## Estado e regras de uma missão no mapa-múndi (estilo For The King):
## cada agente joga seu turno (rola movimento em slots de d20, anda, resolve o que
## encontra); depois o mundo age (Membrana enfraquece, ameaças surgem).
## A cena do mapa só exibe e chama estes métodos; o combate acontece na arena.

signal registro(texto: String)
signal evento_aberto(hex: Vector2i, evento: Dictionary, agente: Agente)
signal encontro_iniciado(config: Dictionary)
signal investigacao_iniciada(config: Dictionary)
signal turno_mudou(agente: Agente)
signal missao_encerrada(vitoria: bool)
signal fala(agente: Agente, texto: String)   ## frases curtas no mapa (docs/75): só voz

var ruleset: Ruleset
var dados: Dados
var mapa: MapaHex
var membrana: Membrana
var agentes: Array[Agente] = []
var armas: Dictionary = {}       ## Agente -> arma (Dictionary)
var posicoes: Dictionary = {}    ## Agente -> Vector2i
var turno_mundo := 1
var indice := 0
var movimento_restante := 0
var movimento_rolado := false
var pode_escalar := false
## Covil selado (docs/42): só abre quando o grupo sabe onde ele fica ("onde" respondida ou um
## evento que o revele), ou à força, com a Membrana rompida.
var covil_localizado := false               ## Tirou 20 nos dados de movimento: sobe a serra neste turno (docs/34)
## Ação do turno no mapa (docs/13): usar um item ou conjurar um ritual que não seja de ataque.
var acao_usada := false
var ultimo_movimento: Dictionary = {}   ## {"slots": [...], "dt": int, "sucessos": int, "total": int}
var evento_pendente: Dictionary = {}    ## {"hex", "evento", "agente"}
var encontro_pendente: Dictionary = {}  ## config para a arena
var investigacao_pendente: Dictionary = {}  ## {"hex", "cena", "agentes"} para a cena de investigação
var caso: Caso
## Modificador de PV do chefe pelas investigações (+0.2 fortalecido, −0.2 enfraquecido)
var modificador_chefe := 0.0
var encerrada := false
var vitoria := false
## Opções da run (Carreira): modo_morte, lesoes, inspiracao_resoluta
var opcoes: Dictionary = {"modo_morte": "normal", "lesoes": true, "inspiracao_resoluta": true}
var semente := 0
var agentes_iniciais: Array[Agente] = []
var reforcos := 0                        ## Reforços da Ordem restantes (modo Normal)
var pistas := 0                          ## Eventos resolvidos com sucesso (pistas adicionais, p.63)
var mortos: Array[Agente] = []
var inocentes_mortos := 0               ## Civis que morreram na missão (p.53: −2 PP cada)
var resgatados: Array[Agente] = []

## Todas as linhas do registro (a cena do mapa é recriada após cada combate)
var historico: Array[String] = []
## Missão da comunidade (Fase 6): conteúdo próprio que vem antes dos dados do jogo.
## {"id", "titulo", "encontros": [], "eventos": [], "ameacas": {}, "covil": {}, "surgimentos": "padrao"}
var extras: Dictionary = {}

var _cfg: Dictionary
var _descansou: Dictionary = {}          ## Agente -> hex onde já fez interlúdio nesta visita
## Pontos de cenas já vistas que ficaram para trás: [{"cena", "pontos": [ids]}] (Revisar Caso, docs/48)
var revisaveis: Array = []
var _turnos_sem_surgimento := 0
## Medo no mapa (docs/53): por onde algo passou ({hex: turno do mundo}), os turnos de alívio
## depois de um combate e os passos da caçada no último turno do mundo (para a tela animar).
var rastros: Dictionary = {}
## O caçador da Perseguição (docs/74): {"lista", "estagio", "encontro", "derrotas", "volta_em",
## "banido"}; {} sem ele. No mapa, é o encontro com "cacador": true.
var cacador: Dictionary = {}
var alivio := 0
var passos_da_caca: Array = []   ## [{"de": Vector2i, "para": Vector2i}]
var _covil_selado_avisado := -1
## Testemunhas que falaram com o grupo (docs/56): [{nome, papel, cena, sumiu}]. Numa noite, uma
## delas pode sumir: o terror indireto do livro (p.163).
var testemunhas_vistas: Array = []
## Contato da Pesquisa (docs/61, IN5): a camada já usada em cada pergunta (pergunta -> 1..3).
var pesquisa: Dictionary = {}
## Mapa de rumores (docs/61, IN5): os hexes onde o grupo achou pista firme ([x, y]).
var rumores: Array = []
## A rotina da Ordem (docs/62): o sinal que trouxe o grupo (OR1) e, se ele era alarme falso,
## quando isso se confirmou; e como o covil foi varrido (OR5: "limpa", "equipe" ou "rastro").
var sinal: Dictionary = {}
var alarme_falso := false
var alarme_confirmado := false
var varredura := ""
## Credencial de fachada (docs/63, OR4): {nome, usos, queimada}; nome inventado por missão.
var credencial: Dictionary = {}
## Cultistas rendidos que vão para a contenção da Base (docs/63, OR8): [{nome, papel, elemento}].
var presos: Array = []
## Rituais de mapa (docs/69): os de uso único já gastos na missão, e o bônus guardado para o
## próximo teste de um agente num evento (Enfeitiçar, Distorcer Aparência).
var rituais_usados_no_mapa: Array = []
var bonus_de_ritual: Dictionary = {}   ## id do agente -> {"pericia": String, "valor": int}
var escuta_instalada := false          ## docs/72: a escuta grava até o fim da missão (+5 para identificar)


const NOMES_TERRENO := {"campo": "campos abertos", "estrada": "estradas de terra", "floresta": "mata fechada",
	"pantano": "brejo", "morro": "morros", "cidade": "cidade", "ruina": "ruínas", "agua": "água parada"}

## O que a Ordem sabe antes de mandar o grupo (docs/23, C7), sem estragar o caso: a região do
## mapa que esta semente vai gerar (terrenos que mais aparecem, vilas, cidades, locais a
## investigar e eventos relatados) e os sinais do caso. Quem, o quê e onde ficam para o jogo.
static func previa(semente_: int) -> Dictionary:
	var mapa_ := GeradorMapa.gerar(semente_)
	var terrenos := {}
	var tipos := {}
	for h in mapa_.celulas:
		var t := mapa_.terreno(h)
		terrenos[t] = int(terrenos.get(t, 0)) + 1
		var tipo := String(mapa_.conteudo(h).get("tipo", ""))
		if tipo != "":
			tipos[tipo] = int(tipos.get(tipo, 0)) + 1
	var ordem: Array = terrenos.keys()
	ordem.sort_custom(func(a, b): return int(terrenos[a]) > int(terrenos[b]))
	var principais: Array = ordem.slice(0, 2).map(func(t): return String(NOMES_TERRENO.get(t, t)))
	var casos := DadosJogo.ler("casos")
	var caso_ := Caso.gerar(Dados.new(semente_))   # o mesmo caso da missão: o resumo já com os sintomas
	return {"numero": semente_ % 10000, "terrenos": principais, "cidades": int(terrenos.get("cidade", 0)),
		"vilas": int(tipos.get("vila", 0)), "investigacoes": int(tipos.get("investigacao", 0)),
		"eventos": int(tipos.get("evento", 0)), "celulas": mapa_.celulas.size(),
		"sinais": caso_.resumo, "objetivo": String(casos.objetivo)}


## Nova missão. `grupo`: agentes da carreira (vazio = grupo padrão de demonstração).
static func nova(semente_: int, ruleset_: Ruleset = null, grupo: Array = [], opcoes_: Dictionary = {}) -> Missao:
	var m := Missao.new()
	m.ruleset = ruleset_ if ruleset_ != null else RulesetOp2022.carregar_padrao()
	m.semente = semente_
	m.dados = Dados.new(semente_)
	m._cfg = DadosJogo.ler("mapa")
	m.mapa = GeradorMapa.gerar(semente_)
	m.membrana = Membrana.carregar_padrao()
	for k in opcoes_:
		if k != "sinal":
			m.opcoes[k] = opcoes_[k]
	m.sinal = (opcoes_.get("sinal", {}) as Dictionary).duplicate()
	m.alarme_falso = bool(m.sinal.get("alarme_falso", false))
	m.reforcos = 2 if m.opcoes.get("modo_morte", "normal") == "normal" else 0
	var cfg_cred: Dictionary = DadosJogo.ler("sinais").credencial
	m.credencial = {"nome": "Agente %s" % String(cfg_cred.sobrenomes[absi(hash("%d|credencial" % semente_)) % cfg_cred.sobrenomes.size()]),
		"usos": 0, "queimada": false}
	m.caso = Caso.gerar(m.dados)
	m._ajustar_encontros_ao_elemento()
	if m.alarme_falso:
		m._tirar_o_paranormal()
	m._aplicar_culto_e_subgenero(false)
	m.credencial["limite"] = int(DadosJogo.ler("sinais").credencial.limite)
	m.covil_localizado = not bool(DadosJogo.ler("mapa").get("covil_selado", true))
	var inicio := m.mapa.encontrar("inicio")
	if grupo.is_empty():
		for ficha in DadosJogo.ler("grupo_inicial").agentes:
			var r := CriacaoAgente.criar(m.ruleset, ficha)
			assert(r.agente != null, "Ficha inicial inválida: %s" % [r.erros])
			var novo: Agente = r.agente
			for item in ficha.get("equipamento", [ficha.arma]):
				novo.equipamento.append(item)
			novo.arma_id = ficha.arma
			grupo.append(novo)
	for a in grupo:
		if a.id == "":   # grupo de demonstração: ids para os comandos que apontam agentes (docs/48)
			a.id = "demo%d" % m.agentes.size()
		m.agentes.append(a)
		m.agentes_iniciais.append(a)
		m.armas[a] = a.arma()
		m.posicoes[a] = inicio
		a.semente_insanidade = semente_
		m._vincular(a)
	m._iniciar_turno_do_agente()
	return m


func _log(texto: String) -> void:
	historico.append(texto)
	registro.emit(texto)


func _vincular(a: Agente) -> void:
	if not a.ganhou_insanidade.is_connected(_ao_ganhar_insanidade):
		a.ganhou_insanidade.connect(_ao_ganhar_insanidade)


func _ao_ganhar_insanidade(a: Agente, efeito: Dictionary) -> void:
	_log(a.linha_insanidade(efeito))


# --- Turno dos agentes -----------------------------------------------------

func agente_atual() -> Agente:
	if encerrada or agentes.is_empty():
		return null
	return agentes[indice]


func posicao(a: Agente) -> Vector2i:
	return posicoes.get(a, Vector2i(-999, -999))


func agentes_em(h: Vector2i) -> Array[Agente]:
	var lista: Array[Agente] = []
	for a in agentes:
		if posicoes.get(a) == h and not a.tem(Ser.MORTO):
			lista.append(a)
	return lista


func ocupado() -> bool:
	return not evento_pendente.is_empty() or not encontro_pendente.is_empty() or not investigacao_pendente.is_empty() or encerrada


## Rola o movimento do agente da vez: 1 d20 por ponto de Agilidade (mínimo 1) + 1 por PE de Foco.
## Cada slot >= DT vale 1 ponto, somado à base (mapa.json). Uma vez por turno.
func rolar_movimento(pe_foco: int = 0) -> Dictionary:
	var a := agente_atual()
	if a == null or movimento_rolado or ocupado():
		return {}
	if pe_foco > 0 and not a.gastar_pe(pe_foco):
		return {}
	var regra: Dictionary = _cfg.movimento
	var qtd := maxi(1, a.atributo(regra.atributo)) + int(regra.get("slots_extras", 0)) + pe_foco
	var dt := int(regra.dt_slot)
	var slots := dados.rolar_varios(qtd, 20)
	var sucessos := slots.filter(func(v): return v >= dt).size()
	movimento_restante = int(regra.base) + sucessos
	movimento_rolado = true
	# Escalada (docs/34): um 20 em algum dado de Agilidade do movimento deixa subir a serra
	pode_escalar = slots.has(20)
	ultimo_movimento = {"slots": slots, "dt": dt, "sucessos": sucessos, "total": movimento_restante, "agente": a.nome,
		"escalada": pode_escalar}
	ultimo_movimento["atributo"] = String(regra.atributo)
	_log("%s rola movimento: %s (DT %d) → %d de movimento" % [a.nome, str(slots), dt, movimento_restante])
	if pode_escalar:
		_log("[color=#e3c27a]Um 20! %s acha apoio na rocha: neste turno dá para escalar a serra.[/color]" % a.nome)
	return ultimo_movimento


## Custos dos hexes ao alcance do movimento restante.
func destinos() -> Dictionary:
	var a := agente_atual()
	if a == null or not movimento_rolado or ocupado():
		return {}
	var custos := mapa.alcancaveis(posicao(a), movimento_restante, true, pode_escalar)
	custos.erase(posicao(a))
	return custos


## Anda até `destino` pelo caminho mais barato. Para ao entrar num hex com conteúdo.
func mover(destino: Vector2i) -> bool:
	var a := agente_atual()
	if a == null or not destinos().has(destino):
		return false
	var passos := mapa.caminho(posicao(a), destino, true, pode_escalar)
	if passos.is_empty() or mapa.custo_do_caminho(passos, pode_escalar) > movimento_restante:
		return false
	_descansou.erase(a)
	for h in passos:
		movimento_restante -= mapa.custo(h, pode_escalar)
		posicoes[a] = h
		# Do alto da serra se vê longe (docs/34)
		var visao := int(_cfg.visao) + (int(_cfg.get("visao_da_serra", 2)) if mapa.escalavel(h) else 0)
		if eh_noite():
			visao = maxi(1, visao - 1)   # à noite se vê menos (docs/53)
		mapa.revelar(h, visao)
		if mapa.escalavel(h):
			_log("%s chega ao alto da serra e enxerga longe." % a.nome)
		if not mapa.conteudo(h).is_empty():
			_entrar(a, h)
			break
	return true


func _entrar(a: Agente, h: Vector2i) -> void:
	var c := mapa.conteudo(h)
	if alarme_falso and not alarme_confirmado and String(c.get("tipo", "")) in ["evento", "investigacao"]:
		# Alarme falso (docs/62): o primeiro lugar com pista mostra o que era de verdade
		var ev := _evento("alarme_falso")
		evento_pendente = {"hex": h, "evento": ev, "agente": a}
		_log("[b]%s[/b]: %s" % [ev.titulo, ev.texto])
		evento_aberto.emit(h, ev, a)
		return
	match c.get("tipo", ""):
		"encontro":
			_contra_o_cacador = c.get("cacador", false)
			_preparar_encontro(h, c.encontro, false)
		"objetivo":
			if not covil_aberto():
				mapa.revelar(h, 0)
				if _covil_selado_avisado != turno_mundo:   # uma vez por turno, não a cada passo (docs/51)
					_covil_selado_avisado = turno_mundo
					_log("[color=#c9a0ff]%s chega às ruínas do covil, mas não acha a entrada. Sem saber [b]onde[/b] procurar, é só pedra fria. (Mande o relatório à Ordem com quem, o quê e onde.)[/color]" % a.nome)
				return
			_preparar_encontro(h, c.encontro, true)
		"evento":
			var ev := _evento(c.evento)
			evento_pendente = {"hex": h, "evento": ev, "agente": a}
			_log("[b]%s[/b]: %s" % [ev.titulo, ev.texto])
			evento_aberto.emit(h, ev, a)
		"investigacao":
			_preparar_investigacao(h, c.cena)
		"vila", "inicio":
			_log("%s chega a %s. Dá para descansar aqui." % [a.nome, c.get("nome", "uma cidade")])
		"mirante":
			_achar_no_alto(a, h, String(c.get("achado", "")))


func pode_descansar() -> bool:
	var a := agente_atual()
	if a == null or ocupado():
		return false
	var tipo: String = mapa.conteudo(posicao(a)).get("tipo", "")
	return tipo in ["vila", "inicio"] and not _descansou.has(a)


## Descanso rápido (piloto e saves antigos): um interlúdio só do agente da vez, dormindo e
## relaxando.
func descansar() -> bool:
	if not pode_descansar():
		return false
	return interludio({agente_atual().id: {"acoes": ["dormir", "relaxar"]}}).get("ok", false)


# --- Interlúdio (p.92-93, docs/48) ------------------------------------------------------

const ACOES_INTERLUDIO := ["dormir", "relaxar", "alimentar", "exercitar", "ler", "revisar"]


## Quem participa: os agentes no hex do agente da vez que ainda não fizeram interlúdio aqui.
func participantes_interludio() -> Array[Agente]:
	var lista: Array[Agente] = []
	if not pode_descansar():
		return lista
	var h := posicao(agente_atual())
	for a in agentes:
		if posicao(a) == h and not a.esta_fora_de_combate() and not _descansou.has(a):
			lista.append(a)
	return lista


## Condição do descanso no lugar (precária, normal, confortável, luxuosa).
func condicao_interludio() -> String:
	var tipo: String = mapa.conteudo(posicao(agente_atual())).get("tipo", "") if agente_atual() != null else ""
	return String(_cfg.interludio.condicao_por_lugar.get(tipo, "normal"))


## Pontos que dá para revisar: ["cena:ponto"].
func pontos_revisaveis() -> Array:
	var lista: Array = []
	for r in revisaveis:
		for p in r.pontos:
			lista.append("%s:%s" % [r.cena, p])
	return lista


## O interlúdio do grupo. `escolhas`: {agente_id: {"acoes": [...até 2], "prato": id, "revisar": "cena:ponto"}}.
## Devolve {ok, linhas}. Encerra o movimento do agente da vez; cada participante só uma vez por visita.
func interludio(escolhas: Dictionary) -> Dictionary:
	var participantes := participantes_interludio()
	if participantes.is_empty():
		return {"ok": false, "erro": "não há interlúdio aqui agora"}
	var cfg: Dictionary = _cfg.interludio
	var cond := condicao_interludio()
	var linhas: Array[String] = []
	var relaxam := 0
	for a in participantes:
		var e: Dictionary = escolhas.get(a.id, {})
		if "relaxar" in e.get("acoes", []):
			relaxam += 1
	for a in participantes:
		var e: Dictionary = escolhas.get(a.id, {})
		var acoes: Array = (e.get("acoes", []) as Array).filter(func(x): return x in ACOES_INTERLUDIO).slice(0, int(cfg.acoes_por_agente))
		if acoes.is_empty():
			continue
		var prato := String(e.get("prato", "")) if "alimentar" in acoes else ""
		var lim := ruleset.limite_pe(a.nex)
		var feito: Array[String] = []
		if prato != "":
			feito.append(String(cfg.pratos.get(prato, {}).get("nome", prato)).to_lower())
		if "dormir" in acoes:
			var mult_pv := float(cfg.multiplicador[cfg.passo_seguinte[cond] if prato == "nutritivo" else cond])
			var mult_pe := float(cfg.multiplicador[cfg.passo_seguinte[cond] if prato == "energetico" else cond])
			var pv := maxi(1, int(lim * mult_pv))
			var pe := maxi(1, int(lim * mult_pe))
			a.curar(pv)
			a.recuperar_pe(pe)
			feito.append("dorme (+%d PV, +%d PE)" % [pv, pe])
		if "relaxar" in acoes:
			var san := maxi(1, int(lim * float(cfg.multiplicador[cond]))) + relaxam + (2 if prato == "favorito" else 0)
			a.recuperar_sanidade(san)
			feito.append("relaxa (+%d SAN)" % san)
		if "exercitar" in acoes:
			a.bonus_exercicio = mini(a.bonus_exercicio + 1, maxi(1, a.atributo("vig")))
			feito.append("se exercita (+1d6 guardado em AGI/FOR/VIG)")
		if "ler" in acoes:
			a.bonus_leitura = mini(a.bonus_leitura + 1, maxi(1, a.atributo("int")))
			feito.append("lê (+1d6 guardado em INT/PRE)")
		if "revisar" in acoes:
			feito.append(_revisar_caso(a, String(e.get("revisar", "")), prato == "rapido"))
		_descansou[a] = posicao(a)
		linhas.append("%s: %s." % [a.nome, ", ".join(PackedStringArray(feito))])
	if linhas.is_empty():
		return {"ok": false, "erro": "ninguém escolheu ações"}
	movimento_restante = 0
	movimento_rolado = true
	_log("[color=#7fd3c7][b]Interlúdio[/b] (descanso %s).[/color]" % cond)
	for l in linhas:
		_log(l)
	return {"ok": true, "linhas": linhas}


## Revisar Caso (p.93): volta às anotações de um ponto que ficou para trás; teste com a melhor
## perícia do ponto contra a DT dele. Passando, a pista entra no caso. Devolve o texto.
func _revisar_caso(a: Agente, alvo: String, prato_rapido: bool) -> String:
	var partes := alvo.split(":")
	if partes.size() != 2:
		return "revisa o caso, sem saber por onde começar"
	var r_idx := -1
	for i in revisaveis.size():
		if revisaveis[i].cena == partes[0] and partes[1] in revisaveis[i].pontos:
			r_idx = i
	if r_idx < 0:
		return "revisa o caso, sem achar nada novo"
	var cena := cena_info(partes[0])
	var ponto: Dictionary = {}
	for p in cena.get("pontos", []):
		if p.id == partes[1]:
			ponto = p
	if ponto.is_empty():
		return "revisa o caso, sem achar nada novo"
	var melhor := ""
	var nota := -1000
	for per in ponto.pericias:
		var v: int = a.dados_da_pericia(per) * 5 + a.bonus_pericia(per) - int(ponto.pericias[per])
		if v > nota:
			nota = v
			melhor = per
	var dt := int(ponto.pericias[melhor])
	var t := a.testar(dados, melhor, dt)
	if t != null and prato_rapido:
		t.somar_bonus(5)   # prato rápido (p.93)
	if t == null or not t.sucesso:
		return "revisa %s (%s), mas não vê nada novo" % [ponto.nome, ruleset.pericia(melhor).nome]
	revisaveis[r_idx].pontos.erase(partes[1])
	if (revisaveis[r_idx].pontos as Array).is_empty():
		revisaveis.remove_at(r_idx)
	var incerta: bool = ponto.get("depoimento", false) and t.total - dt < CenaInvestigacao.MARGEM_DEPOIMENTO_FIRME
	var pista := caso.registrar_pista(String(ponto.pista), String(ponto.responde), partes[0], incerta,
		absi(hash("%s|%s|%d" % [alvo, a.id, turno_mundo])))
	pistas += 1
	_anotar_rumor(posicao(a))
	return "revisa %s e acha uma pista que tinha passado: %s" % [ponto.nome, pista.texto]


func encerrar_turno() -> void:
	if ocupado():
		return
	for _i in agentes.size():
		indice += 1
		if indice >= agentes.size():
			indice = 0
			_turno_do_mundo()
		if not agentes[indice].esta_fora_de_combate():
			break
	_iniciar_turno_do_agente()


func _iniciar_turno_do_agente() -> void:
	movimento_restante = 0
	movimento_rolado = false
	pode_escalar = false
	acao_usada = false
	ultimo_movimento = {}
	var a := agente_atual()
	if a != null:
		a.nova_cena_de_insanidade()
		a.iniciar_turno()   # zera o PE do turno e conta "enlouquecendo" também no mapa
		turno_mudou.emit(a)
		_falas_no_mapa(a)


# --- Frases curtas no mapa (docs/75, AG6) --------------------------------------------------

var _falas_ditas: Dictionary = {}   ## "nome|estado" -> true: já falou, até o estado passar
var _falas := 0


## No começo da vez, o agente perturbado ou ferido diz uma linha. Uma vez por estado: a fala volta
## só depois que o estado passa (descansou, curou) e volta de novo.
func _falas_no_mapa(a: Agente) -> void:
	var estado := Falas.estado_de(a)
	for e in ["perturbado", "ferido"]:
		if e != estado:
			_falas_ditas.erase("%s|%s" % [a.nome, e])
	var chave := "%s|%s" % [a.nome, estado]
	if estado == "" or _falas_ditas.has(chave):
		return
	_falas_ditas[chave] = true
	var texto := Falas.de(a, estado, _falas)
	if texto == "":
		return
	_falas += 1
	_log("[i][color=#d9c9a3]%s: \"%s\"[/color][/i]" % [a.nome, texto])
	fala.emit(a, texto)


# --- Eventos ---------------------------------------------------------------

func _evento(evento_id: String) -> Dictionary:
	for e in extras.get("eventos", []):
		if e.id == evento_id:
			return e
	var d := DadosJogo.ler("eventos")
	for e in d.eventos + d.get("eventos_medo", []) + d.get("eventos_da_ordem", []):
		if e.id == evento_id:
			if evento_id == "alarme_falso":   # a explicação mundana do sinal (docs/62)
				var copia: Dictionary = e.duplicate(true)
				copia.texto = String(e.texto).replace("{explicacao}", String(sinal.get("explicacao", "Era outra coisa.")))
				return copia
			return e
	return {}


## Opções do evento (docs/13): cada uma é um teste de perícia diferente, ou "sem_teste".
## Eventos antigos (só "pericia" e "dt") viram uma opção única. Opções com "treinada"
## só aparecem para quem é treinado na perícia; com "habilidade", para quem a tem.
func opcoes_do_evento(ev: Dictionary = {}, a: Agente = null) -> Array:
	if ev.is_empty() and not evento_pendente.is_empty():
		ev = evento_pendente.evento
		a = evento_pendente.agente
	var lista: Array = ev.get("opcoes", [])
	if lista.is_empty():
		lista = [{"texto": "", "pericia": ev.get("pericia", ""), "dt": ev.get("dt", 10), "sucesso": ev.get("sucesso", {}), "falha": ev.get("falha", {})}]
	return lista.filter(func(o):
		if a == null:
			return true
		if o.get("treinada", false) and not a.pericias.has(String(o.get("pericia", ""))):
			return false
		if o.has("habilidade") and not a.tem_habilidade(String(o.habilidade)):
			return false
		return true)


## O agente que entrou no hex escolhe uma opção e faz o teste. Retorna {teste, sucesso, texto}.
## `trocar`: a perícia que substitui a do teste, pagando 2 PE (Impostor: Enganação; Motor de
## Busca: Tecnologia; p.30-31).
func resolver_evento(pe_foco: int = 0, opcao: int = 0, trocar: String = "") -> Dictionary:
	if evento_pendente.is_empty():
		return {}
	var a: Agente = evento_pendente.agente
	var opcoes := opcoes_do_evento()
	var o: Dictionary = opcoes[clampi(opcao, 0, opcoes.size() - 1)]
	var teste: ResultadoTeste = null
	var sucesso := true
	var linha := ""
	if o.get("sem_teste", false):
		linha = "%s: %s" % [a.nome, String(o.get("texto", "segue em frente"))]
	else:
		var per := String(o.pericia)
		if trocar != "" and trocar in trocas_de_pericia(a) and a.gastar_pe(2):
			_log("%s troca %s por %s (%s)." % [a.nome, ruleset.pericia(per).nome, ruleset.pericia(trocar).nome, trocas_de_pericia(a)[trocar]])
			per = trocar
			o = o.duplicate()
			o.pericia = per
		var ajuda := _ajudar_no_evento(a, per)
		var b_rit: Dictionary = bonus_de_ritual.get(a.id, {})
		if not b_rit.is_empty() and String(b_rit.pericia) == String(o.pericia):
			ajuda += int(b_rit.valor)   # Enfeitiçar, Distorcer Aparência (docs/69)
			bonus_de_ritual.erase(a.id)
		var dos_poderes := _poderes_no_evento(a, per)
		ajuda += int(dos_poderes.bonus)
		var op_teste := {"bonus_extra": ajuda} if ajuda > 0 else {}
		if int(dos_poderes.dados) > 0:
			op_teste["dados_extras"] = int(dos_poderes.dados)
		teste = a.testar(dados, per, int(o.dt), pe_foco, op_teste)
		sucesso = teste != null and teste.sucesso
		linha = "%s testa %s (DT %d): %s" % [a.nome, ruleset.pericia(o.pericia).nome, int(o.dt),
			teste.descrever() if teste != null else "sem treino — falha automática"]
	var lado: Dictionary = o.get("sucesso", {}) if sucesso else o.get("falha", {})
	if sucesso and not o.get("sem_teste", false):
		pistas += 1
	_log(linha)
	if String(lado.get("texto", "")) != "":
		_log(lado.texto)
	var aplicados: Array = []
	for ef in lado.get("efeitos", []):
		var feito := _aplicar_efeito(a, ef, evento_pendente.hex)
		if not feito.is_empty():
			aplicados.append(feito)
	var titulo := String(evento_pendente.evento.get("titulo", ""))
	mapa.limpar_conteudo(evento_pendente.hex)
	evento_pendente = {}
	_verificar_derrota()
	return {"teste": teste, "sucesso": sucesso, "texto": lado.get("texto", ""), "efeitos": aplicados,
		"titulo": titulo, "agente": a.nome, "sem_teste": o.get("sem_teste", false)}


## As perícias que o agente pode pôr no lugar da do evento, pagando 2 PE: {pericia: poder}.
func trocas_de_pericia(a: Agente) -> Dictionary:
	var t := {}
	if a.pe + a.pe_temporario < 2:
		return t
	if a.tem_habilidade("impostor"):
		t["enganacao"] = "Impostor"
	if a.tem_habilidade("motor_de_busca"):
		t["tecnologia"] = "Motor de Busca"
	return t


## Poderes que valem nos testes de evento (cada evento é uma cena): Primeira Impressão (+2
## dados no teste social), Envolto em Mistério (+5 em Enganação e Intimidação contra leigos) e
## Hacker (+5 em Tecnologia).
func _poderes_no_evento(a: Agente, pericia: String) -> Dictionary:
	var r := {"bonus": 0, "dados": 0}
	if a.tem_habilidade("primeira_impressao") and pericia in ["diplomacia", "enganacao", "intimidacao", "intuicao"]:
		r.dados += 2
	if a.tem_habilidade("envolto_em_misterio") and pericia in ["enganacao", "intimidacao"]:
		r.bonus += 5
	if a.tem_habilidade("hacker") and pericia == "tecnologia":
		r.bonus += 5
	return r


## Quem está no hex do evento e pode ajudar o teste (docs/59): vivo, de pé e sem Teimoso.
func ajudantes_do_evento() -> Array:
	if evento_pendente.is_empty():
		return []
	var a: Agente = evento_pendente.agente
	if not a.efeitos("sem_ajuda").is_empty():
		return []
	return agentes.filter(func(x): return x != a and posicao(x) == evento_pendente.hex and not x.tem(Ser.MORTO) \
		and not x.esta_fora_de_combate() and x.efeitos("sem_ajuda").is_empty())


## Ajuda (p.86, a regra de ajuda do livro): cada um no hex testa a mesma perícia contra DT 10;
## quem passa dá +1, e mais +1 a cada 10 acima da DT. Quem não pode usar a perícia não ajuda.
func _ajudar_no_evento(a: Agente, pericia: String) -> int:
	var cfg: Dictionary = ruleset.dados.get("investigacao", {}).get("ajuda", {"dt": 10, "bonus": 1, "bonus_por_10_acima": 1})
	var total := 0
	for h in ajudantes_do_evento():
		var t: ResultadoTeste = h.testar(dados, pericia, int(cfg.dt))
		if t == null:
			continue
		var b := 0
		if t.sucesso:
			b = int(cfg.bonus) + maxi(0, (t.total - int(cfg.dt)) / 10) * int(cfg.bonus_por_10_acima)
		total += b
		_log("%s ajuda %s (%s): %s%s" % [h.nome, a.nome, ruleset.pericia(pericia).nome, t.descrever(), "  → +%d" % b if b > 0 else ""])
	return total


# --- Ação do turno no mapa (docs/13) ------------------------------------------------

## Agentes que o agente da vez alcança fora de combate: ele mesmo e quem está no mesmo hex.
func alcance_de_toque() -> Array:
	var a := agente_atual()
	if a == null:
		return []
	return agentes.filter(func(x): return posicao(x) == posicao(a) and not x.tem(Ser.MORTO))


## Itens que dá para usar fora de combate (consumíveis com "uso" de cura).
func itens_fora_de_combate(a: Agente) -> Array:
	var vistos := {}
	var lista: Array = []
	for item_id in a.equipamento:
		var info := ruleset.equipamento(item_id)
		if vistos.has(item_id) or not info.has("uso") or String(info.uso.get("cura", "")) == "":
			continue
		vistos[item_id] = true
		lista.append(item_id)
	return lista


## Rituais que dá para conjurar fora de combate: só os de cura e PV temporários,
## sem área e com alvo em você ou por toque. Devolve [[ritual_id, forma], …].
func rituais_fora_de_combate(a: Agente) -> Array:
	var lista: Array = []
	for rid in a.rituais:
		if _ritual_de_mapa_disponivel(a, rid):
			lista.append([rid, ""])
	for rid in a.rituais:
		var r := ruleset.ritual(rid)
		if not r.get("implementado", false):
			continue
		for forma in [""] + r.get("formas", {}).keys():
			if _efeito_fora(r, forma).is_empty():
				continue
			if forma != "":
				var f: Dictionary = r.formas[forma]
				if int(f.get("circulo", 1)) > a.circulo_maximo() or (f.get("afinidade", false) and a.afinidade != r.elemento):
					continue
			lista.append([rid, forma])
	return lista


func _efeito_fora(r: Dictionary, forma: String) -> Dictionary:
	var efeitos: Array = r.get("efeitos", [])
	if efeitos.size() != 1:
		return {}
	var ef: Dictionary = efeitos[0].duplicate()
	if forma != "":
		var f: Dictionary = r.formas[forma]
		if f.has("area") or f.has("tipo"):
			return {}
		if f.has("dados"):
			ef["dados"] = f.dados
	if not String(ef.get("tipo", "")) in ["cura", "pv_temporario"]:
		return {}
	return ef


## Itens paranormais de mapa (docs/72): medidor, scanner, escuta e emissor.
func itens_de_mapa(a: Agente) -> Array:
	var lista: Array = []
	for item_id in a.equipamento:
		if not item_id in lista and ruleset.equipamento(item_id).has("uso_mapa"):
			lista.append(item_id)
	return lista


## Por que o item de mapa não pode ser usado agora ("" = pode).
func motivo_item_de_mapa(a: Agente, item_id: String) -> String:
	var u: Dictionary = ruleset.equipamento(item_id).get("uso_mapa", {})
	if u.is_empty() or not a.tem_item(item_id):
		return "Sem esse item."
	if not pode_agir_no_mapa() or a != agente_atual():
		return "A ação deste turno já foi usada."
	if String(u.get("treinado", "")) != "" and not a.treinado_em(String(u.treinado)):
		return "Pede %s treinado." % ruleset.pericia(String(u.treinado)).nome
	if int(u.get("pe", 0)) > a.pe + a.pe_temporario:
		return "PE insuficientes."
	if String(u.tipo) == "escuta" and escuta_instalada:
		return "A escuta já está gravando."
	return ""


## Usa um item paranormal no mapa. `opcao`: o elemento do pulso do emissor.
func usar_item_de_mapa(item_id: String, opcao: String = "") -> Dictionary:
	var a := agente_atual()
	if a == null or motivo_item_de_mapa(a, item_id) != "":
		return {}
	var info := ruleset.equipamento(item_id)
	var u: Dictionary = info.uso_mapa
	if String(u.tipo) == "emissor" and not opcao in ["sangue", "morte", "conhecimento", "energia", "medo"]:
		return {}
	if int(u.get("pe", 0)) > 0:
		a.gastar_pe(int(u.pe))
	acao_usada = true
	var texto := ""
	match String(u.tipo):
		"medidor":
			texto = _ler_membrana(a, int(u.get("raio", 4)))
		"scanner":
			texto = _escanear(a, String(info.get("elemento", "")), int(u.get("raio", 8)))
		"escuta":
			escuta_instalada = true
			texto = "%s instala a escuta. Até o fim da missão, o que ela grava ajuda a identificar as criaturas (+5 em Ocultismo)." % a.nome
		"emissor":
			texto = _emitir_pulso(a, opcao, int(u.get("raio", 6)), int(u.get("passos", 2)))
	_log("[color=#7fd3c7]%s[/color]" % texto)
	return {"ok": true, "texto": texto, "item": item_id}


## Encontros com criatura a até `raio` hexes: [hex].
func _criaturas_perto(h: Vector2i, raio: int, elemento: String = "") -> Array:
	var lista: Array = []
	for c in mapa.celulas:
		var cont := mapa.conteudo(c)
		if Hex.distancia(c, h) > raio or String(cont.get("tipo", "")) != "encontro":
			continue
		var el := elemento_de(String(cont.get("encontro", "")))
		if el != "" and (elemento == "" or el == elemento):
			lista.append(c)
	lista.sort()
	return lista


## Medidor de estabilidade da Membrana (p.77).
func _ler_membrana(a: Agente, raio: int) -> String:
	var achados := _criaturas_perto(posicao(a), raio)
	for c in achados:
		mapa.revelar(c, 0)
	var falta := maxi(1, int(_cfg.get("mundo", {}).get("surgimento_a_cada_turnos", 2)) - _turnos_sem_surgimento)
	var proxima := "Com a Membrana %s, algo novo pode surgir em %d turno%s." % [String(membrana.estado().get("nome", "")).to_lower(), falta, "" if falta == 1 else "s"] \
		if membrana.nivel_ameaca() >= 1 else "A Membrana está firme: nada novo deve surgir por enquanto."
	return "%s lê o medidor: %d leitura%s fora do normal por perto. %s" % [a.nome, achados.size(), "" if achados.size() == 1 else "s", proxima]


## Scanner de manifestação (p.77): o que é do elemento, e o covil se o caso for dele.
func _escanear(a: Agente, elemento: String, raio: int) -> String:
	var achados := _criaturas_perto(posicao(a), raio, elemento)
	var nome_el := String(DadosJogo.ler("casos").get("elementos", {}).get(elemento, {}).get("nome", elemento.capitalize()))
	var partes := PackedStringArray()
	for c in achados:
		mapa.revelar(c, 0)
		partes.append(direcao_em_texto(Hex.para_pixel(c, 1.0) - Hex.para_pixel(posicao(a), 1.0)))
	var texto := "%s liga o scanner de %s: %s." % [a.nome, nome_el, ("sinais " + ", ".join(partes)) if not partes.is_empty() else "nenhum sinal por perto"]
	var obj := mapa.encontrar("objetivo")
	if caso != null and caso.elemento == elemento and mapa.tem(obj) and Hex.distancia(obj, posicao(a)) <= raio:
		mapa.revelar(obj, 0)
		texto += " O ponteiro treme e aponta, forte, %s: é ali o covil." % direcao_em_texto(Hex.para_pixel(obj, 1.0) - Hex.para_pixel(posicao(a), 1.0))
	return texto


## Emissor de pulsos paranormais (p.77): puxa as criaturas do elemento e afasta as do elemento
## que ele oprime, até `passos` hexes. Não entra no hex do agente nem em lugares com conteúdo.
func _emitir_pulso(a: Agente, elemento: String, raio: int, passos: int) -> String:
	var aqui := posicao(a)
	var oprimido := String(ruleset.dados.get("rituais", {}).get("vantagem_elemental", {}).get(elemento, ""))
	var puxados := 0
	var afastados := 0
	for c in _criaturas_perto(aqui, raio):
		var el := elemento_de(String(mapa.conteudo(c).get("encontro", "")))
		var dir := 1 if el == elemento else (-1 if el == oprimido and oprimido != "" else 0)
		if dir == 0:
			continue
		var h: Vector2i = c
		for _i in passos:
			var prox := _passo_para(h, aqui) if dir > 0 else _passo_para_longe(h, aqui)
			if prox == h or prox == aqui:
				break
			var cont := mapa.conteudo(h)
			mapa.limpar_conteudo(h)
			mapa.definir_conteudo(prox, cont)
			h = prox
		if h != c:
			mapa.revelar(h, 0)
			if dir > 0:
				puxados += 1
			else:
				afastados += 1
	var nome_el := String(DadosJogo.ler("casos").get("elementos", {}).get(elemento, {}).get("nome", elemento.capitalize()))
	return "%s liga o emissor no pulso de %s: %d criatura%s vem para perto, %d se afasta%s." % [a.nome, nome_el, puxados, "" if puxados == 1 else "s", afastados, "" if afastados == 1 else "m"]


func _passo_para_longe(de: Vector2i, de_quem: Vector2i) -> Vector2i:
	var melhor := de
	var dist := Hex.distancia(de, de_quem)
	for v in Hex.vizinhos(de):
		if mapa.tem(v) and mapa.passavel(v) and mapa.conteudo(v).is_empty() and Hex.distancia(v, de_quem) > dist:
			melhor = v
			dist = Hex.distancia(v, de_quem)
	return melhor


func pode_agir_no_mapa() -> bool:
	var a := agente_atual()
	return a != null and not acao_usada and not ocupado() and not a.esta_fora_de_combate()


func usar_item_no_mapa(item_id: String, alvo: Agente) -> Dictionary:
	var a := agente_atual()
	if not pode_agir_no_mapa() or not item_id in itens_fora_de_combate(a) or not alvo in alcance_de_toque():
		return {}
	var info := ruleset.equipamento(item_id)
	a.consumir_item(item_id)
	var cura := dados.rolar_expressao(String(info.uso.get("cura", "0"))) + a.bonus_cura()   # Técnica Medicinal
	alvo.curar(cura)
	acao_usada = true
	_log("%s usa %s em %s: +%d PV." % [a.nome, info.nome, alvo.nome, cura])
	return {"cura": cura, "alvo": alvo}


func conjurar_no_mapa(ritual_id: String, forma: String, alvo: Agente) -> Dictionary:
	var a := agente_atual()
	if not pode_agir_no_mapa() or not [ritual_id, forma] in rituais_fora_de_combate(a):
		return {}
	var r := ruleset.ritual(ritual_id)
	if r.has("mapa"):
		return _conjurar_ritual_de_mapa(a, ritual_id)
	var pessoal := String(r.get("alcance", "")).begins_with("pessoal")
	if (pessoal and alvo != a) or not alvo in alcance_de_toque():
		return {}
	var custo := a.custo_ritual(ritual_id, forma)
	if not a.gastar_pe(custo):
		return {}
	var ef := _efeito_fora(r, forma)
	var valor := dados.rolar_expressao(String(ef.get("dados", "0"))) + (a.bonus_cura() if ef.tipo == "cura" else 0)
	if ef.tipo == "cura":
		alvo.curar(valor)
	else:
		alvo.pv_temporario = maxi(alvo.pv_temporario, valor)
	acao_usada = true
	_log("[color=#b98ae6]%s conjura %s%s em %s (%d PE): %s %d.[/color]" % [a.nome, r.nome, "" if forma == "" else " " + forma, alvo.nome, custo,
		"+PV" if ef.tipo == "cura" else "PV temporários", valor])
	return {"valor": valor, "tipo": ef.tipo, "alvo": alvo}


## Rituais que agem no mapa e no caso (docs/69): o efeito vem do bloco "mapa" do ritual. Pedem
## o círculo, os componentes (ou a afinidade) e, alguns, um caso, um preso ou a credencial.
func _ritual_de_mapa_disponivel(a: Agente, rid: String) -> bool:
	var r := ruleset.ritual(rid)
	var m: Dictionary = r.get("mapa", {})
	if m.is_empty() or int(r.circulo) > a.circulo_maximo():
		return false
	if r.elemento != "medo" and a.afinidade != r.elemento and not a.equipamento.any(func(i): return ruleset.equipamento(i).get("componentes", "") == r.elemento):
		return false
	if m.get("uma_vez", false) and rid in rituais_usados_no_mapa:
		return false
	match String(m.get("exige", "")):
		"caso":
			return caso != null
		"preso":
			return not presos.is_empty()
		"credencial":
			return not credencial.is_empty() and int(credencial.get("usos", 0)) > 0 and not credencial.get("queimada", false)
	return true


func _conjurar_ritual_de_mapa(a: Agente, rid: String) -> Dictionary:
	var r := ruleset.ritual(rid)
	var m: Dictionary = r.mapa
	var custo := a.custo_ritual(rid)
	if not a.gastar_pe(custo):
		return {}
	if m.get("uma_vez", false):
		rituais_usados_no_mapa.append(rid)
	acao_usada = true
	_log("[color=#b98ae6]%s conjura %s (%d PE).[/color]" % [a.nome, r.nome, custo])
	var feitos: Array = []
	for ef in m.get("efeitos", []):
		var f := _aplicar_efeito(a, ef, posicao(a))
		if not f.is_empty():
			feitos.append(f)
	return {"tipo": "mapa", "efeitos": feitos, "alvo": a, "valor": 0}


## O subgênero do sinal (docs/71): sobrepõe o mapa.json só nesta missão (ciclo, caça, interlúdio).
func _aplicar_culto_e_subgenero(_inicio: bool) -> void:
	var sub := Culto.dados_subgenero(String(sinal.get("subgenero", "classico")))
	_cfg = Culto.mesclar(DadosJogo.ler("mapa"), sub.get("cfg", {})) if sub.has("cfg") else DadosJogo.ler("mapa")


## O culto do caso (docs/71), nas missões procedurais da carreira: o método e a estrutura mexem
## na Membrana, no chefe e na credencial; o sinal do vilão deixa o chefe mais forte. Missões de
## campanha e da comunidade não passam por aqui (o conteúdo delas é escrito à mão).
func aplicar_efeitos_do_culto() -> void:
	extras["culto"] = true
	var sub := subgenero()
	var ef: Dictionary = caso.culto.get("efeito", {}) if caso != null and not alarme_falso else {}
	if ef.has("membrana_inicial"):
		membrana.alterar(int(ef.membrana_inicial), "culto")
	if ef.has("chefe"):
		modificador_chefe += int(ef.chefe) / 100.0
	credencial["limite"] = int(DadosJogo.ler("sinais").credencial.limite) + int(ef.get("credencial_limite", 0))
	if sinal.get("vilao", {}).get("final", false):
		var fim: Dictionary = DadosJogo.ler("cultos").vilao.final
		membrana.alterar(int(fim.membrana_inicial), "vilao")
		modificador_chefe += int(fim.chefe) / 100.0
	if String(sinal.get("subgenero", "classico")) != "classico":
		_log("[color=#8fa3d9][b]%s.[/b] %s[/color]" % [sub.nome, sub.texto])
	if sub.has("cacador") and not alarme_falso and caso != null:
		_soltar_cacador(sub.cacador)


## O subgênero da missão ({nome, texto, …}).
func subgenero() -> Dictionary:
	return Culto.dados_subgenero(String(sinal.get("subgenero", "classico")))


func _valor(v) -> int:
	return dados.rolar_expressao(v) if v is String else int(v)


## Aplica um efeito de evento. Devolve o efeito como foi aplicado, para o bilhete de
## desfecho (docs/16): {tipo, valor, texto}, ex.: {"tipo": "dano", "valor": 3, "texto": "−3 PV"}.
func _aplicar_efeito(a: Agente, ef: Dictionary, h: Vector2i) -> Dictionary:
	match ef.tipo:
		"dano":
			var d := _valor(ef.valor)
			a.sofrer_dano(d)
			_log("%s sofre %d de dano." % [a.nome, d])
			return {"tipo": "dano", "valor": d, "texto": "−%d PV" % d}
		"alarme_falso":   # docs/62: não era paranormal; a missão acaba, com pouco prestígio
			alarme_confirmado = true
			_log("[color=#7fd3c7][b]Alarme falso.[/b] A Ordem arquiva o sinal: não era paranormal.[/color]")
			_encerrar(true)
			return {"tipo": "alarme_falso", "texto": "Alarme falso"}
		"varredura":   # docs/62: como o covil foi varrido
			varredura = String(ef.get("valor", "rastro"))
			_log("[color=#7fd3c7][b]Varredura:[/b] %s.[/color]" % {"limpa": "o covil está limpo", "equipe": "a equipe de varredura cuida de tudo",
				"rastro": "algo ficou para trás"}.get(varredura, varredura))
			_encerrar(true)
			return {"tipo": "varredura", "texto": "Varredura: %s" % varredura}
		"dano_mental":
			var d := _valor(ef.valor)
			a.sofrer_dano_mental(d)
			_log("%s perde %d de Sanidade." % [a.nome, d])
			return {"tipo": "dano_mental", "valor": d, "texto": "−%d SAN" % d}
		"cura":
			var v := _valor(ef.valor)
			a.curar(v)
			return {"tipo": "cura", "valor": v, "texto": "+%d PV" % v}
		"recupera_pe":
			var v := _valor(ef.valor)
			a.recuperar_pe(v)
			return {"tipo": "recupera_pe", "valor": v, "texto": "+%d PE" % v}
		"recupera_san":
			var v := _valor(ef.valor)
			a.recuperar_sanidade(v)
			return {"tipo": "recupera_san", "valor": v, "texto": "+%d SAN" % v}
		"membrana":
			var v := _valor(ef.valor)
			membrana.alterar(v, "evento")
			return {"tipo": "membrana", "valor": v, "texto": "Membrana %+d" % v}
		"revelar_raio":
			mapa.revelar(h, _valor(ef.valor))
			return {"tipo": "revelar_raio", "valor": _valor(ef.valor), "texto": "Mapa revelado em volta"}
		"revelar_objetivo":
			var obj := mapa.encontrar("objetivo")
			mapa.revelar(obj, 1)
			covil_localizado = true
			_log("O objetivo foi revelado no mapa.")
			return {"tipo": "revelar_objetivo", "valor": 1, "texto": "Covil revelado"}
		"chefe":
			# Escolhas do mapa que mexem com o covil (docs/50): +10 = o chefe começa com 10% a mais de PV
			var v := _valor(ef.valor)
			modificador_chefe += v / 100.0
			_log("[color=#e0574a]O chefe do covil vai começar com %+d%% de PV.[/color]" % v if v > 0 else "[color=#6fcf8e]O chefe do covil vai começar com %d%% a menos de PV.[/color]" % -v)
			return {"tipo": "chefe", "valor": v, "texto": "Chefe %+d%% PV" % v}
		"sussurros":   # Ouvir os Sussurros (p.147): com 1 no d6, o Outro Lado não responde
			if dados.rolar(6) == 1:
				_log("Os sussurros falam muito e não dizem nada.")
				return {"tipo": "sussurros", "valor": 0, "texto": "Os sussurros calam"}
			return _aplicar_efeito(a, {"tipo": "pista", "texto": String(ef.get("texto", "{indicio}"))}, h)
		"credencial":   # Alterar Memória (p.134): quem viu a credencial esquece
			if credencial.is_empty():
				return {}
			var antes := int(credencial.get("usos", 0))
			credencial.usos = maxi(0, antes + int(ef.valor))
			_log("[color=#7fd3c7]A testemunha esquece a credencial de %s.[/color]" % credencial.get("nome", "fachada"))
			return {"tipo": "credencial", "valor": int(credencial.usos) - antes, "texto": "Credencial: −%d uso(s)" % (antes - int(credencial.usos))}
		"bonus_teste":   # Enfeitiçar, Distorcer Aparência: vale no próximo teste dessa perícia num evento
			bonus_de_ritual[a.id] = {"pericia": String(ef.pericia), "valor": int(ef.valor)}
			var nome_p := String(ruleset.pericia(String(ef.pericia)).get("nome", ef.pericia))
			_log("%s guarda +%d para o próximo teste de %s." % [a.nome, int(ef.valor), nome_p])
			return {"tipo": "bonus_teste", "valor": int(ef.valor), "texto": "+%d no próximo teste de %s" % [int(ef.valor), nome_p]}
		"inocente_morto":
			var n := int(ef.get("valor", 1))
			inocentes_mortos += n
			_log("[color=#e0574a]Um inocente morreu. A Ordem vai cobrar por isso.[/color]")
			return {"tipo": "inocente_morto", "valor": n, "texto": "Inocente morto"}
		"pista":
			# Um traço para o caso (docs/32): na pergunta pedida ou na aberta com menos pistas
			if caso == null:
				return {}
			var pid := String(ef.get("pergunta", ""))
			if pid == "" or caso.pergunta(pid).get("respondida", true):
				pid = ""
				var menos := 1 << 20
				for q in caso.perguntas:
					if not q.respondida and int(q.encontradas) < menos:
						menos = int(q.encontradas)
						pid = String(q.id)
			if pid == "":
				return {}
			var pista := caso.registrar_pista(String(ef.get("texto", "{indicio}")), pid, "evento")
			_anotar_rumor(h)
			var rotulo := String(Caso.indicio(pista.indicio).get("rotulo", "")) if pista.indicio != "" else ""
			_log("[color=#6fcf8e]Pista:[/color] %s" % pista.texto)
			return {"tipo": "pista", "valor": 1, "texto": "Pista: %s" % rotulo.to_lower() if rotulo != "" else "Pista"}
	return {}


# --- Encontros -------------------------------------------------------------

## Monta a configuração do combate: agentes no hex + aliados até 1 hex de distância (FTK).
## `semente_salva`: ao carregar um save, o encontro volta com a mesma seed e sem novo registro.
func _preparar_encontro(h: Vector2i, encontro_id: String, chefe: bool, semente_salva: int = -1) -> void:
	var participantes: Array[Agente] = []
	var alcance := int(_cfg.aliados_entram_no_combate_ate)
	for a in agentes:
		if not a.tem(Ser.MORTO) and not a.esta_fora_de_combate() and Hex.distancia(posicao(a), h) <= alcance:
			participantes.append(a)
	var info: Dictionary = (extras.covil if not extras.get("covil", {}).is_empty() else covil_para(participantes, caso.elemento if caso != null else "")) if chefe else _encontro(encontro_id)
	var ameacas: Array = []
	for amea_id in info.ameacas:
		var am := ameaca_info(amea_id)
		if chefe and amea_id == info.ameacas[0]:
			am.chefe = true   # a primeira ameaça do covil é o chefe
		if chefe and am.chefe and caso != null and extras.get("covil", {}).is_empty():
			am = _chefe_do_caso(am)   # só no caso gerado; as campanhas escrevem o próprio chefe
		if chefe and am.chefe and modificador_chefe != 0.0:
			am.ficha = am.ficha.duplicate(true)
			am.ficha.pv = maxi(1, roundi(float(am.ficha.pv) * (1.0 + modificador_chefe)))
			if caso != null and caso.pergunta("quem").get("respondida", false):
				am.nome = caso.sujeito.get("chefe_titulo", am.nome)
		ameacas.append(am)
	if _culto_vale_na_luta():
		ameacas = _estrutura_nos_cultistas(ameacas)
	# Balanceamento (p.187): fora do covil, a soma do VD das ameaças não passa da soma do NEX
	# de quem entra no combate (× dificuldade); sempre sobra ao menos a mais fraca.
	if not participantes.is_empty():
		var orcamento := 0
		for a in participantes:
			orcamento += a.nex
		if not chefe:
			ameacas = escolher_por_vd(ameacas, int(orcamento * float(_cfg.get("dificuldade_encontro", 1.0))))
		elif not ameacas.is_empty():
			# Covil: o chefe sempre está lá; a escolta cabe no que sobra do orçamento difícil (× 1,5)
			var chefe_am: Dictionary = ameacas[0]
			var sobra := int(orcamento * float(_cfg.get("dificuldade_covil", 1.5))) - int(chefe_am.get("vd", 0))
			ameacas = [chefe_am] + escolher_por_vd(ameacas.slice(1), sobra, false)
	if _culto_vale_na_luta():
		_marcar_lider(ameacas)
	for a in participantes:
		armas[a] = a.arma()   # a arma de cada um agora: sem munição, vira coronhada (docs/67)
	encontro_pendente = {
		"hex": h, "nome": info.nome, "chefe": chefe, "terreno": mapa.terreno(h),
		"agentes": participantes, "armas": armas, "ameacas": ameacas, "encontro": encontro_id,
		"regras": {"lesoes": opcoes.get("lesoes", true), "inspiracao_resoluta": opcoes.get("inspiracao_resoluta", true),
			"presenca_perturbadora": true, "bonus_enigma": mini(10, pistas * 2), "perguntas_respondidas": _perguntas_respondidas(),
			"bonus_identificar": 5 if escuta_instalada else 0, "chefe": chefe},
		"nivel_membrana": membrana.nivel_ameaca(), "semente": semente_salva if semente_salva >= 0 else dados.rolar(1000000),
		# O covil é o lugar do caso (docs/58): a arena se veste por ele, e o cartão do chefe diz
		# o elemento só se o grupo o confirmou
		"local": String(caso.local.get("id", "")) if chefe and caso != null else "",
		"local_nome": String(caso.local.get("nome", "")) if chefe and caso != null else "",
		"elemento_caso": caso.elemento if chefe and caso != null and caso.elemento_confirmado() else "",
		"mestre": bool(opcoes.get("mestre", false)),
		"cacador": _contra_o_cacador,
	}
	_contra_o_cacador = false
	if semente_salva < 0:
		_log("[color=#e0574a][b]Encontro: %s![/b][/color] (%d agente(s) entram no combate)" % [info.nome, participantes.size()])
	encontro_iniciado.emit(encontro_pendente)


## Enigma de Medo do chefe do caso (docs/58): um da tabela de casos.json, sorteado pela semente
## (igual no online), com o lugar do caso no texto. {} sem caso.
func enigma_do_chefe() -> Dictionary:
	if caso == null:
		return {}
	var lista: Array = DadosJogo.ler("casos").get("enigmas_do_chefe", [])
	if lista.is_empty():
		return {}
	var en: Dictionary = (lista[absi(hash("%d|enigma" % semente)) % lista.size()] as Dictionary).duplicate(true)
	en.texto = String(en.texto).replace("{local}", String(caso.local.get("nome", "o covil")))
	return en


## O chefe do caso (docs/58): ganha o Enigma de Medo, se refaz a cada turno até ele ser
## resolvido e, na metade dos PV, vira (se desfaz, volta e chama a escolta). Quem já tem
## enigma próprio (as criaturas do livro) ou que não é criatura fica como está.
func _chefe_do_caso(am: Dictionary) -> Dictionary:
	var en := enigma_do_chefe()
	if en.is_empty() or am.ficha.has("enigma") or not am.ficha.get("criatura", false):
		return am   # gente (o líder do culto) não tem Enigma de Medo
	var regras: Dictionary = DadosJogo.ler("casos").get("enigma_do_chefe_regras", {})
	var novo: Dictionary = am.duplicate(true)
	novo.ficha.enigma = {"tipo": "etapas", "id": en.id, "texto": en.texto, "pergunta": en.pergunta, "etapas": en.etapas,
		"efeito": {"remove_imunidade": false, "remove_habilidades": ["cura_acelerada"]}}
	var cura := int(regras.get("cura", 4))
	var habs: Array = (novo.ficha.get("habilidades", []) as Array).duplicate(true)
	habs.append({"id": "cura_acelerada", "valor": cura, "descricao": "Se refaz: recupera %d PV no início do turno até o enigma ser resolvido." % cura})
	habs.append({"id": "virada", "fracao": float(regras.get("virada", 0.5)), "invoca": (regras.get("escolta", []) as Array).duplicate(),
		"descricao": "Na metade dos PV, se desfaz e volta ao lado de quem está mais abalado; a escolta surge com ele."})
	novo.ficha.habilidades = habs
	return novo


## O achado do alto da serra (docs/45): aplica os efeitos e o mirante se esgota.
func _achar_no_alto(a: Agente, h: Vector2i, achado_id: String) -> void:
	var achado: Dictionary = {}
	for x in _cfg.get("achados_da_serra", []):
		if x.id == achado_id:
			achado = x
	mapa.limpar_conteudo(h)
	if achado.is_empty():
		return
	_log("[color=#e3c27a][b]%s.[/b] %s[/color]" % [achado.titulo, achado.texto])
	for ef in achado.get("efeitos", []):
		_aplicar_efeito(a, ef, h)


## O covil abre? (docs/42) Localizado, sem selo, ou à força com a Membrana rompida.
func covil_aberto() -> bool:
	return covil_localizado or membrana.rompida()


## Quantos aliados (fora o próprio agente) estariam a até `aliados_entram_no_combate_ate`
## de `h` e entrariam numa luta ali (docs/42).
func aliados_perto(a: Agente, h: Vector2i) -> int:
	var alcance := int(_cfg.aliados_entram_no_combate_ate)
	var n := 0
	for outro in agentes:
		if outro != a and not outro.esta_fora_de_combate() and Hex.distancia(posicao(outro), h) <= alcance:
			n += 1
	return n


## O covil muda com o grupo: o de maior "nex_minimo" que a soma do NEX alcança.
## O covil do caso (docs/52): o de maior "nex_minimo" que o grupo alcança, entre os do elemento
## do caso; sem nenhum do elemento, entre todos.
static func covil_para(grupo: Array, elemento: String = "") -> Dictionary:
	var d := DadosJogo.ler("encontros")
	var nex_total := 0
	for a in grupo:
		nex_total += a.nex
	for so_do_elemento in [true, false]:
		if so_do_elemento and elemento == "":
			continue
		var melhor: Dictionary = {}
		for c in d.get("chefes", []):
			if so_do_elemento and String(c.get("elemento", "")) != elemento:
				continue
			if nex_total >= int(c.nex_minimo) and (melhor.is_empty() or int(c.nex_minimo) > int(melhor.get("nex_minimo", 0))):
				melhor = c   # no mesmo nível, vale o primeiro da lista
		if not melhor.is_empty():
			return melhor
	return d.chefe


## O elemento de um encontro: o da primeira ameaça paranormal dele ("" se só há gente e bichos).
func elemento_do_encontro(e: Dictionary) -> String:
	for amea_id in e.get("ameacas", []):
		var el := String(ameaca_info(String(amea_id)).get("ficha", {}).get("elemento", ""))
		if el != "":
			return el
	return ""


## Encontros paranormais do mapa seguem o elemento do caso (docs/52): um de outro elemento vira
## um do elemento do caso, de nível até o dele (ou 1) e sem VD maior; os de gente e bichos ficam.
## A troca usa uma semente do hex, sem gastar os Dados.
func _ajustar_encontros_ao_elemento() -> void:
	if caso == null:
		return
	var todos: Array = DadosJogo.ler("encontros").encontros
	for h in mapa.celulas:
		var c := mapa.conteudo(h)
		if String(c.get("tipo", "")) != "encontro":
			continue
		var e := _encontro(String(c.get("encontro", "")))
		var el := elemento_do_encontro(e)
		if el == "" or el == caso.elemento:
			continue
		var teto := maxi(1, int(e.get("nivel", 0)))
		var vd := maxi(20, _vd_minimo(e))
		var opcoes := todos.filter(func(x): return elemento_do_encontro(x) == caso.elemento and int(x.get("nivel", 0)) <= teto and _vd_minimo(x) <= vd)
		if opcoes.is_empty():
			continue
		var i := absi(hash("%d|%d|%s" % [h.x, h.y, caso.elemento])) % opcoes.size()
		mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": String(opcoes[i].id)})


## Encontro que combina com o caso: de gente e bichos, do elemento do caso ou do Medo (que só
## vem com a Membrana fina, pelo nível).
func _encontro_do_caso(e: Dictionary) -> bool:
	var el := elemento_do_encontro(e)
	return el == "" or el == "medo" or caso == null or el == caso.elemento


## O elemento opressor de outro (p.98: Morte oprime Sangue, Sangue oprime Conhecimento,
## Conhecimento oprime Energia, Energia oprime Morte). "" para o Medo.
func elemento_opressor(el: String) -> String:
	var vantagem: Dictionary = ruleset.dados.get("rituais", {}).get("vantagem_elemental", {})
	for k in vantagem:
		if String(vantagem[k]) == el:
			return String(k)
	return ""


## Escolhe ameaças da lista, da mais forte para a mais fraca, sem passar do orçamento de VD.
static func escolher_por_vd(lista: Array, orcamento: int, ao_menos_uma: bool = true) -> Array:
	var ordenadas := lista.duplicate()
	ordenadas.sort_custom(func(a, b): return int(a.get("vd", 0)) > int(b.get("vd", 0)))
	var escolhidas: Array = []
	var total := 0
	for am in ordenadas:
		if total + int(am.get("vd", 0)) <= orcamento:
			escolhidas.append(am)
			total += int(am.get("vd", 0))
	if escolhidas.is_empty() and not ordenadas.is_empty() and ao_menos_uma:
		escolhidas.append(ordenadas[-1])
	return escolhidas


# --- O culto na luta (docs/73) ------------------------------------------------------------

const CULTISTAS := ["iniciado", "investido", "lider_de_culto"]


## A estrutura do culto mexe nos encontros só nas missões procedurais da carreira (como os
## outros efeitos do culto, docs/71), e nunca num alarme falso.
func _culto_vale_na_luta() -> bool:
	return caso != null and not caso.culto.is_empty() and extras.get("culto", false) and not alarme_falso


## As regras de luta da estrutura (cultos.json): lidas pelo id, para valer também em saves antigos.
func _regras_da_estrutura() -> Dictionary:
	var id := String(caso.culto.get("estrutura", {}).get("id", ""))
	for e in DadosJogo.ler("cultos").estruturas:
		if String(e.id) == id:
			return e.get("encontro", {})
	return {}


## Antes do orçamento de VD: troca, soma e marca os cultistas do encontro pela estrutura. O
## chefe do covil não muda. Fichas copiadas: o traço vai em ficha.culto (Ameaca.culto).
func _estrutura_nos_cultistas(ameacas: Array) -> Array:
	var r := _regras_da_estrutura()
	if r.is_empty() or not ameacas.any(func(am): return String(am.get("id", "")) in CULTISTAS and not am.get("chefe", false)):
		return ameacas
	var lista: Array = []
	var trocou_um := false
	for am in ameacas:
		var id := String(am.get("id", ""))
		if am.get("chefe", false) or not id in CULTISTAS:
			lista.append(am)
			continue
		if (r.get("trocar", {}) as Dictionary).has(id):
			id = String(r.trocar[id])
		elif not trocou_um and (r.get("trocar_um", {}) as Dictionary).has(id):
			trocou_um = true
			var novo := ameaca_info(String(r.trocar_um[id])).duplicate(true)
			novo.nome = String(r.get("nome_trocado", novo.nome))
			lista.append(novo)
			continue
		lista.append(_cultista(id, r, lista.size()))
	if r.has("extra"):
		lista.append(_cultista(String(r.extra), r, lista.size()))
	return lista


## Um cultista com o traço da estrutura: a fuga, a família (o parentesco no nome) e a máscara.
func _cultista(id: String, r: Dictionary, i: int) -> Dictionary:
	var am := ameaca_info(id).duplicate(true)
	var traco := {}
	if r.has("fuga"):
		traco["fuga"] = String(r.fuga)
	if r.get("familia", false):
		traco["familia"] = true
		var parentes: Array = r.get("parentes", [])
		if not parentes.is_empty():
			am.nome = "%s, %s" % [am.nome, parentes[(absi(hash("%d|parente" % semente)) + i) % parentes.size()]]
	if r.has("sufixo"):
		am.nome = "%s %s" % [am.nome, String(r.sufixo)]
	am.ficha["culto"] = traco
	return am


## Hierarquia (docs/73): depois do orçamento, com dois ou mais cultistas, o mais forte é o líder
## e os outros, a escolta. Com um só, não há a quem obedecer.
func _marcar_lider(ameacas: Array) -> void:
	if not _regras_da_estrutura().get("lider", false):
		return
	var cultistas := ameacas.filter(func(am): return String(am.get("id", "")) in CULTISTAS and not am.get("chefe", false))
	if cultistas.size() < 2:
		return
	cultistas.sort_custom(func(a, b): return int(a.vd) > int(b.vd))
	for i in cultistas.size():
		var am: Dictionary = cultistas[i]
		if not am.ficha.has("culto"):
			am.ficha = am.ficha.duplicate(true)
			am.ficha["culto"] = {}
		am.ficha.culto[("lider" if i == 0 else "escolta")] = true
		if i == 0:
			am.nome = "%s (líder)" % am.nome


## Encontros que podem surgir: nível até o da Membrana e cuja ameaça mais fraca tenha VD de até
## o dobro do NEX somado do grupo (para uma Membrana fraca não trazer algo impossível).
func encontros_para_surgir(nivel: int, vivos: Array) -> Array:
	var nex_total := 0
	for a in vivos:
		nex_total += a.nex
	var modo := String(extras.get("surgimentos", "padrao"))
	if modo == "nenhum":
		return []
	var base: Array = extras.get("encontros", []) if modo == "proprios" else DadosJogo.ler("encontros").encontros
	var opcoes: Array = base.filter(func(e): return int(e.get("nivel", 0)) <= nivel and _vd_minimo(e) <= nex_total * 2)
	if modo != "proprios":
		var do_caso := opcoes.filter(func(e): return _encontro_do_caso(e))   # o elemento do caso (docs/52)
		if alarme_falso:   # não é paranormal (docs/62): só gente e bicho
			do_caso = opcoes.filter(func(e): return elemento_do_encontro(e) == "")
		if not do_caso.is_empty():
			opcoes = do_caso
	if opcoes.is_empty() and modo != "proprios":
		opcoes = base.filter(func(e): return int(e.get("nivel", 0)) == 0)
	return opcoes


## Ficha de uma ameaça: primeiro as próprias da missão, depois as do jogo e as do livro.
func ameaca_info(amea_id: String) -> Dictionary:
	if extras.get("ameacas", {}).has(amea_id):
		return DadosJogo.info_ameaca(ruleset, amea_id, extras.ameacas[amea_id])
	return DadosJogo.ameaca(ruleset, amea_id)


## VD da ameaça mais fraca de um encontro (o mínimo que o combate terá).
func _vd_minimo(e: Dictionary) -> int:
	var minimo := 1 << 20
	for id in e.ameacas:
		minimo = mini(minimo, int(ameaca_info(id).vd))
	return minimo


func _perguntas_respondidas() -> Array:
	var ids: Array = []
	if caso != null:
		for p in caso.respondidas():
			ids.append(p.id)
	return ids


func _encontro(encontro_id: String) -> Dictionary:
	for e in extras.get("encontros", []) + DadosJogo.ler("encontros").encontros:
		if e.id == encontro_id:
			return e
	return {}


## Chamado quando o combate termina. Vitória limpa o hex (e vence a missão no covil).
## Agentes caídos são socorridos com 1 PV ao fim de uma vitória (simplificação da fatia vertical).
## `rendidos` (docs/40): pessoas desacordadas com dano não letal. Na vitória, a Ordem as
## interroga e o caso ganha uma pista (uma por encontro).
## `escapados`: quem fugiu da luta e não foi caçado (docs/72) avisa o culto: a Membrana cai.
func concluir_encontro(vencedor: String, rendidos: int = 0, escapados: int = 0) -> void:
	if encontro_pendente.is_empty():
		return
	if vencedor == "fuga":
		_fugir_do_encontro()
		return
	if vencedor == "agentes" and encontro_pendente.get("cacador", false):
		_cacador_derrubado(encontro_pendente.hex)
	if escapados > 0 and vencedor == "agentes":
		membrana.alterar(-2 * escapados, "fugitivo")
		_log("[color=#e0574a]%d fugitivo%s leva%s a notícia ao culto. A Membrana cai %d.[/color]" % [escapados, "" if escapados == 1 else "s", "" if escapados == 1 else "m", 2 * escapados])
	if vencedor == "agentes" and rendidos > 0 and caso != null:
		_log("[color=#7fd3c7]Interrogatório: %d rendido(s) acorda(m) algemado(s) e fala(m).[/color]" % rendidos)
		_aplicar_efeito(agente_atual() if agente_atual() != null else agentes[0], {"tipo": "pista"}, encontro_pendente.hex)
		_levar_preso(encontro_pendente)
	var h: Vector2i = encontro_pendente.hex
	var chefe: bool = encontro_pendente.chefe
	var era_cacador: bool = encontro_pendente.get("cacador", false)
	for a in encontro_pendente.agentes:
		a.encerrar_cena()
	var participantes: Array = encontro_pendente.agentes
	encontro_pendente = {}
	alivio = int(_cfg.get("mundo", {}).get("caca", {}).get("alivio_depois_de_combate", 1))   # o pico passou: respiro (docs/53)
	if vencedor == "agentes":
		for a in participantes:
			if a.tem(Ser.MORTO):
				_tratar_queda(a)
			elif a.pv == 0:
				a.estabilizar()
				a.curar(1)
				a.condicoes.erase(Ser.INCONSCIENTE)
				_log("%s é socorrido e volta com 1 PV." % a.nome)
		# Só sai do mapa o que era o encontro (ou o covil, com o chefe). Uma caça que alcança o
		# agente parado nas ruínas do covil fechado, numa vila ou num evento luta ali, mas não
		# apaga o lugar: antes, vencer a caça em cima do covil apagava o covil.
		if chefe or String(mapa.conteudo(h).get("tipo", "")) == "encontro":
			mapa.limpar_conteudo(h)
		_log("[color=#6fcf8e]Encontro vencido.[/color]")
		if chefe and extras.get("covil", {}).is_empty() and caso != null:
			_abrir_varredura(h, participantes)
		elif chefe:
			_encerrar(true)
	else:
		_log("[color=#e0574a]Os agentes caíram.[/color]")
		if era_cacador and mapa.conteudo(h).is_empty():
			mapa.definir_conteudo(h, _conteudo_do_cacador())   # o caçador continua ali (docs/74)
		for a in participantes:
			if a.esta_fora_de_combate() or a.tem(Ser.MORTO):
				_tratar_queda(a)
	_ajustar_indice()
	_verificar_derrota()


## O grupo fugiu (docs/72): o encontro (ou o covil) continua no mapa; o grupo recua para um hex
## livre vizinho e ganha um respiro da caça. O medo deixa marca: a Membrana cai 2.
func _fugir_do_encontro() -> void:
	var h: Vector2i = encontro_pendente.hex
	var participantes: Array = encontro_pendente.agentes
	if encontro_pendente.get("cacador", false) and mapa.conteudo(h).is_empty():
		mapa.definir_conteudo(h, _conteudo_do_cacador())   # o caçador fica onde a luta foi (docs/74)
	encontro_pendente = {}
	for a in participantes:
		a.encerrar_cena()
	var destino := h
	for v in Hex.vizinhos(h):
		if mapa.tem(v) and mapa.passavel(v) and mapa.conteudo(v).is_empty():
			destino = v
			break
	for a in participantes:
		if not a.tem(Ser.MORTO) and posicao(a) == h:
			posicoes[a] = destino
	alivio = int(_cfg.get("mundo", {}).get("caca", {}).get("alivio_depois_de_combate", 1))
	membrana.alterar(-2, "fuga")
	_log("[color=#8fa3d9]O grupo foge e se esconde. O que estava ali continua lá. A Membrana cai 2.[/color]")
	for a in participantes:
		if a.tem(Ser.MORTO):
			_tratar_queda(a)
		elif a.pv == 0:
			# Quem caiu na fuga foi carregado pelos outros, como na vitória
			a.estabilizar()
			a.curar(1)
			a.condicoes.erase(Ser.INCONSCIENTE)
			_log("%s é carregado na fuga e volta com 1 PV." % a.nome)
	_ajustar_indice()
	_verificar_derrota()


## Credencial (docs/63): soma os usos da cena e, no limite, queima a fachada. A polícia de
## verdade vem atrás de quem se passou por polícia: uma patrulha surge ao lado do grupo.
func _somar_usos_da_credencial(usos: int, h: Vector2i) -> void:
	if usos <= 0 or credencial.get("queimada", false):
		return
	var cfg: Dictionary = DadosJogo.ler("sinais").credencial
	credencial.usos = int(credencial.get("usos", 0)) + usos
	if int(credencial.usos) < int(credencial.get("limite", cfg.limite)):
		return
	credencial.queimada = true
	var livres: Array = Hex.vizinhos(h).filter(func(v): return mapa.tem(v) and mapa.conteudo(v).is_empty())
	livres.sort()
	if not livres.is_empty():
		mapa.definir_conteudo(livres[absi(hash("%d|patrulha" % semente)) % livres.size()], {"tipo": "encontro", "encontro": String(cfg.encontro_ao_queimar)})
	_log("[color=#e0574a]A %s não existe, e a polícia local descobriu. Uma patrulha procura os falsos agentes por perto.[/color]" % cfg.orgao)


## Um cultista rendido vai para a contenção da Base (docs/63, OR8): um por encontro, com
## nome de gente comum e o papel que tinha no combate. A Carreira o põe numa cela no fim.
func _levar_preso(enc: Dictionary) -> void:
	var papel := "Cultista"
	for am in enc.get("ameacas", []):
		if not am.get("ficha", {}).get("criatura", false):
			papel = String(am.get("nome", papel))
			break
	var t := DadosJogo.ler("testemunhas")
	var nomes: Array = t.nomes_f + t.nomes_m
	var nome := String(nomes[absi(hash("%d|preso|%d" % [semente, presos.size()])) % nomes.size()])
	presos.append({"nome": nome, "papel": papel, "elemento": caso.elemento if caso != null else ""})
	_log("[color=#7fd3c7]%s, %s, vai algemado para a contenção da Base.[/color]" % [nome, papel.to_lower()])


## A varredura do covil (docs/62, OR5): com o chefe no chão, o grupo varre o covil, paga uma
## equipe ou vai embora. Vira um evento no hex do covil, para o painel de evento (e o piloto)
## resolverem como os outros.
func _abrir_varredura(h: Vector2i, participantes: Array) -> void:
	var a := agente_atual()
	if a == null or not a in participantes:
		for x in participantes:
			if not x.tem(Ser.MORTO) and not x.esta_fora_de_combate():
				a = x
				break
	if a == null:
		_encerrar(true)
		return
	var ev := _evento("varredura")
	evento_pendente = {"hex": h, "evento": ev, "agente": a}
	_log("[b]%s[/b]: %s" % [ev.titulo, ev.texto])
	evento_aberto.emit(h, ev, a)


## Alarme falso (docs/62): sem o paranormal no mapa. Encontros de criatura viram de gente ou
## bicho, do mesmo nível ou menor; quem não tem troca sai do mapa.
func _tirar_o_paranormal() -> void:
	var mundanos: Array = DadosJogo.ler("encontros").encontros.filter(func(x): return elemento_do_encontro(x) == "")
	for h in mapa.celulas:
		var c := mapa.conteudo(h)
		if String(c.get("tipo", "")) != "encontro":
			continue
		var e := _encontro(String(c.get("encontro", "")))
		if elemento_do_encontro(e) == "":
			continue
		var teto := maxi(1, int(e.get("nivel", 0)))
		var opcoes := mundanos.filter(func(x): return int(x.get("nivel", 0)) <= teto)
		if opcoes.is_empty():
			mapa.limpar_conteudo(h)
		else:
			mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": String(opcoes[absi(hash(h)) % opcoes.size()].id)})


## O que o preso contou (docs/63, OR8): uma pista firme na pergunta "quem", logo no começo.
func receber_pista_do_preso(info: Dictionary) -> void:
	if caso == null:
		return
	var texto := String(DadosJogo.ler("sinais").contencao.pista).replace("{cela}", String(info.get("cela", "")))
	var pista := caso.registrar_pista(texto, "quem", "contencao")
	pistas += 1
	_log("[color=#6fcf8e]Pista:[/color] %s" % pista.texto)


## O que ficou no último covil (docs/62): a varredura malfeita volta como um evento de Medo
## perto do início da missão seguinte, e a Membrana já começa um pouco mais fina.
func plantar_eco_do_covil() -> void:
	var inicio := mapa.encontrar("inicio")
	var livres: Array = mapa.celulas.keys().filter(func(h): return Hex.distancia(h, inicio) in [2, 3] and mapa.conteudo(h).is_empty())
	livres.sort()
	if not livres.is_empty():
		mapa.definir_conteudo(livres[absi(hash("%d|eco" % semente)) % livres.size()], {"tipo": "evento", "evento": "eco_do_covil"})
	membrana.alterar(-5, "eco_do_covil")
	_log("[color=#e0574a]O que ficou no último covil achou o caminho até aqui. A Membrana já está mais fina.[/color]")


## Agente morto ou caído num combate perdido. Modo Normal: gasta um Reforço da Ordem e o
## agente é resgatado (sai da missão com uma lesão). Sem reforços, ou no Hardcore, morre.
func _tratar_queda(a: Agente) -> void:
	if a.tem(Ser.INSANO):
		agentes.erase(a)
		return
	if opcoes.get("modo_morte", "normal") == "normal" and reforcos > 0:
		reforcos -= 1
		agentes.erase(a)
		resgatados.append(a)
		a.condicoes.clear()
		a.pv = maxi(1, a.pv)
		var ordem := ["agi", "for", "int", "pre", "vig"]
		var d6 := dados.rolar(6)
		if d6 <= 5:
			var attr: String = ordem[d6 - 1]
			a.atributos[attr] = maxi(0, int(a.atributos.get(attr, 0)) - 1)
			a.lesoes.append(attr)
			a.recalcular_maximos()
			_log("[color=#eda64a]Reforços da Ordem resgatam %s (lesão: −1 %s). Reforços restantes: %d.[/color]" % [a.nome, attr.to_upper(), reforcos])
		else:
			_log("[color=#eda64a]Reforços da Ordem resgatam %s, sem sequelas. Reforços restantes: %d.[/color]" % [a.nome, reforcos])
	else:
		a.condicoes.clear()
		a.condicoes[Ser.MORTO] = true
		agentes.erase(a)
		mortos.append(a)
		_log("[color=#e0574a]%s morreu.[/color]" % a.nome)


func _ajustar_indice() -> void:
	if agentes.is_empty():
		indice = 0
		return
	if indice >= agentes.size():
		indice = 0
	_iniciar_turno_do_agente()


# --- Investigação ----------------------------------------------------------

func _preparar_investigacao(h: Vector2i, cena_id: String, semente_salva: int = -1) -> void:
	var participantes: Array[Agente] = []
	for a in agentes:
		if not a.esta_fora_de_combate() and Hex.distancia(posicao(a), h) <= int(_cfg.aliados_entram_no_combate_ate):
			participantes.append(a)
	investigacao_pendente = {"hex": h, "cena": cena_id, "agentes": participantes, "semente": semente_salva if semente_salva >= 0 else dados.rolar(1000000)}
	if semente_salva < 0:
		_log("[color=#7fd3c7][b]Investigação: %s![/b][/color] (%d agente(s) participam)" % [cena_info(cena_id).get("nome", ""), participantes.size()])
	investigacao_iniciada.emit(investigacao_pendente)


## Cena de investigação pelo id: primeiro as da própria missão, depois as do jogo.
func cena_info(cena_id: String) -> Dictionary:
	for cn in extras.get("cenas", []) + DadosJogo.ler("cenas_investigacao").cenas:
		if cn.id == cena_id:
			return cn
	return {}


## Cria a cena de investigação pendente (a cena da UI chama isto).
func criar_cena_investigacao() -> CenaInvestigacao:
	if investigacao_pendente.is_empty():
		return null
	var d := Dados.new(int(investigacao_pendente.get("semente", 1)))
	var cena := CenaInvestigacao.nova(ruleset, d, caso, investigacao_pendente.cena, investigacao_pendente.agentes, "", membrana, extras.get("cenas", []))
	cena.credencial = credencial.duplicate()   # docs/63: a cena usa, a Missão soma no fim
	# O culto na cena (docs/73): o símbolo para traduzir e, se o caso é do vilão, a notícia no
	# celular de uma testemunha. Num alarme falso não há culto por trás.
	if caso != null and not alarme_falso:
		cena.adicionar_simbolo_do_culto()
		var vil: Dictionary = sinal.get("vilao", {})
		if (vil.get("ligado", false) or vil.get("final", false)) and caso.noticia == "":
			cena.noticia = Culto.recorte(vil, caso.culto, semente)
	return cena


## Aplica o resultado de uma cena de investigação: pistas (PP), perguntas respondidas e
## penalidades da urgência. O hex fica limpo (ou vira um encontro, se a penalidade mandar).
func concluir_investigacao(resultado: Dictionary) -> void:
	if investigacao_pendente.is_empty():
		return
	var h: Vector2i = investigacao_pendente.hex
	investigacao_pendente = {}
	mapa.limpar_conteudo(h)
	pistas += resultado.get("pistas", []).size()
	if not resultado.get("pistas", []).is_empty():
		_anotar_rumor(h)
	_somar_usos_da_credencial(int(resultado.get("usos_credencial", 0)), h)
	for t in resultado.get("testemunhas", []):
		testemunhas_vistas.append({"nome": String(t.nome), "papel": String(t.papel), "cena": String(t.get("cena", "")), "sumiu": false})
	if String(resultado.get("cena", "")) != "" and not resultado.get("restantes", []).is_empty():
		revisaveis.append({"cena": String(resultado.cena), "pontos": (resultado.restantes as Array).duplicate()})
	for p in resultado.get("perguntas", []):
		_aplicar_efeito_pergunta(p)
	var pen: Dictionary = resultado.get("penalidade", {})
	match pen.get("tipo", ""):
		"chefe_fortalecido":
			modificador_chefe += 0.2
		"encontro":
			mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": pen.get("encontro", "celula_cultista")})
	# "membrana" já foi aplicada pela própria cena (urgência estourada)
	_iniciar_turno_do_agente_sem_reset()
	_verificar_derrota()


## Solução do caso (p.53 e p.79, docs/37): a ameaça caiu e a ficha responde o objetivo.
## Missão sem caso (da comunidade, antiga): basta a vitória.
func caso_solucionado() -> bool:
	return vitoria and (caso == null or caso.solucionado())


## O efeito de uma pergunta resolvida (casos.json): chefe mais fraco, Membrana, covil no mapa.
func _aplicar_efeito_pergunta(p: Dictionary) -> void:
	var ef: Dictionary = p.get("efeito", {})
	_log("[color=#e3c27a]%s[/color]" % ef.get("texto", ""))
	match ef.get("tipo", ""):
		"chefe_enfraquecido":
			modificador_chefe -= 0.2
		"membrana":
			membrana.alterar(int(ef.get("valor", 0)), "investigacao")
		"revelar_objetivo":
			var obj := mapa.encontrar("objetivo")
			mapa.revelar(obj, 1)
			covil_localizado = true


## O grupo acusa um candidato fora da cena, pelo painel do caso (docs/32). O acerto aplica o
## efeito na hora; o erro custa Membrana e risca o candidato. Não gasta movimento nem ação.
func deduzir(pergunta_id: String, candidato_id: String) -> Dictionary:
	if caso == null:
		return {"ok": false}
	var r := caso.deduzir(pergunta_id, candidato_id)
	if not r.ok:
		return r
	if r.acertou:
		_log("[color=#e3c27a][b]Dedução certa:[/b] %s → %s[/color]" % [r.pergunta.texto, r.candidato.nome])
		_aplicar_efeito_pergunta(r.pergunta)
		if not r.get("ampliacao", {}).is_empty():
			_log("[color=#c9a0ff][b]A investigação se amplia.[/b] %s Nova pergunta: %s[/color]" % [r.ampliacao.revelacao, r.ampliacao.pergunta.texto])
	else:
		var custo := Caso.penalidade_palpite()
		membrana.alterar(custo, "palpite_errado")
		_log("[color=#e0574a][b]Acusação errada:[/b] %s não bate com tudo. A Membrana cai %d.[/color]" % [r.candidato.nome, -custo])
		_verificar_derrota()
	return r


## Relatório à Ordem (docs/52): quem, o quê e onde de uma vez. Aceito: os efeitos das perguntas,
## o elemento confirmado e a reviravolta. Recusado: a Membrana cai uma vez; no modo normal, a
## Ordem diz quantas respostas se sustentam (no hardcore, nada).
func relatar(respostas: Dictionary) -> Dictionary:
	if caso == null:
		return {"ok": false}
	var r := caso.relatar(respostas)
	if not r.ok:
		return r
	if r.acertou:
		_log("[color=#e3c27a][b]Relatório aceito pela Ordem.[/b][/color]")
		for q in r.perguntas:
			_log("[color=#e3c27a]%s → %s[/color]" % [q.texto, caso.resposta(String(q.id))])
			_aplicar_efeito_pergunta(q)
		if caso.elemento_confirmado():
			_log("[color=#e3c27a]%s[/color]" % linha_do_elemento())
		if not r.get("ampliacao", {}).is_empty():
			_log("[color=#c9a0ff][b]A investigação se amplia.[/b] %s Nova pergunta: %s[/color]" % [r.ampliacao.revelacao, r.ampliacao.pergunta.texto])
	else:
		var custo := Caso.penalidade_palpite()
		membrana.alterar(custo, "palpite_errado")
		_log("[color=#e0574a][b]Relatório recusado:[/b] a teoria não se sustenta. A Membrana cai %d.%s[/color]" % [-custo, texto_do_recusado(r)])
		_verificar_derrota()
	return r


## O que a Ordem diz de um relatório recusado: no normal, quantas respostas se sustentam.
func texto_do_recusado(r: Dictionary) -> String:
	if String(opcoes.get("modo_morte", "normal")) != "normal":
		return ""
	return " %d de %d respostas se sustentam." % [int(r.certas), int(r.total)]


## O elemento confirmado e o que ele muda no covil (rituais do opressor com vantagem, p.118).
func linha_do_elemento() -> String:
	if caso == null:
		return ""
	var op := elemento_opressor(caso.elemento)
	var nomes: Dictionary = DadosJogo.ler("casos").get("elementos", {})
	var nome_op := String(nomes.get(op, {}).get("nome", op.capitalize()))
	return "O elemento é %s: no covil, rituais de %s têm vantagem e os de %s, desvantagem." % [caso.nome_elemento(), nome_op, caso.nome_elemento()]


## Volta ao mesmo agente depois da cena, sem zerar o movimento que ele tinha.
func _iniciar_turno_do_agente_sem_reset() -> void:
	var a := agente_atual()
	if a != null:
		turno_mudou.emit(a)


# --- Mundo -----------------------------------------------------------------

func _turno_do_mundo() -> void:
	turno_mundo += 1
	membrana.registrar("turno_mapa")
	_log("[color=#a69b88]— Turno %d do mundo — Membrana %d (%s)[/color]" % [turno_mundo, membrana.valor, membrana.estado().get("nome", "")])
	if membrana.rompida() and not covil_localizado:
		covil_localizado = true   # confronto final, preparado ou não (membrana.json)
		mapa.revelar(mapa.encontrar("objetivo"), 1)
		_log("[color=#e0574a][b]A Membrana se rompe.[/b] O covil se abre sozinho e chama os agentes.[/color]")
	if eh_noite() != eh_noite(turno_mundo - 1):
		_log("[color=#8fa3d9][b]%s[/b][/color]" % ("A noite cai. Algo começa a se mexer lá fora." if eh_noite() else "Amanhece. O que caçava volta para a névoa."))
		if eh_noite():
			_sumir_testemunha()
	var transmissao := int(subgenero().get("membrana_por_turno", 0))
	if transmissao != 0:
		membrana.alterar(transmissao, "transmissao")   # subgênero Transmissão (docs/71)
	_turnos_sem_surgimento += 2 if eh_noite() else 1   # à noite, duas vezes mais rápido (docs/53)
	if _turnos_sem_surgimento >= int(_cfg.mundo.surgimento_a_cada_turnos) and membrana.nivel_ameaca() >= 1:
		_turnos_sem_surgimento = 0
		_surgir_ameaca()
	_cacador_volta()
	_cacar()
	_ataque_a_sanidade()


# --- Medo no mapa (docs/53) ---------------------------------------------------------

## Terror indireto (p.163, docs/56): quando a noite cai e o caso ainda não está fechado, uma das
## testemunhas que falaram com o grupo pode sumir (uma chance em três). A semente sai da missão e
## do turno: igual no online. Custa um pouco de Membrana; não custa PP, ninguém podia impedir.
func _sumir_testemunha() -> void:
	var cfg: Dictionary = DadosJogo.ler("testemunhas").get("sumico", {})
	var vivas: Array = testemunhas_vistas.filter(func(t): return not t.get("sumiu", false))
	if vivas.is_empty() or cfg.is_empty() or (caso != null and caso.elemento_confirmado()):
		return
	var s := absi(hash("%d|%d|sumico" % [semente, turno_mundo]))
	var chance_em := int(caso.culto.get("efeito", {}).get("sumico_chance_em", cfg.get("chance_em", 3))) if caso != null and extras.get("culto", false) else int(cfg.get("chance_em", 3))
	if s % chance_em != 0:   # o culto que faz gente sumir: mais vezes (docs/71)
		return
	var t: Dictionary = vivas[(s / 5) % vivas.size()]
	t.sumiu = true
	membrana.alterar(int(cfg.get("membrana", -2)), "testemunha_sumiu")
	_log("[color=#e0574a][b]%s[/b], %s que falou com vocês em %s, não volta para casa esta noite. Na porta, só um sinal que ninguém da cidade sabe ler.[/color]" % [
		t.nome, String(t.papel).to_lower(), String(t.cena).to_lower()])


## Noite no turno `t` do mundo: 3 de dia, 2 de noite (mapa.json, mundo.ciclo).
func eh_noite(t: int = -1) -> bool:
	var c: Dictionary = _cfg.get("mundo", {}).get("ciclo", {"dia": 3, "noite": 2})
	var n := int(c.dia) + int(c.noite)
	var turno := turno_mundo if t < 0 else t
	return n > 0 and int(c.noite) > 0 and ((turno - 1) % n) >= int(c.dia)


## À noite, as criaturas caçam (diretor de Alien: Isolation): as que surgiram e as paranormais
## já espalhadas pelo mapa (gente e bichos ficam onde estão). Cada uma anda um hex
## até o agente mais isolado a até 6 hexes, sem atravessar conteúdo nem entrar em vila, e deixa
## rastro. Depois de um combate, recuam por um turno (alívio). Alcançar o hex de um agente
## começa o encontro ali, com quem estiver por perto. Uma emboscada por turno do mundo.
func _cacar() -> void:
	passos_da_caca.clear()
	var cfg: Dictionary = _cfg.get("mundo", {}).get("caca", {})
	var ttl := int(cfg.get("rastro_turnos", 2))
	for h in rastros.keys():
		if turno_mundo - int(rastros[h]) > ttl:
			rastros.erase(h)
	if alivio > 0:
		alivio -= 1
		return
	if ocupado() or _cacador_anda():
		return
	if not eh_noite():
		return
	var raio := int(cfg.get("raio", 6))
	var cacadores: Array[Vector2i] = []
	for h in mapa.celulas:
		var c := mapa.conteudo(h)
		if c.get("cacador", false):
			continue   # o caçador da Perseguição anda à parte (docs/74)
		if String(c.get("tipo", "")) == "encontro" and (c.get("caca", false) or _paranormal(String(c.get("encontro", "")))):
			cacadores.append(h)
	cacadores.sort()   # a mesma ordem nas duas máquinas do online
	for h in cacadores:
		var c := mapa.conteudo(h)
		var alvo := _presa_perto(h, raio)
		if alvo == null:
			continue
		var destino := posicao(alvo)
		var passo := _passo_para(h, destino)
		if passo == h:
			continue
		mapa.limpar_conteudo(h)
		rastros[h] = turno_mundo
		if passo == destino:
			_log("[color=#e0574a][b]Na escuridão, algo alcança %s.[/b][/color]" % alvo.nome)
			_preparar_encontro(destino, String(c.get("encontro", "")), false)
			return
		mapa.definir_conteudo(passo, c)
		passos_da_caca.append({"de": h, "para": passo})


# --- O caçador da Perseguição (docs/74) -----------------------------------------------------

var _contra_o_cacador := false   ## o próximo _preparar_encontro é contra o caçador


func _cfg_cacador() -> Dictionary:
	return subgenero().get("cacador", {})


## O encontro de uma criatura só ("cacador_<ameaça>"), guardado nos extras da missão (vai no save).
func _encontro_do_cacador(ameaca_id: String) -> String:
	var id := "cacador_" + ameaca_id
	var lista: Array = extras.get_or_add("encontros", [])
	if not lista.any(func(e): return String(e.get("id", "")) == id):
		lista.append({"id": id, "nome": "O caçador", "ameacas": [ameaca_id], "nivel": 1})
	return id


func _conteudo_do_cacador() -> Dictionary:
	return {"tipo": "encontro", "encontro": String(cacador.encontro), "caca": true, "cacador": true}


## Solta o caçador longe do grupo: uma criatura do elemento do caso, no primeiro degrau da lista.
func _soltar_cacador(cfg: Dictionary) -> void:
	var lista: Array = cfg.get("por_elemento", {}).get(caso.elemento, [])
	if lista.is_empty():
		return
	cacador = {"lista": lista.duplicate(), "estagio": 0, "encontro": _encontro_do_cacador(String(lista[0])),
		"derrotas": 0, "volta_em": -1, "banido": false}
	var h := _lugar_do_cacador(int(cfg.get("distancia_inicial", 6)))
	if h == Vector2i(-999, -999):
		cacador = {}
		return
	mapa.definir_conteudo(h, _conteudo_do_cacador())
	_log("[color=#e0574a][b]Algo segue o grupo.[/b] Um rastro de %s aparece no mapa e não some com o dia.[/color]" % caso.nome_elemento().to_lower())


## Um hex livre e transitável, fora de vila e do ponto de encontro, o mais longe possível do
## grupo até `distancia` (a semente escolhe entre os empatados: igual no online).
func _lugar_do_cacador(distancia: int) -> Vector2i:
	var grupo: Array = agentes.filter(func(a): return not a.tem(Ser.MORTO)).map(func(a): return posicao(a))
	var candidatos: Array = []
	var melhor := -1
	var celulas: Array = mapa.celulas.keys()
	celulas.sort()
	for h in celulas:
		if not mapa.passavel(h) or not mapa.conteudo(h).is_empty():
			continue
		var d := 1 << 20
		for p in grupo:
			d = mini(d, Hex.distancia(h, p))
		d = mini(d, distancia)
		if d > melhor:
			melhor = d
			candidatos = [h]
		elif d == melhor:
			candidatos.append(h)
	if candidatos.is_empty():
		return Vector2i(-999, -999)
	return candidatos[absi(hash("%d|cacador|%d" % [semente, int(cacador.get("derrotas", 0))])) % candidatos.size()]


func cacador_no_mapa() -> Vector2i:
	for h in mapa.celulas:
		if mapa.conteudo(h).get("cacador", false):
			return h
	return Vector2i(-999, -999)


## O caçador anda todo turno, de dia e de noite (de noite, `passos_de_noite`), atrás do agente
## mais isolado, onde quer que esteja: ele sente o grupo. Vilas e o ponto de encontro seguem
## seguros. Devolve true se alcançou alguém (a emboscada do turno).
func _cacador_anda() -> bool:
	if cacador.is_empty() or cacador.get("banido", false):
		return false
	var h := cacador_no_mapa()
	if not mapa.tem(h):
		return false
	var passos := int(_cfg_cacador().get("passos_de_noite", 2)) if eh_noite() else 1
	var c := mapa.conteudo(h)
	for _i in passos:
		var alvo := _presa_perto(h, 1 << 10)
		if alvo == null:
			return false
		var destino := posicao(alvo)
		var passo := _passo_no_caminho(h, destino)
		if passo == h:
			return false
		mapa.limpar_conteudo(h)
		rastros[h] = turno_mundo
		if passo == destino:
			_log("[color=#e0574a][b]Ele alcança %s.[/b][/color]" % alvo.nome)
			_contra_o_cacador = true
			_preparar_encontro(destino, String(c.encontro), false)
			return true
		mapa.definir_conteudo(passo, c)
		passos_da_caca.append({"de": h, "para": passo})
		h = passo
	return false


## O primeiro passo do caminho mais curto de `de` até `para`, por hexes transitáveis e vazios
## (busca em largura, vizinhos em ordem: igual no online). O caçador contorna rio e mata; os
## outros que caçam vão em linha reta (_passo_para). Sem caminho, fica onde está.
func _passo_no_caminho(de: Vector2i, para: Vector2i) -> Vector2i:
	var veio := {de: de}
	var fila: Array[Vector2i] = [de]
	while not fila.is_empty():
		var h: Vector2i = fila.pop_front()
		if h == para:
			break
		var vizinhos := Hex.vizinhos(h)
		vizinhos.sort()
		for v in vizinhos:
			if veio.has(v) or not mapa.tem(v) or not mapa.passavel(v):
				continue
			if v != para and not mapa.conteudo(v).is_empty():
				continue
			veio[v] = h
			fila.append(v)
	if not veio.has(para):
		return de
	var passo := para
	while veio[passo] != de:
		passo = veio[passo]
	return passo


## Derrubado, o caçador some e volta em alguns turnos. Com o "o quê" respondido, a Ordem sabe o
## que ele é e o prende de vez: a Membrana respira.
func _cacador_derrubado(h: Vector2i) -> void:
	if cacador.is_empty():
		return
	if mapa.conteudo(h).get("cacador", false):
		mapa.limpar_conteudo(h)
	if caso != null and caso.elemento_confirmado():
		cacador.banido = true
		var m := int(_cfg_cacador().get("membrana_ao_banir", 3))
		membrana.alterar(m, "cacador")
		_log("[color=#6fcf8e][b]Sabendo o que ele é, a Ordem o prende de vez.[/b] A Membrana respira (+%d).[/color]" % m)
		return
	cacador.derrotas = int(cacador.get("derrotas", 0)) + 1
	cacador.volta_em = turno_mundo + int(_cfg_cacador().get("volta_em_turnos", 3))
	var lista: Array = cacador.get("lista", [])
	if not lista.is_empty():   # volta um degrau acima (o slasher que volta pior)
		cacador.estagio = mini(int(cacador.get("estagio", 0)) + 1, lista.size() - 1)
		cacador.encontro = _encontro_do_cacador(String(lista[int(cacador.estagio)]))
	_log("[color=#eda64a][b]Ele cai e se desfaz na névoa.[/b] Vai voltar no turno %d, maior, a menos que a Ordem descubra o que ele é.[/color]" % int(cacador.volta_em))


## No turno marcado, o caçador volta, longe do grupo.
func _cacador_volta() -> void:
	if cacador.is_empty() or cacador.get("banido", false) or int(cacador.get("volta_em", -1)) < 0 or turno_mundo < int(cacador.volta_em):
		return
	var h := _lugar_do_cacador(int(_cfg_cacador().get("distancia_inicial", 6)))
	if h == Vector2i(-999, -999):
		return
	cacador.volta_em = -1
	mapa.definir_conteudo(h, _conteudo_do_cacador())
	_log("[color=#e0574a][b]Ele voltou.[/b] O rastro recomeça, longe do grupo.[/color]")


## Encontro com criatura paranormal (o elemento de alguma ameaça), com cache por id.
var _elemento_por_encontro: Dictionary = {}
func _paranormal(encontro_id: String) -> bool:
	return elemento_de(encontro_id) != ""


## O elemento de um encontro pelo id ("" para gente e bichos), com cache.
func elemento_de(encontro_id: String) -> String:
	if not _elemento_por_encontro.has(encontro_id):
		_elemento_por_encontro[encontro_id] = elemento_do_encontro(_encontro(encontro_id))
	return String(_elemento_por_encontro[encontro_id])


## O agente mais isolado (menos aliados por perto) a até `raio` hexes; fora de vilas e do ponto
## de encontro, que são seguros. null se ninguém.
func _presa_perto(h: Vector2i, raio: int) -> Agente:
	var melhor: Agente = null
	var nota := 1 << 20
	for a in agentes:
		if a.esta_fora_de_combate() or a.tem(Ser.MORTO):
			continue
		var p := posicao(a)
		var d := Hex.distancia(h, p)
		if d > raio or String(mapa.conteudo(p).get("tipo", "")) in ["vila", "inicio"]:
			continue
		var n := aliados_perto(a, p) * 100 + d
		if n < nota:
			nota = n
			melhor = a
	return melhor


## O próximo passo de `de` em direção a `para`: um vizinho transitável, sem conteúdo (ou o próprio
## destino), mais perto dele. Sem passo melhor, fica onde está (não se teletransporta).
func _passo_para(de: Vector2i, para: Vector2i) -> Vector2i:
	var melhor := de
	var dist := Hex.distancia(de, para)
	for v in Hex.vizinhos(de):
		if not mapa.tem(v) or not mapa.passavel(v):
			continue
		if v != para and not mapa.conteudo(v).is_empty():
			continue
		var d := Hex.distancia(v, para)
		if d < dist:
			dist = d
			melhor = v
	return melhor


## Os próximos `n` turnos do mundo, para a linha do tempo do Outro Lado (docs/53):
## [{turno, noite, eventos: [{id, texto}]}]. Prevê a Membrana (−2 por turno), o surgimento de
## ameaças, a caçada noturna e o rompimento.
func previsao(n: int = 5) -> Array:
	var lista: Array = []
	var valor := membrana.valor
	var cont := _turnos_sem_surgimento
	var por_turno := int(membrana.config.get("eventos", {}).get("turno_mapa", -2))
	var a_cada := int(_cfg.get("mundo", {}).get("surgimento_a_cada_turnos", 2))
	var tem_cacador := false
	for h in mapa.celulas:
		var c := mapa.conteudo(h)
		if String(c.get("tipo", "")) == "encontro" and (c.get("caca", false) or _paranormal(String(c.get("encontro", "")))):
			tem_cacador = true
			break
	for i in range(1, n + 1):
		var t := turno_mundo + i
		var noite := eh_noite(t)
		var eventos: Array = []
		var antes := membrana.estado_de(valor)
		valor = maxi(0, valor + por_turno)
		var depois := membrana.estado_de(valor)
		if depois.get("id", "") != antes.get("id", ""):
			eventos.append({"id": "membrana", "texto": "Membrana %s" % String(depois.get("nome", "")).to_lower()})
		cont += 2 if noite else 1
		if cont >= a_cada and int(depois.get("nivel_ameaca", 0)) >= 1:
			cont = 0
			eventos.append({"id": "surge", "texto": "algo surge"})
			tem_cacador = true
		if noite and tem_cacador:
			eventos.append({"id": "caca", "texto": "algo caça"})
		if not cacador.is_empty() and not cacador.get("banido", false) and int(cacador.get("volta_em", -1)) == t:
			eventos.append({"id": "cacador", "texto": "ele volta"})   # docs/74
		if valor == 0:
			eventos.append({"id": "rompe", "texto": "o covil se abre"})
		lista.append({"turno": t, "noite": noite, "eventos": eventos})
	return lista


## Progresso do caso (Ato, docs/53): pistas firmes que contam para o relatório, até 2 por
## pergunta de base em aberto. {firmes, necessarias}.
func progresso_do_caso() -> Dictionary:
	if caso == null:
		return {"firmes": 0, "necessarias": 0}
	var firmes := 0
	var necessarias := 0
	for q in caso.perguntas:
		if q.respondida:
			continue
		var precisa := int(q.get("pistas_necessarias", 2))
		necessarias += precisa
		firmes += mini(precisa, caso.indicios_encontrados(String(q.id)).size())
	return {"firmes": firmes, "necessarias": necessarias}


## Rumo do caso (docs/51, IN5): sem pista à vista e com perguntas em aberto, a direção do lugar
## com pista mais perto do grupo, ainda na névoa ("ao norte", "a sudeste"...). "" se há o que
## investigar à vista ou nada a achar.
func rumo_do_caso() -> String:
	if caso == null or caso.perguntas.all(func(q): return q.respondida):
		return ""
	var a := agente_atual()
	if a == null:
		return ""
	var pos := posicao(a)
	var melhor := Vector2i(-999, -999)
	var md := 1 << 20
	for h in mapa.celulas:
		var tipo := String(mapa.conteudo(h).get("tipo", ""))
		if not tipo in ["investigacao", "evento"]:
			continue
		if mapa.revelado(h):
			return ""   # há pista à vista
		var d := Hex.distancia(pos, h)
		if d < md:
			md = d
			melhor = h
	if md == 1 << 20:
		return ""
	return direcao_em_texto(Hex.para_pixel(melhor, 1.0) - Hex.para_pixel(pos, 1.0))


# --- Contato da Pesquisa e mapa de rumores (docs/61, IN5) ------------------------------

## A próxima ligação para a Pesquisa: a pergunta mais fraca do caso (menos traços firmes) e a
## camada seguinte dela. {} se não há o que pedir. Camadas, cada uma mais cara:
##   1 · orientação: qual pergunta pesa menos e para onde há pista sem visita (a ação do turno);
##   2 · cruzamento: um candidato errado que ainda batia sai da lista (ruído: o que caça ouve);
##   3 · ficha: um traço verdadeiro chega por mensagem, como pista firme (a Membrana sente).
func proxima_pesquisa() -> Dictionary:
	if caso == null or encerrada:
		return {}
	var abertas: Array = caso.perguntas.filter(func(q): return not q.respondida)
	abertas.sort_custom(func(x, y): return caso.indicios_encontrados(String(x.id)).size() < caso.indicios_encontrados(String(y.id)).size())
	for q in abertas:
		var pid := String(q.id)
		var camada := int(pesquisa.get(pid, 0)) + 1
		if camada == 2 and _descartavel(pid).is_empty():
			camada = 3   # nada a descartar: vai direto à ficha
		if camada > 3:
			continue
		var cfg: Dictionary = DadosJogo.ler("casos").get("pesquisa", {})
		var c: Dictionary = (cfg.get("camadas", []) as Array)[camada - 1]
		return {"pergunta": pid, "texto_pergunta": String(q.texto), "camada": camada, "titulo": String(c.titulo),
			"ganho": String(c.ganho), "custo": String(c.custo)}
	return {}


## Liga para a Pesquisa (comando "pesquisa"): aplica o custo da camada e devolve a resposta.
## Sem Dados: tudo sai do estado e de hash da semente, igual no online.
func ligar_pesquisa() -> Dictionary:
	var p := proxima_pesquisa()
	var a := agente_atual()
	if p.is_empty() or a == null or ocupado():
		return {"ok": false}
	var pid := String(p.pergunta)
	var cfg: Dictionary = DadosJogo.ler("casos").get("pesquisa", {})
	var texto := ""
	if alarme_falso and not alarme_confirmado:
		# Alarme falso (docs/62): a Pesquisa cruza os dados e nada bate com o paranormal
		if not pode_agir_no_mapa():
			return {"ok": false, "erro": "sem ação neste turno"}
		acao_usada = true
		texto = "A Pesquisa cruzou tudo: nada no sinal bate com o paranormal. Vale olhar com calma o que era."
		_log("[color=#7fd3c7][b]Pesquisa:[/b] %s[/color]" % texto)
		var ev := _evento("alarme_falso")
		evento_pendente = {"hex": posicao(a), "evento": ev, "agente": a}
		evento_aberto.emit(posicao(a), ev, a)
		return {"ok": true, "camada": 1, "titulo": "Orientação", "texto": texto}
	match int(p.camada):
		1:
			if not pode_agir_no_mapa():
				return {"ok": false, "erro": "sem ação neste turno"}
			acao_usada = true
			var rumo := _rumo_de_pista_sem_visita()
			texto = String(cfg.orientacao).format({"pergunta": String(p.texto_pergunta).to_lower(),
				"rumo": (String(cfg.orientacao_rumo) % rumo) if rumo != "" else String(cfg.orientacao_sem_rumo)})
		2:
			var lista := _descartavel(pid)
			var c: Dictionary = lista[absi(hash("%d|pesquisa|%s" % [semente, pid])) % lista.size()]
			var q := caso.pergunta(pid)
			var desc: Array = q.get("descartados", [])
			desc.append(String(c.id))
			q.descartados = desc
			texto = String(cfg.cruzamento) % String(c.nome)
			_turnos_sem_surgimento += 1
			_cacar()   # ruído: o que caça ouve a ligação
			texto += " " + String(cfg.ruido)
		3:
			var pista := caso.registrar_pista(String(cfg.ficha), pid, "pesquisa")
			_anotar_rumor(posicao(a))
			pistas += 1
			membrana.alterar(int(cfg.get("membrana", -5)), "pesquisa")
			texto = String(pista.texto) + " " + String(cfg.membrana_texto)
	pesquisa[pid] = int(p.camada)
	_log("[color=#7fd3c7][b]Pesquisa (%s):[/b] %s[/color]" % [String(p.titulo).to_lower(), texto])
	return {"ok": true, "camada": int(p.camada), "titulo": p.titulo, "texto": texto}


## Candidatos errados que ainda batem com os traços firmes (a camada 2 tira um deles).
func _descartavel(pid: String) -> Array:
	var certo := String(caso.verdadeiro(pid).get("id", ""))
	return caso.compativeis(pid).filter(func(c): return String(c.id) != certo)


## Para onde fica o lugar com pista mais perto ainda sem visita, visto ou não ("" se nenhum).
func _rumo_de_pista_sem_visita() -> String:
	var a := agente_atual()
	if a == null:
		return ""
	var pos := posicao(a)
	var melhor := Vector2i.ZERO
	var md := 1 << 20
	for h in mapa.celulas:
		if not String(mapa.conteudo(h).get("tipo", "")) in ["investigacao", "evento"]:
			continue
		var d := Hex.distancia(pos, h)
		if d < md:
			md = d
			melhor = h
	return "" if md == 1 << 20 else ("aqui perto" if md <= 1 else direcao_em_texto(Hex.para_pixel(melhor, 1.0) - Hex.para_pixel(pos, 1.0)))


func _anotar_rumor(h: Vector2i) -> void:
	if not [h.x, h.y] in rumores:
		rumores.append([h.x, h.y])


## O "?" do mapa de rumores (docs/61): com duas pistas firmes achadas em lugares diferentes,
## uma região de raio 3 em volta de um ponto perto do covil; com três, raio 2; com quatro ou
## mais, raio 1. O covil está sempre dentro dela. {} sem pistas o bastante ou com o covil já
## localizado. {centro: Vector2i, raio: int, origens: [Vector2i]}.
func regiao_dos_rumores() -> Dictionary:
	var obj := mapa.encontrar("objetivo")
	if caso == null or not mapa.tem(obj) or rumores.size() < 2 or caso.pergunta("onde").get("respondida", false):
		return {}
	var raio := 3 if rumores.size() == 2 else (2 if rumores.size() == 3 else 1)
	var perto: Array = mapa.celulas.keys().filter(func(h): return Hex.distancia(h, obj) <= raio - 1)
	perto.sort()
	var centro: Vector2i = perto[absi(hash("%d|rumor|%d" % [semente, raio])) % perto.size()] if not perto.is_empty() else obj
	var origens: Array = rumores.map(func(r): return Vector2i(int(r[0]), int(r[1])))
	return {"centro": centro, "raio": raio, "origens": origens}


## "ao norte", "a nordeste"... para um vetor na tela (y para baixo é o sul).
static func direcao_em_texto(v: Vector2) -> String:
	if v.length() < 0.01:
		return "por perto"
	var ang := fposmod(rad_to_deg(atan2(-v.y, v.x)), 360.0)
	var nomes := ["a leste", "a nordeste", "ao norte", "a noroeste", "a oeste", "a sudoeste", "ao sul", "a sudeste"]
	return nomes[int(round(ang / 45.0)) % 8]


## Membrana Rompendo: o Outro Lado ataca a mente de todos (Vontade ou perde Sanidade).
func _ataque_a_sanidade() -> void:
	var cfg: Dictionary = DadosJogo.ler("membrana").get("medo", {}).get("ataque_sanidade", {})
	if cfg.is_empty() or membrana.nivel_ameaca() < int(cfg.nivel):
		return
	for a in agentes:
		if a.esta_fora_de_combate():
			continue
		var t := a.testar(dados, String(cfg.pericia), int(cfg.dt))
		if t == null or not t.sucesso:
			var antes := a.san
			a.sofrer_dano_mental(dados.rolar_expressao(String(cfg.dano)))
			_log("[color=#b98ae6]O Medo sussurra para %s: −%d de Sanidade.[/color]" % [a.nome, antes - a.san])
	_verificar_derrota()


## Uma nova ameaça surge perto de um agente vivo, com nível até o da Membrana.
func _surgir_ameaca() -> void:
	var vivos := agentes.filter(func(a): return not a.esta_fora_de_combate())
	if vivos.is_empty():
		return
	var alvo: Agente = vivos[dados.rolar(vivos.size()) - 1]
	var nivel := membrana.nivel_ameaca()
	var opcoes := encontros_para_surgir(nivel, vivos)
	var candidatos: Array[Vector2i] = []
	for h in Hex.area(posicao(alvo), 3):
		if Hex.distancia(h, posicao(alvo)) >= 2 and mapa.passavel(h) and mapa.conteudo(h).is_empty() and agentes_em(h).is_empty():
			candidatos.append(h)
	if candidatos.is_empty() or opcoes.is_empty():
		return
	var h := candidatos[dados.rolar(candidatos.size()) - 1]
	var medo: Dictionary = DadosJogo.ler("membrana").get("medo", {}).get("manifestacoes", {})
	var eventos_medo: Array = DadosJogo.ler("eventos").get("eventos_medo", [])
	if not medo.is_empty() and nivel >= int(medo.nivel) and not eventos_medo.is_empty() and dados.rolar(int(medo.chance_em)) == 1:
		var ev: Dictionary = eventos_medo[dados.rolar(eventos_medo.size()) - 1]
		mapa.definir_conteudo(h, {"tipo": "evento", "evento": ev.id})
		mapa.revelar(h, 0)
		_log("[color=#b98ae6]O Medo se manifesta perto de %s: %s.[/color]" % [alvo.nome, ev.titulo])
		return
	var e: Dictionary = opcoes[dados.rolar(opcoes.size()) - 1]
	mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": e.id, "caca": true})   # caça à noite (docs/53)
	mapa.revelar(h, 0)
	_log("[color=#b98ae6]Com a Membrana %s, algo surge perto de %s: %s.[/color]" % [membrana.estado().nome.to_lower(), alvo.nome, e.nome])


func _verificar_derrota() -> void:
	if encerrada:
		return
	if agentes.is_empty() or agentes.all(func(a): return a.esta_fora_de_combate()):
		_encerrar(false)


func _encerrar(venceu: bool) -> void:
	if encerrada:
		return
	encerrada = true
	vitoria = venceu
	_log("[b]%s[/b]" % ("MISSÃO CUMPRIDA" if venceu else "MISSÃO FRACASSADA"))
	missao_encerrada.emit(venceu)


# --- Salvar / carregar ------------------------------------------------------

## Os agentes são referenciados pelo id (eles mesmos são salvos pela Carreira).
func para_dicionario() -> Dictionary:
	var pos: Dictionary = {}
	for a in posicoes:
		pos[a.id] = [posicoes[a].x, posicoes[a].y]
	var ev: Dictionary = {}
	if not evento_pendente.is_empty():
		ev = {"hex": [evento_pendente.hex.x, evento_pendente.hex.y], "evento": evento_pendente.evento.id, "agente": evento_pendente.agente.id}
	var enc: Dictionary = {}
	if not encontro_pendente.is_empty():
		enc = {"hex": [encontro_pendente.hex.x, encontro_pendente.hex.y], "encontro": encontro_pendente.encontro, "chefe": encontro_pendente.chefe,
			"semente": int(encontro_pendente.semente), "cacador": encontro_pendente.get("cacador", false)}
	var descansos: Dictionary = {}
	for a in _descansou:
		descansos[a.id] = [_descansou[a].x, _descansou[a].y]
	return {
		"semente": semente, "rng": str(dados.estado()), "mapa": mapa.para_dicionario(), "membrana": membrana.para_dicionario(),
		"opcoes": opcoes.duplicate(), "agentes": agentes.map(func(a): return a.id),
		"agentes_iniciais": agentes_iniciais.map(func(a): return a.id),
		"mortos": mortos.map(func(a): return a.id), "resgatados": resgatados.map(func(a): return a.id),
		"inocentes_mortos": inocentes_mortos,
		"posicoes": pos, "turno_mundo": turno_mundo, "indice": indice,
		"movimento_restante": movimento_restante, "movimento_rolado": movimento_rolado, "acao_usada": acao_usada,
		"pode_escalar": pode_escalar, "covil_localizado": covil_localizado,
		"evento_pendente": ev, "encontro_pendente": enc, "reforcos": reforcos, "pistas": pistas, "cacador": cacador.duplicate(),
		"caso": caso.para_dicionario() if caso != null else {}, "modificador_chefe": modificador_chefe,
		"investigacao_pendente": {"hex": [investigacao_pendente.hex.x, investigacao_pendente.hex.y], "cena": investigacao_pendente.cena,
			"semente": int(investigacao_pendente.semente)} if not investigacao_pendente.is_empty() else {},
		"turnos_sem_surgimento": _turnos_sem_surgimento, "alivio": alivio, "testemunhas_vistas": testemunhas_vistas.duplicate(true),
		"pesquisa": pesquisa.duplicate(), "rumores": rumores.duplicate(true),
		"sinal": sinal.duplicate(), "alarme_confirmado": alarme_confirmado, "varredura": varredura,
		"credencial": credencial.duplicate(), "presos": presos.duplicate(true),
		"rituais_usados_no_mapa": rituais_usados_no_mapa.duplicate(), "bonus_de_ritual": bonus_de_ritual.duplicate(true), "escuta_instalada": escuta_instalada,
		"rastros": rastros.keys().map(func(h): return [h.x, h.y, int(rastros[h])]), "descansos": descansos, "revisaveis": revisaveis.duplicate(true),
		"historico": historico.slice(maxi(0, historico.size() - 300)),
		"encerrada": encerrada, "vitoria": vitoria, "extras": extras.duplicate(true),
	}


## `por_id`: {id: Agente} vindo da Carreira.
static func de_dicionario(ruleset_: Ruleset, d: Dictionary, por_id: Dictionary) -> Missao:
	var m := Missao.new()
	m.ruleset = ruleset_
	m._cfg = DadosJogo.ler("mapa")
	m.semente = int(d.get("semente", 0))
	m.extras = d.get("extras", {})
	m.dados = Dados.new(m.semente)
	m.dados.restaurar_estado(String(d.get("rng", "0")).to_int())
	m.mapa = MapaHex.new(m._cfg.terrenos)
	m.mapa.de_dicionario(d.mapa)
	m.membrana = Membrana.carregar_padrao()
	m.membrana.de_dicionario(d.membrana)
	m.opcoes = d.get("opcoes", m.opcoes)
	for i in d.get("agentes", []):
		if por_id.has(i):
			m.agentes.append(por_id[i])
	for i in d.get("agentes_iniciais", []):
		if por_id.has(i):
			m.agentes_iniciais.append(por_id[i])
	m.inocentes_mortos = int(d.get("inocentes_mortos", 0))
	for i in d.get("mortos", []):
		if por_id.has(i):
			m.mortos.append(por_id[i])
	for i in d.get("resgatados", []):
		if por_id.has(i):
			m.resgatados.append(por_id[i])
	for a in m.agentes_iniciais:
		m._vincular(a)
		m.armas[a] = a.arma()
		var p: Array = d.posicoes.get(a.id, [0, 0])
		m.posicoes[a] = Vector2i(int(p[0]), int(p[1]))
	m.turno_mundo = int(d.get("turno_mundo", 1))
	m.indice = int(d.get("indice", 0))
	m.movimento_restante = int(d.get("movimento_restante", 0))
	m.movimento_rolado = d.get("movimento_rolado", false)
	m.pode_escalar = d.get("pode_escalar", false)
	m.covil_localizado = bool(d.get("covil_localizado", true))   # save antigo: covil como antes
	m.acao_usada = d.get("acao_usada", false)
	m.reforcos = int(d.get("reforcos", 0))
	m.pistas = int(d.get("pistas", 0))
	m._turnos_sem_surgimento = int(d.get("turnos_sem_surgimento", 0))
	m.revisaveis = (d.get("revisaveis", []) as Array).duplicate(true)
	m.alivio = int(d.get("alivio", 0))
	m.testemunhas_vistas = (d.get("testemunhas_vistas", []) as Array).duplicate(true)
	for k in d.get("pesquisa", {}):
		m.pesquisa[String(k)] = int(d.pesquisa[k])
	for r in d.get("rumores", []):
		m.rumores.append([int(r[0]), int(r[1])])
	m.sinal = (d.get("sinal", {}) as Dictionary).duplicate()
	m.alarme_falso = bool(m.sinal.get("alarme_falso", false))
	m.alarme_confirmado = bool(d.get("alarme_confirmado", false))
	m._aplicar_culto_e_subgenero(false)   # o subgênero volta a valer no mapa.json desta missão (docs/71)
	m.varredura = String(d.get("varredura", ""))
	if d.has("credencial"):
		m.credencial = {"nome": String(d.credencial.get("nome", "")), "usos": int(d.credencial.get("usos", 0)),
			"queimada": bool(d.credencial.get("queimada", false)), "limite": int(d.credencial.get("limite", DadosJogo.ler("sinais").credencial.limite))}
	m.presos = (d.get("presos", []) as Array).duplicate(true)
	m.rituais_usados_no_mapa = (d.get("rituais_usados_no_mapa", []) as Array).duplicate()
	m.bonus_de_ritual = (d.get("bonus_de_ritual", {}) as Dictionary).duplicate(true)
	m.escuta_instalada = bool(d.get("escuta_instalada", false))
	m.cacador = (d.get("cacador", {}) as Dictionary).duplicate()
	if not m.cacador.is_empty():
		m.cacador.derrotas = int(m.cacador.get("derrotas", 0))
		m.cacador.volta_em = int(m.cacador.get("volta_em", -1))
		m.cacador.estagio = int(m.cacador.get("estagio", 0))
	for r in d.get("rastros", []):
		m.rastros[Vector2i(int(r[0]), int(r[1]))] = int(r[2])
	for i in d.get("descansos", {}):
		if por_id.has(i):
			var hx: Array = d.descansos[i]
			m._descansou[por_id[i]] = Vector2i(int(hx[0]), int(hx[1]))
	for linha in d.get("historico", []):
		m.historico.append(linha)
	m.encerrada = d.get("encerrada", false)
	m.vitoria = d.get("vitoria", false)
	m.caso = Caso.de_dicionario(d.caso) if not d.get("caso", {}).is_empty() else Caso.gerar(m.dados)
	m.modificador_chefe = float(d.get("modificador_chefe", 0.0))
	var inv: Dictionary = d.get("investigacao_pendente", {})
	if not inv.is_empty():
		m._preparar_investigacao(Vector2i(int(inv.hex[0]), int(inv.hex[1])), inv.cena, int(inv.get("semente", -1)))
	var ev: Dictionary = d.get("evento_pendente", {})
	if not ev.is_empty() and por_id.has(ev.agente):
		m.evento_pendente = {"hex": Vector2i(int(ev.hex[0]), int(ev.hex[1])), "evento": m._evento(ev.evento), "agente": por_id[ev.agente]}
	var enc: Dictionary = d.get("encontro_pendente", {})
	if not enc.is_empty():
		m._contra_o_cacador = bool(enc.get("cacador", false))
		m._preparar_encontro(Vector2i(int(enc.hex[0]), int(enc.hex[1])), enc.encontro, enc.chefe, int(enc.get("semente", -1)))
	return m
