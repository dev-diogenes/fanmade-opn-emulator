# Sensação de jogo (feedback) no estilo de OP

> Status: **v0.1**, 20/10/2026. Continua o [10-terror-e-menus.md](10-terror-e-menus.md) e o [11-audio.md](11-audio.md): cada ação do jogador tem uma resposta visual e sonora.

| Onde | Resposta |
|---|---|
| **Combate: acerto** | Som de golpe (estalo + baque). O dano sobe e some sobre o alvo (`−5`). Quem atacou toca a animação de ataque |
| **Combate: crítico** | `CRÍTICO −12` dourado e maior, com glitch de VHS |
| **Combate: erro** | "ERROU" cinza, com som de ar cortado |
| **Combate: ritual** | Acorde dissonante que cresce e corta. O conjurador toca a animação de conjurar |
| **Mapa: andar** | Passos a cada movimento de agente |
| **Mapa: encontro** | Duas notas graves descendo e a fita falhando por 1 s, antes de ir para o combate |
| **Mapa: investigação** | A nota da pista |
| **Mapa: evento** | O bilhete abre com papel e é datilografado |
| **Base: Arsenal** | Gaveta de evidências: cada item é uma etiqueta de papel (nome, categoria, espaços). Marcada, ganha o carimbo **REQUISITADO**. Os amaldiçoados têm ☠ e borda vermelha, com as maldições no tooltip |
| **Título** | Caixinha de música desafinada em laço: tom menor, com uma nota "errada". Toca só no título e desliga com o som ambiente |

![Arsenal](arsenal.png)
![Dano no combate](combate_dano.png)
