# Crítica de design: acessibilidade e engajamento

> Status: **v0.1**, 20/10/2026. Revisão do produto **como está hoje**, depois dos docs 08 a 14, em todas as telas:
> - título;
> - Base (4 abas);
> - mapa, com briefing, evento, rolagem, ação, ficha e pausa;
> - combate;
> - investigação;
> - relatórios;
> - saguão;
> - editor.
>
> **Base da análise:** capturas a 1280 × 720, contraste medido pela fórmula do WCAG e a suíte de testes (429 testes).

## Impressão geral

O jogo já **tem identidade**: dossiê, sigilos, VHS, cortiça e a caixinha desafinada formam um terror investigativo coerente, e as telas de jogo têm a leitura de um RPG (HUD flutuante, cartas, rolagem no centro).

A maior oportunidade agora **não é visual**. É **orientar e recompensar o jogador**:
- o que eu faço agora;
- o que aconteceu por causa da minha escolha;
- quanto falta para resolver o caso.

E também **deixar o jogo jogável para mais gente**: texto pequeno, estados apagados sem explicação, atalhos invisíveis.

## 1. Primeira impressão (2 segundos)

| Tela | O que chama atenção primeiro | Está certo? |
|---|---|---|
| Título | O logo e o sigilo se desenhando; "Continuar carreira" com moldura | ✅ |
| Base | O carimbo CONFIDENCIAL e a ficha em papel | ⚠️ O jogador novo procura o "jogar", que fica escondido na aba **Missão** |
| Mapa | O grupo no centro e a Membrana no topo | ✅, mas o **objetivo** (o caso) não aparece |
| Evento | O bilhete com as opções | ✅ |
| Combate | As cartas e os retratos | ⚠️ Não está claro **de quem é a vez** quando é a vez de uma ameaça |
| Investigação | O quadro de cortiça e o bilhete | ✅ |
| Saguão | Uma folha de papel **vazia** | ❌ Parece travado |

## 2. Usabilidade

| Achado | Gravidade | Recomendação |
|---|---|---|
| O **desfecho** de um evento ("ele se acalma e indica uma trilha") só aparece no relatório recolhido. A rolagem mostra SUCESSO ou FALHA, mas não o **que aconteceu** | 🔴 Crítico | Bilhete de **desfecho**: o texto do resultado e os efeitos em ícones (+PV, −SAN, Membrana, revelou mapa) por 2 a 3 s, ou até um clique |
| Não há **criação de agente**: recrutar é um dropdown com um nome pronto ("Tiago (combatente)"). A persona "fã de OP" quer **criar o próprio agente** (docs/00) | 🔴 Crítico (engajamento) | Tela de **ficha nova** no estilo dossiê: nome, origem, classe, atributos (pontos), perícias e a foto (sigilo). A regra já existe em `CriacaoAgente` |
| Na Base, o fluxo principal (montar o grupo e iniciar) fica na **3ª aba**; a 1ª aba abre a ficha | 🟡 Moderado | "Continuar" e "Começar" abrem a Base **na aba Missão**, com "Iniciar missão" em destaque. A aba Agentes fica para quem quer mexer |
| **Atalhos invisíveis**: 1–5, F, C, E, Tab, Esc, WASD só aparecem em alguns tooltips | 🟡 Moderado | Dica de tecla **dentro do botão** ("Rolar [Espaço]", "Ficha [F]") e uma **folha de atalhos** (tecla H ou na pausa) |
| Estados **apagados sem motivo**: "Ação", "Descansar" e "Ritual" ficam cinza sem dizer por quê | 🟡 Moderado | Tooltip do motivo ("Só numa vila", "Sem PE", "Já usou a ação do turno") e um ícone de cadeado |
| No combate, a vez das ameaças passa rápido e sem aviso; a rolagem central de cada ataque pode se acumular | 🟡 Moderado | **Faixa "VEZ DO CULTISTA"** com o retrato da ameaça. Rolagem das ameaças em versão compacta, perto do alvo; a central fica para os testes do jogador |
| **Objetivo e progresso** do caso só aparecem no briefing e no quadro da investigação | 🟡 Moderado | **Rastreador do caso** no HUD do mapa: as 3 perguntas (0/2, 1/2, ✔) e um aviso quando o covil for revelado |
| A ficha mostra "* ainda sem efeito no motor" (nota de desenvolvimento) | 🟢 Menor | Esconder do jogador. O asterisco vira um tooltip discreto ("efeito ainda não implementado") |
| Aba Jogadores: "7777", "127.0.0.1" e "seu nome" são termos de rede | 🟢 Menor | "Criar sala" (mostra um **código** para compartilhar) e "Entrar na sala" (campo do código). A porta e o IP ficam num "Avançado" |
| Saguão "Conectando…" com papel vazio | 🟢 Menor | Animação de espera (sigilo girando e REC) e texto explicando o que acontece |
| Investigação: rótulos 3D grandes cortados na borda; a dica do hover fica presa | 🟢 Menor | Rótulos menores, só no hover ou perto; a dica some quando o mouse sai da vista |
| "Último teste" no canto do combate repete a rolagem central | 🟢 Menor | Remover e manter o histórico no relatório |

## 3. Hierarquia visual

- **O que chama atenção primeiro:** acerta no título, no mapa e na investigação. No combate, as cartas competem com o "Ataque Especial" e o Foco, que estão no mesmo nível visual. O Foco deveria ficar dentro do bilhete da carta Atacar.
- **Fluxo de leitura:** topo (situação) → centro (mundo e rolagem) → embaixo (grupo e ações). É bom e consistente entre as telas.
- **Ênfase:** o botão principal (sangue com ouro) está certo. Mas **há moldura riscada em tudo**: painel, botão, aba e campo, e o traço perde força como sinal. Recomendação: o traço **dourado** fica para o que é interativo e importante; os painéis passivos ganham traço mais apagado.

## 4. Consistência

| Elemento | Problema | Recomendação |
|---|---|---|
| Rolagens | Movimento, eventos, ataques e investigação usam a rolagem central, mas o **dock do mapa** ainda mostra os slots pequenos | Manter só um formato. Os slots pequenos viram histórico no relatório |
| Fechar overlays | Esc fecha a pausa, a ficha e o diálogo; um clique fecha a rolagem e a ficha, mas **não** a pausa | Mesma regra para todos: Esc e clique fora fecham |
| Retratos | 176 px na investigação e no combate, 150 px no mapa | Um tamanho só (150) |
| Textos de papel | A maioria em máquina de escrever, mas os títulos dos papéis da Base misturam Cinzel e Alegreya | Títulos de papel em Cinzel; corpo em máquina de escrever |

## 5. Acessibilidade (medido)

**Contraste (WCAG 2.1):**

| Par | Razão | Resultado |
|---|---|---|
| Texto pergaminho / painel | 13,8 | ✅ AA |
| Texto suave / painel | 6,7 | ✅ AA |
| Subtítulo ouro / painel | 5,9 | ✅ AA |
| Perigo / painel | 4,9 | ✅ AA |
| Tinta / papel (e sobre as manchas) | 11,4 / 7,1 | ✅ AA |
| Tinta a 70% (dica das cartas) / papel | 4,9 | ✅ AA |
| Tinta a 60% (notas nos bilhetes) / papel | 3,7 | ⚠️ Só texto grande |
| Carimbo sangue claro / papel | 4,0 | ⚠️ Só texto grande (os carimbos são grandes: ok) |
| **Botão desabilitado / pedra** | **2,5** | ❌ Ilegível. Falta dizer **por que** está desabilitado |
| **Tinta a 35% (desabilitado no papel)** | **2,0** | ❌ |
| **Borda dos campos (ouro escuro) / painel** | **2,2** | ❌ Abaixo de 3:1 para componentes (WCAG 1.4.11): os campos "seu nome" e a porta somem |

**Tamanho de texto (a 1280 × 720):**
- legendas das fotos do quadro: 10 px;
- dicas das cartas e PV/PE/SAN dos retratos: 12 px;
- número do atalho nas cartas: 12 px.

Em telas de notebook a 1080p com escala, isso fica pequeno. **Não existe escala de interface.**

**Outros pontos:**
- **Cor sozinha:** os slots têm ✓/✗ e o caído tem ✝ (bom). O destino no mapa é só azul, mas a dica diz "Clique para ir" (aceitável).
- **Movimento e brilho:** dá para desligar estática, glitch e granulação (bom). **Falta:** a velocidade da datilografia (ou texto instantâneo) e o **tempo da rolagem** (1,5 s pode ser rápido para ler).
- **Controles:** sem **remapeamento de teclas**. O controle funciona no mapa, no combate e na investigação.
- **Fotossensibilidade:** o glitch pisca rápido em faixas (até 18 vezes/s). Recomendo deixar o padrão mais suave e pôr um aviso na primeira abertura.

## 6. O que funciona bem

- A **identidade**: cada estética no seu contexto (docs/09) é reconhecível e coerente.
- **Feedback físico**: dados girando, carimbo batendo, fio vermelho, números de dano, som de tecla.
- **Pista central sem dados** (docs/14): tira a frustração de "travar o caso por um dado", que é a frustração número 1 de RPG investigativo.
- **Ajustes de conforto** já existem: efeitos, som ambiente, volume e câmera.
- A **suíte de testes** (429) cobre regras, comandos online e as telas principais: dá para mexer no visual com segurança.

## 7. Testes e medição

- **Cobertos:** regras, comandos (lockstep), carregamento das telas, componentes visuais e o tutorial (alvos e abertura).
- **Não cobertos:** como o jogador **se sente**. Não há dado de playtest. O docs/07 já prevê estatísticas do tutorial em `user://preferencias.json`.
- **Recomendações:**
  1. **Telemetria local opcional** (sem rede): tempo até a primeira ação, eventos abandonados, onde o tour é pulado, quantas vezes a ficha é aberta.
  2. **Roteiro de playtest** do docs/08 (5 hipóteses), agora com as telas reais.
  3. **Testes de captura** (screenshot) das telas principais, para pegar regressões de layout (como a sobreposição do dock que apareceu no playtest).

## 8. Opções priorizadas

### Acessibilidade

| # | Opção | Esforço | Impacto |
|---|---|---|---|
| A1 | **Escala da interface** (80 a 150%) e **tamanho mínimo de 14 px** nos textos de jogo | Baixo | Alto |
| A2 | **Motivo do desabilitado** (tooltip e cadeado) e contraste 4,5:1 nos rótulos desabilitados; **bordas de campo** com 3:1 | Baixo | Alto |
| A3 | **Velocidade do texto** (lenta, normal, instantânea) e **duração da rolagem** (curta, normal, até clicar) | Baixo | Médio |
| A4 | **Remapeamento de teclas** e folha de atalhos (H) | Médio | Médio |
| A5 | **Modo de fotossensibilidade**: glitch suave por padrão e aviso no primeiro uso | Baixo | Médio |
| A6 | **Paleta para daltonismo**: trocar o par vermelho/verde do sucesso por dourado/azul, além do ✓/✗ | Baixo | Médio |

### Engajamento

| # | Opção | Esforço | Impacto |
|---|---|---|---|
| E1 | **Bilhete de desfecho** depois de cada evento e teste: o que aconteceu, com os efeitos em ícones | Baixo | Alto |
| E2 | **Criação de agente** em dossiê (nome, origem, classe, atributos, perícias, foto/sigilo) | Médio | Muito alto |
| E3 | **Rastreador do caso** no HUD do mapa (as 3 perguntas e o covil) | Baixo | Alto |
| E4 | **Faixa da vez da ameaça** e intenção ("vai atacar Rita") no combate | Baixo | Médio |
| E5 | **Base abre na aba Missão**, com "Próxima operação" em destaque | Muito baixo | Médio |
| E6 | **Sanidade com consequência visual**: com SAN baixa, o turno daquele agente tem sussurros, falhas e alucinações (uma figura que some) | Médio | Alto (terror) |
| E7 | **Cerimônia de NEX/patente** no relatório: o carimbo de promoção e o novo poder | Baixo | Médio |
| E8 | **Sala online por código** e saguão animado | Médio | Médio |

### Pacote recomendado (uma rodada)

**E1 + E3 + E5 + A1 + A2 + A3**: tudo de baixo esforço. Responde ao "o que aconteceu" e ao "o que falta" e deixa o jogo legível para mais gente.

Na rodada seguinte: **E2** (criação de agente) e **E6** (sanidade com consequência), que são os dois que mais aproximam o jogo da experiência de Ordem Paranormal.
