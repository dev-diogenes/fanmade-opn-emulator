# Mirante no alto da serra

> Status: **v0.1**, 21/10/2026. Item 5 do playtest (docs/41): a serra não tinha motivo para ser escalada. O 20 aparecia 2,4 vezes por missão, mas só 0,2 subidas aconteciam.

## Como funciona

- **Um mirante por serra:** cada serra ganha um mirante, marcado com um **▲** no mapa.
- **O que tem lá em cima:** um **achado**, sorteado na geração do mapa pela posição, sem gastar o rng (a seed do resto não muda).
- **Quem pega:** só quem sobe, no turno em que um dado de movimento dá 20 (docs/34).
- **Uma vez só:** o achado vale uma vez, e o mirante se esgota.

| Achado | O que acontece |
|---|---|
| **Fumaça entre as árvores** | Lá de cima se vê o covil: ele fica **localizado**, o que abre o selo (docs/42) |
| **Movimento no vale** | Uma **pista** para o caso |
| **Vento frio** | +1d6 de SAN e +2 de PE |
| **Esconderijo da Ordem** | +2d6 de PV e uma **pista** |

Os achados ficam em `mapa.json` (`achados_da_serra`), então dá para acrescentar outros sem mexer no código.

**A dica da serra:**
- "Escalável: só com um 20 nos dados de movimento (custo 2)". Antes dizia "Intransponível", o que confundia;
- "▲ Mirante: algo espera lá em cima".

Isso dá um motivo concreto para gastar PE de Foco no movimento: cada dado a mais é mais uma chance de tirar o 20.

![O mirante ▲ no alto da serra](mir45_serra.png)

## Testes

Total: **542**.
- **Mirantes:** toda serra tem um.
- **Achados:** "Movimento no vale" vira pista e esgota o mirante; "Fumaça entre as árvores" localiza o covil.

## Não medido

O jogador simulado (`dev/playtest_auto.gd`) não desvia o caminho para subir a serra. Ainda não está medido quanto o mirante atrai um jogador de verdade.
