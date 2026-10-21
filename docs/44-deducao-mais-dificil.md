# Dedução mais difícil: pistas espalhadas e mais testemunhas

> Status: **v0.1**, 21/10/2026. Item 3 do playtest (docs/41): a dedução estava fácil. Uma cena só dava duas pistas firmes da mesma pergunta, e os depoimentos incertos quase não apareciam.

## O que mudou

### Um ponto firme por pergunta em cada cena
Toda cena agora tem **um ponto firme para quem, um para o quê e um para onde**, e **uma testemunha**. Para ter duas pistas firmes da mesma pergunta, o grupo precisa juntar **fontes diferentes**:
- outra cena;
- um evento com pista;
- o interrogatório de um rendido (docs/40);
- a reviravolta, que reaproveita os pontos de perguntas já resolvidas.

Um teste garante a regra em todas as cenas.

| Cena | Firmes | Testemunha (sobre) |
|---|---|---|
| Casa abandonada | escrivaninha (quem), porão (o quê, antes era quem), computador (onde) | a vizinha (quem; antes era o quê) |
| Capela em ruínas | inscrições, altar, livro de registros | o zelador (onde) |
| Acampamento na mata | barraca, fogueira, rastros | **o rádio** (quem): uma gravação de alguém em pânico. Antes, o rádio era uma segunda pista firme de onde |
| Escola rural | quadro-negro, diário, cantina | a merendeira (quem) |
| Posto de estrada | câmera, caixa, **banheiro** (onde; antes era o quê) | o caminhoneiro (onde) |

### Mais dúvida nas testemunhas
- O depoimento só sai **firme** se o teste passar por **10 ou mais**. Antes bastavam 5.
- **Examinar com treino** (a pista central, docs/14) continua **firme**: é a recompensa do treino.

## Medido (`dev/playtest_auto.gd`, 10 seeds; números brutos em `docs/playtest44.json`)

| | Antes (docs/43) | Agora |
|---|---|---|
| Depoimentos incertos por missão | 0,2 | **1,1 a 1,3** |
| Cenas de investigação por missão | 2,6 | **2,9** (investigador) e **3,8** (pressa) |
| Pistas firmes | 7,8 | 7,4 |
| Turnos do mundo | 8,0 | 7,9 (investigador) e 9,9 (pressa) |
| PP | 12,4 | 11,9 |
| Caso solucionado | 100% | 90% |

O jogador simulado só acusa quando tem certeza, então as acusações erradas continuam poucas (0,3). Um jogador de verdade, tentado pelo "?", vai errar mais. Isso é o que o próximo playtest com a interface precisa observar.

## Testes

Total: **540**.
- **Cenas:** toda cena tem um ponto firme por pergunta e uma testemunha.
