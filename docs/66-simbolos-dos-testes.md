# Os símbolos dos testes

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: os dados das rolagens (ataque, movimento, defesa, luta, pontaria e as outras) devem mostrar o símbolo do atributo ou da perícia, como os slots do For The King 2.

## O problema

A rolagem no centro da tela mostrava um símbolo só, o do atributo, no cabeçalho. Os dados eram caixas com número, sem dizer de onde vinham. A perícia (Luta, Pontaria, Percepção…) só aparecia no texto, quando aparecia.

## O que mudou

- **Um símbolo para cada atributo e cada perícia** (`IconeTeste`), desenhado em código, na cor do atributo da perícia (p.30–32). Exemplos:

  | Símbolo | Para |
  |---|---|
  | lâminas cruzadas | Luta |
  | mira | Pontaria |
  | escudo | Reflexos e Fortitude |
  | espiral | Vontade e Intuição |
  | lupa | Investigação |
  | olho com cílios | Percepção |
  | triângulo com olho | Ocultismo |
  | pegadas | o movimento do mapa |

  As perícias sem desenho próprio usam o do atributo delas (Atletismo, o punho da Força).
- **O cabeçalho da rolagem** mostra o símbolo da perícia, o título com o nome dela ("ATAQUE DE CLÉBER · LUTA") e uma etiqueta do atributo que deu os dados ("FORÇA").
- **Cada d20** leva no canto o símbolo do atributo que o deu. Em OP, os dados vêm do atributo: Força 3, três dados com o punho.
- **O último teste** (os slots do canto, no mapa e no combate) também leva o símbolo.
- **O teste guarda a perícia e o atributo** (`ResultadoTeste.pericia` e `atributo_id`), e as telas leem dali.

Vale para o ataque no combate, o procurar, facilitar e ajudar na investigação, a pista central, o movimento e os testes de evento no mapa.

![A rolagem de Luta](i66_luta.png)

![Todos os símbolos](i66_simbolos.png)

## O que fica para depois

- **Os testes de resistência das criaturas** (a Vontade contra a presença perturbadora) com a rolagem central e o símbolo; hoje eles vão só para o registro.
- **Símbolos próprios** para Atletismo, Profissão e Tática, que hoje usam o do atributo.

## Onde está

- **Tela:**
  - `IconeTeste` (novo);
  - `RolagemDados`: o parâmetro `pericia`, a etiqueta do atributo e o símbolo em cada dado;
  - `Tema.slot_d20`: o parâmetro `atributo`;
  - as chamadas na arena, na investigação e no mapa.
- **Regra:** `ResultadoTeste.pericia` e `atributo_id`, preenchidos em `Agente.testar`.

## Testes

Total: **671**. Arquivo novo, `test_icones_teste.gd`:
- **Perícias:** cada uma tem símbolo e a cor do atributo do livro.
- **Teste:** guarda a perícia e o atributo.
- **Rolagem:** mostra a perícia, a etiqueta do atributo e um símbolo em cada dado.
- **Slot:** o slot do último teste leva o símbolo.
