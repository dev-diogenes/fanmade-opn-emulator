class_name Memorial
extends RefCounted
## Parede de memória (docs/59, AG1 do relatório): na Base, uma foto de luto para cada agente
## que caiu, com a vela acesa, o apelido, a cidade, o NEX e a patente de quando caiu, o lugar
## do caso, a data, a causa, o objeto que levava e o último registro em que o nome aparece.
## O mesmo cartão é a despedida na volta da missão (CerimoniaNex).
##   Memorial.parede(carreira.memorial)   Memorial.cartao(entrada)

const LARGURA := 220.0
const ULTIMO_MAX := 140


static func parede(entradas: Array) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", Tema.ESPACO_M)
	var t := Label.new()
	t.text = "Parede de memória"
	t.theme_type_variation = "Titulo"
	t.add_theme_font_size_override("font_size", Tema.FONTE_G + 4)
	v.add_child(t)
	var sub := Label.new()
	sub.text = "Quem a Ordem perdeu para o Outro Lado. As velas não se apagam." if not entradas.is_empty() \
		else "Ninguém na parede, ainda. Que continue assim."
	sub.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	v.add_child(sub)
	var fluxo := HFlowContainer.new()
	fluxo.add_theme_constant_override("h_separation", Tema.ESPACO_GG)
	fluxo.add_theme_constant_override("v_separation", Tema.ESPACO_GG)
	fluxo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(fluxo)
	for i in range(entradas.size() - 1, -1, -1):   # quem caiu por último fica primeiro
		fluxo.add_child(cartao(entradas[i]))
	return v


## O cartão de um agente que caiu: a foto de luto e a vela à esquerda, o que se sabe à direita.
static func cartao(e: Dictionary) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(14, 12)))
	p.theme = Tema.tema_papel()
	p.custom_minimum_size = Vector2(LARGURA * 2.0, 0)
	p.rotation_degrees = -0.6 + float(absi(hash(String(e.get("nome", "")))) % 12) / 10.0   # cada um torto do seu jeito
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", Tema.ESPACO_M)
	p.add_child(h)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	var foto := FotoAgente.new()
	foto.luto = true
	var nome := String(e.get("nome", ""))
	if String(e.get("classe", "")) != "":
		foto.mostrar(String(e.classe), String(e.get("aparencia", "")), int(e.get("tom", 0)), hash(nome))
	foto.legenda = nome
	col.add_child(foto)
	var vela := Vela.new()
	vela.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(vela)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var titulo := _linha(nome + (" “%s”" % e.apelido if String(e.get("apelido", "")) != "" else ""), Tema.TINTA)
	titulo.add_theme_font_size_override("font_size", Tema.FONTE_G)
	var ft := Tema.fonte_titulo()
	if ft != null:
		titulo.add_theme_font_override("font", ft)
	v.add_child(titulo)
	if e.has("nex"):
		v.add_child(_linha("NEX %d%%%s" % [int(e.nex), (" · " + String(e.patente)) if String(e.get("patente", "")) != "" else ""], Color(Tema.TINTA, 0.8)))
	if String(e.get("cidade", "")) != "":
		v.add_child(_linha("De %s." % e.cidade, Color(Tema.TINTA, 0.8)))
	var onde := "Missão %d" % int(e.get("missao", 0))
	if String(e.get("lugar", "")) != "":
		onde += " · " + String(e.lugar)
	v.add_child(_linha(onde, Color(Tema.TINTA, 0.8)))
	var causa := String(e.get("causa", ""))
	causa = causa.left(1).to_upper() + causa.substr(1)
	if String(e.get("data", "")) != "":
		causa += " · " + data_br(String(e.data))
	v.add_child(_linha(causa, Tema.SANGUE))
	if String(e.get("objeto", "")) != "":
		v.add_child(_linha("Levava %s." % e.objeto, Color(Tema.TINTA, 0.85)))
	var ultimo := String(e.get("ultimo", ""))
	if ultimo != "":
		if ultimo.length() > ULTIMO_MAX:
			ultimo = ultimo.left(ULTIMO_MAX - 1).strip_edges() + "…"
		var u := _linha("Último registro: «%s»" % ultimo, Color(Tema.TINTA, 0.7))
		u.add_theme_font_size_override("font_size", Tema.FONTE_P)
		var maquina := Tema.fonte_maquina()
		if maquina != null:
			u.add_theme_font_override("font", maquina)
		v.add_child(u)
	return p


## A despedida na volta (CerimoniaNex): estreita, na fileira de quem voltou. A foto de luto,
## "em memória", a causa, o que levava e a vela.
static func cartao_despedida(e: Dictionary) -> Control:
	var c := VBoxContainer.new()
	c.custom_minimum_size = Vector2(190, 0)
	c.add_theme_constant_override("separation", 4)
	var foto := FotoAgente.new()
	foto.luto = true
	foto.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var nome := String(e.get("nome", ""))
	if String(e.get("classe", "")) != "":
		foto.mostrar(String(e.classe), String(e.get("aparencia", "")), int(e.get("tom", 0)), hash(nome))
	foto.legenda = nome + (" “%s”" % e.apelido if String(e.get("apelido", "")) != "" else "")
	c.add_child(foto)
	var t := _linha("EM MEMÓRIA", Tema.SANGUE)
	t.custom_minimum_size = Vector2(190, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", Tema.FONTE_M + 2)
	var ft := Tema.fonte_titulo()
	if ft != null:
		t.add_theme_font_override("font", ft)
	c.add_child(t)
	var causa := String(e.get("causa", ""))
	for texto in [causa.left(1).to_upper() + causa.substr(1) + ".", ("Levava %s." % e.objeto) if String(e.get("objeto", "")) != "" else ""]:
		if texto == "" or texto == ".":
			continue
		var l := _linha(texto, Color(Tema.TINTA, 0.85))
		l.custom_minimum_size = Vector2(190, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l)
	var vela := Vela.new()
	vela.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.add_child(vela)
	return c


## "2026-10-22" -> "22/10/2026".
static func data_br(iso: String) -> String:
	var partes := iso.split("-")
	return "%s/%s/%s" % [partes[2], partes[1], partes[0]] if partes.size() == 3 else iso


static func _linha(texto: String, cor: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(LARGURA, 0)
	l.add_theme_color_override("font_color", cor)
	return l
