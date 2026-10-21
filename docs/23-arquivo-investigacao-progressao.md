# Arsenal, ficha da Base, investigação, briefing e cerimônia de NEX

> Status: **v0.1**, 21/10/2026. Implementa o **C5**, o **C6** e o **C7** da [crítica 20](20-critica-pos-acessibilidade.md).

## C5: Arsenal e ficha da Base

### Arsenal

**Antes:** 32 etiquetas iguais em quatro colunas e nomes cortados ("Equipamento de sobrevivênc", "Componentes ritualísticos ("). Nada dizia o efeito do item nem para quem se requisitava.

**Agora:**

- **Para quem:** o cabeçalho diz "Equipando Mauro (Recruta): até 2 itens de categoria I, 0 de II e 0 de III." (desde o docs/21).
- **Etiquetas:** três por linha, 372 × 76, com o **nome inteiro** em até duas linhas.
- **Ícone de tinta à esquerda:** desenhado por código (`IconeItem`). São nove tipos:
  - lâmina, arma de fogo, arco;
  - proteção, kit, frasco;
  - componente ritual, granada e pacote.

  Amaldiçoados usam o mesmo ícone em vermelho-sangue.
- **Tooltip com o efeito:**
  - **armas:** dano, crítico, corpo a corpo ou alcance, e a perícia;
  - **proteções:** "Defesa +N";
  - **outros itens:** a descrição do ruleset.

![Arsenal](base_arsenal_23.png)

### Ficha em blocos

**Antes:** um bloco de texto corrido num terço da folha.

**Agora:**

- **Pentágono de atributos** (`PentagonoAtributos`): os cinco atributos em círculos de tinta nos vértices (AGI no alto, depois INT, PRE, VIG e FOR), com o valor grande e a sigla embaixo. Atributo 0 fica tracejado.
- **Cabeçalho:**
  - o nome em Cinzel;
  - classe, trilha e origem;
  - NEX, patente, PP, Defesa e deslocamento;
  - **PV, PE e SAN em barras de tinta**.
- **Embaixo:** perícias em **duas colunas** e, depois, habilidades e rituais. A ficha (F) do jogo continua com o texto completo.
- **Foto 3x4:** continua no canto (docs/21).
- **Os dois caminhos de recrutar ficaram claros:** "Recrutar pronto" (com tooltip) e "+ Criar ficha de agente".

![Ficha em blocos](base_agentes_23.png)

## C6: investigação mais limpa

- **Quadro do caso fechado ao entrar.** A cena 3D vem primeiro, e o quadro abre com Tab. Na pista nova, ele abre sozinho para mostrar a foto sendo presa, e o botão pulsa três vezes.
- **Nomes dos pontos só por perto:** a menos de 2,8 do agente da vez, ou no ponto escolhido.
  - **Atrás do HUD, nunca:** o nome some quando cai nos 30% de baixo da tela, onde ficam retratos, bilhete e cartas.
  - **Antes:** "Computador velho" ficava por cima dos retratos.
- **Peças por tipo de ponto** (`PropsInvestigacao`), escolhidas pelo id e pelo nome do ponto:

| Tipo | Pontos | Peça |
|---|---|---|
| Mesa | escrivaninha, livro, registro, diário, relatório, bilhete, foto, planta | Mesa de madeira com papéis |
| Tela | computador, rádio, câmeras, painel | Mesa com monitor aceso em verde |
| Pessoa | vizinha, zelador, operário, ferido | Figura encolhida, em tons apagados |
| Alçapão | porão, jazigo, cofre, armário | Alçapão com travas e cadeado |
| Altar | altar, oratório | Pedra com duas velas acesas (e luz) |
| Lápides | covas, inscrições | Lápides tortas |
| Fogueira | fogueira | Lenha em cruz, brasas e luz baixa |
| Barraca | barraca | Tenda da KayKit |
| Rastros | rastros, pegadas | Pegadas escuras em fila |

  Sem palavra conhecida, a cena usa a peça antiga.
- **Perícia só para treinados:** no Procurar, ela fica bloqueada, e a escolha começa pela de maior chance. Antes, a primeira perícia vinha marcada mesmo quando o agente não podia usá-la.

![Investigação](inv_23.png)
![Perto do computador](inv_perto_23.png)

## C7: briefing procedural e cerimônia de NEX

### Briefing da missão procedural

**Antes:** uma linha só ("Um mapa novo a cada missão…").

**Agora:**

- **Mesma semente da missão:** a Base sorteia a semente da próxima missão ao abrir. O briefing descreve o mapa que essa semente gera (`Missao.previa`), e "Iniciar missão" usa a mesma semente.
- **Formato:**

> **ARQUIVO Nº 2657 · OPERAÇÃO EM CAMPO** — CONFIDENCIAL
> Região: campos abertos e brejo, 176 áreas no mapa. Gente: 2 trechos de cidade, 1 vila onde descansar. Locais a investigar: 3. Ocorrências relatadas: 6.
> Sinais, objetivo e os agentes designados.

- **O briefing não entrega o caso:** sujeito, ação e local são as respostas das três perguntas da investigação, então ficam de fora. Há um teste para isso.

![Briefing](base_missao_23.png)

### Cerimônia de NEX e patente

- **Quando aparece:** na volta de uma missão, a Base abre uma folha "Relatório de progressão" (`CerimoniaNex`). Ela aparece **uma vez por missão** (`cerimonia_vista` no relatório, que fica salvo).
- **Para cada agente que voltou:**
  - a foto 3x4;
  - **NEX antes → depois**;
  - a patente e os PP ganhos;
  - quantas **escolhas novas** esperam na ficha.
- **Promoção:** o carimbo **PROMOVIDO** bate, com som, um agente de cada vez.
- **Rodapé:** quem morreu ou enlouqueceu aparece "Em memória".
- **Depois:** "Arquivar" (ou Esc) fecha. A Base já abre na aba Agentes quando há escolha pendente (docs/16).

![Cerimônia](cerimonia_23.png)

## Testes

O `tests/unit/test_arquivo.gd` tem 8 testes:

- **Arsenal:** ícone e efeito dos itens.
- **Ficha:** pentágono com cinco vértices; ficha da Base em blocos (barras, perícias em duas colunas, etiquetas largas).
- **Investigação:** peças pelo tipo do ponto; o quadro começa fechado e os nomes só aparecem por perto.
- **Briefing:** a prévia bate com a missão e não entrega o caso.
- **Cerimônia:** aparece uma vez por missão.

Total: **474 testes**.

## Pendências

- **Peças da investigação:** são de primitivas (caixas e cápsulas). Modelos de móveis CC0 dariam mais vida (o pacote precisaria ser baixado, com confirmação).
- **Pentágono:** não mostra o efeito de lesões nem de penalidades. Mostra o atributo atual.
- **Cerimônia:** não lista o nome dos poderes novos. Diz quantas escolhas esperam, e elas são feitas na ficha.
- **Briefing:** as missões da comunidade e da campanha continuam com o texto que o autor escreveu.
