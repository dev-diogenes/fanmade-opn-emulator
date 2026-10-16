# Missões da comunidade — formato `mission.json` v1

Qualquer pessoa pode criar uma missão para o jogo: pelo **Editor de missões** (botão na Base da Ordem) ou escrevendo o JSON à mão. Este documento descreve o formato.

## Onde ficam

- `res://data/missoes/`: as missões que vêm com o jogo (por exemplo, `a_capela_do_morro.json`).
- `user://missoes/`: as missões do jogador. No Windows: `%APPDATA%\Godot\app_userdata\Ordem Paranormal- Fanmade (WIP)\missoes\`.

A Base lista as duas pastas. Uma missão com erros aparece marcada "(com erros)", e a Base mostra o motivo; ela não começa até ser corrigida.

## Estrutura

```json
{
  "formato": "opn-missao",
  "versao": 1,
  "id": "a_capela_do_morro",
  "titulo": "A Capela do Morro",
  "autor": "Seu nome",
  "descricao": "Aparece na Base.",
  "briefing": "Aparece no registro quando a missão começa.",
  "nex_recomendado": 5,
  "membrana_inicial": 90,
  "mapa": { ... },
  "caso": { ... },
  "eventos": [ ... ],
  "encontros": [ ... ],
  "ameacas": { ... },
  "covil": { ... },
  "opcoes": { "surgimentos": "padrao" }
}
```

Só `formato`, `versao`, `titulo` e `mapa` são obrigatórios. Sem `caso`, o caso é sorteado; sem `covil`, vale o covil do jogo, que muda com o NEX do grupo.

### `mapa`

**Desenhado à mão:** uma linha de texto por linha do mapa, uma letra por hex.

| Letra | Terreno | Custo |
|---|---|---|
| `c` | campo | 1 |
| `e` | estrada | 1 |
| `u` | cidade | 1 |
| `r` | ruínas | 1 |
| `f` | mata fechada | 2 |
| `p` | pântano | 2 |
| `m` | morro | 2 |
| `a` | água | não dá para passar |

```json
"mapa": {
  "terreno": ["fffccccmmfff", "fccccecmmcff", "ccuccecccrcf", "cccceeeeccrc"],
  "inicio": [0, 3],
  "nome_inicio": "Estrada de chegada",
  "objetivo": [11, 3],
  "conteudo": [
    {"em": [2, 2], "tipo": "vila", "nome": "Santa Luzia"},
    {"em": [3, 1], "tipo": "evento", "evento": "badalada"},
    {"em": [5, 3], "tipo": "encontro", "encontro": "procissao"},
    {"em": [9, 2], "tipo": "investigacao", "cena": "capela"}
  ]
}
```

- As posições são `[coluna, linha]`, contando do zero, a partir do canto de cima à esquerda.
- O mapa tem no máximo 30 colunas e 20 linhas.
- `inicio` é onde o grupo começa. `objetivo` é o covil: vencer o combate dele cumpre a missão.
- Precisa existir um caminho por terra do início ao objetivo.
- Tipos de conteúdo:
  - `vila`: lugar de descanso;
  - `evento`: um teste de perícia;
  - `encontro`: um combate;
  - `investigacao`: uma cena de investigação (`casa_abandonada`, `capela` ou `acampamento`).
- Eventos e encontros podem ser da missão ou do jogo, pelo `id`. Veja `data/jogo/eventos.json` e `data/jogo/encontros.json`.

**Gerado por seed:** em vez de `terreno`, use `"semente": 1234`. O terreno sai como no modo procedural. Com `"conteudo_procedural": true`, o mapa também ganha os encontros, eventos, vilas e investigações sorteados; sem isso, só o que você puser em `conteudo`. `inicio` e `objetivo` são opcionais nesse caso.

### `caso` (opcional)

Troca partes da ficha do caso. Os textos das pistas usam essas partes.

```json
"caso": {
  "sujeito": {"id": "sineiro", "nome": "o antigo sineiro da capela", "chefe_titulo": "o Sineiro"},
  "acao": {"id": "chamar", "texto": "toca os sinos para chamar algo do Outro Lado"},
  "local": {"id": "torre", "nome": "a torre da capela"},
  "objetivo": "Descobrir quem toca os sinos e silenciá-los."
}
```

Quando o grupo descobre *quem* é o culpado, o chefe passa a se chamar `chefe_titulo`.

### `eventos`

```json
{"id": "badalada", "titulo": "Badalada fora de hora",
 "texto": "Os sinos tocam ao meio-dia.",
 "pericia": "vontade", "dt": 15,
 "sucesso": {"texto": "Você conta as badaladas.", "efeitos": [{"tipo": "revelar_objetivo"}]},
 "falha": {"texto": "O som entra nos ossos.", "efeitos": [{"tipo": "dano_mental", "valor": "1d6"}]}}
```

- A perícia é o id do livro: `vontade`, `percepcao`, `investigacao`, `ocultismo`, `diplomacia` etc.
- Efeitos possíveis:
  - `dano`, `dano_mental`, `cura`, `recupera_pe` e `recupera_san`, com `valor` como número ou dados ("1d6");
  - `membrana`, com `valor` positivo para fortalecer ou negativo para enfraquecer;
  - `revelar_raio`, com `valor` em hexes;
  - `revelar_objetivo`, sem valor.

### `encontros`

```json
{"id": "procissao", "nome": "Procissão da madrugada", "nivel": 0, "ameacas": ["iniciado", "fiel_do_sino"]}
```

- `ameacas` lista ameaças do livro (`zumbi_de_sangue`, `bandido`, `investido` etc., em `data/rulesets/op2022/ameacas.json`), do jogo (`data/jogo/ameacas.json`) ou da própria missão.
- `nivel` só importa para os surgimentos: o nível mínimo da Membrana para aquele encontro aparecer sozinho no mapa (0 a 3).
- No combate, entram só as ameaças que cabem no orçamento de VD do grupo (p.187), da mais forte para a mais fraca.

### `ameacas` (opcional)

Ameaças próprias, no formato do jogo:

```json
"o_sineiro": {"nome": "O Sineiro", "nivel": 2, "arma": "mordida_sangue",
  "ficha": {"pv": 40, "defesa": 14, "vd": 25, "elemento": "sangue", "criatura": true,
            "atributos": {"agi": 2, "for": 3, "vig": 3},
            "pericias": {"luta": {"dados": 2, "bonus": 5}, "vontade": {"dados": 2, "bonus": 5}},
            "presenca_perturbadora": {"dt": 15, "dano": "1d6", "nex": 30}}}
```

- `arma` pode ser uma arma do livro (`faca`, `machete`…), uma das armas extras do jogo (`garras`, `mordida_sangue`) ou o objeto da arma.
- Também vale o formato do livro, com `"ataques": [...]` na ficha.
- A ficha aceita o mesmo que as ameaças do jogo: `resistencias`, `vulnerabilidades`, `imunidades`, `habilidades`, `enigma` e outros campos.

### `covil` (opcional)

```json
"covil": {"nome": "A Torre da Capela", "ameacas": ["o_sineiro", "fiel_do_sino"]}
```

A primeira ameaça é o chefe e sempre está lá. As outras entram até 1,5 × o NEX somado do grupo.

### `opcoes`

`surgimentos` define o que aparece no mapa quando a Membrana enfraquece:
- `"padrao"`: os encontros do jogo;
- `"proprios"`: só os encontros da missão;
- `"nenhum"`: nada aparece.

## Direitos

Missões da comunidade são conteúdo de fã. Não copie textos do livro: escreva com as suas palavras, como pede o [documento legal](03-legal-e-conteudo.md).
