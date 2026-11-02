# Referências de design: dedução, pavor, co-op e apego ao esquadrão

Catálogo de padrões comprovados em jogos de investigação, terror e co-op de mesa/digital, com o que cada um poderia virar no RPG fanmade de Ordem Paranormal (OP). Cada achado tem fonte. O mapeamento para o jogo fica em "Inferências", porque é proposta nossa, não fato. A marca **[docs/51]** indica que o padrão se sobrepõe a algo já proposto na crítica anterior; nesses casos, o texto diz qual nuance nova ele traz.

Legenda de confiança das fontes: (P) página lida por inteiro; (R) só o resumo da busca, porque a página não abriu ou não foi lida.

## 1. Quais padrões fazem a dedução parecer merecida e impedem o chute por força bruta?

### Takeaway
Os jogos que melhor impedem o chute combinam três coisas: **confirmação em lote** (Obra Dinn só valida fates de três em três), **vocabulário fechado com contexto** (Golden Idol: frases limitadas encaixadas num texto que dá pistas gramaticais) e **feedback parcial calibrado** ("duas ou menos lacunas erradas"). Os que mostram progresso sem dar a resposta usam um **registro que se preenche sozinho com o que é fato** (logbook de Obra Dinn, ship log de Outer Wilds, diário de Phasmophobia) e deixam ao jogador só a parte inferencial. Para o OP, o padrão mais forte é trocar a acusação item a item por uma **confirmação em lote do trio quem/o quê/onde**, com a Membrana como custo do erro.

### Cited Findings

#### Return of the Obra Dinn (Lucas Pope)
- O relógio Memento Mortem congela os segundos antes de uma morte. Dentro da cena congelada, o jogador pode achar outros corpos e outras pistas. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)
- O logbook registra sozinho o que é fato: um esboço de cada tripulante, a lista da tripulação e a planta do navio. O jogador só precisa dar o nome de quem estava presente e a causa da morte; o resto se preenche sozinho. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)
- As causas de morte vêm de um catálogo fixo, e algumas mortes aceitam mais de uma resposta. As entradas podem ser revistas a qualquer momento. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)
- **Para desencorajar o chute, os destinos corretos só são confirmados em grupos de três**; os seis últimos são confirmados em grupos de dois. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P); a análise da [Film Stories](https://filmstories.co.uk/?p=83249) chama isso de "regra de três" (R). Um dos resultados da busca (guia ou resenha; não identifiquei qual) fala em lotes de "três ou quatro". A Wikipedia é a fonte mais confiável aqui.
- A Wikipedia cita a regra de travar três por vez como elemento que influenciou jogos de dedução posteriores. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)
- Pope organizou a história em capítulos e em dez eventos que disparam grupos de mortes, depois que testadores se confundiram com mortes fora de ordem. Ele usou planilhas para ligar personagens e destinos, para que as cadeias de morte fossem seguíveis por lógica. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)
- Não achei fala direta de Pope explicando o porquê do lote de três; a intenção ("desencorajar o chute") vem de fontes secundárias. — [Wikipedia](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn) (P)

#### The Case of the Golden Idol (Color Gray Games)
- O jogador preenche lacunas num texto em estilo pergaminho, escolhendo entre um conjunto limitado de frases do cenário. O texto dá contexto gramatical e semântico, então o jogador não parte de uma página em branco. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- Um protótipo inicial pedia frases inteiras montadas com termos genéricos. Os testes mostraram que um banco de palavras e a pergunta "onde cada uma encaixa" funcionavam melhor. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- Limitar a entrada cria risco de força bruta. Julgar o pergaminho inteiro como certo ou errado frustrava os jogadores, então a equipe criou o aviso **"duas ou menos lacunas estão erradas"**. Os próprios autores admitem que o aviso reduziu a dificuldade e a duração do jogo. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- Identificar cada pessoa da cena e resolver um quebra-cabeça próprio de cada cenário dá sensação de progresso contínuo. Os dois recursos entraram depois de uma demo em que o veredito único frustrou os jogadores em casos complexos. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- A coleta de evidência é mínima: cada pista existe porque é necessária à solução ou porque desvia o jogador. A abordagem mais ampla e "vivida" de Obra Dinn sobrecarregou os testadores. Os cenários aceitam vários caminhos até a mesma conclusão. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- A equipe descreve um "caminho de pensamento" ligando pistas (a chave leva à sala, a sala revela um nome) e divide os cenários em "quem matou" e "o que diabos está acontecendo aqui". — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- O "aha" vem depois de um bloqueio: nos testes (pelo menos 5 a 7 rodadas), os jogadores travavam, achavam que o cenário era ilógico e, depois de um tempo, tudo encaixava. A meta declarada é o jogador se sentir detetive porque resolveu o mistério, não pela fantasia. — [Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol) (P)
- Na expansão, a equipe diz ter batido num "teto de complexidade", acima do qual os quebra-cabeças deixavam de ser divertidos e funcionais. — [Thinky Games](https://thinkygames.com/features/how-the-case-of-the-golden-idol-developers-made-one-of-the-decades-best-detective-games-twice/) (R)
- Os autores citam Obra Dinn, Her Story e Outer Wilds como inspirações principais. — [Game Developer, Road to IGF](https://www.gamedeveloper.com/road-to-igf-2023/-the-case-of-the-golden-idol-i-used-frequent-testing-to-improve-its-mystery-solving) (R)

#### Phasmophobia (Kinetic Games): dedução por eliminação
- Há sete tipos de evidência, e cada fantasma tem exatamente três. O diário lista cada fantasma com pontos fortes, fracos e as evidências que o identificam, e é preciso marcar evidência e tipo no diário para receber dinheiro e XP. — [ExitLag](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/) (R); [KeenGamer](https://www.keengamer.com/articles/guides/phasmophobia-all-ghost-types-explained-behaviors-strengths-and-weaknesses/) (R)
- Nas dificuldades altas, o fantasma mostra só duas evidências ou menos, e o jogador tem de identificar pelo comportamento. — [ExitLag](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/) (R)
- O Mimic produz uma "quarta evidência" falsa (orbes), e falhas de energia podem dar leitura falsa de temperatura. Isso obriga a cruzar evidência com comportamento antes de fechar. — [Steam, discussão](https://steamcommunity.com/app/739630/discussions/0/5904837854430269389) (R); [Steam, discussão](https://steamcommunity.com/app/739630/discussions/2/2984159549093360596) (R). Fontes de comunidade: confiança média.

#### Her Story (Sam Barlow): o jogador formula a pergunta
- O jogador busca por palavra-chave num banco de vídeos policiais e vê os trechos que contêm a palavra. Novas palavras levam a novos trechos. — [Wikipedia](https://en.wikipedia.org/wiki/Her_Story_(video_game)) (R)
- Barlow escreveu os interrogatórios em ordem, cortou em trechos pesquisáveis e pôs o roteiro inteiro num fluxograma. Algumas palavras foram pensadas para destravar vídeos novos aos poucos. Ele prototipou com transcrições reais de interrogatório. — [Wikipedia](https://en.wikipedia.org/wiki/Her_Story_(video_game)) (R); [PocketGamer.biz](https://www.pocketgamer.biz/making-of-her-story/) (R)
- A intenção era deixar o jogador quase sem guia, para ele sentir que descobriu a história sozinho. — [Wikipedia](https://en.wikipedia.org/wiki/Her_Story_(video_game)) (R)

#### Outer Wilds (Mobius): o mapa de rumores
- O "Rumor Mode" do computador da nave mostra os pontos de interesse achados como uma teia interligada de "rumores". — [SFRA Review](https://sfrareview.org/wp-content/uploads/2020/12/50.4.32.pdf) (R). Um jogador descreve setas com texto apontando um lugar e algo de interesse. — [Steam, discussão](https://steamcommunity.com/app/753640/discussions/0/2518023667592336699?l=latam) (R)
- O conhecimento é a recompensa do jogo. O log marca com asterisco os lugares com coisa a descobrir, mas terminar um lugar não é obrigatório. — [Thinky Games](https://thinkygames.com/games/outer-wilds/) (R; o resumo da busca não deixou claro se o trecho é da Thinky Games ou da Edge na [PressReader](https://www.pressreader.com/australia/edge/20190620/282278141843961))
- A GDC teve duas palestras sobre o tema: "Curiosity-Driven Exploration: The Design of Outer Wilds" (Alex Beachum e Loan Verneau, 2020) e uma de Kelsey Beachum sobre a narrativa a serviço da curiosidade (2021). — [GDC Vault](https://gdcvault.com/play/1027008/Independent-Games-Summit-Sparking-Curiosity) (R); [GDC](https://www.gdconf.com/news/attend-gdc-and-learn-how-outer-wilds-nailed-curiosity-driven-game-design) (R)

#### Disco Elysium (ZA/UM): perícias como vozes e o Gabinete de Pensamentos
- As 24 perícias, em quatro atributos, agem como vozes na cabeça do protagonista: debatem com o jogador, sugerem e puxam escolhas de diálogo. O peso de cada voz depende dos pontos investidos. — [Wikipedia](https://en.wikipedia.org/wiki/Disco_Elysium) (P)
- Perícias altas trazem defeitos, o que desestimula o min-max: Drama alto detecta e inventa mentiras, mas pode trazer histeria e paranoia. — [Wikipedia](https://en.wikipedia.org/wiki/Disco_Elysium) (P)
- Os pensamentos surgem em conversas e no monólogo interno. O jogador os "internaliza" ao longo de horas do jogo, com poucos espaços no começo. Enquanto internaliza, o pensamento pode dar penalidade; ao concluir, dá bônus. Exemplo: "Hobocop" reduz a compostura enquanto é internalizado e depois dobra a renda com reciclagem. — [Wikipedia](https://en.wikipedia.org/wiki/Disco_Elysium) (P)
- O gabinete substitui ao mesmo tempo os sistemas de perk, traço, classe e reputação. Cada pensamento começa virado para baixo, só com o nome. O jogo tem 53. — [GameBanshee, blog dos desenvolvedores](https://gamebanshee.com/39hc9) (R)
- O design abraça o fracasso como conteúdo: um slogan descartado chamava o jogo de RPG "sobre ser um fracasso total". A equipe chama de "microrreatividade" o efeito em cadeia de escolhas pequenas. — [Wikipedia](https://en.wikipedia.org/wiki/Disco_Elysium) (P)

#### Sherlock Holmes: Chapter One (Frogwares): palácio mental e veredito moral
- O jogador coleta pistas por observação e as leva ao "palácio mental", onde as liga em deduções e conclusões. Acusações erradas são possíveis. — [Film Stories](https://filmstories.co.uk/gaming/a-look-at-sherlock-holmes-chapter-one/) (R)
- As conclusões viram veredito, que pode incluir escolha moral: condenar ou absolver o suspeito. — [GameCritics](https://gamecritics.com/david-bakker/sherlock-holmes-chapter-one-preview/) (R)
- A GameSpot elogiou a investigação, mas criticou a simplicidade. — [Wikipedia](https://en.wikipedia.org/wiki/Sherlock_Holmes_Chapter_One) (R)

#### Paradise Killer (Kaizen Game Works): acuse quem quiser, mas prove
- O jogador pode acusar qualquer um, mas precisa provar o caso no julgamento, que pode começar a qualquer momento. O resultado depende das evidências e depoimentos reunidos e de como o jogador interpreta os fatos para o Juiz. — [Indie Arena Booth](https://indiearenabooth.de/gamescom2020/games/show/1925) (R); [Select Button](https://selectbutton.com/reviews/paradise-killer-review) (R)
- Segundo a PC Gamer, o jogo nem diz se o jogador acertou. Um desenvolvedor contou que permitir acusar qualquer um foi difícil, e que o julgamento entrou tarde: antes, o jogo era quase um walking simulator. — [PC Gamer](https://pcgamer.com/how-a-new-indie-studio-created-one-of-the-best-detective-games-ever/) (R; a página não abriu, só o resumo)

#### Shadows of Doubt (ColePowered): procedural com quadro de cortiça
- O quadro de cortiça digital, onde o jogador prende pistas, fotos e notas, é apontado como um dos recursos mais satisfatórios. — [GamingTrend](https://gamingtrend.com/feature/previews/shadows-of-doubt-early-access-preview-shining-a-light-on-the-truth) (R)
- As pistas são geradas proceduralmente, não deixadas como trilha fixa. O desenvolvedor reconhece que a liberdade pode frustrar e por isso oferece alguma orientação roteirizada no começo. — [Wireframe](https://wireframe.raspberrypi.com/articles/walking-the-voxelated-city-streets-in-shadows-of-doubt-a-fully-simulated) (R)
- Um crítico notou que os casos procedurais não batem com o caso tutorial roteirizado. — [Gameluster](https://gameluster.com/early-access-review-shadows-of-doubt-theres-not-been-another-murder-yet/) (R)

#### Duskwood (Everbyte): investigação por mensageiro
- O jogo roda dentro de um mensageiro fictício, no estilo do WhatsApp, com notificações em tempo real, perfis, fotos, áudios e ligações. As respostas do jogador mudam o que os personagens revelam. — [App Store](https://apps.apple.com/app/id1479430106) (R)

### Inferences

**Padrões para o quadro de cortiça do OP**

| Padrão | Fonte | Por que funciona (psicologia) | Como mapear no OP | Sobreposição |
|---|---|---|---|---|
| **Confirmação em lote** | Obra Dinn | O jogador nunca sabe qual peça está certa, então chutar uma lacuna isolada não dá informação; ele só ganha certeza quando acerta o conjunto. Isso pune o chute sem punir o raciocínio. | Hoje cada pergunta é deduzida e paga Membrana se errar. Proposta: o quadro só **valida o trio quem/o quê/onde junto**. O erro custa Membrana uma vez e diz só "o relato não se sustenta". A reviravolta (docs/50) fica num lote próprio, depois. | Reforça a regra de docs/51 ("todo traço em 2+ candidatos"): sem ela, o lote vira chute com 3 tentativas. |
| **Aviso "perto"** | Golden Idol | Feedback parcial mantém o jogador motivado em casos difíceis, mas encurta o jogo, como os autores admitem. | Um aviso só no erro, por dificuldade: Fácil diz quantas peças estão erradas; Normal diz "uma ou mais"; Pesadelo não diz nada. | Novo. |
| **Vocabulário fechado com contexto** | Golden Idol | O jogador não cria do zero: escolhe entre termos vistos e encaixa num texto que já sugere a gramática. Só entram termos coletados, então não dá para deduzir sem ter visto. | O relatório de dedução vira um **texto com lacunas** ("___ usou ___ no ___ para ___"). Só entram palavras de pistas registradas (polaroides). Uma palavra não coletada não aparece no banco. | Complementa o close-up de pista de docs/51: a palavra carimbada vira a peça do banco. |
| **Registro que se preenche sozinho** | Obra Dinn, Phasmophobia | Separa fato de inferência: o jogo anota o que se viu; o jogador só decide o que isso significa. O registro não fica com cara de dever de casa. | O arquivo do caso anota sozinho quem estava em cada cena, as falas e o local. A ficha do suspeito fica só com o que é inferência: riscar e marcar. | Novo. |
| **Eliminação por traços (3 de 7)** | Phasmophobia | Cada evidência corta metade das hipóteses; o jogador sente o funil se fechando. A versão difícil esconde uma evidência e exige comportamento. | Para "o quê" (a criatura ou o elemento do ritual): cada entidade tem **3 traços de um pool de 7** (marca de sangue, frio, sigilo, falha elétrica, etc.). No Pesadelo, um traço não aparece e o jogador deduz pelo comportamento no mapa. Uma criatura "imitadora" (Medo?) planta um traço falso. | Casa com docs/51 (2+ candidatos por traço): é o mesmo princípio. |
| **Mapa de rumores** | Outer Wilds | Mostra o que falta saber sem dizer a resposta; a curiosidade vira a bússola. O asterisco diz "aqui tem mais", não "vá aqui". | O quadro desenha **fios tracejados** de cada pista a um "?" ligado a uma região do mapa ("a vizinha falou de um caminhão na estrada velha"). O hex ganha um asterisco discreto. | Aprofunda o "rumo do caso" de docs/51: em vez de uma mensagem, uma teia permanente. |
| **Perícias como vozes** | Disco Elysium | A ficha vira personagem; perícia alta "fala mais" e às vezes engana. O jogador sente a perícia sem ver um número. | Nas cenas, perícias passivas comentam sem rolagem (Ocultismo: "esse sigilo está de cabeça para baixo"; Percepção: "o chão foi lavado"), com a voz e o tom do agente. Perícia muito alta pode dar uma leitura enviesada (paranoia de Ocultismo). | Novo. |
| **Gabinete de teorias** | Disco Elysium | Transforma uma ideia num investimento com tempo e custo. O "virado para baixo" gera curiosidade. | Algumas pistas destravam uma **teoria** que o agente "rumina" por N turnos do mundo (penalidade leve enquanto pensa) e que vira um bônus permanente ou uma pergunta extra no quadro. Também serve à Base: traumas e convicções como teorias. | Novo. |
| **Veredito com escolha moral** | Sherlock Chapter One, Paradise Killer | Depois da certeza, a decisão do que fazer com ela pesa mais que acertar. Paradise Killer mostra que "fato" e "verdade" podem divergir. | Depois do trio confirmado: **entregar à Ordem, encobrir ou deixar fugir**, com efeito em Prestígio e na Membrana. Paradise Killer sugere uma variante arriscada: no julgamento, cada acusação precisa **anexar a evidência**; o jogo pesa a força do caso, não só o acerto. | Prolonga as escolhas morais de docs/50. |
| **Busca por palavra** | Her Story | O jogador formula a pergunta; acertar o termo é uma pequena dedução. | Um terminal na Base (ou no celular do agente) pesquisa o **arquivo da Ordem** com palavras das polaroides e devolve trechos de relatórios antigos ou de depoimentos. Bom para a campanha e para casos recorrentes. | Novo. |
| **Mensageiro** | Duskwood | Testemunhas "vivas" que escrevem entre um turno e outro dão presença sem gastar uma cena. | As testemunhas com nome de docs/51 mandam mensagens no celular do agente entre os turnos do mundo. O silêncio de uma testemunha vira terror indireto. | Dá forma às testemunhas recorrentes de docs/51. |

**Cuidados destilados das fontes**
- Golden Idol mostra que o feedback parcial **reduz a dificuldade**: em OP, ele deve depender da dificuldade escolhida, e não ser padrão em tudo.
- Golden Idol também mostra o **teto de complexidade**: um caso com 5 perguntas (quem, o quê, onde, mandante, origem) já está perto dele. É melhor confirmar em lotes menores que somar perguntas.
- Shadows of Doubt mostra o risco do procedural: casos gerados precisam de uma **gramática fixa** (como o "caminho de pensamento" de Golden Idol) e de um tutorial que use **o mesmo gerador**. Não serve um caso roteirizado que ensina outra coisa.
- Obra Dinn mostra que agrupar mortes em **eventos-capítulo** ajudou os testadores. Em OP, cada cena de investigação deve ser um "capítulo" com duas perguntas, como docs/51 já propõe.

### Gaps
- Não achei fala primária de Lucas Pope sobre a escolha do lote de três; a intenção vem de fontes secundárias.
- Não confirmei por fonte lida as regras de checagem "branca" (repetível) e "vermelha" (uma chance) de Disco Elysium; ficaram fora dos achados.
- A página da PC Gamer sobre Paradise Killer não abriu; as falas do desenvolvedor vêm do resumo da busca.
- Não achei dado público (telemetria, entrevista) que meça quanto o aviso "duas ou menos erradas" reduziu o chute em Golden Idol; os autores só dizem que reduziu a dificuldade.
- Não confirmei por fonte se Her Story limita o número de resultados por busca.

## 2. Quais sistemas de pavor e ritmo criam antecipação, especialmente em jogos por turno?

### Takeaway
Nos jogos de tabuleiro e por turno, a antecipação vem de **relógios visíveis com limiares** (agenda e perdição de Arkham LCG, trilha de presságio de Eldritch Horror, medidor de Caos de FTK) que o jogador **pode atrasar com ações** e que mostram **o que vem a seguir**. Nos jogos de tempo real, a lição transferível é o **diretor que dosa a pressão e alivia depois do pico** (o "menace gauge" de Alien: Isolation, o diretor de Left 4 Dead). A lição de Amnesia, Eternal Darkness e Dark Corners of the Earth para a sanidade: **efeitos ambíguos e diegéticos assustam mais que números**, mas efeitos com custo mecânico pesado criam espiral de derrota.

### Cited Findings

#### Arkham Horror: The Card Game (FFG): agenda contra ato
- O baralho de Ato representa o progresso dos investigadores; o de Agenda é um cronômetro que as forças contrárias avançam. A cada turno entra um marcador de perdição na Agenda; quando a perdição em jogo atinge o limiar da agenda atual, ela avança, normalmente com consequência ruim. — [Wikipedia](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game) (P)
- A perdição em outras cartas em jogo (por exemplo, cultistas) também conta para o limiar, e alguns limiares escalam "por investigador". — [Arkham Grimoire, FFG](https://images-cdn.fantasyflightgames.com/filer_public/4e/da/4eda7782-c983-47cc-8d9f-ae372a44d87b/arkham_grimoire_v11.pdf) (R)
- Os limiares da primeira agenda ficam entre cerca de 3 e 8 de perdição, conforme o cenário. — [ArkhamDB](https://arkhamdb.com/decklist/view/40898/standalone-ready-amina-is-no-longer-welcome-at-game-night-1.0) (R)
- As escolhas de um cenário têm efeito duradouro e mudam cenários seguintes; cada cenário tem vários pontos de divergência. — [Wikipedia](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game) (P)

#### Eldritch Horror (FFG): presságio cíclico
- A trilha de Perdição conta o tempo até o Antigo despertar. A trilha de Presságio é um círculo que gira na fase de Mitos; portais abertos com o símbolo do presságio atual avançam a Perdição, o que dá motivo para fechar portais depressa. — [Board Game Quest](https://boardgamequest.com/eldritch-horror-board-game-review) (R); [There Will Be Games](https://therewillbe.games/articles-boardgame-reviews/7507-eldritch-horror-in-review) (R)
- Cada Antigo tem seus Mistérios; em geral, vence-se resolvendo três antes do fim da Perdição. Os resenhistas dizem que isso dá um arco de história mais forte que o de Arkham Horror. — [Zatu](https://zatu.com/eldritch-horror-review/) (R)
- O "Acerto de Contas" (Reckoning) da fase de Mitos é a parte mais temida e um pouco trabalhosa, mas aumenta a tensão. — [There Will Be Games](https://therewillbe.games/articles-boardgame-reviews/7507-eldritch-horror-in-review) (R)

#### For The King (IronOak): Caos, linha do tempo e flagelos [docs/51]
- O medidor de Caos tem três emblemas. O Caos sobe depois de um número fixo de turnos, se não for contido, e cada aumento cria hexes de Caos com efeitos aleatórios. Os inimigos ganham 5%, 10% ou 20% de vida por nível, conforme a dificuldade. — [FTK Wiki, Gameplay](https://fortheking.wiki.gg/wiki/Gameplay) (P); [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- Com os três emblemas cheios vem o Caos total: terra amaldiçoada inunda os hexes e surge uma Besta do Caos escondida num hex aleatório, que ataca o grupo inteiro e só aparece quando alguém pisa nela. — [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- O Caos cai ao desativar Geradores de Caos (um por região), achar Dispositivos de Culto, destruir acampamentos de acólitos em missões de cidade ou vencer o carrossel da Feira Sombria. O carrossel é uma aposta: um sucesso **aumenta** o Caos, e uma falha total enche o medidor. — [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- Se o Caos for reduzido quando não há Caos visível na linha do tempo, a **próxima** ocorrência é que some. — [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- Fora do combate, a linha do tempo mostra o ciclo de dia e noite e os eventos que vêm (flagelos despertos, Caos crescente, inundações, alinhamentos de planetas). No combate, a mesma faixa mostra a ordem dos turnos. — [FTK Wiki, Gameplay](https://fortheking.wiki.gg/wiki/Gameplay) (P)
- Os Flagelos (Scourges) ficam dormentes em Assombrações até serem achados. O jogador pode **selar** a Assombração antes que o Flagelo acorde; depois que ela fica ativa, não dá mais para selar. — [FTK Wiki, Scourge](https://fortheking.wiki.gg/wiki/Scourge) (R)
- A morte de um personagem não gera Caos, mas reduz o "pool de vidas" do grupo. — [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- Chuva e tempestade de areia reduzem testes de Percepção e aumentam a chance de emboscada. — [FTK Wiki, Gameplay](https://fortheking.wiki.gg/wiki/Gameplay) (P)

#### Betrayal at House on the Hill (Avalon Hill): a virada com probabilidade crescente
- Cada carta de Presságio pede uma rolagem; conforme o resultado, começa a fase de Assombração. O Presságio que a dispara (e, nas primeiras edições, a sala) define qual das 50 assombrações acontece e quem é o traidor. — [Wikipedia](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill) (P)
- O traidor sai da sala e lê seus objetivos num livro; os heróis leem os deles em outro. Cada porta sem sala atrás puxa um ladrilho aleatório, então a casa muda a cada partida. — [Wikipedia](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill) (P)

#### Mansions of Madness 2ª ed. (FFG): o app como Guardião
- Cada rodada tem fase de Investigadores e fase de Mitos. O app gera eventos de Mitos, ligados ao cenário ou às ações dos jogadores, ativa cada monstro em ordem e descreve o ataque. Depois, cada investigador faz um teste de horror contra o monstro em alcance com maior valor de horror. — [The Board Game Family](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) (P)
- Ao explorar, o app revela qual ladrilho pôr e o que há nele, então o mapa nasce durante a partida. O app faz o papel do Guardião, e por isso nenhum jogador controla os monstros. — [The Board Game Family](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) (P); [Rulespal, regras](https://rulespal.com/mansions-of-madness-second-edition/rulebook) (R)

#### Alien: Isolation (Creative Assembly): diretor e "menace gauge"
- Há duas camadas: um diretor "macro", que sempre sabe onde o jogador está, e a IA "micro" do alien, que precisa achar o jogador sozinha. O diretor às vezes aponta o alien na direção do jogador, mas o alien não trapaceia: em 12 a 18 horas de campanha, ele se teletransporta só duas vezes, ambas em cutscenes. — [Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) (P)
- O medidor de ameaça sobe com a proximidade, quando o jogador vê o alien e quando o alien aparece perto no detector de movimento e pode chegar rápido. Perto mas em outra sala, sobe devagar. Vem de proximidade e tensão, não de ataques. — [Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) (P)
- No pico, o diretor manda o alien para os dutos ou áreas vizinhas ("bastidores"), para dar fôlego. Medo constante faz o jogador desistir. — [Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) (P)
- Comportamentos novos do alien se destravam pelas ações do jogador, nunca pelas mortes, para o jogador não se sentir punido por regras escondidas. Jump scares roteirizados funcionam uma vez e nada acrescentam numa segunda partida. — [Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) (P)
- Os designers podem bloquear áreas onde o alien nunca procura, para manter o encontro justo. — [Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) (P)

#### Left 4 Dead (Valve): o diretor de IA
- O jogo avalia o desempenho e o ritmo do time: reduz zumbis quando o time apanha muito e aumenta hordas e chefes quando o time está tranquilo. — [Shacknews](https://shacknews.com/article/46769/left-4-dead-preview) (R)
- Numa entrevista de 2007, Mike Booth descreve o diretor planejando ataques quando a ação acalma e deixando a situação assentar depois de combate longo. — [Game*Spark](https://www.gamespark.jp/article/2007/04/10/11866.html) (R)

#### Darkwood (Acid Wizard): dia de busca, noite de cerco
- De dia o jogador explora a floresta, junta recursos e conserta barricadas; de noite fica preso no esconderijo e precisa resistir a invasores até de manhã. Armadilhas e barricadas preparadas de dia fazem a diferença. — [Wikipedia](https://en.wikipedia.org/wiki/Darkwood) (R); [Push Square](https://pushsquare.com/reviews/ps4/darkwood) (R)
- Cozinhar alucinógenos destrava habilidades, mas cada habilidade boa vem com uma ruim. — [Wikipedia](https://en.wikipedia.org/wiki/Darkwood) (R)

#### Sanidade: Amnesia, Eternal Darkness e Dark Corners of the Earth
- **Amnesia:** a sanidade começou explícita, com números na tela, e virou implícita: só uma imagem e um texto no inventário, com retorno audiovisual (tela pulsando, som de casca de ovo rachando, quedas súbitas). Motivos: nos níveis interligados alguns jogadores mal notavam a sanidade, e outros ficavam presos em sanidade baixa, o que deixava o jogo quase injogável. No fim, o desafio foi tirado (não dá para perder por sanidade), e a ambiguidade fazia o jogador temer enlouquecer e inventar teorias. Thomas Grip: "Horror should feel real, not actually be real." — [Game Developer](https://www.gamedeveloper.com/design/game-design-deep-dive-i-amnesia-i-s-sanity-meter-) (P)
- **Eternal Darkness:** a sanidade cai quando monstros veem o jogador; em sanidade baixa vêm efeitos que vão de estátuas virando a cabeça a falsos erros de TV ou do console. A ideia veio de Call of Cthulhu. A equipe precisou deixar claro o que era truque, porque alguns efeitos (como o falso "formatar o cartão de memória") assustavam de verdade. — [Wikipedia](https://en.wikipedia.org/wiki/Eternal_Darkness) (R); [Time Extension](https://timeextension.com/features/the-making-of-eternal-darkness-sanitys-requiem-gamecubes-horror-classic) (R)
- **Call of Cthulhu: Dark Corners of the Earth:** não há HUD; vida e sanidade aparecem por som e imagem (batimento, respiração, visão tremida, tontura). Os autores evitaram efeitos fora do mundo do jogo, como os de Eternal Darkness. A sanidade cai com horrores e conhecimento proibido e sobe ao matar criaturas e fazer o bem (salvar NPCs, cumprir objetivos). Também aparecem tiques, como carregar e descarregar a arma sem parar. — [Wikipedia](https://en.wikipedia.org/wiki/Call_of_Cthulhu:_Dark_Corners_of_the_Earth) (R); [GameSpot, entrevista com Andrew Brazier](https://www.gamespot.com/articles/call-of-cthulhu-dark-corners-of-the-earth-qanda/1100-2838073/) (R)

#### Interface diegética e found footage: Dead Space e Outlast
- **Dead Space:** sem HUD tradicional; vida, inventário e localizador ficam no traje RIG. A vida é uma barra luminosa na coluna, que muda de cor conforme cai. — [Game Developer, palestra de Dino Ignacio](https://gamedeveloper.com/design/video-designing-i-dead-space-i-s-immersive-user-interface) (R); [Dead Space Wiki](https://deadspace.fandom.com/wiki/Resource_Integration_Gear) (R). O relevo do traje ajudou a iluminação e permitiu a barra nas costas. — [80.lv](https://cdn.80.lv/articles/the-technological-reason-behind-the-ribbed-suit-design-in-dead-space) (R)
- **Outlast:** a câmera é a única ferramenta; a visão noturna gasta bateria, e sem bateria não há visão noturna. Ela também borra e encurta a visão. O limite de baterias muda com a dificuldade: 10 no Normal, 5 no Difícil, 2 no Pesadelo e no Insano. A Red Barrels citou os filmes [REC] e Quarentena como influência. — [Wikipedia](https://en.wikipedia.org/wiki/Outlast) (R); [Outlast Wiki](https://outlast.fandom.com/wiki/Batteries) (R)

#### Darkest Dungeon 1 e 2 (Red Hook): luz como risco
- No DD2, a tocha é a mecânica central: com luz baixa os heróis se estressam mais, e os inimigos ganham bônus no escuro. Chris Bourassa diz que a tocha é também símbolo: se apagar, a jornada acaba, com uma última luta difícil para reacendê-la. — [Zero Indent](https://zeroindent.com/darkestdungeon2/) (R)
- No DD1, aventurar-se sem comida ou luz é fonte de estresse. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon) (P)

### Inferences

**Padrões para o mapa, o turno do mundo e a Sanidade**

| Padrão | Fonte | Por que funciona | Como mapear no OP | Sobreposição |
|---|---|---|---|---|
| **Agenda contra Ato** | Arkham LCG | Dois relógios visíveis correndo um contra o outro: o jogador sempre sabe "quanto falta" e "quanto já fiz". Cada turno gasto vira uma escolha. | A Membrana já é a Agenda. Falta o **Ato**: uma trilha de progresso do caso (pistas firmes registradas) com limiares que destravam coisas (o covil se revela, um aliado aparece). Os limiares da Agenda escalam por número de agentes, como o "por investigador". | Completa a linha do Outro Lado de docs/51 com o lado do jogador. |
| **Perdição em cartas no mapa** | Arkham LCG | A perdição não fica só no relógio: ameaças ignoradas aceleram o fim, e o jogador escolhe entre investigar e conter. | Cultistas e rituais no mapa carregam **marcadores de Membrana**: enquanto estiverem de pé, somam ao dreno do turno do mundo. Eliminar um é uma forma de "comprar tempo". | Dá motivo mecânico às ameaças que caçam de docs/51. |
| **Presságio cíclico por elemento** | Eldritch Horror | O jogador sabe qual símbolo vem a seguir e prioriza; a antecipação vem da previsibilidade, não da surpresa. | Uma roda com os cinco elementos (Sangue, Morte, Conhecimento, Energia, Medo) gira a cada turno do mundo. Anomalias abertas do elemento da vez drenam Membrana extra. O próximo elemento fica à vista: "na próxima noite, Morte". | Novo; casa com a linha do Outro Lado de docs/51. |
| **Relógio que se compra de volta** | FTK (Geradores, Dispositivos) | Dá agência contra o pavor: o jogador pode atrasar a ruína, mas pagando com desvios. | Na linha do Outro Lado, eventos futuros podem ser **removidos**: selar um sigilo no mapa, destruir um altar, salvar uma testemunha. Se não há evento visível, some o próximo (regra de FTK). | Nuance sobre docs/51: a linha não é só aviso, é alvo. |
| **Selar antes de acordar** | FTK (Flagelos) | Uma ameaça dormente é uma pergunta aberta ("vale gastar turnos agora?"); depois de acordada, a janela fecha. | Locais "adormecidos" no mapa (uma igreja fechada, um poço) podem ser **selados com ritual** antes de despertar, a custo de PE e turnos. Despertos, viram um mini-chefe que caça. | Novo. |
| **Aposta com o Outro Lado** | FTK (carrossel) | O risco escolhido dá mais pavor que o risco imposto. | Um evento raro de "barganha": um teste de Ocultismo que pode recuperar Membrana, mas que no fracasso parcial a **piora**. | Novo. |
| **Virada por probabilidade crescente** | Betrayal | Cada presságio aumenta a chance de a casa "virar"; a mesa sente o perigo subindo antes de ele chegar. | A reviravolta de docs/50 vira um **teste do Outro Lado**: cada presságio coletado (pista de Medo, objeto amaldiçoado) aumenta a chance de a virada acontecer no turno do mundo. A barra fica visível. | Nuance sobre docs/50: o momento da virada deixa de ser fixo. |
| **Diretor com alívio** | Alien: Isolation, Left 4 Dead | O pico só assusta se houver vale. Pressão constante cansa e faz desistir. Destravar comportamento por ação, não por morte, evita a sensação de regra escondida. | Um **medidor de pressão** escondido (proximidade de ameaças, PV e Sanidade baixos, noite). Ao passar do limite, as ameaças recuam para a névoa por 1 ou 2 turnos ("bastidores"). Quando o grupo está tranquilo, o diretor puxa um encontro. As ameaças aprendem com o que o grupo faz (quem usa muita luz atrai criaturas de Energia). | Nuance sobre as ameaças que caçam de docs/51: sem o alívio, a caça vira atrito. |
| **Sem trapaça** | Alien: Isolation | O medo só é justo se o jogador acredita que poderia ter escapado. | A ameaça que caça só anda pelo mapa visível às regras (sem teleporte), e o agente vê o rastro (pegadas, luz piscando) antes do encontro. | Reforça docs/51. |
| **Noite de cerco** | Darkwood | O contraste entre "sair para buscar" e "segurar a porta" dá ritmo natural ao dia. A preparação de dia vira tensão à noite. | À noite, um agente numa vila ou num abrigo pode **fortificar** (barricada, sal, sigilos) e enfrenta um evento de cerco curto. Quem está no mato enfrenta a caça. A escolha de onde passar a noite vira tática. | Nuance sobre a noite de docs/51. |
| **Sanidade implícita e ambígua** | Amnesia, Dark Corners | O número tranquiliza; a dúvida assusta. Sanidade com custo mecânico pesado vira espiral de derrota. | Manter a Sanidade exata na ficha, como o livro pede, mas no mapa e na cena mostrar **sinais**: respiração na trilha sonora, vinheta, tiques do agente (checar a arma, olhar para trás). Só os efeitos de insanidade de docs/49 têm peso mecânico. Recuperar Sanidade por **atos bons** (salvar a testemunha, fechar o caso), como em Dark Corners. | Complementa docs/49. |
| **Glitch que quebra a quarta parede** | Eternal Darkness | O jogador duvida do próprio jogo. | Só com Sanidade muito baixa e só para criaturas de **Energia**: o HUD falha, a Membrana mostra um número falso por um segundo, uma polaroide aparece com outro rosto. Deve ser opcional (docs/18) e deixar claro depois que foi truque, como a equipe de Eternal Darkness aprendeu. | Novo. |
| **Interface diegética** | Dead Space | A informação vital fica no mundo, e o olho não sai da cena. | A vida e a Sanidade aparecem na figura 3D: a lanterna treme com Sanidade baixa e a postura muda com PV baixo. A Membrana rachada já é um passo nessa direção. | Estende a direção visual existente. |
| **Bateria da câmera** | Outlast | Um recurso escasso que é ao mesmo tempo olho e relógio. O limite por dificuldade ajusta o pavor sem mexer no inimigo. | A estética REC da investigação vira mecânica: a **câmera ou lanterna** revela pontos de pista escondidos no escuro, mas gasta bateria. As baterias têm limite por dificuldade. | Novo; usa a linguagem REC já existente. |
| **Luz como risco** | Darkest Dungeon 2 | A luz é recurso e símbolo; o escuro paga mais e cobra mais. | Uma luz por agente (lanterna) ou a luz do turno do mundo. No escuro, os encontros dão mais recompensa e mais Sanidade perdida. | Liga-se à noite de docs/51. |

**Ordem sugerida para o turno**: (1) a roda do presságio gira; (2) a Agenda soma perdição, incluindo os marcadores no mapa; (3) o diretor decide caçar ou recuar; (4) o teste da virada, se houver presságios; (5) mensagens de testemunhas. Tudo numa só animação curta, como a fase de Mitos de Mansions.

### Gaps
- Não confirmei por fonte primária o ciclo "build-up, peak, relax" do diretor de Left 4 Dead; as fontes lidas descrevem o comportamento, mas não usam esses termos.
- A palestra da GDC sobre Alien: Isolation não estava disponível; os detalhes vêm do texto da Game Developer, que resume a palestra.
- Não achei como o dia e a noite de FTK 1 e 2 afetam o jogo (a wiki só diz que a linha do tempo mostra o ciclo). Também não achei fonte sobre a mecânica de dia e noite de FTK2.
- O artigo da Tabletop Gaming com Bruce Glassco sobre o design das assombrações de Betrayal não abriu; não há fala do autor nestas notas.
- Não confirmei por fonte lida os detalhes do teste de horror de Mansions (dados, limiares); a resenha só descreve a ordem dos passos.

## 3. Quais padrões de apresentação co-op mantêm 2 a 4 jogadores engajados durante o turno dos outros?

### Takeaway
Os padrões que funcionam dão ao jogador parado **algo a decidir no turno alheio**: comprometer um recurso no teste do colega (Arkham LCG), **planejar em simultâneo** e revelar junto (Gloomhaven), ou **guardar um segredo** (traidor de Betrayal, objetivo de insanidade de Mansions). Há também os **momentos compartilhados** que todos assistem juntos (a fase de Mitos narrada pelo app de Mansions) e o **diário coletivo** de evidências (Phasmophobia), onde a dedução vira conversa. A ressalva de Mansions: um aparelho só deixa gente de fora, e os jogadores espelham o app na TV.

### Cited Findings
- **Arkham LCG, ajuda no teste:** cada outro investigador **no mesmo local** pode comprometer uma carta da mão no teste de perícia do colega. O FAQ trata uma carta como o padrão, e cartas como Copycat e Daredevil permitem mais. — [FFG Forum Archive](https://ffg-forum-archive.entropicdreams.com/topic/236873-card-use/) (R); [ArkhamDB](https://arkhamdb.com/reviews/360) (R)
- **Gloomhaven, planejamento simultâneo:** cada jogador escolhe duas cartas da mão, e a carta de cima define a iniciativa. Todos revelam juntos, depois as cartas dos monstros são viradas e tudo se resolve por iniciativa. Cada carta tem metade de cima e metade de baixo, e o jogador escolhe qual metade usar na sua vez. — [Wikipedia, Gloomhaven (video game)](https://en.wikipedia.org/wiki/Gloomhaven_(video_game)) (R); [Opinionated Gamers](https://opinionatedgamers.com/2020/11/28/gloomhaven-does-it-live-up-to-the-hype-review-by-rj-garrison/) (R)
- **Gloomhaven, desgaste como relógio:** com o tempo os jogadores perdem cartas para sempre; se demorarem demais, ficam exaustos e precisam recuar. — [Opinionated Gamers](https://opinionatedgamers.com/2020/11/28/gloomhaven-does-it-live-up-to-the-hype-review-by-rj-garrison/) (R)
- **Mansions of Madness:** cada jogador opera o app no seu turno, e todos discutem as escolhas. Como um aparelho só pode excluir os outros, a família da resenha espelhou o app na TV. Enlouquecer faz o investigador comprar uma carta que **pode mudar seu objetivo pessoal**, às vezes contra o do grupo. — [The Board Game Family](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) (P)
- **Betrayal:** quando a assombração começa, o traidor sai da sala para ler seus objetivos num livro à parte; os heróis leem os deles noutro. Informação assimétrica e secreta. — [Wikipedia](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill) (P)
- **Phasmophobia:** o diário de evidências e a identificação do fantasma são marcados pelo grupo para receber a recompensa. A comunidade recomenda cruzar evidência com comportamento antes de marcar (o caso do Mimic). — [ExitLag](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/) (R); [Steam, discussão](https://steamcommunity.com/app/739630/discussions/0/5904837854430269389) (R)
- **Mansions, momento compartilhado:** a fase de Mitos acontece depois que todos agem; o app narra os eventos e os ataques, mas os jogadores rolam os dados físicos, o que mantém a tensão. — [The Board Game Family](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) (P)
- **FTK 2:** até quatro jogadores enfrentam missões e combates por turno juntos. Um crítico chama o jogo de jogo de planejamento tático, gestão de risco e trabalho em equipe. — [Inverse](https://www.inverse.com/gaming/for-the-king-2-game-pass-review) (R)

### Inferences

| Padrão | Fonte | Por que funciona | Como mapear no OP | Sobreposição |
|---|---|---|---|---|
| **Apoiar o teste do colega** | Arkham LCG | O jogador parado tem uma decisão real e cara no turno alheio; o sucesso vira coletivo. | Quando um agente rola numa cena ou num evento, cada outro agente **no mesmo hex ou na mesma cena** pode gastar **1 PE** ou um item para somar um bônus. A janela abre na tela de todos por alguns segundos (online) ou na vez do hotseat. | Novo. Precisa conferir a regra de ajuda do livro e citar `ref: "p.N"`. |
| **Planejar junto, revelar junto** | Gloomhaven | Elimina a espera: todos decidem ao mesmo tempo, e a revelação vira um momento. | No combate tático, uma **fase de plano** em que cada jogador escolhe sua ação e o alvo em segredo. Depois, a faixa de iniciativa (docs/51) resolve tudo em ordem. Opcional para quem prefere o turno clássico. | Nuance sobre a faixa de iniciativa de docs/51. |
| **Segredo de um só** | Betrayal, Mansions | A informação assimétrica faz cada jogador olhar para os outros com suspeita, mesmo fora do turno. | Ao enlouquecer (docs/49), um agente pode receber um **objetivo secreto**, visto só pelo seu jogador: "garanta que o grupo não destrua o livro". No online vai para a tela do dono; no hotseat, numa tela "passe para fulano". Na virada (docs/50), um agente pode ser **possuído pelo Medo** com instruções próprias. | Nuance sobre docs/49 e docs/50. |
| **Diário coletivo** | Phasmophobia | Dedução vira conversa: alguém marca, outro contesta. | O quadro de cortiça é compartilhado no online, e cada jogador vê quem prendeu o quê (cor do fio por agente). Para validar o lote, é preciso **voto da maioria**, o que gera discussão. | Nuance sobre o lote de três (Q1). |
| **Fase de Mitos assistida** | Mansions | Um momento curto, narrado, que todos assistem juntos depois de agir. | O turno do mundo vira uma "fase do Outro Lado" de 3 a 5 segundos, igual para todos, com narração e a roda do presságio (Q2). | Dá forma ao "turno do mundo vira momento" de docs/51. |
| **Uma tela para a mesa** | Mansions (o espelho na TV) | Ninguém fica de fora da informação. | No hotseat local, a interface deve ser legível de longe (texto de 16 px ou mais, como docs/51 pede) e evitar painéis que só o jogador da vez entende. | Reforça a acessibilidade de docs/51. |
| **Papéis na cena** | Inferência a partir de Arkham e Disco Elysium | Quem não está rolando ainda participa. | Na investigação, as perícias passivas dos agentes **que não estão agindo** também comentam (Q1, vozes): cada jogador "ouve" a sua. | Novo. |

### Gaps
- Não achei fonte sobre como FTK 1 e 2 fazem os aliados próximos entrarem no combate (a página da wiki lida não cobre). Também não achei fonte sobre o co-op online de FTK2 (turnos compartilhados, ajuda).
- Não achei estudos ou telemetria sobre o tempo de espera no co-op por turno; os padrões vêm de regras e resenhas, não de medição.
- Não achei fonte primária sobre a intenção de Isaac Childres com o planejamento simultâneo; só a descrição da regra.

## 4. O que esses jogos fazem para tornar os membros do esquadrão memoráveis e suas mortes significativas?

### Takeaway
O apego nasce de **identidade visível** (nome, apelido, bandeira, retrato), **história escrita pelo jogador** (XCOM dá "adereços" em vez de biografia), **cicatrizes que persistem** (afflictions que se repetem em Darkest Dungeon, traços negativos e cansaço em XCOM 2, trauma permanente em Arkham LCG) e **laços entre personagens** (bonds de XCOM 2, relações de DD2). A morte pesa quando tem **ritual e memória** (o memorial de XCOM, com foto, missão e data) e quando **a campanha continua sem ela**: em Arkham LCG, o substituto começa sem XP.

### Cited Findings

#### XCOM: Enemy Unknown (Firaxis)
- O memorial fica no bar da base: as placas começam cinzas e ganham foto, nome, abates, operação e data quando um soldado morre. Toca uma gaita de foles, e copos de dose se acumulam com as mortes. — [Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627) (P)
- Jake Solomon diz que o jogo evita impor biografias e dá "adereços" para o jogador contar a própria história. Exemplo: um jogador inventou a história de dois soldados australianos chamados Lee que morreram juntos em Brisbane. — [Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627) (P)
- A bandeira do país de cada soldado vai bordada na gola e aparece nas corridas e nas câmeras de cobertura. Esquadrões pequenos (de quatro a seis) reforçam o laço com cada um. — [Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627) (P)
- Solomon conta que recarregou o jogo quando morreu sua coronel favorita, "Doc". O modo Ironman desliga o recarregar e torna cada decisão permanente. — [Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627) (P)
- Os soldados ganham um apelido ao chegar a certa patente. — [Kill Screen](https://www.killscreen.com/we-talked-man-who-remaking-xcom-finally/) (R)
- A 2K lançou um memorial no Facebook onde os jogadores postavam nome, detalhes e uma breve homenagem aos soldados mortos. — [Gaming Nexus](https://www.gamingnexus.com/FullNews/Memorial-app-lets-you-honor-your-fallen-XCOM-Enemy-Unknown-soldiers/Item28611.aspx) (R)

#### XCOM 2: War of the Chosen (Firaxis)
- Cada par de soldados tem uma compatibilidade que torna o laço mais provável em missões juntas. Em "momentos divisores", como resgatar um colega inconsciente ou perder mais da metade do esquadrão, a compatibilidade dispara. — [Fextralife](https://fextralife.com/?p=29352) (R)
- O laço é exclusivo até o parceiro morrer. O sobrevivente pode sofrer com a perda, mas se recupera e pode criar outro laço. Os níveis de laço dão habilidades de dupla, como uma ação extra compartilhada e o "Dual Strike". — [Fextralife](https://fextralife.com/?p=29352) (R); [Magic Game World](https://www.magicgameworld.com/?p=10686) (R)
- A Vontade cai com eventos (ver inimigos, presenciar mortes); abaixo de cerca de 66% o soldado fica Cansado, abaixo de 33% fica Abalado, e precisa de dias de descanso. — [XCOM Wiki, Tired or shaken](https://xcom.fandom.com/wiki/Tired_or_shaken_(War_of_the_Chosen)) (R); [Steam, discussão](https://steamcommunity.com/app/268500/discussions/0/1474221865192094656) (R)
- Traços negativos (medo de Sectoides, medo de errar tiros) são chances, não certezas, e podem causar pânico. Ficar ao lado do parceiro de laço ajuda a controlar o pânico. A cura é na Enfermaria e tira o soldado de rotação por alguns dias. — [XCOM Wiki, Negative Traits](https://xcom.fandom.com/wiki/Negative_Traits) (R); [Twinfinite](https://twinfinite.net/guides/xcom-2-war-chosen-how-negative-traits/) (R)

#### Darkest Dungeon 1 (Red Hook)
- O estresse vem de explorar sem comida ou luz, ver um aliado morrer ou se ferir e de ataques inimigos. Estresse alto causa aflições que atrapalham o herói (fugir, desobedecer ordens) ou, às vezes, Virtudes. As aflições ficam registradas, e o herói tende a repetir a mesma. Estresse extremo pode causar um ataque cardíaco. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon) (P)
- O vilarejo (Hamlet) cura aflições, reduz estresse, recruta e melhora heróis. Os heróis mortos se perdem para sempre. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon) (P)
- Um sistema de "falas" (barks) faz os heróis comentarem conforme o estresse e as aflições. Um narrador sem corpo, voz de Wayne June, comenta com sarcasmo para criar clima. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon) (P)
- Os autores queriam "brincar com a agência do jogador", lembrando que ele não controla o grupo inteiro. Queriam também que o jogador apoiasse os personagens em vez de caçar equipamento. O combate de lado foi pensado para aproximar o jogador dos personagens. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon) (P)
- Segundo a PC Gamer, Band of Brothers e Aliens inspiraram o jogo. — [PC Gamer](https://www.pcgamer.com/uk/how-darkest-dungeon-got-inspiration-from-band-of-brothers-and-aliens) (R; só o título e o resumo). Tyler Sigman apresentou na GDC 2016 o "Darkest Dungeon: A Design Postmortem". — [GDC Vault](https://www.gdcvault.com/play/1023089/contactUs) (R)
- Todas as falas e trailers foram escritos para a voz de Wayne June. Depois da morte dele, em 2025, Bourassa recusou recriar a voz com IA, mesmo com a permissão do ator. — [GameSpot](https://www.gamespot.com:443/articles/the-gothic-sensibilities-of-darkest-dungeon/1100-6424880/) (R); [80.lv](https://80.lv/articles/darkest-dungeon-creator-won-t-replace-late-narrator-with-ai-despite-his-permission/) (R)

#### Darkest Dungeon 2 (Red Hook)
- O jogo foca em como as circunstâncias sombrias moldam os laços entre os heróis, e gerir as relações é o foco central. — [Slant Magazine](https://slantmagazine.com/games/darkest-dungeon-ii-review) (R); [Zero Indent](https://zeroindent.com/darkestdungeon2/) (R)
- Atualizações posteriores amenizaram os problemas que relações e estresse causavam para vencer. — [PC Gamer, análise](https://pcgamer.com/darkest-dungeon-2-review) (R)
- Bourassa e Sigman descreveram a sequência como uma "viagem de família", menos brutal que o primeiro jogo. — [Wikipedia](https://en.wikipedia.org/wiki/Darkest_Dungeon_II) (R)

#### Arkham Horror LCG, FTK e Battle Brothers
- **Arkham LCG:** quem é derrotado por dano ou horror ganha **trauma** físico ou mental permanente, e derrotas repetidas enfraquecem o investigador na campanha. A derrota não acaba a campanha: o investigador ainda ganha XP. Em certos pontos, a falha pode matá-lo ou enlouquecê-lo, e o substituto começa sem XP. — [Wikipedia](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game) (P)
- **Arkham LCG:** cada baralho tem uma fraqueza própria do investigador e outra sorteada de um conjunto geral. — [Wikipedia](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game) (P)
- **FTK:** a morte de um personagem reduz o "pool de vidas" do grupo. — [FTK Wiki, Chaos](https://fortheking.wiki.gg/wiki/Chaos) (P)
- **Battle Brothers:** cada mercenário tem história de origem e traços (caçador de ratos, caçador de bruxas, nobre deserdado), sem classe rígida, e quem morre fica morto. — [Xbox Store](https://www.xbox.com/is-IS/games/store/battle-brothers/9NRN3D584LD3) (R)

### Inferences

| Padrão | Fonte | Por que funciona | Como mapear no OP | Sobreposição |
|---|---|---|---|---|
| **Memorial ritual** | XCOM | A morte ganha lugar e cerimônia; ver a parede crescer pesa mais que um texto. As placas cinzas antecipam a perda. | Na Base, uma **parede de memória da Ordem**: polaroide do agente, nome, NEX, caso, data e a "última frase" (o último registro do agente no relatório). Velas acesas por agente perdido. A cerimônia de NEX (docs/23) ganha um par: a cerimônia de despedida. | Novo. |
| **Adereços, não biografia** | XCOM | O jogador projeta a história; o que ele inventa pesa mais que um texto pronto. | Origem do livro (com `ref: "p.N"`), apelido escolhido pelo jogador, cidade natal e um **objeto pessoal** (um terço, um walkman) que aparece no modelo 3D e na polaroide. | Novo. |
| **Apelido merecido** | XCOM | Marco de identidade ligado ao feito. | Ao subir de patente ou depois de um feito (sobreviver com 1 PV, deduzir sozinho), o agente ganha um apelido do relatório ("a Que Viu o Lodo"), editável. | Novo. |
| **Laços por momento divisor** | XCOM 2, DD2 | O laço vem de algo que aconteceu na partida, não de um menu. A exclusividade faz a perda doer. | **Laços entre agentes**: sobem quando um socorre o outro (Caído, docs/39), quando dividem uma noite de cerco ou quando um sobrevive à morte do resto. Lado a lado, dão um bônus pequeno (por exemplo, +1 contra Medo). A morte do par gera uma perda de Sanidade e um traço de luto. Não chamar de "afinidade", que já é o termo do livro para elemento (docs/34). | Novo. |
| **Cicatriz que persiste** | DD1, XCOM 2, Arkham LCG | A personagem muda com a história, e o jogador lê a campanha no corpo dela. A repetição da mesma aflição vira personalidade. | Ao ficar perturbado (docs/49), o efeito de insanidade **tem chance de virar trauma**: uma fobia ligada ao elemento que a causou ("medo de Sangue"), que pode disparar em cenas futuras. A cura é na Base (psicólogo da Ordem, um interlúdio), e o agente fica fora de uma missão. | Estende docs/49 e docs/48. |
| **Cansaço que força o elenco** | XCOM 2 (Vontade) | Obriga a rodar o elenco, e mais agentes viram "conhecidos". | Depois de uma missão com perda de Sanidade, o agente fica "Abalado" e precisa de descanso. O jogador tem de levar outros agentes, o que espalha o apego. | Novo. |
| **Falas por estado** | DD1 (barks) | O personagem reage ao que acontece, então parece vivo. | Frases curtas dos agentes, conforme Sanidade, PV, laços e traumas, no mapa e no combate. Exemplo: "Não vou entrar nesse frigorífico de novo." | Novo. |
| **Uma voz de narrador** | DD1 | Uma voz única amarra o tom e faz cada perda soar épica ou trágica. | Um narrador (o arquivista da Ordem?) comenta o turno do mundo, a morte de agentes e o veredito. Bastam textos curtos com estilo; a voz gravada é opcional. | Liga-se à fase do Outro Lado (Q3). |
| **A campanha continua** | Arkham LCG, FTK | Perder não encerra a história; a morte vira capítulo, não game over. O substituto sem XP faz a perda ter custo. | Quando um agente morre, o recruta novo entra com NEX baixo, e os Pontos de Prestígio da Ordem bancam a reposição. Um "pool de reforços" por campanha, como as vidas de FTK, deixa claro quantas perdas a Ordem aguenta. | Novo. |
| **Origens com traços** | Battle Brothers | O recruta já chega com algo a contar. | Os recrutas vêm com a origem do livro (com `ref: "p.N"`) e dois traços sorteados, o mesmo roteiro de NPC que docs/51 propõe para testemunhas. | Reusa o roteiro de NPC de docs/51. |

**O que priorizar nesta pergunta:** o memorial e o objeto pessoal são baratos e dão retorno imediato. Laços e traumas mexem em regras e pedem um ADR. O cansaço só vale se o elenco da Base for grande o bastante para rodar.

### Gaps
- Não achei fonte primária de Firaxis com a intenção por trás dos laços de XCOM 2: a página oficial redirecionou, e o texto veio de sites que reproduzem o anúncio.
- Não achei fonte dos desenvolvedores de Battle Brothers sobre a intenção das origens e da morte permanente; só a descrição da loja.
- As páginas de DD2 (Zero Indent, Slant, PC Gamer) não abriram; o funcionamento detalhado das relações (como se formam, efeitos exatos) não foi confirmado.
- Não confirmei por fonte lida os limiares de estresse de DD1 (100 para aflição, 200 para ataque cardíaco); a Wikipedia lida não dá os números.
- Não achei estudo ou dado que meça o apego ao esquadrão (por exemplo, taxa de recarregar em XCOM); a evidência é de relatos e da intenção dos autores.
