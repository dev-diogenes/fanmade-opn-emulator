# Interface: um papel por vez, iniciativa, alcance por contorno

> Status: **v0.1**, 22/10/2026. Sexta fase do plano (docs/51: a limpeza da interface). Os pontos vieram da partida jogada na crítica: o tour do tutorial por cima do briefing e da cerimônia, o "Manobra" saindo da tela, a falta de uma fila de turnos, o mapa todo pintado de azul e a ★ em escolhas ruins.

## O que mudou

### Um papel por vez

**Antes:** o tour do tutorial abria junto com o briefing do caso, no mapa, e com a cerimônia de NEX, na Base. Duas caixas falavam ao mesmo tempo (docs/51, `crit51_briefing_tutorial.png` e `crit51_relatorio_tutorial.png`).

**Agora:**
- O briefing, a cerimônia de NEX e a sala de Transcender entram no grupo `papel_modal`.
- O tour espera, escondido, até nenhum desses papéis estar aberto, e só então mostra o primeiro passo.
- Enquanto espera, o teclado não o avança: Enter fecha o briefing, e não um tour invisível.
- O briefing deixou de precisar ficar numa camada abaixo do tour.

![O briefing sozinho; o tour vem depois](i57_briefing.png)

### Faixa de iniciativa

No alto do combate, logo abaixo da Membrana, uma fila mostra quem age agora e quem vem depois, como os retratos do For The King 2:
- **A ficha da vez** é maior, com borda dourada.
- **Os agentes** têm a cor do jogador e o símbolo da classe (⚔ ✦ ☾ ●).
- **As criaturas** têm a cor do elemento (Sangue, Morte, Conhecimento, Energia; Medo em branco). O nome aparece sem o artigo: "Sacerdote Carmesim".
- **Um "↻"** marca onde começa a rodada seguinte.
- **Mortos** saem da fila. Quem está morrendo ou enlouquecendo aparece apagado.
- **A dica** de cada ficha traz o total de Iniciativa.

O aviso "VEZ DA AMEAÇA" desceu um pouco para não cobrir a faixa.

### Os botões cabem

Na vez do combatente, a linha acima das cartas tinha Foco, "✦ Ataque Especial (+5, 2 PE)", "Golpe não letal (−5)" e "Manobra ▾". A 1280 px, a Manobra saía da tela. Agora:
- os rótulos são curtos ("✦ Especial +5", "Não letal −5"), e o detalhe vai na dica;
- a linha cresce para a esquerda: nada sai pela direita;
- os retratos do grupo na arena usam um tamanho compacto (150 px; 190 px na vez). Com a escala da interface acima de 1, o retrato da vez encostava nas cartas.

![Mauro na vez: Especial, Não letal e Manobra cabem; a faixa no alto](i57_arena.png)

### Alcance por contorno

O mapa pintava cada hex alcançável de azul (ou âmbar, longe do grupo). Com 4 ou 5 de movimento, quase tudo virava azul e o terreno sumia. Agora:
- cada destino ganha **uma borda acesa** (`Pecas.contorno_hex`);
- por dentro, só **um véu leve**: as árvores, as casas e os marcos continuam legíveis;
- as cores não mudaram: azul perto do grupo, âmbar quando o agente fica sozinho (docs/42).

![Alcance por contorno](i57_contorno.png)

### A ★ só em escolha boa

A ★ marcava a opção de maior chance, mesmo quando a maior chance era 20%. Recomendar 20% contra 15% é recomendar um erro. Agora:
- a ★ só aparece com **50% ou mais** (`LinhaTeste.recomendada`);
- a perícia que já vem escolhida continua sendo a de maior chance.

Vale para os pontos da investigação e para os eventos do mapa.

## O que fica para depois

- Pontos de investigação que ficam embaixo do HUD (docs/51): a câmera precisa de margem no enquadramento.
- Retratos de verdade na faixa (a foto do agente, como no dossiê), em vez do símbolo.
- Com 4 agentes, a arena ainda aperta a 1280 px com escala acima de 1.

## Onde está

- **Regra:** `Combate.proximos(n)`, que devolve `[{ser, nova_rodada}]` a partir de quem está na vez.
- **Tela:**
  - `FaixaIniciativa` (novo);
  - `TourGuiado.papel_aberto` e a espera em `iniciar`;
  - `LinhaTeste.recomendada`;
  - `Pecas.contorno_hex` e `Mapa3D.atualizar`;
  - `CartaoAgente.largura` e `largura_vez`;
  - a linha de extras da arena.

## Testes

Total: **616**.
- **Arquivo novo, `test_interface57.gd`:**
  - a ★ só com 50%;
  - os próximos começam por quem está na vez, marcam a rodada seguinte e pulam os mortos;
  - a faixa mostra a vez e some com o combate encerrado;
  - os nomes encurtam;
  - o contorno é um anel de 36 vértices, sem miolo.
- **`test_tutorial.gd`:** o tour espera o papel aberto fechar.
