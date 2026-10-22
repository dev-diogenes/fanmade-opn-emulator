class_name IconeItem
extends RefCounted
## Ícone desenhado por código para as etiquetas do Arsenal (docs/23, C5): lâmina, arma de
## fogo, proteção, kit, frasco, componente ritual, granada, munição e pacote. Traço de tinta, como
## carimbo de inventário. Amaldiçoados usam o mesmo ícone em vermelho-sangue.


## Tipo do ícone de um item do ruleset (o dicionário de Ruleset.equipamento).
static func tipo(item: Dictionary) -> String:
	var id := String(item.get("id", ""))
	var t := String(item.get("tipo", ""))
	if id.contains("granada") or id.contains("explosiv") or item.has("explosivo"):
		return "granada"
	if item.get("municao") is Dictionary:
		return "municao"
	if t == "arma" and (id.contains("arco") or id.contains("besta")):
		return "arco"
	if t == "arma":
		return "lamina" if String(item.get("ataque", "corpo_a_corpo")) == "corpo_a_corpo" else "fogo"
	if t == "protecao" or item.has("defesa"):
		return "protecao"
	if id.begins_with("componentes") or item.has("elemento") or String(item.get("grupo", "")) == "paranormal":
		return "componente"
	if item.has("kit") or id.begins_with("kit"):
		return "kit"
	if item.get("uso", {}).has("cura") or item.get("consumivel", false):
		return "frasco"
	return "pacote"


## Os números na etiqueta, depois da categoria e dos espaços: o dano e o crítico da arma, a
## Defesa da proteção, quanto dura a munição, as cargas, o bônus em perícia.
static func resumo(item: Dictionary, ruleset: Ruleset = null) -> String:
	if String(item.get("tipo", "")) == "arma":
		var partes := PackedStringArray(["%s %d/x%d" % [item.get("dano", "?"), int(item.get("margem", 20)), int(item.get("multiplicador", 2))]])
		for chave in [["agil", "ágil"], ["automatica", "automática"], ["recarga", "recarga"]]:
			if item.get(chave[0], false):
				partes.append(chave[1])
		return " · ".join(partes)
	if item.has("defesa"):
		return "Defesa +%d" % int(item.defesa)
	var m = item.get("municao")
	if m is Dictionary:
		if m.get("missao", false):
			return "a missão"
		return "%d cena%s" % [int(m.cenas), "s" if int(m.cenas) > 1 else ""] if m.has("cenas") else "1 disparo"
	if item.has("cargas"):
		return "%d cargas" % int(item.cargas)
	var bonus: Dictionary = item.get("bonus_pericia", {})
	if not bonus.is_empty():
		var p: String = bonus.keys()[0]
		return "+%d %s" % [int(bonus[p]), String(ruleset.pericia(p).get("nome", p)) if ruleset != null else p.capitalize()]
	return ""


## Resumo do efeito para o tooltip: a descrição do item ou, para armas, os números e a regra
## da descrição (p.68). O que ainda não tem efeito no jogo vem dito no fim.
static func efeito(item: Dictionary, ruleset: Ruleset) -> String:
	var texto := String(item.get("descricao", ""))
	if String(item.get("tipo", "")) == "arma" or item.has("dano"):
		var partes := PackedStringArray()
		partes.append("Dano %s" % item.get("dano", "?") + (" (%s com as duas mãos)" % item.dano_duas_maos if item.has("dano_duas_maos") else ""))
		partes.append("crítico %d/x%d" % [int(item.get("margem", 20)), int(item.get("multiplicador", 2))])
		partes.append("corpo a corpo" if String(item.get("ataque", "corpo_a_corpo")) == "corpo_a_corpo" else "alcance %s" % item.get("alcance", "curto"))
		partes.append(String(ruleset.pericia(String(item.get("pericia", "luta"))).get("nome", "Luta")))
		partes.append({"leve": "leve", "uma_mao": "uma mão", "duas_maos": "duas mãos"}.get(String(item.get("empunhadura", "")), ""))
		texto = " · ".join(partes.slice(0, partes.size() if partes[-1] != "" else partes.size() - 1)) + ("\n" + texto if texto != "" else "")
	elif item.has("defesa"):
		texto = "Defesa +%d. %s" % [int(item.defesa), texto]
	if item.has("pendente"):
		texto += "\nAinda sem efeito no jogo: %s." % item.pendente
	return texto


static func desenhar(ci: CanvasItem, t: String, centro: Vector2, r: float, cor: Color) -> void:
	var w := 2.2
	match t:
		"lamina":
			ci.draw_line(centro + Vector2(-r * 0.7, r * 0.7), centro + Vector2(r * 0.75, -r * 0.75), cor, w + 1.0, true)
			ci.draw_line(centro + Vector2(-r * 0.55, r * 0.15), centro + Vector2(-r * 0.15, r * 0.55), cor, w, true)
			ci.draw_line(centro + Vector2(-r * 0.9, r * 0.9), centro + Vector2(-r * 0.6, r * 0.6), cor, w + 2.0, true)
		"fogo":
			ci.draw_rect(Rect2(centro + Vector2(-r * 0.9, -r * 0.35), Vector2(r * 1.7, r * 0.4)), cor)
			ci.draw_colored_polygon(PackedVector2Array([centro + Vector2(-r * 0.5, 0), centro + Vector2(-r * 0.1, 0),
				centro + Vector2(-r * 0.25, r * 0.8), centro + Vector2(-r * 0.7, r * 0.8)]), cor)
			ci.draw_arc(centro + Vector2(r * 0.05, r * 0.2), r * 0.22, 0, PI, 8, cor, w * 0.7, true)
		"arco":
			ci.draw_arc(centro + Vector2(-r * 0.35, 0), r * 0.9, -PI * 0.42, PI * 0.42, 12, cor, w + 0.6, true)
			var ponta := Vector2(cos(PI * 0.42), sin(PI * 0.42)) * r * 0.9
			ci.draw_line(centro + Vector2(-r * 0.35, 0) + Vector2(ponta.x, -ponta.y), centro + Vector2(-r * 0.35, 0) + ponta, cor, w * 0.5, true)
			ci.draw_line(centro + Vector2(-r * 0.6, 0), centro + Vector2(r * 0.9, 0), cor, w * 0.8, true)
		"protecao":
			var pts := PackedVector2Array([centro + Vector2(-r * 0.75, -r * 0.8), centro + Vector2(r * 0.75, -r * 0.8),
				centro + Vector2(r * 0.7, r * 0.1), centro + Vector2(0, r * 0.9), centro + Vector2(-r * 0.7, r * 0.1), centro + Vector2(-r * 0.75, -r * 0.8)])
			ci.draw_polyline(pts, cor, w, true)
			ci.draw_line(centro + Vector2(0, -r * 0.8), centro + Vector2(0, r * 0.85), cor, w * 0.7, true)
		"kit":
			ci.draw_rect(Rect2(centro + Vector2(-r * 0.85, -r * 0.4), Vector2(r * 1.7, r * 1.2)), cor, false, w)
			ci.draw_arc(centro + Vector2(0, -r * 0.4), r * 0.35, PI, TAU, 8, cor, w, true)
			ci.draw_line(centro + Vector2(0, -r * 0.05), centro + Vector2(0, r * 0.55), cor, w, true)
			ci.draw_line(centro + Vector2(-r * 0.3, r * 0.25), centro + Vector2(r * 0.3, r * 0.25), cor, w, true)
		"frasco":
			ci.draw_arc(centro + Vector2(0, r * 0.3), r * 0.55, 0, TAU, 16, cor, w, true)
			ci.draw_rect(Rect2(centro + Vector2(-r * 0.2, -r * 0.85), Vector2(r * 0.4, r * 0.65)), cor, false, w)
			ci.draw_line(centro + Vector2(-r * 0.35, r * 0.35), centro + Vector2(r * 0.35, r * 0.35), cor, w * 0.7, true)
		"componente":
			ci.draw_arc(centro, r * 0.85, 0, TAU, 20, cor, w, true)
			var tri := PackedVector2Array()
			for k in 4:
				tri.append(centro + Vector2.UP.rotated(TAU * k / 3.0) * r * 0.7)
			ci.draw_polyline(tri, cor, w * 0.8, true)
			ci.draw_circle(centro, r * 0.12, cor)
		"municao":
			for k in 3:
				var x := centro.x + (k - 1) * r * 0.55
				ci.draw_rect(Rect2(Vector2(x - r * 0.16, centro.y - r * 0.35), Vector2(r * 0.32, r * 0.95)), cor, false, w * 0.8)
				ci.draw_arc(Vector2(x, centro.y - r * 0.35), r * 0.16, PI, TAU, 8, cor, w * 0.8, true)
		"granada":
			ci.draw_arc(centro + Vector2(0, r * 0.2), r * 0.6, 0, TAU, 16, cor, w, true)
			ci.draw_rect(Rect2(centro + Vector2(-r * 0.2, -r * 0.65), Vector2(r * 0.4, r * 0.25)), cor)
			ci.draw_arc(centro + Vector2(r * 0.35, -r * 0.6), r * 0.25, -PI * 0.5, PI * 0.6, 8, cor, w * 0.7, true)
		_:
			ci.draw_rect(Rect2(centro - Vector2(r, r) * 0.75, Vector2(r, r) * 1.5), cor, false, w)
			ci.draw_line(centro + Vector2(-r * 0.75, 0), centro + Vector2(r * 0.75, 0), cor, w * 0.7, true)
			ci.draw_line(centro + Vector2(0, -r * 0.75), centro + Vector2(0, r * 0.75), cor, w * 0.7, true)
