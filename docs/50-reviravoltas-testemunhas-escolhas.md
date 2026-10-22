# Mais conteúdo: reviravoltas, testemunhas e escolhas morais

> Status: **v0.1**, 21/10/2026. Pedido: "faz mais conteúdo: novas ampliações e reviravoltas, cenas com testemunhas e eventos de escolha moral". Todo o texto é original; os números seguem as regras já usadas (DTs 12 a 18, PP da Tabela 3.2, p.63).

## Reviravoltas: de 3 para 6

Cada caso sorteia uma reviravolta, revelada na primeira acusação certa (investigação ampliada, p.79, docs/36). As novas seguem a mesma regra da tabela: 4 candidatos de 3 traços, e dois candidatos nunca dividem mais de um traço.

| Reviravolta | A revelação | Pergunta | Candidatos | Ao acertar |
|---|---|---|---|---|
| **Próxima vítima** | A lista não acabou: o culpado ainda precisa de alguém | Quem será a próxima vítima? | o padre, o dono do armazém, a filha do prefeito, o menino do jornal | Membrana +10 (a vítima sai da cidade a tempo) |
| **Mandante** | Alguém que nunca aparece paga as contas e dá as ordens | Quem financia o culpado? | um vereador, um fazendeiro poderoso, um colecionador de antiguidades, um apresentador de TV | Chefe mais fraco (−20% PV) |
| **Origem** | A cidade abafou um primeiro caso, anos atrás | Onde tudo começou? | o incêndio do cinema, a grande enchente, o sumiço da excursão, o desabamento na pedreira | Membrana +10 |

São 25 traços novos, cada um com o seu texto de indício. Por exemplo, "Ficha de doação com o tipo sublinhado duas vezes" (sangue raro) ou "Canhotos de pedágio da capital, ida e volta no mesmo dia".

## Cenas com testemunhas: de 5 para 8

As três cenas novas têm **duas testemunhas**, que falam de perguntas diferentes, além de um ponto firme para cada pergunta (docs/44). Cada testemunha pode hesitar e dar um depoimento duvidoso (docs/35). Com duas na mesma cena, elas podem se contradizer.

| Cena | Terrenos | Pontos firmes | Testemunhas |
|---|---|---|---|
| **Velório na capela mortuária** | cidade, campo, morro | caixão pregado (o quê), livro de condolências (quem), coroa de flores (onde) | a viúva (quem), o agente funerário (onde) |
| **Delegacia do interior** | cidade, estrada | pilha de boletins (quem), armário de provas (o quê), rádio da viatura (onde) | o escrivão de plantão (o quê), o preso na cela (quem) |
| **Rodoviária de madrugada** | estrada, cidade, campo | guichê (quem), mala no bagageiro (o quê), quadro de horários (onde) | a bilheteira (onde), o engraxate (o quê) |

Cada cena tem duas formas de **Facilitar**, como as outras.

**Na tela:**
- Duas peças novas: o **caixão** em cavaletes, com uma vela em cada ponta, e a **coroa de flores** no tripé, com a faixa sem nome.
- As testemunhas usam a figura de pessoa.
- Um teste novo garante que **todo ponto de toda cena tem peça 3D**.

![O velório: a coroa à esquerda, o caixão à direita e as duas testemunhas ao fundo](velorio50.png)

## Escolhas morais: 7 eventos

O "Pedido de socorro" (docs/37) era a única escolha moral do mapa. Agora são sete, marcadas com `"moral": true`:
- O cabeçalho do bilhete troca **EVENTO** por **ESCOLHA DIFÍCIL**, em vermelho-sangue.
- Uma linha avisa que nenhuma saída é segura.
- **Toda opção tem um custo**, garantido por teste, seja no sucesso, seja no risco da falha.
- Os custos são os que o sistema conta:
  - **inocente morto** (−2 PP no fim, Tabela 3.2);
  - **Membrana** (tempo perdido e medo espalhado);
  - **SAN** e **PV**;
  - **um covil mais forte**.

| Evento | O dilema |
|---|---|
| **O vídeo** | Um adolescente filmou a criatura e vai postar. Convencer, furtar o celular, assustar o garoto (mais fácil, mas custa SAN) ou deixar postar (Membrana −8). |
| **O cultista ferido** | Um rapaz de túnica sangra. Salvar dá uma pista. Interrogar até o fim dá **duas pistas**, mas ele morre e custa SAN. Também dá para chamar a polícia ou deixar que fuja (o **chefe fica mais forte**). |
| **O coração de pedra** | Uma pedra cura quem está perto, drenando um homem que dorme ao lado. Usar cura muito, mas **mata o homem**. Também dá para quebrá-la, tirar o homem dali ou ir embora. |
| **Casa em chamas** | Uma família presa no fogo, e o rastro da criatura esfriando. Salvar custa tempo. Seguir o rastro **revela o covil**, mas custa um inocente. |
| **Simpatia na encruzilhada** | Moradores rezam um círculo que abre em vez de proteger. Mentir, contar a verdade (o medo se espalha), desfazer o desenho escondido ou, treinado em Ocultismo, usar o círculo para ver o covil (custa SAN). |
| **O agente desaparecido** | Um agente da Ordem possuído pede para acabar. Trazê-lo de volta (Religião DT 18), ouvir a voz (revela o covil, custa SAN), fazer o que ele pede ou deixar para o resgate. |
| **Pedido de socorro** | (já existia) agora com o mesmo cabeçalho. |

**Efeito novo, `chefe`:** muda os PV do chefe do covil em porcentagem (`+10` = 10% a mais). É a mesma alavanca das perguntas do caso (chefe enfraquecido, −20%). O bilhete do desfecho mostra "Chefe +10% PV" em vermelho.

![A escolha difícil da casa em chamas](moral50_evento.png)

## Medido (`dev/playtest_auto.gd`, 10 seeds; números brutos em `docs/playtest50.json`)

| Perfil | Vitória | Solucionado | Turnos | PP | Eventos (morais) | Inocentes mortos | Duvidosas |
|---|---|---|---|---|---|---|---|
| Investigador | 0,9 | 0,9 | 6,3 (era 7,9) | 13,3 (era 11,9) | 3,3 (1,4) | 0,1 | 1,4 |
| Pressa | 0,8 | 0,5 | 10,7 (era 9,9) | 20,1 (era 17,3) | 7,1 (3,0) | 0,2 | 2,1 |

- **Escolhas morais aparecem** de 1 a 3 vezes por missão. O jogador simulado prefere a opção com teste, por isso quase não morre inocente. Um jogador que corta caminho ("seguir o rastro", "usar a pedra") paga em PP.
- **As seis reviravoltas saem**: na amostra, "quando" 3 vezes, "mandante", "objeto" e "vítima" 2 vezes cada, "origem" 1.
- **As missões do investigador ficaram mais curtas** (6,3 turnos, era 7,9). Os mapas mudaram com o sorteio maior, e as cenas novas têm 5 pontos, então as perguntas fecham mais cedo. Está dentro do que docs/42 queria, mas fica de olho.
- **O PP do perfil "pressa" continua alto** (20 por missão), por causa das pistas adicionais (2 PP cada) de quem roda o mapa todo. Isso já acontecia antes (17,3) e não mudou de natureza.

## Onde está

- **Dados:**
  - `data/jogo/casos.json`: `ampliacoes` e `indicios`;
  - `data/jogo/cenas_investigacao.json`: as três cenas;
  - `data/jogo/eventos.json`: os seis eventos novos, `moral` no socorro e `chefe` em `efeitos_possiveis`.
- **Regra:** `Missao._aplicar_efeito` trata o efeito `chefe`.
- **Tela:**
  - `MapaMundo` mostra o cabeçalho e o aviso da escolha difícil;
  - `BilheteDesfecho` dá a cor do selo do chefe;
  - `PropsInvestigacao` ganha o caixão, a coroa e as palavras das testemunhas novas.
- **Playtest:** conta os eventos morais e qual reviravolta saiu.

## Testes

Total: **571**. Arquivo `test_conteudo.gd`:
- **Reviravoltas:**
  - As seis existem, com todos os traços descritos.
  - A da próxima vítima abre a pergunta, com 4 candidatos.
- **Cenas:**
  - As três novas têm duas testemunhas, de perguntas diferentes.
  - O velório roda.
  - Todo ponto tem peça 3D.
- **Escolhas morais:**
  - Toda opção dos sete eventos tem um custo.
  - O efeito `chefe` mexe no covil.
  - Seguir o rastro revela o covil e custa um inocente.
  - O cabeçalho troca entre ESCOLHA DIFÍCIL e EVENTO.

A regra "uma testemunha por cena" de `test_investigacao.gd` passou a aceitar duas.
