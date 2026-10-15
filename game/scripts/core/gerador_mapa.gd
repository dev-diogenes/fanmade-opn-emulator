class_name GeradorMapa
extends RefCounted
## Gera um mapa-múndi procedural a partir de uma seed (mesma seed = mesmo mapa).
## Terreno por ruído; início à esquerda, objetivo (covil) à direita; vilas,
## encontros e eventos espalhados. Garante caminho do início ao objetivo.


static func gerar(semente: int) -> MapaHex:
	var cfg := DadosJogo.ler("mapa")
	for tentativa in 30:
		var mapa := _tentar(semente + tentativa * 7919, cfg)
		if mapa != null:
			return mapa
	push_error("GeradorMapa: não achou mapa conectado para a seed %d" % semente)
	return _tentar(semente, cfg, true)


static func _tentar(semente: int, cfg: Dictionary, forcar: bool = false) -> MapaHex:
	var mapa := MapaHex.new(cfg.terrenos)
	mapa.colunas = int(cfg.tamanho.colunas)
	mapa.linhas = int(cfg.tamanho.linhas)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = 0.12
	ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var limiares: Array = cfg.geracao.limiares_ruido

	for linha in mapa.linhas:
		for coluna in mapa.colunas:
			var h := Hex.de_offset(coluna, linha)
			var v := ruido.get_noise_2d(coluna * 1.0, linha * 1.0)
			var t := "campo"
			for l in limiares:
				if v <= float(l.ate):
					t = l.terreno
					break
			mapa.celulas[h] = {"terreno": t, "conteudo": {}, "revelado": false}

	# Início (coluna 0-1) e objetivo (últimas colunas), forçados a terreno firme.
	var inicio := Hex.de_offset(1, mapa.linhas / 2)
	var objetivo := Hex.de_offset(mapa.colunas - 2, rng.randi_range(1, mapa.linhas - 2))
	for h in Hex.area(inicio, 1):
		if mapa.tem(h) and not mapa.passavel(h):
			mapa.celulas[h].terreno = "campo"
	mapa.celulas[inicio].terreno = "cidade"
	mapa.celulas[objetivo].terreno = "ruina"
	mapa.definir_conteudo(inicio, {"tipo": "inicio", "nome": "Ponto de encontro"})
	mapa.definir_conteudo(objetivo, {"tipo": "objetivo", "encontro": "covil"})

	if not forcar and mapa.caminho(inicio, objetivo, false).is_empty():
		return null

	# Ruínas decorativas
	for i in int(cfg.geracao.ruinas_por_mapa):
		var h := _hex_livre(mapa, rng, inicio, 2)
		if h != Vector2i(-999, -999):
			mapa.celulas[h].terreno = "ruina"

	# Vilas no meio do caminho
	for i in int(cfg.geracao.vilas):
		var h := _hex_livre(mapa, rng, inicio, 4, mapa.colunas / 3, mapa.colunas * 2 / 3)
		if h != Vector2i(-999, -999):
			mapa.celulas[h].terreno = "cidade"
			mapa.definir_conteudo(h, {"tipo": "vila", "nome": "Vila"})

	# Encontros e eventos
	var encontros: Array = DadosJogo.ler("encontros").encontros.filter(func(e): return int(e.nivel) <= 1)
	var minimo := int(cfg.geracao.distancia_minima_do_inicio)
	for i in int(cfg.geracao.encontros):
		var h := _hex_livre(mapa, rng, inicio, minimo)
		if h != Vector2i(-999, -999):
			var e: Dictionary = encontros[rng.randi_range(0, encontros.size() - 1)]
			mapa.definir_conteudo(h, {"tipo": "encontro", "encontro": e.id})
	var eventos: Array = DadosJogo.ler("eventos").eventos
	var ordem := range(eventos.size())
	for i in range(ordem.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = ordem[i]
		ordem[i] = ordem[j]
		ordem[j] = tmp
	for i in mini(int(cfg.geracao.eventos), eventos.size()):
		var h := _hex_livre(mapa, rng, inicio, 2)
		if h != Vector2i(-999, -999):
			mapa.definir_conteudo(h, {"tipo": "evento", "evento": eventos[ordem[i]].id})

	# Se o conteúdo bloqueou todo caminho até o objetivo, tenta de novo.
	if not forcar and mapa.caminho(inicio, objetivo, true).is_empty() and _sem_rota_por_conteudo(mapa, inicio, objetivo):
		return null
	mapa.revelar(inicio, int(cfg.visao))
	return mapa


## O objetivo precisa ser alcançável passando por hexes vazios OU resolvendo conteúdos;
## como conteúdos são resolvidos ao entrar, basta existir caminho sem considerar conteúdo.
static func _sem_rota_por_conteudo(mapa: MapaHex, inicio: Vector2i, objetivo: Vector2i) -> bool:
	return mapa.caminho(inicio, objetivo, false).is_empty()


static func _hex_livre(mapa: MapaHex, rng: RandomNumberGenerator, inicio: Vector2i, dist_min: int, col_min: int = 0, col_max: int = 999) -> Vector2i:
	for _t in 200:
		var col := rng.randi_range(maxi(0, col_min), mini(mapa.colunas - 1, col_max))
		var lin := rng.randi_range(0, mapa.linhas - 1)
		var h := Hex.de_offset(col, lin)
		if mapa.passavel(h) and mapa.conteudo(h).is_empty() and Hex.distancia(h, inicio) >= dist_min:
			return h
	return Vector2i(-999, -999)
