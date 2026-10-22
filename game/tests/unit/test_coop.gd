extends GutTest
## Fase 5: co-op local (ADR 0004) — donos dos agentes, filtro de entrada e cursores de controle.

var rs: RulesetOp2022


func before_all():
	rs = RulesetOp2022.carregar_padrao()
	Entrada.configurar()


func _agente(id: String) -> Agente:
	var a := Agente.criar(rs, id.capitalize(), "combatente", {"agi": 1, "for": 1, "int": 1, "pre": 1, "vig": 1}, {"luta": "treinado", "fortitude": "treinado"}, 5)
	a.id = id
	return a


func _tecla() -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	return ev


func _botao(device: int, botao: int = JOY_BUTTON_A) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = botao
	ev.pressed = true
	return ev


func test_um_jogador_controla_tudo():
	var c := ControleLocal.padrao()
	var a := _agente("rita")
	assert_false(c.co_op())
	assert_true(c.evento_permitido(_tecla(), a))
	assert_true(c.evento_permitido(_botao(0), a))
	assert_eq(c.faixa_da_vez(a), "", "sem co-op, não há faixa")


func test_so_o_dono_age_na_vez_do_agente():
	var c := ControleLocal.padrao()
	var rita := _agente("rita")
	var cleber := _agente("cleber")
	assert_eq(c.adicionar_jogador(ControleLocal.CONTROLE, 0), 1)
	c.definir_dono(cleber, 1)
	assert_eq(c.jogador_de(rita), 0, "sem dono definido, é do Jogador 1")
	assert_eq(c.jogador_de(cleber), 1)
	assert_true(c.evento_permitido(_tecla(), rita))
	assert_false(c.evento_permitido(_botao(0), rita), "o controle do Jogador 2 não mexe na vez da Rita")
	assert_false(c.evento_permitido(_tecla(), cleber), "o teclado não mexe na vez do Cléber")
	assert_true(c.evento_permitido(_botao(0), cleber))
	assert_false(c.evento_permitido(_botao(1), cleber), "outro controle também não")
	var clique := InputEventMouseButton.new()
	assert_false(c.evento_permitido(clique, cleber))
	assert_true(c.evento_permitido(_tecla(), null), "vez de uma ameaça: ninguém é bloqueado")
	assert_eq(c.faixa_da_vez(cleber), "Vez de Cleber — Jogador 2 (controle 1)")
	assert_true(c.usa_controle(cleber))


func test_quatro_jogadores_no_maximo_e_remocao():
	var c := ControleLocal.padrao()
	for i in 3:
		c.adicionar_jogador(ControleLocal.CONTROLE, i)
	assert_eq(c.adicionar_jogador(ControleLocal.CONTROLE, 3), -1, "até 4 jogadores")
	var a := _agente("a")
	var b := _agente("b")
	c.definir_dono(a, 2)
	c.definir_dono(b, 3)
	c.remover_jogador(2)
	assert_eq(c.jogador_de(a), 0, "os agentes do jogador removido voltam para o Jogador 1")
	assert_eq(c.jogador_de(b), 2, "quem vinha depois desce uma posição")


func test_dividir_o_teclado():
	var c := ControleLocal.padrao()
	c.adicionar_jogador(ControleLocal.TECLADO)
	var a := _agente("a")
	c.definir_dono(a, 1)
	assert_true(c.evento_permitido(_tecla(), a), "dois jogadores no mesmo teclado: o filtro não separa")
	assert_eq(c.faixa_da_vez(a), "Vez de A — Jogador 2 (teclado e mouse)")


func test_controles_salvam_na_carreira():
	var car := Carreira.nova(rs)
	car.controles.adicionar_jogador(ControleLocal.CONTROLE, 1)
	car.controles.definir_dono(car.roster[0], 1)
	var copia := Carreira.de_dicionario(JSON.parse_string(JSON.stringify(car.para_dicionario())), rs)
	assert_true(copia.controles.co_op())
	assert_eq(copia.controles.jogador_de(copia.roster[0]), 1)
	assert_eq(int(copia.controles.jogadores[1].indice), 1)
	var vazia := ControleLocal.de_dicionario({})
	assert_eq(vazia.jogadores.size(), 1, "save antigo: um jogador no teclado")


func test_atalhos_de_controle():
	var antes := InputMap.action_get_events("confirmar").size()
	Entrada.configurar()
	assert_eq(InputMap.action_get_events("confirmar").size(), antes, "configurar de novo não duplica")
	assert_eq(Entrada.direcao(_botao(0, JOY_BUTTON_DPAD_LEFT)), Vector2i(-1, 0))
	assert_eq(Entrada.direcao(_botao(2, JOY_BUTTON_DPAD_DOWN)), Vector2i(0, 1))
	var eixo := InputEventJoypadMotion.new()
	eixo.axis = JOY_AXIS_LEFT_X
	eixo.axis_value = 0.9
	assert_eq(Entrada.direcao(eixo), Vector2i(1, 0), "analógico esquerdo também move o cursor")
	assert_eq(Entrada.direcao(eixo), Vector2i.ZERO, "inclinado parado não repete")
	eixo.axis_value = 0.1
	Entrada.direcao(eixo)
	eixo.axis_value = -0.8
	assert_eq(Entrada.direcao(eixo), Vector2i(-1, 0), "voltar e empurrar para o outro lado move de novo")
	assert_eq(Entrada.direcao(_botao(0, JOY_BUTTON_A)), Vector2i.ZERO)
	assert_true(_botao(1, JOY_BUTTON_B).is_action_pressed("cancelar"))


func test_cursor_do_tabuleiro_segue_a_camera():
	var g := Grade.new(14, 9)
	var tab := Tabuleiro3D.new()
	add_child_autofree(tab)
	tab.construir(g)
	assert_eq(tab.celula_na_direcao(Vector2i(5, 5), Vector2i(1, 0)), Vector2i(6, 5))
	assert_eq(tab.celula_na_direcao(Vector2i(0, 0), Vector2i(-1, 0)), Vector2i(0, 0), "não sai da grade")
	tab.rig.giro = PI / 2.0
	assert_ne(tab.celula_na_direcao(Vector2i(5, 5), Vector2i(1, 0)), Vector2i(6, 5), "com a câmera girada, a direita da tela muda")


func test_cursor_do_mapa_anda_para_um_vizinho():
	var m := Missao.nova(7)
	var m3d := Mapa3D.new()
	add_child_autofree(m3d)
	m3d.construir(m.mapa, DadosJogo.ler("mapa").terrenos)
	var h := m.posicao(m.agente_atual())
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var v := m3d.vizinho_na_direcao(h, dir)
		assert_true(v == h or v in Hex.vizinhos(h))
	var direita := m3d.vizinho_na_direcao(h, Vector2i(1, 0))
	if direita != h:
		assert_gt(m3d.posicao_hex(direita, 0.0).x, m3d.posicao_hex(h, 0.0).x, "direita da tela = x maior com a câmera parada")
