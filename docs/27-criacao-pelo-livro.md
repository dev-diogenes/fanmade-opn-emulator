# Criação de agente de acordo com o livro de regras

> Status: **v0.1**, 21/10/2026. Pedido: a construção da ficha deve seguir o livro de regras. Fontes no livro: o passo a passo (p.23), conceito e atributos (p.24-25), origens (p.26-31), classes (p.32-45), toques finais (p.46-47) e a regra opcional Idade Variada (p.182-184).

## O que já seguia o livro

As **regras** da criação (`CriacaoAgente`) já eram as do livro. Cada número abaixo foi conferido no capítulo 1.

| Regra | Livro | Jogo |
|---|---|---|
| Atributos | Começam em 1; 4 pontos; um pode ir a 0 para dar +1; máximo 3 (p.23-24) | Igual |
| PV, PE e SAN iniciais | Pela classe, com VIG para PV e PRE para PE (p.46) | Igual, com os valores de cada classe (p.34, 38, 42) |
| Perícias | Origem + classe + Intelecto (p.23 e p.25) | Igual, com perícias livres = base da classe + INT |
| Habilidades | Todas as de NEX 5% da classe (p.32) | Igual |
| Ocultista | Três rituais de 1º círculo (p.42) | Igual |
| Defesa | 10 + Agilidade + modificadores (p.46) | Igual |
| Deslocamento | 9 m (p.46) | Igual |
| Equipamento | "Você receberá o necessário em sua primeira missão" (p.23) | O kit da classe entra ao assinar |

## O que mudou: a ordem e os passos

**Antes:** Identidade (nome e origem), Classe, Atributos, Perícias, Rituais, Descrição e Revisão.

**Agora:** os passos na ordem do livro (p.23), com a descrição dos toques finais antes da revisão.

| # | Passo | Do livro |
|---|---|---|
| 1 | **Conceito** | "Crie um conceito": as perguntas da p.24 (o que fazia, o primeiro contato, o quanto sabe do Outro Lado, como age em investigação e em ação), resumidas numa frase. Também nome, gênero e idade (p.46-47): a idade fica aqui porque, com a regra opcional, ela muda os atributos e o NEX |
| 2 | **Atributos** | p.24-25 |
| 3 | **Origem** | p.26-31; criança e adolescente escolhem só parte dos benefícios (p.182) |
| 4 | **Classe** | p.32-45, com trilha e poderes quando a idade faz o agente começar com mais NEX ou com a Vivência do adulto |
| 5 | **Perícias** | p.23 e capítulo 2 |
| 6 | **Rituais** | Ocultista: 3 + 1 por NEX acima de 5%, até o círculo do NEX (p.42) |
| 7 | **Descrição** | Toques finais (p.46-47): aparência, personalidade, histórico e objetivo, cada um com a dica do livro em palavras nossas |
| 8 | **Revisão** | "Revise sua ficha" (p.23): PV, PE, SAN, Defesa e deslocamento com a conta, as escolhas pendentes e a página 1 da ficha |

### Conceito, gênero, idade e aparência

Os novos campos do agente são `conceito`, `genero`, `idade_anos` e `aparencia_texto`. São só apresentação: ficam no save e têm limite de tamanho.

- **Idade:** o livro sugere a idade pela origem ou rolar **2d6+15** (17 a 27). O botão "Rolar 2d6+15" faz isso.
- **Aparência:** é a frase do livro ("pelos traços marcantes"). O modelo da miniatura continua escolhido na foto.
- **Na ficha:**
  - o conceito aparece no topo da página 1;
  - gênero, idade e aparência abrem a descrição da página 2.

### Regra opcional: idade variada

Uma caixa no passo Conceito liga a regra (combine com a mesa). A faixa sai da idade em anos (`faixa_por_anos`), e as regras de cada faixa vêm do `idades.json`, que já estava implementado:

| Faixa | O que o dossiê pede |
|---|---|
| Criança / Adolescente | Benefícios da origem: escolher 1 ou 2 entre as perícias e o poder (passo Origem); atributos limitados (a validação avisa) |
| Jovem | Nada |
| Adulto | Uma desvantagem de idade (passo Conceito) e **o poder da Vivência** (passo Classe) |
| Maduro | NEX 10%: duas desvantagens e a **trilha**; ocultistas, 4 rituais |
| Idoso | NEX 15%: três desvantagens, trilha e um **poder de classe** |

**Antes**, um adulto travava na criação: a regra pedia um poder de classe, e o dossiê não tinha onde escolhê-lo. Agora o passo Classe mostra a trilha e os poderes quando eles são exigidos.

Três poderes ficam de fora: os que pedem uma escolha extra (Treinamento em Perícia, Especialista em Elemento, Ritual Predileto). Eles continuam disponíveis na Base, pelas pendências de NEX.

## Editar a descrição depois

O livro diz que o personagem "pode se desenvolver ao longo do jogo" (p.46).

- **Na Base:** a página 2 da ficha ganhou o botão **Editar descrição**. Ele abre um bilhete com conceito, gênero, idade, aparência, personalidade, histórico e objetivo, e salva a carreira (`EditorDescricao`).
- **Na ficha (F) do jogo:** a descrição só pode ser lida.

| Conceito | Classe (maduro: trilha) | Descrição | Revisão | Editar na Base |
|---|---|---|---|---|
| ![Conceito](livro27_conceito.png) | ![Classe](livro27_classe.png) | ![Descrição](livro27_descricao.png) | ![Revisão](livro27_revisao.png) | ![Editor](livro27_editor.png) |

## Testes

O `tests/unit/test_criacao_livro.gd` tem 7 testes:

- **Faixa:** a faixa pela idade.
- **Conceito e idade:** ficam no primeiro passo; a regra opcional muda faixa e NEX.
- **Toques finais:** vão ao agente, ao save e às duas páginas da ficha.
- **Adolescente:** escolhe os benefícios da origem.
- **Adulto:** só fecha a ficha com o poder da Vivência e a desvantagem.
- **Maduro:** NEX 10% com trilha; ocultista com 4 rituais.
- **Editar descrição:** edita depois na Base (limites, salvar) e fica só leitura no jogo.

Também foram atualizados os testes da ordem das abas. Total: **490 testes**.

## Pendências

- **Poderes com escolha extra:** Treinamento em Perícia e os de elemento ou ritual não são escolhidos na criação; ficam para a Base.
- **Pré-requisitos dos poderes:** são conferidos só na validação (o rodapé avisa). A lista não esconde os que o agente não cumpre.
- **Recrutas prontos:** os da lista "Recrutar pronto" vêm sem conceito nem descrição. Dá para preenchê-los com "Editar descrição".
