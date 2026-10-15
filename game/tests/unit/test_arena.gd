extends GutTest
## Teste de fumaça da Arena de Teste: a cena carrega e um combate inteiro
## jogado pela IA (dos dois lados) termina com um vencedor.

const CENA := "res://scenes/arena_teste.tscn"


func test_arena_completa_em_autoplay():
	for semente in [1, 7, 2026]:
		var arena = load(CENA).instantiate()
		arena.autoplay = true
		arena.semente = semente
		add_child_autofree(arena)
		assert_true(arena.combate.encerrado, "seed %d: o combate deveria terminar" % semente)
		assert_ne(arena.combate.lado_vencedor(), "", "seed %d: precisa de um vencedor" % semente)
		assert_lt(arena.membrana.valor, 100, "a Membrana cai a cada rodada")


func test_arena_espera_o_jogador():
	var arena = load(CENA).instantiate()
	arena.semente = 3
	add_child_autofree(arena)
	await wait_seconds(0.1)
	assert_false(arena.combate.encerrado)
	assert_not_null(arena.combate.ser_atual())
