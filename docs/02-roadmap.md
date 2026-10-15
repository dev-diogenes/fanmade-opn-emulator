# Roadmap

> As fases são sequenciais. Cada uma termina com algo **jogável ou testável**. As issues do GitHub ganham o rótulo da fase (`fase:1`, `fase:2`…).

| Fase | Entrega | Critério de pronto |
|---|---|---|
| **0. Organização** ✅ | Repositório, docs, visão, brainstorm, ADRs | Este documento existe 🙂 |
| **1. Motor de regras** ✅ | `game/scripts/rules/` sem interface: agente, teste em slots, PE, PV/SAN, combate básico, carregados de `data/rulesets/op2022` | 34 testes GUT passando, cobrindo os testes de perícia e um combate 1×1 |
| **1.5 Regras de criação** ✅ | 26 origens, 50 poderes de classe e 15 trilhas em dados; criação validada (`CriacaoAgente`); Ataque Especial, Eclético, Engenhosidade e Perito; custo mínimo acima do limite de PE; reações (bloqueio, esquiva, contra-ataque); dano massivo; Lesões; Inspiração Resoluta | 76 testes GUT passando. Efeitos já aplicados pelo motor: 14/26 poderes de origem, 13/50 poderes de classe, 6/60 habilidades de trilha. O resto está marcado `"implementado": false` com o motivo em `pendente` |
| **1.6 Pendências de regras** ✅ | Idade Variada (6 faixas, 16 desvantagens) e NEX 0%/Mundano com promoção; Versatilidade com trilha alheia; Iniciativa única das ameaças; surpresa; economia de ações (padrão/movimento/completa); condições desprevenido/indefeso; 26 poderes de combate (Duas Armas, Ataque Extra, Duro de Matar, Ataque Furtivo, Inspirar Confiança, Tiro de Cobertura…) | 124 testes GUT passando. Efeitos aplicados: 15/26 origens, 17/50 poderes, 24/60 habilidades de trilha. Distâncias e alcances ainda não são verificados (ficam para a grade da Fase 2) |
| **2. Fatia vertical** | 1 mapa hexagonal, 4 agentes, elemento Sangue, 5 ameaças, 1 chefe, Base da Ordem, Membrana, salvar | 5 playtesters de fora terminam uma missão |
| ↳ 2.1 Grade e arena ✅ | Grade tática (quadrados de 1,5 m, diagonal dobrada, terreno difícil, alcances, flanco, cobertura, ataque de oportunidade), medidor de Membrana e a **Arena de Teste** 2D jogável (cena principal) | 126 testes GUT; combate completo em autoplay com 3 seeds |
| ↳ 2.2 Mapa hexagonal | Mapa-múndi em hexágonos (coordenadas axiais), turnos no mapa, encontros e eventos, Membrana por turno | — |
| ↳ 2.3 Base da Ordem e save | Hub entre missões, requisição de itens pela Patente, roster persistente, salvar/carregar em JSON | — |
| ↳ 2.4 Apresentação 3D | Tabuleiro e mapa em 3D low poly (Blender → .glb), câmera estilo FTK | — |
| **3. Investigação** | Cena com zoom, hotspots, urgência, ficha do grupo, relatório e PP | Uma missão com investigação e combate final |
| **4. Procedural** | Gerador de missões com seed, os 4 elementos, rituais, itens amaldiçoados | 10 seeds seguidas jogáveis sem travar |
| **5. Co-op local** | Até 4 jogadores no mesmo PC, com controle ou teclado | Sessão de 4 pessoas sem bugs bloqueadores |
| **6. Conteúdo da comunidade** | Formato `mission.json` v1 e editor mínimo | Alguém de fora cria e joga uma missão |
| **7. Campanha** | Campanha original (3 a 5 missões) | Campanha completa jogável |
| **8. Online e Modo Mestre** | Rede (ENet ou Steam), papel de mestre | Uma sessão online com mestre |
| **9. Lançamento** | Página itch.io/Steam (veja o documento legal) e Workshop | Build pública |
| **V2** | Ruleset `op-v2` com foco em investigação | Assim que as regras novas estiverem disponíveis |
