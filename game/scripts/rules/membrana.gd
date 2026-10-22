class_name Membrana
extends RefCounted
## Estado da Membrana na região da missão (o "medidor de Caos" do jogo).
## Enfraquece com o tempo e com ações perigosas; em cada limiar o mundo fica mais hostil.

signal mudou(valor: int, delta: int, motivo: String)
signal estado_mudou(estado: Dictionary, anterior: Dictionary)

const ARQUIVO := "res://data/jogo/membrana.json"

var valor := 100
var config: Dictionary = {}
var historico: Array[Dictionary] = []   ## [{motivo, delta, valor}]


static func carregar_padrao() -> Membrana:
	var m := Membrana.new()
	var texto := FileAccess.get_file_as_string(ARQUIVO)
	var dados = JSON.parse_string(texto)
	assert(dados is Dictionary, "membrana.json inválido")
	m.config = dados
	m.valor = int(dados.valor_inicial)
	return m


## Aplica um evento pelo nome (ver "eventos" no JSON). `vezes` multiplica (ex.: 3 rodadas).
func registrar(evento: String, vezes: int = 1) -> int:
	assert(config.eventos.has(evento), "Evento de Membrana desconhecido: %s" % evento)
	return alterar(int(config.eventos[evento]) * vezes, evento)


## Ritual: custo fixo mais um extra por círculo.
func registrar_ritual(circulo: int) -> int:
	return alterar(int(config.eventos.ritual_conjurado) + int(config.eventos.ritual_por_circulo) * circulo, "ritual_conjurado")


func alterar(delta: int, motivo: String = "") -> int:
	var anterior := estado()
	var antes := valor
	valor = clampi(valor + delta, int(config.minimo), int(config.maximo))
	var real := valor - antes
	historico.append({"motivo": motivo, "delta": real, "valor": valor})
	mudou.emit(valor, real, motivo)
	var atual := estado()
	if atual.id != anterior.id:
		estado_mudou.emit(atual, anterior)
	return real


## Estado atual (o de maior "a_partir_de" que o valor alcança).
func estado() -> Dictionary:
	return estado_de(valor)


## O estado para um valor qualquer (a previsão da linha do tempo, docs/53).
func estado_de(v: int) -> Dictionary:
	var melhor: Dictionary = {}
	for e in config.estados:
		if v >= int(e.a_partir_de) and (melhor.is_empty() or int(e.a_partir_de) > int(melhor.a_partir_de)):
			melhor = e
	return melhor


func nivel_ameaca() -> int:
	return int(estado().get("nivel_ameaca", 0))


func rompida() -> bool:
	return estado().get("id", "") == "rompida"


func para_dicionario() -> Dictionary:
	return {"valor": valor, "historico": historico.duplicate(true)}


func de_dicionario(d: Dictionary) -> void:
	valor = int(d.get("valor", config.get("valor_inicial", 100)))
	historico.clear()
	for h in d.get("historico", []):
		historico.append(h)
