# Identidade visual de Ordem Paranormal

> Status: **v0.1**, 20/10/2026. Segue o [08-direcao-de-arte-e-ux.md](08-direcao-de-arte-e-ux.md), que deixou o jogo com cara de FTK2, mas ainda "genérico, quadrado e antigo" (avaliação do autor). Aqui o objetivo é outro: **parecer feito por um artista de Ordem Paranormal**.

## 1. Decisões do autor

Respostas às perguntas de descoberta, em 20/10/2026:

| Tema | Decisão |
|---|---|
| Estética | As quatro, **cada uma no seu contexto** (abaixo) |
| Mundo 3D | Base FTK (tiles da KayKit recoloridos) **mais marcos próprios de OP**: covil, vila, ruína e encontros |
| Layout | **HUD flutuante tipo FTK2** como padrão; **cartas e pastas** em pontos específicos |
| Plataforma | **PC com mouse e teclado**: hover, tooltips e atalhos. O controle é bônus |
| Combate | **Híbrido**: grade tática, com close cinematográfico nos ataques e rituais |
| Arte | Blender via MCP, packs CC0 (cada download confirmado antes) e **arte 2D procedural** |
| Piloto | **Investigação** |

## 2. A linguagem: uma estética por contexto

| Contexto | Estética | Onde aparece | Sensação |
|---|---|---|---|
| **Menus, título, botões principais** | **Sigilos e traço riscado** | Tela de título, menus, molduras dos painéis do HUD | Ritual, ameaça, algo escrito à mão por quem viu o Outro Lado |
| **Base, fichas, itens, relatórios** | **Dossiê da Ordem** | Base, ficha do agente, requisição, relatório de missão | Burocracia sigilosa: papel, carimbo, clipe, máquina de escrever |
| **Investigação e pistas** | **Quadro de investigação** | Tela de investigação, ficha do caso, pistas do mapa | Obsessão: cortiça, alfinetes, fio vermelho, fotos instantâneas |
| **O paranormal se manifestando** | **VHS / found footage** | Pista encontrada, Membrana caindo, ritual, criatura aparecendo | A câmera não aguenta: grão, *tracking*, aberração cromática, REC piscando |

**Regra de ouro:** o 3D é o tabuleiro; a interface é o **material da Ordem sobre a mesa**. Nada de caixa cinza com borda reta: tudo é papel, cortiça ou traço.

### Restrições de propriedade intelectual

- **Não reproduzimos os sigilos oficiais** dos elementos nem o logo da série. Os sigilos do jogo são **gerados por código**, com a mesma gramática visual (círculo, traços radiais, ganchos, assimetria), mas são desenhos originais.
- As cores dos elementos seguem a convenção da comunidade (sangue vermelho, morte cinza-chumbo, conhecimento dourado, energia roxa, medo branco). Cor não tem dono.

## 3. Crítica da Investigação (antes)

![Investigação antes](investigacao.png)

| Achado | Gravidade | Proposta |
|---|---|---|
| A coluna da direita tem **14 controles de formulário** (dropdowns, checkboxes, spinbox): parece um painel de configuração, não um jogo | 🔴 Crítico | Ações viram **cartas** na base da tela, e as opções abrem num **bilhete** ao lado da carta |
| As pistas encontradas só aparecem no texto do registro: **o momento de achar uma pista não tem recompensa visual** | 🔴 Crítico | A pista vira uma **foto instantânea presa no quadro**, com fio vermelho até a pergunta que responde, e um *glitch* VHS na hora da descoberta |
| A ficha do caso é texto com "(0/2)" | 🟡 Moderado | **Quadro de cortiça**: cada pergunta é um bilhete preso; os espaços de pista vazios ficam pontilhados |
| O 3D ocupa metade da tela e os pontos de interesse são caixas marrons | 🟡 Moderado | 3D em tela cheia, com os pontos destacados por **sigilo pulsando** no chão e tooltip no hover |
| A urgência é o texto "rodada 1 de 4" | 🟡 Moderado | **Fita de urgência**: quatro marcas riscadas que vão sendo cortadas, ao lado de um **REC** com tempo de gravação |
| Não há leitura do grupo | 🟢 Menor | Os mesmos `CartaoAgente` do mapa, no canto inferior esquerdo |

### Depois (piloto, 20/10/2026)

![Investigação depois](investigacao_v2.png)

Os critérios de pronto da seção 5.5 estão cobertos pelos testes em `test_visual.gd`. A fonte de máquina de escrever ainda não entrou: depende de um download.

## 4. Brainstorm

- ✅ Quadro de cortiça deslizante (tecla **Tab**), com perguntas, pistas e fio vermelho.
- ✅ Cartas de ação: **Procurar**, **Facilitar**, **Ajudar**, **Passar**; atalhos **1** a **4**.
- ✅ Bilhete de opções ao lado da carta: perícias como linhas "Investigação · DT 15 · 1d20+0", Foco com − e +, e habilidades como selos.
- ✅ Sigilo procedural no chão de cada ponto de interesse; ao passar o mouse, a câmera "foca".
- ✅ Overlay de found footage na investigação: `REC ●`, timecode e cantos de enquadramento.
- ✅ *Glitch* VHS ao encontrar pista (0,6 s) e ao falhar feio (0,3 s).
- ✅ Molduras com **traço riscado** (StyleBox procedural) no HUD inteiro.
- 💡 Fonte de máquina de escrever (Special Elite, Apache 2.0) no registro e nos bilhetes: depende de um download.
- 💡 Ao fim da cena, o quadro "fotografa" a si mesmo e vira a página do relatório de missão.
- 💡 Sussurros e estática de rádio no áudio quando a urgência estoura.

## 5. Handoff (especificação para implementar)

### 5.1 Tokens novos (`Tema`)

| Token | Valor | Uso |
|---|---|---|
| `PAPEL` | `#e8dcc0` | Bilhetes, cartas, fichas |
| `PAPEL_SOMBRA` | `#bfae8a` | Bordas e manchas do papel |
| `TINTA` | `#2a2320` | Texto sobre papel |
| `CORTICA` | `#8a5a36` | Quadro |
| `FIO` | `#b3121c` | Fio vermelho do quadro |
| `TRACO` | `#e9dfc8` a 75% | Traço riscado das molduras |

### 5.2 Componentes

#### `MolduraRiscada` (StyleBox procedural)

- **Fundo:** `PEDRA` a 92%.
- **Borda:** de 2 a 3 traços sobrepostos, com desvio de ±1,5 px e cantos que passam do limite (o traço "escapa" de 4 a 8 px, como desenhado à mão).
- **Variantes:**
  - `normal`: traço `TRACO`;
  - `destaque`: traço `OURO_CLARO`;
  - `perigo`: traço `SANGUE_CLARO`.
- **Estabilidade:** o desvio usa uma semente vinda do tamanho do retângulo, para o desenho não "tremer" a cada quadro.

#### `Sigilo` (Control e textura)

- **Gramática:** um círculo externo (às vezes duplo) e de 3 a 7 raios ou ganchos, com 1 ou 2 arcos internos e de 0 a 2 pontos.
- **Traço:** com desvio, como os da `MolduraRiscada`.
- **Determinismo:** `semente` (int) gera sempre o mesmo sigilo.
- **Cor:** a do elemento ou `TRACO`.
- **Animação:** opcional, revela o traço em 0,6 s.

#### `QuadroInvestigacao` (painel)

- **Superfície:** cortiça procedural (ruído) com moldura de madeira escura.
- **Perguntas:** um bilhete por pergunta do caso, com alfinete vermelho, o texto da pergunta e os espaços de pista.
  - O espaço vazio fica pontilhado.
  - O espaço preenchido recebe a foto da pista.
- **Fotos de pista:**
  - formato de foto instantânea (moldura branca e área escura com o sigilo da cena);
  - legenda com o texto da pista;
  - inclinação de ±4°.
- **Fio vermelho:** liga cada foto ao bilhete da pergunta que ela responde, com uma curva que cai levemente.
- **Resposta:** quando a pergunta é respondida, o bilhete ganha o carimbo "RESOLVIDO" com a resposta.
- **Abertura:** desliza da direita (0,25 s) e abre com **Tab** ou com o botão "Quadro".

#### `CartaAcao`

- **Tamanho:** 132 × 176 px, em papel, com sigilo no topo, título em Cinzel e uma dica curta.
- **Estados:**
  - `normal`;
  - `hover`: sobe 12 px e ganha sombra;
  - `selecionada`: borda `OURO_CLARO`, com o bilhete de opções aberto;
  - `desabilitada`: 40% de opacidade, sem hover.
- **Atalhos:** do 1 ao 4.

#### `BilheteOpcoes`

- **Aparência:** papel com clipe, ancorado acima da carta selecionada.
- **Conteúdo:**
  - lista de opções clicáveis (uma perícia ou opção de facilitar por linha, com DT e dados);
  - Foco (− e +);
  - selos de habilidade (Faro, Perito, Eclético, Presteza) que ligam e desligam;
  - botão de confirmação: "Procurar", "Facilitar" ou "Ajudar".

#### `FitaFoundFootage` (overlay)

- **Topo à esquerda:** `● REC` piscando e o timecode `00:MM:SS` (o tempo real da cena).
- **Cantos:** marcas de enquadramento em L.
- **Topo central:** o nome da cena e a fita de urgência (marcas riscadas).

### 5.3 Efeitos (shader `veu_membrana`)

- **Novo uniforme `glitch`** (0 a 1), que aplica:
  - aberração cromática (deslocamento de R e B de até 6 px);
  - faixas horizontais deslocadas;
  - linhas de varredura.
- **Pulsos:**
  - pista encontrada: `glitch` 0,8, decaindo em 0,6 s;
  - falha: `glitch` 0,35, decaindo em 0,3 s.

### 5.4 Layout da Investigação (1280 × 720)

```
┌───────────────────────────────────────────────────────────────┐
│ ● REC 00:01:12          CASA ABANDONADA   ▮▮▮▯ urgência   [?] │
│ ┌                                                           ┐ │
│                       (3D em tela cheia)                 ┌────┤
│                                                          │Qua-│
│                                                          │dro │ ← Tab abre
│ └                                                           ┘ │
│ [Mauro][Bianca][Rita]   [PROCURAR][FACILITAR][AJUDAR][PASSAR] │
│                                         ▸ relatório de campo  │
└───────────────────────────────────────────────────────────────┘
```

### 5.5 Critérios de pronto (piloto)

- Nenhum dropdown ou checkbox visível na tela de investigação.
- Achar uma pista dispara o *glitch*, adiciona a foto ao quadro e liga o fio vermelho.
- Tudo é acessível só com o mouse, e também só com o teclado (1 a 4, Tab, Enter, Esc).
- Os testes de investigação, comandos e tutorial continuam passando: os alvos do tutorial existem.

## 6. Demais telas (20/10/2026)

Depois do piloto, o estilo foi aplicado ao resto do jogo:

| Tela | O que mudou |
|---|---|
| **Tema** | Painéis e botões em traço riscado (`MolduraRiscada`); abas como pastas; caixas de marcar desenhadas; `RelatorioCampo` e `PassoFoco` reutilizados |
| **Título** | Sigilo grande se desenhando e girando atrás do logo; menu em Cinzel, só texto, com moldura riscada e sigilo no item com foco |
| **Mapa** | 3D em tela cheia; turno no topo à esquerda, Membrana com sigilo no topo central, grupo embaixo; dock com Foco −/+, rolagem e ações; evento como bilhete no centro; dica em papel ao passar o mouse sobre um hex (terreno, custo, conteúdo); relatório recolhível |
| **Combate** | Mesmo HUD; ações como cartas (Mover, Atacar, Ritual, Item, Encerrar); rituais e itens num bilhete; Ataque Especial como selo; close de câmera no alvo dos ataques e rituais, com *glitch* VHS no crítico e no ritual |
| **Base** | Dossiê com abas Agentes, Arsenal, Missão e Jogadores; ficha em papel com carimbo CONFIDENCIAL e foto (sigilo da classe); briefing e relatório da última missão em papel. O tour do tutorial abre sozinho a aba do elemento que destaca |

![Título](titulo_v2.png)
![Mapa](mapa_v2.png)
![Combate](combate_v2.png)
![Base](base_v2.png)

### Ainda falta

- **Inimigos em 3D:** ainda são cones e prismas. Precisam de modelos próprios (Blender) ou de um pack CC0 (Quaternius), com confirmação antes do download.
- **Marcos de OP no mapa** (covil, vila, ruína): as casas ainda são as medievais por código.
- **Saguão e editor de missões:** herdaram o tema, mas não foram redesenhados.
- **Fonte de máquina de escrever** nos bilhetes e no relatório: depende de um download.
- **Registro do combate e do mapa:** ainda usa cores em hex no BBCode, em vez de `Tema.bb()`.
