class_name Cifra
extends RefCounted
## O alfabeto de sigilos da Ordem (docs/77). Na lore, os sigilos do Conhecimento formam palavras,
## um sigilo por letra (wiki, "Símbolos Ocultistas"). O jogo tem um alfabeto PRÓPRIO, com 26
## glifos desenhados por código (`Sigilo.glifo`), e não copia o oficial. Os cultos assinam o
## símbolo com o nome escrito nele; as letras que a Ordem já leu ficam na carreira e ajudam a
## ler os próximos símbolos.
## Lógica pura: sem nós de cena.

const ALFABETO := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
const _ACENTOS := {"Á": "A", "À": "A", "Â": "A", "Ã": "A", "Ä": "A", "É": "E", "È": "E", "Ê": "E", "Ë": "E",
	"Í": "I", "Ì": "I", "Î": "I", "Ï": "I", "Ó": "O", "Ò": "O", "Ô": "O", "Õ": "O", "Ö": "O",
	"Ú": "U", "Ù": "U", "Û": "U", "Ü": "U", "Ç": "C", "Ñ": "N"}


## Só as letras de A a Z, em maiúsculas e sem acento. Espaços viram um espaço só; o resto some.
static func normalizar(texto: String) -> String:
	var saida := ""
	for ch in texto.to_upper():
		var c: String = _ACENTOS.get(ch, ch)
		if ALFABETO.contains(c):
			saida += c
		elif c == " " and not saida.ends_with(" ") and saida != "":
			saida += " "
	return saida.strip_edges()


## Índice de cada letra no alfabeto (0..25); os espaços ficam como -1.
static func cifrar(texto: String) -> Array:
	var saida: Array = []
	for c in normalizar(texto):
		saida.append(ALFABETO.find(c))
	return saida


## As letras diferentes do texto, em ordem alfabética.
static func letras(texto: String) -> Array:
	var vistas: Array = []
	for c in normalizar(texto):
		if c != " " and not c in vistas:
			vistas.append(c)
	vistas.sort()
	return vistas


## Como a Ordem lê o texto com as letras que conhece: as outras ficam como "_".
static func leitura(texto: String, conhecidas: Array) -> String:
	var saida := ""
	for c in normalizar(texto):
		saida += c if (c == " " or c in conhecidas) else "_"
	return saida


## Quantas letras do texto a Ordem ainda não conhece.
static func faltam(texto: String, conhecidas: Array) -> int:
	return letras(texto).filter(func(c): return not c in conhecidas).size()


## Junta letras novas às conhecidas, sem repetir, em ordem alfabética.
static func aprender(conhecidas: Array, texto: String) -> Array:
	var saida := conhecidas.duplicate()
	for c in letras(texto):
		if not c in saida:
			saida.append(c)
	saida.sort()
	return saida
