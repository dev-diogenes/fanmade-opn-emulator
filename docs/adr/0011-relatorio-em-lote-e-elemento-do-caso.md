# ADR 0011: relatório em lote e elemento do caso

- **Status:** aceito, 22/10/2026
- **Contexto:** docs/51 (crítica a partir de uma partida), o relatório de pesquisa "Melhorias pelo universo de Ordem Paranormal" (itens IN1 e IN2) e docs/52
- **Substitui em parte:** ADR 0010 (a acusação por pergunta)

## Contexto

Na partida de docs/51, o caso se resolveu no turno 5. Duas causas:
- **Traços únicos:** de 10% a 50% dos traços apareciam num candidato só, então uma pista bastava para acusar.
- **Chute barato:** acusar errado custava 5 de Membrana por pergunta. Com uma pista deixando dois ou três suspeitos, chutar compensava.

Além disso, todo caso era de Sangue, e o elemento, o centro da lore de Ordem Paranormal, não pesava em nada.

## Decisão

- **Regra da tabela mais forte:** todo traço aparece em **dois candidatos ou mais**, e dois candidatos continuam dividindo no máximo um. A estrutura de cada pergunta:

  | Pergunta | Candidatos | Estrutura | Uma pista deixa |
  |---|---|---|---|
  | Quem | 7 | Plano de Fano: 7 traços, cada um em 3 suspeitos | 3 suspeitos |
  | O quê | 5 | 1 traço em 3 ações e 6 em pares | 2 ou 3 ações |
  | Onde | 6 | Bipartido 3 × 3 | 3 locais |
  | Reviravoltas | 4 | Cada par divide exatamente um traço | 2 candidatos |

  Em todos os casos, duas pistas diferentes deixam um só candidato. Um teste verifica as duas regras nos dados.
- **Relatório à Ordem (`Caso.relatar`), em lote como os destinos de Return of the Obra Dinn:**
  - Quem, o quê e onde se confirmam juntos, cada um com ao menos uma pista.
  - **Aceito:** as três perguntas se resolvem, os efeitos valem e a reviravolta aparece.
  - **Recusado:** a Membrana cai uma vez (`penalidade_palpite`) e nada se confirma.
    - No modo normal, a Ordem diz quantas respostas se sustentam; no hardcore, nada.
    - O mesmo relatório não pode ser mandado de novo (`relatorios_recusados`, vai no save).
  - **A reviravolta** continua com a acusação avulsa (`Caso.deduzir`).
- **Comando de lockstep `relatar`** no mapa e na cena, como o `deduzir` (ADR 0007).
- **Elemento do caso:**
  - Sai de uma semente do próprio caso (Sangue, Morte, Conhecimento ou Energia). Não gasta os Dados e sai igual no online.
  - O briefing traz só os **sintomas** do elemento, com sinais tirados da wiki.
  - Responder "o quê" o **confirma** na ficha. O registro diz o elemento opressor: no covil, os rituais dele têm vantagem (p.98 e p.118).
  - O covil e os encontros paranormais do mapa (e os que surgem) são do elemento do caso. Os de gente e bichos ficam, e o Medo só vem com a Membrana fina.

## Consequências

- **Bom:**
  - chutar com uma pista deixou de compensar: acertar três perguntas no escuro é improvável, e cada recusa custa Membrana;
  - o caso pede duas fontes por pergunta, ou seja, mais cenas, eventos e testemunhas antes do covil;
  - o elemento muda a missão inteira: as criaturas, o covil e os rituais que valem a pena.
- **Custo:**
  - o covil só abre com o relatório aceito ou com a Membrana rompida;
  - covis de Morte, Conhecimento e Energia só existem no primeiro nível; nos níveis mais altos, o covil cai para os de Sangue;
  - os textos dos traços tiveram de ficar genéricos o bastante para servir a dois ou três candidatos.
- **Saves antigos:** sem elemento, ficam com Sangue. Os traços são relidos da tabela atual, e a ordem das pistas é refeita se não bater.
