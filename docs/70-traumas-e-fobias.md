# Traumas que ficam: a fobia do elemento

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: "Pode implementar trauma e fobia" (AG4 do relatório "Melhorias pelo universo de Ordem Paranormal"). Estende docs/48 (interlúdio) e docs/49 (efeito de insanidade).
>
> **Não é regra do livro.** O livro não tem fobia: o efeito de insanidade dura no máximo até o fim da missão (p.111). Esta é uma camada do jogo, inspirada no estresse de Darkest Dungeon e nos traumas de Arkham Horror LCG. Os números ficam em `data/jogo/traumas.json`, fora do ruleset.

## A ideia

Até aqui, enlouquecer numa missão não deixava marca: na Base tudo sumia. Agora quem passa do limite pode voltar com um medo que fica.

Esse medo é uma **fobia do elemento do caso**: Sangue, Morte, Conhecimento, Energia ou Medo. Não chega a ser uma doença com nome clínico. É o agente que viu demais daquele lado do Outro Lado.

## Como funciona

1. **Quem fica com trauma.** No fim da missão, o agente que chegou a **enlouquecer** testa **Vontade (DT 20)**. Enlouquecer é ter SAN 0, quando o efeito de insanidade passa a durar até o fim da missão. Se falhar, ganha a fobia do elemento do caso. Uma missão sem caso, como as da campanha e da comunidade, dá fobia do **Medo**.
2. **O que a fobia faz.** No começo de um combate com uma **criatura** do mesmo elemento, o agente fica **abalado** (−1 dado, p.320) até o fim da cena. Diante de pessoas ou de outros elementos, nada muda.
3. **O tratamento.** Na **Enfermaria** da Base, cada agente com trauma tem o botão **Tratar**:
   - o agente fica **fora da próxima missão** e não pode ser escolhido para o grupo;
   - quando essa missão termina sem ele, a **fobia mais antiga passa**, e o relatório diz quem terminou o tratamento;
   - **Desistir** cancela o tratamento.
4. **Uma fobia por elemento:** a mesma fobia não se repete. Um agente pode ter várias, de elementos diferentes.

## Na tela

- **Relatório da missão:** "Bianca: voltou… — saiu com um trauma: fobia de sangue (trate na Enfermaria)".
- **Combate:** "Fobia de Sangue: Bianca começa abalado." no registro.
- **Ficha e dossiê:** a linha "Traumas" e, se for o caso, "em tratamento".
- **Missão:** quem está em tratamento aparece desmarcado e bloqueado no grupo.

![A Enfermaria com dois agentes traumatizados](i70_enfermaria.png)

## O que fica para depois

- **Sussurros da fobia:** cada fobia já tem duas falas em `traumas.json`. Elas ainda não entram nas alucinações (docs/17 e docs/49).
- **Tratar com mais de uma missão:** um trauma mais grave poderia pedir mais tempo, ou um custo em prestígio.

## Onde está

- **Dados:** `data/jogo/traumas.json` (DT, condição, nome, descrição e falas de cada fobia).
- **Regra:**
  - `Agente.traumas`, `em_tratamento` e `tem_fobia`, salvos com o agente;
  - `Carreira._trauma_da_missao`, `tratar` e a cura no fim da missão; `validar_grupo` barra quem está em tratamento;
  - `Combate._fobias_no_inicio`.
- **Tela:** a Enfermaria (`BaseOrdem._sala_enfermaria`), o grupo da missão, o relatório e o dossiê.

## Testes

Total: **737**. Arquivo novo, `test_traumas.gd`:
- **Quem leva fobia:** quem enlouqueceu e falhou em Vontade, mas não quem passou nem quem não enlouqueceu.
- **No combate:** a fobia deixa abalado diante de uma criatura do elemento, e não diante de outro elemento.
- **O tratamento:** tira o agente da missão e cura a fobia no fim dela.
- **Save:** o trauma é salvo e carregado com o agente.
