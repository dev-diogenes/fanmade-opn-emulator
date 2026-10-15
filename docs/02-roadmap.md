# Roadmap

> As fases são sequenciais. Cada uma termina com algo **jogável ou testável**. As issues do GitHub ganham o rótulo da fase (`fase:1`, `fase:2`…).

| Fase | Entrega | Critério de pronto |
|---|---|---|
| **0. Organização** ✅ | Repositório, docs, visão, brainstorm, ADRs | Este documento existe 🙂 |
| **1. Motor de regras** ✅ | `game/scripts/rules/` sem interface: agente, teste em slots, PE, PV/SAN, combate básico, carregados de `data/rulesets/op2022` | 34 testes GUT passando, cobrindo os testes de perícia e um combate 1×1 |
| **1.5 Regras de criação** | Origens, poderes de classe e trilhas em dados; Ataque Especial, Eclético e Perito; reações (bloqueio, esquiva, contra-ataque); dano massivo; Lesões; Inspiração Resoluta | Agente criado do zero com todas as escolhas do livro |
| **2. Fatia vertical** | 1 mapa hexagonal, 4 agentes, elemento Sangue, 5 ameaças, 1 chefe, Base da Ordem, Membrana, salvar | 5 playtesters de fora terminam uma missão |
| **3. Investigação** | Cena com zoom, hotspots, urgência, ficha do grupo, relatório e PP | Uma missão com investigação e combate final |
| **4. Procedural** | Gerador de missões com seed, os 4 elementos, rituais, itens amaldiçoados | 10 seeds seguidas jogáveis sem travar |
| **5. Co-op local** | Até 4 jogadores no mesmo PC, com controle ou teclado | Sessão de 4 pessoas sem bugs bloqueadores |
| **6. Conteúdo da comunidade** | Formato `mission.json` v1 e editor mínimo | Alguém de fora cria e joga uma missão |
| **7. Campanha** | Campanha original (3 a 5 missões) | Campanha completa jogável |
| **8. Online e Modo Mestre** | Rede (ENet ou Steam), papel de mestre | Uma sessão online com mestre |
| **9. Lançamento** | Página itch.io/Steam (veja o documento legal) e Workshop | Build pública |
| **V2** | Ruleset `op-v2` com foco em investigação | Assim que as regras novas estiverem disponíveis |
