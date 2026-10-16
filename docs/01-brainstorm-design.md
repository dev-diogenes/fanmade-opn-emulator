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

**Implementado na Fase 3 ✅:**
- **Caso por missão:** a estrutura Sujeito + Ação + Local do Gerador de Missões, com tabelas próprias. A ficha tem 3 perguntas (quem, o quê, onde), e cada uma precisa de 2 pistas.
- **Cada resposta muda o jogo:** *onde* revela o covil; *quem* tira 20% dos PV do chefe e dá a ele o nome do vilão; *o quê* dá +10 à Membrana.
- **Penalidade ao estourar a urgência** (sorteada): Membrana −10, chefe com +20% de PV, ou um encontro surge no hex.
- **Tempo:** cada rodada de investigação custa 2 de Membrana.
- **Ajuda (p.86):** DT 10, +1 e mais +1 a cada 10 acima. Teimoso não ajuda nem é ajudado; Espírito Cívico soma +2 por 1 PE.
- **Poderes com efeito:** Faro para Pistas, Incansável, Presteza Atlética, Na Trilha Certa, Pensamento Ágil, Guiado pelo Paranormal, Intuição Paranormal, Conhecimento Aplicado e Distraído (perde o 1º turno).

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

## 11b. Viagem no mapa ✅ (implementado na Fase 2.2)

- **Movimento em slots:** no turno de cada agente, 1 d20 por ponto de AGI (mínimo 1), +1 por PE de Foco. Cada slot com 11+ vale 1 ponto de movimento, mais 1 de base. Terreno: campo, estrada, cidade e ruína custam 1; mata, pântano e morro custam 2; água bloqueia.
- **Conteúdo para o movimento:** ao entrar num hex com evento, encontro, vila ou covil, o agente para ali.
- **Aliados entram no combate** se estiverem até 1 hex do encontro, como no FTK.
- **Turno do mundo:** depois de todos os agentes, a Membrana perde 1. A cada 3 turnos, se a Membrana estiver Instável ou pior, surge um encontro perto de um agente, com nível até o da Membrana.
- **Derrota:** perder um encontro encerra a missão nesta fatia vertical. Os Reforços da Ordem (§6) entram com a Base (Fase 2.3).
- **Vitória com aliados caídos:** quem ficou com 0 PV é socorrido com 1 PV (simplificação até existir a regra de Medicina/primeiros socorros fora do combate).
- Números em `game/data/jogo/mapa.json`; eventos em `eventos.json`; encontros em `encontros.json`; fichas de ameaças (criadas por nós) em `ameacas.json`.

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
| Distância e alcance | Verificados só quando o combate tem uma grade. Distância = quadrados ortogonais + 2 por diagonal; adjacência = 8 vizinhos |
| Tiro além do alcance | Até o dobro do alcance: −1 dado (p.66). A p.85 fala em −5; ficamos com a regra do capítulo de equipamento |
| Cobertura | Linha entre os centros dos quadrados (o livro usa os cantos) |
| Flanquear | O aliado precisa estar exatamente no quadrado oposto ao atacante |
| PP por missão | O grupo é avaliado junto (p.61): cada agente que volta recebe o total da tabela 3.2. "Pista adicional" = evento resolvido com sucesso |
| NEX por missão | +5% só para quem volta de uma missão cumprida (p.33: "missão concluída com sucesso") |
| Recuperação | Na Base, entre missões, todos recuperam PV, PE e SAN e as condições acabam |
| Dano de rituais com dois tipos (Descarnar) | Tratado como um tipo só (o elemento do ritual) |
| Rituais em armas (Amaldiçoar Arma, Arma Atroz) | Ficam no ser que empunha a arma; os dados extras não multiplicam no crítico |
| Coincidência Forçada | O +2 em testes de perícia também vale para testes de ataque (Luta/Pontaria são perícias) |
| Concentração | Só é testada por causa de proteção (leve/pesada); ser ferido durante a execução fica para rituais com execução maior que padrão |
| Transcender | O agente não ganha a SAN do NEX em que pegou o poder (perde a SAN de classe por NEX, por Transcender) |
| Afinidade e poder repetido | A 2ª escolha só vale para poderes que têm efeito de afinidade, e do elemento da afinidade (ou de elemento à escolha) |
| Itens amaldiçoados | A 1ª maldição soma +2 de categoria e cada extra +1. O preço: falhar num teste do atributo do elemento custa 2 SAN (Conhecimento→INT, Energia→AGI, Morte→PRE, Sangue→FOR/VIG) |
| Bônus de itens amaldiçoados | Efeitos iguais não se somam; vale o maior |
| Áreas na grade | Raio em quadrados de 1,5 m com a distância da grade (diagonal conta 2), então esferas viram losangos. Nuvem, círculo e esfera usam a mesma forma no chão. Uma rolagem de dano vale para todos na área; cada alvo resiste em separado |
| "Alvos escolhidos" na arena | O jogador clica um alvo e o ritual pega os seres do mesmo lado em alcance, do mais perto ao mais longe, até o limite da forma |
| Explosões | Centradas no conjurador, que não é atingido. Aliados na área são atingidos, exceto quando a forma diz "só alvos à sua escolha" |
| Arma Atroz verdadeira | "+2 na margem de ameaça e no multiplicador de crítico" lido ao pé da letra: +2 em cada |
| Tentáculos de Lodo | Manobra agarrar com Ocultismo contra o melhor entre Atletismo e Acrobacia do alvo. Soltar-se: ação padrão, Atletismo ou Acrobacia contra a DT do ritual |
| Purgatório | "Vulneráveis a dano físico" = dano em dobro (vulnerabilidade, p.190), não a condição vulnerável. Quem sai sofre 6d6 e, se falhar em Fortitude, perde o movimento |
| Decadência e Hemofagia discentes | O dano do ritual soma ao da arma e usa o tipo de dano da arma; não multiplica no crítico |
| Presença Perturbadora | Testada no início de cada combate, não só na primeira vez que o agente vê a criatura |
| Enigma de Medo | No jogo, decifrar é uma ação padrão (Ocultismo, Intuição ou Investigação). Cada pista da missão reduz a DT em 2, até −10 |
| Ameaças do livro | Os números vêm das fichas do cap. 7; as descrições são nossas. Ataques usam o "Teste" da ficha, que já inclui tudo; "x2" são dois ataques na mesma ação Agredir |
| Orçamento de VD | Soma do VD ≤ soma do NEX de quem entra no combate (p.187, dificuldade 1 = equilibrado). As ameaças entram da mais forte para a mais fraca; se nenhuma cabe, vem só a mais fraca. O covil ignora o orçamento |
| Imortalidade | A poça não impede a vitória: o combate acaba se todas as outras ameaças caírem. Na poça, só fogo e Energia contam (o enraizado precisa de 20 somados) |
| Agarrões de ameaças | Teste da ficha contra o melhor entre Atletismo e Acrobacia do alvo (oposto). Soltar-se é o mesmo teste, como ação padrão. Abocanhar (aberração) acontece sozinho no início do turno dela |
| Succ | Ao soltar a vítima antes do próximo turno do succ, ela acorda. Se não, vai a 0 PV e o succ a solta |
| Implantar Confusão | O agarrão vira só um teste oposto: o perturbado não mantém a vítima agarrada |
| Aceleração | Vale no turno seguinte ao golpe: gastar ação de movimento e padrão (ou completa) causa o dano uma vez |
| Habilidades com "capazes de vê-lo" ou "em alcance médio" | Explosão centrada na ameaça com o raio do alcance (médio = 18 m); só atinge inimigos dela |
| Cultistas | Conjuram só a forma básica dos rituais da ficha, sem PE, com a DT da ficha. Escolhemos Decadência e Definhar (iniciado) e Decadência, Definhar, Hemofagia e Descarnar (investido) |
| Enxames | Na grade, o enxame não entra no espaço do alvo: fere quem está adjacente no fim do turno dele. Metade do dano de armas, +50% de áreas |
| Faixas da Permanência | A múmia a 0 PV continua agindo; se ao fim do turno seguinte ainda tiver 0 PV, morre. Drenar com a Agarrada Mumificadora conta como recuperar |
| Invisibilidade permanente (Viajante) | Quem o ataca tem 50% de chance de errar (camuflagem total); quem ele ataca fica desprevenido (−5 na Defesa) |
| Surgimentos | Com a Membrana fraca, só surgem encontros cuja ameaça mais fraca tenha VD de até o dobro do NEX somado do grupo |
| Sangrando | Teste de Vigor (dados de Vigor, sem bônus) DT 20 no início do turno: passou, para; falhou, perde 1d6 PV |
| Ordens (comandante) | Uma vez por cena; +1 dado em testes (inclusive ataques) e um dado de dano a mais para os aliados em alcance médio |
| Enigmas sem número no livro | Espreitador: Enganação ou Furtividade DT 25 para fingir dormir, Atletismo ou Reflexos DT 20 para fechar a fresta. Mulher Afogada: Tecnologia ou Atletismo DT 20, Tecnologia ou Crime DT 20, Atletismo ou Reflexos DT 15. Viajante: fotografar com Percepção ou Tecnologia DT 25. Cada passo é uma ação padrão, na ordem |
| Mulher Afogada na forma de Sangue | "Se recupera dos ferimentos" vira cura acelerada 20 enquanto o enigma não é resolvido. Asfixiado: Fortitude DT 24 no início do turno; falhando, perde 1d6 PV |
| Escutado | As rodadas contam no início do turno do original: se a melodia tocou desde o turno anterior, conta mais uma e surge uma cópia; se não tocou, zera |
| Hipnose | O hipnotizado muda de lado e é jogado pela IA. Se todos os agentes ficarem hipnotizados, o combate é perdido; no fim do combate, todos voltam ao normal |
| Ocioso | Escolhe como alvo o primeiro agente do combate (outro, se ele cair). A Retaliação vale uma vez por ataque e o dano não é não letal ainda |
| Enpap-X | No mapa aparece como "Prisioneiro Marcado" (um existido); a transformação acontece a 0 PV, com todos os PV da nova ficha |
| Granadas | DT Agi = DT de habilidade com Agilidade (10 + limite de PE + Agilidade). Em chamas: 1d6 de fogo no início do turno; ação padrão para apagar |
| Confuso | No início do turno, rola 1d6: com 6 a condição termina e o ser age; senão, perde o turno (simplificação do "comporta-se de modo aleatório") |
| Dama de Sangue | Só desabrocha flores consumindo cadáveres do combate (ação padrão, adjacente). Itens das fraquezas são do jogo e precisam ser usados ao lado dela. "Caído" do Arremessar ainda não existe no motor |
| Minotauro e Kerberos | Cravar Chifres vale em qualquer acerto dos chifres (o jogo ainda não tem investida). Derrubar e Devorar alcança só quem está adjacente |
| Covil | Escolhido pela soma do NEX de quem entra: 0 = Covil Carmesim, 90 = Jardim das Sete Flores, 180 = Labirinto, 280 = Portão do Inferno |
| Enigmas que o livro deixa em aberto | Aniquilação: ritual de contenção em três testes (Ocultismo DT 35-40). Anjo: estudar e enganar o julgamento (DT 35 e 40). O Diabo: 200 de dano de Morte acumulados (o dano conta mesmo sem ferir). O Deus da Morte: 200 de dano de Sangue acumulados. Nidere e EstrangEiro: etapas com DT 25-35 |
| Senhor do Tempo | O turno adicional vira uma ação padrão e uma de movimento a mais no turno do Deus da Morte |
| Silhueta | Qualquer ataque corpo a corpo contra ela é um toque: o atacante sofre a aura uma vez por turno, acerte ou não |
| Marionete | Reflexos Guiados ao terminar um movimento ao lado dela. Ironia do Destino divide pela metade o dano que ela sofre enquanto agarra |
| Desejos de Sangue e Comandar | Viram uma "fúria" de um turno: o agente muda de lado e é jogado pela IA até o fim do próprio turno |
| Covil e orçamento | O chefe sempre está no covil; a escolta entra só no que sobra de 1,5 × o NEX somado (o "difícil" do livro). O Horror Carmesim, chefe do grupo inicial, é uma criatura nossa calibrada para VD 25 |
| Sustentado com vários alvos | Custa 1 PE por turno pelo ritual inteiro, não por alvo; conjurar outro ritual sustentado encerra o anterior |
| Reforços da Ordem (modo Normal) | 2 por missão. Um agente caído num combate perdido (ou morto) é resgatado: sai da missão com uma lesão (1d6 no atributo, como a regra de Lesões) |
| Campanha e derrota | Perder uma missão da campanha não encerra a campanha: a mesma missão espera outra tentativa. As mortes e os PP seguem as regras de sempre |
| Marcas da campanha | Uma pergunta do caso respondida numa missão vencida vira marca. As missões seguintes leem as marcas e aplicam um efeito que a investigação já tinha: Membrana, chefe enfraquecido ou covil revelado |
| Recrutas da campanha | Personagens da história entram no roster como recrutas de NEX 5%, iguais aos outros; quem morre vai para o memorial e não volta |

## 14. Ferramentas: Godot e o Tabletop Simulator ✅

O Tabletop Simulator é feito em Unity, mas isso **não nos obriga a usar Unity**. Decisão completa no [ADR 0001](adr/0001-engine-godot.md).

## Questões em aberto

As questões da v0.1 foram fechadas. Restam detalhes para o playtest:

1. ❓ Número de **Reforços da Ordem** por missão no modo Normal (proposta: 2).
2. ❓ Se o PE extra quebrar as DTs, limitar a +2 slots por teste?
3. ❓ Quantas rodadas de investigação equivalem a 1 turno do mapa?
4. ❓ Regras da **Desconjuração**, para depois da fatia vertical.
5. ❓ O que muda na V2. Fica pendente até termos as regras novas.
