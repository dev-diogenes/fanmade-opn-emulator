# ADR 0007: Online por comandos replicados (lockstep) e Modo Mestre

- **Status:** Aceito
- **Data:** 16/10/2026

## Contexto

A Fase 8 pede uma sessão online com mestre. O jogo já tem:
- lógica pura e determinística: toda rolagem passa por `Dados`, com seed;
- um save completo da carreira, com o estado do gerador de números;
- co-op local com um dono por agente (ADR 0004).

O combate, porém, não é salvável no meio: ele é montado da configuração do encontro (com a seed) e evolui na memória.

Havia duas formas de sincronizar:
1. **Estado:** o host roda tudo e manda o estado inteiro a cada ação. Isso exige serializar o combate e mandar muito dado.
2. **Comandos (lockstep):** todos partem do mesmo estado e aplicam as mesmas decisões na mesma ordem. Como tudo é determinístico, o resultado é igual em todo lugar.

## Decisão

- **Toda ação de jogador é um comando:** um dicionário que vira JSON sem perda, como `{"ctx": "combate", "acao": "agredir", "ator": 0, "alvo": 4, "foco": 1}`. Seres entram pelo índice no combate; hexes e células, como `[x, y]`. `Comandos` aplica cada comando à lógica: `Missao`, `CenaInvestigacao` ou `Combate`. As telas não chamam mais a lógica direto: montam o comando e o entregam à `Sessao`.
- **O host é a autoridade da ordem:**
  - O cliente pede (`pedir(cmd)`).
  - O host confere se quem pediu pode agir: é o dono do agente da vez, ou o mestre.
  - O host numera o comando e o manda a todos (`aplicar(seq, cmd)`).
  - Todos aplicam em ordem. Ninguém aplica um comando fora da vez.
- **O que não é decisão roda em cada máquina:** turnos das ameaças pela IA, o turno do mundo, surgimentos e Inspiração Resoluta. O passo a passo do combate fica em `FluxoCombate`, que a arena, o piloto e os testes usam igual.
- **Checkpoint e replay:**
  - Ao trocar de cena (Base → mapa → combate/investigação → mapa), o estado da carreira (`para_dicionario`) é o checkpoint, e o registro de comandos recomeça.
  - Para ressincronizar um cliente, o host manda o checkpoint e o registro; o cliente remonta tudo e reaplica os comandos.
  - Combate e investigação se remontam da configuração e da seed que já estão na missão.
- **Checksum:** cada comando leva o hash do estado do host no ponto de decisão em que foi aceito. O cliente compara com o seu antes de aplicar. Se não bater, pede ressincronização.
- **Transporte:** ENet pelo multiplayer de alto nível do Godot (`ENetMultiplayerPeer`), por IP e porta (7777 por padrão). Steam fica para depois.
- **A Base é do host:** só ele recruta, requisita e inicia missões, e a carreira é salva só nele. Os clientes recebem o checkpoint quando a missão começa.
- **Donos online:** cada jogador do `ControleLocal` ganha um `peer`. Um agente só aceita comandos do peer do seu dono. Quando um cliente cai, os agentes dele passam para o jogador 1 do host.
- **Modo Mestre** é um papel: um dos peers, que pode ser o próprio host. O mestre:
  - vê o mapa inteiro;
  - pode jogar as ameaças no lugar da IA;
  - tem comandos próprios (`ctx: "mestre"`): narrar no registro, mexer na Membrana, revelar hexes, pôr encontros e eventos no mapa, ferir e curar.
  - Como são comandos, as ações do mestre se replicam como as outras.
- **Ordem da entrega:**
  - **8.1:** comandos, `FluxoCombate`, `Sessao` local e telas por comando. Não muda nada no jogo offline e prova o replay.
  - **8.2:** rede e saguão.
  - **8.3:** Modo Mestre.

## Consequências

- Qualquer código de lógica que usar outro gerador de números, ou que depender da ordem de algo não determinístico, quebra a sincronia. O checksum detecta o problema, e a ressincronização corrige no ponto seguinte.
- Comandos são pequenos (dezenas de bytes). O tráfego pesado é só o checkpoint, que tem o tamanho de um save, a cada troca de cena ou ressincronização.
- A IA das ameaças e a animação rodam em cada máquina, então a latência só pesa nas decisões dos jogadores.
- Um novo tipo de ação no jogo precisa virar comando. Uma tela que chamar a lógica direto funciona offline, mas sai de sincronia online.
- O registro de comandos também serve para reproduzir bugs: checkpoint mais comandos refazem a partida.
