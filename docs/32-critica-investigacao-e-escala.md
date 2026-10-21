# Crítica: envolvimento, investigação e escala do mundo 3D

> Status: **v0.1**, 21/10/2026. Crítica de design (framework do `/design-critique`) com dois focos pedidos no playtest:
> 1. o jogo precisa ser mais envolvente e trazer o aspecto de **investigação: pistas, mistério e dedução**;
> 2. as árvores, casas e marcos precisam ter **tamanho e design coerentes** entre si e com Ordem Paranormal.

## Impressão geral

O jogo já tem clima: a noite no mapa, o véu, a cortiça do quadro, as fichas e o ritual de Transcender passam o tom de Ordem Paranormal. O que falta é o **jogador pensar**. Hoje a investigação é uma sequência de testes de perícia; quem raciocina é o jogo. E, no mapa, as casas batem no joelho dos agentes e a vila parece uma feira medieval. A maior oportunidade é a mesma nos dois casos: fazer o mundo e o caso **pedirem leitura** em vez de só clique.

## 1. Investigação: pistas, mistério e dedução

### Como funciona hoje

- O caso sorteia um **sujeito** (5 opções), uma **ação** (4) e um **local** (4).
- Cada cena tem 4 pontos. A pista de cada ponto **diz a resposta**:
  - "Cartas com o mesmo remetente: *um médico aposentado*."
  - "Os rastros seguem para *um frigorífico desativado*."
- Na 2ª pista de uma pergunta, o próprio jogo marca a pergunta como **respondida** e carimba RESOLVIDO no quadro.

### Usabilidade

| Achado | Gravidade | Recomendação |
|---|---|---|
| A pista entrega a resposta pronta. A 2ª pista da mesma pergunta só repete a 1ª | 🔴 Crítico | A pista traz um **indício** (um traço do culpado, do plano ou do lugar), não o nome |
| A pergunta se responde sozinha: o jogador nunca decide nada sobre o caso | 🔴 Crítico | O grupo **acusa** no quadro: escolhe um suspeito entre os candidatos |
| O jogador não sabe quem são os suspeitos possíveis; não há hipóteses a eliminar | 🔴 Crítico | Uma **ficha de suspeitos** por pergunta, com os traços de cada candidato, aberta desde o início |
| Não há risco em interpretar: errar não existe | 🟡 Moderado | Acusar errado custa (Membrana −5) e risca o suspeito; acertar dá o efeito da pergunta |
| Não há recompensa por arriscar cedo | 🟡 Moderado | Pode-se acusar com 1 pista. Alguns indícios são **provas fortes** (só um candidato tem) e já bastam |
| O quadro só é olhado, não usado | 🟡 Moderado | O quadro vira a mesa de trabalho: as fotos mostram o indício e o botão **Deduzir** abre a ficha de suspeitos |
| No mapa, o painel do caso mostra ●○ e a resposta, mas não deixa agir | 🟢 Menor | O mesmo **Deduzir** no painel do caso do mapa |

### Hierarquia visual (quadro)

- **O que chama o olho primeiro:** o carimbo vermelho RESOLVIDO. Hoje ele aparece sozinho; deveria aparecer porque o jogador acertou.
- **Leitura:** objetivo → três bilhetes → fotos. Funciona. Falta o rótulo do indício em cada foto, para o olho ligar foto e suspeito.
- **Ênfase:** os buracos pontilhados "?" mostram quantas pistas faltam. Com a dedução, eles passam a ser "pistas recomendadas", não um requisito.

### Proposta: dedução por indícios

Inspirada em jogos de dedução de tabuleiro (Cluedo, Detetive): cada candidato tem **3 traços**. Cada pista revela **um traço do culpado verdadeiro**. Os traços se sobrepõem entre candidatos, então:

- **1 pista** deixa, em geral, 2 suspeitos (ou 1, se for uma prova forte);
- **2 pistas** diferentes sempre deixam **um só**.

A tabela foi montada para que dois candidatos nunca dividam mais de um traço; um teste verifica isso nos dados.

| Pergunta | Candidatos | Traços (exemplos) |
|---|---|---|
| Quem | seita, médico, herdeira, ex-agente, radialista | age em grupo · linguagem de fé · esconde o rosto · mão treinada · dinheiro sobrando · idade avançada · nome de família · treino de campo · fala no ar |
| O quê | invocar, sequestros, objeto amaldiçoado, vingança | chamado · data marcada · sangue coletado · lista de nomes · cativeiro · objeto · lucro · rancor |
| Onde | frigorífico, igreja, fazenda, hospital | frio · eco · longe da cidade · perto do centro · vitral · azulejo · bichos · terra arada |

**Fluxo:**
1. O agente examina a escrivaninha.
2. A pista diz: "Cartas sem remetente, guardadas com cuidado. Caixas de remédio para pressão e uma letra trêmula." A foto no quadro recebe o rótulo **IDADE AVANÇADA**.
3. Na ficha de suspeitos de "Quem?", o traço *idade avançada* acende no médico e no radialista.
4. Mais uma pista (*dinheiro sobrando*) deixa só o médico.
5. O grupo acusa:
   - **Acertou:** a pergunta é resolvida e o efeito acontece (o chefe começa mais fraco, a Membrana se fortalece ou o covil aparece).
   - **Errou:** a Membrana cai 5 e o suspeito fica riscado.

**Online:** acusar é um comando de lockstep (`deduzir`), tanto na cena quanto no mapa. A ordem em que os traços aparecem é sorteada com os `Dados` da missão, então sai igual nas duas máquinas.

### Mistério (próximas rodadas)

- **Pistas duvidosas:** um descuido pode render um indício falso, marcado com "?" no quadro. O jogador decide em qual pista confiar.
- **Depoimentos:** testemunhas que contradizem uma pista.
- **Linha do tempo:** um terceiro eixo, "quando", para casos de campanha.

## 2. Escala e design do mundo 3D

### Medições (altura em unidades 3D; o hex tem raio 1)

| Objeto | Altura | Relação com o agente (0,82) |
|---|---|---|
| Agente no mapa (escala 0,75) | 0,82 | 1× |
| Casa (`casa_br`) | 0,36 | **0,44×: bate no joelho** |
| Árvore por código | 0,35–0,8 | 0,4–1× |
| Árvores KayKit no mapa | 0,47–0,60 | 0,6–0,7× |
| Morros | 0,68 | 0,8× |
| Montanha | 1,11 | 1,35× |
| Barraca KayKit (cidade) | 0,20 | 0,25× |
| Barril KayKit (cidade) | 0,08 | 0,1× |
| Cultista do encontro | 0,55 | 0,67× |
| Obelisco do covil | 0,85 | 1× |

![Casas na altura do joelho dos agentes](escala32_mapa.png)

### Consistência

| Elemento | Problema | Recomendação |
|---|---|---|
| Casas | 0,36 de altura, três por hex, no meio do caminho das figuras | **Casa de alvenaria brasileira** de ~0,95 (um pouco mais alta que o agente), com muro, porta e telha de barro; 1 ou 2 por hex, na borda |
| Árvores | Menores que os agentes; mata parece arbusto | Árvores de 0,9 a 1,3; a mata ganha duas copas de alturas diferentes |
| Cidade | Barril, caixote, saco e barraca da KayKit: feira medieval | Props contemporâneos: **poste com fiação**, **orelhão**, **carro abandonado**, muro chapiscado |
| Ruína | Pilares de templo genéricos | Paredes de tijolo quebradas e uma **cruz de madeira** caída (o interior de OP: capelas e fazendas) |
| Marcos | "?" e "◎" gigantes flutuando sem nada no chão | Marcos **diegéticos**: a investigação ganha **fita de isolamento** em estacas e uma plaqueta de evidência; o evento, uma **placa de estrada** torta. O símbolo flutuante fica menor, acima da peça |
| Vila | Casas iguais às da cidade | Vila = casas + lampião aceso + igrejinha |

**Regra de escala adotada (miniatura de mesa, como FTK):**

| Coisa | Altura em relação ao agente |
|---|---|
| Props de rua (poste, orelhão, carro, muro) | 0,4× a 1,3× |
| Casas | 1,1× a 1,3× |
| Árvores | 1,1× a 1,6× |
| Morros e montanhas | Como estão |

Nada cobre o **centro do hex**, onde ficam as figuras.

### Acessibilidade

- **Contraste:** as casas novas, mais altas, escondem menos que as árvores. As janelas acesas continuam como referência à noite.
- **Leitura dos marcos:** o símbolo flutuante continua lá (menor), então o tipo do hex segue legível de longe; a peça no chão é o reforço, não a única pista.
- **Ficha de suspeitos:** os traços encontrados acendem em ouro **e** ganham ✔, para não depender só da cor.

## O que funciona

- **O quadro de cortiça**, com fio vermelho e fotos instantâneas, é a metáfora certa. Só falta ser usado.
- **O gerador Sujeito + Ação + Local** já dá 80 combinações; o caso varia de verdade.
- **A pista central (GUMSHOE)** faz o especialista brilhar sem rolar dados.
- **A noite, as janelas acesas e o véu** dão o tom de OP. A escala nova só reforça.

## Implementado nesta rodada

### Dedução por indícios (ADR 0010)

- `casos.json`:
  - 3 traços por candidato (`indicios`);
  - 25 traços descritos com rótulo e frase;
  - `penalidade_palpite` (Membrana −5).
- **As 12 pistas** das cenas foram reescritas: o lugar onde se acha + `{indicio}`. Nenhuma diz mais a resposta.
- `Caso`: `registrar_pista` revela um traço e não resolve nada; ganhou também `candidatos`, `compativeis`, `indicios_encontrados` e `deduzir`. A ordem dos traços tem semente própria do caso.
- **Comando `deduzir`** no mapa e na investigação:
  - erro: Membrana −5 e o suspeito riscado;
  - acerto: o efeito da pergunta.
- **Ficha de suspeitos** (`PainelDeducao`): abas Quem/O quê/Onde, as cartas dos candidatos com os traços e confirmação antes de acusar.
- **Quadro:** cada foto mostra o rótulo do indício (o texto inteiro fica na dica), e cada bilhete tem **Deduzir**. O carimbo RESOLVIDO só aparece depois da acusação certa.
- **Mapa:** o painel do caso lista os traços achados e tem **Deduzir…**.
- **Tutorial:** o texto da ficha do caso fala de traços e acusação.

| Quadro com os indícios | Ficha de suspeitos |
|---|---|
| ![Quadro](ded32_quadro.png) | ![Ficha](ded32_ficha.png) |

### Escala e props

- **Casa de alvenaria:** 0,88 de altura, com barrado, porta, janelas e caixa d'água em metade das casas.
- **Cidade:** 1 ou 2 casas na borda, de porta para o centro, mais um poste aceso e, às vezes, um orelhão ou um carro. A feira medieval da KayKit saiu.
- **Ruína:** paredes de tijolo quebradas e uma cruz de madeira (de pé ou caída).
- **Árvores KayKit:** mais altas, só no eixo vertical, para a copa não invadir o centro. As árvores por código também cresceram (0,8 a 1,3).
- **Marcos:**
  - a investigação tem fita de isolamento em volta do centro;
  - o evento tem uma placa de estrada;
  - os símbolos flutuam menores (90 px) e acima da cabeça;
  - o cultista do encontro está na escala do agente (0,7).
- **Combate:** a borda da cidade usa as mesmas peças (casas, postes, carros, orelhões), e a das ruínas usa paredes e cruzes, todas na escala da figura do combate (`ESCALA_PROPS` 1,35).

| Cidade | Ruína |
|---|---|
| ![Cidade](escala32_cidade.png) | ![Ruína](escala32_ruina.png) |

| Investigação no mapa | Combate na cidade |
|---|---|
| ![Fita de isolamento](escala32_isolamento.png) | ![Combate](escala32_combate.png) |

**Testes:** 511 (eram 504).
- **Regra da tabela:** dois candidatos nunca dividem mais de um traço.
- **Pistas:** em 12 casos sorteados, duas pistas sempre deixam um só suspeito.
- **Acusação:**
  - certo e errado no `Caso`;
  - o comando no mapa (penalidade e covil revelado) e na cena (o efeito vai com o resultado, sem gastar a vez).
- **Save antigo:** um save sem traços é completado ao carregar.
- **Interface:** o quadro (rótulo, Deduzir, carimbo) e a ficha de suspeitos.

## Recomendações em ordem

1. **Dedução por indícios** (crítico): traços nos dados, pistas que dão traços, ficha de suspeitos, acusação com custo, comando online.
2. **Escala e props brasileiros** (moderado, muito visível): casas, árvores, cidade, ruína e marcos diegéticos.
3. **Mistério** (próximo): pistas duvidosas e depoimentos.
4. **Conteúdo** (próximo): mais cenas de investigação, eventos e casos, já no formato de indícios.
