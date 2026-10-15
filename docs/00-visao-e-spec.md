# Visão e Especificação (PRD)

> Status: **rascunho v0.2**, 14/10/2026. As decisões de design do brainstorm foram fechadas. Documento vivo: decisões fechadas ficam aqui, discussões abertas ficam em [01-brainstorm-design.md](01-brainstorm-design.md).

## 1. Resumo

Um RPG eletrônico **fanmade e gratuito** ambientado no universo de *Ordem Paranormal*, com o loop de jogo de *For The King* / *For The King II*: um grupo de agentes atravessa um mapa hexagonal 3D low poly, enfrenta encontros e combates por turnos, e as rolagens aparecem como "slots" de d20.

É **um jogo com um motor só** e vários **rulesets**:

| Versão | Ruleset | Foco | Status |
|---|---|---|---|
| **I** | `op2022`: livro básico de 2022 (v1.3) | Combate, com investigação simplificada | Primeiro alvo |
| **II** | `op-v2`: regras novas (a definir) | Investigação | Depois da V1. Algumas regras podem mudar |

## 2. Problema e oportunidade

- Fãs de Ordem Paranormal não têm uma forma digital de **jogar o sistema sozinhos ou em grupo sem mestre** e sem preparar a sessão.
- Mestres não têm uma ferramenta que **automatize as regras** e deixe a narração com eles.
- O loop de For The King (exploração curta, risco visível nas rolagens, co-op) combina com o tom de missão da Ordem: briefing, investigação, confronto, relatório.

## 3. Modos de jogo

1. **Sandbox procedural (estilo FTK).** O jogador escolhe os agentes que quiser e joga missões aleatórias, geradas a partir da estrutura do *Gerador de Missões* do livro: Sujeito, Ação, Local, Amigo, Objeto, Evento.
2. **Campanha fixa.** História **original**, sem relação com a trama das campanhas transmitidas.
3. **Missões da comunidade.** Missões criadas por jogadores num formato de dados aberto, jogáveis:
   - **sem mestre**, com a IA do jogo arbitrando;
   - **com mestre**: um jogador humano controla revelações, NPCs, DTs e aparições. *(Fase posterior: exige rede.)*

## 4. Público

| Persona | O que quer |
|---|---|
| **Fã de OP que não mestra** | Viver uma missão da Ordem e criar os próprios agentes |
| **Jogador de FTK** | Co-op com a tensão de "vai dar o 20?" e progressão entre runs |
| **Mestre de OP** | Rodar missões com as regras automatizadas e criar e compartilhar missões |
| **Criador da comunidade** | Um editor e um formato simples para publicar missões |

## 5. Objetivos

1. Ser **fiel às regras** de OP. Toda regra implementada aponta para a página do livro (`ref`).
2. Ser **legível**: o jogador entende cada rolagem (slots de d20, bônus de perícia, DT).
3. Uma **missão completa em 30 a 60 minutos** no modo sandbox.
4. **Co-op local** com até 4 agentes desde a fatia vertical.
5. **Conteúdo como dados**: regras, itens, ameaças e missões em arquivos que a comunidade consegue editar sem programar.

## 6. Fora do escopo (por enquanto)

- Monetização de qualquer tipo.
- Online e modo mestre em rede antes da fatia vertical estar divertida.
- Celular. Fica para depois, se fizer sentido.
- Localização completa. Só PT-BR; outros idiomas, quando existirem, aparecem marcados como **WIP**.
- Usar a arte, os textos, os personagens ou a trama oficiais das campanhas. Veja [03-legal-e-conteudo.md](03-legal-e-conteudo.md).

## 7. Requisitos

### P0: fatia vertical (V1)
- Criação de agente: atributos (AGI, FOR, INT, PRE, VIG), origem, classe (Combatente, Especialista, Ocultista), NEX 5%.
- **Teste de OP como slots**: cada ponto no atributo-base vira 1 slot de d20, vale o maior resultado e a perícia treinada soma bônus. Com atributo 0, rola 2d20 e vale o menor.
- **PE como Foco**: cada PE adiciona +1 d20 ao teste, dentro do limite de PE por turno do NEX.
- Mapa hexagonal 3D low poly, com 1 mapa e 1 elemento (Sangue).
- Combate em grade, como no FTK II, com 4 agentes, 5 tipos de ameaça e 1 chefe.
- PV, PE, SAN, condições básicas, morrendo e enlouquecendo.
- Medidor de **Membrana** no lugar do medidor de Caos do FTK.
- Base da Ordem como hub entre missões. Recompensas: NEX e **Patente completa** (5 patentes, itens por categoria, crédito, PP e rebaixamento).
- **Roster persistente** de agentes, como uma carreira na Ordem.
- **Opções da run**: modo de morte (Normal, com Reforços da Ordem, ou Hardcore) e regras opcionais (Lesões, Inspiração Resoluta, Idade Variada).
- Co-op local com até 4 jogadores.
- Salvar e carregar.

### P1
- **Cena de investigação** com zoom aproximado e visão reduzida (seção 3 do brainstorm).
- Gerador procedural de missões.
- Os 4 elementos, rituais como habilidades e itens amaldiçoados. Medo aparece só como ameaça e evento.
- Modo **"Pessoas Comuns"** (NEX 0% / Mundano) e prólogo/tutorial.
- Aposentadoria (o agente vira aliado ou mentor). A Desconjuração entra como evento raro mais tarde.
- Formato de missão versionado e um editor mínimo dentro do jogo.

### P2
- Campanha fixa.
- Online co-op.
- Modo Mestre.
- Steam Workshop para missões da comunidade.
- Ruleset V2.

## 8. Métricas de sucesso (projeto de fã)

- Fatia vertical: 5 jogadores de fora do time terminam uma missão sem ajuda e **querem jogar outra**.
- Clareza das regras: ≥ 80% dos playtesters explicam, depois de jogar, por que um teste passou ou falhou.
- Pelo menos 3 missões da comunidade publicadas até 3 meses depois do editor sair.

## 9. Questões em aberto

Estão consolidadas em [01-brainstorm-design.md](01-brainstorm-design.md#questões-em-aberto).
