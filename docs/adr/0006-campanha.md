# ADR 0006: Campanha como sequência de missões v1

- **Status:** Aceito
- **Data:** 16/10/2026

## Contexto

A Fase 7 pede uma campanha original de 3 a 5 missões. O jogo já tem o formato `mission.json` v1 (ADR 0005), que cobre mapa desenhado, caso, eventos, encontros, ameaças e covil próprios. Faltava o que liga as missões numa história: a ordem, os textos entre elas, consequências de uma missão nas seguintes e o progresso salvo na carreira.

## Decisão

- **Uma campanha é uma pasta** em `res://data/campanhas/<id>/`. Ela tem um `campanha.json` (`"formato": "opn-campanha"`, `"versao": 1`) e um arquivo de missão v1 para cada etapa (referência em `docs/05-campanha.md`). Cada missão é montada por `MissaoComunidade.criar_missao`, então valem as mesmas regras e a mesma validação.
- **Os textos ficam na campanha, não na missão:**
  - `prologo` e `antes` aparecem na Base;
  - `depois`, `falha` e `epilogo` aparecem no relatório.
  - O `briefing` de cada missão continua indo para o registro do mapa.
- **Marcas ligam as missões.** Cada missão pode associar uma marca a uma pergunta do caso. Responder à pergunta e vencer guarda a marca na carreira. Missões seguintes declaram `efeitos_de_marcas`, que valem no início delas: Membrana, chefe enfraquecido e objetivo revelado, os mesmos efeitos que a investigação já produzia. Assim a investigação de uma missão vale para a campanha toda, sem uma linguagem de script.
- **Recrutas da história:** a campanha declara fichas no formato de `recrutas.json`, e uma vitória as copia para `Carreira.recrutas_extras`. Daí em diante elas aparecem no recrutamento da Base como as outras.
- **A missão leva a campanha consigo.** No início, `Campanha.extras_da_etapa` copia para `missao.extras.campanha` os textos, as marcas possíveis e os recrutas. O fim da missão (e um save no meio dela) não depende de reler os arquivos.
- **Progresso por campanha** em `Carreira.campanhas[id]`: `{etapa, concluida, vezes, marcas, historico}`. Derrota não avança. Concluir e iniciar de novo recomeça da primeira missão: as marcas são zeradas e os recrutas continuam.
- **Cenas de investigação próprias** (`cenas` na missão) entram no formato v1 como campo opcional. A `Missao` procura a cena primeiro nos `extras` e depois em `data/jogo`, e `"visual"` reaproveita as peças 3D de uma cena do jogo.
- O critério "campanha completa jogável" é testado pelo piloto automático, que joga as 4 missões em sequência numa carreira, faz as escolhas de NEX sozinho (`PilotoMissao.resolver_pendencias`) e tenta de novo quando perde.

## Consequências

- Uma campanha nova é só dados: nenhum código muda para escrevê-la. As consequências narrativas ficam limitadas aos efeitos de marca existentes; um efeito novo precisa entrar em `Campanha.EFEITOS` e em `aplicar_marcas`.
- `cenas` e `caso.resumo` são campos opcionais do formato v1. Uma versão antiga do jogo acusa "cena desconhecida" numa missão que use `cenas`. Isso é aceitável enquanto o jogo não tem versão publicada.
- Missões de campanha não aparecem na lista da comunidade, porque pedem a ordem e as marcas da campanha.
- O Modo Mestre (Fase 8) pode usar o mesmo arquivo: o mestre lê `antes` e `depois` em voz alta e decide as marcas.
