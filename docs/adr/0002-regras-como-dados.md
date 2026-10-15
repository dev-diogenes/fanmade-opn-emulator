# ADR 0002: Regras como dados e rulesets plugáveis

- **Status:** Aceito
- **Data:** 14/10/2026

## Contexto

O mesmo jogo precisa rodar a **V1**, com o livro de 2022, e a **V2**, com as regras novas, que podem mudar parte das mecânicas. Missões da comunidade precisam declarar para qual ruleset foram feitas.

## Decisão

1. **Conteúdo em dados.** Atributos, perícias, origens, classes, trilhas, itens, rituais, ameaças e tabelas ficam em arquivos JSON dentro de `game/data/rulesets/<id>/`. Cada entrada tem `id`, campos de mecânica, `descricao` (escrita com palavras próprias) e `ref` (a página do livro).
2. **Regra em código, com pontos de troca.** As mecânicas que mudam entre versões são funções de um `Ruleset`:
   - fórmula do teste;
   - cálculo de PV, PE e SAN;
   - ações de combate;
   - ações de investigação.

   `Ruleset` é uma classe base, e `RulesetOp2022` é a sua implementação. A V2 herda dela e sobrescreve só o que mudar.
3. **Manifesto.** Cada ruleset tem um `ruleset.json` com `id`, `nome`, `versao_livro`, `herda_de` (opcional) e a lista de arquivos de dados.
4. **Missões** declaram `"ruleset": "op2022"`. O jogo recusa carregar uma missão de ruleset desconhecido.

## Consequências

- Balancear o jogo vira editar JSON, o que é acessível a colaboradores fãs.
- É preciso validar o esquema ao carregar os dados, para pegar erros cedo.
- Com `herda_de`, a V2 só sobrescreve o que mudar e evita duplicar conteúdo.
