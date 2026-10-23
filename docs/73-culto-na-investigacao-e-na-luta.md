# O culto na investigação e na luta

> Status: **v0.1**, 22/10/2026. Segundo passo recomendado depois do docs/72: levar o culto do docs/71 para as cenas e para os encontros. Junta três itens:
> - o símbolo de culto traduzível (EL5 do relatório "Melhorias pelo universo de Ordem Paranormal");
> - a estrutura do culto mudando os cultistas;
> - os recortes do vilão nas cenas.
>
> **Não é regra do livro.** É a lore da wiki transformada em sistema, com textos nossos. As regras de onde o culto vale são as do ADR 0014.

## O símbolo do culto (EL5)

Na wiki, o símbolo de um culto junta o traço do elemento a um anel de sigilos, o alfabeto do Conhecimento. No jogo, o símbolo é um ponto a mais em toda cena de investigação, até alguém traduzir o anel:

- **Na sala 3D:** um pedaço de muro com o traço do meio na cor do elemento do caso e oito sigilos dourados em volta. A cor já é uma pista para quem conhece os elementos.
- **Quem traduz:** só **Ocultismo**, que é perícia só para treinados.
  - Com o treino, o agente examina e acha a pista central sem teste (DT 15, sem custo de PE).
  - Sem treino, o ponto fica lá, mas ninguém consegue ler.
- **O que dá:**
  - a pista responde **quem** e traz o próximo traço verdadeiro do culpado;
  - o anel traduzido dá o **nome do culto**, que vai para o quadro do caso antes da dedução ("O anel do símbolo assina: …");
  - o close-up da pista mostra o desenho do símbolo.
- **Uma vez por caso.** Traduzido, o símbolo some das próximas cenas.
- **Nunca num alarme falso**, porque ali não há culto por trás.

![O símbolo na parede e o bilhete de Procurar com Ocultismo](i73_simbolo.png)

![A pista do símbolo, com o desenho no canto](i73_simbolo_pista.png)

## A notícia do vilão (recortes nas cenas)

Numa missão ligada ao vilão da carreira (docs/71), a primeira testemunha que fala mostra uma **manchete no celular**: a mesma manchete que vira recorte no fim do caso, com o nome da empresa.
- A linha aparece no close-up do depoimento e no relatório de campo.
- O quadro do caso guarda: "No celular de uma testemunha: …".
- Antes, o jogador só descobria a ligação depois de fechar o caso. Agora ela aparece no meio da investigação.
- É uma vez por caso.

![A manchete no celular do zelador](i73_noticia.png)

## A estrutura do culto na luta

Nas missões procedurais da carreira (como os outros efeitos do culto, ADR 0014), a estrutura do culto muda os **cultistas** dos encontros: Cultista Iniciado, Cultista Investido e Líder de Culto. Gente e bicho que não são do culto não mudam, e o chefe do covil também não.

A troca acontece **antes** do orçamento de VD (p.187), então o balanceamento continua valendo. Com o NEX baixo, o orçamento ainda corta para um cultista só. As diferenças de composição aparecem quando o grupo cresce; o traço de cada cultista vale desde o começo.

| Estrutura | Composição | Traço na luta |
|---|---|---|
| Células sem líder | investido vira iniciado, líder vira investido, +1 iniciado | fogem com metade dos PV, em vez de um quarto (docs/72) |
| Hierarquia | +1 iniciado de escolta | com dois ou mais, o mais forte vira "(líder)"; se o líder cai, a escolta foge com metade dos PV |
| Mente coletiva mascarada | +1 iniciado, todos "mascarados" | nunca fogem |
| Família | o parentesco no nome ("Cultista Iniciado, avô") | quando um parente cai, os outros ganham +1 dado nos ataques (até +2) |
| Empresa | um iniciado vira "Segurança da empresa" (capanga, mesmo VD) | — |

As regras ficam em `data/jogo/cultos.json`, no bloco `encontro` de cada estrutura. O traço vai na ficha copiada (`ficha.culto`) e vira `Ameaca.culto`. O jogo lê as regras pelo id da estrutura, então saves antigos também as recebem.

![Uma família de cultistas na arena](i73_familia.png)

## Correção

**O quadro do caso** tinha um espaço fixo entre o objetivo e as perguntas. Com o sinal do culto, o nome e a notícia, o objetivo cresceu e cobria os botões Deduzir. Agora o quadro mede o texto, e as perguntas descem junto.

## Playtest

Uma sonda pela interface (1280×720) jogou a missão 777 com o culto "Família dos Que Esperam" e a missão ligada à Companhia Valadares:

1. **Na capela em ruínas:**
   - o símbolo apareceu como quinto ponto da cena;
   - o Cléber (treinado em Ocultismo pela sonda) examinou e traduziu o anel, e a pista deu o traço "Esconde o rosto";
   - a Bianca ouviu o zelador, que mostrou a manchete da Companhia Valadares no celular.
2. **De volta ao mapa, uma célula cultista de família:**
   - "Cultista Iniciado, irmã" e "Cultista Iniciado, avô", mais um capanga;
   - quando a irmã caiu, o avô ganhou +1 dado.

O playtest automático (docs/67) ficou estável:

| Perfil | Vitórias | Turnos |
|---|---|---|
| Investigador | 100% | 7,1 |
| Pressa | 90% | 10,8 |

**Testes:** 787 passando. Os novos estão em `test_culto_em_campo.gd`.

## O que ficou de fora

- **A gramática de desenho dos sigilos por elemento** (a outra metade do EL5). O símbolo usa o sigilo procedural do docs/09, na cor do elemento.
- **Os agentes controlados pela IA** não procuram o símbolo de propósito; ele é só mais um ponto da cena.
- **O parentesco no nome** é "Cultista Iniciado, irmã": o nome da ficha não muda de gênero.
