# ADR 0004: Co-op local por dono de agente

- **Status:** Aceito
- **Data:** 15/10/2026

## Contexto

A Fase 5 pede até 4 jogadores no mesmo PC, com controle ou teclado. O jogo é por turnos, como For The King: no mapa, no combate e na investigação há sempre **um agente da vez**. Não existe ação simultânea, então não é preciso tela dividida nem várias câmeras.

## Decisão

- **Cada agente tem um dono.** O dono é um jogador local (Jogador 1 a 4) com um dispositivo: *teclado e mouse* ou *controle N*. Um jogador pode ter vários agentes; sem configuração, o Jogador 1 (teclado) é dono de todos e o jogo fica como antes.
- **Na vez de um agente, só o dispositivo do dono age.** Cada cena (mapa, arena, investigação) filtra a entrada em `_input` com `ControleLocal.evento_permitido`. Eventos de outros dispositivos são descartados antes de chegar à interface. A Base da Ordem é de todos e não filtra nada.
- **Vários jogadores podem dividir o teclado** (modo "passa o mouse"). O filtro só separa teclado de controles e um controle do outro; quem está na vez é avisado por uma faixa no topo ("Vez de Rita — Jogador 2, controle 1").
- **Controles jogam sem mouse.** Os botões usam a navegação por foco do Godot (direcional e A), e os tabuleiros ganham um **cursor**: o direcional ou o analógico esquerdo movem o cursor pelo hex ou quadrado, A confirma e B volta para os botões. Os atalhos ficam em `Entrada.configurar()`, que cria as ações no `InputMap` em tempo de execução.
- Os donos são salvos na carreira (`Carreira.controles`), junto com os agentes.

## Consequências

- A lógica de quem pode agir fica em `scripts/core/controle_local.gd`, sem nós de cena, e é testada com eventos sintéticos.
- O modo de um jogador continua igual: com um dono só, o filtro deixa tudo passar.
- Agentes hipnotizados (que mudam de lado) e ameaças continuam sendo jogados pela IA; o filtro só vale para agentes do lado dos agentes.
- O mesmo dono por agente servirá de base para o online (Fase 8): um jogador remoto é só mais um tipo de dispositivo.
