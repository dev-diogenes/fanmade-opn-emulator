# Crítica de design: o terror nas telas

> Status: **v0.1**, 02/11/2026. Pedido do dono do projeto: "Dê um print em todas as telas, pesquise e analise a melhora do design do jogo considerando que é terror/suspense". São 16 capturas, de uma carreira nova, em 1152×648:
>
> - título, aviso de conteúdo e Sobre;
> - as seis abas da Base e o convite do tutorial;
> - mapa, arquivo do caso e Pausa;
> - investigação, combate, saguão online e editor.
>
> Ela complementa as críticas anteriores (docs/15, 20, 51 e 57), que trataram de usabilidade e contraste. Esta mede **o clima**.

## Impressão geral

O jogo tem uma identidade forte e coerente: o dossiê da Ordem, os papéis datilografados, os sigilos, a moldura de REC na investigação e o aviso de conteúdo antes de tudo. Isso já parece Ordem sem copiar a Ordem. **O maior problema é que a luz está ao contrário.** As telas mais claras do jogo são a Base e o combate. A Base é o lugar seguro, e o combate é onde o medo deveria chegar ao pico.

## As medições

| Tela | Luminância média (0-255) | Área clara (>180) | Área escura (<40) | Saturação | Leitura |
|---|---|---|---|---|---|
| Base, aba Missão | **101** | **36%** | 49% | 67 | Mais clara que qualquer tela de jogo. O papel claro grande domina |
| Base, aba Agentes | **95** | **35%** | 53% | 68 | Idem: a ficha é uma folha branca enorme |
| Base, aba Arsenal | 79 | 27% | 63% | 68 | Cartões de papel em grade, muito claro |
| **Combate** | **63** | 9% | **34%** | **104** | O chão azul-acinzentado iluminado por igual. O clímax é a tela menos escura |
| Investigação | 58 | 16% | 74% | 64 | Boa: escuro, com o que importa aceso |
| Mapa | 26 | 1% | 81% | **145** | Escuro, mas o verde dos hexes é saturado e vivo |
| Título | 46 | 18% | 78% | 69 | Boa |

**A regra que as referências apontam:** no terror, a escuridão é **informação perdida**, não só uma luz mais fraca. A luz é o primeiro termômetro da tensão (Striking Distance, sobre The Callisto Protocol), e a tensão está no momento a momento (Silent Hill f). Darkest Dungeon transforma isso em mecânica: menos luz traz mais perigo e mais recompensa. Dead Space e Signalis escondem a interface no mundo para não haver uma "barreira de segurança" entre o jogador e o horror.

## Por tela

### Título e aviso de conteúdo
- ✅ O aviso de conteúdo antes do título, em papel e com "Sair do jogo" do lado, já cria clima e cumpre a licença.
- ✅ O sigilo vermelho riscado atrás do nome e o selo no canto funcionam.
- 🟢 Os itens do menu em versalete claro sobre fundo quase preto são legíveis. A barra decorativa sob "MEMBRANA" poderia "sangrar" devagar, como se o traço fosse vivo, mas isso é polimento.

### Base
- 🔴 **O papel claro ocupa um terço da tela nas abas Missão, Agentes e Arsenal.** Numa sala de arquivo à noite, a folha deveria estar sob a luz de uma luminária, com as bordas caindo para o escuro. Hoje ela parece um formulário iluminado por igual.
- 🟡 A aba **Base** (o bar de fachada em 3D) é a mais atmosférica do jogo, com lum 21 e luz vermelha. Mas é a menos visitada, porque a Base abre na aba Missão.
- 🟡 **Bordas douradas em tudo:** abas, listas, botões, painéis e cartões. Quando tudo tem moldura, nada tem destaque. Em terror, o ornamento dourado lembra fantasia medieval, que o docs/51 já criticou nas miniaturas.
- 🟢 **Memorial vazio:** "Ninguém na parede, ainda. Que continue assim." é ótimo. Uma parede com pregos vazios e marcas de retrato tirado diria isso sem texto.

### Mapa
- 🔴 **O verde dos hexes (saturação 145) é o de um jogo de fantasia alegre.** O relatório de pesquisa já pedia, no AU3, "cor lavada no mundo e a cor do elemento só quando o Outro Lado se manifesta". Com o mapa dessaturado, o vermelho de um rastro de Sangue ou o roxo neon de Energia gritariam.
- 🟡 **Cinco painéis com moldura dourada ao mesmo tempo:** vez, caso, Membrana, registro e dock. O docs/51 já pedia menos modais, e o mesmo vale para o HUD sempre visível. Em repouso, o caso e o registro poderiam recolher-se a uma aba.
- 🟢 O arquivo do caso agora abre com a frase-tema (docs/79). O papel ocupa a altura toda: fica bom, mas no limite.

### Investigação
- ✅ **É a tela mais "de terror":** escuro, os personagens no círculo de luz, o REC no canto, a testemunha na janela.
- 🟡 **Os círculos de sigilo dourados no chão são grandes e saturados demais.** Dizem "clique aqui" com força de interface, não de achado. Se brilhassem fraco e só acendessem quando um agente se aproxima, a lanterna viraria a mecânica.

### Combate
- 🔴 **Arena iluminada por igual, chão azul claro e 34% de área escura.** É a tela menos ameaçadora, e é onde a criatura está. Sem breu, não há o que temer do outro lado da grade.
- 🟡 **Barra de ações com cinco cartões grandes de papel claro.** A ação vira um cardápio de restaurante. Mais finos e mais escuros, com o papel só no cartão escolhido, roubariam menos a cena.
- 🟢 A faixa de iniciativa com os inimigos em vermelho é clara e útil.

### Saguão, editor e Pausa
- 🟢 O saguão e a Pausa estão consistentes. O editor é ferramenta e pode continuar utilitário.

## Consistência

| Elemento | Problema | Recomendação |
|---|---|---|
| Molduras | Moldura dourada dupla em quase todo container | Reservar a moldura ao foco e à ação principal; o resto, só fundo escuro com borda fina |
| Papel | O mesmo papel claro para briefing, ficha, cartões de ação e diálogos | Dois tons: o papel "luz de luminária" para o que se lê agora e o papel envelhecido escuro para o resto |
| Cor de destaque | Dourado e vermelho brigam pelo papel de "clique aqui" | Vermelho para ação e perigo; dourado só para o achado (pista, sigilo) |

## Acessibilidade
- **Contraste:** os textos principais passam, como já mostraram o docs/15 e o docs/20. Escurecer o papel exige reconferir o contraste da tinta, que hoje passa com folga.
- **Tamanho:** os subtítulos de 11 a 12 px ("Arquivo de agentes · uso restrito" e "algo caça" na Membrana) estão no limite. O ajuste de escala da Pausa resolve para quem precisa.
- **Escuridão como mecânica:** o breu no combate precisa de um contorno das criaturas e um modo "mais claro" nos Ajustes, como os flashes suaves do docs/18.

## O que já funciona
- A identidade por contexto do docs/09: dossiê na Base, quadro na investigação, VHS na Membrana.
- O aviso de conteúdo e a Licença tratados como parte do clima, não como rodapé.
- A investigação: escura, focada, com REC e a testemunha à janela.

## Recomendações, por prioridade

1. **Luz ao contrário → luz certa (alto impacto, custo médio).**
   - **Combate:** breu fora do raio de luz dos agentes (lanterna de 2 a 3 células) e criaturas vistas pelo contorno até entrarem na luz.
   - **Membrana:** quanto mais baixa, menor o raio.
   - **Acessibilidade:** um ajuste "combate mais claro".
   - Meta: o combate com lum ≤ 40 e mais de 70% da área escura.
2. **Mapa com cor lavada, cor só no paranormal (AU3; alto impacto, custo baixo).** Dessaturar os terrenos para menos de 60 de saturação média, com névoa azul-acinzentada, e manter saturados só os marcadores, os presságios e os rastros. Meta: a saturação do mapa cai de 145 para menos de 80.
3. **Base sob luminária (médio impacto, custo baixo).**
   - Escurecer as bordas do papel claro com uma vinheta por shader ou um gradiente.
   - Baixar o papel dos cartões do Arsenal para o tom envelhecido.
   - Meta: as abas Missão e Agentes com lum ≤ 65.
4. **Menos moldura dourada (médio impacto, custo baixo):** só no foco, na ação principal e no papel em uso.
5. **Sigilos da investigação que acendem por perto (médio impacto, custo baixo):** fracos de longe e fortes a 1 a 2 metros do agente da vez.

**Ordem sugerida:** a 2 e a 4 entram já, porque são baratas e não mexem em regra. A 1 vira um item da Sprint 02, porque mexe na leitura tática e precisa de playtest.

## Fontes
- [Dead Space 2: Diegetic Interface Design (HUDs+GUIs)](https://www.hudsandguis.com/2012/08/22/dead-space-2-diegetic-interface-design)
- [Designing Dead Space's immersive user interface (Game Developer)](https://gamedeveloper.com/design/video-designing-i-dead-space-i-s-immersive-user-interface)
- [Glancing Signalis: Immersion from across the room](https://steventus.substack.com/p/glancing-signalis-part-1-immersion)
- [Diegetic interfaces in game design (Wayline)](https://www.wayline.io/blog/diegetic-interfaces-game-design)
- [Shape and Shadow: Creating Horror in The Callisto Protocol (GDC Vault)](https://gdcvault.com/play/1029307/Shape-and-Shadow-Creating-Horror)
- [Lighting design in The Callisto Protocol (80.lv)](https://80.lv/articles/a-sneak-peek-on-visuals-lighing-design-in-the-callisto-protocol)
- [Dead Space: Harnessing the Power of Light and Darkness (GDC Vault)](https://gdcvault.com/play/1029020/-Dead-Space-Harnessing-the)
- [Defining Horror as Tension: Silent Hill f (GameDev.net)](https://gamedev.net/news/4735-defining-horror-as-tension-silent-hill-f/)
- [Darkest Dungeon: Light Meter (wiki)](https://darkestdungeon.wiki.gg/wiki/Light_meter)
- [Darkest Dungeon review (Pocket Gamer)](https://www.pocketgamer.com/darkest-dungeon/review/)
- [Road to the IGF: Darkest Dungeon (Game Developer)](https://www.gamedeveloper.com/audio/road-to-the-igf-red-hook-studios-i-darkest-dungeon-i-)

## Feito em 02/11/2026 (recomendações 2 e 4)

- **Mapa com cor lavada (AU3):** o mapa tem saturação própria, 0,38 (as outras cenas 3D continuam com 0,62), e os tiles clareiam menos. Na área do mundo, sem o HUD e contando só o que não é breu, a saturação caiu de **141 para 59**, abaixo da meta de 80. A área clara visível caiu de 34% para 14%. Marcadores, rastros e presságios brilham e se destacam do chão oliva. Código: `Mapa3D.SATURACAO_MAPA` e `Pecas.clima_membrana(env, valor, saturacao_base)`.
- **Menos moldura dourada:** painéis, botões em repouso e o fundo das abas usam o traço dourado-escuro (`OURO_ESCURO`) apagado. O dourado vivo fica no hover, no foco, na aba aberta, no painel lateral (mais fraco) e na ação principal (`BotaoPrincipal`). Código: `Tema`.
- **Ainda não:** a Base sob luminária (lum 101 na aba Missão) fica para a Sprint 03, e o breu no combate (lum 62) para a Sprint 02.

## Feito em 02/11/2026 (recomendações 3 e 5, adiantadas da Sprint 03)

- **A Base sob luminária:**
  - Os papéis da Base (briefing, relatório e cartões do Arsenal) usam o tom envelhecido (`Tema.caixa_papel_envelhecido`). O cartão marcado continua mais claro: é o "papel em uso".
  - A ficha do agente ganhou um tom intermediário.
  - Uma vinheta radial (`Tema.luminaria`) escurece as bordas e deixa a luz no meio da tela.
  - Luminância medida: aba Missão de **101 para 69**, Agentes de **95 para 69** e Arsenal de **79 para 54**. A área clara (acima de 180) caiu de 36% para 0% na aba Missão.
  - A tinta continua com cerca de 9:1 de contraste no papel e por volta de 4,7:1 nos cantos mais escuros.
- **Sigilos que acendem por perto:** na investigação, o sigilo de cada ponto fica escuro de longe (22% da cor e emissão baixa) e acende inteiro a 1,5 m do agente da vez ou quando o ponto é o escolhido (`Investigacao3D.SIGILO_PERTO` e `SIGILO_LONGE`). O pulso continua. A cor escurece em vez de a malha ficar transparente, porque o sigilo é quase todo emissão.
- **Ainda não:** o breu no combate (lum 62), na Sprint 02.
