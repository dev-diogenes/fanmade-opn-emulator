# Itens de campo, fuga e caçada

> Status: **v0.1**, 22/10/2026. Dois pedidos do dono do projeto:
> - dar efeito aos itens paranormais de investigação, às amarras como armadilha, à mina, às algemas e ao arremesso;
> - conferir as ações de batalha, criar a fuga e a caçada "semelhante ao livro", corrigir o covil que travou a partida e fazer um playtest.
>
> A decisão de estrutura está no ADR 0015.

## Itens paranormais (p.76-77)

| Item | Onde | Custo | Efeito no jogo |
|---|---|---|---|
| Câmera de aura | investigação (selo Procurar) | 1 PE e a ação | Tira a dúvida de um depoimento incerto: confirma o traço (vira pista firme) ou o desmente (sai do quadro com ✗) |
| Medidor da Membrana | mapa (Ação) | a ação; pede Ocultismo treinado | Mostra as criaturas a até 4 hexes e quanto falta para a próxima surgir |
| Scanner (um por elemento) | mapa | 1 PE e a ação | Aponta tudo do elemento a até 8 hexes. Se o caso for desse elemento, aponta também o covil |
| Escuta de ruídos | mapa | 2 PE e a ação | Instalada, vale a missão inteira: +5 em Ocultismo para identificar criaturas (decifrar o enigma) |
| Emissor de pulsos | mapa, escolhendo o elemento | 1 PE e a ação | Puxa 2 hexes para perto as criaturas do elemento e afasta 2 hexes as do elemento que ele oprime |

No mapa, os itens entram no bilhete **Ação do turno**. Item sem uso possível fica apagado, e a dica explica por quê: falta treino, PE, a ação, ou a escuta já está instalada.

![O bilhete de ação com os itens paranormais](i72_mapa_itens.png)

## Itens de combate

- **Arremesso (p.64):** faca, lança e machadinha têm o botão **Arremessar**.
  - O ataque vira de Pontaria, em alcance curto, e a Força soma no dano.
  - Outras armas corpo a corpo também podem ser arremessadas, com −1 dado.
  - A arma cai perto do alvo. Para usá-la de novo, o agente vai até ela e usa **Pegar a arma**.
- **Amarras (p.76):** têm dois usos.
  - **Laçar** (ação padrão, 1 PE): paralisa a criatura do elemento. Ela repete a Vontade a cada turno, e o dono paga 1 PE por rodada para manter, mesmo fora do turno dele.
  - **Armadilha** (ação completa, 2 PE): as amarras ficam no chão numa área de 3×3 m, que vira terreno difícil. Quem entra testa Reflexos ou fica imóvel até o fim da cena.
- **Mina antipessoal (p.74):**
  - **Instalar:** ação completa, Tática DT 15 e Tática **treinada**. Falhando no teste, a mina se perde.
  - **Detonar:** ação padrão, de até alcance longo. Causa 12d6 num cone de 6 m e pega quem estiver na frente, aliado ou não.
- **Algemas (p.74):** ação padrão. Quem está caído, inconsciente ou paralisado é algemado direto; quem está de pé, só se estiver agarrado por você. Quem é algemado se rende, sai da luta e vai para o interrogatório.

No tabuleiro, a armadilha aparece na cor do elemento, e a mina, em âmbar no espaço onde foi instalada. No bilhete de itens, armadilha e mina ficam apagadas quando a ação completa já foi gasta.

![A armadilha de Sangue no meio do tabuleiro e a mina sob a Rita](i72_armadilha_e_mina.png)

## Fuga e caçada

**Não é um subsistema do livro.** O núcleo não tem regra de perseguição. Usamos o **teste estendido** dele (p.86-87):
- o grupo junta sucessos antes de três falhas;
- 3, 5 ou 7 sucessos, pela complexidade;
- cada um testa por rodada;
- na variante aberta, cada um usa a perícia que explicar como ajuda.

A lista de perícias de cada teste é nossa. A peça de regra é `TesteEstendido` (`game/scripts/rules/teste_estendido.gd`): cada agente usa a melhor perícia da lista que ainda não usou naquele teste.

### Fugir

É uma ação completa do agente da vez, e vale para o grupo todo. Cada agente de pé testa uma perícia de fuga: Atletismo, Acrobacia, Furtividade, Percepção, Sobrevivência, Pilotagem ou Tática.

| Quem persegue | Complexidade | Sucessos | DT |
|---|---|---|---|
| Gente e bicho | baixa | 3 | 15 |
| Criatura do Outro Lado | média | 5 | 20 |
| O chefe do covil | alta | 7 | 25 |

- **Cada falha:** o perseguidor mais forte (o de maior VD) alcança quem tropeçou e ataca.
- **Fugiu:** o combate acaba como "fuga" e o relatório ganha o carimbo **O GRUPO FUGIU**. No mapa:
  - o encontro (ou o covil) continua lá;
  - o grupo recua para um hex livre vizinho e ganha um respiro da caça;
  - a Membrana cai 2;
  - quem caiu na fuga foi carregado pelos outros e volta com 1 PV.
- **Três falhas:** o grupo fica encurralado e desprevenido, e a luta segue.
- **Ninguém foge deixando um agente preso:** com alguém agarrado, imóvel ou paralisado, o botão fica apagado e diz por quê.

![O relatório da fuga](i72_fuga.png)

### A ameaça que foge e a caçada

Uma **pessoa** (não uma criatura) foge quando:
- tem um quarto dos PV ou menos;
- é a última de pé do lado dela;
- a luta não é no covil.

Criaturas do Outro Lado não fogem.

No fim da luta, o relatório oferece **Caçar o fugitivo**: um teste estendido de complexidade baixa (3 sucessos, DT 15), com Atletismo, Percepção, Sobrevivência, Investigação, Intimidação ou Pilotagem.
- **Pegou:** o fugitivo se rende e vai para o interrogatório (docs/40), como os rendidos.
- **Escapou, ou ninguém foi atrás:** ele avisa o culto, e a Membrana cai 2 por fugitivo.

![A caçada no relatório do fim](i72_cacada.png)

## As ações de batalha, conferidas

Uma sonda jogou um encontro inteiro pela interface da arena. **Mover**, **Atacar**, **Ritual** e **Item** (o cicatrizante) funcionaram, com o gasto certo de ações e PE.

O javaporco é muito letal no NEX 5 (Ferocidade e críticos), mas isso segue a ficha do livro.

## Correções

- **O covil apagado pela caça** (o bug da partida do dono do projeto, já publicado em 4a06766): vencer a caça em cima das ruínas do covil apagava o covil, e a missão não tinha mais como acabar. Agora só sai do mapa o que era o encontro.
- **Os rendidos sumiam no fim do combate:** o fim da cena limpava a marca de rendido, e a arena contava zero presos para o interrogatório. A marca agora sobrevive, e o mesmo vale para algemado, fugiu e escapou.
- **As alucinações** (no mesmo commit do covil): a visão girava antes de entrar na cena e gerava erro no console.
- **A mina sem Tática:** a tentativa sem treino gastava o item. Agora nem tenta.
- **A faixa "Vez da ameaça":** ficava acesa quando o fugitivo encerrava a luta no turno dele.

## Playtest

Uma sonda pela interface (1280×720) fez a missão inteira de uma vez:

1. **No mapa:**
   - o bilhete mostrou os oito usos de item, com o medidor apagado porque o agente não tinha Ocultismo;
   - o scanner de Sangue rodou e não achou sinal por perto.
2. **Contra uma célula cultista:**
   - a Bianca armou as amarras de Sangue (6 → 4 PE);
   - o Cléber arremessou a faca, e ela caiu ao lado do capanga;
   - a Rita instalou a mina;
   - na segunda rodada, o grupo fugiu com 3 sucessos seguidos.
   - De volta ao mapa: o encontro continuava no hex, o grupo estava no vizinho e a Membrana tinha caído 2.
3. **De volta ao encontro:**
   - o bandido, quase morto e sozinho, fugiu no turno dele;
   - a caçada o pegou com 3 sucessos;
   - ele virou preso da Ordem, e a Membrana não caiu.

O playtest automático (docs/67) ficou estável:

| Perfil | Vitórias | Turnos |
|---|---|---|
| Investigador | 100% | 6,8 |
| Pressa | 90% | 10,5 |

**Testes:** 771 passando. Os novos estão em:
- `test_itens_de_campo.gd`;
- `test_fuga_e_cacada.gd`;
- `test_regressoes_partida.gd`.

## O que ficou de fora

- **A IA dos agentes** (o playtest automático e o piloto) não decide fugir. A fuga é sempre escolha do jogador.
- **Algemas e câmera de aura pela interface:** a sonda não usou as duas. Ambas estão cobertas por testes de unidade.
- **A fuga das ameaças** é só a de pessoas fora do covil. O chefe e as criaturas lutam até o fim.
