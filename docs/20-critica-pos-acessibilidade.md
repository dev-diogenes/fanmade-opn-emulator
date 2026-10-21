# Crítica de design: depois da acessibilidade e das pendências visuais

> Status: **v0.1**, 20/10/2026.
>
> - **Base de comparação:** a [crítica anterior](15-critica-acessibilidade-engajamento.md), depois de três rodadas: [16](16-pacote-acessibilidade-engajamento.md), [17](17-criacao-e-sanidade.md), [18](18-atalhos-flashes-daltonismo.md) e [19](19-pendencias-visuais.md).
> - **Método:** 17 capturas a 1280×720, cada tela no estado mais revelador (evento aberto, vez da ameaça, bilhetes, pausa com ajustes, fim de missão), mais medição de contraste e uma busca no código por fontes abaixo de 14 px.
> - **Estágio:** refinamento de um protótipo jogável.

## Impressão geral

A interface virou um sistema coerente:

- papel, carimbos e máquina de escrever em tudo o que é documento;
- cartas legíveis, com teclas que dá para trocar;
- rolagem e desfecho no centro, no estilo FTK2;
- ajustes de acessibilidade completos.

A **Investigação** é a tela que mais parece Ordem Paranormal: escura, com sigilos dourados no chão, fita REC e quadro de cortiça.

**A maior oportunidade agora é o mundo 3D, não os menus.** O título e o mapa têm grama verde-limão saturada e água azul viva sob luz do dia. Parece um jogo de fazenda com uma moldura de terror por cima. O segundo ponto é **decidir sem saber a chance**: eventos e investigação pedem escolhas entre perícias, mas não mostram a probabilidade de cada uma, que é o que o FTK2 deixa à vista.

## O que mudou desde a crítica anterior

| Item da [crítica 15](15-critica-acessibilidade-engajamento.md) | Situação |
|---|---|
| A1 escala e mínimo de 14 px | ✅ escala; ⚠️ ainda há textos de 11 a 13 px (ver Acessibilidade) |
| A2 motivo do desabilitado e contraste | ✅ |
| A3 velocidade do texto e da rolagem | ✅ |
| A4 atalhos e folha | ✅ |
| A5 fotossensibilidade | ✅ |
| A6 daltonismo | ✅ |
| E1 desfecho, E2 criação em dossiê, E3 rastreador do caso, E5 Base na aba Missão, E6 sanidade | ✅ |
| E4 faixa da vez da ameaça | ❌ pendente |
| E7 cerimônia de NEX e patente | ❌ pendente |
| E8 sala por código e saguão animado | ❌ pendente: o saguão ainda é um papel vazio |
| "* ainda sem efeito no motor" na ficha | ❌ continua na Base e na ficha (F) |
| "Último teste" no canto do combate | ❌ continua, vazio ("—") |
| Slots pequenos no dock do mapa, além da rolagem central | ❌ continuam |
| Rótulos 3D cortados na investigação | ⚠️ agora ficam atrás do HUD (ver Usabilidade) |
| Termos de rede na aba Jogadores | ❌ continuam (7777, 127.0.0.1) |

## 1. Primeira impressão (2 segundos)

| Tela | O que chama atenção primeiro | Está certo? |
|---|---|---|
| Título | O logo dourado e o sigilo vermelho | ✅, mas o diorama ensolarado contradiz o tom |
| Base › Agentes | A folha de papel enorme e quase vazia | ⚠️ O olho vai para o vazio; a ficha ocupa um terço da folha |
| Base › Arsenal | A grade de 32 etiquetas iguais | ⚠️ Nada diz para **qual agente** se está requisitando |
| Base › Missão | "Iniciar missão" | ✅, mas o briefing tem uma linha só |
| Mapa | O grupo e a Membrana | ✅ |
| Evento | A primeira opção, grande e vermelha | ⚠️ Parece "recomendada", mas é só o foco do teclado |
| Combate (vez da ameaça) | Cinco cadeados nas cartas | ❌ O que importa (quem age e em quem) não aparece |
| Investigação | O quadro de cortiça, que cobre 40% da cena | ⚠️ A cena 3D, o melhor da tela, fica atrás |
| Fim de missão | O carimbo CASO ENCERRADO | ✅, mas o carimbo cobre o botão |
| Saguão | Uma folha vazia | ❌ Parece travado (já apontado na crítica 15) |

![Título](critica20_titulo.png)

## 2. Usabilidade

| Achado | Gravidade | Recomendação |
|---|---|---|
| **A chance não aparece nas escolhas.** O evento mostra "Diplomacia +0 (DT 15)" e "Enganação −5 (DT 15)"; o Facilitar, só "Atletismo · DT 15". Para comparar, o jogador precisa saber quantos d20 tem, como funciona o maior e o que significa o −5 (não treinado). No FTK2, a decisão é ver a chance e os slots | 🔴 Crítico | Em cada opção, os **dados** (⚀⚀ = 2 d20), o **bônus** e a **chance estimada** ("≈ 60%"), calculada pela mesma regra do `Teste`. A melhor opção do agente da vez ganha um selo discreto. "−5" ganha tooltip: "sem treino nesta perícia". |
| **Vez da ameaça sem aviso (E4).** O topo muda para "Rodada 1 · Cultista", a mão inteira vira cadeado e nada diz quem age nem em quem | 🟡 Moderado | Faixa "VEZ DO CULTISTA" com o retrato e a **intenção** ("vai atacar Rita"); a mão desce e sai de vista enquanto a ameaça age, em vez de mostrar cinco cadeados |
| **Facilitar repete a ação por perícia:** quatro linhas para duas ações ("Arrancar as tábuas… · Atletismo" e "… · Luta"); "DT 15" quebra em duas linhas | 🟡 Moderado | Uma linha por ação, com **chips de perícia** (a de maior bônus já marcada) e a chance ao lado |
| **Bilhete de rituais só com nome e custo** ("Eletrocussão · 1 PE"). Não diz efeito, alvo nem alcance, e não tem tecla | 🟡 Moderado | Segunda linha curta ("2d6 de energia · 1 alvo · curto") e teclas 1–3 no bilhete, como nas cartas |
| **Arsenal:** nomes cortados ("Equipamento de sobrevivênc", "Componentes ritualísticos ("), sem efeito, sem dizer para qual agente, e "categoria I até 2, II até 0" é jargão | 🟡 Moderado | Cabeçalho "Equipando: **Mauro** · Recruta · pode levar 2 itens de categoria I"; nome em até duas linhas; tooltip com o efeito; 3 colunas; um ícone procedural por tipo (arma, proteção, kit, componente) |
| **Base › Agentes:** a foto é o sigilo vermelho, enquanto a criação e a ficha (F) mostram a foto 3x4; a ficha ocupa um terço da folha. Há dois caminhos de recrutar (lista "Tiago (combatente)" + Recrutar, e "+ Novo agente") sem dizer a diferença | 🟡 Moderado | `FotoAgente` também na Base. Ficha em blocos: barras PV/PE/SAN, atributos em pentágono (a marca da ficha de OP), perícias em duas colunas. Botões "Recrutar pronto" e "Criar ficha" |
| **Investigação:** o quadro abre por padrão e cobre a cena (corta o rótulo "Ri…"). Os rótulos 3D perto da borda de baixo ficam atrás dos retratos e das cartas ("Computador velho"). Os pontos de interesse são cubos escuros | 🟡 Moderado | Quadro **fechado** por padrão: abre com Tab e pulsa quando chega pista nova. Rótulos só no hover ou ao alcance, empurrados para fora da faixa do HUD. Peças low-poly simples por tipo de ponto (mesa, janela, computador) |
| **Missão:** o briefing da missão procedural é uma linha. A tela de "jogar" não tem clima; "Opções da run" e "(p.184)" são linguagem de desenvolvedor | 🟡 Moderado | "Arquivo do caso nº 0xx" datilografado com o lugar, a urgência e o tipo de ameaça sorteados (o caso já existe no `Missao`). "Regras opcionais", com tooltip do que cada uma faz e sem número de página |
| **Fim de missão:** o carimbo cobre o botão "Voltar à Base" e linhas do texto; o resumo não mostra NEX nem promoção (E7) | 🟡 Moderado | Carimbo acima do botão, numa área reservada; o relatório ganha a linha de cada agente (PP ganhos, NEX, patente) com carimbo de promoção |
| **Evento:** a opção em foco vira um botão principal grande em Cinzel, e as outras ficam em máquina de escrever pequena. O foco parece recomendação | 🟢 Menor | Mesmo tamanho e fonte para todas; o foco ganha borda dourada e seta ▸ |
| **Pausa com 14 controles em lista**, sem seções; "Ajustes" parece título mas é botão | 🟢 Menor | Subtítulos (Leitura, Imagem, Som, Controles) ou abas; a mesma estrutura na aba Jogadores |
| **"Nova carreira (apaga o save)"** fica no fim das preferências, meio cortado pela rolagem | 🟢 Menor | Seção separada "Zona de perigo", com o diálogo de confirmação que já existe |
| **Topo do combate** repete o retrato e quebra mal ("SAN" sozinho na linha) | 🟢 Menor | Topo só com "Rodada 1 · Rita" e a arma; os números ficam no retrato |
| **Rótulos do grupo no mapa** se empilham (Mauro / Bianca / Rita) | 🟢 Menor | Peças em leque no hex e só o nome do agente da vez; os outros no hover |
| **Título:** "Continuar carreira" não diz o que continua | 🟢 Menor | Linha abaixo: "3 agentes · missão em andamento · turno 4" |
| **Pendências antigas:** "Último teste —", "* ainda sem efeito no motor", slots no dock do mapa, saguão vazio, termos de rede | 🟢 Menor | Ver a tabela "O que mudou" |

![Evento](critica20_evento.png)
![Vez da ameaça](critica20_combate_ameaca.png)
![Facilitar](critica20_inv_bilhete.png)

## 3. Hierarquia visual

- **O que puxa o olho:**
  - **mapa e investigação:** a ordem está certa. A Membrana no topo, o agente da vez no centro, a ação principal em vermelho no canto de baixo.
  - **combate (vez da ameaça):** os cadeados, que são a informação menos útil daquele momento.
  - **Base › Agentes:** o espaço vazio.
- **Fluxo de leitura:**
  - **cartas:** o "sigilo → título → dica" funciona bem desde o docs/19;
  - **eventos:** o título da opção e o teste estão na mesma linha, em fonte de corpo. O olho não separa "o que faço" de "o que rolo". Teste em linha própria, menor, com os dados e a chance.
- **Ênfase:** o vermelho-sangue tem três papéis:
  - ação principal ("Rolar movimento", "Iniciar missão", "Requisitar");
  - item selecionado (origem Acadêmico, classe Ocultista, opção de evento em foco);
  - perigo.

  Recomendação: seleção em **borda dourada sobre papel** (como as cartas), vermelho só para a ação e o perigo.

## 4. Consistência

| Elemento | Problema | Recomendação |
|---|---|---|
| Foto do agente | Foto 3x4 na criação e na ficha (F); sigilo na Base | `FotoAgente` nas três (e, renderizada uma vez em textura, nos retratos do HUD) |
| Seleção | Vermelho cheio nas listas de papel (origem, classe, opção); borda dourada nas cartas | Borda dourada em todo o papel |
| Escolhas com teste | Evento: "Perícia +X (DT N)". Facilitar: "· Perícia · DT N". Procurar: outro formato | Um componente só, `LinhaTeste`: ação, perícia, dados, bônus, DT e chance |
| Teclas | Cartas e retratos mostram a tecla; os bilhetes (rituais, itens, opções) não têm | Número em selo também nas linhas dos bilhetes |
| Rolagem | Central (FTK2) no mapa, no combate e na investigação; os slots pequenos ainda aparecem no dock do mapa e no "Último teste" do combate | Só a central, com o histórico no relatório de campo |
| Clima 3D | Investigação escura e com névoa; mapa e título com luz de meio-dia saturada; combate num cinza neutro | Uma gradação de terror por cena (ver Opções) |

## 5. Acessibilidade (medido)

**Contraste** (WCAG 2.1, texto de 14 px pede 4,5:1):

| Par | Razão | Resultado |
|---|---|---|
| Tinta 88% (dica das cartas) / papel | 8,3 | ✅ |
| Selo da tecla (papel sobre tinta 82%) | 7,0 | ✅ |
| Texto suave / pedra | 6,7 | ✅ |
| `#6b5a48` (rótulos "Perícias:" e "Habilidades:" da ficha) / papel | 4,9 (3,8 sobre as manchas) | ⚠️ |
| **Tinta 60%** (nota do bilhete "Ande com WASD…", nota do mapa, cabeçalho do relatório) / papel | **3,7** (3,4 sobre as manchas) | ❌ Subir para 75% (≈5,5:1) |
| Dica da carta bloqueada (sobre o véu de 34%) | 3,6 | Isento (componente desabilitado); o cadeado e o tooltip compensam |

**Textos abaixo de 14 px** (a regra do A1):

| Onde | Tamanho |
|---|---|
| Carimbo "REQUISITADO" no Arsenal (`base_ordem.gd:387`) | 11 px |
| Legenda das fotos no quadro (`quadro_investigacao.gd:162`) | 11 px |
| Carimbo "RESOLVIDO" com a resposta, no quadro (`quadro_investigacao.gd:183`) | 13 px |
| Objetivo do caso no quadro (`quadro_investigacao.gd:59`) | 13 px |
| PV/PE/SAN e os números das barras nos retratos (`cartao_agente.gd:61 e 76`) | 13 px |
| Nota do mapa (`mapa_mundo.gd:254`) | 13 px |

O "REQUISITADO" é decorativo. O "RESOLVIDO" traz a resposta da pergunta, e ela é informação. Esse e os outros quatro são texto de jogo e devem ir a 14.

**Teclado:**

- **Com tecla:** as cartas, a ficha, o quadro, a câmera e a pausa.
- **Só com Tab e Enter:** os bilhetes de rituais e itens e as opções de evento. Funcionam, mas falta o atalho numérico (ver Consistência).

**Movimento e cor:** o modo suave, o aviso e a paleta azul e laranja estão completos. A foto 3x4 é parada, de propósito.

## 6. O que funciona bem

- **A linguagem de papel está madura.** Bilhetes, dossiê, folha de atalhos, carimbos e foto com clipe parecem do mesmo arquivo da Ordem.
- **As cartas** agora são legíveis a 1280×720, com tecla em selo e cadeado com motivo.
- **A investigação** tem o melhor clima do jogo: escuridão, círculos de sigilo dourados, REC, urgência com risquinhos, quadro com espaços "?".
- **Rastreador do caso, desfecho e motivo dos bloqueios** resolveram as maiores dúvidas do playtest ("o que eu faço?", "o que aconteceu?", "por que está cinza?").
- **A acessibilidade** saiu do básico: escala, leitura, flashes, daltonismo, atalhos remapeáveis, tudo num lugar só, na pausa e na Base.

## 7. Opções priorizadas

| # | Opção | Esforço | Impacto |
|---|---|---|---|
| **C1** | **Clima de terror no mundo 3D**: noite azulada e dessaturada no mapa e no título, com luz da lua, névoa baixa, tiles a ~60% de saturação e janelas acesas nas vilas. O véu da Membrana pesa mais a partir de 75. O chão do combate herda o terreno do encontro | Médio | Muito alto (identidade) |
| **C2** | **Chance nas escolhas**: componente `LinhaTeste` (dados, bônus, DT e "≈ N%") no evento, no Facilitar, no Procurar e no ataque; a melhor opção do agente marcada; tooltip do −5 | Baixo a médio | Alto |
| **C3** | **Vez da ameaça (E4)**: faixa com o retrato e a intenção; a mão desce durante a vez dela | Baixo | Médio |
| **C4** | **Limpeza**, numa rodada só: <br>• tirar "Último teste" e os slots do dock; <br>• trocar o asterisco por tooltip; <br>• tinta 60% → 75%; <br>• textos de 13 para 14 px; <br>• foto 3x4 na Base; <br>• carimbo fora do botão; <br>• foco do evento sem trocar de fonte; <br>• seleção em borda dourada | Baixo | Médio |
| **C5** | **Arsenal e ficha da Base**: "Equipando: X", nomes inteiros, ícones por tipo, ficha em blocos com pentágono de atributos | Médio | Médio |
| **C6** | **Investigação mais limpa**: quadro fechado por padrão com pulso na pista nova, rótulos fora do HUD, peças por tipo de ponto | Baixo a médio | Médio |
| **C7** | **Briefing procedural** na aba Missão e **cerimônia de NEX** no relatório (E7) | Baixo | Médio |
| **C8** | **Sala por código e saguão animado** (E8) | Médio | Médio (online) |

### Pacote recomendado (uma rodada)

**C2 + C3 + C4.** Juntos, resolvem a decisão sem informação, o combate mudo na vez da ameaça e as pendências que se arrastam desde a crítica 15. São mudanças de interface, sem arte nova.

O **C1** merece uma rodada própria: mexe em luz, ambiente e materiais do mapa, do título e do combate, e pede capturas de antes e depois.

![Base, Agentes](critica20_base0.png)
![Arsenal](critica20_base1.png)
![Missão](critica20_base2.png)
![Rituais](critica20_combate_ritual.png)
![Investigação](critica20_investigacao.png)
![Fim](critica20_fim.png)
![Pausa](critica20_pausa.png)
![Saguão](critica20_saguao.png)
