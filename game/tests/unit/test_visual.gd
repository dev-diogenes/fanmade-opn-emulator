extends GutTest
## Direção de arte (ADR 0008): o tema da interface e as peças com modelos KayKit
## (ou o fallback por código, quando os modelos não estão no clone).


func test_tema_tem_variacoes_e_estilos():
	var t := Tema.criar()
	assert_true(t.has_stylebox("panel", "PanelContainer"))
	assert_true(t.has_stylebox("normal", "Button"))
	assert_eq(t.get_type_variation_base("Titulo"), &"Label")
	assert_eq(t.get_type_variation_base("BotaoPrincipal"), &"Button")
	assert_eq(t.get_type_variation_base("PainelLateral"), &"PanelContainer")


func test_painel_herda_tamanho_do_conteudo():
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(300, 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var p := Tema.painel(v, true)
	add_child_autofree(p)
	assert_eq(p.custom_minimum_size, Vector2(300, 0))
	assert_eq(p.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_eq(p.theme_type_variation, &"PainelLateral")
	assert_eq(v.get_parent(), p)


func test_agente_sempre_devolve_figura():
	for classe in ["combatente", "especialista", "ocultista", "mundano", "desconhecida"]:
		var f := Pecas.agente(classe, Color.BLUE, 0.75)
		assert_not_null(f, classe)
		add_child_autofree(f)
		assert_gt(f.get_child_count(), 0, classe)


func test_tile_terreno_usa_modelo_ou_null():
	var tile := Pecas.tile_terreno("floresta", 1.0, 0.24, 42, Color("24452b"))
	if not ResourceLoader.exists(Pecas.DIR_HEX + "hex_grass.gltf"):
		assert_null(tile, "sem os modelos, o mapa usa a primitiva")
		return
	assert_not_null(tile)
	add_child_autofree(tile)
	assert_eq(tile.get_child_count(), 2, "tile e decoração")


func test_slot_d20_por_estado():
	for estado in ["sucesso", "falha", "neutro"]:
		var s := Tema.slot_d20(17, estado)
		add_child_autofree(s)
		var l: Label = s.get_child(0)
		assert_true(l.text.begins_with("17"), estado)
	var falha := Tema.slot_d20(3, "falha")
	add_child_autofree(falha)
	assert_true((falha.get_child(0) as Label).text.ends_with("✗"), "falha não depende só da cor")


func test_bb_usa_o_token():
	assert_eq(Tema.bb("Encontro!", Tema.PERIGO), "[color=#%s]Encontro![/color]" % Tema.PERIGO.to_html(false))


func test_cartao_agente_mostra_vez_e_queda():
	var rs := RulesetOp2022.carregar_padrao()
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2})
	var c := CartaoAgente.criar(a, Tema.CORES_JOGADORES[0])
	add_child_autofree(c)
	c.atualizar(true)
	assert_eq(c.modulate.a, 1.0)
	assert_eq(c._estilo.border_color, Tema.OURO_CLARO, "borda dourada na vez")
	a.condicoes[Ser.INCONSCIENTE] = true
	c.atualizar(false)
	assert_string_contains(c._nome.text, "✝", "caído não depende só da cor")
	assert_eq(c.modulate.a, 0.5)


func test_tela_de_titulo_carrega():
	var t = load("res://scenes/titulo.tscn").instantiate()
	t.avisar_flashes = false
	add_child_autofree(t)
	await wait_frames(2)
	assert_not_null(t._mapa3d)
	assert_gt(t._menu.get_child_count(), 3)


func test_sigilo_e_deterministico_e_varia():
	assert_eq(Sigilo.gerar(7), Sigilo.gerar(7), "mesma semente, mesmo sigilo")
	assert_ne(Sigilo.gerar(7), Sigilo.gerar(8))
	assert_gt(Sigilo.gerar(7).size(), 4, "círculo, raios e arcos")


func test_moldura_riscada_tem_margens():
	var m := MolduraRiscada.criar(Tema.OURO, Tema.PEDRA, Vector2(14, 10))
	assert_eq(m.get_content_margin(SIDE_LEFT), 14.0)
	assert_eq(m.get_content_margin(SIDE_TOP), 10.0)


func test_quadro_mostra_fotos_e_carimbo():
	var caso := Caso.gerar(Dados.new(5))
	var q := QuadroInvestigacao.new()
	q.size = Vector2(470, 420)
	add_child_autofree(q)
	caso.registrar_pista("Pista um", "quem", "teste")
	caso.registrar_pista("Pista dois", "quem", "teste")
	q.atualizar(caso)
	assert_eq(q._fios.size(), 2, "um fio por pista")
	var textos: Array = q.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.any(func(t): return t.begins_with("RESOLVIDO")), "pergunta respondida recebe o carimbo")


func test_investigacao_sem_formularios():
	var tela = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	for tipo in ["OptionButton", "CheckBox", "SpinBox"]:
		var visiveis: Array = tela.find_children("*", tipo, true, false).filter(func(n): return n.is_visible_in_tree())
		assert_eq(visiveis.size(), 0, "nenhum %s visível (docs/09, 5.5)" % tipo)
	assert_eq(tela._cartas.size(), 4)
	tela._selecionar_carta("ajudar")
	assert_true(tela._cartas.ajudar.selecionada)


func _sem_formularios(tela: Node) -> void:
	for tipo in ["SpinBox"]:
		var visiveis: Array = tela.find_children("*", tipo, true, false).filter(func(n): return n.is_visible_in_tree())
		assert_eq(visiveis.size(), 0, "nenhum %s visível em %s" % [tipo, tela.name])


func test_mapa_e_hud_flutuante():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	_sem_formularios(tela)
	assert_true(tela._log is RelatorioCampo, "registro recolhível")
	assert_eq(tela._vista.anchor_right, 1.0, "3D em tela cheia")
	tela._mostrar_dica(Vector2(400, 300))   # não quebra fora ou dentro de um hex


func test_combate_tem_cartas():
	var arena = load("res://scenes/arena_teste.tscn").instantiate()
	arena.semente = 3
	add_child_autofree(arena)
	await wait_frames(2)
	_sem_formularios(arena)
	assert_eq(arena._cartas.size(), 5)
	arena._abrir_bilhete("item")
	assert_eq(arena._bilhete_tipo, "item")
	arena._abrir_bilhete("item")
	assert_eq(arena._bilhete_tipo, "", "clicar de novo fecha o bilhete")


func test_base_e_dossie_com_abas():
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	await wait_frames(2)
	assert_eq(base._abas.get_tab_count(), 4)
	assert_eq(base._abas.current_tab, 2, "a Base abre na aba Missão (E5)")
	base._abas.current_tab = 0
	var tour := TourGuiado.new()   # fora da árvore: não conta como tour aberto
	tour._abrir_aba_de(base._btn_iniciar)
	tour.free()
	assert_eq(base._abas.current_tab, 2, "o tour abre a aba Missão para mostrar o Iniciar")
	for c in get_tree().root.find_children("ConviteTutorial", "", true, false):
		c.queue_free()


func test_marcos_de_op_tem_peca_e_cor():
	for tipo in ["encontro", "evento", "objetivo", "investigacao", "vila", "inicio", "desconhecido"]:
		var m := Pecas.marco(tipo)
		add_child_autofree(m)
		assert_true(m.has_meta("peca"), tipo)
		assert_true(m.get_meta("peca").get_parent() == m, "%s: a peça flutuante fica no marco" % tipo)


func test_ameacas_tem_figura():
	var rs := RulesetOp2022.carregar_padrao()
	for id in ["zumbi_de_sangue", "iniciado", "tita_de_sangue"]:
		var ficha := rs.ameaca(id)
		var a := Ameaca.criar(rs, String(ficha.get("nome", id)), ficha)
		var f := Pecas.ameaca(a)
		add_child_autofree(f)
		assert_gt(f.get_child_count(), 0, id)


func test_dialogo_papel_confirma_e_cancela():
	var resultado := []
	var d := DialogoPapel.perguntar(self, "Teste", "Apagar?", "Sim", func(): resultado.append("sim"))
	d._responder(true)
	assert_eq(resultado, ["sim"])
	var d2 := DialogoPapel.perguntar(self, "Teste", "Apagar?", "Sim", func(): resultado.append("de novo"))
	d2._responder(false)
	assert_eq(resultado, ["sim"], "voltar não confirma")
	await wait_frames(1)


func test_relatorio_fim_mostra_carimbo_e_resumo():
	var r := RelatorioFim.new("Voltar")
	add_child_autofree(r)
	assert_false(r.aberto)
	r.mostrar("CASO ENCERRADO", ["Linha 1", "Linha 2"], true)
	assert_true(r.aberto)
	assert_true(r.rotulo.is_visible_in_tree(), "o carimbo aparece junto com a folha")
	assert_eq(r.rotulo.text, "CASO ENCERRADO")
	assert_eq(r._resumo.text, "Linha 1\nLinha 2")


func test_preferencias_de_efeitos_e_pausa():
	var antes := Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_efeitos.json"
	Preferencias._efeitos_cache = {}
	assert_true(Preferencias.efeito("grao"), "ligado por padrão")
	Preferencias.definir_efeito("grao", false)
	assert_false(Preferencias.efeito("grao"))
	var m := MenuPausa.abrir(self)
	assert_true(MenuPausa.aberto(self))
	assert_eq(m._ajustes.get_child_count(), 12, "texto, resultados, escala, flashes, daltonismo, atalhos, volume, câmera e quatro efeitos")
	m.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = antes
	Preferencias._efeitos_cache = {}


func test_transicao_some_sozinha():
	var t := Transicao.new(Transicao.para_cena("res://scenes/mapa_mundo.tscn"))
	assert_eq(t._texto.text, "OPERAÇÃO EM CAMPO")
	add_child(t)
	await wait_seconds(1.6)
	assert_false(is_instance_valid(t), "a estática se desfaz")


func test_barra_membrana_racha():
	var b := BarraMembrana.new()
	b.size = Vector2(200, 14)
	add_child_autofree(b)
	b.value = 20
	await wait_frames(2)
	assert_eq(b.value, 20.0)


func test_som_procedural_gera_e_toca():
	for nome in ["tecla", "carimbo", "pista", "drone"]:
		var w := Som.gerar(nome)
		assert_gt(w.data.size(), 100, nome)
	assert_eq(Som.gerar("drone").loop_mode, AudioStreamWAV.LOOP_FORWARD, "o drone fica em laço")
	assert_same(Som.gerar("tecla"), Som.gerar("tecla"), "cache")
	Som.tocar("clique")        # com ou sem a instância do Jogo, não quebra
	Som.ambiente(0.8)
	Som.ambiente(0.0)


func test_sons_do_combate_e_caixinha():
	for nome in ["golpe", "erro", "ritual", "passo", "encontro"]:
		assert_gt(Som.gerar(nome).data.size(), 100, nome)
	assert_eq(Som.gerar("caixinha").loop_mode, AudioStreamWAV.LOOP_FORWARD)
	Som.musica("")


func test_arsenal_usa_etiquetas():
	var base = load("res://scenes/base_ordem.tscn").instantiate()
	add_child_autofree(base)
	await wait_frames(2)
	assert_false(base._checks_itens.is_empty())
	for id in base._checks_itens:
		assert_false(base._checks_itens[id] is CheckBox, "o Arsenal não usa mais caixas de marcar")
		break
	for c in get_tree().root.find_children("ConviteTutorial", "", true, false):
		c.queue_free()


func test_investigacao_exige_chegar_perto():
	var tela = load("res://scenes/investigacao.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	var a: Agente = tela.cena.agente_atual()
	assert_eq(tela._visao.ponto_proximo(a, tela.cena.pontos_restantes), "", "o grupo começa no centro, longe dos pontos")
	var alvo: String = tela.cena.pontos_restantes[0]
	var p: Vector3 = tela._visao._props[alvo].position
	for i in 200:
		var f: Node3D = tela._visao.figura(a)
		var dir := Vector3(p.x - f.position.x, 0, p.z - f.position.z)
		if dir.length() < 0.9:
			break
		tela._visao.mover_agente(a, dir, 0.05)
	assert_eq(tela._visao.ponto_proximo(a, tela.cena.pontos_restantes), alvo, "andando até o ponto, ele fica ao alcance")


func test_camera_troca_de_modo():
	var antes := Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_camera.json"
	var rig := CameraRig.new()
	add_child_autofree(rig)
	var fig := Node3D.new()
	add_child_autofree(fig)
	rig.seguir = fig
	assert_eq(rig.modo, "terceira")
	assert_eq(rig.proximo_modo(), "segunda")
	assert_eq(rig.proximo_modo(), "primeira")
	assert_false(fig.visible, "em 1ª pessoa a própria figura some")
	rig.proximo_modo()
	assert_true(fig.visible)
	assert_eq(Preferencias.camera(), "terceira")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = antes


func test_ficha_mostra_atributos_e_inventario():
	var rs := RulesetOp2022.carregar_padrao()
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2})
	a.equipamento.append("cicatrizante")
	var texto := DossieAgente.ficha_bbcode(a)
	assert_string_contains(texto, "Teste")
	assert_string_contains(texto, "FOR 2")
	var usados := []
	var d := DossieAgente.abrir(self, a, func(item): usados.append(item))
	var botoes: Array = d.find_children("*", "Button", true, false).filter(func(b): return b.text == "Usar")
	assert_eq(botoes.size(), 1, "o Cicatrizante pode ser usado pela ficha no mapa")
	botoes[0].pressed.emit()
	assert_eq(usados, ["cicatrizante"])
	await wait_frames(1)


func test_bilhete_de_desfecho_mostra_selos():
	var b := BilheteDesfecho.mostrar(self, "Ponte podre", "Uma tábua cede.", [{"tipo": "dano", "valor": 3, "texto": "−3 PV"}, {"tipo": "membrana", "valor": -2, "texto": "Membrana −2"}], false)
	var textos: Array = b.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_has(textos, "−3 PV")
	assert_has(textos, "Membrana −2")
	assert_has(textos, "FALHA")
	b.free()


func test_preferencias_de_leitura_e_escala():
	var antes := Preferencias.caminho
	Preferencias.caminho = "user://teste_preferencias_leitura.json"
	assert_eq(Preferencias.velocidade_texto(), "normal")
	Preferencias.definir_tempo_resultado("clique")
	assert_eq(Tema.duracao_resultado(4.0), 0.0, "até clicar: o resultado não some")
	Preferencias.definir_tempo_resultado("curto")
	assert_lt(Tema.duracao_resultado(4.0), 4.0)
	Preferencias.definir_escala(3.0)
	assert_eq(Preferencias.escala(), 1.5, "a escala tem teto")
	Preferencias.definir_velocidade_texto("instantanea")
	var l := Label.new()
	l.text = "Texto"
	add_child_autofree(l)
	Tema.datilografar(l)
	assert_eq(l.visible_ratio, 1.0, "instantâneo: aparece inteiro")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Preferencias.caminho))
	Preferencias.caminho = antes


func test_mapa_mostra_o_caso_e_os_motivos():
	var tela = load("res://scenes/mapa_mundo.tscn").instantiate()
	add_child_autofree(tela)
	await wait_frames(2)
	assert_true(tela._caso.visible)
	assert_string_contains(tela._lbl_caso.get_parsed_text(), "Covil")
	assert_true(tela._btn_descansar.disabled or tela._btn_descansar.tooltip_text != "")
	tela._rolar()
	assert_true(tela._btn_rolar.disabled)
	assert_string_contains(tela._btn_rolar.tooltip_text, "já foi rolado", "o motivo do bloqueio aparece no tooltip")
	for c in get_tree().root.find_children("*", "", true, false):
		if c is DialogoPapel or c is TourGuiado:
			c.queue_free()


func test_dossie_de_criacao_navega_e_valida():
	var c := Carreira.nova()
	var criados := []
	var d := CriacaoDossie.abrir(self, c, func(a): criados.append(a))
	assert_true(d._assinar.disabled, "sem nome e sem perícias, não dá para assinar")
	for i in d._abas.get_tab_count():
		d._abas.current_tab = i   # todas as páginas se desenham sem erro
	d.ficha.classe = "ocultista"
	d._abas.current_tab = 4
	assert_gt(d._paginas["Rituais"].get_child_count(), 2, "o ocultista escolhe rituais")
	d.free()


func test_loucura_cresce_quando_a_sanidade_cai():
	var rs := RulesetOp2022.carregar_padrao()
	var a := Agente.criar(rs, "Teste", "combatente", {"agi": 1, "for": 2, "int": 1, "pre": 1, "vig": 2})
	assert_eq(Alucinacoes.intensidade(a), 0.0, "sanidade cheia: nada")
	a.san = a.san_maximo / 2
	assert_eq(Alucinacoes.intensidade(a), 0.0, "na metade ainda não")
	a.san = a.san_maximo / 4
	assert_almost_eq(Alucinacoes.intensidade(a), 0.5, 0.15)
	a.sofrer_dano_mental(a.san)
	assert_eq(Alucinacoes.intensidade(a), 1.0, "sanidade zerada (enlouquecendo): máximo")
	var c := CartaoAgente.criar(a, Tema.CORES_JOGADORES[0])
	add_child_autofree(c)
	c.atualizar(true)
	assert_eq(c._barras["san"].titulo.text, "SAN!", "perturbado não depende só da cor")
