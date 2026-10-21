# PP por pista adicional, como no livro

> Status: **v0.1**, 21/10/2026. Item 4 do playtest (docs/41 e 42): PP demais por pista.

## A regra

A Tabela 3.2 (p.53) dá **+10** pela solução do caso e **+2 por pista adicional encontrada**. O livro não detalha o "adicional". A leitura adotada:

- **Necessárias:** as pistas que cada pergunta da ficha pede (`pistas_necessarias`, 2 por pergunta). Elas já são pagas pela solução do caso.
- **Adicionais:** cada pista **além** disso, em qualquer pergunta, inclusive a da investigação ampliada. Vale +2.

| | Antes | Agora |
|---|---|---|
| O que valia +2 | **Toda** pista, mais todo evento bem-sucedido, mesmo sem pista (`Missao.pistas`) | Só as pistas além das necessárias (`Caso.pistas_adicionais()`) |
| Missões sem caso (antigas) | — | Continuam com as pistas reunidas, como antes |

O mapa continua mostrando "Pistas: N" com tudo o que foi reunido. Só o PP mudou.

## Medido (`dev/playtest_auto.gd`, 10 seeds)

| Perfil | PP por missão antes | Agora |
|---|---|---|
| Investigador (deduz assim que dá) | 32,6 | **12,4** (de 10 a 16) |
| Pressa (deduz só no fim) | 37,7 | **17,9** (de 4 a 32) |

**Progressão:**

| Patente | PP | Missões (com cerca de 12 PP por missão) |
|---|---|---|
| Operador | 20 | 2 |
| Agente especial | 50 | ~4 |
| Oficial de operações | 100 | ~8 |
| Agente de elite | 200 | ~16 |

O exemplo do livro (p.51) é um agente que ganha **14 PP** numa missão.

Quem demora mais para deduzir junta mais pistas e ganha mais PP, mas paga com a Membrana, que termina em 16 (docs/42).

## Testes

Total: **539**.
- **Vitória com 4 + 4 + 3 pistas** em perguntas que pedem 2: são 5 adicionais, +10, com a solução.
- **Duas pistas por pergunta, mais 9 "pistas" do mapa:** só os +10 da solução.
