# Tutorial (tour guiado) e plano de validação

O tutorial é um **tour guiado** no estilo UserGuiding. Quando o jogo abre, a Base convida para o tutorial. Quem aceita vê um tour curto da Base, e os tours do mapa, do combate e da investigação aparecem **na primeira vez** que a pessoa chega a cada tela. Todo tour destaca um elemento por vez (o resto fica escuro), explica numa caixa com **Próximo / Voltar / Pular** e mostra em que passo está. O botão **?** de cada tela repete o tour daquela tela quando a pessoa quiser.

Os textos ficam em `game/data/jogo/tutorial.json` (conteúdo como dado, ADR 0002).

## Por que assim (brainstorm)

**O trabalho que o tutorial resolve:** "Abri o jogo pela primeira vez e quero começar uma missão e sobreviver ao primeiro combate sem me perder."

Opções consideradas:

| Opção | A favor | Contra |
|---|---|---|
| Missão-tutorial roteirizada | Aprende fazendo | Cara de manter; fica velha a cada mudança de tela |
| Um tour único e longo ao abrir | Simples | Explica o combate antes da pessoa ver um combate; muita gente pula no meio |
| Checklist de "primeiros passos" | Dá sensação de progresso | Sozinho, não explica nada |
| **Tours curtos por tela, na hora certa** (escolhido) | Explica cada tela quando ela aparece; 6 a 8 passos cada | Exige marcar os elementos de cada tela |

**Suposição mais arriscada:** que tours de 6 a 8 passos são curtos o bastante para as pessoas não pularem. Os playtests medem isso: veja as métricas abaixo.

**Ideias guardadas para depois:**
- pontos pulsantes (hotspots) em elementos novos depois de uma atualização;
- um tour do Modo Mestre;
- dicas contextuais, como "você tem uma escolha de NEX pendente".

## Quem vai jogar (proto-personas)

| Persona | Já sabe | Precisa aprender | Risco |
|---|---|---|---|
| **Fã de Ordem Paranormal** (assiste às campanhas, talvez jogue o RPG de mesa) | NEX, PE, Sanidade, elementos, Membrana | Como o jogo traduz a mesa em telas: mapa em hexágonos, slots de d20, ordem dos cliques | Não sabe por onde começar na Base, que tem informação demais |
| **Jogador de For The King** (não conhece OP) | Mapa por turnos, slots de rolagem, combate | O que são PE, SAN, NEX, Membrana e a investigação | Ignora a Membrana e a Sanidade e perde sem entender por quê |
| **Mestre de mesa** (quer jogar com o grupo) | As regras do livro | Co-op, online e o Modo Mestre | Não acha onde escolher o mestre nem como hospedar |

## O que cada tour ensina

- **Base:** quem são os agentes e como ler a ficha (PV, PE, SAN, NEX); escolhas de NEX; requisição de equipamento; montar o grupo; jogadores, mestre e online; escolher a missão e partir.
- **Mapa:** de quem é a vez; **rolar o movimento primeiro**; andar pelos hexes azuis e o que significa cada marcador; descansar e encerrar o turno; a Membrana; o registro.
- **Combate:** a grade e a cobertura; **escolher a ação e depois clicar** na célula ou no inimigo; testes em slots de d20; Foco e Ataque Especial; rituais e itens; encerrar o turno.
- **Investigação:** as perguntas do caso; escolher o ponto; procurar pistas pela perícia; facilitar e ajudar; o que cada resposta faz; urgência e saída.

## Onde esperamos que travem (hipóteses)

1. Na Base, sem saber que é preciso marcar o grupo e clicar em Iniciar missão.
2. Um agente com escolha de NEX pendente (!) impede a partida, e a pessoa não entende o motivo.
3. No mapa, clicar num hex antes de rolar o movimento, e nada acontecer.
4. Na arena, clicar no inimigo sem antes escolher Atacar.
5. Na investigação, não perceber que se escolhe o ponto clicando no objeto da cena.
6. Não ligar a Membrana caindo ao perigo crescente.

## Plano de validação nos playtests

**Objetivo:** saber se o tutorial leva uma pessoa nova a começar e terminar a primeira missão sozinha, e onde ela abandona ou se perde.

**Método:** teste de usabilidade moderado, com 5 pessoas (as da Fase 2). Cada sessão dura uns 45 minutos, com a pessoa pensando em voz alta. O moderador não ajuda, só anota.

**Roteiro da sessão:**
1. **Aquecimento (5 min):** "Você conhece Ordem Paranormal? Já jogou For The King?" Explicar que o teste é do jogo, não da pessoa.
2. **Primeiro contato (2 min):** abrir o jogo e observar o que a pessoa faz com o convite do tutorial. Não sugerir nada.
3. **Tarefas (30 min)**, ditas uma de cada vez:
   1. "Monte um grupo e comece uma missão."
   2. "Leve um agente até um evento ou um encontro."
   3. "Vença o primeiro combate."
   4. "Faça uma investigação e descubra uma pista."
   5. (Bônus, para o persona mestre) "Escolha um mestre e diga como você hospedaria uma partida online."
4. **Conversa final (8 min):**
   - "O que o tutorial explicou bem? O que faltou?"
   - "Em que momento você se sentiu perdido?"
   - "De 1 a 7, quão fácil foi começar a primeira missão?" (SEQ)
   - "Você pularia o tutorial numa segunda vez? Por quê?"
   - "Uma palavra para descrever o jogo."

**Planilha de observação**, uma linha por pessoa:

| Pessoa | Persona | Aceitou o tutorial? | Pulou algum tour (tela e passo)? | Tarefa 1 (tempo, ajuda?) | 2 | 3 | 4 | Travas observadas (hipóteses 1-6 ou novas) | SEQ (1-7) | Frases marcantes |
|---|---|---|---|---|---|---|---|---|---|---|

**Métricas do jogo:** o tutorial grava em `user://preferencias.json`, em `estatisticas_tutorial`, quantas vezes cada tour foi iniciado, concluído ou pulado e **em que passo** a pessoa pulou. No Windows, o arquivo fica em `%APPDATA%\Godot\app_userdata\Ordem Paranormal- Fanmade (WIP)\preferencias.json`. Depois de cada sessão, copie o arquivo ou anote os números e apague-o antes da próxima pessoa.

**Critérios de sucesso:**
- pelo menos 4 de 5 pessoas começam a primeira missão sem ajuda;
- pelo menos 4 de 5 vencem ou terminam o primeiro combate sem ajuda;
- menos de 1 em 5 pula o tour do mapa ou do combate;
- SEQ médio de 5 ou mais.

**Depois dos testes:**
- Agrupe as travas observadas por tema (mapa de afinidade).
- Marque cada uma por impacto e esforço.
- Corrija primeiro as de alto impacto e baixo esforço, que em geral são textos e a ordem dos passos no `tutorial.json`.
