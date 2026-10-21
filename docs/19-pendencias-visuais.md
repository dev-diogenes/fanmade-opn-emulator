# Pendências visuais: 1ª pessoa no mapa, cartas e foto do agente

> Status: **v0.1**, 20/10/2026. Fecha três pendências registradas no [17-criacao-e-sanidade.md](17-criacao-e-sanidade.md) e no [16-pacote-acessibilidade-engajamento.md](16-pacote-acessibilidade-engajamento.md).

## 1ª pessoa no mapa

**O que estava estranho:**

| Problema | Por quê |
|---|---|
| Olho rente ao chão | A câmera usava os valores da investigação: olho a 0,7 da base e olhar quase reto. No mapa, a miniatura é pequena perto dos hexes (raio 1), então a névoa elevada dos hexes inexplorados tapava tudo. |
| Câmera sem alvo no começo da missão | O mapa focava o agente antes de criar as peças. Com o `seguir` nulo, a 1ª e a 2ª pessoa só pegavam no turno seguinte. |
| A própria miniatura voltava | `_atualizar_agentes` redefinia o `visible` de todas as peças a cada passo. O rótulo "Mauro" e o corpo do próprio agente apareciam colados na lente. |
| Companheiros na lente | Quem divide o hex fica a 0,3 de distância e enchia a tela. |
| Vista virada para o nada | O giro inicial era 0, e a câmera costumava olhar para a borda do mapa. |

**Agora:**

- O `CameraRig` tem ajustes por cena: `altura_olhos`, `olhar`, `recuo_primeira`, `fov_primeira` e `centro_olhar`.
  - No mapa: olho a 2,3, olhar −0,5 rad, recuo de 0,9 e campo de visão de 70°. A vista fica acima da névoa, com os hexes de alcance à frente e o território ao fundo.
  - Na investigação e no combate, nada muda.
- Ao trocar de agente ou de modo, a 1ª e a 2ª pessoa **se viram para o centro do mapa**, de onde o grupo veio. O botão direito continua girando a câmera.
- O mapa cuida da visibilidade das peças (`_visibilidade_das_pecas`), ligado ao novo sinal `CameraRig.modo_mudou`. Em 1ª pessoa somem duas coisas:
  - a peça do agente da vez;
  - as peças a menos de 0,8 dele, ou seja, quem divide o hex.

  Quem saiu da missão continua escondido.
- O foco do agente da vez é refeito depois que as peças existem. A 1ª pessoa funciona desde o primeiro turno.

![1ª pessoa no mapa](primeira_19.png)

## Textos das cartas

**Antes:**

- **Tamanho:** título 15 px, dica 13 px e tecla 13 px, os dois últimos em tinta a 70%.
- **Combate:** a dica longa ("Cicatrizante e itens de combate") ocupava três linhas.
- **Bloqueio:** o véu preto a 50% apagava a dica das cartas bloqueadas.

**Agora:**

| | Antes | Agora |
|---|---|---|
| Título | 15 px | **17 px** |
| Dica | 13 px, tinta 70% | **15 px, tinta 88%** (9:1 no papel) |
| Tecla | 13 px solta no canto | **14 px num selo escuro** (papel sobre tinta) |
| Véu da carta bloqueada | 50% | **34%**: a dica continua legível e o cadeado diz que está bloqueada |

- **Combate:**
  - as cartas ficaram com 118 × 156 (eram 112 × 150) e o sigilo encolheu para 58;
  - a mão subiu e não encosta mais no relatório de campo;
  - as dicas viraram frases curtas ("Até uma célula azul", "Um inimigo marcado", "Curar ou usar item"). O detalhe continua no tooltip e no bilhete.
- **Investigação:** as cartas já eram maiores (132 × 176) e só ganharam os tamanhos novos.

![Cartas](cartas_19.png)

## Foto 3x4 na criação de agente

O dossiê de criação ganhou uma coluna à direita, ao lado das abas, com a **foto 3x4 do agente**. A foto fica presa com clipe numa moldura de papel fotográfico, com o nome datilografado embaixo:

- **Retrato:** a miniatura com a aparência escolhida é fotografada num estúdio próprio (um `SubViewport` com mundo 3D isolado, parede clara e luz de lado).
- **Revelação:** o shader `foto.gdshader` revela em sépia, com contraste, vinheta e grão. O grão é parado, porque é uma foto: nada se mexe nem pisca, o que respeita o A5.
- **Pose:** a figura fica congelada na pose parada, sem a base de peça.
- **Aparência:** os botões ◂ ▸ alternam entre quatro modelos da KayKit (Armadura, Capuz, Chapéu, Rústico). Sem escolha, a foto acompanha a classe, com a indicação "(da classe)".
- **Tom da roupa:** quatro tons (Original, Sépia, Noite, Luto), aplicados como tinta nos materiais.
- **A aparência vale no jogo todo:**
  - **save:** fica em `Agente.aparencia` e `Agente.tom`, só apresentação; as regras não leem;
  - **figuras:** `Pecas.do_agente` usa esses campos na miniatura do mapa, do combate e da investigação;
  - **saves antigos:** ficam com o modelo da classe.
- **A ficha (F) mostra a mesma foto** no canto da aba Ficha.
- **Largura da pasta:** fica fixa entre as abas, porque as abas têm largura mínima de 900.

![Identidade com a foto](criacao_19.png)
![Outra aparência e tom](criacao2_19.png)
![Ficha com a foto](ficha_19.png)

## Testes

O `tests/unit/test_aparencia.gd` tem 6 testes:

- **Aparência:** vai do dossiê ao save e volta, e saves antigos ficam com a classe.
- **Modelo:** o da classe ou o escolhido.
- **Foto:** só refaz quando muda e mostra a legenda.
- **Dossiê:** alterna aparência e tom, dando a volta nas listas.
- **Cartas:** nenhum texto abaixo de 14 px.
- **1ª pessoa:** vira do agente para o centro do mapa.

Total: **451 testes**.

## Pendências

- **Animação da foto:** a pose fica congelada. Seria possível escolher entre algumas poses.
- **Retratos do HUD:** ainda não mostram a foto. Um `SubViewport` por retrato pesaria; o caminho seria renderizar uma vez para uma textura.
- **Regra opcional de idade:** continua fora da criação em dossiê.
