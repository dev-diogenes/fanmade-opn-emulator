extends GutTest
## Relatório do playtest (docs/78): o texto junta tutorial, carreira, última missão e registro, e
## o arquivo vai para user://relatorios.


func test_texto_tem_as_secoes_e_tira_o_bbcode():
	var c := Carreira.nova()
	var m := c.iniciar_missao(c.roster.slice(0, 3), 42)
	assert_not_null(m)
	m.historico.append("[color=#6fcf8e]Pista:[/color] uma [b]marca[/b] na parede")
	var t := RelatorioPlaytest.texto(c, {"year": 2026, "month": 11, "day": 2, "hour": 10, "minute": 5})
	for secao in ["RELATÓRIO DO PLAYTEST", "2026-11-02 10:05", "== Tutorial ==", "== Carreira ==", "== Missão em andamento =="]:
		assert_string_contains(t, secao)
	assert_string_contains(t, "Pista: uma marca na parede", "o registro sai sem BBCode")
	assert_false(t.contains("[color"), "nenhuma tag sobra")
	assert_string_contains(t, c.roster[0].nome)


func test_sem_carreira_nao_quebra():
	assert_string_contains(RelatorioPlaytest.texto(null), "(sem carreira)")


func test_gerar_grava_o_arquivo():
	var caminho := RelatorioPlaytest.gerar(Carreira.nova())
	assert_ne(caminho, "")
	assert_true(FileAccess.file_exists(caminho))
	assert_string_contains(FileAccess.get_file_as_string(caminho), "== Carreira ==")
	DirAccess.remove_absolute(caminho)
