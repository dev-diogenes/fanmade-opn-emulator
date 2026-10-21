# Qualidade gráfica

> Status: **v0.1**, 21/10/2026. Resolve a pendência de desempenho do [22-clima-de-terror-3d.md](22-clima-de-terror-3d.md).

Ajuste **Qualidade gráfica: alta / média / baixa** em **Pausa › Ajustes** e na **Base › Jogadores** (`MenuPausa.montar_leitura`). Vale na hora, em tudo o que está aberto, e fica salvo em `preferencias.json` → `qualidade`.

| | Alta (padrão) | Média | Baixa |
|---|---|---|---|
| SSAO (oclusão de ambiente) | sim | não | não |
| Desfoque de maquete (DOF) | sim | não | não |
| Glow (janelas, marcos) | sim | sim | não |
| Névoa rasteira | sim | sim | não (a névoa comum fica) |
| Sombras (lua, clareira, lanterna) | sim | sim | não |
| Luzes de clima (janelas de cidade, casas em volta do combate, velas, fogueira) | sim | sim | não |
| MSAA | 4x | 2x | desligado |
| Resolução da cena 3D | 100% | 100% | **75%** (a interface continua nítida) |

**Como funciona:** a classe `Qualidade` registra o que pode mudar em quatro grupos de nós:

- **ambientes:** `Qualidade.ambiente`, chamado por `Pecas.ambiente` e pela investigação;
- **vistas 3D:** `Qualidade.vista`, nos quatro `SubViewport` (título, mapa, combate e investigação);
- **luzes com sombra:** `Qualidade.sombra`;
- **luzes de clima:** `Qualidade.luz_extra`.

Trocar o nível chama `Qualidade.aplicar(get_tree())`. **A qualidade só desliga, nunca liga** o que a cena não usa: a investigação, sem glow, continua sem glow na alta. Os marcos do mapa (encontro, covil, vila) mantêm a luz em todos os níveis, porque informam.

## Medição

Medido nesta máquina, a 1280×720, com V-Sync desligado. É a média de 4 s, depois de a cena assentar.

| Cena | Alta | Média | Baixa |
|---|---|---|---|
| Mapa (início da missão 11) | 51 FPS | 73 FPS | 174 FPS |
| Combate na cidade (casas acesas em volta) | 43 FPS | 62 FPS | 157 FPS |

- **Média:** cerca de +40%.
- **Baixa:** cerca de 3,5 vezes a alta.
- **Recomendação** (no tooltip do botão): para máquinas mais fracas, começar pela média.
- **Erro do Vulkan:** numa das rodadas da alta, o driver registrou um `VK_ERROR_OUT_OF_HOST_MEMORY` ao apresentar o quadro. O jogo continuou e a medição terminou, mas vale observar em máquinas com pouca memória de vídeo.

## Testes

O `tests/unit/test_qualidade.gd` tem 2 testes:

- **Níveis:** os três níveis aplicam e voltam (SSAO, glow, névoa rasteira, sombra, luzes de clima, MSAA e escala).
- **Teto da cena:** a qualidade não liga o que a cena não usa.

Total: **476 testes**.
