# Conclusão do caso e PP pelo livro

> Status: **v0.1**, 21/10/2026. Continuação da conferência com o livro: o fim da missão e os pontos de prestígio.

## O que o livro diz

- **Ficha de investigação (p.79):** no fim da missão, só o que está na ficha do grupo vale para a **Conclusão do Caso**.
- **Pontos de prestígio (p.51 e p.53, Tabela 3.2):** ao voltar à sede, o grupo é avaliado pela eficiência em solucionar o caso e recolher pistas:

| Evento | PP |
|---|---|
| Solução do caso | +10 |
| Pista adicional encontrada | +2 |
| Morte de inocente | −2 |
| Morte de membro do grupo | −5 |

Os números do jogo (`patentes.json`) já batiam com a tabela. Duas regras não:

| Antes | Agora |
|---|---|
| "Solução do caso" valia em qualquer vitória, mesmo com a ficha em branco | Só vale quando a ameaça cai **e** a ficha responde o objetivo do caso: **quem** está por trás e **o quê** pretende (`casos.json`, `solucao.exige`). "Onde" não é exigido, porque chegar ao covil já o encontra |
| A morte de inocentes não existia | Novo efeito de evento `inocente_morto`: −2 PP cada um, no relatório da Base |

## Na tela: Conclusão do Caso

A folha de fim de missão virou a **Conclusão do Caso**:

1. **O que a ficha responde:** cada pergunta, inclusive a da investigação ampliada, com [x] e a resposta, ou [ ].
2. **O veredito:** "Caso solucionado", ou "Ameaça contida, caso em aberto", dizendo o que falta na ficha.
3. **Os números:** turno, Membrana, pistas e inocentes mortos.

O carimbo tem três estados:

| Carimbo | Quando |
|---|---|
| **CASO SOLUCIONADO** (verde) | A ameaça caiu e a ficha responde quem e o quê |
| **AMEAÇA CONTIDA** (âmbar) | A ameaça caiu, mas a ficha não responde o objetivo |
| **MISSÃO FRACASSADA** (vermelho) | A ameaça não caiu |

No relatório da Base, quando a ficha não fecha o caso, aparece a linha "Caso em aberto: a ficha não responde o objetivo (+0)".

![Conclusão do Caso](conc37_fim.png)

## Pedido de socorro (evento novo)

Uma mulher grita numa casa trancada por fora, e algo arrasta os móveis lá dentro. As opções:

| Opção | Teste | Se der certo | Se der errado |
|---|---|---|---|
| Arrombar a porta | Atletismo 15 | +2 SAN e uma pista | Inocente morto e 1d6 de SAN |
| Acalmar pela janela | Diplomacia 18 | Uma pista | Inocente morto e 1d4 de SAN |
| Entrar pelos fundos | Furtividade 15 | +2 SAN | Inocente morto e 1d6 de dano |
| Seguir em frente | Sem teste | — | Os gritos param: inocente morto e 1d4 de SAN |

É a primeira escolha moral do mapa: ajudar custa um teste, e ignorar custa prestígio.

## Testes

Total: **526**.
- **Vitória com a ficha completa:** +10 de solução e +2 por pista.
- **Vitória sem "o quê" na ficha:** sem a solução do caso, −2 pelo inocente, e a linha "Caso em aberto" no relatório.
- **Solução do caso:** exige quem e o quê, e não onde.
- **Inocente morto:** conta na missão e vai no save.
