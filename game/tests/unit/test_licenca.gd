extends GutTest
## A Licença da Comunidade (docs/60, ADR 0012): o título sem a marca, o selo com o aviso de IA
## na tela de título, o aviso de conteúdo, a tela Sobre e nenhum personagem do cânone nos nomes.

## Primeiros nomes dos personagens principais do cânone (wiki, Categoria:Personagens principais,
## consultada em 22/10/2026), os dois exemplos do texto da licença (Agatha, Kian) e os de um
## nome só que o jogo já usou. Nenhum nome de gente do
## jogo pode ser um deles (comparação sem acento e com "th" = "t").
const CANONE := ["Alan", "Alexandre", "Alexsander", "Amanda", "Amelie", "Aniela", "Antônio", "Artemis", "Arthur",
	"Ayla", "Beatrice", "Benito", "Boris", "Breno", "Bruna", "Bárbara", "Carina", "Cesar", "Cristopher", "Damir",
	"Daniel", "Dante", "Dara", "Diego", "Edgar", "Elizabeth", "Eloísa", "Enzo", "Erin", "Fernando", "Francisco",
	"Gal", "Guilherme", "Heitor", "Jaime", "Jasper", "Jeffrey", "Joel", "Jorel", "Jorge", "Joui", "Juan", "Kênia",
	"Leandro", "Lena", "Lila", "Luciano", "Lucie", "Lucio", "Luis", "Lírio", "Mauro", "Maya", "Melissa", "Mike",
	"Milo", "Nathalia", "Olivier", "Raven", "Remi", "Ricardo", "Roberta", "Rubens", "Shanyqua", "Thalita",
	"Theodore", "Thiago", "Tuco", "Val", "Victor", "Wanderley", "Agatha", "Kian",
	"Joana", "Jéssica", "Wagner", "Lúcia", "Coruja", "Corvo"]


static func _normal(s: String) -> String:
	var t := s.to_lower()
	for par in [["á", "a"], ["à", "a"], ["â", "a"], ["ã", "a"], ["é", "e"], ["ê", "e"], ["í", "i"], ["ó", "o"],
			["ô", "o"], ["õ", "o"], ["ú", "u"], ["ç", "c"], ["th", "t"], ["y", "i"]]:
		t = t.replace(par[0], par[1])
	return t


func _nomes_de_gente() -> Array:
	var nomes: Array = []
	for r in DadosJogo.ler("recrutas").recrutas:
		nomes.append(String(r.nome))
	for r in DadosJogo.ler("grupo_inicial").agentes:
		nomes.append(String(r.nome))
	var t := DadosJogo.ler("testemunhas")
	nomes.append_array(t.nomes_f + t.nomes_m)
	nomes.append_array(DadosJogo.ler("pessoais").apelidos)
	var camp: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/campanhas/o_fundo_da_represa/campanha.json"))
	for r in camp.get("recrutas", []):
		nomes.append(String(r.nome))
	return nomes


func test_nenhum_nome_do_canone():
	var proibidos := {}
	for n in CANONE:
		proibidos[_normal(n)] = n
	var nomes := _nomes_de_gente()
	assert_gt(nomes.size(), 40)
	for nome in nomes:
		for parte in String(nome).split(" "):
			assert_false(proibidos.has(_normal(parte)), "%s coincide com %s, do cânone" % [nome, proibidos.get(_normal(parte), "")])


func test_save_antigo_troca_o_nome_do_recruta():
	var c := Carreira.nova()
	var d: Dictionary = JSON.parse_string(JSON.stringify(c.para_dicionario()))
	for ad in d.roster:
		if ad.nome == "Cléber":
			ad.nome = "Mauro"
	var volta := Carreira.de_dicionario(d)
	assert_true(volta.roster.any(func(a): return a.nome == "Cléber"))
	assert_false(volta.roster.any(func(a): return a.nome == "Mauro"))


func test_titulo_sem_a_marca_e_com_selo():
	assert_false(Licenca.TITULO.to_lower().contains("ordem paranormal"), "a marca não vai no título (Parte 4)")
	assert_false(ProjectSettings.get_setting("application/config/name").to_lower().contains("ordem paranormal"))
	var t = load("res://scenes/titulo.tscn").instantiate()
	t.avisar_flashes = false
	add_child_autofree(t)
	await get_tree().process_frame
	var textos: Array = t.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has(Licenca.TITULO.to_upper()))
	assert_true(textos.has(Licenca.DESCRICAO), "a descrição embaixo do título, fora do nome")
	assert_false(textos.any(func(x): return String(x).contains("ORDEM\nPARANORMAL")))
	assert_true(textos.has(Licenca.AVISO_IA), "o aviso de IA junto do selo")
	assert_true(textos.has(Licenca.NAO_OFICIAL))
	var selo: Control = t.find_child("SeloLicenca", true, false)
	assert_not_null(selo, "o selo na capa")
	assert_true(Licenca.tem_selo(), "o arquivo oficial do selo está no projeto")
	assert_true(selo is TextureRect and (selo as TextureRect).texture != null, "é o selo, não o quadro reservado")
	assert_true(selo.custom_minimum_size.x >= 0.10 * t.get_viewport_rect().size.x, "com ao menos 10% da largura")
	assert_true(t.find_children("*", "Button", true, false).any(func(b): return b.text == "Sobre e licença"))


func test_painel_sobre():
	var p := PainelSobre.abrir(self)
	var textos: Array = p.find_children("*", "Label", true, false).map(func(l): return l.text)
	assert_true(textos.has(Licenca.NAO_OFICIAL))
	assert_true(textos.has(Licenca.AVISO_IA))
	assert_true(textos.any(func(x): return String(x).contains(Licenca.AVISO_CONTEUDO)), "o aviso de conteúdo")
	assert_true(textos.any(func(x): return String(x).contains(Licenca.LICENCA_URL)))
	assert_true(TourGuiado.papel_aberto(get_tree()))
	p.fechar()
	assert_false(TourGuiado.papel_aberto(get_tree()))
