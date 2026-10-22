# O arsenal do livro

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: os itens devem ser os do livro de regras. Este documento cobre o equipamento: armas, munição, proteções, equipamento geral e itens paranormais (cap. 3, p.66-77). Os rituais e poderes vêm em outro documento.
>
> Páginas: a numeração do PDF, como no resto do projeto. O docs/64 usava a numeração impressa (p.52-53) e foi corrigido para p.62-63.

## O que faltava

O jogo tinha 10 armas, 2 proteções e 22 itens. O livro traz:
- 34 armas na Tabela 3.3;
- 6 munições;
- 3 proteções, contando o escudo;
- uns 35 itens entre acessórios, explosivos, itens operacionais e itens paranormais.

Também faltavam as regras das descrições das armas: armas ágeis, automáticas, de recarga e as que pedem as duas mãos.

## O que mudou

### O catálogo

- **Armas** (`armas.json`): as 34 da Tabela 3.3, com estes números do livro:
  - categoria, dano, crítico, alcance, tipo e espaços;
  - a empunhadura (leve, uma mão, duas mãos);
  - a proficiência (simples, táticas, pesadas).

  A descrição de cada uma é escrita com palavras próprias.
- **Munições** (Tabela 3.4): balas curtas, balas longas, cartuchos, combustível, flechas e foguete.
- **Proteções**: o escudo entra ao lado da proteção leve e da pesada.
- **Equipamento geral**:
  - **acessórios:** kits, utensílios e vestimentas;
  - **explosivos:** as quatro granadas e a mina antipessoal;
  - **itens operacionais:** os 19 da Tabela 3.8;
  - **itens paranormais:** amarras, câmera de aura, componentes, emissor de pulsos, escuta, medidor da Membrana e scanner. Os itens "de (elemento)" têm uma versão para cada elemento.
- **Os itens da Dama de Sangue** (fertilizante, agrotóxico, bulbo e galão de água) ficam. Eles vêm das fraquezas da ficha dela no livro (p.200), e agora formam um grupo próprio.
- **O que ainda não tem efeito no jogo:** o item diz isso na dica, com o campo `pendente`.

### Munição (p.69)

- A arma de fogo ou de disparo precisa de um **pacote** da munição dela. Sem pacote, só serve de **coronhada**: 1d4 de impacto com arma leve ou de uma mão, 1d6 com arma de duas mãos.
- **Quanto dura um pacote:**

  | Munição | Duração |
  |---|---|
  | Balas curtas | duas cenas |
  | Balas longas, cartuchos, combustível | uma cena |
  | Flechas | a missão inteira |
  | Foguete | um disparo |

  Só a cena em que o agente atirou conta para gastar o pacote.
- **No arsenal**, munição, granadas e caixas de recarga têm **− e +** para pedir mais de uma unidade. Cada unidade conta na cota da categoria e na carga. Uma arma sem munição na requisição mostra um aviso.
- **Os grupos iniciais e os recrutas** levam munição dentro da carga e da cota do livro:
  - Bianca troca o kit de medicina pelas balas;
  - Rita troca o cicatrizante pelas balas;
  - Ademir troca o fuzil de caça pelo revólver: como Recruta, o fuzil e as balas longas usariam as duas vagas de categoria I e ele ficaria sem a proteção.

### As armas (p.68-69)

| Regra | Armas | No jogo |
|---|---|---|
| Ágil | faca, punhal, cajado, nunchaku, florete, katana | Agilidade no lugar da Força no ataque e no dano, se for maior |
| Automática | submetralhadora, fuzil de assalto, metralhadora | botão **Rajada**: −1 dado no ataque, +1 dado de dano |
| Recarga | besta, balestra, bazuca | depois do tiro, o próximo pede uma ação de movimento |
| Uma ou duas mãos | bastão, espada | o dano maior com as duas mãos, quando não há escudo |
| Explode | motosserra | cada 6 no dano rola mais um dado; −1 dado no ataque |
| Força mínima | metralhadora | sem Força 4, −5 no ataque |
| Metade do dano | espingarda | além do alcance curto |
| Força no dano | arco composto | soma a Força |
| Mira de veterano | fuzil de precisão | veterano em Pontaria que mira: +5 na margem de ameaça |
| Explosão | bazuca | quem está a 3 m do alvo sofre o mesmo dano (Reflexos DT Agi: metade) |
| Linha | lança-chamas | o mesmo teste contra todos na linha; quem é atingido fica em chamas |
| Manobras | corrente | +2 para desarmar e derrubar |

**A proficiência** também ficou certa. Os poderes "armas táticas de fogo" (Balística Avançada) e "armas táticas exceto de fogo" (Ninja Urbano) agora valem para as armas táticas do tipo certo.

### Escudo (p.72)

- +2 na Defesa, somado ao da proteção.
- Para a proficiência, conta como proteção pesada.
- Não protege quando a arma é de duas mãos. A katana fica numa mão para quem é veterano em Luta.

### Itens de combate (p.74-77)

No combate, o menu **Itens** agora traz os itens de uso. Escolhe-se o item e depois o alvo no tabuleiro.

| Item | Efeito | Cargas |
|---|---|---|
| Taser | 1d6 de eletricidade e atordoado | 2 |
| Spray de pimenta | cego por 1d4 rodadas | 2 |
| Lanterna tática | ofuscado por 1 rodada; uma vez por alvo na cena | — |
| Pistola de dardos | quem é acertado dorme até o fim da cena | 2, mais a caixa |
| Pistola sinalizadora | 2d6 de fogo | 2, mais a caixa |
| Amarras | paralisam uma criatura vulnerável ao elemento | 1 PE por uso |

- **Testes:** os que têm DT usam a Agilidade de quem usa o item.
- **Rendidos:** uma pessoa que dorme com o dardo conta como rendida e pode ser interrogada depois (docs/40).

**Outros efeitos:**
- **Granada de fumaça:** cega quem estiver na área por 2 rodadas.
- **Soqueira:** +1 no dano desarmado, que passa a ser letal.
- **Mochila militar:** não ocupa espaço e dá +2 de carga.
- **Óculos de visão térmica:** a camuflagem não faz o golpe se perder.
- **Máscara de gás:** +10 em Fortitude contra miasmas.
- **Traje hazmat:** resistência a químico 10.

### A condição cego (p.320)

A condição nova:
- deixa o agente desprevenido e lento;
- tira dois dados das perícias de Agilidade e de Força;
- faz metade dos ataques de quem está cego se perder.

A condição **lento** também passou a cortar o deslocamento pela metade.

### O arsenal na Base

O catálogo mostra um grupo por vez:
- Armas
- Munição
- Proteções
- Acessórios
- Explosivos
- Operacionais
- Paranormais
- Amaldiçoados
- Contra criaturas
- Na requisição

A etiqueta mostra os números: o dano e o crítico da arma, a Defesa da proteção, quanto dura a munição e as cargas. A dica traz a regra da arma e o que ainda não tem efeito.

![Armas no arsenal](i67_armas.png)

![Munição com − e +](i67_municao.png)

## O que fica para depois

- **Modificações** de armas, munições, proteções e acessórios (p.70-71 e p.74): feitas em docs/68.
- **Arremessar** a faca, a lança e a machadinha. Hoje elas só servem no corpo a corpo.
- **Itens sem efeito ainda:**
  - mina antipessoal;
  - algemas;
  - bandoleira;
  - bloqueador de sinal;
  - o bônus de arrombar do pé de cabra;
  - a armadilha das amarras;
  - os itens paranormais de investigação (câmera de aura, emissor, escuta, medidor da Membrana e scanner).
- **Outras regras:**
  - o tripé da metralhadora;
  - ligar a motosserra;
  - o +5 do traje hazmat contra o ambiente.

## Onde está

- **Dados:** `armas.json`, `equipamentos.json`, e a marca `respiracao` no Miasma Entrópico e no miasma da Dama de Sangue.
- **Regra:**
  - `Agente`: `arma()` com coronhada, `pacote_de_municao`, `registrar_disparo`, `cargas_restantes` e `usar_carga`, `escudo` e `usa_duas_maos`, `proficiente_com`, `dados_com_atributo` e `bonus_contra`;
  - `Combate`: `pode_disparar`, `_ajuste_da_arma`, `_atingir_linha`, `_explodir_no_alvo`, `usar_item_combate` e `motivo_item_combate`;
  - `Ser`: as condições `CEGO` e `LENTO`.
- **Comando:** `usar` no combate.
- **Tela:**
  - arena: o botão Rajada e os itens de uso;
  - Base: filtros, − e + e o resumo na etiqueta (`IconeItem.resumo`).

## Testes

Total: **694**. Arquivo novo, `test_arsenal_do_livro.gd`, com 23 testes:
- **Catálogo:** a tabela inteira; todo item tem página e grupo.
- **Munição:** sem pacote só sobra a coronhada; quanto dura cada pacote; o foguete se gasta no disparo.
- **Armas:** a ágil, a rajada, a recarga, a motosserra, a espingarda longe, o lança-chamas e a bazuca.
- **Proficiência e mãos:** a proficiência tática de fogo, o escudo e a arma de uma ou duas mãos.
- **Requisição:** munição em unidades e a mochila.
- **Itens de combate:** o taser, os dardos com caixa, a lanterna e as amarras.
- **Cego:** a condição e a granada de fumaça.

O playtest automático ficou igual: investigador 1,0 de vitória em 6,9 turnos; pressa 0,8 em 11,5.
