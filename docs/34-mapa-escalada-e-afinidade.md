# Mapa mais cheio, serra escalável e sala da afinidade

> Status: **v0.1**, 21/10/2026. Pedidos do playtest:
> - "mais itens nos hex, pouquíssimos hex bloqueados (só dá pra subir neles caso algum dado de agilidade dê 20)";
> - "a sala de transcender deve mudar de acordo com a afinidade do personagem", seguindo o livro.

## Afinidade pelo livro (p.114)

Segundo o livro:
- em **NEX 50%**, o agente se conecta com um elemento (Conhecimento, Energia, Morte ou Sangue);
- a afinidade só **se desenvolve na primeira vez que ele transcende depois disso**.

Antes, o jogo dava a afinidade na hora da escolha. Agora o jogo segue a regra:

| Momento | O que acontece |
|---|---|
| NEX 50% | A escolha "Elemento da afinidade" guarda o elemento em `afinidade_escolhida`. Os benefícios ainda não valem |
| Próximo Transcender (ganhar um poder paranormal) | `afinidade = afinidade_escolhida`. Os benefícios passam a valer |

- **Base:** o rótulo da escolha avisa que a afinidade se firma no próximo Transcender.
- **Dossiê:** mostra "elemento escolhido" enquanto ela não se firma.
- **Saves antigos:** um agente salvo que já tem `afinidade` continua com ela.

## Sala de Transcender pela afinidade

- **Sem afinidade:** a sala é a da classe (docs/33).
- **Com afinidade:** a sala é a do elemento, montada com o que o livro associa a cada elemento (p.110-116), descrito com palavras próprias.
- **Quando a afinidade se firma no próprio ritual** (o agente escolheu o elemento antes e agora transcende), os móveis somem e a sala vira a do elemento na hora, com o pulso da fita e o aviso "A afinidade com Morte desperta.".
- O sigilo no meio continua o mesmo.

| Elemento | Sala | Luz |
|---|---|---|
| Sangue | Carne pendurada em ganchos, mesa de metal enferrujado com lâminas, poças e veias nas paredes | Vermelha |
| Morte | Relógio de pêndulo parado, montes de cinza, ossos, pedras e uma espiral riscada em volta do sigilo | Luar frio e baço |
| Conhecimento | Paredes claras com papéis e sigilos dourados, máscaras, cordas do teto e pergaminhos | Dourada |
| Energia | Neon rosa, roxo e verde, televisores chiando e cabos pelo chão | Roxa |

| Sangue | Morte |
|---|---|
| ![Sangue](sala34_sangue.png) | ![Morte](sala34_morte.png) |

| Conhecimento | Energia |
|---|---|
| ![Conhecimento](sala34_conhecimento.png) | ![Energia](sala34_energia.png) |

## Mapa: poucos bloqueios e a serra

| Terreno | Antes | Agora |
|---|---|---|
| Água | Bloqueava, em boa parte do mapa | **Água rasa:** atravessa-se com custo 3 e é rara (cerca de 2% dos hexes) |
| Serra (nova) | — | **O único bloqueio:** 4 por mapa (cerca de 2,3%), nos pontos mais altos, longe do início e do covil |

Como funciona a escalada:
- **Subir a serra:** só no turno em que **algum dado de Agilidade do movimento dá 20**. Contam os dados do atributo, os slots extras e os de Foco, então gastar PE aumenta a chance.
- **Custo:** 2 de movimento.
- **Lá de cima:** a visão cresce em 2 hexes.
- **No registro:** "Um 20! Mauro acha apoio na rocha: neste turno dá para escalar a serra.".
- **O mapa:** é sempre gerado com caminho até o covil sem escalar.
- **Missões da comunidade:** ganharam a letra `s` (serra), e o editor tem o pincel "Terreno: serra". A letra `a` agora é água rasa.

Na tela, a serra é um platô alto (0,85) cercado de agulhas de pedra. O centro fica livre para quem sobe.

### Mais itens em cada hex

Cada hex ganha 2 ou 3 miudezas na borda (na qualidade baixa, 1). Todas são peças novas feitas por código:

| Terreno | Miudezas |
|---|---|
| Campo | Cerca de arame, moita, cupinzeiro, toco, pedra |
| Estrada | Marco de quilômetro, poste, cruz de beira de estrada, placa |
| Mata | Moitas, tocos, pedras |
| Pântano e água | Árvores secas, moitas, tocos |
| Morro, ruína, cidade, serra | Pedras, moitas, cercas |

| Campo | Serra |
|---|---|
| ![Campo](mapa34_campo.png) | ![Serra](mapa34_serra.png) |

## Testes

Total: **518**.
- **Afinidade:** a escolha não dá a afinidade; o Transcender seguinte, sim; e ela vai no save.
- **Sala de Transcender:**
  - com afinidade, a sala é a do elemento (ganchos, relógio, máscaras, televisores);
  - se transforma no ritual, e os móveis da classe somem.
- **Mapa:** a serra só é passável com escalada; um 20 no movimento libera e um 19 não; há poucas serras.
- **Missões da comunidade:** a serra bloqueia o caminho e o início.
