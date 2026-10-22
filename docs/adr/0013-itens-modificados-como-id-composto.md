# ADR 0013: itens modificados guardados como id composto

- **Status:** aceito, 22/10/2026
- **Contexto:**
  - as modificações do livro para armas, munições, proteções e acessórios (Tabelas 3.5, 3.7 e 3.9; p.70-74);
  - o arsenal por agente (docs/64);
  - o arsenal do livro (docs/67);
  - docs/68.

## Contexto

No livro, qualquer arma, munição, proteção ou acessório pode ser requisitado com modificações. Cada modificação sobe a categoria do item em I e não se repete: uma katana (categoria I) certeira e perigosa é um item de categoria III.

**Como o inventário funcionava:**
- era uma lista de ids (`Agente.equipamento: Array[String]`);
- itens repetidos eram unidades a mais (granadas, munição);
- `Ruleset.equipamento(id)` devolvia o dicionário do item;
- os itens amaldiçoados (p.154) já eram montados a partir de uma base, mas como entradas fixas em `equipamentos.json`.

Com 22 modificações e cerca de 70 itens que as aceitam, as combinações passam de milhares. Não dá para listá-las no JSON.

## Decisão

- **Um item modificado é o id da base seguido das modificações, separadas por `+`:**
  - `pistola+alongada+mira_laser`;
  - `protecao_pesada+blindada`;
  - `balas_curtas+explosiva`.
- **A modificação que pede uma escolha** leva o parâmetro depois de `:`: `notebook+funcao:investigacao+instrumental:tecnologia`.
- **`Ruleset.equipamento(id)` monta o item** a partir da base e guarda o resultado num cache:
  - a categoria sobe I por modificação;
  - os efeitos são somados;
  - o nome vira "Pistola alongada, mira laser";
  - o campo `base` guarda o id original.

  O id é inválido (`{}`) quando:
  - uma modificação não serve para o tipo do item;
  - uma modificação se repete;
  - uma combinação fere o que o livro pede, como compensador sem arma automática ou proteção discreta e reforçada.
- **Os efeitos ficam em `equipamentos.json` (`modificacoes`),** com:
  - `aplica`: corpo_a_corpo, disparo, fogo, municao_balas, protecao, protecao_leve, protecao_pesada ou acessorio;
  - `efeitos`;
  - `exige`, `exclui` e `exclui_se`, quando houver.
- **Base amaldiçoada:** a modificação pode vir sobre uma base amaldiçoada (`pistola_predadora+alongada`), porque a base é montada primeiro.
- **A munição modificada vale na arma que a dispara.** Dum dum e explosiva passam o efeito para a arma pela `efeitos_municao` do pacote.

## Consequências

- **O resto do jogo não muda:**
  - o inventário continua uma lista de strings, e o save não muda de formato;
  - cotas, carga e validação leem o item montado;
  - combate, defesa e perícias usam os mesmos campos de antes (`bonus_ataque`, `margem`, `defesa`, `resistencias`, `bonus_pericia`, `kit`).
- **O arsenal reconhece as versões de um item pela base** (`Ruleset.base_do_item`). Desmarcar a etiqueta tira todas.
- **Um item com `+` no id não é mais um id simples.** Nenhum id de base pode ter `+` ou `:`.
- **Uma nova modificação é uma entrada no JSON.** Ela só precisa de código se o efeito for de um tipo novo.
