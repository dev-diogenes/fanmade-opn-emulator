# Medo no mapa: noite, caçada e linha do tempo

> Status: **v0.1**, 22/10/2026. Segunda fase do plano (docs/51 e o relatório de pesquisa, itens ME1, ME2, ME3, ME5, IN5 e CO2).

## O problema

Na partida de docs/51:
- **Nada no mapa avisava o que vinha.** O turno do mundo era uma linha no relatório.
- **As ameaças que surgiam ficavam paradas para sempre.** Ficar isolado só era perigoso na teoria.
- **Sem pista à vista, o jogo não dava rumo.** O grupo ficou 16 turnos em volta do covil selado.

O livro diz que o terror é a **antecipação** (p.162-163), e For The King tem dia, noite e uma linha do tempo das ameaças.

## O que mudou

### Dia e noite

- **O ciclo:** 3 turnos do mundo de dia e 2 de noite (`mapa.json`, `mundo.ciclo`).
- **À noite:**
  - **a visão cai 1** ao andar;
  - **as ameaças surgem duas vezes mais rápido** (o contador anda 2 por turno);
  - **as criaturas caçam**.
- **No 3D:** o dia é um crepúsculo; à noite a luz ambiente cai e esfria. A virada é suave.

### A caçada, com alívio (o diretor de Alien: Isolation)

- **Quem caça:** à noite, as ameaças que surgiram e as **criaturas paranormais** já espalhadas pelo mapa. Gente e bichos ficam onde estão.
- **Como anda:** cada uma dá **um passo por turno do mundo** até o agente **mais isolado** a até 6 hexes.
  - Não atravessa conteúdo e não se teletransporta.
  - **Vilas e o ponto de encontro são seguros.**
- **Rastro:** no hex de onde saiu, deixa pegadas na cor do elemento do caso, que somem em 2 turnos.
- **Alcançou um agente:** o encontro começa ali, com quem estiver por perto, como nos encontros comuns. É uma emboscada por turno do mundo, no máximo.
- **Alívio:** depois de qualquer combate, nada caça no turno seguinte. O pico passa e o jogador respira.
- **Na tela:** a peça anda de um hex ao vizinho, em vez de sumir e aparecer.

### A linha do tempo do Outro Lado

Embaixo da Membrana, **cinco bilhetes**, um por turno do mundo que vem:
- o número do turno e **☾** quando for noite (o bilhete fica azul);
- o que se prevê: **"Membrana instável/fina/rompendo"**, **"algo surge"**, **"algo caça"** e **"o covil se abre"**.

Ela não adivinha nada: faz a mesma conta do turno do mundo (−2 de Membrana por turno, o contador de surgimento, a noite).

### O progresso do caso no lugar de "Pistas"

O HUD mostrava "Pistas N", que contava testes de evento (docs/51). Agora mostra **"Caso a/b"**: as pistas firmes que contam para o relatório, até duas por pergunta em aberto. É o "Ato" de Arkham Horror contra a "Agenda", que é a Membrana.

### Rumo do caso

Sem nenhuma investigação ou evento à vista e com perguntas em aberto, o quadro do caso diz para onde ir: **"Sem pista à vista: há algo a nordeste, na névoa."** A direção é a do lugar com pista mais perto do agente da vez.

O aviso do covil selado agora sai **uma vez por turno**, não a cada passo, e lembra que o covil abre com o relatório à Ordem.

### O turno do mundo vira um momento

Quando o mundo age:
- uma faixa cruza a tela: **"TURNO 4 DO MUNDO · A NOITE CAI"**, ou "AMANHECE", ou só o turno;
- a fita treme;
- toca o som da estática, ou o do encontro na virada;
- as peças que caçam andam.

![A noite cai: a linha do tempo, o caso 0/6 e o mapa mais escuro](medo53_noite.png)

## Medido (`dev/playtest_auto.gd`, 10 seeds)

| Perfil | Vitória | Turnos | Combates | Mortos | PP |
|---|---|---|---|---|---|
| Investigador | 1,0 | 6,9 | **2,5** (era 1,9) | 0 | 15,8 |
| Pressa | 0,6 | 11,5 | **3,2** (era 2,3) | 0,3 | 18,5 |

Primeiro, só as ameaças que surgiam caçavam, e isso não mudava nada para o investigador: ele fecha o caso antes de a Membrana ficar instável. Com as criaturas do mapa caçando à noite, o medo começa na **primeira noite** (turno 4). Há mais combates, sem mais mortes.

## Onde está

- **Regra:**
  - `Missao`: `eh_noite`, `_cacar`, `_presa_perto`, `_passo_para`, `previsao`, `progresso_do_caso`, `rumo_do_caso`, `direcao_em_texto`, `rastros`, `alivio`, `passos_da_caca`;
  - `Membrana.estado_de`;
  - os ajustes em `mapa.json`.
- **Tela:**
  - `MapaMundo`: `_desenhar_linha_tempo`, `_momento_do_turno`, o "Caso a/b" e o rumo no quadro;
  - `Mapa3D`: `ciclo`, `mover_marcador`, `atualizar_rastros`.
- **Save:** os rastros e o alívio.

## Testes

Total: **589**. Arquivo novo `test_medo_mapa.gd`:
- **Noite:** o ciclo de dia e noite; quem surge caça.
- **Caçada:**
  - à noite a ameaça anda até o isolado e deixa rastro;
  - alcançar abre o encontro e o combate dá respiro;
  - a vila é segura.
- **Linha do tempo:** a previsão mostra a Membrana mudando, a noite e o rompimento.
- **Caso:** o progresso conta duas pistas por pergunta.
- **Rumo:** aponta a névoa, e o covil selado avisa uma vez por turno.
- **Save e tela:** rastros e alívio vão no save; o mapa mostra a linha do tempo e o caso.

O teste antigo de surgimento passou a contar dois surgimentos até o turno 4 (a noite dobra o ritmo).
