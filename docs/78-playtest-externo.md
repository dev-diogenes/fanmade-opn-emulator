# Playtest externo

> Status: **v0.1**, 02/11/2026. Sprint 01 ([sprints/sprint-01.md](sprints/sprint-01.md)). Junta o plano de validação do tutorial (docs/07) com os critérios "com pessoas" que faltam no roadmap: Fase 2 (5 pessoas de fora terminam uma missão), Fase 5 (co-op com 4 sem bug que trave), Fase 6 (alguém de fora cria e joga uma missão) e Fase 8 (uma sessão online com mestre).

## Formatos de sessão

| Sessão | Fase | Pessoas | Duração | O que valida |
|---|---|---|---|---|
| **A. Solo** | 2 e tutorial | 1 testador e 1 moderador | 45 a 60 min | Primeiro contato, tutorial, uma missão até o fim |
| **B. Co-op local** | 5 | 2 a 4 no mesmo PC | 60 min | Donos dos agentes, faixa "Vez de…", controle e teclado |
| **C. Online com mestre** | 8 | 2 a 4 em PCs diferentes | 60 a 90 min | Sala por código, saguão, mestre jogando as ameaças, sem dessincronia |
| **D. Editor** | 6 | 1 testador | 45 min | Criar, validar, salvar e jogar uma missão |

Comece pela **A**, com pelo menos 2 pessoas, antes das outras. Muita trava das sessões B, C e D vem do primeiro contato.

## Antes de cada sessão

1. Use a build da sprint (`builds/`), não o editor.
2. Apague a pasta de dados do jogo para começar do zero: `%APPDATA%\Godot\app_userdata\Membrana (fanmade, não oficial)\`. Antes, guarde a pasta da pessoa anterior.
3. Grave a tela se a pessoa deixar. Explique que o teste é do jogo, não dela.
4. Tenha a ficha de observação aberta (mais abaixo).

## Roteiro da sessão A (solo)

1. **Aquecimento (5 min):** "Você conhece Ordem Paranormal? Já jogou For The King?" Anote a persona (docs/07): fã de OP, jogador de FTK ou mestre de mesa.
2. **Primeiro contato (3 min):** abrir o jogo e observar o título, a tela Sobre e o convite do tutorial. Não sugira nada.
3. **Tarefas (35 min)**, ditas uma de cada vez, sem ajudar:
   1. "Crie ou escolha os agentes, monte um grupo e comece uma missão."
   2. "Leve um agente até um evento ou um encontro."
   3. "Vença o primeiro combate."
   4. "Faça uma investigação e descubra uma pista."
   5. "Responda uma pergunta do caso no quadro."
   6. "Termine a missão" (ou pare aos 35 min e anote onde a pessoa chegou).
4. **Relatório (2 min):** em Ajustes, **Gerar relatório do playtest**. Peça o arquivo para a pessoa.
5. **Conversa final (8 min):** as perguntas do docs/07, mais estas:
   - "O que você achou que a Membrana fazia?"
   - "Você entendeu de onde veio a resposta do caso?"
   - "Teve algum momento de medo ou tensão? Qual?"

## Roteiros curtos B, C e D

- **B (co-op):** cada pessoa escolhe um dispositivo na Base. Jogam uma missão juntos. Anote toda vez que alguém tentar agir fora da própria vez, e toda vez que o controle não chegar a um botão.
- **C (online com mestre):** o host cria a sala e passa o código, e uma pessoa vira mestre. Peça ao mestre para narrar uma vez, pôr um encontro e jogar o turno das ameaças. No fim, anote se alguém viu "fora de sincronia" e se o estado final bateu.
- **D (editor):** "Crie uma missão com um evento, um encontro e um covil, valide e jogue." Anote cada erro de validação que a pessoa não entendeu.

## Ficha de observação

Uma linha por pessoa e sessão:

| Pessoa | Sessão | Persona | Aceitou o tutorial? | Pulou tour (tela e passo) | T1 | T2 | T3 | T4 | T5 | T6 | Travas (hipóteses 1-6 do docs/07 ou novas) | Bugs | SEQ (1-7) | Frase marcante |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|

Em cada tarefa, anote o tempo e se precisou de ajuda (✓ sozinho, ½ com dica, ✗ não conseguiu).

## Critérios de sucesso

| Critério | Meta |
|---|---|
| Começar a primeira missão sem ajuda | 4 de 5 pessoas |
| Terminar o primeiro combate sem ajuda | 4 de 5 |
| Responder uma pergunta do caso | 3 de 5 |
| Terminar uma missão (Fase 2) | 5 pessoas de fora, em uma ou mais sessões |
| Co-op sem bug que trave (Fase 5) | 1 sessão com 4 pessoas |
| Online com mestre sem dessincronia (Fase 8) | 1 sessão |
| Missão criada e jogada por alguém de fora (Fase 6) | 1 pessoa |
| SEQ médio | 5 ou mais |

## Depois dos testes

1. Junte as fichas e os relatórios gerados numa pasta `playtests/AAAA-MM-DD/` fora do git: eles podem ter nomes reais.
2. Agrupe as travas por tema e marque impacto e esforço (`design:research-synthesis`).
3. Viram o backlog da Sprint 02: primeiro as de alto impacto e baixo esforço.
4. Marque no roadmap os critérios de pronto que fecharam.
