# CLAUDE.md

RPG fanmade de Ordem Paranormal no estilo For The King, feito em Godot 4 com GDScript. Toda a documentação está em português. Comece por `docs/00-visao-e-spec.md` e `docs/01-brainstorm-design.md`.

## Regras do projeto

- O livro de regras fica em `reference/Ordem Paranormal RPG.pdf`. É material **pago**: nunca faça commit dele nem cite trechos longos em arquivos versionados. Registre só números e estruturas, escreva as descrições com palavras próprias e indique `ref: "p.N"`.
- O PDF tem mais de 100 MB e o Read não abre. Para extrair texto, use `pypdf` via Python numa pasta temporária. O sumário (outline) do PDF dá a página de cada seção.
- O PDF tem marca d'água com dados pessoais do comprador. Nunca reproduza.
- O conteúdo do jogo vive em `game/data/rulesets/<id>/` como JSON (ADR 0002). `game/scripts/rules/` é lógica pura, sem nós de cena.
- Os testes usam GUT 9.6.1, em `game/tests/unit/`. Rode com `GODOT=<console.exe> tools/rodar_testes.sh`. Nesta máquina, o Godot fica em `E:\Downloads\Godot_v4.6.1-stable_mono_win64\...\Godot_v4.6.1-stable_mono_win64_console.exe`.
- O JSON do Godot devolve todo número como float: converta com `int()` ao ler os dados do ruleset.
- Toda decisão estrutural vira um ADR em `docs/adr/`.
