class_name CodigoSala
extends RefCounted
## Código de sala do online (docs/29, C8): o endereço IPv4 e a porta do host escritos em
## 10 letras e números fáceis de ditar ("K7RQ2-M9XAD"), no lugar de "192.168.0.12" e "7777".
## Não é um servidor de salas: o código só guarda o endereço. Quem entra precisa alcançar o
## host (mesma rede local, VPN como ZeroTier/Radmin, ou porta aberta no roteador).
##   var c := CodigoSala.gerar("192.168.0.12", 7777)   # "XXXXX-XXXXX"
##   var alvo := CodigoSala.ler(c)                        # {"ip": "192.168.0.12", "porta": 7777}

## Base 32 de Crockford: 32 símbolos sem I, L, O e U. Ao ler, O vale 0, I e L valem 1 e U vale V
## (quem dita ou copia à mão erra menos).
const ALFABETO := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
const TAMANHO := 10


## 48 bits (4 do IPv4 + 2 da porta) e 2 bits de conferência = 50 bits = 10 símbolos de 5 bits.
static func gerar(ip: String, porta: int) -> String:
	var partes := ip.split(".")
	if partes.size() != 4 or porta <= 0 or porta > 65535:
		return ""
	var n := 0
	for p in partes:
		if not p.is_valid_int() or int(p) < 0 or int(p) > 255:
			return ""
		n = (n << 8) | int(p)
	n = (n << 16) | porta
	n = (n << 2) | _conferencia(n)
	var base := ALFABETO.length()
	var s := ""
	for i in TAMANHO:
		s = ALFABETO[n % base] + s
		n /= base
	return s.left(5) + "-" + s.right(5)


## Lê um código (aceita minúsculas, espaços e sem o hífen) ou, como atalho do modo avançado,
## "IP" e "IP:porta". Devolve {} quando não dá para entender ou a conferência falha.
static func ler(texto: String, porta_padrao: int = Rede.PORTA_PADRAO) -> Dictionary:
	var t := texto.strip_edges()
	if t.count(".") == 3:
		var ip := t.get_slice(":", 0)
		var porta := t.get_slice(":", 1).to_int() if ":" in t else porta_padrao
		return {"ip": ip, "porta": porta} if gerar(ip, porta) != "" else {}
	var limpo := t.to_upper().replace("-", "").replace(" ", "").replace("O", "0").replace("I", "1").replace("L", "1").replace("U", "V")
	if limpo.length() != TAMANHO:
		return {}
	var base := ALFABETO.length()
	var n := 0
	for ch in limpo:
		var v := ALFABETO.find(ch)
		if v < 0:
			return {}
		n = n * base + v
	var conf := n & 3
	n >>= 2
	if n >= (1 << 48) or _conferencia(n) != conf:
		return {}
	var porta := n & 0xFFFF
	n >>= 16
	var ip := "%d.%d.%d.%d" % [(n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255]
	return {"ip": ip, "porta": porta} if porta > 0 else {}


## Que rede é esta, pelo endereço (para o host saber qual código passar). Ordem de uso.
static func tipo_de_rede(ip: String) -> Array:
	var p := ip.split(".")
	if p.size() != 4:
		return [9, "outra rede"]
	var a := int(p[0])
	var b := int(p[1])
	if a == 192 and b == 168:
		return [0, "rede local (Wi-Fi ou cabo)"]
	if a == 10:
		return [1, "rede local ou VPN"]
	if a == 172 and b >= 16 and b <= 31:
		return [2, "rede local ou máquina virtual"]
	if a == 26:
		return [3, "Radmin VPN"]
	if a == 25:
		return [3, "Hamachi"]
	if a == 100 and b >= 64 and b <= 127:
		return [3, "Tailscale ou ZeroTier"]
	if a == 127:
		return [8, "só esta máquina"]
	return [5, "internet (precisa da porta aberta)"]


static func _conferencia(n: int) -> int:
	var soma := 0
	for i in 6:
		soma += (n >> (8 * i)) & 255
	return soma & 3
