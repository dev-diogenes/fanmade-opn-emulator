# Poderes de classe no dossiê: pré-requisitos e escolhas extras

> Status: **v0.1**, 21/10/2026. Fecha as pendências do [27-criacao-pelo-livro.md](27-criacao-pelo-livro.md).

Quando a idade variada faz o agente começar com poderes de classe (a Vivência do adulto ou o NEX maior do idoso), o passo **Classe** lista os poderes. O dossiê agora cuida de duas coisas que antes ficavam para a Base.

## Só os poderes possíveis

A lista **esconde os poderes cujos pré-requisitos a ficha ainda não cumpre**.

- **Os pré-requisitos** (atributo mínimo, treino em perícia, NEX ou outro poder) são conferidos na ficha em construção (`CriacaoDossie.falta_pre`). As regras são as mesmas de `CriacaoAgente._checar_pre`, que confere o agente pronto.
- **As perícias treinadas** contam:
  - a origem (ou os benefícios escolhidos por criança e adolescente);
  - as fixas e as escolhidas da classe;
  - as livres e as do Treinamento em Perícia.
- **Aviso:** uma nota diz quantos poderes ficaram escondidos e por quê ("atributo, treino, NEX ou outro poder").
- **Pré-requisito que deixa de valer:** se o jogador mudar um atributo e um poder escolhido deixar de valer, o poder sai da ficha junto com a escolha extra dele.
- **Trilhas** com pré-requisito seguem a mesma regra.

## As três escolhas extras

| Poder | O que o dossiê pede | Regra conferida |
|---|---|---|
| **Treinamento em Perícia** | Duas perícias novas. Só aparecem as que o agente ainda não treina: abaixo de NEX 35%, o poder treina, não sobe para veterano | `CriacaoAgente`: um par por Treinamento, grau possível no NEX |
| **Especialista em Elemento** (ocultista) | Um dos cinco elementos | **Novo:** o elemento precisa existir (antes, bastava haver uma escolha) |
| **Ritual Predileto** (ocultista) | Um dos rituais escolhidos na aba Rituais | **Novo:** o ritual precisa estar entre os conhecidos. Se o jogador desmarcar o ritual, a escolha cai |

Tirar o poder (ou trocá-lo quando o limite de poderes é atingido) limpa a escolha extra dele.

| Treinamento em Perícia (combatente adulto) | Especialista em Elemento (ocultista adulto) |
|---|---|
| ![Treinamento](poderes28_treinamento.png) | ![Elemento](poderes28_elemento.png) |

## Testes

O `tests/unit/test_poderes_dossie.gd` tem 4 testes:

- **Lista:** esconde poderes por atributo, por outro poder e por NEX, e mostra o poder quando o atributo sobe.
- **Pré-requisito perdido:** o poder sai da ficha.
- **Elemento e ritual:** o Especialista em Elemento exige um elemento válido, e o Ritual Predileto, um ritual conhecido; tirar o poder limpa a escolha.
- **Treinamento em Perícia:** não oferece perícia já treinada e treina as duas escolhidas.

Total: **494 testes**.

## Pendências

- **Repetir o Treinamento em Perícia:** o poder é repetível, mas na criação só dá para escolhê-lo uma vez. Com um ou dois poderes iniciais, não faz falta.
