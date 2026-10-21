# Investigação pelo livro e depoimentos incertos

> Status: **v0.1**, 21/10/2026. Continuação de docs/32 (Mistério): pistas duvidosas e testemunhas que se contradizem. Antes, conferimos a cena de investigação com o livro.

## Auditoria: a cena de investigação contra o livro (p.79-81)

| Regra do livro | No jogo |
|---|---|
| Ficha de investigação do grupo: resumo, objetivo, perguntas e espaço para as pistas. O grupo preenche por consenso, e só vale o que estiver na ficha | ✔ Quadro do caso. Com a dedução (docs/32), quem preenche a resposta é o grupo, ao acusar |
| Pista básica no começo da cena e pistas complementares | ✔ `pista_basica` e os pontos de interesse |
| Rodadas abstratas, uma ação por personagem por rodada | ✔ |
| Procurar pistas: DT 15 (simples), 20 (complexa), 25+ (vaga ou muito complexa) | ✔ As DTs dos pontos seguem essa escala |
| Ação sem chance de sucesso: falha sem teste e gasta a ação | ✔ Sem a perícia do ponto, não há como procurar ali |
| Facilitar investigação: DT 15 a 25, +2 no próximo teste de cada aliado, não cumulativo | ✔ |
| Usar habilidades e itens, com +5 quando a habilidade ajuda | ✔ Ação extra, Na Trilha Certa e os selos de habilidade |
| Ajudar | ✔ |
| Urgência de 6, 5, 4, 3 ou 2 rodadas; a cada 3 falhas, −1 rodada (opcional) | ✔ |
| Penalidades ao estourar a urgência: chefe com mais PV, reforços, sem descanso | ✔ Chefe mais forte, encontro no hex e Membrana |
| Investigação ampliada: perguntas novas no meio do caso | ✗ Ainda não. Fica como próximo conteúdo |

Duas exceções, ambas design do jogo:
- **A pista central** (docs/14) é inspirada no GUMSHOE: quem tem treino acha a pista sem rolar.
- **A escalada da serra** (docs/34) segue o pedido do playtest (um 20 nos dados de Agilidade). O livro trataria isso com um teste estendido de Atletismo (p.77).

## Depoimentos incertos (design do jogo)

O livro não tem pistas falsas: quem decide se a informação é boa é o mestre. Para dar ao jogador o trabalho de desconfiar, as **testemunhas** passaram a poder se enganar.

- **Testemunhas:** os pontos com `"depoimento": true` (a vizinha, o zelador, a merendeira e o caminhoneiro).
- **Quando o depoimento é incerto:** quando o teste passa **por menos de 5** (`MARGEM_DEPOIMENTO_FIRME`). Aí a testemunha hesita, e há duas saídas:
  - **acerta:** dá o próximo traço do culpado verdadeiro;
  - **se engana:** dá um traço de outro candidato.
- **O jogador nunca sabe** qual das duas foi. A pista aparece com **"?"** no quadro, na ficha de suspeitos (etiqueta âmbar) e no painel do caso no mapa ("data marcada?").
- **A garantia continua:** só as pistas **firmes** contam para "duas pistas diferentes deixam um só suspeito". Um depoimento incerto ajuda a desconfiar, mas pode levar a uma acusação errada (Membrana −5).
- **Passar por 5 ou mais** dá um depoimento firme, como antes.
- **Online:** quem decide se a testemunha se enganou é uma semente da cena, do ponto, da rodada e do número de pistas. Ela sai igual nas duas máquinas e **não gasta a fila dos Dados**, então as rolagens seguintes não mudam.

| Quadro: a foto com "?" | Ficha: o traço incerto em âmbar |
|---|---|
| ![Quadro](dep35_quadro.png) | ![Ficha](dep35_ficha.png) |

## Testes

Total: **520**.
- **Testemunha enganada:** dá um traço de outro candidato, não entra nos firmes e não quebra a dedução por duas pistas firmes.
- **Testemunha certa:** dá o traço verdadeiro, mas fica marcada como incerta mesmo assim.
- **Na cena:** a vizinha é testemunha; o depoimento incerto fica marcado no caso e no resultado da cena.
