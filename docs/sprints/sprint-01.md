# Sprint 01: build de playtest

**Datas:** 02/11/2026 a 08/11/2026 (1 semana) | **Time:** o dono do projeto e o Claude
**Objetivo da sprint:** ter uma build de Windows que uma pessoa de fora consiga instalar, jogar uma missão e devolver um relatório, com o roteiro de playtest pronto.

> Por que este objetivo: o jogo tem 834 testes automáticos e 77 docs, mas nenhum critério "com pessoas" das Fases 2, 5, 6 e 8 foi cumprido. Todo o equilíbrio vem do piloto automático. Sem build não há playtest, e sem playtest cada sistema novo aumenta o risco do teto de complexidade (veja o relatório em `reports/`).

## Andamento

| Data | Item | Situação |
|---|---|---|
| 02/11 | docs/77 sigilos e cifra | ✅ commit f486d15 (834 testes, 9 corridas online iguais) |
| 02/11 | docs/78 roteiro de playtest | ✅ |
| 02/11 | Relatório do testador (Pausa → Playtest) | ✅ 3 testes |
| 02/11 | `tools/exportar.sh` (cria o preset, exporta, teste de fumaça) | ✅ pronto, **bloqueado**: faltam os modelos em `%APPDATA%\Godot\export_templates.6.1.stable.mono\` |
| — | Captura do sigilo no chão da arena e do muro 3D | pendente |
| — | Crítica de primeiro contato (design e acessibilidade) | pendente |

## Capacidade

| Quem | Disponibilidade | Alocação | Notas |
|---|---|---|---|
| Claude | sessões sob demanda | ~20 pontos | Código, testes, docs, capturas e builds. Não publica nem baixa nada sem o "sim" do dono |
| Dono do projeto | estimativa de 4 a 6 h na semana | ~6 pontos | Decisões, baixar os templates de exportação, recrutar testadores, subir no itch.io |
| **Total** | | **~26 pontos** | Planejado a 75% (buffer para correções) |

Escala de pontos: 1 é menos de 1 h; 3 é meio dia; 5 é um dia.

## Backlog da sprint

| Prioridade | Item | Estimativa | Dono | Dependências |
|---|---|---|---|---|
| P0 | Fechar o docs/77 (sigilos e cifra): suíte completa, captura do sigilo no chão da arena e do muro 3D, commit | 1 | Claude | Suíte rodando |
| P0 | **Instalar os templates de exportação do Godot 4.6.1 (mono)**, cerca de 1 GB, pelo editor (Editor → Gerenciar Templates) ou pelo site oficial | 1 | Dono | — (**bloqueia a build**) |
| P0 | `export_presets.cfg` (Windows Desktop, PCK embutido, nome Membrana) e `tools/exportar.sh`. O arquivo de presets continua no `.gitignore`, e o script recria o preset padrão | 3 | Claude | Templates |
| P0 | Relatório do testador: um botão em Ajustes que junta `preferencias.json`, o resumo da carreira e o registro da última missão num `.txt` em `user://`, e abre a pasta. Sem rede (LI4) | 3 | Claude | — |
| P0 | `docs/78-playtest-externo.md`: roteiro (solo, co-op com 2 pessoas, online com mestre, editor), tarefas, ficha de observação e critérios, juntando o docs/07 | 2 | Claude | — |
| P0 | Teste de fumaça da build: o `.exe` abre, chega ao título e fecha (`--quit-after`) numa pasta sem o projeto | 1 | Claude | Build |
| P1 | Checagem de licença na build: título "Membrana", selo ≥10% na capa, aviso de IA e de conteúdo, tela Sobre | 1 | Claude | Build |
| P1 | Rodada de `design:design-critique` e `design:accessibility-review` no primeiro contato (título, convite do tutorial, Base, briefing), consertando só o que bloqueia | 3 | Claude | — |
| P1 | Recrutar de 3 a 5 testadores e marcar 1 sessão de co-op e 1 online com mestre | 2 | Dono | docs/78 |
| P1 | Subir no itch.io como **rascunho privado ou com senha** | 1 | Dono | Build e checagem de licença |
| P2 (extra) | AU6: frase-tema e premissa na abertura da missão ("lugar banal + evento estranho + quem chamou a Ordem") | 2 | Claude | — |
| P2 (extra) | IN6: selo de "vasculhado" no local sem mais pistas | 1 | Claude | — |

**Carga planejada:** P0 + P1 = 18 pontos de Claude e 4 do dono, cerca de 85% da capacidade com o buffer de 75% contado. O P2 entra só se sobrar tempo.

## Fora desta sprint (de propósito)

- Os sistemas novos do relatório (AG3 laços, CO3 quadro online, ME4 Membrana local…): esperam os playtests.
- O polimento 2.5 (modelos do Blender): depende do que os testadores apontarem.
- Inglês e espanhol (AU8).

## Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Os templates de exportação não estão instalados (`%APPDATA%\Godot\export_templates` vazio) | Sem build, a sprint para | O primeiro passo da semana é do dono. Claude prepara o resto em paralelo |
| A versão mono exige o SDK do .NET para exportar | A exportação falha | Testar logo. Se falhar, usar o Godot 4.6.1 padrão (não mono) só para exportar: o projeto é todo em GDScript |
| Testadores reais não aparecem | O critério de pronto não fecha | Começar com 1 ou 2 conhecidos, numa sessão gravada, e anotar pela ficha do docs/78 |
| Vontade de adicionar sistema novo no meio | O foco da sprint se perde | Congelar sistemas: só correções e o que o playtest pedir |
| Aviso de IA e postura oficial sobre IA | Risco de imagem na publicação | Build só privada nesta sprint; publicação pública decidida depois |

## Definição de pronto

- [ ] Suíte GUT sem falhas e testes online com o mesmo hash
- [ ] Build abre num PC limpo
- [ ] Relatório do testador gerado e legível
- [ ] docs/78 e roadmap atualizados
- [ ] `git grep` sem marca d'água; push só com o "pode fazer o push"

## Datas

| Data | Evento |
|---|---|
| 02/11 | Início: templates de exportação e fechamento do docs/77 |
| 04/11 | Meio da sprint: build de fumaça pronta |
| 07/11 | Primeira sessão de playtest com uma pessoa |
| 08/11 | Fim: retro e planejamento da Sprint 02 (feedback → balanceamento) |

## Rota depois desta sprint

| Sprint | Objetivo |
|---|---|
| 02 | Corrigir e equilibrar a partir dos relatórios: tutorial, ritmo da missão, dificuldade do caso |
| 03 | Os P2 baratos do relatório (ME8 sinais de sanidade, AU3 cor só no paranormal), mais o polimento 2.5 dos marcos de OP |
| 04 | Lançamento 9: página no itch.io, build pública, missões da comunidade |
