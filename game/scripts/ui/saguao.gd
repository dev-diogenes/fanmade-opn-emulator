extends Control
## Saguão do cliente online (Fase 8.2): enquanto o host está na Base, quem entrou na sessão
## espera aqui e vê os jogadores, os agentes (e de quem é cada um) e a última missão.
## Quando o host começa uma missão, o estado chega e o Jogo troca de cena sozinho.

var _jogo: Node
var _lbl_status: Label
var _info: RichTextLabel


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	_montar()
	if _jogo != null:
		_jogo.saguao_mudou.connect(_atualizar)
	_atualizar()


func _montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())
	var margem := MarginContainer.new()
	margem.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 24)
	add_child(margem)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 10)
	margem.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Sessão online"
	titulo.theme_type_variation = "Titulo"
	caixa.add_child(titulo)
	_lbl_status = Label.new()
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_status.add_theme_color_override("font_color", Tema.INFO)
	caixa.add_child(_lbl_status)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caixa.add_child(_info)
	var sair := Button.new()
	sair.text = "Sair da sessão"
	sair.pressed.connect(_sair)
	caixa.add_child(sair)


func _atualizar() -> void:
	if not is_inside_tree():
		return
	var info: Dictionary = _jogo.saguao_info if _jogo != null else {}
	var aviso: String = _jogo.aviso_rede if _jogo != null else ""
	_lbl_status.text = String(info.get("status", "Conectando…")) + ("\n" + aviso if aviso != "" else "")
	var linhas: Array[String] = []
	var meu: int = _jogo.rede.meu_peer() if _jogo != null else 1
	if not info.get("jogadores", []).is_empty():
		linhas.append("[b]Jogadores[/b]")
		for j in info.jogadores:
			linhas.append("  " + String(j))
	if String(info.get("mestre", "")) != "":
		linhas.append("[b]Mestre:[/b] %s" % info.mestre)
	if not info.get("agentes", []).is_empty():
		linhas.append("")
		linhas.append("[b]Agentes da carreira do host[/b]")
		for a in info.agentes:
			var seu: bool = int(a.get("peer", 1)) == meu
			linhas.append("  %s (NEX %d%%) — %s%s" % [a.nome, int(a.nex), a.jogador, "  [color=#6fcf8e](seu)[/color]" if seu else ""])
	var rel: Dictionary = info.get("relatorio", {})
	if not rel.is_empty():
		linhas.append("")
		linhas.append("[b]Última missão:[/b] %s" % ("cumprida" if rel.get("vitoria", false) else "fracassada"))
		var camp: Dictionary = rel.get("campanha", {})
		if not camp.is_empty() and String(camp.get("texto", "")) != "":
			linhas.append("[i]%s[/i]" % camp.texto)
	_info.text = "\n".join(linhas)


func _sair() -> void:
	if _jogo != null:
		_jogo.sair_da_sessao()
	else:
		get_tree().quit()
