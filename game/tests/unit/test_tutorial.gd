extends GutTest
## Tutorial (docs/07-tutorial.md): o tour guiado, as preferências e estatísticas, o convite ao
## abrir o jogo e os tours das telas. Usa um arquivo de preferências de teste.

const ARQUIVO_TESTE := "user://preferencias_teste.json"


func before_each():
	Preferencias.caminho = ARQUIVO_TESTE
	if FileAccess.file_exists(ARQUIVO_TESTE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_TESTE))
	Tutorial.reiniciar_sessao()


func after_each():
	if FileAccess.file_exists(ARQUIVO_TESTE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQUIVO_TESTE))
	Preferencias.caminho = Preferencias.ARQUIVO
	Tutorial.reiniciar_sessao()


## Espera quadros de verdade do motor (o tour espera o layout da tela).
func _quadros(n: int) -> void:
	for i in n:
		await get_tree().process_frame


# --- Conteúdo -------------------------------------------------------------------------

func test_cada_tela_tem_um_tour_curto():
	var telas: Dictionary = DadosJogo.ler("tutorial").telas
	for tela in Tutorial.TELAS:
		assert_true(telas.has(tela), tela)
		var passos: Array = telas[tela].passos
		assert_between(passos.size(), 4, 8, "%s: tour curto (4 a 8 passos)" % tela)
		for p in passos:
			assert_ne(String(p.get("titulo", "")), "")
			assert_ne(String(p.get("texto", "")), "")
	assert_ne(String(DadosJogo.ler("tutorial").convite.texto), "")


# --- Tour ---------------------------------------------------------------------------------

func _tour(lista: Array) -> TourGuiado:
	var t := TourGuiado.new()
	add_child_autofree(t)
	t.iniciar(lista)
	return t


func test_tour_navega_e_conclui():
	var fins: Array = []
	var t := _tour([{"titulo": "A", "texto": "1"}, {"titulo": "B", "texto": "2"}, {"titulo": "C", "texto": "3"}])
	t.terminou.connect(func(concluido, passo): fins.append([concluido, passo]))
	await _quadros(3)
	assert_true(TourGuiado.em_andamento())
	assert_eq(t._lbl_contador.text, "1 de 3")
	assert_true(t._btn_voltar.disabled)
	t.avancar()
	await _quadros(2)
	assert_eq(t._lbl_titulo.text, "B")
	t.voltar()
	await _quadros(2)
	assert_eq(t._lbl_titulo.text, "A")
	t.avancar()
	await _quadros(2)
	t.avancar()
	await _quadros(2)
	assert_eq(t._btn_proximo.text, "Concluir")
	t.avancar()
	assert_eq(fins, [[true, 3]])
	await _quadros(2)
	assert_false(TourGuiado.em_andamento(), "o tour fechou")


func test_tour_pulado_diz_em_que_passo():
	var fins: Array = []
	var t := _tour([{"titulo": "A", "texto": "1"}, {"titulo": "B", "texto": "2"}])
	t.terminou.connect(func(concluido, passo): fins.append([concluido, passo]))
	await _quadros(3)
	t.avancar()
	await _quadros(2)
	t.pular_tour()
	assert_eq(fins, [[false, 2]])


func test_tour_destaca_o_elemento_e_centraliza_sem_elemento():
	# Uma tela do tamanho do jogo (sem janela, a raiz do teste é minúscula)
	var tela := SubViewport.new()
	tela.size = Vector2i(1152, 648)
	add_child_autofree(tela)
	var botao := Button.new()
	botao.text = "Alvo"
	botao.position = Vector2(200, 150)
	botao.size = Vector2(120, 40)
	tela.add_child(botao)
	var t := TourGuiado.new()
	tela.add_child(t)
	t.iniciar([{"titulo": "Centro", "texto": "sem alvo"}, {"titulo": "Botão", "texto": "com alvo", "alvo": botao}])
	await _quadros(3)
	assert_false(t._moldura.visible, "sem elemento: sem moldura")
	assert_eq(t._escuros[0].size, Vector2(1152, 648), "tudo escuro")
	t.avancar()
	await _quadros(3)
	assert_true(t._moldura.visible)
	var r := botao.get_global_rect().grow(TourGuiado.MARGEM)
	assert_eq(t._moldura.position, r.position)
	assert_eq(t._bloqueio.size, r.size, "o elemento aparece mas não recebe cliques")
	assert_eq(t._escuros[0].size.y, r.position.y, "escuro acima do elemento")
	var balao := Rect2(t._balao.position, t._balao.size)
	assert_true(Rect2(0, 0, 1152, 648).encloses(balao), "a caixa fica dentro da tela")
	assert_false(balao.intersects(r), "a caixa não cobre o elemento")


# --- Preferências e estatísticas -------------------------------------------------------------

func test_preferencias_e_estatisticas():
	assert_true(Preferencias.perguntar_tutorial(), "pergunta por padrão")
	Preferencias.definir_perguntar_tutorial(false)
	assert_false(Preferencias.perguntar_tutorial())
	Preferencias.registrar_tour("mapa", "inicio")
	Preferencias.registrar_tour("mapa", "pulado", 3)
	Preferencias.registrar_tour("mapa", "inicio")
	Preferencias.registrar_tour("mapa", "concluido")
	var est: Dictionary = Preferencias.estatisticas().mapa
	assert_eq(int(est.inicio), 2)
	assert_eq(int(est.concluido), 1)
	assert_eq(int(est.pulado), 1)
	assert_eq(int(est.pulou_no_passo["3"]), 1)


# --- Convite e tours das telas ------------------------------------------------------------

func _tela() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(c)
	return c


func _botoes(no: Node) -> Dictionary:
	var achados := {}
	for b in no.find_children("*", "Button", true, false):
		achados[(b as Button).text] = b
	return achados


var _aceitou := 0


func _ao_aceitar() -> void:
	_aceitou += 1


func test_convite_aparece_e_lembra_a_escolha():
	var raiz := _tela()
	var convite := Tutorial.convidar(raiz, _ao_aceitar)
	assert_not_null(convite, "pergunta ao abrir o jogo")
	assert_null(Tutorial.convidar(raiz, _ao_aceitar), "uma vez por execução")
	var caixa: CheckBox = convite.find_children("*", "CheckBox", true, false)[0]
	caixa.button_pressed = true
	_botoes(convite)["Agora não"].emit_signal("pressed")
	assert_false(Tutorial.na_sessao)
	assert_false(Preferencias.perguntar_tutorial(), "não perguntar de novo")
	Tutorial.reiniciar_sessao()
	assert_null(Tutorial.convidar(raiz, _ao_aceitar), "quem pediu para não perguntar não vê o convite")


func test_aceitar_abre_os_tours_uma_vez_por_tela():
	var raiz := _tela()
	_aceitou = 0
	var convite := Tutorial.convidar(raiz, _ao_aceitar)
	_botoes(convite)["Ver o tutorial"].emit_signal("pressed")
	assert_true(Tutorial.na_sessao)
	assert_eq(_aceitou, 1)
	assert_eq(int(Preferencias.estatisticas().convite.concluido), 1)
	var t := Tutorial.ao_entrar("mapa", raiz, {})
	assert_not_null(t, "primeira vez no mapa")
	t.pular_tour()
	assert_null(Tutorial.ao_entrar("mapa", raiz, {}), "não repete na mesma execução")
	assert_not_null(Tutorial.abrir("mapa", raiz, {}), "o botão ? sempre abre")
	assert_eq(int(Preferencias.estatisticas().mapa.inicio), 2)


func test_sem_aceitar_nenhum_tour_abre_sozinho():
	assert_null(Tutorial.ao_entrar("combate", _tela(), {}))


func test_telas_tem_os_elementos_do_tour():
	var jogo = get_node("/root/Jogo")
	var carreira_antes = jogo.carreira
	var salvar_antes: bool = jogo.salvar_automaticamente
	jogo.salvar_automaticamente = false
	jogo.carreira = Carreira.nova()
	jogo.carreira.iniciar_missao(jogo.carreira.roster.duplicate(), 8)
	Tutorial.na_sessao = true
	var telas := {"mapa": "res://scenes/mapa_mundo.tscn", "combate": "res://scenes/arena_teste.tscn", "investigacao": "res://scenes/investigacao.tscn"}
	for tela in telas:
		var no = load(telas[tela]).instantiate()
		add_child_autofree(no)
		await _quadros(3)
		var alvos: Dictionary = no._alvos_do_tutorial()
		for p in DadosJogo.ler("tutorial").telas[tela].passos:
			if p.has("alvo"):
				assert_true(alvos.get(p.alvo) is Control, "%s: elemento %s" % [tela, p.alvo])
		assert_eq(no.find_children("*", "TourGuiado", true, false).size(), 1, "%s: o tour abriu sozinho" % tela)
		assert_true(_botoes(no).has("?"), "%s: botão ?" % tela)
		for t in no.find_children("*", "TourGuiado", true, false):
			t.pular_tour()
		await _quadros(2)
	jogo.carreira = carreira_antes
	jogo.salvar_automaticamente = salvar_antes
