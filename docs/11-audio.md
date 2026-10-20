# Áudio procedural

> Status: **v0.1**, 20/10/2026. Complementa o [10-terror-e-menus.md](10-terror-e-menus.md).

## Decisão

Todos os sons são **sintetizados em código** (`scripts/core/som.gd`) na primeira vez que tocam e ficam em cache. Por isso:
- não há arquivo de áudio no repositório;
- não há licença de terceiros;
- não há peso no Git LFS.

Quando o projeto tiver trilha e efeitos gravados, `Som.gerar(nome)` pode carregar um `.ogg` no lugar da síntese, sem mudar quem chama.

## Sons

| Nome | O que é | Onde toca |
|---|---|---|
| `estatica` | Ruído filtrado que some | Entrada de toda tela (`Transicao`) |
| `tecla` | Estalo metálico com batida curta | Datilografia (no máximo uma tecla a cada 45 ms) |
| `carimbo` | Baque grave com o "tapa" da borracha | Quando o carimbo do relatório bate |
| `papel` | Farfalhar | Abertura de diálogo, briefing e pausa |
| `clique` / `hover` | Clique seco e tique baixo | Todo botão do jogo (ligado pelo `Jogo` quando o botão entra na árvore) |
| `pista` | Duas notas agudas desafinadas, com tremor | Pista encontrada na investigação |
| `glitch` | Ruído em degraus, com cortes | Todo pulso de VHS (crítico, ritual, falha) |
| `drone` | Laço de 4 s: senos graves com batimento e vento | Ambiente. Cresce e desafina quando a Membrana cai |
| `sussurro` | Laço de 4 s: ruído em faixa de voz com "respiração" | Ambiente, a partir de intensidade 0,35 (Membrana abaixo de ~74) |

O ambiente segue `Tema.membrana_na_tela` e fica baixo na Base, no editor e no saguão.

## Barramentos e ajustes

- **Barramentos:** `Efeitos` e `Ambiente`, criados em tempo de execução, os dois enviando para o `Master`.
- **Ajustes na pausa:** volume geral e "Som ambiente". Ficam guardados em `user://preferencias.json`.
- **Volume dos efeitos:** cada efeito tem o seu volume em dB e uma leve variação de altura, para não soar repetitivo.
- **Medição:** conferimos o pico de cada som gerado, para nenhum estourar (todos ficam abaixo de 0,9).

## Ainda não

- Música (temas da Base, do mapa e do combate).
- Sons de passos, de ataque e de ritual por elemento.
