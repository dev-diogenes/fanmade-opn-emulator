extends Control
## Saguão do cliente online (Fase 8.2): enquanto o host está na Base, quem entrou na sessão
## espera aqui e vê os jogadores, os agentes (e de quem é cada um) e a última missão.
## Quando o host começa uma missão, o estado chega e o Jogo troca de cena sozinho.
## Desde o docs/29 (C8), a espera é visível: o código da sala, um "REC" de escuta, pontos
## que andam, o tempo de espera e, se a conexão demorar, o que conferir.

var _jogo: Node
var _lbl_status: Label
var _info: RichTextLabel
var _sigilo: Sigilo
var _lbl_espera: Label
var _lbl_codigo: Label
var _tempo := 0.0
## Segundos de "Conectando…" até mostrar o que conferir.
const DICA_APOS := 8.0


func _ready() -> void:
	_jogo = get_node_or_null("/root/Jogo")
	_montar()
	if _jogo != null:
		_jogo.saguao_mudou.connect(_atualizar)
	_atualizar()


func _montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(Tema.fundo())
	# Sigilo grande ao fundo, girando devagar: a sessão "convoca" os agentes
	_sigilo = Sigilo.new()
	_sigilo.semente = 1987
	_sigilo.cor = Color(Tema.SANGUE_CLARO, 0.18)
	_sigilo.espessura = 3.0
	_sigilo.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_sigilo.size = Vector2(620, 620)
	_sigilo.position -= _sigilo.size / 2.0
	_sigilo.pivot_offset = _sigilo.size / 2.0
	add_child(_sigilo)
	_sigilo.revelar(2.0)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centro)
	var painel := PanelContainer.new()
	painel.custom_minimum_size = Vector2(620, 460)
	centro.add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", Tema.ESPACO_G)
	painel.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Sessão online"
	titulo.theme_type_variation = "Titulo"
	caixa.add_child(titulo)
	_lbl_codigo = Label.new()
	_lbl_codigo.add_theme_color_override("font_color", Tema.TEXTO_SUAVE)
	caixa.add_child(_lbl_codigo)
	_lbl_status = Label.new()
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_status.add_theme_color_override("font_color", Tema.INFO)
	caixa.add_child(_lbl_status)
	_lbl_espera = Label.new()
	_lbl_espera.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_espera.add_theme_color_override("font_color", Tema.PERGAMINHO)
	var maquina := Tema.fonte_maquina()
	if maquina != null:
		_lbl_espera.add_theme_font_override("font", maquina)
	caixa.add_child(_lbl_espera)
	# O que o host mandou fica num papel, como a ficha da operação
	var papel := PanelContainer.new()
	papel.add_theme_stylebox_override("panel", Tema.caixa_papel(Vector2(18, 14)))
	papel.theme = Tema.tema_papel()
	papel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	caixa.add_child(papel)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	papel.add_child(_info)
	var sair := Button.new()
	sair.text = "Sair da sessão"
	sair.size_flags_horizontal = Control.SIZE_SHRINK_END
	sair.pressed.connect(_sair)
	caixa.add_child(sair)


func _process(delta: float) -> void:
	_tempo += delta
	if _sigilo != null:
		_sigilo.rotation += delta * 0.04
		# A "convocação" pulsa devagar (sem piscar: respeita o modo suave de flashes)
		_sigilo.modulate.a = 0.75 + 0.25 * sin(_tempo * 1.2)
	if _lbl_espera != null:
		_lbl_espera.text = texto_espera(_tempo, _conectado())


func _conectado() -> bool:
	if _jogo == null:
		return false
	var peer: MultiplayerPeer = _jogo.rede.multiplayer.multiplayer_peer
	return peer != null and not peer is OfflineMultiplayerPeer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## O que a espera diz: escuta com pontos que andam e o tempo; antes de conectar, depois de
## alguns segundos, o que conferir. Estático para os testes.
static func texto_espera(t: float, conectado: bool) -> String:
	var pontos := ".".repeat(1 + int(t * 2.0) % 3)
	var s := int(t)
	var relogio := "%s REC  %02d:%02d" % ["●" if int(t * 2.0) % 2 == 0 else "○", s / 60, s % 60]
	if conectado:
		return "%s\nAguardando o host abrir a operação%s" % [relogio, pontos]
	var texto := "%s\nProcurando a sala%s" % [relogio, pontos]
	if t >= DICA_APOS:
		texto += "\n\nDemorando? Confira o código, se o host está com a sala aberta e se vocês estão na mesma rede (ou na mesma VPN de jogos)."
	return texto


func _atualizar() -> void:
	if not is_inside_tree():
		return
	var info: Dictionary = _jogo.saguao_info if _jogo != null else {}
	var aviso: String = _jogo.aviso_rede if _jogo != null else ""
	_lbl_status.text = String(info.get("status", "Conectando…")) + ("\n" + aviso if aviso != "" else "")
	if _jogo != null and _jogo.rede.endereco != "":
		_lbl_codigo.text = "Sala %s" % CodigoSala.gerar(_jogo.rede.endereco, _jogo.rede.porta)
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
			linhas.append("  %s (NEX %d%%) — %s%s" % [a.nome, int(a.nex), a.jogador, "  " + Tema.bb("(seu)", Tema.cor_sucesso(true)) if seu else ""])
	var rel: Dictionary = info.get("relatorio", {})
	if not rel.is_empty():
		linhas.append("")
		linhas.append("[b]Última missão:[/b] %s" % ("cumprida" if rel.get("vitoria", false) else "fracassada"))
		var camp: Dictionary = rel.get("campanha", {})
		if not camp.is_empty() and String(camp.get("texto", "")) != "":
			linhas.append("[i]%s[/i]" % camp.texto)
	_info.text = "\n".join(linhas) if not linhas.is_empty() else "[i]Quando o host responder, aqui aparecem os jogadores, os agentes da carreira e de quem é cada um.[/i]"


func _sair() -> void:
	if _jogo != null:
		_jogo.sair_da_sessao()
	else:
		get_tree().quit()
