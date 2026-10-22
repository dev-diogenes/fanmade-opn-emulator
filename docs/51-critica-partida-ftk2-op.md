# Crítica de design: uma partida inteira, com For The King 2 e o livro como régua

> Status: **v0.1**, 22/10/2026. Pedido: rodar o Godot, jogar uma partida própria e apontar o que melhorar no design, tomando For The King 2 e Ordem Paranormal (livro de regras) como referências. A régua é a de um jogo de ponta no nicho de RPG investigativo e terror.

## Como foi a partida

- **Jogada por script, com os comandos dos botões.** O jogo rodou de verdade em 1280 × 720 (Godot 4.6.1). Um script jogou como um jogador: rolar, andar, escolher a opção de evento com mais chance, ir até o ponto da cena, procurar, acusar quando sobrava um suspeito, lutar e voltar à Base. Cada tela foi fotografada.
- **Duas partidas na semente 23, com 3 agentes em NEX 5%:**
  - **A primeira** expôs um travamento: o jogador ficou 16 turnos sem pista à vista (detalhes abaixo).
  - **A segunda** foi até o fim: caso solucionado no turno 5 do mundo, com 10 pistas. O chefe caiu na rodada 3, sem baixas.
- **Também conta:** o playtest automático de 20 missões de docs/50.
- **O que este método não avalia:** a sensação do mouse e da câmera, o áudio e a leitura de um jogador novo. Isso pede o playtest com pessoas (Fase 2 do roadmap).

### O que veio de fora

- **For The King 2:**
  - A crítica mais repetida no lançamento foi a interface **poluída e confusa**.
  - A atualização de maio de 2025 respondeu com:
    - um **HUD contextual**, que só mostra o que importa no momento;
    - uma **barra de habilidades que recolhe** depois da escolha;
    - **casas do combate mais fáceis de clicar**.
  - Análises também apontam **texto pequeno** e menus que não fecham com Esc.
  - No combate, posição, cobertura, linha da frente e de trás contam.
- **For The King (o primeiro):**
  - **dia e noite**: 10 rodadas de dia e 5 de noite, com inimigos mais fortes à noite;
  - uma **linha do tempo no mapa** que mostra as ameaças chegando (caos, flagelos) antes de acontecerem.
- **Livro (cap. 6, p.161-163):**
  - **Suspense** é antecipação, feita com elementos que voltam.
  - **Terror** é o mal-estar antes do evento ruim; um jeito de criá-lo é a criatura ferir **indiretamente**, por exemplo matando um NPC querido.
  - **Horror** vem de detalhe, interação e empatia, e usa sentidos além da visão (cheiro, tato).
  - O narrador age como o **operador de câmera**.
  - NPCs têm nome, função, envolvimento, objetivo e um traço de aparência e um de personalidade. Os que voltam são descritos igual, para serem reconhecidos.
- **Sites de Ordem Paranormal:** não achei links seus na conversa nem na sessão anterior, só o livro. Usei o livro e material público do jogo oficial *Enigma do Medo*: pixel art em cenários 3D com luz dinâmica, inspeção de objetos e um "mapa mental" das descobertas. Se você mandar os sites de novo, eu incluo.

## Impressão geral

A **interface já fala Ordem Paranormal**: sigilos, dossiê, moldura de gravação (REC), Membrana rachada, quadro de cortiça com polaroides e fio vermelho, escolha difícil e nota de insanidade. É a parte mais madura.

O que separa o jogo de um título de ponta é a **experiência do caso**:
- o mistério se resolve rápido demais;
- o medo não tem antecipação, porque nada no mapa avisa nem caça;
- os agentes parecem cavaleiros e bruxas de fantasia medieval, não investigadores do Brasil de hoje.

## 1. Primeira impressão (2 segundos)

| Tela | O que chama o olho | Está certo? |
|---|---|---|
| Título | O logo dourado e o sigilo vermelho sobre o mapa | Sim. Mas o mapa de fundo é estático e iluminado como de dia; falta um sinal do Outro Lado (névoa, um vulto, uma luz que pisca). |
| Base | O briefing em papel e o botão Iniciar missão | Em parte. A tela parece um **formulário** (caixas de marcar, listas suspensas), e o grupo é uma lista de nomes **sem rosto**. |
| Mapa | O grupo iluminado no meio de muito preto | Sim. Mas o tabuleiro é pouco povoado, e o realce de movimento pinta os hexes de azul e âmbar fortes. |
| Investigação | A moldura REC, os sigilos dourados e as miniaturas | Sim. Mas **as miniaturas de fantasia** são a primeira coisa que destoa. |
| Combate | A grade cinza e os blocos | **Não.** O covil era um frigorífico, e a arena é uma sala genérica. |

![Base: o grupo é uma lista de nomes](crit51_base.png)

## 2. Usabilidade

| Achado | Gravidade | Recomendação |
|---|---|---|
| **O caso se resolve em 5 turnos.** Uma cena deu pista para todas as perguntas: cada cena tem um ponto firme por pergunta (docs/44). Além disso, **22 a 50% dos traços são únicos**, então uma pista só já pode apontar o culpado. Foi o que aconteceu: "lucro" sozinho resolveu "o quê" ([ficha](crit51_deducao.png)). Medido nos dados: "quem" 10%, "o quê" 27%, "onde" 22%, "mandante" e "origem" 50%, as duas de docs/50. O playtest dá 6,3 turnos de média. | 🔴 | Todo traço deve aparecer em **dois candidatos ou mais**: uma pista nunca basta, e duas diferentes sempre bastam (a regra de docs/32 continua valendo). Cada cena deve focar **duas perguntas**, não três. A pergunta que falta fica para outra cena, um evento ou uma testemunha. |
| **Sem nenhuma pista à vista, o jogo não orienta.** Na primeira partida, sem pista nova, o grupo foi ao covil selado e ficou **16 turnos** em volta dele. O relatório repetiu "chega às ruínas do covil, mas não acha a entrada" duas vezes por agente por turno ([tela](crit51_covil_travado.png)). Um jogador explora a névoa, mas o jogo não diz para onde. | 🔴 | **Rumo do caso:** quando não há pista à vista, o quadro aponta onde procurar ("faltam pistas de ONDE: há uma ocorrência a leste, na névoa"). Na névoa, o lugar com pista ganha um sinal discreto. A mensagem do covil selado sai **uma vez**, não a cada passo. |
| **Modais empilhados.** O tutorial do mapa cobre o arquivo do caso, justo o gancho da missão ([tela](crit51_briefing_tutorial.png)). O tour da Base abre **por cima do relatório da missão** ([tela](crit51_relatorio_tutorial.png)). A faixa da rolagem cobre o quadro do caso que abriu sozinho ([tela](crit51_pista.png)). | 🟡 | **Uma fila de papéis:** um papel por vez, e o tutorial espera o briefing e o relatório fecharem. É a lição de FTK2: só o que importa naquele momento. |
| **"Pistas N" no HUD conta testes vencidos em eventos**, não pistas do caso. Com o caso vazio, o HUD já dizia "Pistas 1" ([tela](crit51_evento.png)). | 🟡 | Contar só pistas registradas no caso, ou trocar o nome do contador. |
| **"Manobra" cortada** na linha de cima do combate, em 1280 px ([tela](crit51_combate.png)). | 🟡 | Quebrar a linha ou recolher as opções num menu. |
| **Pontos da investigação embaixo do HUD**: há sigilos sob os retratos e sob as cartas ([tela](crit51_investigacao.png)). | 🟡 | Uma margem segura na hora de posicionar os pontos, ou a câmera abrindo o enquadramento. |
| **A ordem de iniciativa só aparece no relatório** ("Ordem: Mauro (19), Rita (16)…"). | 🟡 | Uma faixa de retratos no alto, na ordem dos turnos, com a vez em destaque. |
| **Procurar mostra duas ações principais**: "Examinar… pista garantida", em vermelho, e "PROCURAR", também em vermelho ([tela](crit51_pista.png)). | 🟢 | Uma ação principal só. O Examinar fica como opção secundária, com o custo à vista. |
| **★ "melhor chance" numa opção de 20%** (escolha difícil): parece recomendação. | 🟢 | Mostrar a ★ só com 50% ou mais, ou trocar por "a menos arriscada". |

## 3. Terror e ritmo (o coração do pedido)

| Achado | Gravidade | Recomendação |
|---|---|---|
| **O medo não tem antecipação.** O turno do mundo é uma linha no relatório. A Membrana desce 2 por turno e terminou **83, Estável** num caso solucionado. Nada no mapa avisa o que vem. O livro pede antecipação com elementos recorrentes (p.162); FTK tem a linha do tempo das ameaças. | 🔴 | **Linha do tempo do Outro Lado** no alto, ao lado da Membrana: ícones que andam até agora, como "em 3 turnos a Membrana fica instável", "esta noite algo caça" ou "o ritual tem data". O turno do mundo vira um momento: a luz baixa, um som, a Membrana pulsa. |
| **As ameaças que surgem ficam paradas.** "Algo surge perto de Bianca" e a figura fica no hex para sempre ([tela](crit51_covil_travado.png)). Não há perseguição, então ficar isolado só é perigoso na teoria. | 🔴 | **As ameaças caçam:** no turno do mundo, andam um passo em direção ao agente mais isolado, principalmente à noite. É o terror do livro: a ameaça que pode chegar a qualquer momento. |
| **Não há dia e noite.** | 🟡 | **Noite** a cada N turnos: visão menor, encontros mais fortes e eventos de Medo. A luz do mapa já tem clima por Membrana (docs/22), então serve de base. |
| **O terror indireto não existe.** Ninguém de quem o grupo gosta corre risco. As testemunhas são figuras sem rosto e sem nome ("Vizinha na janela", "Viúva"). | 🟡 | **Testemunhas com nome**, pelo roteiro de NPC do livro: nome, função, envolvimento, objetivo e dois traços. A mesma pessoa pode **voltar** num evento e, às vezes, **morrer** fora da tela. Por exemplo: "a merendeira que falou com vocês foi achada…". É o terror indireto da p.163. |
| **A pista não tem o seu momento.** O que o agente achou vira uma polaroide com uma palavra ("LUCRO"). O texto da descoberta fica no relatório recolhido e, no fim da cena, num bloco corrido. | 🟡 | **Close-up da pista**: a câmera aproxima do objeto, o texto é datilografado com um sentido além da visão (cheiro, tato, como pede a p.161) e o traço é carimbado. Dura 2 a 3 segundos e pode ser pulado. É o "operador de câmera" do livro. |
| **O chefe caiu na rodada 3**, numa arena genérica que não lembra o frigorífico deduzido. | 🟡 | **O covil é o lugar deduzido:** ganchos e névoa fria no frigorífico, bancos e vitral na igreja, baias na fazenda. O chefe ganha uma **virada** na metade dos PV (um ritual, uma segunda forma, a Membrana caindo). |

## 4. Hierarquia visual

- **O que chama o olho primeiro:** no mapa, o grupo iluminado; na investigação, as miniaturas. Está certo, mas o foco cai justamente no que mais destoa: as miniaturas de fantasia.
- **Ordem de leitura:**
  - No mapa, o olho vai do topo à esquerda (vez e turno) para o centro (grupo) e depois para baixo à direita (ações). É a leitura de FTK2 e funciona.
  - Na investigação, o painel de Procurar, à esquerda, e as cartas, à direita, cercam a cena por baixo. Com o quadro aberto, sobra pouco da cena.
- **Ênfase:**
  - O realce de movimento (azul e âmbar cheios) é a coisa mais saturada do mapa e apaga o clima ([tela](crit51_movimento.png)). FTK2 marca o alcance com **contorno**, sem preencher o hex.
  - O quadro do caso merece mais destaque no mapa: hoje é uma caixinha de texto pequeno no topo à esquerda.

![Realce de movimento: azul e âmbar cheios](crit51_movimento.png)

## 5. Consistência e identidade

| Elemento | Problema | Recomendação |
|---|---|---|
| **Personagens** | As miniaturas são **fantasia medieval** (KayKit Adventurers): elmo de cavaleiro, capuz de ranger, chapéu de bruxa. Ordem Paranormal se passa no **Brasil de hoje**, com agentes de jaqueta, jeans, lanterna e celular. O desencontro aparece em todas as telas, até nas polaroides da Base. | Trocar por figuras **contemporâneas**. Caminhos a conferir: pacotes CC0 de personagens modernos (por exemplo, Kenney ou Quaternius, um download de cada vez, com sua confirmação) ou modelagem no Blender via MCP. Classe e afinidade entram por acessórios: o combatente com colete, o especialista com bolsa e lanterna, o ocultista com cordão e caderno de sigilos. |
| **Inimigos** | O cultista e as criaturas também vêm da fantasia (elmos, chifres). | Cultistas de túnica e máscara de pano (como os indícios dos casos dizem), e criaturas por elemento: Sangue em vermelho e carne, Morte em cinza e lodo, Conhecimento em dourado e sigilos, Energia em glitch, Medo em branco. |
| **Mundo** | Casas, postes, orelhões, carros, placas e cercas já são do interior do Brasil (docs/32). O tabuleiro é que é pouco povoado: muito gramado vazio entre os marcos. | Mais densidade por terreno (roça, beira de estrada, mata) e marcos à noite: janelas acesas, um poste que pisca. |
| **Base** | Abas, caixas de marcar e listas suspensas. Destoa do resto, que é diegético. | Uma **mesa da Ordem**: pastas dos agentes com foto para escolher o grupo, o caso pregado na cortiça e o arsenal num armário. Tirar números técnicos do briefing ("240 áreas no mapa"). |
| **Eventos** | Papel só com texto. FTK mostra o lugar do evento. | Uma **foto** no papel: um close do 3D do evento com filtro de fita. A tecnologia de foto da Base já existe. |

![Investigação: o clima está certo, as miniaturas não](crit51_investigacao.png)

## 6. Acessibilidade

- **Contraste:**
  - O texto escuro no papel bege passa com folga.
  - O dourado claro no fundo escuro passa.
  - Os rótulos "Deduzir" sobre a cortiça e os nomes flutuantes sobre o 3D claro ficam fracos.
- **Cor não é a única pista:** o âmbar de "longe do grupo" vem com texto ("âmbar: longe do grupo"), e o modo daltônico existe (docs/18). O azul e o âmbar cheios são o caso mais pesado de cor.
- **Tamanho de texto:**
  - O quadro do caso no mapa e o relatório recolhido usam 14 px em 720p.
  - FTK2 levou críticas por texto pequeno.
  - Vale um mínimo de 16 px e uma opção de escala da interface.
- **Alvos de clique:** os botões e as cartas têm bom tamanho para mouse. No combate, a linha de cima ficou apertada a ponto de cortar "Manobra".

## 7. O que funciona bem

- **A linguagem visual de OP por contexto** (docs/09): sigilos nas ações, dossiê na Base, REC na investigação, quadro de cortiça com fio vermelho, Membrana rachada, escolha difícil em vermelho e nota de insanidade.
- **A chance à vista em toda decisão:** dados, DT, porcentagem e "provável/difícil". Isso tira a opacidade que FTK2 recebeu de crítica.
- **A ficha de suspeitos** é clara, segue a regra e mostra o porquê.
- **Os eventos com várias perícias e as escolhas morais** dão decisões de verdade.
- **Os retratos do grupo no estilo FTK2**, com a vez em destaque, e o relatório de fim de cena em papel com carimbo.

## 8. Prioridades

1. **Ritmo do caso e terror no mapa** (o maior impacto):
   - todo traço em dois candidatos ou mais;
   - cenas que focam duas perguntas;
   - linha do tempo do Outro Lado;
   - ameaças que caçam;
   - noite;
   - rumo do caso quando não há pista.

   Isso ataca os dois 🔴 de jogo: o caso que se resolve em 5 turnos e o mapa sem antecipação.
2. **Agentes e inimigos contemporâneos**, o 🔴 de identidade. É o que um fã de OP nota primeiro, e está em todas as telas.
3. **O momento da pista e as testemunhas com nome:** o close-up da pista e o roteiro de NPC do livro, com NPCs que voltam e às vezes morrem. É o terror indireto da p.163.
4. **Limpeza da interface:** fila de papéis, contador de pistas, Manobra cortada, pontos sob o HUD, faixa de iniciativa e realce por contorno. É a lição de FTK2: HUD contextual.
5. **Covil e chefe como clímax:** arena do lugar deduzido e uma virada na metade dos PV.

## Fontes

- For The King II, atualização de interface de maio de 2025: [Turn Based Lovers](https://turnbasedlovers.com/news/tabletop-rpg-for-the-king-ii-is-slowly-becoming-the-game-it-was-meant-to-be/).
- Análises de For The King II: [The Nerd Stash](https://thenerdstash.com/for-the-king-2-review-for-the-rebellion/) (interface confusa, Esc, alvo que não fica salvo) e [Steam Deck HQ](https://steamdeckhq.com/game-reviews/for-the-king-2/) (texto pequeno, escala de interface).
- Dia, noite e linha do tempo em For The King: [wiki, Day](https://fortheking.wiki.gg/wiki/Day), [wiki, Time](https://fortheking.wiki.gg/wiki/Time).
- *Enigma do Medo* (direção de arte e investigação): [Nuuvem](https://nuuvem.com/medo), [TecMundo](https://www.tecmundo.com.br/voxel/257233-enigma-medo-jogo-do-cellbit-entra-pre-venda-veja-preco.htm).
- Livro de regras, cap. 6 (p.161-163): narração, suspense, terror, horror e NPCs, resumidos com palavras próprias.
