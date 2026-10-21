extends GutTest
## Matemática de hexágonos, mapa e gerador procedural.


func test_distancia_e_vizinhos():
	assert_eq(Hex.distancia(Vector2i(0, 0), Vector2i(3, 0)), 3)
	assert_eq(Hex.distancia(Vector2i(0, 0), Vector2i(2, -1)), 2)
	assert_eq(Hex.distancia(Vector2i(0, 0), Vector2i(-2, 3)), 3)
	for v in Hex.vizinhos(Vector2i(4, 2)):
		assert_eq(Hex.distancia(Vector2i(4, 2), v), 1)
	assert_eq(Hex.area(Vector2i.ZERO, 2).size(), 19)


func test_offset_ida_e_volta():
	for col in 6:
		for lin in 6:
			assert_eq(Hex.para_offset(Hex.de_offset(col, lin)), Vector2i(col, lin))


func test_pixel_ida_e_volta():
	for h in Hex.area(Vector2i(3, 3), 3):
		assert_eq(Hex.de_pixel(Hex.para_pixel(h, 25.0), 25.0), h)


func _mapa_linha() -> MapaHex:
	var m := MapaHex.new({"campo": {"custo": 1}, "floresta": {"custo": 2}, "agua": {"custo": -1}})
	for q in 6:
		m.celulas[Vector2i(q, 0)] = {"terreno": "campo", "conteudo": {}, "revelado": false}
	return m


func test_custo_e_caminho():
	var m := _mapa_linha()
	m.celulas[Vector2i(2, 0)].terreno = "floresta"
	var c := m.caminho(Vector2i(0, 0), Vector2i(4, 0))
	assert_eq(c, [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)] as Array[Vector2i])
	assert_eq(m.custo_do_caminho(c), 5)
	var alc := m.alcancaveis(Vector2i(0, 0), 2)
	assert_true(alc.has(Vector2i(1, 0)))
	assert_false(alc.has(Vector2i(2, 0)), "floresta custa 2: total 3")


func test_agua_bloqueia():
	var m := _mapa_linha()
	m.celulas[Vector2i(2, 0)].terreno = "agua"
	assert_true(m.caminho(Vector2i(0, 0), Vector2i(4, 0)).is_empty())


func test_conteudo_para_o_movimento():
	var m := _mapa_linha()
	m.definir_conteudo(Vector2i(2, 0), {"tipo": "evento", "evento": "x"})
	var alc := m.alcancaveis(Vector2i(0, 0), 10)
	assert_true(alc.has(Vector2i(2, 0)), "pode entrar no hex com conteúdo")
	assert_false(alc.has(Vector2i(3, 0)), "mas não atravessa")


func test_gerador_e_deterministico_e_conectado():
	var a := GeradorMapa.gerar(42)
	var b := GeradorMapa.gerar(42)
	assert_eq(a.para_dicionario(), b.para_dicionario())
	for semente in [1, 2, 3, 42, 777, 2026]:
		var m := GeradorMapa.gerar(semente)
		var inicio := m.encontrar("inicio")
		var objetivo := m.encontrar("objetivo")
		assert_ne(inicio, Vector2i(-999, -999))
		assert_ne(objetivo, Vector2i(-999, -999))
		assert_false(m.caminho(inicio, objetivo, false).is_empty(), "seed %d precisa de rota até o covil" % semente)
		assert_true(m.revelado(inicio))
		var encontros := 0
		var eventos := 0
		for h in m.celulas:
			match m.conteudo(h).get("tipo", ""):
				"encontro": encontros += 1
				"evento": eventos += 1
		assert_gt(encontros, 3, "seed %d" % semente)
		assert_gt(eventos, 3, "seed %d" % semente)


func test_mapa_serializa():
	var m := GeradorMapa.gerar(9)
	var copia := MapaHex.new(m.terrenos)
	copia.de_dicionario(m.para_dicionario())
	assert_eq(copia.para_dicionario(), m.para_dicionario())


func test_serra_so_com_escalada():
	var m := MapaHex.new({"campo": {"custo": 1}, "serra": {"custo": -1, "escalavel": true, "custo_escalada": 2}})
	m.colunas = 3
	m.linhas = 1
	for x in 3:
		m.celulas[Vector2i(x, 0)] = {"terreno": "campo", "conteudo": {}, "revelado": false}
	m.celulas[Vector2i(1, 0)].terreno = "serra"
	assert_false(m.passavel(Vector2i(1, 0)))
	assert_true(m.passavel(Vector2i(1, 0), true), "com escalada, a serra é passável")
	assert_eq(m.custo(Vector2i(1, 0), true), 2)
	assert_false(m.alcancaveis(Vector2i(0, 0), 5).has(Vector2i(1, 0)))
	assert_true(m.alcancaveis(Vector2i(0, 0), 5, true, true).has(Vector2i(1, 0)))
