# Escolhas de NEX por seleção, dentro das regras

> Status: **v0.1**, 21/10/2026. Pedidos:
> - "Coloque o poder de classe também na sala de transcendência ao invés de uma caixa para escrever ou selecionar o poder";
> - "Todas as seleções de classe, itens etc. devem ser por seleção, não escrevendo, e seguir à risca o sistema".

## O que estava errado

O painel das escolhas de NEX era o mesmo na Base e no papel da sala de Transcender, e tinha dois problemas:

1. **Uma lista suspensa** para a escolha principal.
2. **Um campo de texto livre** para a escolha a mais. Para Treinamento em Perícia, para Transcender (o poder paranormal e o elemento ou ritual dele) ou para Expansão de Conhecimento, era preciso **digitar ids** como `luta, pontaria`, `sangue` ou `especialista:eclético`.

Além disso, escolher **Especialista em Elemento** ou **Ritual Predileto** pela progressão **não guardava** o elemento ou o ritual. O poder ficava sem efeito. Só a criação guardava.

## Como ficou: `EscolhaNex`

Um componente só, usado na Base e no papel da sala de Transcender:

- **Cada opção é um botão**, com a descrição embaixo. Os poderes cujo efeito ainda não está no jogo aparecem com **\***, e a descrição avisa.
- **Quando a opção pede algo a mais**, aparece uma segunda lista, **só com o que a regra permite**:

| Escolha | A segunda lista |
|---|---|
| Treinamento em Perícia | As perícias que podem subir agora: abaixo de NEX 35%, só as novas; depois, também as que sobem de grau (2 escolhas) |
| Transcender | Os poderes paranormais disponíveis (pré-requisitos de elemento e repetições com afinidade). Se o poder pede escolha, uma terceira lista: o elemento (Resistir a Elemento), o ritual até o círculo do NEX (Aprender Ritual) ou o poder de outra classe com os pré-requisitos cumpridos (Expansão de Conhecimento) |
| Especialista em Elemento | Os elementos |
| Ritual Predileto | Os rituais que o agente conhece |
| Grau de Treinamento | As perícias que podem subir, com a contagem "2/3" |

- **Confirmar** só acende com a escolha completa.
- A **Progressão** agora guarda o elemento ou o ritual de Especialista em Elemento e Ritual Predileto em `escolhas`, e recusa a escolha sem eles.

![A sala de Transcender: poderes do combatente e as perícias do Treinamento](esc47_sala.png)

## Como as regras filtram hoje

As listas não são livres: vêm de `Progressao` e `CriacaoAgente`, que seguem o livro. Escolher fora da lista é recusado também na regra, não só na tela.

| Escolha | Só aparece o que… | Onde |
|---|---|---|
| Classe e origem (criação) | as 3 classes e as 26 origens do livro | `criacao_dossie` |
| Trilha | é da **classe do agente** e tem os pré-requisitos cumpridos | `Progressao.trilhas_possiveis` |
| Poder de classe | é da **classe do agente** (o ocultista não vê os do combatente), tem os pré-requisitos (atributo, treino, NEX, outro poder) e não é repetido, salvo os repetíveis | `Progressao.poderes_possiveis` |
| Poder paranormal | tem os pré-requisitos de elemento (ex.: Morte 2) e só se repete com afinidade, quando o poder permite | `Progressao.poderes_paranormais_possiveis` |
| Ritual | está até o **círculo do NEX**, ainda não é conhecido e não é de Medo de 4º círculo. Só aparece para quem aprende rituais pela classe (o ocultista) ou por poder | `Progressao.rituais_possiveis` |
| Aumento de atributo | está abaixo do máximo e não é proibido pela faixa de idade | `Progressao.atributos_aumentaveis` |
| Grau de treinamento | é treinada (NEX 35%) ou veterana (NEX 70%) | `Progressao.pericias_para_subir` |
| Afinidade | Conhecimento, Energia, Morte ou Sangue, em NEX 50% (p.114) | `Progressao` |
| Perícias da criação | as da origem e da classe vêm marcadas e travadas; as livres seguem a conta da classe + Intelecto | `criacao_dossie` |
| Itens (Arsenal) | cabem nos limites de categoria da patente (Tabela 3.1), na carga e numa proteção; itens amaldiçoados só a partir de Agente Especial | `Agente.validar_equipamento` |

**O que continua sendo escrito**, porque é texto por natureza: o nome do agente, a descrição (personalidade, histórico, objetivo), o endereço e a porta da sala online.

## Testes

Total: **549**.
- **Poderes de classe:** o ocultista só recebe poderes de ocultista.
- **Treinamento em Perícia por cliques:** a luta (já treinada em NEX 15) não aparece; Atletismo e Medicina sobem.
- **Transcender por cliques:** Resistir a Elemento → Sangue; Confirmar só acende com o elemento; resistência a Sangue 10.
- **Especialista em Elemento:** sem elemento, é recusado; com Energia, a escolha fica guardada.
