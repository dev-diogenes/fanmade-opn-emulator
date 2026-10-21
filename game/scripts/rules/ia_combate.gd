class_name IaCombate
extends RefCounted
## IA de combate para quem não é controlado pelo jogador (ameaças, agentes no automático e
## hipnotizados): escolhe o alvo, usa habilidades e rituais, anda e ataca. Lógica pura,
## usada pela arena e pelo simulador de combate do piloto automático.


static func jogar(c: Combate, ser: Ser, armas: Dictionary) -> void:
	var alvo := IaAmeaca.alvo_preferido(c, ser, inimigo_mais_proximo(c, ser))
	if alvo == null:
		return
	var arma: Dictionary = armas.get(ser, c.ruleset.arma("desarmado"))
	if ser is Ameaca:
		if IaAmeaca.agir_antes(c, ser as Ameaca, alvo) or c.encerrado:
			return
		if IaAmeaca.so_se_move(ser):
			var perto := c.grade.aproximar(ser, alvo, ser.deslocamento_quadrados())
			if perto != c.grade.posicao(ser):
				c.mover(ser, perto)
			return
		arma = IaAmeaca.escolher_arma(c, ser, alvo, arma)
	if ser is Agente:
		if ser.lado == "agentes" and _tentar_enigma(c, ser as Agente):
			return
		for rid in (ser as Agente).rituais:
			var rr := c.ruleset.ritual(rid)
			if rr.get("implementado", false) and rr.efeitos[0].tipo == "dano" and not rr.efeitos[0].has("area") and c.pode_conjurar(ser, rid, alvo) == "":
				c.conjurar(ser, rid, alvo)
				return
	if not pode_atacar(c, ser, alvo, arma):
		var destino := c.grade.aproximar(ser, alvo, ser.deslocamento_quadrados())
		if arma.get("ataque", "") != "corpo_a_corpo" and c.grade.em_alcance(ser, alvo, arma.get("alcance", "curto")) and c.grade.cobertura(ser, alvo) != "total":
			destino = c.grade.posicao(ser)   # atirador já em alcance: não precisa andar (atrás de cobertura total, anda)
		if destino != c.grade.posicao(ser):
			c.mover(ser, destino)
	if pode_atacar(c, ser, alvo, arma) and not c.encerrado:
		if alvo is Agente and alvo.treinado_em("reflexos"):
			c.declarar_reacao(alvo, "esquiva")
		c.agredir(ser, alvo, arma)


## O que a IA provavelmente fará na vez deste ser (docs/21, C3), para a faixa da vez:
## {"alvo": Ser ou null, "acao": "atacar" | "aproximar" | ""}. Mesma escolha de alvo de `jogar`;
## habilidades usadas antes do ataque podem mudar o plano (é uma intenção, não uma promessa).
static func intencao(c: Combate, ser: Ser, armas: Dictionary) -> Dictionary:
	if c.grade == null or not c.grade.tem(ser):
		return {"alvo": null, "acao": ""}
	var alvo := IaAmeaca.alvo_preferido(c, ser, inimigo_mais_proximo(c, ser))
	if alvo == null:
		return {"alvo": null, "acao": ""}
	var arma: Dictionary = armas.get(ser, c.ruleset.arma("desarmado"))
	if IaAmeaca.so_se_move(ser):
		return {"alvo": alvo, "acao": "aproximar"}
	return {"alvo": alvo, "acao": "atacar" if pode_atacar(c, ser, alvo, arma) else "aproximar"}


## Agentes no automático gastam a ação com o Enigma de Medo enquanto houver uma criatura
## protegida por ele (sem isso, um combate contra a Sombra Sussurrante nunca termina).
static func _tentar_enigma(c: Combate, ag: Agente) -> bool:
	for s in c.participantes:
		if not s is Ameaca or s.esta_fora_de_combate() or s.lado == ag.lado:
			continue
		var am := s as Ameaca
		if not am.enigma_pendente() or am.enigma.get("tipo", "") == "acumular_dano":
			continue
		# Enigma que só enfraquece (a criatura já sofre dano): só vale a ação de quem é treinado
		if not _enigma_protege(am) and not am.etapa_atual().get("pericias", ["ocultismo"]).any(func(per): return ag.treinado_em(per)):
			continue
		if am.enigma.get("tipo", "") == "temporario" and (am.mods_cena.has("visivel_ate") or c.dados.rolar(2) == 1):
			continue
		if c.acoes_restantes(ag).padrao > 0 and c.decifrar_enigma(ag, am) != null:
			return true
	return false


## O enigma impede o dano (imunidade até ser resolvido)?
static func _enigma_protege(am: Ameaca) -> bool:
	var ef = am.enigma.get("efeito", "remove_imunidade")
	return ef is String or (ef is Dictionary and ef.get("remove_imunidade", true))


static func inimigo_mais_proximo(c: Combate, ser: Ser) -> Ser:
	var melhor: Ser = null
	var melhor_d := 1 << 30
	for outro in c.participantes:
		if outro.lado == ser.lado or outro.esta_fora_de_combate() or not c.grade.tem(outro):
			continue
		var d := c.grade.distancia_entre(ser, outro)
		if d < melhor_d:
			melhor = outro
			melhor_d = d
	return melhor


static func pode_atacar(c: Combate, ser: Ser, alvo: Ser, arma: Dictionary) -> bool:
	if c.acoes_restantes(ser).padrao <= 0 or (alvo.esta_fora_de_combate() and not alvo.tem(Ser.POCA)):
		return false
	if arma.get("ataque", "corpo_a_corpo") == "corpo_a_corpo":
		return c.grade.estao_adjacentes(ser, alvo)
	return c.grade.faixa_de_alcance(ser, alvo, arma.get("alcance", "curto")) != "fora" and c.grade.cobertura(ser, alvo) != "total"
