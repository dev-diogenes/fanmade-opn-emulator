# Chance nas escolhas, vez da ameaça e limpeza

> Status: **v0.1**, 21/10/2026. Implementa o pacote recomendado da [crítica 20](20-critica-pos-acessibilidade.md): **C2**, **C3** e **C4**.

## C2: chance nas escolhas

**Antes:** o evento mostrava "Diplomacia +0 (DT 15)", e a investigação, "Atletismo · DT 15". Para comparar as opções, era preciso saber quantos d20 o agente rola, que vale o maior e de onde vem um "−5".

**Agora:** toda escolha com teste mostra a mesma linha, montada pelo `LinhaTeste`:

> Luta · 3d20+5 · DT 15 · ≈ 91% (quase certo)

- **Dados:** a reserva de d20 e o bônus total. Com reserva 0 ou menos, aparece "2d20 (o pior)".
- **Chance:** em porcentagem, com uma palavra para a faixa:
  - **quase certo:** 85% ou mais;
  - **provável:** a partir de 60%;
  - **arriscado:** a partir de 35%;
  - **difícil:** abaixo disso.

  A palavra serve para quem não quer ler números.
- **★** marca a opção de maior chance para o agente da vez.
- **Tooltip:** explica a conta. Diz quem rola e com qual atributo, se a perícia está sem treino e de onde vem um bônus negativo (kit faltando, carga ou condição).
- **Perícia só para treinados:** mostra "exige treino" e fica bloqueada, em vez de "≈ 0%".

**De onde vem a chance:** das próprias regras, sem gastar PE nem rolar nada.

| Onde | Função |
|---|---|
| Teste de perícia (evento) | `Agente.prever_teste`, com as contas de `Agente.testar`: Foco, opções pagas, atributo trocado. O dado do Perito e as rerrolagens ficam de fora, então a chance é um piso |
| Procurar Pistas | `CenaInvestigacao.prever_procurar`: soma o +2 do Facilitar, a Ajuda, os dados da Na Trilha Certa e a Causalidade Fortuita. O teste e a previsão usam o mesmo `_preparar_procurar` |
| Facilitar e Ajudar | `prever_facilitar` e `prever_ajudar` |
| Ataque | `Combate.chance_de_acerto`: modificadores, alcance, flanco, cobertura, alvo em corpo a corpo, mira, Foco e Ataque Especial. Não conta a reação que o alvo ainda pode declarar. −1 = fora de alcance |
| Cálculo | `Teste.chance_de_passar` (já existia): com vários d20, basta um passar; com "o pior", todos precisam passar |

**Onde aparece:**

| Tela | Como |
|---|---|
| Evento no mapa | Cada opção em duas linhas: a ação e o teste. Todas no mesmo estilo de papel (antes, a primeira era um botão vermelho grande e parecia recomendada); ★ na melhor. O bilhete ficou mais largo (500 px) e as chances acompanham o Foco |
| Procurar | Uma linha por perícia do ponto, com dados, DT, chance e ★ |
| Facilitar | **Uma linha por ação**, com as perícias em selos ("Atletismo · ≈ 91%"). Antes eram quatro linhas para duas ações. Sem escolha, fica marcada a de maior chance |
| Ajudar | A chance em cada selo de perícia |
| Combate | No modo Atacar, o rótulo de cada alvo marcado ganha "acerto ≈ 45% (arriscado)", atualizado com o Foco e o Ataque Especial |

![Evento](evento_21.png)
![Procurar](procurar_21.png)
![Facilitar](facilitar_21.png)
![Ataque](atacar_21.png)

## C3: vez da ameaça

**Antes:** o topo mudava para "Rodada 1 · Cultista", as cinco cartas viravam cadeados e nada dizia quem agia nem em quem.

**Agora:**

- **Faixa:** abaixo da Membrana aparece "VEZ DA AMEAÇA · **CULTISTA** · → vai atacar Rita" (ou "→ avança sobre Rita"). A borda tem a cor do elemento da ameaça.
- **Intenção:** vem de `IaCombate.intencao`, que usa a mesma escolha de alvo de `IaCombate.jogar`. É uma intenção, não uma promessa: uma habilidade usada antes do ataque pode mudar o plano.
- **Mão e Foco saem de vista** enquanto a ameaça age e voltam na vez do jogador.
- **Pausa maior:** a vez da ameaça para 1,0 s (era 0,6 s), o tempo de ler a faixa.
- **Mestre humano:** quando é ele quem joga as ameaças, a faixa não aparece. A vez é dele, e os controles continuam os do mestre.

![Vez da ameaça](ameaca_21.png)

## C4: limpeza

| Pendência (crítica 15 e 20) | Como ficou |
|---|---|
| "Último teste —" no canto do combate e slots pequenos no dock do mapa | Escondidos: só a rolagem central, com o histórico no relatório. O tutorial fala da rolagem no centro |
| "* ainda sem efeito no motor" na ficha | Sem nota de rodapé. O que ainda não tem efeito aparece em itálico, com a dica "Ainda sem efeito nas regras deste jogo" ao passar o mouse |
| Rótulos "Perícias:" e "Habilidades:" a 4,9:1 (3,8 nas manchas) | `#4e4034`: cerca de 7:1 |
| Notas em tinta 60% (3,7:1) | 75% (cerca de 5,5:1): bilhetes da investigação, nota do mapa e cabeçalho do relatório |
| Textos de 11 a 13 px | 14 px: legendas e carimbo "RESOLVIDO" do quadro, objetivo do caso, PV/PE/SAN e números dos retratos, nota do mapa. O "REQUISITADO" do Arsenal é decorativo e ficou como estava |
| Foto 3x4 só na criação e na ficha (F) | Também na Base › Agentes, no lugar do sigilo |
| Carimbo do fim sobre o texto e o botão | O carimbo bate num vão reservado ao lado de "Voltar à Base" e acompanha a folha enquanto ela se acomoda |
| Seleção em vermelho cheio no papel | Lavado de ouro com borda dourada escura e tinta escura. O vermelho fica para a ação principal e o perigo |
| Topo do combate repetindo o retrato | "Bianca · Especialista, NEX 5% · Defesa 12" e a arma. PV, PE e SAN ficam no retrato |
| Pausa em lista corrida | Seções "Leitura e acessibilidade" e "Imagem e som"; o item vira "Ajustes ▾/▴" |
| "Nova carreira (apaga o save)" no meio das preferências | Seção própria, "Zona de perigo" |
| "Opções da run", "(p.184)" | "Regras opcionais", com tooltip do que cada regra faz |
| Arsenal sem dizer para quem | "Equipando Mauro (Recruta): até 2 itens de categoria I, 0 de II e 0 de III." |
| "Continuar carreira" sem contexto | Uma linha embaixo: "3 agentes · missão em andamento, turno 4" (`Carreira.resumo_save`, sem carregar o save) |
| Nomes empilhados no mapa | Quem divide o hex com outro só mostra o nome se for o agente da vez |

![Fim](fim_21.png)
![Base](base_21.png)
![Pausa](pausa_21.png)

## Testes

O `tests/unit/test_escolhas.gd` tem 11 testes:

- **`LinhaTeste`:** formato da linha, faixas e a melhor opção.
- **Previsão de perícia:** confere com 3.000 rolagens (±3%) e com o Foco.
- **Chance de acerto:** confere com 1.500 ataques (±3%) e devolve −1 fora de alcance.
- **Investigação:** a previsão soma o +2 do Facilitar.
- **Intenção da IA:** ataca o mais próximo ou avança sobre ele.
- **Faixa da vez:** aparece, e a mão desce e volta.
- **Ficha:** sem a nota de desenvolvimento.
- **Resumo do save.**
- **Carimbo do fim:** não cobre o botão.
- **Seleção em papel:** dourada.

Total: **462 testes**.

## Pendências

- **C1, clima de terror no mundo 3D:** o maior impacto da crítica 20 e o próximo passo natural.
- **C5, C6 e C7:** Arsenal com ícones e nomes inteiros, ficha da Base em blocos, quadro fechado por padrão na investigação, briefing procedural e cerimônia de NEX.
- **Bilhete de rituais:** continua só com nome e custo, sem efeito, alcance nem teclas 1–3.
- **Reação do alvo:** a chance de acerto não a considera. Quando o alvo já declarou esquiva, a chance real é menor.
