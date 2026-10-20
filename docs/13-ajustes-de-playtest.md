# Ajustes do playtest de 20/10/2026

> O autor jogou e mandou 12 pontos. Este documento registra o que mudou em cada um e as decisões de regra.

| # | Pedido | O que mudou |
|---|---|---|
| 1 | Personagens dentro das pedras nos hexes inclinados | Morros, matas e decorações soltas foram para a **borda** do hex, menores; o centro fica livre para as figuras |
| 2 | Movimento baixo: "está assim no livro?" | **Não.** O livro não tem regra de viagem; o movimento no mapa é design nosso (`mapa.json`). Antes: 1 d20 por Agilidade + base 1, então um agente comum andava 1 ou 2 hexes. Agora: Agilidade **+ 2 slots extras** e **base 2**, uns 3 ou 4 hexes, perto do FTK |
| 3 | Estradas estranhas | A peça de estrada da KayKit (girada ao acaso) saiu. Agora a estrada é grama com **faixas de terra que ligam o centro aos vizinhos** (estrada, cidade, vila, início), então os trechos sempre se encontram. O gerador procedural também passou a **traçar estradas do início até as vilas** |
| 4 | Rolagem estilo FTK2 | `RolagemDados`: faixa escura no centro, com o **símbolo do atributo** (Agilidade: raio; Força: punho; Intelecto: olho; Presença: estrela; Vigor: coração), os d20 **girando e caindo um a um** com ✓ ou ✗, e o resultado embaixo. Vale para movimento, eventos, ataques e testes de investigação. Um clique fecha |
| 5 | Ver a ficha e o inventário | `DossieAgente`: tecla **F** ou clique no retrato. Abas Ficha (atributos, perícias com bônus, habilidades, rituais, condições) e Inventário (carga, itens, categoria, dano, cura). No mapa, os itens de cura têm **Usar** |
| 6 | Dock por cima do relatório | O relatório de campo do mapa foi para o **alto, à direita**, abrindo para baixo. Os retratos ficaram mais estreitos e os botões, mais curtos |
| 7 | Encontros pouco envolventes | Os eventos ganharam **opções** (`eventos.json`, `opcoes`): diplomacia, intimidação, enganação, luta, sobrevivência (só para treinados), furtividade, investigação, medicina e outras, mais "seguir em frente" sem teste. São 43 opções escritas para os 11 eventos. O bilhete mostra uma linha por opção, com perícia, bônus e DT |
| 8 | Botões ativos sem ação | No combate, sem ação padrão, **Atacar, Ritual e Item ficam apagados**; sem padrão e sem movimento, **Mover** também |
| 9 | Câmera em 1ª/2ª/3ª pessoa | `CameraRig` com 3 modos (**C** alterna, ou pela pausa): 3ª (de cima, como antes), 2ª (na frente do agente da vez, olhando para ele) e 1ª (dos olhos do agente, cuja figura some). O modo fica guardado nas preferências |
| 10/11 | Rituais e itens fora de combate; uma ação além do movimento | Botão **Ação** no mapa: **uma ação por turno** (`Missao.acao_usada`), além do movimento. Dá para usar itens de cura e rituais de **cura ou PV temporários**, sem área e com alcance pessoal ou toque, em você ou em quem está no mesmo hex. Comandos `usar_item` e `conjurar` (funcionam no online) |
| 12 | Investigação andando com WASD | O agente da vez **anda pela cena** (WASD, setas ou analógico) e a câmera acompanha. Só dá para procurar no **ponto ao alcance** (1,5 m); **E** abre a carta Procurar. Clicar não escolhe mais o ponto. O tutorial foi atualizado |

![Estradas](estradas_13.png)
![Morro](morro_13.png)
![Rolagem no centro](rolagem_13.png)
![Opções de evento](evento_13.png)
![Ficha](ficha_13.png)
![2ª pessoa](segunda_13.png)
![Investigação andando](investigacao_13.png)

## Investigação: inspiração em *The Esoterrorists*

Ordem Paranormal nasceu inspirado no sistema GUMSHOE (*The Esoterrorists*). Lá, **a pista central nunca depende de um dado**: quem tem a habilidade certa e está no lugar certo encontra a pista. Os dados ficam para o que é extra ou para o perigo.

Proposta para a próxima rodada (ainda **não** implementada, porque muda a regra da cena):
- **Pista central automática:** ao chegar perto de um ponto, o agente *treinado* numa das perícias do ponto recebe a pista básica sem teste.
- **Gasto de foco por pistas extras:** PE para pistas adicionais ou para respostas mais completas.
- **Teste só para o perigo e para o tempo:** a urgência e o Medo continuam sendo testados.

## Notas

- O movimento no mapa e as opções de evento são **conteúdo original** do jogo. O livro não tem regras de viagem nem esses eventos.
- Os rituais fora de combate usam as fichas do ruleset (`rituais.json`). Nada foi copiado do livro além dos números que já estavam lá.
