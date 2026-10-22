# O covil e o chefe do caso

> Status: **v0.1**, 22/10/2026. Sétima fase do plano. Ela junta três itens:
> - de docs/51: o covil sem cara de lugar e o chefe sem virada;
> - do relatório de pesquisa: o Enigma de Medo do chefe (IN4) e a apresentação do chefe (AU2).
>
> A lore do Enigma de Medo vem da wiki (Medo, Degolificada). Os textos e os números são nossos.

## O problema

O combate do covil era uma sala genérica, com caixotes e pedras. Faltava o lugar que o grupo tinha deduzido. O chefe entrava sem apresentação, apanhava até cair e não mudava nada no meio da luta. O caso terminava ali, sem o mistério de origem que toda criatura de Medo carrega na lore.

## O que mudou

### O covil é o lugar do caso

O combate do chefe acontece no lugar sorteado para o caso (a pergunta "onde"). Cada lugar tem:
- **chão, paredes e luz próprios**;
- **a sua peça de cobertura**;
- **o que o cerca**, além da grade.

| Lugar | Cobertura | Luz | Em volta |
|---|---|---|---|
| Frigorífico desativado | carcaças no gancho | fluorescente fria | paredes, carcaças |
| Igreja interditada | bancos | vela | paredes, cruzes, bancos |
| Fazenda de porcos | fardos de feno | lâmpada amarela | fardos, árvores |
| Ala fechada do hospital | macas com o lençol manchado | fluorescente verde | paredes, macas |
| Escola rural | carteiras | luz pálida | paredes, carteiras, poste |
| Cemitério municipal | lápides | luar | lápides, cruzes, mata |

A grade também muda com o lugar (`arena` em cada local de `casos.json`). Por exemplo, a escola é cheia de carteiras, o frigorífico tem câmaras, e o cemitério tem lápides e mato alto.

As campanhas escritas à mão continuam com o próprio covil.

![A igreja interditada](c58_igreja.png)

![O hospital](c58_hospital.png) ![O cemitério](c58_cemiterio.png)

### O chefe tem um Enigma de Medo

Na lore, toda criatura de Medo carrega um mistério ligado à sua origem. Enquanto ninguém o resolve, ela se refaz. Resolvido, ela perde poderes.

**O enigma do caso:**
- um por caso, sorteado pela semente (igual no online), de uma tabela de cinco;
- quatro tipos vêm da wiki:
  - juntar as metades de um objeto da primeira vítima;
  - destruir o registro que ainda circula (um vídeo, um áudio, uma foto);
  - fechar a passagem por onde ele volta (o lugar do caso entra no texto);
  - fotografar o que ninguém vê;
- um quinto é nosso: dizer em voz alta quem ele foi.

**Como se resolve:**
- uma ou duas etapas, cada uma com duas perícias, pelo botão **Enigma** do combate;
- as pistas do caso baixam a DT em 2 cada, até 10, como nos enigmas do livro;
- se a pergunta do caso ligada ao enigma foi respondida, a DT cai mais 5.

**Enquanto não é resolvido,** o chefe recupera 4 PV no início de cada turno. Resolvido, ele para de se refazer. Ele nunca fica imune a dano: o enigma premia quem investigou, mas não trava quem não investigou.

**Onde não entra:**
- em gente (o líder do culto é uma pessoa);
- em quem já tem enigma próprio (as criaturas do livro);
- nos covis das campanhas.

### A virada na metade dos PV

Quando o chefe chega à metade dos PV, uma vez por combate:
- **ele se desfaz no ar e volta** ao lado do agente com a Sanidade mais baixa;
- **a escolta surge com ele:** um cultista;
- **ele pode mudar de elemento** conforme o que o grupo fez, como a Degolificada da wiki:
  - se derrubou alguém, vira **Sangue**, porque se alimentou;
  - se a luta se arrastou até a 4ª rodada, vira **Morte**, porque o tempo corre a favor dele;
  - nos outros casos, o elemento não muda.
- **A fraqueza muda junto:** passa a ser o elemento que oprime o novo (p.128). Um chefe que virou Sangue leva o dobro de Morte.
- **Na tela,** a fita treme, toca o som do novo elemento, e um papel vermelho diz "VIRADA".

![A virada](c58_virada.png)

### A apresentação do chefe

Ao abrir o combate do covil:
- a câmera vai até o chefe e entra a trilha do chefe (um coração a 60 batimentos sobre um acorde menor grave, sintetizado em código);
- uma ficha de dossiê mostra:
  - **o lugar:** "COVIL · UMA IGREJA INTERDITADA";
  - **o nome;**
  - **o elemento,** carimbado na cor dele se o relatório o confirmou, ou "ELEMENTO ?" se não;
  - **a fraqueza,** pelo ciclo dos elementos, só com o elemento confirmado;
  - **o Enigma de Medo.**
- A ficha some em 5 segundos ou com um clique. A IA e o tour do combate esperam por ela.
- A trilha para quando o combate acaba.

![A apresentação do chefe](c58_cartao.png)

## Equilíbrio

Playtest automático, com 10 sementes em cada perfil:

| Versão | Investigador | Pressa |
|---|---|---|
| Escolta de Iniciado (o do livro) | 50% de vitória | 10% de vitória |
| Escolta de cultista (a final) | 100% de vitória, 6,9 turnos | 80% de vitória, 11,5 turnos |

O Iniciado do livro é forte demais para NEX 5–10%. A regeneração de 4 PV quase não mexe no resultado: ela pesa quando o grupo demora, e é isso que se quer.

## O que fica para depois

- O enigma no quadro de dedução, como uma pergunta do caso: hoje ele aparece no cartão e no combate.
- A figura do chefe mudando de cor na virada: hoje muda o elemento, a fraqueza, o som e o texto.
- Carcaças penduradas num trilho de verdade, e o altar no fundo da igreja.

## Onde está

- **Dados:** `casos.json`:
  - `arena` em cada local;
  - `enigmas_do_chefe` e `enigma_do_chefe_regras` (cura 4, virada 0,5, escolta).
- **Regra:**
  - `Missao`: `enigma_do_chefe` e `_chefe_do_caso`. Em `_preparar_encontro`, os campos `local`, `local_nome` e `elemento_caso`;
  - `Combate`: o sinal `virada`, `_virada`, `elemento_da_virada` e `opressor_de`;
  - `MontagemCombate._terreno`, que usa o local.
- **Tela:**
  - `Tabuleiro3D.ESTILO_COVIL`;
  - `Pecas.peca_covil`, com banco, carcaça, maca, carteira, fardo e lápide;
  - `CartaoChefe` (novo);
  - `Som`: a trilha `chefe`;
  - na arena: `_apresentar_chefe` e `_ao_virada`.

## Testes

Total: **623**. Arquivo novo, `test_chefe_do_caso.gd`:
- **Enigma:**
  - sorteado pela semente, variado e com o lugar no texto;
  - o covil traz o chefe com enigma, regeneração e virada, e o elemento só com o relatório;
  - resolver o enigma para a regeneração.
- **Virada:**
  - acontece na metade dos PV, uma vez, com a escolta e ao lado de quem está mais abalado;
  - o elemento muda pelo que o grupo fez, e a fraqueza segue o ciclo.
- **Covil:** a arena segue o lugar, e cada lugar tem estilo e peças.
- **Cartão:** mostra o lugar e o "?", e o tour espera por ele.
