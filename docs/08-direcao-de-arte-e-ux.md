# Direção de arte e UX

> Status: **v0.1**, 20/10/2026. Complementa o [ADR 0008](adr/0008-direcao-de-arte.md), que trata dos assets e do pipeline. Este documento reúne a auditoria do sistema de design, a crítica das telas, as hipóteses de pesquisa com jogadores, o brainstorm e a spec com critérios de pronto.

## 1. Norte visual

**"Diorama do For The King 2 visto através de um dossiê da Ordem."**

- **O mundo (3D)** segue o FTK2:
  - tabuleiro hexagonal em miniatura, peças que parecem de mesa, luz quente e névoa;
  - a câmera é inclinada e gira em volta do grupo.
- **A interface (2D)** é o arquivo da Ordem:
  - painéis de pedra escura com borda dourada envelhecida;
  - registros como relatório de campo;
  - o paranormal aparece pelos cinco elementos.
- **O terror** vem do contraste, não de escurecer tudo:
  - o mapa é legível e calmo;
  - o Outro Lado invade aos poucos: névoa roxa nos hexes não revelados, vinheta e granulação que crescem conforme a Membrana cai, vermelho-sangue só onde há perigo.

### Pilares de UX

1. **Risco legível antes da ação.** Como no FTK, o jogador vê a chance antes de rolar: slots de d20, DT e custo em PE.
2. **O grupo sempre à vista.** Os retratos do grupo, com PV, PE e SAN, ficam fixos sobre o 3D, e não escondidos num texto.
3. **Pouco texto, muita iconografia.** O registro existe, mas não é a interface principal.
4. **Consistência.** Toda cor, tamanho e espaçamento sai de um token do `Tema`.

## 2. Auditoria do sistema de design (estado em 20/10/2026)

**Telas revisadas:** 8 (Base, Mapa, Arena, Investigação, Editor, Saguão, convite do tutorial, tour guiado). **Problemas:** 9. **Nota:** 58/100.

### Tokens

| Categoria | Definidos no `Tema` | Valores soltos no código |
|---|---|---|
| Cores (interface) | 10 | 32 `Color("…")` em `ui/*.gd` (16 tons diferentes) e 110 `[color=#…]` em BBCode (17 tons) |
| Tipografia | 2 fontes, 3 variações (Titulo, Subtitulo, BotaoPrincipal) | 11 `font_size` soltos (17, 18, 19, 24, 28) |
| Espaçamento | nenhum | 17 `separation` soltos (4, 5, 6, 8, 10, 12, 14) |
| Estilos de caixa | painel, botão, campo, lista, barra | 5 `StyleBoxFlat` montados à mão (slots, tutorial, tour, arena) |

### Componentes

| Componente | Estados | Variantes | Docs | Nota |
|---|---|---|---|---|
| Botão | ✅ normal, hover, pressed, disabled, focus | ⚠️ só primário e padrão; falta o "perigoso" | ❌ | 6/10 |
| Painel | ✅ | ✅ padrão e lateral | ❌ | 7/10 |
| Barra (Membrana, PV) | ⚠️ sem faixas de estado | ❌ uma só cor | ❌ | 4/10 |
| Slot de d20 | ❌ caixa verde ou cinza montada à mão | ❌ | ❌ | 2/10 |
| Retrato do agente | ❌ não existe: a ficha é texto | — | — | 0/10 |
| Registro (log) | ⚠️ BBCode com 17 cores soltas | — | ❌ | 3/10 |

### Problemas de nomes e consistência

| Problema | Onde | Recomendação |
|---|---|---|
| O mesmo papel com cores diferentes: perigo em `ec7063`, `c0392b` e `f1948a` | registro, avisos | Token `PERIGO` |
| Destaque da vez em `f7dc6f` e o tema em `e3c27a` | mapa, arena, tutorial | Token `OURO_CLARO` |
| Texto secundário em `aab7b8` e `7f8c8d` | todas as telas | Token `TEXTO_SUAVE` |
| Cores dos elementos repetidas em 3 arquivos | tabuleiro, rituais, registro | Tokens `ELEMENTO.<nome>` |

## 3. Crítica de design

Comparação com o FTK2 e com o tom de Ordem Paranormal.

### Primeira impressão

O jogo abre direto numa planilha (a Base), com três colunas de texto. Não há tela de título, logo ou clima. O FTK2 abre num diorama vivo, com o logo e quatro botões.

### Usabilidade

| Achado | Gravidade | Recomendação |
|---|---|---|
| Não há tela de título: "login", carreira nova, online e editor ficam espalhados na Base | 🔴 Crítico | Tela de título com Continuar, Nova carreira, Online, Editor e Sair |
| O estado do grupo (PV, PE, SAN) aparece só da vez de cada agente, em texto | 🔴 Crítico | Retratos do grupo fixos sobre o 3D, como no FTK2 |
| O resultado da rolagem são números em caixas cinza e verdes | 🟡 Moderado | Slots de d20 com ícone de sucesso ou falha e animação de giro |
| A legenda "vermelho = encontro…" é texto no rodapé | 🟡 Moderado | Marcadores com forma própria (sigilo, exclamação, interrogação) e tooltip ao passar o mouse |
| Os hexes não revelados são placas pretas: parecem buraco, e não mistério | 🟡 Moderado | Névoa roxa animada (a Membrana) |
| A Base tem tudo numa tela só (roster, ficha, requisição, grupo, co-op, online, opções) | 🟡 Moderado | Separar em abas: Agentes, Arsenal, Missão, Jogadores |
| O registro ocupa metade do painel lateral | 🟢 Menor | Registro recolhível; os eventos importantes aparecem como aviso no centro |

### Hierarquia visual

- **O que chama atenção primeiro:** no mapa, o painel de texto, quando deveria ser o grupo e o hex da vez. Na Base, a coluna de requisição, quando deveria ser o grupo e o botão "Iniciar missão".
- **Fluxo de leitura:** o olho vai e volta entre o 3D e o texto.
- **Ênfase:** o botão principal só passou a se destacar com o `BotaoPrincipal`.

### Consistência e clima

- As peças eram primitivas. Os tiles e personagens da KayKit resolveram isso no mapa (ADR 0008), mas os inimigos ainda são cones e os marcadores ainda são cubos.
- O terror ainda não aparece: falta a Membrana visível no mundo (vinheta, granulação, névoa) e falta a iconografia dos elementos.

### O que funciona

- A câmera estilo FTK, com giro, zoom e foco no agente da vez.
- O tour guiado, com moldura sobre o elemento.
- A separação entre lógica e apresentação, que permite trocar o visual sem tocar nas regras.

## 4. Pesquisa com jogadores

As personas vêm do [00-visao-e-spec.md](00-visao-e-spec.md) e do [07-tutorial.md](07-tutorial.md). Ainda **não há dados de jogadores**: o que segue são hipóteses que os playtests precisam confirmar.

### Hipóteses

| # | Hipótese | Persona | Como medir |
|---|---|---|---|
| H1 | Quem vem do FTK procura o estado do grupo no canto inferior e se perde no texto | Jogador de FTK | Teste de 5 segundos: "quem está com menos vida?" |
| H2 | Fãs de OP reconhecem o universo pelos elementos e pela Membrana, não pelo cenário medieval da KayKit | Fã de OP | Entrevista pós-sessão: "o que lembrou Ordem?" |
| H3 | A tela de título com "Continuar" reduz o tempo até a primeira ação | Todos | Tempo entre abrir o jogo e o primeiro movimento |
| H4 | Slots com ícones são entendidos sem o tutorial | Jogador novo | Pedir para prever o resultado antes de rolar |
| H5 | Vinheta e granulação ligadas à Membrana aumentam a tensão sem atrapalhar a leitura | Fã de OP | Escala de tensão de 1 a 5 e erros de leitura |

### Plano

- **Método:** teste de usabilidade moderado e remoto (Discord com tela compartilhada), com 5 a 6 jogadores por rodada: 2 de FTK, 2 fãs de OP e 1 a 2 mestres.
- **Roteiro (30 min):**
  1. Abrir o jogo e começar uma missão (H3).
  2. Teste de 5 segundos no mapa (H1).
  3. Rolar o movimento e prever o resultado (H4).
  4. Jogar até o primeiro combate.
  5. Entrevista curta (H2, H5).
- **Síntese:** uma tabela de achados por hipótese, com a frequência (quantos de 6) e a gravidade.

## 5. Brainstorm (divergência)

Ideias levantadas antes de priorizar. As marcadas com ✅ entram na spec abaixo.

- ✅ Tela de título com o diorama girando ao fundo e o logo em Cinzel.
- ✅ Retratos do grupo sobre o 3D, com barras de PV, PE e SAN e o destaque da vez.
- ✅ Membrana visível: vinheta e granulação que crescem conforme ela cai.
- ✅ Névoa roxa animada nos hexes não revelados.
- ✅ Marcadores que flutuam e brilham, com forma por tipo.
- ✅ Slots de d20 como peças: dourado no sucesso, apagado na falha, com giro.
- 💡 Quadro de investigação (cortiça, fotos, fio vermelho) como tela de pistas.
- 💡 Cartas de dossiê para os agentes, com a ficha como documento carimbado "CONFIDENCIAL".
- 💡 Fonte de máquina de escrever no registro (Special Elite, licença Apache 2.0).
- 💡 Sigilos dos cinco elementos como ícones, modelados no Blender com a paleta do ADR 0008.
- 💡 Inimigos: Quaternius (CC0) ou modelagem própria. Cultistas encapuzados e criaturas de cada elemento.
- 💡 Ciclo de dia e noite no mapa: à noite a névoa avança e os encontros pioram.
- 💡 Trilha e ambiência: drones graves e sussurros quando a Membrana cai.

## 6. Spec

### Problema

O jogo funciona, mas não parece um RPG acabado, não lembra o FTK2 e não transmite o terror investigativo de Ordem Paranormal. Isso reduz a retenção e o interesse da comunidade, que é a principal fonte de contribuidores.

### Objetivos

1. Um jogador de FTK2 reconhece o "jeito FTK" em 5 segundos (H1).
2. Um fã de OP cita pelo menos um elemento do universo, sem ser perguntado (H2).
3. Nenhuma cor, tamanho ou espaçamento solto nas telas: tudo sai do `Tema`.

### Fora do escopo

- Trocar o motor de regras ou o fluxo das telas.
- Arte 2D pintada (retratos ilustrados). Os retratos usam os modelos 3D ou ícones.
- Áudio (fica para uma fase própria).

### Requisitos

**P0 (esta entrega): ✅ implementado em 20/10/2026.** R1 está parcial: o BBCode do registro foi harmonizado para os valores dos tokens (8 tons no lugar de 17), mas ainda está escrito como hex literal nos textos. A troca por `Tema.bb()` fica no P1.

| # | Requisito | Critério de pronto |
|---|---|---|
| R1 | **Tokens semânticos** no `Tema` | Cores semânticas: `PERIGO`, `SUCESSO`, `AVISO`, `INFO`, `MESTRE`, `ELEMENTO.*`. Mais `ESPACO_*` e `FONTE_*`. Nenhum `Color("…")` de interface em `scripts/ui/*.gd`; o BBCode usa `Tema.bb()` |
| R2 | **Tela de título** como cena principal | Diorama 3D girando ao fundo e o logo. Botões: Continuar, Nova carreira (com confirmação), Editor de missões e Sair. Funciona no teclado e no controle |
| R3 | **Retratos do grupo** no mapa | Um cartão por agente, com nome, classe, PV, PE e SAN em barras. O agente da vez fica em destaque dourado e o caído aparece apagado. Atualiza a cada comando |
| R4 | **Membrana na tela** | Vinheta e granulação por shader, com intensidade proporcional a (100 − Membrana). Quase nada a 100, forte abaixo de 25 |
| R5 | **Névoa do Outro Lado** | Os hexes não revelados ganham névoa roxa animada no lugar da placa preta |
| R6 | **Marcadores vivos** | Os marcadores flutuam e giram devagar, com luz própria. A forma depende do tipo |
| R7 | **Slots de d20** | Componente `SlotD20`: valor, estado (sucesso ou falha) e animação curta de entrada |

**P1 (próxima entrega)**

- Registro com `Tema.bb()` em todos os textos (fecha o R1).
- Abas na Base.
- Tooltip nos hexes (terreno, custo, conteúdo).
- Registro recolhível.
- Inimigos em 3D.
- Sigilos dos elementos.

**P2**

- Quadro de investigação.
- Cartas de dossiê.
- Fonte de máquina de escrever.
- Ciclo de dia e noite.
- Áudio.

### Componentes (documentação)

#### `Tema` (tokens)

| Grupo | Tokens |
|---|---|
| Base | `FUNDO`, `PEDRA`, `PEDRA_CLARA`, `OURO`, `OURO_ESCURO`, `OURO_CLARO`, `SANGUE`, `SANGUE_CLARO`, `PERGAMINHO`, `TEXTO_SUAVE` |
| Semânticos | `PERIGO` (dano, encontro, falha), `SUCESSO` (cura, vitória), `AVISO` (custo, NEX, alerta), `INFO` (online, investigação, pista), `MESTRE` (painel do mestre) |
| Elementos | `ELEMENTO.sangue` (vermelho), `.morte` (cinza-chumbo), `.conhecimento` (dourado), `.energia` (roxo), `.medo` (branco gelo) |
| Espaço | `ESPACO_P` = 4, `ESPACO_M` = 8, `ESPACO_G` = 12, `ESPACO_GG` = 20 |
| Fonte | `FONTE_P` = 14, `FONTE_M` = 17, `FONTE_G` = 20, `FONTE_TITULO` = 28, `FONTE_LOGO` = 64 |

**Uso no BBCode:** `Tema.bb("texto", Tema.PERIGO)` devolve `[color=#…]texto[/color]`.

#### `CartaoAgente`

| Propriedade | Tipo | Descrição |
|---|---|---|
| `agente` | `Agente` | O agente representado |
| `cor` | `Color` | Cor do jogador (a mesma da base da figura no 3D) |
| `da_vez` | `bool` | Borda dourada e leve escala |

Estados:
- **normal**;
- **da vez**: borda `OURO_CLARO`;
- **fora de combate**: 50% de opacidade e um ✝;
- **morto**: oculto.

#### `SlotD20`

| Propriedade | Tipo | Descrição |
|---|---|---|
| `valor` | `int` | Resultado do d20 |
| `sucesso` | `bool` | Igual ou acima da DT |

Visual:
- **sucesso:** caixa dourada com valor escuro;
- **falha:** caixa de pedra com valor apagado.

A entrada é uma escala de 0,6 para 1 em 0,15 s, uma caixa depois da outra.

### Acessibilidade

- Contraste mínimo de 4,5:1 entre texto e painel. `PERGAMINHO` sobre `PEDRA` dá cerca de 13:1.
- O estado nunca é indicado só pela cor: os slots têm ✓ e ✗, e o caído tem ✝.
- A granulação e a vinheta podem ser desligadas nas preferências (P1).

### Questões em aberto

- ❓ O cenário medieval da KayKit combina com OP contemporâneo? A proposta é recolorir as casas e trocá-las por modelos próprios (casas brasileiras, postes, carros) no P1/P2.
- ❓ Os retratos devem usar render 3D ao vivo (SubViewport por agente) ou ícones de classe? Para o P0, ícone de classe; o render ao vivo fica para medir desempenho.
