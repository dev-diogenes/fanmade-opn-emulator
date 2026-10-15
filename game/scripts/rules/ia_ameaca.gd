class_name IaAmeaca
extends RefCounted
## Decisões simples das ameaças no combate: qual arma usar e quando usar as habilidades
## da ficha (cap. 7) ou conjurar rituais (cultistas). Lógica pura, usada pela arena.


## Arma para atacar o alvo: corpo a corpo se estiver adjacente; à distância se o alvo estiver
## em alcance; senão, a de corpo a corpo (para se aproximar).
static func escolher_arma(c: Combate, ser: Ser, alvo: Ser, padrao: Dictionary) -> Dictionary:
	var lista: Array = (ser as Ameaca).ataques if ser is Ameaca and not (ser as Ameaca).ataques.is_empty() else [padrao]
	var corpo: Dictionary = {}
	var distancia: Dictionary = {}
	for a in lista:
		if a.get("ataque", "corpo_a_corpo") == "corpo_a_corpo":
			if corpo.is_empty():
				corpo = a
		elif distancia.is_empty():
			distancia = a
	if c.grade == null or alvo == null or not c.grade.tem(ser) or not c.grade.tem(alvo):
		return corpo if not corpo.is_empty() else distancia
	if not corpo.is_empty() and c.grade.estao_adjacentes(ser, alvo):
		return corpo
	if not distancia.is_empty() and c.grade.faixa_de_alcance(ser, alvo, distancia.get("alcance", "curto")) != "fora":
		return distancia
	return corpo if not corpo.is_empty() else distancia


## Alvo que a ameaça persegue: o escutado vai atrás de quem toca a melodia; o ocioso, do seu alvo.
static func alvo_preferido(c: Combate, ser: Ser, padrao: Ser) -> Ser:
	if ser is Ameaca:
		var am := ser as Ameaca
		var dele = am.mods_cena.get("alvo_ocioso")
		if dele != null and not dele.esta_fora_de_combate():
			return dele
		if am.tem_hab("multiplicacao_melodica") and c._melodia_quem != null and not c._melodia_quem.esta_fora_de_combate():
			return c._melodia_quem
	return padrao


## Usa habilidades e rituais antes de atacar. Retorna true se o turno já foi gasto.
static func agir_antes(c: Combate, ser: Ameaca, alvo: Ser) -> bool:
	if ser.mods_cena.has("prendendo"):
		return true   # o succ só segura a vítima
	if ser.tem_hab("consumir") and int(ser.mods_cena.get("flores", 0)) < 7 and c.usar_habilidade(ser, "consumir").ok:
		return true   # a Dama consome os corpos que encontra
	if ser.tem_hab("comportamento_erratico"):
		if ser.habilidade("comportamento_erratico").get("tipo", "") == "erratico_simples":
			c.comportamento_anarquico(ser)
		else:
			c.comportamento_erratico(ser)   # o anomiático não planeja: rola a tabela
		return true
	if ser.tem_hab("sempre_presente") and (ser.mods_cena.get("alvo_ocioso") == null or ser.mods_cena.alvo_ocioso.esta_fora_de_combate()):
		c._escolher_alvo_ocioso(ser)
	if ser.tem_hab("instinto_mortal") and ser.tem(Ser.MACHUCADO) and ser.tem_hab("hipnose") and alvo != null:
		c.usar_habilidade(ser, "hipnose", alvo, null, true)   # machucado: Hipnose como ação livre
	var adjacente_a_inimigo := false
	if c.grade != null and c.grade.tem(ser):
		for x in c.participantes:
			if x.lado != ser.lado and not x.esta_fora_de_combate() and c.grade.estao_adjacentes(ser, x):
				adjacente_a_inimigo = true
	for h in ser.habilidades:
		if not h.has("acao"):
			continue
		var atingiria := _atingiria(c, ser, h, alvo)
		var t_h := String(h.get("tipo", ""))
		var alvo_h := alvo
		if h.has("requer_condicao"):
			alvo_h = null
			for x in c.participantes:
				if x.mods_cena.get("asfixiado_por") == ser and x.tem(h.requer_condicao):
					alvo_h = x
			if alvo_h == null:
				continue
		match h.acao:
			"livre":
				if t_h == "teleporte_alvo" or atingiria > 0:
					c.usar_habilidade(ser, h.id, alvo)
			"movimento":
				var t := String(h.get("tipo", ""))
				if t == "aliados":
					if int(ser.usos.get(h.id, 0)) == 0 and c.participantes.any(func(x): return x != ser and x.lado == ser.lado and not x.esta_fora_de_combate()):
						c.usar_habilidade(ser, h.id)
				elif t in ["marcar", "alvo"]:
					if alvo_h != null and not ser.mods_cena.has(h.id):
						c.usar_habilidade(ser, h.id, alvo_h)
				elif t == "teleporte":
					if alvo != null and c.grade != null and not c.grade.estao_adjacentes(ser, alvo):
						c.usar_habilidade(ser, h.id, alvo)
				elif h.has("buff"):
					if not ser.rituais_ativos.has(h.id) and ser.mods_cena.get("efeito_" + String(h.get("requer", "")), false):
						c.usar_habilidade(ser, h.id)
				elif h.get("morre", false):
					if ser.tem(Ser.MACHUCADO) and atingiria > 0 and c.usar_habilidade(ser, h.id, alvo).ok:
						return true   # autodestruição
			"padrao":
				if t_h == "invocar":
					if int(ser.usos.get(h.id, 0)) == 0 and c.usar_habilidade(ser, h.id).ok:
						return true
					continue
				if t_h == "alvo":
					if alvo != null and not alvo.mods_cena.has("hipnotizado_por") and not alvo.tem(String(h.get("condicao", "_"))) and (not h.has("hipnose") or c.dados.rolar(2) == 1):
						if c.usar_habilidade(ser, h.id, alvo).ok:
							return true
				elif atingiria >= 2 and c.usar_habilidade(ser, h.id, alvo).ok:
					return true   # granada em grupo
			"completa":
				if h.get("requer_agarrado", false):
					for vit in ser.mods_cena.get("agarrando", []):
						if c.usar_habilidade(ser, h.id, vit).ok:
							return true
					continue
				if t_h in ["alvo", "manobra_ataques", "dois_ataques_agarra"]:
					if alvo != null and c.usar_habilidade(ser, h.id, alvo).ok:
						return true
					continue
				if not adjacente_a_inimigo and atingiria > 0 and c.dados.rolar(2) == 1 and c.usar_habilidade(ser, h.id, alvo).ok:
					return true
	if not ser.conjurador.is_empty() and alvo != null and c.rodada % 2 == 1:
		for rid in ser.conjurador.get("rituais", []):
			var r := c.ruleset.ritual(rid)
			if not r.get("implementado", false) or not r.efeitos[0].tipo in ["dano", "purgatorio"]:
				continue
			if r.efeitos[0].has("area"):
				# Ritual de área: só quando pega 2+ inimigos e nenhum aliado
				var inimigos := 0
				var aliados := 0
				for x in c.grade.seres_em(c._celulas_do_efeito(ser, c.efeito_do_ritual(rid), alvo, {})) if c.grade != null else []:
					if x.esta_fora_de_combate():
						continue
					if x.lado == ser.lado:
						aliados += 1
					else:
						inimigos += 1
				if inimigos < 2 or aliados > 0:
					continue
				var cat := c._categoria(String(r.get("alcance", "")))
				if Grade.ALCANCES.has(cat) and c.grade.distancia_entre(ser, alvo) > int(Grade.ALCANCES[cat]):
					continue
			if c.conjurar_ameaca(ser, rid, alvo).ok:
				return true
	return false


## Enxames não atacam: só chegam perto (o dano vem no fim do turno).
static func so_se_move(ser: Ser) -> bool:
	return ser is Ameaca and (ser as Ameaca).ataques.is_empty()


## Quantos inimigos uma habilidade de área atingiria agora.
static func _atingiria(c: Combate, ser: Ameaca, h: Dictionary, alvo: Ser) -> int:
	if not h.has("area"):
		return 0
	if c.grade == null or not c.grade.tem(ser):
		return 1
	var origem := c.grade.posicao(ser)
	var ponto := c.grade.posicao(alvo) if alvo != null and c.grade.tem(alvo) else origem
	if h.area.forma == "esfera" and h.has("alcance") and Grade.distancia(origem, ponto) > int(Grade.ALCANCES.get(h.alcance, 6)):
		return 0
	var n := 0
	for x in c.grade.seres_em(c.grade.celulas_da_area(String(h.area.forma), origem, ponto, float(h.area.get("raio", h.area.get("comprimento", 1.5))))):
		if x.lado != ser.lado and not x.esta_fora_de_combate():
			n += 1
	return n
