# Clima de terror no mundo 3D

> Status: **v0.1**, 21/10/2026. Implementa o **C1** da [crítica 20](20-critica-pos-acessibilidade.md): noite no mapa e no título, a Membrana pesando no clima e o combate no terreno do encontro.

## O problema

O título e o mapa tinham grama verde-limão saturada e água azul viva sob luz de meio-dia. O combate acontecia numa sala cinza neutra, fosse o encontro numa floresta, numa cidade ou num pântano. A interface já falava de terror; o mundo 3D, não. A Investigação era a única cena que soava como Ordem Paranormal.

## Noite (todas as cenas que usam `Pecas.ambiente`)

`Pecas.ambiente` virou uma noite de horror e passou a devolver o `Environment`, para a cena reagir à Membrana.

| | Antes | Agora |
|---|---|---|
| Luz principal | Sol quente, energia 1,2 | **Lua** fria (`b4c3ff`), energia 0,75, sombra suave |
| Contraluz | Fria e azulada | **Brasa** quente e rasante (`c9603f`, 0,22), como uma cidade queimando longe; recorta as peças |
| Céu | Cinza-arroxeado | Quase preto, com o horizonte puxado para o vinho |
| Névoa | Leve e uniforme | Mais densa (0,03), com **névoa rasteira** (fog de altura) junto ao chão |
| Cor | Saturação 0,95 | **0,62**, contraste 1,12: o mundo fica lavado |
| Glow | Limiar 1,1 | 0,9: janelas, marcos e o núcleo do covil brilham |

**Janelas acesas:**

- As casas ganharam janelas. Em cerca de 65% delas há alguém acordado (janelas quentes com emissão); nas outras, as janelas são pretas.
- Cada hex de cidade com casas acesas ganha uma luz âmbar no chão da rua.
- O marco da vila virou um lampião âmbar.
- Na investigação, a casa abandonada tem as janelas apagadas.

## A Membrana no clima

Antes, o véu crescia linear de 100 a 25. Agora há uma curva só, `Pecas.intensidade_membrana`:

- quase nada até 75 (no máximo 0,15);
- dali para baixo, cresce até 1 em 25.

A mesma curva move:

- **o véu na tela:** vinheta, grão e dessaturação do shader (`Tema.membrana_na_tela`);
- **o som ambiente:** drone e sussurros;
- **o clima 3D** (`Pecas.clima_membrana`):
  - a névoa engrossa e puxa para o vermelho-sangue;
  - a luz ambiente esquenta para o vinho;
  - a saturação cai mais 0,2.

Valem no mapa, no combate e no título (que mostra a Membrana em 70).

## Combate no terreno do encontro

O encontro já guardava o `terreno` do hex. Agora o `Tabuleiro3D.construir(grade, terreno)` usa esse dado:

| Terreno | Chão | Cobertura | Em volta do tabuleiro |
|---|---|---|---|
| Floresta | Musgo escuro | Rochas | Mata fechada (árvores KayKit) |
| Campo e estrada | Grama seca e terra | Rochas e caixotes | Árvores soltas e pedras |
| Cidade | Calçamento | Caixotes | Casas, algumas acesas e com luz, barris e caixas |
| Ruína | Pedra velha | Rochas | Pedras e pilares quebrados |
| Morro | Rocha | Rochas | Morros e montanhas |
| Pântano e água | Lama | Rochas | Plantas d'água e árvores |

- **Moldura:** a borda tem duas faixas de peças, sorteadas pela posição. O mesmo encontro sempre tem a mesma moldura. Um pano escuro no tom do terreno fica sob a moldura, para nada flutuar no vazio.
- **Clareira ao luar:** um foco frio quase a pino ilumina o tabuleiro, e o entorno fica no escuro. O chão é clareado 30% sobre a paleta noturna.
  - **Na prática:** a noite fica na moldura, e a luta continua legível.
  - **Por quê:** as primeiras capturas, só com a lua, deixavam o tabuleiro quase preto.
- **Sala da demonstração:** sem terreno, continua a sala cinza, mas também ganha a clareira e o chão clareado.

## Antes e depois

| Antes | Depois |
|---|---|
| ![Título antes](clima22_titulo_antes.png) | ![Título depois](clima22_titulo_depois.png) |
| ![Mapa antes](clima22_mapa_antes.png) | ![Mapa depois](clima22_mapa_depois.png) |
| ![Combate antes (sala cinza)](cartas_19.png) | ![Combate na floresta](clima22_combate_floresta_depois.png) |

Mais capturas:

- **Membrana em 30:** névoa grossa e vinho, cores lavadas.
- **Combate na cidade:** casas acesas em volta.
- **Combate no pântano.**

![Membrana em 30](clima22_mapa_baixa_depois.png)
![Combate na cidade](clima22_combate_cidade_depois.png)
![Combate no pântano](clima22_combate_pantano_depois.png)

## Testes

O `tests/unit/test_clima.gd` tem 4 testes:

- **Noite:** saturação, névoa rasteira, lua e brasa.
- **Curva da Membrana:** a curva, e a névoa engrossando, lavando e puxando para o vermelho.
- **Casas:** janelas acesas e apagadas, e nem toda casa acesa.
- **Combate:** a floresta cerca o tabuleiro, a clareira está nas duas salas e a paleta muda com o terreno.

Total: **466 testes**.

## Pendências

- **Desempenho:** não medido em máquina fraca.
  - **O que pesa:** a névoa de altura, o SSAO e as luzes por hex de cidade.
  - **Saída possível:** se pesar, um ajuste "Qualidade" nas preferências pode desligar o SSAO e limitar as luzes.
- **Investigação:** continua com o ambiente próprio (já era escura), sem a reação à Membrana no clima.
- **Hexes do mapa:** ainda são os da KayKit tingidos. Um tile "à noite" com textura própria daria mais identidade.
- **1ª pessoa no mapa:** ficou mais escura com a noite. Vale conferir jogando.
