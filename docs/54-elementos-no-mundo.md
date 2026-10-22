# Elementos no mundo: comportamento, cor, presságio e som

> Status: **v0.1**, 22/10/2026. Terceira fase do plano (relatório de pesquisa, itens EL1, EL2, EL6 e AU1). As descrições dos elementos vêm da wiki de Ordem Paranormal, resumidas com palavras próprias.

## O problema

Fora a cor da base da peça, os cinco elementos não se distinguiam:
- **Comportamento:** toda criatura ia no agente mais próximo.
- **Cor:** a paleta seguia a convenção "energia roxa, medo branco", que a wiki corrige.
- **Som:** nenhum próprio.
- **Mapa:** nada anunciava a criatura antes do encontro.

## O que mudou

### Cada elemento caça de um jeito

É **escolha de alvo**, papel do mestre, e não regra nova; as fichas do livro ficam como estão.

| Elemento | Na lore (wiki) | No combate |
|---|---|---|
| **Sangue** | criaturas cegas, guiadas pelo tato e frenéticas | vai em **quem se mexeu** nesta rodada ou na anterior; com todos parados, no mais próximo |
| **Morte** | acelera e desacelera de modo errático | vai no mais próximo, mas **numa rodada em cada três para, imóvel**, "como se o tempo tivesse falhado" |
| **Conhecimento** | ataca a mente, observa | mira **a menor SAN**, a mente mais frágil |
| **Energia** | caos, ação sorteada | escolhe o **alvo ao acaso** a cada rodada |

O acaso sai de uma semente da rodada e da criatura: é igual no online e não gasta os dados.

O combate passou a marcar quem tentou se mexer em cada rodada (`moveu_na_rodada`).

### A cor de cada elemento no mundo

- **Energia** é um **espectro neon**: roxo de base, com rosa, ciano, azul e verde. A criatura brilha numa luz que troca de cor sem parar.
- **Morte** é **lodo preto** com cinza.
- **Medo não tem cor:** a criatura fica quase transparente e lavada. Na interface, o Medo segue em branco, para ser legível.

### Presságios no mapa

Toda criatura paranormal deixa o **sinal do seu elemento num hex revelado vizinho**. O grupo vê o sinal antes de dar de cara com ela, e o sinal some quando a criatura sai.

| Elemento | Presságio |
|---|---|
| Sangue | uma carcaça com as costelas à mostra, numa mancha escura |
| Morte | relva cinza e cinza em espiral |
| Conhecimento | um poste com uma corda e uma máscara dourada |
| Energia | um poste com uma luz que pisca em neon |
| Medo | névoa parada, que não se mexe com o vento |

Somado aos sintomas do briefing (docs/52), o presságio ajuda a deduzir o elemento do caso antes de confirmá-lo no relatório.

![O presságio de Energia (o poste em ciano) ao lado da criatura, e o rumo do caso no quadro](el54_pressagio.png)

### O som de cada elemento

Cinco assinaturas sintetizadas em código, como o resto do áudio (docs/11), a partir da trilha que a wiki atribui a cada elemento:
- **Sangue:** metal batido e respiração molhada.
- **Morte:** uma nota que nasce invertida e um tique-taque fora de ritmo.
- **Conhecimento:** sino com eco e um sussurro em coro.
- **Energia:** estática em rajadas e um zumbido de serra estourado.
- **Medo:** quase silêncio, e três notas de piano que não combinam.

Tocam quando o combate começa (o elemento da criatura mais forte) e quando a noite cai (o elemento do caso).

![Combate contra a Energia: o Anárquico em neon](el54_energia.png)

## Medido

O playtest (10 seeds) ficou igual ao de docs/53: vitória 1,0 e 2,5 combates por missão para o investigador. A IA nova muda quem apanha, não o tamanho da luta.

## O que falta

- **As peças ainda são esqueletos do KayKit tingidos.** A silhueta por elemento entra junto da troca dos agentes por figuras contemporâneas (próxima fase):
  - Sangue: baixa e larga;
  - Morte: alta e magra;
  - Conhecimento: ereta, com máscara;
  - Energia: instável e translúcida.
- **O ambiente sonoro contínuo** (Realidade acústica, Outro Lado sintético que cresce com a Membrana) fica para a fase do som.

## Onde está

- **IA:**
  - `IaAmeaca`: `alvo_do_elemento` e `parado_no_tempo`;
  - `IaCombate.jogar`: a Morte que para;
  - `Combate.mover`: `moveu_na_rodada`.
- **Cor e peças:**
  - `Tema`: `ESPECTRO_ENERGIA` e `LODO_MORTE`;
  - `Pecas.ameaca`: tinta por elemento, Medo translúcido, `_neon`;
  - `Pecas.pressagio`.
- **Mapa:**
  - `Mapa3D.atualizar_pressagios`;
  - `Missao.elemento_de`, com cache.
- **Som:**
  - `Som`: `el_sangue`, `el_morte`, `el_conhecimento`, `el_energia`, `el_medo`;
  - a arena e a virada da noite os tocam.

## Testes

Total: **597**. Arquivo novo `test_elementos.gd`:
- **Comportamento:**
  - o Sangue vai em quem se mexeu;
  - o Conhecimento mira a menor SAN;
  - a Energia sorteia, igual no online;
  - a Morte para mais ou menos uma rodada em três;
  - o combate marca quem se mexeu.
- **Presságios e sons:**
  - cada elemento tem presságio, e o de Energia pisca;
  - os cinco sons existem;
  - o mapa põe o presságio ao lado da criatura.
