# O caçador que volta e as dicas de primeira vez

> Status: **v0.1**, 23/10/2026. Terceiro passo recomendado depois do docs/72: "o caçador único e persistente, e o tutorial e as dicas sobre munição, Oficina, fobias, subgênero, fuga e culto". As decisões de estrutura estão no ADR 0016.
>
> **Não é regra do livro.** O caçador é design do jogo, inspirado no assassino que sempre volta do slasher e no diretor de Alien: Isolation (docs/53). O livro entra no orçamento de VD (p.187), que escolhe por onde ele começa.

## O caçador da Perseguição

Antes, a Perseguição (docs/71) só mexia nos números da caça noturna, e nos testes não ficava mais difícil. Agora ela tem um **caçador**:

- **Quem é:** uma criatura do elemento do caso. Ele começa no primeiro degrau da lista e sobe um a cada vez que volta:

  | Elemento | 1º (VD 20) | 2º (VD 25) | 3º (VD 40) |
  |---|---|---|---|
  | Sangue | zumbi de sangue | horror carmesim | aberração de carne |
  | Morte | esqueleto de lodo | arauto cinzento | succ |
  | Conhecimento | existido | máscara dourada | vulto |
  | Energia | anárquico | estática viva | perturbado de energia |

  O primeiro degrau cabe no orçamento de um grupo novo. O Medo não é elemento de caso, então não tem caçador.
- **Onde começa:** num hex livre, a pelo menos 6 hexes do grupo. O registro avisa: "Algo segue o grupo".
- **Como anda:**
  - todo turno do mundo, de dia (um passo) e de noite (dois passos);
  - vai atrás do agente mais isolado, onde quer que ele esteja: ele sente o grupo;
  - contorna rio e mata pelo caminho mais curto, enquanto os outros que caçam andam em linha reta;
  - vilas e o ponto de encontro continuam seguros.

  Quando alcança alguém, a luta começa ali, com quem estiver por perto.
- **No mapa:** a peça dele tem o rótulo **CAÇADOR**, em vermelho.
- **Derrubado:**
  - ele se desfaz e **volta em 3 turnos**, um degrau acima, longe do grupo;
  - a linha do tempo avisa "ele volta" no turno certo.
- **Para sumir de vez:** a Ordem precisa saber o que ele é, ou seja, o relatório com **o quê** respondido (o elemento confirmado, docs/52). Vencida a luta com isso, ele é preso de vez e a Membrana sobe 3.
- **Fugir dele** (docs/72): o grupo foge e ele fica no hex da luta. Se o grupo cai, ele também continua ali.

![A dica do caçador ao começar a Perseguição](i74_dica_cacador.png)

![O caçador no mapa, com o rótulo](i74_cacador.png)

![Depois de derrubado: "ele volta" no turno 10](i74_ele_volta.png)

## As dicas de primeira vez

Um bilhete curto no alto da tela, na primeira vez que um sistema aparece na partida.
- **Não bloqueia nada:** a tela segue jogável.
- **"Entendi"** não mostra mais aquela dica.
- **"Sem dicas"** desliga todas.
- **Na aba Jogadores**, em Preferências, há a caixa "Mostrar dicas" e o botão **Rever as dicas**.

| Dica | Quando aparece |
|---|---|
| Munição | na vez de um agente com arma de fogo |
| Fugir | na vez de um agente, quando alguém do grupo está com metade dos PV ou caído |
| A caçada | quando o relatório do fim oferece "Caçar o fugitivo" |
| A Oficina | ao abrir a aba Arsenal |
| Traumas | na Base, quando alguém tem fobia |
| O caçador | ao começar uma missão de Perseguição |
| O subgênero | ao começar uma missão de Isolados ou de Transmissão |
| O culto por trás | na cena de investigação com o símbolo na parede |

Os textos ficam em `data/jogo/tutorial.json`, no bloco `dicas`.

![A dica de fuga no combate](i74_dica_fuga.png)

![A dica da Oficina ao abrir o Arsenal](i74_dica_oficina.png)

## O tutorial

Os tours por tela ganharam o que faltava, sem passar de oito passos (um teste do jogo cobra isso):
- **Base:** a requisição fala de munição e da Oficina; a ficha fala de fobia e da Enfermaria.
- **Mapa:** um passo novo sobre o caso, o culto, o subgênero e o caçador (no quadro "O caso").
- **Combate:** um passo novo sobre Fugir (no botão).
- **Investigação:** um passo novo sobre o símbolo do culto.

## Playtest

**Pela interface** (1280×720), missão 777 com a Perseguição, caso de Morte:
1. A dica do caçador apareceu, e o esqueleto de lodo começou do outro lado do mapa.
2. Ele andou um hex de dia e dois à noite, contornou o terreno e alcançou o Cléber no turno 7.
3. No combate apareceram as dicas de munição (na vez da Rita) e de fuga (com um agente ferido).
4. Derrubado, ele marcou a volta para o turno 10; a linha do tempo mostrou "ele volta" e, no turno 10, ele voltou como arauto cinzento.
5. Na Base, apareceram a dica de traumas e, ao abrir o Arsenal, a da Oficina.

**Playtest automático** (docs/67): ganhou um parâmetro de subgênero (`playtest_auto.gd -- <pasta> perseguicao`). O clássico não mudou; a Perseguição ficou mais dura, como devia:

| Perfil | Clássico | Perseguição |
|---|---|---|
| Investigador | 100%, 7,1 turnos | 90%, 7,0 turnos, 0,4 emboscada por missão |
| Pressa | 90%, 10,8 turnos | 60%, 8,1 turnos, 0,7 emboscada por missão |

- **Quem anda junto** quase não sente o caçador. **Quem se separa**, como o perfil "pressa", é pego sozinho.
- **O piloto não foge.** Um jogador pode fugir da emboscada (docs/72).
- **A primeira versão** usava as criaturas de VD 40 desde o começo. Nos testes, o grupo de NEX 5 perdia quase sempre (0 de 17 contra o plasma). Daí a escada de degraus.

**Testes:** 798 passando. Os novos estão em `test_cacador_e_dicas.gd`.

## O que ficou de fora

- **O piloto e o playtest automático** não decidem fugir.
- **Dicas de outros sistemas** (itens de campo, rituais no mapa, interlúdio) podem entrar como novas entradas em `dicas`.
- **Os outros que caçam à noite** continuam andando em linha reta. Só o caçador contorna obstáculos.
