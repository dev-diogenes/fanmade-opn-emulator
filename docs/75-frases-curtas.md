# Frases curtas: os agentes falam

> Status: **v0.1**, 23/10/2026. Item "depois" da lista de próximos passos: as frases curtas (AG6 do relatório "Melhorias pelo universo de Ordem Paranormal"). Fecha também o que ficou pendente no docs/70: os sussurros da fobia.
>
> **Não é regra do livro, e não muda regra nenhuma.** É voz: uma linha que o agente diz conforme o estado, como os comentários dos heróis em Darkest Dungeon. Textos próprios.

## Quando o agente fala

| Estado | Quando | Onde |
|---|---|---|
| **Ferido** | PV na metade ou menos | no combate, depois do golpe; no mapa, no começo da vez |
| **Perturbado** | Sanidade na metade ou menos | no combate (dano mental e Presença Perturbadora); no mapa, no começo da vez |
| **Aliado caído** | um agente sai de combate | o primeiro aliado de pé fala, com o nome de quem caiu |
| **Fobia** | o combate começa diante de uma criatura do elemento da fobia (docs/70) | no começo do combate, junto com o "abalado" |

- **Sem repetição:** cada estado fala **uma vez por cena** no combate. No mapa, a fala volta só depois que o estado passa (curou, descansou) e volta de novo.
- **Prioridade:** perturbado vem antes de ferido; uma fala por vez.
- **A escolha da linha** sai do nome do agente, do estado e de um contador, sem gastar os Dados, então é igual no online.

## As falas

- **Onde ficam:** `data/jogo/falas.json`, por estado e por classe (combatente, especialista, ocultista, mundano), com uma lista "geral" para quem não tem a sua. A fobia usa as duas frases de cada fobia em `traumas.json`.
- **O tom de cada classe:**
  - o combatente segura a pose: "Já levei pior. Vem.";
  - o especialista tenta organizar o caos: "Os números não fecham. Nada aqui fecha.";
  - o ocultista escuta o Outro Lado: "A Membrana tá fina. Dá pra ouvir eles.";
  - o mundano só quer ir pra casa: "Por que tá tão frio?".

## Na tela

- **Balão:** a linha aparece entre aspas, acima da cabeça de quem fala, por uns 4 segundos, no tabuleiro do combate e no mapa.
  - O texto corre para a direita da cabeça, porque os agentes começam na borda esquerda da arena.
  - Quem fala antes de ter peça no tabuleiro (a fobia, no começo do combate) ganha o balão quando a peça aparece.
- **Registro:** a mesma linha entra no relatório de campo, em itálico.

![No mapa: a Bianca começa a vez ferida](i75_mapa.png)

![No combate: a fobia de Morte da Rita diante do succ](i75_fobia.png)

![A Bianca cai, e o Cléber responde](i75_aliado.png)

## Os sussurros da fobia (docs/70)

As alucinações de quem está perturbado (docs/17 e docs/49) agora também sussurram as frases da fobia do agente da vez, junto com as do efeito de insanidade.

## Playtest

Uma sonda pela interface (1280×720), na missão 777:
1. **No mapa:** a Bianca começou a vez com metade dos PV e disse "Alguém tem gaze? Sério.".
2. **No combate contra o succ (Morte):**
   - a Rita, com fobia de Morte, começou abalada e disse "Está tudo apodrecendo.";
   - o Cléber, ferido, disse "Isso vai deixar marca.";
   - quando a Bianca caiu, ele disse "Ninguém fica pra trás. Ninguém!".

**Testes:** 807 passando. Os novos estão em `test_falas.gd`.

## O que ficou de fora

- **Laços:** o relatório também pedia falas sobre os laços entre agentes. Ficaram de fora junto com o sistema de laços, como pedido antes.
- **Falas de vitória, de crítico ou de abate.** Dá para pôr mais estados em `falas.json`; cada estado novo precisa de um gatilho no código.
- **Voz gravada.** As falas são só texto.
