# ADR 0017: selos como item de id composto e os achados da missão

- **Status:** aceito, 23/10/2026
- **Contexto:**
  - Criar Selo (p.43) e Selos Paranormais (p.161);
  - O Crime Compensa (p.28);
  - o item modificado como id composto (ADR 0013);
  - docs/76.

## Contexto

Um selo guarda um ritual qualquer. Criar um item no `equipamentos.json` para cada ritual seria uma lista de 85 entradas quase iguais. O Crime Compensa pede itens "achados na missão", e o jogo não tinha nenhum item que surgisse durante a missão.

## Decisão

- **O selo é um id composto**, `selo:<ritual>`, como `pistola+certeira` (ADR 0013).
  - `Ruleset.equipamento` monta a ficha na hora: nome, categoria (o círculo), grupo paranormal e consumível.
  - Entra e sai do `equipamento` do agente como qualquer item.
- **Os achados são as armas das pessoas vencidas**, que a missão guarda em `Missao.itens_achados`: só as que existem no arsenal do livro, sem repetir.
  - No fim da missão, viram `Carreira.achados`.
  - O criminoso escolhe um deles no Arsenal (`Agente.item_do_crime`).
  - O item fica fora da cota (`Agente._contam_na_cota`) e sai do inventário no fim da missão seguinte.
- **A categoria e os espaços efetivos** ficam no agente (`categoria_do_item`, `espacos_do_item`). A cota, a carga, a validação, a ficha e o Arsenal usam essas funções, em vez de ler o número do item.

## Consequências

- **Saves:** os campos novos (`item_do_crime`, `achados`, `itens_achados`, os usos por missão) têm valor padrão. Saves antigos carregam sem mudança.
- **Componentes improvisados** ficam no agente durante a missão e não vão para o save. Uma missão carregada no meio os perde.
- **Outros itens criados no jogo**, como o item de um ritual de criação, podem seguir o mesmo caminho do selo.
