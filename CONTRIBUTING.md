# Contribuindo

Obrigado por ajudar! Este é um projeto de fã, então leia primeiro [docs/03-legal-e-conteudo.md](docs/03-legal-e-conteudo.md).

## Regras de ouro

1. **Nunca** suba conteúdo do livro: PDF, prints ou texto copiado. Escreva as descrições com palavras próprias e indique a página em `ref`.
2. **Nunca** use arte oficial. Registre a origem e a licença de cada asset em `game/assets/CREDITS.md`.
3. Toda regra nova vem com **teste** em `game/tests/`.

## Fluxo

1. Escolha ou abra uma **issue** e use o rótulo da fase (`fase:1`, `fase:2`…).
2. Crie uma branch: `feat/<assunto>`, `fix/<assunto>`, `docs/<assunto>` ou `content/<assunto>`.
3. Commits curtos, em português, no imperativo: `adiciona teste de perícia em slots`.
4. Abra um **Pull Request** ligado à issue.

## Código (GDScript)

- Siga o [guia de estilo do GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html): `snake_case` para funções e variáveis, `PascalCase` para classes.
- Os nomes do domínio ficam em português, como no livro: `pericia`, `nex`, `sanidade`, `ritual`. Os termos técnicos podem ficar em inglês.
- `scripts/rules/` **não depende** de cenas nem nós. É lógica pura e testável.

## Decisões de arquitetura

Mudanças estruturais precisam de um ADR em `docs/adr/` (copie o formato dos existentes).
