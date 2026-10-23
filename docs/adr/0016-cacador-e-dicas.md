# ADR 0016: o caçador como encontro da missão e as dicas fora dos testes

- **Status:** aceito, 23/10/2026
- **Contexto:**
  - docs/74;
  - a caça noturna (docs/53);
  - o subgênero (docs/71, ADR 0014);
  - o tutorial (docs/07).

## Contexto

A Perseguição precisava de um caçador que sobrevive à derrota, sobe de degrau e volta. Os encontros do jogo vivem em `encontros.json` e são citados pelo id no conteúdo do hex. Não havia um encontro de uma criatura só para cada degrau.

As dicas de primeira vez precisam lembrar o que a pessoa já viu, de uma partida para outra. Os testes e as sondas abrem as mesmas telas e não podem marcar nada nas preferências do jogador.

## Decisão

- **O caçador é estado da missão** (`Missao.cacador`):
  - a lista de degraus, o degrau atual, o encontro, as derrotas, o turno da volta e se foi banido;
  - vai no save da missão.
- **Os encontros dele são criados na missão:** `cacador_<ameaça>` entra em `extras.encontros`, ao lado dos encontros das missões da comunidade.
  - O conteúdo do hex continua o mesmo: `{"tipo": "encontro", "encontro": id, "caca": true, "cacador": true}`.
  - A arena, o piloto, os presságios e o painel do mestre o leem como qualquer encontro.
- **O encontro pendente guarda `cacador`**, também no save. Assim, vencer, fugir ou cair sabe o que fazer com ele.
- **As dicas ficam nas preferências da máquina** (`dicas`, `dicas_vistas`), fora do save da carreira, como o tutorial.
  - Só aparecem com `Dicas.ativas`, que a tela de título liga quando abre de verdade.
  - Testes e sondas não passam por ela e ficam sem dicas.

## Consequências

- **Saves antigos** não têm caçador. Uma missão de Perseguição salva antes deste ADR continua sem ele.
- **A escada é dado:** um degrau novo, ou outro elemento, é uma linha em `subgeneros.json`.
- **Uma sonda que quiser ver as dicas** liga `Dicas.ativas` e troca `Preferencias.caminho`.
