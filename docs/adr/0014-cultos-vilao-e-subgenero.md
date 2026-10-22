# ADR 0014: cultos sorteados, o vilão da carreira e o subgênero da missão

- **Status:** aceito, 22/10/2026
- **Contexto:**
  - OR6 e OR7 do relatório "Melhorias pelo universo de Ordem Paranormal";
  - o caso procedural (docs/32, docs/52);
  - os sinais da rede (docs/62);
  - a contenção (docs/63);
  - docs/71.

## Contexto

O caso procedural sorteia quem, o quê, onde e o elemento, mas não dizia que grupo estava por trás. Na wiki, todo culto combina cinco coisas: um elemento, uma fachada banal, uma estrutura, um método de espalhar o medo e um sinal visual. Um deles é uma empresa de fachada que liga cultos isolados e aparece primeiro em recortes de jornal. Cada temporada da série também troca de subgênero.

## Decisão

- **O culto é parte do caso.** `Caso.culto` sai de uma semente própria do caso, como o elemento: igual em qualquer máquina, sem gastar os Dados, e salvo com o caso.
  - Os eixos ficam em `data/jogo/cultos.json`.
  - O efeito da estrutura e do método é um dicionário pequeno: `membrana_inicial`, `chefe`, `credencial_limite`, `sumico_chance_em` e `segredos_preso`. Ele só age nos sistemas que já existem.
- **Onde o culto vale:**
  - **efeitos:** só nas missões procedurais da carreira (`Missao.aplicar_efeitos_do_culto`, chamada por `Carreira.iniciar_missao`, que marca `extras.culto`);
  - **campanha e comunidade:** o caso é escrito à mão e fica sem culto;
  - **sem carreira** (testes, sondas, demonstração): o culto aparece, mas não mexe em nada.
- **O vilão é estado da carreira.** `Carreira.vilao` guarda a empresa e quantas já caíram; `Carreira.recortes`, os recortes do quadro.
  - Metade das missões, pela semente, liga o culto ao vilão (`sinal.vilao.ligado`); fechar esse caso rende um recorte.
  - Com três recortes, a Base mostra um quarto sinal, a sede (`sinal.vilao.final`). Vencer e fechar esse caso derruba o vilão, apaga os recortes e sorteia o próximo.
- **O subgênero vem no sinal** (`sinal.subgenero`, pelos pesos de `data/jogo/subgeneros.json`).
  - O bloco `cfg` sobrepõe o `mapa.json` só naquela missão, com uma cópia mesclada em `Missao._cfg`. O cache de `DadosJogo` não muda.
  - O efeito volta a valer ao carregar o save, porque o sinal é salvo.
  - O que não cabe em `cfg`, como a Membrana por turno da Transmissão, é lido do subgênero no turno do mundo.

## Consequências

- **Novos cultos, métodos e subgêneros** são entradas de JSON. Só pedem código se trouxerem um tipo de efeito novo.
- **O tamanho da carreira:** o vilão e os recortes fazem a carreira procedural ter um arco de três ou mais missões, com um clímax.
- **Saves antigos:**
  - o caso sem `culto` ganha o culto da semente;
  - a carreira sem `vilao` ganha um na primeira missão com sinal;
  - o sinal sem `subgenero` é clássico.
- **O playtest automático** passa a sentir o culto: a Membrana às vezes começa mais fraca e o chefe, mais forte. Os números estão em docs/71.
