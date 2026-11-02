# Sigilos e cifra

> Status: **v0.1**, 01/11/2026. Pedido do dono do projeto: "utilize referências da própria wiki de Ordem Paranormal, como sigilos, rituais, símbolos". Decisão: seguir a **gramática** que a wiki descreve, com desenhos do jogo. Aprofunda o EL5 e o IN7 do relatório de pesquisa (`reports/`) e o símbolo do culto do docs/73.

## Por que não copiamos os símbolos oficiais

A Licença da Comunidade proíbe a identidade visual oficial e as imagens dos livros (docs/60, ADR 0012). Os símbolos dos elementos e dos rituais são parte dessa identidade. O docs/09 já tinha decidido que os sigilos do jogo seriam gerados por código, e isso continua valendo. O que aproveitamos da wiki ([Símbolos Ocultistas](https://ordemparanormal.fandom.com/wiki/S%C3%ADmbolos_Ocultistas), [Rituais](https://ordemparanormal.fandom.com/wiki/Rituais)) é a **descrição** de como os símbolos funcionam:

- **Cada elemento tem um traço próprio.** No Sangue, uma haste com bifurcações. Na Morte, uma espiral. No Conhecimento, sigilos pequenos encadeados. Na Energia, ângulos abertos e um traço que sobe torto. No Medo, um gancho com círculo na ponta e um arco.
- **No Conhecimento, cada sigilo é uma letra**, e um texto pode ser escrito com eles.
- **Os símbolos de culto e de relíquia** juntam o traço de um elemento a sigilos do Conhecimento.
- **Cada ritual tem um símbolo**, e há as variações indouta, discente e verdadeira.

## O que entrou

| Peça | No jogo | Onde |
|---|---|---|
| Sigilo de elemento | O miolo segue o traço descrito acima, com variação pela semente. Uma assinatura de 2 a 4 glifos do alfabeto fica em volta | `Sigilo.gerar_elemento` |
| Sigilo de ritual | Elemento e semente vêm do ritual. A forma põe anéis: discente +1 e verdadeiro +2, com marcas entre eles | `Sigilo.de_ritual` |
| Alfabeto de sigilos | São 26 glifos do jogo: uma haste com uma marca em cima (6 tipos) e outra no meio ou embaixo (5 tipos) | `Sigilo.glifo`, `Cifra` |
| Símbolo do culto | O miolo é o sigilo do elemento do caso, e o anel **escreve o nome do culto**, uma letra por sigilo, a partir do topo e no sentido do relógio | `PropsInvestigacao.simbolo` |
| Close-up do símbolo | Cada sigilo do anel aparece com a letra embaixo, e o close-up diz quantas letras novas entram na tabela | `CloseupPista._anel_lido` |
| Tabela da Ordem | As letras lidas ficam na carreira e passam para a missão e a cena | `Carreira.sigilos_conhecidos` |
| Ritual na arena | Ao conjurar, o sigilo do ritual acende no chão de quem conjura, na cor do elemento, e apaga | `Tabuleiro3D.sigilo_de_ritual` |
| Sala de Transcender | Com afinidade, o sigilo do chão é o do elemento, na forma verdadeira | `SalaTranscender` |

## A regra da tabela (camada do jogo, não do livro)

O símbolo do culto continua como no docs/73: só Ocultismo traduz, com DT 15. A tabela da Ordem muda isso:

- **Metade das letras do nome conhecida:** a DT do Ocultismo cai 5.
- **Todas as letras conhecidas:** a DT do Ocultismo vira 5, e **qualquer um** pode ler pela tabela com Investigação DT 10. O ponto aparece como "Símbolo na parede (sigilos conhecidos)".
- **Traduzir o símbolo** ensina as letras do nome. A tabela cresce no fim da missão, e o relatório mostra "Sigilos novos na tabela da Ordem: N (X de 26 letras)".

Os números ficam em `data/jogo/cultos.json`, em `simbolo.tabela`.

## Testes

`test_sigilos.gd` (9 testes) cobre:

- o sigilo de elemento é determinístico e cada elemento tem um miolo diferente;
- a forma põe anéis;
- o sigilo de ritual vem do ritual;
- sem elemento, o sigilo antigo continua igual;
- os 26 glifos são diferentes;
- a cifra normaliza (acentos e símbolos), cifra e lê de volta;
- a DT do símbolo cai com a tabela;
- o close-up mostra o anel lido;
- a carreira aprende as letras e as guarda no save da carreira e da missão.
