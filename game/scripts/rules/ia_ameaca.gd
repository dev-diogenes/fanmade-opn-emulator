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


## Usa habilidades e rituais antes de atacar. Retorna true se o turno já foi gasto.
static func agir_antes(c: Combate, ser: Ameaca, alvo: Ser) -> bool:
	if ser.mods_cena.has("prendendo"):
		return true   # o succ só segura a vítima
	var adjacente_a_inimigo := false
	if c.grade != null and c.grade.tem(ser):
		for x in c.participantes:
			if x.lado != ser.lado and not x.esta_fora_de_combate() and c.grade.estao_adjacentes(ser, x):
				adjacente_a_inimigo = true
	for h in ser.habilidades:
		if not h.has("acao"):
			continue
		var atingiria := _atingiria(c, ser, h, alvo)
		match h.acao:
			"livre":
				if atingiria > 0:
					c.usar_habilidade(ser, h.id, alvo)
			"movimento":
				var t := String(h.get("tipo", ""))
				if t == "aliados":
					if int(ser.usos.get(h.id, 0)) == 0 and c.participantes.any(func(x): return x != ser and x.lado == ser.lado and not x.esta_fora_de_combate()):
						c.usar_habilidade(ser, h.id)
				elif t in ["marcar", "alvo"]:
					if alvo != null and not ser.mods_cena.has(h.id):
						c.usar_habilidade(ser, h.id, alvo)
				elif h.has("buff"):
					if not ser.rituais_ativos.has(h.id) and ser.mods_cena.get("efeito_" + String(h.get("requer", "")), false):
						c.usar_habilidade(ser, h.id)
				elif h.get("morre", false):
					if ser.tem(Ser.MACHUCADO) and atingiria > 0 and c.usar_habilidade(ser, h.id, alvo).ok:
						return true   # autodestruição
			"padrao":
				if atingiria >= 2 and c.usar_habilidade(ser, h.id, alvo).ok:
					return true   # granada em grupo
			"completa":
				if h.get("requer_agarrado", false):
					for vit in ser.mods_cena.get("agarrando", []):
						if c.usar_habilidade(ser, h.id, vit).ok:
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
