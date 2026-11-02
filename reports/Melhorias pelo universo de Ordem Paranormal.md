# Licença e Elementos guiam a próxima etapa

Além do que a crítica de docs/51 já apontou, a lacuna mais urgente não é de design, é de licença. A **Licença da Comunidade de Ordem Paranormal v1.0 (28/06/2026)** proíbe usar a marca "Ordem Paranormal" e os nomes próprios do cânone ([licença](https://ordemparanormal.com.br/licenca)). Hoje, porém, o projeto se chama **"Ordem Paranormal: Fanmade (WIP)"** (`game/project.godot`) e dá às ameaças nomes canônicos como Zumbi de Sangue, Esqueleto de Lodo e Enraizado (`game/data/rulesets/op2022/ameacas.json`). Isso precisa ser resolvido antes de qualquer publicação, junto com o selo, os avisos e uma consulta ao canal oficial. No design, o recurso mais subaproveitado são os **cinco elementos**. A wiki dá a cada um paleta, matéria, comportamento de criatura, presságios, trilha sonora e um lugar num ciclo de fraquezas. Isso basta para que "qual elemento?" vire uma dedução que rende no combate, e para que o **Enigma de Medo** do chefe seja a recompensa do caso, e não um teste de DT. A rotina da Ordem descrita na wiki também dá estrutura autêntica à Base e às missões sem usar nenhum nome protegido: casos achados por varredura da internet, equipe de pesquisa a distância, credencial policial de fachada, investigação seguida de varredura e celas de contenção. As referências de design refinam docs/51 em pontos precisos: a confirmação em lote de Obra Dinn, o Ato contra a Agenda de Arkham Horror e o diretor com alívio de Alien: Isolation. Elas também cobrem três áreas que docs/51 não tocou: o co-op durante o turno dos outros, o apego e a morte dos agentes, e o som. O contexto favorece o projeto. O combate em tempo real foi o ponto fraco mais apontado de *Enigma do Medo*, e o mapa mental do jogo quebrou no lançamento. Um RPG tático com um quadro de dedução estável ocupa um espaço que a crítica deixou aberto. Ao todo são 4 itens P0, 13 P1 e o restante em P2 e P3. Cada um vem marcado como novo ou como refinamento de docs/51, com a base que o sustenta e um custo aproximado.

## Quatro bloqueios legais e treze apostas concentram o retorno

Cada recomendação tem um código por área:

| Código | Área |
|---|---|
| LI | licença e nome do jogo |
| EL | identidade dos elementos e criaturas |
| OR | Ordem, Base e missões |
| IN | investigação e dedução |
| ME | medo e ritmo |
| CO | co-op |
| AG | agentes, apego e morte |
| AU | áudio e apresentação |

As tabelas usam três marcações:

- **Coluna docs/51:** "Refina" quando o item detalha ou corrige algo que a crítica já propôs, e "Novo" quando o tema fica fora de docs/51. Se o item estende outro doc do projeto, esse doc aparece entre parênteses.
- **Prioridade:**
  - P0 bloqueia qualquer publicação.
  - P1 entra junto das prioridades de docs/51 e dá o maior retorno.
  - P2 aprofunda a identidade depois disso.
  - P3 é opcional ou depende de outra peça.
- **Custo**, relativo ao histórico do projeto:
  - Baixo: dados, texto ou ajuste de interface, sem regra nova.
  - Médio: regra ou sistema novo com interface e testes GUT, do porte de um doc numerado típico.
  - Alto: sistema que atravessa o jogo, rede online ou arte 3D em volume.

A ordem não segue só o impacto. Três itens P1 dependem do que docs/51 já pediu:

- A **confirmação em lote (IN1)** vira três chutes se cada traço não aparecer em dois candidatos ou mais.
- O **diretor com alívio (ME2)** impede que as ameaças que caçam virem desgaste.
- As **silhuetas por elemento (EL2)** usam a mesma modelagem da troca para agentes contemporâneos. Fazer as duas coisas juntas divide o custo.

Um princípio atravessa a lista. O caso já tem quem, o quê, onde e uma reviravolta. Os autores de Golden Idol contam que bateram num **teto de complexidade**, acima do qual o mistério deixa de divertir ([Thinky Games](https://thinkygames.com/features/how-the-case-of-the-golden-idol-developers-made-one-of-the-decades-best-detective-games-twice/)). Por isso, os itens P1 **trocam** peças que já existem em vez de somar novas:

- O elemento deduzido substitui o bônus fixo de −20% de PV que a pergunta "quem" dá hoje (`game/data/jogo/casos.json`).
- A trilha de progresso do caso substitui o contador "Pistas N", que docs/51 já achou enganoso.

| Prioridade | Código | Recomendação | docs/51 | Custo |
|---|---|---|---|---|
| P0 | LI1 | Tirar "Ordem Paranormal" do título e de tudo o que for público | Novo | Baixo |
| P0 | LI2 | Selo, aviso de conteúdo sensível, aviso de IA e página "Sobre/Licença" | Novo | Baixo |
| P0 | LI3 | Trocar nomes canônicos de criaturas e organizações por equivalentes próprios | Novo | Baixo a Médio |
| P0 | LI4 | Manter gratuito e sem coleta de dados; consultar o canal oficial; ADR | Novo | Baixo |
| P1 | EL1 | Corrigir a paleta: Energia em espectro neon, Medo sem cor | Refina | Baixo |
| P1 | EL2 | Silhueta e comportamento de combate por elemento | Refina | Médio a Alto |
| P1 | IN1 | Validar o trio quem/o quê/onde em lote | Refina | Médio |
| P1 | IN2 | Deduzir o elemento da ameaça e cobrar a fraqueza no combate | Novo | Médio |
| P1 | IN3 | Kit de detecção da Ordem como lentes do close-up da pista | Refina | Médio |
| P1 | IN4 | Chefe com Enigma de Medo resolvido pelas pistas do caso | Refina | Médio |
| P1 | IN5 | Mapa de rumores e contato da Pesquisa com dicas em camadas | Refina | Médio |
| P1 | ME1 | Ato contra Agenda: trilha do caso e linha do tempo que se pode atrasar | Refina | Médio |
| P1 | ME2 | Diretor com alívio para as ameaças que caçam | Refina | Médio |
| P1 | CO1 | Apoiar o teste do colega gastando PE ou item | Novo | Médio |
| P1 | AG1 | Parede de memória e cerimônia de despedida na Base | Novo | Baixo |
| P1 | AG2 | Apelido, cidade natal e objeto pessoal visível | Novo | Baixo |
| P1 | AU1 | Som em duas camadas e assinatura sonora por elemento | Novo | Médio |

Um aviso sobre as fontes. A wiki de Ordem Paranormal é mantida por fãs e tem uma categoria de conjecturas ([Wiki](https://ordemparanormal.fandom.com/wiki/Ordem_Paranormal_Wiki)). Onde ela diz "acredita-se", este relatório trata o dado como incerto. **Só a Morte tem assinaturas forenses canônicas.** As dos outros elementos, sugeridas abaixo, são invenção do projeto e devem ser marcadas assim. O livro pago não foi usado: os números de regra continuam vindo dele, com `ref: "p.N"`.

## Licença e nome do jogo: o título atual fere a licença de 2026

**A licença existe e está verificada.** A página `/licenca` mostra a versão 1.0, atualizada em 28/06/2026. Ela é concedida só por Rafael "Cellbit" Lange e se declara limitada, não exclusiva e revogável ([licença](https://ordemparanormal.com.br/licenca)). O lançamento foi noticiado no dia seguinte como iniciativa de Cellbit com a Jambô ([Joga o D20](https://jogaod20.com/2026/06/29/licenca-aberta-ordem-paranormal/)). A página inicial do site não tem link para a licença e mostra só "todos os direitos reservados" ([site oficial](https://ordemparanormal.com.br/)). Por isso uma das notas de pesquisa concluiu que não havia política para fãs. **Essa conclusão está superada.**

A licença libera os termos de sistema e alguns termos gerais do universo: atributos, classes, perícias, rituais, NEX, Membrana, Outro Lado, os cinco Elementos e Ordo Realitas. Proíbe:

- a marca "Ordem Paranormal" e os logos;
- a identidade visual oficial;
- textos e imagens dos livros;
- **nomes próprios do cânone**: personagens, organizações (exceto a Ordo Realitas), entidades, lugares e eventos.

E exige:

- o **selo da licença com pelo menos 10% da largura da capa**;
- um aviso de conteúdo sensível;
- em conteúdo gratuito com material gerado por IA, o aviso "Contém material gerado por inteligência artificial" junto ao selo;
- em conteúdo vendido, nenhuma IA;
- em aplicativos, respeito à LGPD.

Grupos fechados de até 10 pessoas não precisam da licença ([licença](https://ordemparanormal.com.br/licenca)). Isso libera o playtest com pessoas que docs/51 pede, desde que fique num grupo fechado de até 10, enquanto a publicação aberta espera a consulta oficial. As citações literais da licença nas notas vieram de uma ferramenta que resume páginas. Antes de levar alguma frase para material versionado, confira a redação exata no navegador.

O projeto hoje esbarra na licença em três pontos:

- **O título** usa a marca proibida.
- **O crédito em docs/03** não é o aviso que a licença pede. Além disso, docs/03 recomenda pedir autorização à Jambô, que não é a concedente.
- **As fichas de ameaça** usam nomes que têm página própria na wiki como criaturas do universo, por exemplo [Zumbis de Sangue](https://ordemparanormal.fandom.com/wiki/Zumbis_de_Sangue), [Esqueletos de Lodo](https://ordemparanormal.fandom.com/wiki/Esqueletos_de_Lodo) e [Anárquicos](https://ordemparanormal.fandom.com/wiki/An%C3%A1rquicos).

O texto da licença não diz se o nome de um tipo de criatura do livro conta como "entidade" (vedado) ou como terminologia de sistema (liberada). Mas a licença proíbe explorar lacunas e deixa os casos ambíguos para Cellbit decidir. A leitura segura é **renomear e manter os números**, sempre com `ref`. As notas de criaturas propõem equivalentes genéricos: "Tomado", "Fera de carne", "Costurado", "Ossudo de lodo", "Cadáver-raiz". O mesmo vale para as instituições canônicas:

- **C.R.I.S.** vira algo como "Central de Sinais".
- **O Setor de Crimes Inabituais** vira uma delegacia de fachada com nome próprio.
- **O título "Veríssimo"** vira uma coordenação com codinome inventado.
- **"Ordo Veritatis" e "Esoterroristas"** saem do jogo de vez. A própria franquia os trocou por virem do sistema *The Esoterrorists* ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)).

Há três perguntas abertas que só o canal oficial responde:

1. **Videogames não aparecem no texto.** A licença cita "aplicativos (incluindo plataformas VTT)" só como formato de venda de homebrew, e "apps" na cláusula da LGPD. A lista de conteúdo gratuito termina em "outros", o que é uma leitura favorável, mas não explícita. Para comparar: a Licença Aberta da Jambô exclui apps de forma expressa e manda os fãs de Ordem Paranormal para a licença do site oficial ([Jambô](https://jamboeditora.com.br/licenca-aberta/)).
2. **Não se sabe se "material gerado por IA" inclui código.** O projeto é feito com assistência de IA. Um sistema de fã para Foundry resolve isso declarando código assistido por IA e dizendo que regras, lore e arte não foram geradas ([SergioSJS](https://github.com/SergioSJS/ordem-paranormal-2e-fvtt)). A Joga o D20 descreve Cellbit como crítico declarado da IA generativa ([Joga o D20](https://jogaod20.com/2026/06/29/licenca-aberta-ordem-paranormal/)). Isso faz da IA o maior risco de imagem do projeto. Também é por isso que o jogo deve continuar gratuito: cobrar de qualquer forma o torna comercial, e aí qualquer material gerado por IA fica proibido.
3. **A licença só fala em "capa" e "thumbnail".** Levar o selo para a capa do itch.io e para a tela de título é inferência nossa.

Também fica sem resposta se "compatível com Ordem Paranormal" conta como uso da marca. O canal é a página de [contato](https://ordemparanormal.com.br/contato). O e-mail aparece atrás de um botão e precisa ser aberto à mão. Há precedentes de conformidade: um suplemento atualizou a capa para cumprir a licença ([devlog no itch.io](https://jxz8.itch.io/manualdoinvestigadorindependente/devlog/1575452/atualizao-para-a-licena-de-comunidade-ordem-paranormal)), e o plugin ATO20 exibe o selo e se declara não oficial ([ATO20](https://github.com/ato20-org/ato20.ordem-paranormal.plugin)).

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| LI1 | Renomear o jogo: título, tela de título e página da loja sem "Ordem Paranormal" nem nome que se confunda com ele. Não registrar domínio nem perfil com o nome. A descrição pode dizer que é conteúdo não oficial publicado sob a Licença da Comunidade (inferência). | Novo | Licença, parte 4 ([licença](https://ordemparanormal.com.br/licenca)) | Baixo | P0 |
| LI2 | Selo com pelo menos 10% da largura na capa do itch.io e na tela de título. Aviso de terror intenso antes de jogar, que pode ser um "termo de sigilo" diegético com texto próprio. Aviso de IA junto ao selo. Página "Sobre/Licença" no menu. Reescrever o crédito de docs/03. | Novo | Licença, parte 4; precedentes [ATO20](https://github.com/ato20-org/ato20.ordem-paranormal.plugin) e [SergioSJS](https://github.com/SergioSJS/ordem-paranormal-2e-fvtt) | Baixo | P0 |
| LI3 | Auditar `game/data` (ameaças, encontros, casos, campanha) e trocar nomes canônicos de criaturas, cultos e instituições por equivalentes próprios. Os números ficam, com `ref`. | Novo | Licença, parte 4; páginas da wiki de cada criatura | Baixo a Médio | P0 |
| LI4 | Manter o jogo gratuito e sem telemetria ou contas (LGPD). Perguntar pelo canal oficial sobre videogame, o alcance do aviso de IA e o lugar do selo. Registrar em ADR. Corrigir docs/03: quem concede é Cellbit, não a Jambô. | Novo | Licença, partes 1 a 4; [contato](https://ordemparanormal.com.br/contato) | Baixo | P0 |
| LI5 | ADR sobre a edição: ficar na 1ª ou preparar um ruleset `op2`. A comunidade de ferramentas já migra para o playtest de OP2, com dados por tamanho e Ímpeto. | Novo | [SergioSJS](https://github.com/SergioSJS/ordem-paranormal-2e-fvtt) | Baixo para decidir, Alto para implementar | P3 |

## Elementos e Ordem dão ao jogo uma gramática própria

### Identidade dos elementos e criaturas: silhueta e comportamento contam mais que a cor

Docs/51 pediu criaturas coloridas por elemento, e docs/09 segue a convenção da comunidade: "energia roxa, medo branco". A wiki corrige dois pontos:

- **Energia é um espectro neon.** O roxo é a base, alternando com azul, ciano, rosa e verde, numa "chama líquida" ([Energia](https://ordemparanormal.fandom.com/wiki/Energia)).
- **Medo não tem cor própria.** Aparece como uma chama transparente que distorce o que está em volta, e na névoa dos lugares onde a Membrana está danificada ([Medo](https://ordemparanormal.fandom.com/wiki/Medo)).

A Morte, por sua vez, é lodo preto com cinza, e não só cinza ([Morte](https://ordemparanormal.fandom.com/wiki/Morte)). Corrigir isso custa pouco. Na interface, o Medo pode ficar neutro para ser legível. No mundo, ele deve aparecer como refração, névoa e cor lavada.

Mais que a cor, o que importa é o **comportamento**, porque ele se lê na grade tática:

- **Sangue:** a maioria das criaturas é cega e se guia pelo tato. As mais avançadas se escondem e emboscam ([Sangue](https://ordemparanormal.fandom.com/wiki/Sangue); [Zumbis de Sangue](https://ordemparanormal.fandom.com/wiki/Zumbis_de_Sangue)). No jogo, a criatura mira quem se moveu no turno.
- **Morte:** as criaturas aceleram e desaceleram de modo errático, e **som alto as atordoa** ([Morte](https://ordemparanormal.fandom.com/wiki/Morte)). O projeto já tem a regra da poça de lodo que só fogo e Energia destroem (docs/01). Falta a velocidade errática e o atordoamento por som.
- **Conhecimento:** há criaturas que só atacam se atacadas e uma que só a vítima escolhida vê ([Ocioso](https://ordemparanormal.fandom.com/wiki/Ocioso)). Outra perde as habilidades sob luz forte ([Rastejador Sombrio](https://ordemparanormal.fandom.com/wiki/Rastejador_Sombrio)).
- **Energia:** há uma criatura cuja **ação a cada turno é sorteada** ([Anárquicos](https://ordemparanormal.fandom.com/wiki/An%C3%A1rquicos)).

Daí saem silhuetas fáceis de distinguir de longe:

| Elemento | Silhueta |
|---|---|
| Sangue | baixa e larga |
| Morte | alta e magra, com espirais |
| Conhecimento | ereta e imóvel, com máscara |
| Energia | instável e translúcida |

O melhor momento para fazer isso é junto com a troca de agentes que docs/51 pede.

Duas regras de lore guiam o que aparece em cada caso:

- **Ordem de chegada:** o Sangue é o elemento mais comum e o primeiro a atravessar quando a Membrana enfraquece ([Sangue](https://ordemparanormal.fandom.com/wiki/Sangue)). Então o começo do caso pode trazer encontros de Sangue, os outros elementos chegam conforme a Membrana cai, e o Medo vem por último. Basta mudar os pesos da tabela de encontros.
- **Origem das criaturas:** as entidades tomam a forma da ideia que causou o medo, seja uma lenda urbana, uma história ou o medo enorme de uma única pessoa ([Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo)). O gerador de casos pode escolher arquétipo e elemento a partir do "medo central" da cidade. O folclore brasileiro em domínio público serve de molde.

Os sigilos do Conhecimento funcionam como um alfabeto, e os símbolos de culto juntam o símbolo do elemento a um anel de sigilos ([Símbolos Ocultistas](https://ordemparanormal.fandom.com/wiki/S%C3%ADmbolos_Ocultistas)). Como o projeto já gera sigilos por código (docs/09), um símbolo de culto pode virar pista: o traço central diz o elemento, e o anel traz uma mensagem que um agente com Ocultismo traduz.

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| EL1 | Corrigir a paleta: Energia em espectro neon; Medo sem cor (distorção, névoa, cor lavada); Morte em preto e cinza | Refina (cores por elemento) | Lore: [Energia](https://ordemparanormal.fandom.com/wiki/Energia), [Medo](https://ordemparanormal.fandom.com/wiki/Medo), [Morte](https://ordemparanormal.fandom.com/wiki/Morte) | Baixo | P1 |
| EL2 | Silhueta e comportamento por elemento: Sangue cego que mira quem se moveu; Morte de velocidade errática e atordoada por som; Conhecimento passivo, visível a um só ou ferido por luz; Energia de ação sorteada | Refina (inimigos por elemento) | Lore: páginas acima e [Zumbis de Sangue](https://ordemparanormal.fandom.com/wiki/Zumbis_de_Sangue), [Ocioso](https://ordemparanormal.fandom.com/wiki/Ocioso), [Anárquicos](https://ordemparanormal.fandom.com/wiki/An%C3%A1rquicos) | Médio nas regras, Alto nos modelos 3D | P1 |
| EL3 | Ordem de chegada no caso: primeiro Sangue, depois os outros, e o Medo por último | Novo | Lore: [Sangue](https://ordemparanormal.fandom.com/wiki/Sangue) | Baixo | P2 |
| EL4 | Criatura gerada a partir do medo central do caso (lenda local, fobia de uma vítima, folclore em domínio público) | Novo | Lore: [Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo) | Médio | P2 |
| EL5 | Regras de desenho de sigilos por elemento; símbolo de culto com anel traduzível por Ocultismo | Novo (estende docs/09) | Lore: [Símbolos Ocultistas](https://ordemparanormal.fandom.com/wiki/S%C3%ADmbolos_Ocultistas) | Baixo a Médio | P2 |
| EL6 | Presságios por elemento a 1 ou 2 hexes: carcaça sem olhos (Sangue); relva cinza e relógio parado (Morte); cordas, máscaras e sino (Conhecimento); poste piscando e rádio ligando sozinho (Energia); névoa que avança (Medo) | Refina (antecipação no mapa) | Lore: páginas dos cinco elementos | Médio | P2 |

### Ordem, Base e missões: a rotina da Ordem vira estrutura sem nome protegido

Pela wiki, a Ordo Realitas é feita de gente comum com vida dupla. Ela recruta quem já teve contato com o paranormal e manda equipes de pelo menos três, com um veterano nos casos perigosos ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)). O jogo já respeita isso com o grupo de 3 ou mais agentes e as patentes. O que falta é a rotina:

- **Como os casos chegam.** Um programa varre a internet atrás de padrões: posts assustadores, notas em jornais pequenos, desaparecimentos ([C.R.I.S.](https://ordemparanormal.fandom.com/wiki/C.R.I.S.)). Nos casos oficiais, às vezes os recrutas vão só **para descobrir se o caso é mesmo paranormal** ([Casos Paranormais](https://ordemparanormal.fandom.com/wiki/Casos_Paranormais)). Na Base, os casos podem chegar como "sinais" com um nível de confiança. Alguns são alarmes falsos, que terminam em "não é paranormal" com recompensa menor.
- **A equipe de pesquisa.** Ela trabalha a distância e manda por telefone fichas de suspeitos, fotos de símbolos e a lista de moradores de um prédio ([Equipe de Pesquisa](https://ordemparanormal.fandom.com/wiki/Equipe_de_Pesquisa_da_Ordem)). Isso alimenta o contato de campo (IN5).
- **A credencial de fachada.** Uma falsa divisão policial dá acesso e jurisdição ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)). No jogo, vira uma opção social que **se queima** se for usada demais no mesmo caso.
- **Investigação e varredura.** Antes havia equipes que investigavam e equipes que vinham depois **eliminar tudo sem deixar rastros**. Depois da reforma, toda equipe faz as duas coisas ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)). Isso refina o covil como clímax de docs/51: fechado o caso, o grupo varre o covil por conta própria ou paga uma equipe de varredura. Uma varredura malfeita gera um evento de Medo mais tarde.

A **Base canônica** é um bar velho de fachada com salas que funcionam como serviços: ala médica, balcão de equipamentos, escritório com quadro de fios vermelhos, central de tecnologia, sala de ocultismo, laboratório forense e celas iluminadas só por uma vela, para que os presos não consigam se concentrar em símbolos ([Base da Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Base_da_Ordo_Realitas)). Isso dá forma concreta à "mesa da Ordem" de docs/51. Também dá destino aos cultistas vencidos sem matar (docs/40): presos na contenção, viram NPCs que podem ser interrogados entre missões. Os pontos de encontro canônicos são lugares banais, como um café com pedido-senha, um lava-rápido que guarda armas ou uma sala numa torre comercial ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)). O briefing pode mudar de lugar a cada missão, com nomes e senhas inventados.

Os **cultos** da wiki combinam sempre cinco coisas: um elemento, uma fachada banal, uma estrutura, um método de gerar medo e um sinal visual. Alguns exemplos:

- células de Sangue sem líder, com arame farpado, em lugares abandonados ([Transtornados](https://ordemparanormal.fandom.com/wiki/Transtornados));
- uma seita mascarada de mente coletiva, com túnica e corda ([Seita das Máscaras](https://ordemparanormal.fandom.com/wiki/Seita_das_M%C3%A1scaras));
- um culto que controla a polícia e a prefeitura de uma cidade por trás de uma santa local ([Sanguis Orchid](https://ordemparanormal.fandom.com/wiki/Sanguis_Orchid));
- uma empresa de fachada que liga cultos isolados e aparece primeiro em **recortes de jornal** ([Imobiliária Fachada](https://ordemparanormal.fandom.com/wiki/Imobili%C3%A1ria_Fachada)).

Isso dá um gerador de cultos em cinco eixos e um vilão que liga um caso ao outro na campanha. Cada temporada da série troca de subgênero: na ilha, cada episódio é um dia ([O Segredo na Ilha](https://ordemparanormal.fandom.com/wiki/O_Segredo_na_Ilha)), e o suplemento de sobrevivência traz perseguição, furtividade e recursos contados ([Sobrevivendo ao Horror](https://ordemparanormal.fandom.com/wiki/Ordem_Paranormal_RPG:_Sobrevivendo_ao_Horror)). Daí sai um modificador de subgênero por missão.

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| OR1 | Casos chegam como "sinais" de rede, com nível de confiança e alarmes falsos ("não é paranormal") | Novo | Lore: [C.R.I.S.](https://ordemparanormal.fandom.com/wiki/C.R.I.S.), [Casos Paranormais](https://ordemparanormal.fandom.com/wiki/Casos_Paranormais) | Médio | P2 |
| OR2 | Base como salas que prestam serviços: bar de fachada, enfermaria, arsenal, ocultismo, laboratório que transforma evidências em bônus, central de sinais, escritório com o quadro, contenção | Refina (mesa da Ordem) | Lore: [Base da Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Base_da_Ordo_Realitas) | Médio em 2D, Alto em 3D | P2 |
| OR3 | Briefing num local de fachada que muda, com senha de entrada própria | Novo | Lore: [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) | Baixo | P2 |
| OR4 | Credencial policial de fachada, com nome inventado, que se queima com o uso repetido | Novo | Lore: [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) | Baixo a Médio | P2 |
| OR5 | Varredura como fase final: limpar o covil com o próprio grupo ou pagar uma equipe com prestígio; varredura malfeita gera evento de Medo depois | Refina (covil como clímax) | Lore: [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) | Médio | P2 |
| OR6 | Gerador de cultos em cinco eixos e um vilão que liga os casos da campanha por recortes de jornal | Novo (estende docs/50) | Lore: [Transtornados](https://ordemparanormal.fandom.com/wiki/Transtornados), [Sanguis Orchid](https://ordemparanormal.fandom.com/wiki/Sanguis_Orchid), [Imobiliária Fachada](https://ordemparanormal.fandom.com/wiki/Imobili%C3%A1ria_Fachada) | Médio | P2 |
| OR7 | Modificador de subgênero por missão: slasher com perseguição e furtividade, ilha onde cada turno é um dia, granja com transmissões | Novo | Lore: [O Segredo na Ilha](https://ordemparanormal.fandom.com/wiki/O_Segredo_na_Ilha), [Sobrevivendo ao Horror](https://ordemparanormal.fandom.com/wiki/Ordem_Paranormal_RPG:_Sobrevivendo_ao_Horror) | Médio por subgênero | P3 |
| OR8 | Contenção: cultistas capturados viram NPCs interrogáveis entre missões | Novo (estende docs/40) | Lore: [Base da Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Base_da_Ordo_Realitas) | Médio | P3 |
| OR9 | Uma facção que observa o "Equilíbrio" intervém quando o grupo acumula poder demais | Novo | Lore: [Seita das Máscaras](https://ordemparanormal.fandom.com/wiki/Seita_das_M%C3%A1scaras) | Médio | P3 |

## Dedução e medo ganham prova, relógio e alívio

### Investigação e dedução: provar em lote e vencer pelo enigma

Docs/51 achou que uma pista sozinha resolve uma pergunta. A correção que propôs (todo traço em dois candidatos ou mais, e duas perguntas por cena) mexe na oferta de pistas. As referências de design atacam o outro lado, o da **verificação**:

- **Obra Dinn** só confirma os destinos em grupos de três, justamente para desestimular o chute ([Obra Dinn](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn)).
- **Golden Idol** criou o aviso "duas ou menos lacunas erradas". Os autores admitem que isso **reduziu a dificuldade e a duração do jogo** ([Game Developer](https://www.gamedeveloper.com/design/case-of-the-golden-idol)).

Daí sai a IN1: o quadro valida o trio quem/o quê/onde de uma vez. O erro custa Membrana uma vez e diz só que o relato não se sustenta. A reviravolta de docs/50 é validada num lote à parte. O aviso parcial depende da dificuldade: no Fácil, conta quantas peças estão erradas; no Pesadelo, não diz nada.

O **elemento** é a melhor recompensa que a lore oferece. Hoje o resumo do caso já entrega o elemento ("atividade paranormal ligada a Sangue", em `casos.json`). A lore, porém, define um ciclo fechado: Sangue vence Conhecimento, que vence Energia, que vence Morte, que vence Sangue. Cada elemento resiste a si mesmo, e o Medo é neutro ([Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo)). Energias comuns também ferem a Morte: fogo, eletricidade, luz UV e som alto ([Morte](https://ordemparanormal.fandom.com/wiki/Morte)). Phasmophobia mostra a forma de deduzir isso: cada fantasma tem 3 de 7 tipos de evidência, e as dificuldades altas escondem uma ([ExitLag](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/)).

Na IN2, o briefing deixa de dizer o elemento, e o grupo o deduz por presságios e assinaturas. Acertar libera a contramedida certa (ritual, munição ou item) no lugar do bônus fixo. Errar pode até ajudar a criatura, que resiste ao próprio elemento. Para não passar do teto de complexidade, o elemento entra **dentro de "o quê"** ou no efeito de "quem", e não como uma sexta pergunta.

O **close-up da pista** de docs/51 ganha ferramentas canônicas. A página da Morte lista sinais que um equipamento detecta:

- frio;
- um pó branco que forma espirais;
- no infravermelho, silhuetas que repetem o mesmo movimento;
- numa câmera modificada, vultos cinzentos;
- num rádio, ecos fora do tempo.

Ela também dá um cheiro de cinzas, enxofre e mofo ([Morte](https://ordemparanormal.fandom.com/wiki/Morte)). O Sangue tem cheiro de carne podre ([Sangue](https://ordemparanormal.fandom.com/wiki/Sangue)). Em *Enigma do Medo*, a lanterna UV revela mensagens escondidas ([Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/)). Se cada lente depender do item ou da perícia de um agente diferente, montar um grupo variado passa a valer a pena.

O **Enigma de Medo** é a versão canônica da dedução que rende no combate. Criaturas com Medo carregam um mistério ligado à sua origem. Resolvê-lo tira poderes da criatura ou a derrota, e duas criaturas do mesmo tipo podem ter soluções diferentes ([Medo](https://ordemparanormal.fandom.com/wiki/Medo)). A wiki registra vários tipos de solução:

- juntar as metades de um brinquedo ([Degolificada](https://ordemparanormal.fandom.com/wiki/Degolificada));
- fechar todas as saídas de água ([Mulher Afogada](https://ordemparanormal.fandom.com/wiki/Mulher_Afogada));
- fotografar o que é invisível ([Viajante](https://ordemparanormal.fandom.com/wiki/Viajante));
- destruir a fita amaldiçoada ([Telopsia](https://ordemparanormal.fandom.com/wiki/Telopsia));
- bloquear a fresta de onde a criatura sai ([O Espreitador](https://ordemparanormal.fandom.com/wiki/O_Espreitador)).

A criatura-modelo também **muda de elemento conforme o que o grupo faz**: se demoram atacando, vira Morte; se ela devora alguém, vira Sangue ([Degolificada](https://ordemparanormal.fandom.com/wiki/Degolificada)). Hoje o jogo trata o enigma como uma ação de decifrar, e cada pista reduz a DT (docs/01). A IN4 sorteia o tipo de solução de uma tabela, coloca a pergunta no quadro e faz o chefe se regenerar até o enigma ser resolvido. Assim, a "virada na metade dos PV" de docs/51 ganha uma razão de lore.

O **rumo do caso** de docs/51 pode virar uma teia permanente:

- O log de Outer Wilds mostra os pontos de interesse como uma rede de "rumores" ligados entre si ([SFRA Review](https://sfrareview.org/wp-content/uploads/2020/12/50.4.32.pdf)).
- O rádio de *Enigma do Medo* dá uma orientação geral a cada pista nova, nunca a solução ([Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/)).

O jogo pode desenhar fios tracejados de cada pista até um "?" numa região do mapa, e oferecer um contato da Pesquisa que dá dicas em camadas, cada uma com um custo (um turno do mundo ou ruído que atrai ameaças).

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| IN1 | Confirmação em lote do trio; reviravolta num lote à parte; aviso parcial conforme a dificuldade | Refina (dedução fácil demais) | Design: [Obra Dinn](https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn), [Golden Idol](https://www.gamedeveloper.com/design/case-of-the-golden-idol) | Médio | P1 |
| IN2 | Elemento da ameaça deduzido (fora do briefing) e cobrado pelo ciclo de fraquezas, dentro de "o quê" ou do efeito de "quem" | Novo | Lore: [Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo), [Morte](https://ordemparanormal.fandom.com/wiki/Morte); design: [Phasmophobia](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/) | Médio | P1 |
| IN3 | Kit de detecção como lentes do close-up (pó, câmera, infravermelho, rádio, UV), cada lente ligada a um item ou perícia; cheiro no texto | Refina (close-up da pista) | Lore: [Morte](https://ordemparanormal.fandom.com/wiki/Morte), [Sangue](https://ordemparanormal.fandom.com/wiki/Sangue); mídia: [Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/) | Médio | P1 |
| IN4 | Chefe com Enigma de Medo: solução sorteada de uma tabela, deduzida no quadro; o chefe se regenera até o enigma ser resolvido e muda de elemento conforme o grupo age | Refina (chefe e virada; docs/01) | Lore: [Medo](https://ordemparanormal.fandom.com/wiki/Medo), [Degolificada](https://ordemparanormal.fandom.com/wiki/Degolificada), [Telopsia](https://ordemparanormal.fandom.com/wiki/Telopsia) | Médio | P1 |
| IN5 | Mapa de rumores (fio tracejado até um "?" no mapa) e contato da Pesquisa com dicas em camadas e custo | Refina (rumo do caso) | Design: [Outer Wilds](https://sfrareview.org/wp-content/uploads/2020/12/50.4.32.pdf); mídia: [Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/); lore: [Equipe de Pesquisa](https://ordemparanormal.fandom.com/wiki/Equipe_de_Pesquisa_da_Ordem) | Médio | P1 |
| IN6 | Selo de "vasculhado" quando o local não tem mais pistas, e um Modo Detetive opcional em que o quadro não liga as pistas sozinho | Novo | Mídia: [Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/), [TecMundo](https://www.tecmundo.com.br/voxel/500299-review-enigma-do-medo-traz-o-tempero-brasileiro-para-o-mundo-do-terror.htm) | Baixo | P2 |
| IN7 | Três estados de pista: oculta, "descobrível" (silhueta com a perícia exigida) e aberta | Novo | Fã: [SergioSJS](https://github.com/SergioSJS/ordem-paranormal-2e-fvtt) | Baixo | P2 |
| IN8 | Relatório com lacunas e banco de palavras formado só pelas polaroides coletadas | Novo (liga-se ao close-up) | Design: [Golden Idol](https://www.gamedeveloper.com/design/case-of-the-golden-idol) | Médio | P2 |
| IN9 | Testemunhas que mandam mensagens entre turnos; uma testemunha aliada que é do culto; cidade com polícia e prefeitura do culto | Refina (testemunhas com nome) | Lore: [Sanguis Orchid](https://ordemparanormal.fandom.com/wiki/Sanguis_Orchid), [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) (traidores) | Médio | P2 |
| IN10 | Veredito depois da prova (entregar, encobrir, deixar fugir), com evidência anexada; o "outro lado" do dilema ganha desenvolvimento | Novo (estende docs/50) | Design: [Paradise Killer](https://selectbutton.com/reviews/paradise-killer-review); fãs: [fórum](https://ordemparanormal.fandom.com/f/p/4400000000000070723) | Baixo a Médio | P3 |
| IN11 | Perícias passivas que comentam a cena e teorias que o agente "rumina" | Novo | Design: [Disco Elysium](https://en.wikipedia.org/wiki/Disco_Elysium) | Médio | P3 |
| IN12 | Busca por palavra no arquivo da Ordem; dilema de registrar, porque relatos de medo fortalecem o Conhecimento | Novo | Design: [Her Story](https://en.wikipedia.org/wiki/Her_Story_(video_game)); lore: [Conhecimento](https://ordemparanormal.fandom.com/wiki/Conhecimento) | Médio | P3 |

### Medo e ritmo: relógios que o jogador consegue empurrar

Docs/51 já pede a linha do tempo do Outro Lado, ameaças que caçam e noite. As referências dizem como fazer isso sem cansar o jogador.

**Ato contra Agenda (Arkham Horror).** A Agenda é um relógio que avança a cada turno contra os investigadores. O Ato mede o progresso deles ([Arkham Horror LCG](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game)). A Membrana já faz o papel da Agenda. O que falta é o Ato: uma trilha de pistas firmes com limiares que liberam coisas, como o covil ou um aliado.

**Uma linha do tempo que se pode atrasar (For The King).** O Caos de FTK cai quando o grupo desativa geradores. Se não houver Caos à vista, some a próxima ocorrência ([FTK, Caos](https://fortheking.wiki.gg/wiki/Chaos)). Assim, os eventos da linha do tempo viram alvos: selar um sigilo, destruir um altar, salvar uma testemunha.

**O diretor de Alien: Isolation.** Ele mede a tensão pela proximidade. No pico, manda a criatura para os bastidores para o jogador respirar. Comportamentos novos só surgem por ações do jogador, nunca por mortes, e a criatura quase nunca se teletransporta ([Game Developer](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation)). **Sem esse alívio, a ameaça que caça vira desgaste**, e esse é o refinamento mais importante de docs/51.

**A noite (Darkwood e a série).** Em Darkwood, de dia o jogador explora e se prepara, e de noite se defende num esconderijo ([Darkwood](https://en.wikipedia.org/wiki/Darkwood)). À noite, cada agente escolhe entre fortificar um abrigo ou ficar no mato e ser caçado. Para casos curtos, "cada turno do mundo é um dia", como em *O Segredo na Ilha* ([O Segredo na Ilha](https://ordemparanormal.fandom.com/wiki/O_Segredo_na_Ilha)).

**A Membrana fica local e visível.** Pela lore, o dano à Membrana é **localizado** e mostra sinais: névoa fora do normal, temperatura que não bate, alucinações compartilhadas, tempo distorcido e plantas e animais mutados ([Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo)). Cada sinal pode virar um efeito em zonas de Membrana fina no mapa. A lore, porém, não descreve nenhum jeito de **consertar** a Membrana. Qualquer ação que segure o dano (cobrir um símbolo, acalmar uma testemunha) é invenção do projeto.

**Outros padrões:**

- **Presságio previsto.** Em Eldritch Horror, o jogador sabe qual presságio vem a seguir ([Board Game Quest](https://boardgamequest.com/eldritch-horror-board-game-review)). No jogo, isso vira uma roda de elementos: "na próxima noite, Morte".
- **Virada por probabilidade.** Em Betrayal, cada presságio aumenta a chance de a casa virar ([Betrayal](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill)). A reviravolta de docs/50 pode deixar de ter hora marcada.
- **Sobreviver também vale.** O próprio criador lembrou que algumas temporadas são sobre sobreviver, não combater ([newsletter jul/2025](https://ordemparanormal.com.br/newsletter/julho-2025)). Fugir, se esconder e recuar devem ser opções de primeira linha, com recompensa real.
- **Sanidade sugerida.** Amnesia trocou os números da sanidade por sinais de som e imagem. Alguns jogadores mal notavam a sanidade, e outros ficavam presos com ela baixa ([Game Developer](https://www.gamedeveloper.com/design/game-design-deep-dive-i-amnesia-i-s-sanity-meter-)). Dark Corners devolve sanidade quando o jogador faz o bem ([Dark Corners](https://en.wikipedia.org/wiki/Call_of_Cthulhu:_Dark_Corners_of_the_Earth)). A SAN exata fica na ficha, como o livro pede. No mapa, aparecem sinais.

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| ME1 | Ato contra Agenda: trilha do caso com limiares no lugar do contador "Pistas N"; ameaças no mapa somam ao desgaste da Membrana; eventos da linha do tempo podem ser removidos | Refina (linha do tempo) | Design: [Arkham LCG](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game), [FTK](https://fortheking.wiki.gg/wiki/Chaos) | Médio | P1 |
| ME2 | Diretor com alívio: medidor de pressão escondido, recuo para a névoa no pico, sem teletransporte, rastro visível antes do encontro | Refina (ameaças que caçam) | Design: [Alien: Isolation](https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation) | Médio | P1 |
| ME3 | Noite de escolha (fortificar abrigo ou ser caçado no mato); casos curtos em que cada turno é um dia | Refina (noite) | Design: [Darkwood](https://en.wikipedia.org/wiki/Darkwood); lore: [O Segredo na Ilha](https://ordemparanormal.fandom.com/wiki/O_Segredo_na_Ilha) | Médio | P2 |
| ME4 | Membrana local, com os sinais da lore como efeitos no mapa e fontes de dano ligadas ao caso | Novo (estende docs/22) | Lore: [Ocultismo](https://ordemparanormal.fandom.com/wiki/Ocultismo) | Médio | P2 |
| ME5 | Roda de presságio por elemento, com o próximo à vista | Novo | Design: [Eldritch Horror](https://boardgamequest.com/eldritch-horror-board-game-review) | Baixo a Médio | P2 |
| ME6 | Reviravolta com chance que cresce a cada presságio coletado | Novo (estende docs/50) | Design: [Betrayal](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill) | Médio | P2 |
| ME7 | Fugir, se esconder e recuar com recompensa real (perseguição e furtividade) | Novo | Mídia: [newsletter](https://ordemparanormal.com.br/newsletter/julho-2025); lore: [Sobrevivendo ao Horror](https://ordemparanormal.fandom.com/wiki/Ordem_Paranormal_RPG:_Sobrevivendo_ao_Horror) | Médio | P2 |
| ME8 | Sanidade com sinais no mapa (respiração, vinheta, tiques) e recuperação por boas ações | Novo (estende docs/49) | Design: [Amnesia](https://www.gamedeveloper.com/design/game-design-deep-dive-i-amnesia-i-s-sanity-meter-), [Dark Corners](https://en.wikipedia.org/wiki/Call_of_Cthulhu:_Dark_Corners_of_the_Earth) | Baixo a Médio | P2 |
| ME9 | Luz como recurso: a câmera ou lanterna revela pontos no escuro e gasta bateria, com limite por dificuldade | Novo (usa a moldura REC) | Design: [Outlast](https://en.wikipedia.org/wiki/Outlast), [Darkest Dungeon 2](https://zeroindent.com/darkestdungeon2/) | Médio | P3 |
| ME10 | Falha de interface só com criaturas de Energia e SAN baixa; opcional, e o jogo revela depois que foi truque | Novo | Design: [Eternal Darkness](https://en.wikipedia.org/wiki/Eternal_Darkness); lore: [Energia](https://ordemparanormal.fandom.com/wiki/Energia) | Baixo | P3 |
| ME11 | Locais adormecidos que podem ser selados antes de despertar | Novo | Design: [FTK, Flagelos](https://fortheking.wiki.gg/wiki/Scourge) | Médio | P3 |

## Pessoas no centro: a mesa e os mortos

### Co-op: quem espera o turno precisa ter o que decidir

Docs/51 não tratou do co-op, embora o jogo tenha co-op local por dono de agente (ADR 0004) e sala online por código (docs/29). As referências convergem num ponto: **dar ao jogador parado uma decisão no turno alheio**.

- **Arkham Horror LCG:** cada investigador no mesmo local pode gastar uma carta no teste do colega ([fórum FFG](https://ffg-forum-archive.entropicdreams.com/topic/236873-card-use/)).
- **Gloomhaven:** todos planejam ao mesmo tempo e revelam juntos ([Gloomhaven](https://en.wikipedia.org/wiki/Gloomhaven_(video_game))).
- **Mansions of Madness:** o app narra a fase dos monstros, que todos assistem. Enlouquecer pode dar a um investigador um objetivo pessoal contra o grupo. A família da resenha espelhou o app na TV, porque um aparelho só deixava gente de fora ([The Board Game Family](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/)).

O universo nasceu ao vivo. O especial Quarentena teve **215 mil espectadores simultâneos**, acima dos 212 mil de Critical Role ([Mesa de RPG](https://mesaderpg.com.br/ordem-paranormal/ordem-paranormal-quarentena-bate-recorde-do-critical-role-na-twitch/)). Um modo pensado para jogar diante de uma plateia é uma aposta barata. É, porém, inferência nossa, e não um pedido dos fãs.

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| CO1 | Apoiar o teste do colega: agentes no mesmo hex ou cena gastam 1 PE ou um item para somar bônus (conferir a regra de ajuda do livro e registrar o `ref`) | Novo | Design: [Arkham LCG](https://ffg-forum-archive.entropicdreams.com/topic/236873-card-use/) | Médio | P1 |
| CO2 | Turno do mundo como cena curta que todos assistem juntos | Refina (o turno do mundo vira momento) | Design: [Mansions](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) | Baixo a Médio | P2 |
| CO3 | Quadro compartilhado online, com fio de cor por agente e voto da maioria para validar o lote | Novo (depende de IN1) | Design: [Phasmophobia](https://www.exitlag.com/blog/phasmophobia-cheat-sheet/) | Médio | P2 |
| CO4 | Modo mesa e transmissão: rolagens grandes, ficha resumida, spoilers do quadro escondidos, texto legível de longe | Novo (estende a acessibilidade de docs/51) | Mídia: [Mesa de RPG](https://mesaderpg.com.br/ordem-paranormal/ordem-paranormal-quarentena-bate-recorde-do-critical-role-na-twitch/); design: [Mansions](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/) | Baixo a Médio | P2 |
| CO5 | Pista pessoal que precisa ser compartilhada, primeiro só no online, porque no hotseat só somaria cliques | Novo | Fã: [SergioSJS](https://github.com/SergioSJS/ordem-paranormal-2e-fvtt) | Médio | P3 |
| CO6 | Objetivo secreto ao enlouquecer, ou possessão na reviravolta, primeiro só no online | Novo (estende docs/49 e docs/50) | Design: [Mansions](https://www.theboardgamefamily.com/2017/04/mansions-of-madness-board-game-review/), [Betrayal](https://en.wikipedia.org/wiki/Betrayal_at_House_on_the_Hill) | Médio | P3 |
| CO7 | Planejar junto e revelar junto no combate, como opção | Novo | Design: [Gloomhaven](https://en.wikipedia.org/wiki/Gloomhaven_(video_game)) | Alto | P3 |

### Agentes, apego e morte: a mortalidade é a marca da franquia

Na lore, quase todas as equipes listadas aparecem como "dissolvidas", e ex-agentes viram traidores ou criaturas ([Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas)). A primeira equipe perdeu dois de quatro membros no primeiro caso ([Equipe de Varredura](https://ordemparanormal.fandom.com/wiki/Equipe_de_Varredura)). Os fãs mantêm uma página que registra as mortes, inclusive as falsas ([Mortes](https://ordemparanormal.fandom.com/wiki/Mortes)). Um artigo de opinião explica o apego por dois motivos: os protagonistas são pessoas comuns com traumas, e as relações nascem dentro do jogo, como numa novela ([Lab J/PUCRS](https://labjornalismo.pucrs.br/conteudo/opiniao-ordem-paranormal-e-rpg-que-une-geracoes-atraves-do-medo/)). Na campanha de *Enigma do Medo*, apoiadores pagaram para ter **lápides com o próprio nome** no cemitério do jogo ([Catarse](https://catarse.com.br/ordem)).

O projeto já tem memorial no relatório, Reforços da Ordem e cerimônia de NEX (docs/02, docs/23). Falta dar ritual e identidade a isso:

- **O memorial de XCOM** fica no bar da base: placas cinzas ganham foto, operação e data quando um soldado morre ([Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627)).
- **Jake Solomon** diz que o jogo dá "adereços" em vez de biografias, para o jogador inventar a história ([Kotaku](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627)).
- **XCOM 2** cria laços entre soldados em momentos decisivos. O laço é exclusivo até o parceiro morrer ([Fextralife](https://fextralife.com/?p=29352)).
- **Darkest Dungeon** registra as aflições, que tendem a se repetir, e faz os heróis comentarem o que acontece ([Darkest Dungeon](https://en.wikipedia.org/wiki/Darkest_Dungeon)).
- **Na série**, cada jogador tem uma Marca que passa ao próximo personagem quando o anterior morre ([Marcas](https://ordemparanormal.fandom.com/wiki/Marcas)). Isso é uma meta-progressão pronta, desde que tenha nome e símbolo próprios.
- **Em *Enigma do Medo***, ficar perto do cão ajuda a manter a sanidade ([Steam](https://store.steampowered.com/app/1507580/Enigma_of_Fear/)). Jogadores reclamaram de não poder fazer carinho nele ([Steam, discussão](https://steamcommunity.com/app/1507580/discussions/0/4633736978453569401/)).

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| AG1 | Parede de memória na Base (polaroide, nome, NEX, caso, data, causa, último registro, vela) e uma cerimônia de despedida, par da cerimônia de NEX | Novo (amplia o memorial de docs/02 e docs/23) | Design: [XCOM](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627); mídia: [Catarse](https://catarse.com.br/ordem); lore: [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) | Baixo | P1 |
| AG2 | Adereços em vez de biografia: apelido escolhido ou ganho por um feito, cidade natal e um objeto pessoal visível no modelo e na polaroide; um apego (foto, objeto, animal da Base) que recupera SAN no interlúdio | Novo (casa com os agentes contemporâneos de docs/51) | Design: [XCOM](https://kotaku.com/remembering-the-fallen-and-the-decisions-for-which-the-5916627); mídia: [Steam](https://store.steampowered.com/app/1507580/Enigma_of_Fear/) | Baixo | P1 |
| AG3 | Laços entre agentes nascidos de um momento decisivo (socorrer um Caído, uma noite de cerco), com bônus pequeno lado a lado e luto quando o par morre; o nome não pode ser "afinidade", que já é termo do livro | Novo (pede ADR) | Design: [XCOM 2](https://fextralife.com/?p=29352); fãs: [Lab J](https://labjornalismo.pucrs.br/conteudo/opiniao-ordem-paranormal-e-rpg-que-une-geracoes-atraves-do-medo/) | Médio | P2 |
| AG4 | Trauma que fica: o efeito de insanidade tem chance de virar fobia do elemento, tratada na Base com o agente fora de uma missão | Novo (estende docs/48 e docs/49) | Design: [Darkest Dungeon](https://en.wikipedia.org/wiki/Darkest_Dungeon), [Arkham LCG](https://en.wikipedia.org/wiki/Arkham_Horror:_The_Card_Game) | Médio | P2 |
| AG5 | Uma marca por vaga de jogador, com nome próprio, que sobrevive à morte do agente e passa uma mensagem ao recruta; traço do elemento no retrato aos 50% de NEX | Novo | Lore: [Marcas](https://ordemparanormal.fandom.com/wiki/Marcas) | Médio | P2 |
| AG6 | Falas curtas conforme o estado (SAN, PV, laços, traumas) | Novo | Design: [Darkest Dungeon](https://en.wikipedia.org/wiki/Darkest_Dungeon) | Baixo a Médio | P2 |
| AG7 | Ex-agentes do próprio jogador voltam: quem enlouqueceu ou transcendeu reaparece como inimigo, preso ou traidor | Novo | Lore: [Ordo Realitas](https://ordemparanormal.fandom.com/wiki/Ordo_Realitas) | Médio | P3 |
| AG8 | Cansaço que obriga a revezar os agentes (o grupo tem até 8) | Novo | Design: [XCOM 2](https://xcom.fandom.com/wiki/Negative_Traits) | Baixo | P3 |

## Áudio e apresentação: o som do Outro Lado e as lições de Enigma do Medo

Docs/11 decidiu que todos os sons são sintetizados em código e deixou os **sons por elemento** para depois. A lore dá um gênero de trilha para cada elemento:

| Elemento | Trilha na lore | Fonte |
|---|---|---|
| Sangue | metal | [Sangue](https://ordemparanormal.fandom.com/wiki/Sangue) |
| Morte | notas invertidas e ritmo lento, com violino e piano | [Morte](https://ordemparanormal.fandom.com/wiki/Morte) |
| Conhecimento | coros e sussurros, num tom religioso | [Conhecimento](https://ordemparanormal.fandom.com/wiki/Conhecimento) |
| Energia | guitarra elétrica e sintetizador | [Energia](https://ordemparanormal.fandom.com/wiki/Energia) |
| Medo | só um piano, com melodias estranhas | [Medo](https://ordemparanormal.fandom.com/wiki/Medo) |

Algumas criaturas também têm sons descritos, como falas e rugidos tocados ao contrário ([Esqueletos de Lodo](https://ordemparanormal.fandom.com/wiki/Esqueletos_de_Lodo)) e um sino distorcido com eco sintético ([Silhueta](https://ordemparanormal.fandom.com/wiki/Silhueta)). O jogo oficial mistura piano, cordas e sintetizadores sombrios ([Indie Game Reviewer](https://indiegamereviewer.com/enigma-of-fear-review/)). Disso sai o desenho em duas camadas:

- **a Realidade é acústica**, com piano e cordas sintetizados;
- **o Outro Lado é sintético** e cresce conforme a Membrana racha;
- **cada elemento tem um timbre próprio** por cima.

Tocar um som ao contrário custa quase nada num áudio feito por código. A trilha oficial está fora de cogitação: a licença só a libera para lives, vídeos e podcasts ([licença](https://ordemparanormal.com.br/licenca)).

As críticas a *Enigma do Medo* funcionam como lista do que evitar:

- **Paleta clara e saturada.** Ela enfraqueceu o horror, a barra de vida feita de manchas vermelhas piscando confundiu, e um menu revelava a solução de um enigma ([Gamerview](https://gamerview.com.br/reviews/enigma-do-medo-review/)).
- **Chefes sem apresentação e leitura demais.** Um jogador disse que os chefes não tinham apresentação e que o excesso de documentos fazia o jogo parecer mais longo do que era ([Steam, discussão](https://steamcommunity.com/app/1507580/discussions/0/4633736978453569401/)).
- **A peça central quebrou.** O mapa mental, recurso de assinatura do jogo, falhou e foi desativado num hotfix ([Recanto do Dragão](https://recantododragao.com.br/enigma-do-medo-a-puberdade-de-um-estudio-analise/); [Critical Hits](https://criticalhits.com.br/reviews/enigma-do-medo-analise-vale-a-pena-review/)).

Do lado da série vêm dois rituais. As temporadas abrem com uma frase-tema que se repete ([Sinais do Outro Lado](https://ordemparanormal.fandom.com/wiki/Sinais_do_Outro_Lado)). E as estreias caem perto do Halloween, como em 31/10/2020 e 25/10/2025, com um especial de Natal ([Wikipedia](https://pt.wikipedia.org/wiki/Ordem_Paranormal)). Isso sugere casos sazonais, que as missões da comunidade (docs/04) já comportam.

| Código | Recomendação | docs/51 | Base | Custo | Prioridade |
|---|---|---|---|---|---|
| AU1 | Som em duas camadas (Realidade acústica, Outro Lado sintético que cresce com a Membrana) e assinatura por elemento: metal e respiração molhada; sons invertidos e tique-taque irregular; sussurros e sino com eco; estática e risada distorcida; silêncio e piano solo | Novo (completa docs/11) | Lore: páginas dos cinco elementos; mídia: [IGR](https://indiegamereviewer.com/enigma-of-fear-review/) | Médio | P1 |
| AU2 | Apresentação do chefe: ficha de dossiê revelada, nome em cartão, troca de trilha | Refina (covil e chefe) | Mídia: [Steam, discussão](https://steamcommunity.com/app/1507580/discussions/0/4633736978453569401/) | Baixo | P2 |
| AU3 | Cor só para o paranormal: mapa e combate com cor lavada, e a cor do elemento só quando o Outro Lado se manifesta | Refina (realce saturado e clima) | Mídia: [Gamerview](https://gamerview.com.br/reviews/enigma-do-medo-review/) | Baixo | P2 |
| AU4 | Limite de texto por pista, resumo automático no quadro e nenhuma solução revelada por dica de interface ou menu | Novo | Mídia: [Gamerview](https://gamerview.com.br/reviews/enigma-do-medo-review/), [Steam, discussão](https://steamcommunity.com/app/1507580/discussions/0/4633736978453569401/) | Baixo | P2 |
| AU5 | Testes GUT do quadro (salvar, carregar, ligar pistas) como condição para lançar | Novo | Mídia: [Recanto do Dragão](https://recantododragao.com.br/enigma-do-medo-a-puberdade-de-um-estudio-analise/) | Baixo | P2 |
| AU6 | Abertura de missão com frase-tema própria e premissa no formato "lugar banal + evento estranho + quem chamou a Ordem" | Novo | Lore: [Sinais do Outro Lado](https://ordemparanormal.fandom.com/wiki/Sinais_do_Outro_Lado) | Baixo | P2 |
| AU7 | Casos sazonais (Halloween, Natal) pelas missões da comunidade | Novo (usa docs/04) | Mídia: [Wikipedia](https://pt.wikipedia.org/wiki/Ordem_Paranormal) | Baixo por caso | P3 |
| AU8 | Inglês e espanhol cedo, aproveitando os dados em JSON | Novo | Mídia: [Steam](https://store.steampowered.com/app/1507580/Enigma_of_Fear/) (8 idiomas) | Médio a Alto | P3 |
| AU9 | Ficha exportável como imagem; segredos só dentro do jogo; a página anuncia só o que já dá para jogar | Novo | Mídia: [Gamerview](https://gamerview.com.br/reviews/enigma-do-medo-review/), [Steam, discussão](https://steamcommunity.com/app/1507580/discussions/0/4633736978453569401/) | Baixo | P3 |

## Conclusão

O fio que une lore e referências de design é um só. Docs/51 tratou investigação, mapa e combate como três problemas separados: pista demais, terror sem antecipação e chefe genérico. O universo de Ordem Paranormal mostra que são **uma corrente só, costurada pelo elemento**. O presságio no mapa sugere o elemento. O close-up com o kit o confirma. A dedução em lote o prova. O ciclo de fraquezas e o Enigma de Medo cobram o acerto no combate. Implementar essa corrente vale mais que qualquer item isolado. Ela também responde ao teto de complexidade, porque troca bônus genéricos por recompensas com sentido, em vez de somar perguntas.

A licença muda o enquadramento do projeto mais do que parece. A identidade "de Ordem Paranormal" precisa vir do **vocabulário de sistema liberado** e de uma linguagem visual e sonora própria, e não da marca nem dos nomes do cânone. E manter o jogo **gratuito** deixa de ser só preferência: é a condição que mantém o desenvolvimento com IA compatível com a licença. Resolvido o P0, o espaço é favorável. Os jogos de fã existentes são pequenos, como jams, uma visual novel e um micro-RPG ([Sinfonia dos Amalgamados](https://lekeu.itch.io/ordem-paranormal-sinfonia-dos-amalgamados)), e o jogo oficial deixou o combate tático por fazer. A vaga é de quem chegar com conformidade, estabilidade e mortes que os jogadores queiram lembrar.
