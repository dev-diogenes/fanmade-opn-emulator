# ADR 0005: Missões da comunidade como JSON versionado

- **Status:** Aceito
- **Data:** 16/10/2026

## Contexto

A Fase 6 pede um formato de missão que pessoas de fora consigam criar e jogar, e um editor mínimo. O jogo já gera missões por seed (`GeradorMapa`, `Caso.gerar`) e guarda todo o conteúdo em JSON (ADR 0002).

## Decisão

- **Uma missão é um arquivo JSON** com `"formato": "opn-missao"` e `"versao": 1` (referência em `docs/04-missoes-da-comunidade.md`). O mapa pode ser desenhado (uma linha de letras por linha de hexes) ou gerado por seed. Além disso, o arquivo pode trazer caso, eventos, encontros, ameaças e covil próprios.
- **Conteúdo próprio vem antes do conteúdo do jogo.** A `Missao` guarda esse conteúdo em `extras`. As buscas de evento, encontro e ameaça olham primeiro ali e depois em `data/jogo` e no ruleset. Por isso uma missão pode usar qualquer ameaça do livro sem copiá-la.
- **Validação antes de jogar.** `MissaoComunidade.validar` devolve erros legíveis: terreno desconhecido, sem caminho até o objetivo, id inexistente, efeito inválido. A Base e o editor mostram esses erros, e a missão só começa quando não sobra nenhum.
- **Duas pastas:** `res://data/missoes` (exemplos do jogo) e `user://missoes` (do jogador). O editor salva nesta última.
- **O editor é uma cena fina** sobre `EditorMissao`, que é lógica pura e testada: pintar terreno, pôr conteúdo, redimensionar, gerar terreno, criar eventos.
- Os `extras` vão no save da carreira, junto da missão em andamento.

## Consequências

- Missões da comunidade usam as mesmas regras do jogo (orçamento de VD, Membrana, investigação, piloto automático nos testes).
- Ameaças, encontros e eventos com habilidades complexas ainda dependem de escrever o JSON à mão; o editor cobre mapa, eventos simples e covil.
- Uma versão nova do formato precisa de `"versao": 2` e de uma conversão; arquivos v1 continuam valendo.
- O mesmo formato vai servir às missões jogadas com mestre (Fase 8).
