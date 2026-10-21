# ADR 0009: atalhos de teclado como ações remapeáveis

- **Status:** aceito, 20/10/2026
- **Contexto:** docs/15 (A4) e docs/18

## Contexto

Cada tela tratava o teclado comparando `evento.keycode` com constantes (`KEY_F`, `KEY_TAB`, `KEY_W`…):

- `mapa_mundo`, `arena_teste`, `investigacao`, `camera_rig`, `dossie_agente`.

Essa abordagem tinha três problemas:

- não dava para trocar uma tecla;
- não havia uma lista única para mostrar ao jogador;
- os textos de dica ("(F)", "(Tab)", "(C)") repetiam a tecla à mão.

## Decisão

- Uma classe estática, `Atalhos`, é a **única fonte** das teclas de ação. Ela guarda id, nome, grupo e tecla padrão.
- Na inicialização (`Entrada.configurar`) e a cada troca, cada ação vira `atalho_<id>` no **InputMap**. As telas consultam o InputMap por `Atalhos.pressionou` e `Atalhos.segurando`, nunca por `KEY_*`.
- **Conflitos** são por tela: cada grupo declara em que telas vale. Uma tecla nova que já pertence a outra ação de uma tela em comum faz as duas trocarem de tecla.
- **Esc** fica fora: é a saída fixa (`ui_cancel`). As **setas** e o **Enter numérico** valem junto, como teclas extras fixas.
- O que o jogador mudou fica em `user://preferencias.json` (`atalhos`), só com as diferenças do padrão.
- O controle (ADR 0004) continua com as próprias ações e não é remapeável por enquanto.

## Consequências

- Uma tela nova com teclado registra a ação em `Atalhos.ACOES` e usa `pressionou`. Assim ela aparece na folha e pode ser trocada sem mais trabalho.
- Textos com tecla usam `Atalhos.com_tecla` ou `nome_tecla` e acompanham a troca.
- O teste de comandos não muda: as teclas só disparam os mesmos métodos que os cliques.
