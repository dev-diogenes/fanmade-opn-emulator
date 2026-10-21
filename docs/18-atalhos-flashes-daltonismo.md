# Atalhos, fotossensibilidade e daltonismo

> Status: **v0.1**, 20/10/2026. Implementa o **A4**, o **A5** e o **A6** do [15-critica-acessibilidade-engajamento.md](15-critica-acessibilidade-engajamento.md). A decisão de arquitetura dos atalhos está no [ADR 0009](adr/0009-atalhos-remapeaveis.md).

Os três ajustes ficam no mesmo bloco, na **Pausa › Ajustes** e na **Base › Jogadores** (`MenuPausa.montar_leitura`):

- Flashes: suaves / completos
- Cores para daltonismo (azul e laranja)
- Atalhos de teclado (H)

## A4: atalhos remapeáveis e folha de atalhos

**Antes:** cada tela comparava `KEY_F`, `KEY_TAB`, `KEY_W`… no próprio código. Não havia como trocar uma tecla nem ver a lista delas. As cartas do combate mostravam 1–5, mas as teclas não faziam nada.

**Agora:** a classe `Atalhos` (`scripts/core/atalhos.gd`) guarda 17 ações com nome, grupo e tecla padrão. Cada uma vira uma ação `atalho_<id>` no InputMap. As telas perguntam pela ação:

- `Atalhos.pressionou(evento, "ficha")` para um aperto;
- `Atalhos.segurando("mover_cima")` para tecla segurada.

| Grupo | Ações (padrão) | Vale em |
|---|---|---|
| Em qualquer tela | Folha de atalhos (H), Ficha e inventário (F) | mapa, combate, investigação |
| Câmera | Trocar modo (C), girar à esquerda (Q) e à direita (E) | mapa, combate |
| Andar e deslizar | W, A, S, D (as setas valem junto, fixas) | mapa, combate, investigação |
| Cartas | 1 a 5 | combate, investigação |
| Investigação | Quadro (Tab), procurar no ponto próximo (E), confirmar a carta (Enter; o Enter do teclado numérico vale junto) | investigação |

- **Folha de atalhos:**
  - abre com **H** em qualquer tela (o autoload `Jogo` recebe a tecla que a tela não usou), pela pausa ou pela Base;
  - é uma folha datilografada em papel, com as ações por grupo e uma coluna de **fixos**: Esc, clique, botões do mouse na câmera, roda e setas.
- **Remapear:**
  - clique na tecla e aperte a nova; **Esc desiste**;
  - se a tecla já era de outra ação **de uma tela em comum**, as duas **trocam de lugar** e a folha avisa ("W já era de 'Para a frente' (agora F)…"). Assim nenhuma ação fica sem tecla;
  - ações de telas diferentes podem dividir a tecla: E gira a câmera no mapa e procura pistas na investigação.
- **Esc é reservado:** é a saída de tudo (pausa, fechar, voltar) e não pode ser escolhido.
- **Restaurar padrões** limpa tudo.
- **Onde fica salvo:** em `preferencias.json` → `atalhos`, só com o que difere do padrão.
- **Dicas de tecla:** os textos que citam teclas leem o mapa:
  - o número no canto das cartas e o tooltip delas;
  - "Ficha e inventário (F)" nos retratos;
  - "Quadro (Tab)" na investigação;
  - "Câmera: … (C)" nos ajustes.
- **Cartas do combate pelo teclado:** 1–5 agora funcionam. Equivalem ao clique e respeitam o cadeado: carta bloqueada não faz nada.

![Folha de atalhos](atalhos_18.png)

## A5: fotossensibilidade

**Antes:** o pulso de VHS trocava as faixas da fita 18 vezes por segundo, a estática entre as telas mudava a cada quadro e o logo do título dava três trancos a 20 por segundo. A única saída era desligar o glitch inteiro.

**Agora:** a preferência **Flashes** tem dois modos. **Suave é o padrão.**

| | Suave (padrão) | Completo |
|---|---|---|
| Pulso de VHS (`Tema.pulso_vhs`) | 45% da força, dura pelo menos 0,9 s, a fita troca de faixa ~2,7 vezes/s (`ritmo` = 0,15 no shader) | força cheia, 18 trocas/s |
| Estática entre telas | o chuvisco troca ~3 vezes/s, com menos contraste (`ritmo` = 0,1) | a cada quadro |
| Logo do título | dois saltos lentos (0,35 s), deslocamento menor | três trancos a 20/s |

- **Limite:** o modo suave fica abaixo do limite de **3 flashes por segundo** do WCAG 2.3.1.
- **Sem nada piscando:** desmarque "Glitch de VHS e tremores". A loucura (E6) já reduzia a ondulação sem o glitch.
- **Aviso na primeira abertura:** um bilhete na tela de título explica os efeitos e oferece duas saídas:
  - **Manter suave**;
  - **Desligar glitches** (Esc também desliga: na dúvida, o seguro).

  O aviso aparece uma vez por máquina (`aviso_flashes_visto`) e não aparece nas capturas automáticas.

![Aviso](aviso_flashes_18.png)

## A6: paleta para daltonismo

**Antes:** sucesso e falha eram verde e vermelho em quatro lugares: o bilhete de desfecho, os selos de efeito, o carimbo do relatório e o texto do resultado da rolagem. Os dados eram dourado e sangue. Para quem tem deuteranopia ou protanopia, verde e vermelho se confundem. Os símbolos ✓/✗ ajudavam só nos dados.

**Agora:** os tokens semânticos `Tema.cor_sucesso(papel)`, `Tema.cor_falha(papel)` e `Tema.cores_slot(estado)` substituem os hex soltos. Com **"Cores para daltonismo"** marcado, viram o par azul e laranja da paleta Okabe-Ito.

| Uso | Normal | Daltonismo | Contraste (daltonismo) |
|---|---|---|---|
| Texto sobre a pedra | sucesso `6fcf8e`, falha `e0574a` | `56b4e9`, `e69f00` | 7,9:1 e 8,1:1 |
| Tinta sobre o papel (selos, carimbo, desfecho) | `2f6b3f`, `8e1b22` | `0b5a8f`, `9a4500` | 5,4:1 e 4,8:1 |
| Dado (fundo / borda / número) | dourado e sangue | `1f5f99`/`56b4e9` e `8a4a00`/`e69f00`, número em pergaminho | 5,0:1 e 5,2:1 |

- **Símbolos:** ✓ e ✗ continuam nos dados, e o selo sempre diz SUCESSO ou FALHA. A cor reforça, mas não é a única pista.
- **Onde a troca vale:**
  - rolagem e dados (mapa e combate);
  - desfecho e selos (perda em laranja, ganho em azul; a Membrana segue a mesma regra);
  - carimbo do relatório de fim;
  - rastreador do caso ("✔" respondida);
  - "(promovido!)" e "pode ser recrutado" no relatório da Base;
  - "(seu)" no saguão;
  - status do editor e rodapé da criação de agente.
- **O que não muda:** as barras de PV, PE e SAN e as cores de elemento. Não são um par de sucesso e falha, e já se distinguem pelo rótulo e pela posição.

![Dados](daltonismo_dados_18.png)
![Desfecho](daltonismo_18.png)

## Testes

O `tests/unit/test_acessibilidade.gd` tem 9 testes:

- **Atalhos:** padrões no InputMap, repetição, setas e Enter numérico; remapear e salvar; troca no conflito; telas diferentes dividindo tecla; Esc reservado; restaurar.
- **Folha:** remapeia pela tecla e Esc desiste.
- **Carta:** mostra a tecla escolhida.
- **Flashes:** suaves por padrão (força e ritmo do pulso).
- **Daltonismo:** paleta, com ✓ no dado e a cor do selo.

Total: **445 testes**.

## Pendências

- Os atalhos são só de teclado. Os botões do controle seguem o ADR 0004 e não são remapeáveis.
- O modo suave limita a frequência, mas não mede a área do clarão (o outro critério do WCAG 2.3.1). Os pulsos cobrem a vista inteira, só que com 45% da força.
- O BBCode do log das regras (`missao.gd`, "Encontro vencido") continua com o verde em hex: é lógica pura e não conhece o `Tema`.
