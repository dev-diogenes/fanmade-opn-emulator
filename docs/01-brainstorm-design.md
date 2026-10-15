# Brainstorm de Design: Ordem Paranormal × For The King

> Cada tópico tem uma **decisão** (✅), uma **proposta** (💡, aguardando aprovação) ou uma **dúvida** (❓).
> As páginas citadas são do livro básico de 2022 (v1.3).
> **Última revisão:** 14/10/2026. As propostas e dúvidas da v0.1 foram fechadas.

## 1. Teste = slots de d20 ✅

No OP (p.19), você rola 1d20 por ponto no atributo-base, vale o maior resultado e soma o bônus da perícia treinada. Esse número é comparado à DT.

**Tradução para FTK:** cada ponto de atributo vira **um slot**, e cada slot mostra um d20 rolando. A UI mostra lado a lado:

```
[d20][d20][d20]  ← AGI 3
maior: 14  +5 (Furtividade treinada)  = 19   vs  DT 20  ✗
```

- Com **atributo 0**, aparecem 2 slots vermelhos e vale o **menor**.
- **Por que não porcentagem?** O fã de OP já pensa em d20 e DT. Antes de rolar, a UI pode mostrar a "chance de passar" calculada como dica.

## 2. PE = Foco: +1 d20 por PE ✅

- Antes de rolar, o jogador pode gastar PE: **cada PE adiciona 1 slot de d20** ao teste.
- O gasto respeita o **limite de PE por turno** do NEX (p.33), somado ao PE gasto em habilidades no mesmo turno.
- A tensão de cada turno fica entre "forçar este teste" e "guardar para a habilidade".
- **Atributo 0 ✅ (implementado):** a reserva é `atributo + dados extras`. Com reserva 0 ou menos, rolam-se `2 − reserva` d20 e vale o pior. Então, com atributo 0, **1 PE de Foco leva a 1d20 normal**: o Foco tira o agente da penalidade. Penalidades que deixam a reserva negativa somam dados ao "pior". Essa extensão é interpretação nossa: as Clarificações (p.322–323) não tratam do assunto, então ela fica valendo.
- 🔧 **Balanceamento a observar:** quem tem atributo alto e muito PE pode quebrar as DTs. Se acontecer, o plano B é limitar o bônus a 2 slots extras por teste.

## 3. Investigação: zoom aproximado com a visão reduzida ✅

O livro já traz uma estrutura de investigação completa (p.89–91), que encaixa muito bem num jogo:

| Conceito do livro | No jogo |
|---|---|
| **Ficha de Investigação** do grupo: resumo, objetivo, perguntas | Diário compartilhado na UI, com as perguntas do caso |
| **Pista básica** no início de cada cena | Revelada automaticamente quando a cena começa |
| **Pistas complementares** | *Hotspots* no cenário |
| Ações: Procurar Pistas, Facilitar, Usar Habilidade/Item, Ajudar | Menu de ação por agente em cada rodada |
| DT 15 / 20 / 25+ conforme a abordagem | Cada hotspot aceita perícias diferentes, com DTs diferentes |
| **Urgência** (Muito baixo 6 → Muito alto 2 rodadas) | Contador de rodadas na tela. A cada 3 falhas, perde 1 rodada |
| Penalidade ao estourar a urgência | O chefe ganha PV, chegam reforços, o grupo não descansa |
| Conclusão do Caso → Prestígio | Tela de relatório. As respostas certas rendem PP |

**Câmera:** no mapa, a visão é aberta e isométrica. Ao entrar num hex de investigação, a câmera aproxima e o raio de visão encolhe (escuridão, lanterna, névoa). Os hotspots só aparecem dentro do campo de visão. Facilitar Investigação **aumenta o raio**, por exemplo acendendo a luz ou abrindo janelas.

**Tempo ✅:** cada rodada gasta na cena **avança o relógio da missão** no mapa e **enfraquece a Membrana**. Investigar a fundo rende mais pistas e mais PP, mas custa tempo. Sair cedo poupa a Membrana, mas o relatório sai incompleto.

A **V1 também tem investigação**, numa versão simplificada. A V2 aprofunda o sistema (interrogatórios, quadro de conexões, falsas pistas).

## 4. Progressão: NEX ≠ nível ✅

| Eixo | O que representa | Fonte | Como sobe | Efeito no jogo |
|---|---|---|---|---|
| **NEX** | Poder individual e exposição ao Outro Lado | p.33 | +5% por missão concluída | PV, PE e SAN; habilidades de classe; limite de PE |
| **Patente**, via **Pontos de Prestígio (PP)** | Posição na Ordem: a recompensa dada pela Ordem | p.61 | PP por missão, conforme a eficiência. **Pode cair** | Itens liberados por categoria e limite de crédito |

- **A Patente é implementada completa** ✅: as 5 patentes, os itens por categoria, o limite de crédito, a tabela de PP por missão e o **rebaixamento**, com devolução de itens.
- A Patente **substitui ouro e loja** do FTK. Na Base da Ordem, antes da missão, o grupo requisita equipamento dentro do limite da patente.
- Os recrutas abrem o jogo e servem de tutorial.

## 5. Carreira: roster persistente ✅

- **Os agentes persistem entre missões**, como uma carreira na Ordem. NEX, Patente, lesões e traumas acompanham o agente.
- O jogador mantém um **roster de agentes** e monta o grupo de até 4 a cada missão.
- **Aposentadoria ✅:** o agente pode se aposentar e vira **aliado ou mentor** no roster, usando as regras de Aliados (Acólito, Faz-Tudo, Guerrilheiro, Socorrista) e o texto de Aposentadoria (p.318). Um aliado é uma carta de bônus para o grupo, não um personagem com turno próprio.
- **Desconjuração ✅:** um **evento raro e perigoso** para agentes em NEX 99%. É o único caminho para 100%, com consequências imprevisíveis e sem final feliz garantido. Os detalhes ficam para depois da fatia vertical.

## 6. Morte: escolha na criação da run ✅

Na criação da run, o jogador escolhe o modo:

| Modo | Regra |
|---|---|
| **Normal** | O grupo tem um contador de **Reforços da Ordem** por missão. Quando um agente morre, gasta-se 1 reforço: o agente é resgatado para a Base com uma penalidade (lesão ou perda de SAN). Sem reforços, a morte é permanente. |
| **Hardcore** | A morte é sempre permanente, o que é fiel ao horror de OP. Com o roster persistente, perder um agente veterano dói de verdade. |

❓ O número de Reforços por missão será definido no playtest. Proposta inicial: 2.

## 7. Medidor de Caos → Membrana ✅

O medidor de Caos do FTK vira o **estado da Membrana** na região da missão (cap. 5, p.105).

- Ela enfraquece com o tempo no mapa, com as **rodadas de investigação**, com rituais conjurados, com mortes de civis e com urgências estouradas.
- Ela se fortalece quando o grupo destrói itens amaldiçoados ou fecha portais.
- Em cada limiar, aparecem ameaças mais fortes, eventos do Outro Lado e manifestações de **Medo**.

## 8. Elementos e o Medo ✅

- **Sangue, Morte, Conhecimento e Energia** são jogáveis: rituais, poderes e criaturas. A fatia vertical usa só Sangue.
- **Medo** entra na V1 **só como ameaça e evento**: manifestações quando a Membrana está fraca, eventos de pavor e ataques à Sanidade. Na V1 não há rituais de Medo para os agentes, o que preserva o mistério do lore.

## 9. Grupo e combate ✅

- **Até 4 agentes** e **combate em grade com posicionamento**, como no FTK II.
- Ordem por Iniciativa, ações padrão, de movimento e livre, e reações, conforme o cap. 4 (p.92–99).
- PV 0 leva a *morrendo*. SAN 0 leva a *enlouquecendo* (p.98).
- **Rituais = habilidades**, com custo em PE, elemento, componentes e risco à Sanidade.
- **Munição abstrata**, como na regra padrão. A contagem de munição fica desligada.

## 10. Regras opcionais (cap. 6) ✅

São ligadas ou desligadas nas **opções da run**, como o modo de morte. Ligadas por padrão na V1:

| Regra | Página | No jogo |
|---|---|---|
| **Lesões** | p.184 | Ficar *morrendo* pela 2ª vez na mesma cena pede um teste de Vigor. A perda permanente de atributo segue o agente pela carreira. |
| **Inspiração Resoluta** | p.184 | Quem morre continua jogando: rola 1d10 por rodada e dá o bônus a um aliado. Ótimo para o co-op. |
| **Idade Variada** | p.182–184 | Faixa etária na criação do agente, com bônus e desvantagens ("Peso da Idade"). |
| **NEX 0% / Mundano** | p.181–182 | **Modo "Pessoas Comuns"** e **prólogo/tutorial**: civis sem treinamento encontram o paranormal e, ao chegar a NEX 5%, entram para a Ordem. |

Desligadas na V1: **Contagem de Munição** e **Loucura Não Letal**. Elas podem virar opção mais tarde.

## 11. Missões procedurais 💡

A geração segue a **estrutura do Gerador de Missões** (p.165–167): `Sujeito + Ação + Local + Amigo + Objeto + Evento`.

- **Local** escolhe o bioma ou mapa. Habitado ou abandonado muda os encontros.
- **Sujeito + Ação** definem o chefe e o objetivo.
- **Amigo** é um NPC aliado que pode ser revelado como vilão.
- **Evento** é a reviravolta no meio ou no fim da missão.
- Uma **seed** reproduzível permite compartilhar missões geradas.

Como as **tabelas** do livro são conteúdo do livro, usamos a estrutura e escrevemos **tabelas próprias**.

## 12. Missões da comunidade e Modo Mestre 💡

- **Formato:** um pacote com `mission.json` (metadados, ficha de investigação, cenas, encontros, pistas) e, opcionalmente, assets próprios. O formato é **versionado** (`format_version`) e declara o **ruleset**.
- **Sem mestre**, a IA arbitra: DTs e revelações vêm dos dados da missão.
- **Com mestre**, um jogador tem a "ficha do mestre" com todas as pistas e decide DT, aparições, NPCs e quando liberar cada pista. Esse modo exige rede e fica para a Fase 8.
- **Distribuição:** pasta local primeiro, Steam Workshop depois.

## 13. Interpretações adotadas no motor ✅

Pontos em que o livro é ambíguo e escolhemos uma leitura (revisar se surgir errata):

| Tema | Leitura adotada |
|---|---|
| Penalidades abaixo de 0 dados | `2 − reserva` d20, fica o pior (§2) |
| Criança/adolescente com FOR/VIG 0 | Os atributos zerados por idade **não** rendem o ponto extra da regra geral |
| Pré-requisitos de poderes | Checados no estado final do agente, não no NEX em que o poder foi escolhido |
| Iniciativa das ameaças | Um teste só, com o menor bônus entre elas (p.93) |
| PE fora do turno (reações) | Contam no limite do turno atual do agente e zeram no início do turno dele |
| Golpe Pesado no crítico | O dado extra faz parte do dano da arma e também é multiplicado |
| Distância e alcance | Não verificados até existir a grade (Fase 2) |

## 14. Ferramentas: Godot e o Tabletop Simulator ✅

O Tabletop Simulator é feito em Unity, mas isso **não nos obriga a usar Unity**. Decisão completa no [ADR 0001](adr/0001-engine-godot.md).

## Questões em aberto

As questões da v0.1 foram fechadas. Restam detalhes para o playtest:

1. ❓ Número de **Reforços da Ordem** por missão no modo Normal (proposta: 2).
2. ❓ Se o PE extra quebrar as DTs, limitar a +2 slots por teste?
3. ❓ Quantas rodadas de investigação equivalem a 1 turno do mapa?
4. ❓ Regras da **Desconjuração**, para depois da fatia vertical.
5. ❓ O que muda na V2. Fica pendente até termos as regras novas.
