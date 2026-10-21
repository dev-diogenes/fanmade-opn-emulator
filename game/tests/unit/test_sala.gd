extends GutTest
## Sala online por código e saguão animado (docs/29, C8).


func test_codigo_vai_e_volta():
	for par in [["192.168.0.12", 7777], ["10.0.0.1", 1], ["255.255.255.255", 65535], ["0.0.0.0", 7777], ["127.0.0.1", 24680]]:
		var c := CodigoSala.gerar(par[0], par[1])
		assert_eq(c.length(), 11, "XXXXX-XXXXX: %s" % c)
		assert_eq(CodigoSala.ler(c), {"ip": par[0], "porta": par[1]})


func test_codigo_tolera_digitacao():
	var c := CodigoSala.gerar("192.168.0.12", 7777)
	assert_eq(CodigoSala.ler(c.to_lower()).ip, "192.168.0.12", "minúsculas")
	assert_eq(CodigoSala.ler(c.replace("-", " ")).porta, 7777, "espaço no lugar do hífen")
	assert_eq(CodigoSala.ler(c.replace("0", "O")).ip, "192.168.0.12", "O vale 0")
	assert_eq(CodigoSala.ler(c.replace("1", "l")).ip, "192.168.0.12", "l vale 1")


func test_codigo_recusa_erro_de_digitacao():
	var c := CodigoSala.gerar("192.168.0.12", 7777)
	var errados := 0
	for i in [0, 1, 2, 3, 4, 6, 7, 8, 9, 10]:
		var trocado := c.substr(0, i) + ("A" if c[i] != "A" else "B") + c.substr(i + 1)
		var lido := CodigoSala.ler(trocado)
		if lido.is_empty() or lido != {"ip": "192.168.0.12", "porta": 7777}:
			errados += 1
	assert_eq(errados, 10, "um símbolo trocado nunca leva à sala certa")
	assert_eq(CodigoSala.ler("ABC"), {}, "curto demais")
	assert_eq(CodigoSala.ler("!!!!!-!!!!!"), {})


func test_atalho_por_ip():
	assert_eq(CodigoSala.ler("192.168.0.5"), {"ip": "192.168.0.5", "porta": Rede.PORTA_PADRAO})
	assert_eq(CodigoSala.ler("192.168.0.5:9000"), {"ip": "192.168.0.5", "porta": 9000})
	assert_eq(CodigoSala.ler("300.1.1.1"), {})


func test_espera_do_saguao():
	var script = load("res://scripts/ui/saguao.gd")
	var antes: String = script.texto_espera(2.0, false)
	assert_true(antes.contains("Procurando a sala"))
	assert_false(antes.contains("Demorando"), "a dica só aparece depois de alguns segundos")
	assert_true(script.texto_espera(9.0, false).contains("Demorando"))
	assert_true(script.texto_espera(65.0, true).contains("01:05"))
	assert_true(script.texto_espera(3.0, true).contains("Aguardando o host"))


func test_tipo_de_rede_ordena_a_local_primeiro():
	assert_eq(CodigoSala.tipo_de_rede("192.168.0.12")[1], "rede local (Wi-Fi ou cabo)")
	assert_eq(CodigoSala.tipo_de_rede("26.10.0.4")[1], "Radmin VPN")
	assert_lt(CodigoSala.tipo_de_rede("192.168.0.12")[0], CodigoSala.tipo_de_rede("26.10.0.4")[0])
