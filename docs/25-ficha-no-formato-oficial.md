# Ficha no formato da ficha oficial

> Status: **v0.1**, 21/10/2026. Pedido: a ficha dos agentes deve parecer a ficha oficial de Ordem Paranormal, exceto a terceira página (a ficha de rituais), que deve ser otimizada.

## Referência

A ficha oficial tem três páginas A4. Ela diz que pode ser reproduzida para uso pessoal, mas o PDF fica fora do repositório.

Copiamos a **estrutura** (que campos existem e como se agrupam), não a arte. O emblema, as fontes e o fundo são da editora. Aqui, o desenho continua o nosso: papel, tinta, rótulos pretos de formulário e máquina de escrever.

| Página oficial | O que tem |
|---|---|
| 1. Ficha de agente | Personagem e jogador; atributos em círculos; origem, classe, trilha; NEX, PE/rodada, deslocamento; PV, PE e SAN (atuais e máximos); Defesa (10 + AGI + equipamento + outros); proteção, resistências; perícias (dados, bônus, treino, outros); ataques (teste, dano, crítico/alcance/especial) |
| 2. Habilidades e inventário | Habilidades; proficiências (armas simples/táticas/pesadas, proteções leves/pesadas); rituais (DT, custo, página); PP e patente; limite de itens I–IV, crédito, carga; itens com categoria e espaços; descrição (aparência, personalidade, histórico, objetivo) |
| 3. Ficha de rituais | Cartões em branco: nome, elemento, círculo, execução, alcance, alvo, duração, resistência e o texto; tabela de custo por círculo |

## A ficha no jogo (`FichaAgente`)

Uma pasta com as **mesmas três páginas**. Ela é usada na **ficha (F)** durante a missão (1180 × 660) e na **Base › Agentes**. Na Base, as colunas se reorganizam pela largura, e as escolhas de NEX pendentes aparecem num bilhete abaixo.

### 1. Agente

- **Topo:** os campos têm **rótulos pretos** com o valor à máquina sobre uma linha, como um formulário preenchido: Personagem e Patente (o jogo não tem "jogador" por agente).
- **Atributos:** no pentágono de círculos, como na oficial.
- **Ao lado:** Origem, Classe, Trilha e a linha NEX · PE/rodada · Desl.
- **PV, PE e SAN em caixas:** sigla, nome por extenso, **atuais / máximo** em destaque e uma barra.
- **Defesa:** a caixa e a **conta da ficha**, "= 12 (10 + 2 AGI) + 0 equip. + 2 outros", com Proteção e Resistências.
- **Ataques:** as armas do inventário, com teste ("2d20+5"), dano (com a FOR quando soma), crítico, alcance e tipo de dano. ✦ marca a empunhada.
- **Perícias:** **todas** as perícias, como na oficial, com DADOS ("2 AGI"), BÔNUS total, TREINO (+5/+10/+15) e OUTROS.
  - As treinadas ficam em negrito.
  - \* marca as que exigem treino, e † as que sofrem penalidade de carga.
- **Cabe sem rolar** a 1280×720 na ficha (F).

### 2. Habilidades e inventário

- **Habilidades:** nome e descrição. As que ainda não têm efeito ficam em itálico, com a dica.
- **Proficiências:** marcadas ☑/☐, como na oficial.
- **Descrição:** a foto 3x4, a aparência escolhida e a origem com o seu poder. O jogo não guarda personalidade, histórico nem objetivo.
- **Recursos:** PP e Patente; Limite de itens I–IV; Crédito; Carga (usados/máximo).
- **Inventário:** item, categoria e espaços. A dica traz o efeito, e "Usar" aparece no mapa.
- **Rituais:** a contagem, apontando para a página 3.

### 3. Rituais (otimizada)

A ficha oficial é para preencher à mão: cartões em branco, campos para copiar do livro e uma tabela para calcular o custo. No jogo, nada disso precisa ser escrito.

| Ficha oficial | Ficha do jogo |
|---|---|
| Cartões em branco, quantos couberem | **Só os rituais que o agente conhece**, um cartão para cada |
| Marcar elemento e círculo | Elemento em cor (borda e nome) e o selo "1º · 1 PE" |
| Calcular o custo pela tabela | **Custo calculado** com os poderes que reduzem (Ritual Predileto, Mestre em Elemento…) |
| Um campo DT para todos | **DT de cada ritual**, com os bônus por elemento e de poderes |
| Copiar execução, alcance, alvo, duração, resistência e o efeito | Já preenchidos a partir do ruleset (texto com palavras nossas) |
| Formas discente e verdadeira no texto | Linha "Formas — Discente: 3 PE (2º) · Verdadeiro: 6 PE (3º)" |
| — | Cabeçalho com DT, PE/rodada, PE atuais, círculo máximo e a tabela de custo |
| — | **Filtro por elemento** quando há mais de um |
| — | Aviso "PE insuficiente agora" e "ainda sem efeito nas regras deste jogo" |

Quem não conhece rituais vê a explicação: ocultistas começam com três, e as outras classes aprendem por poderes.

| Página 1 | Página 2 | Página 3 |
|---|---|---|
| ![Agente](ficha25_p1.png) | ![Habilidades e inventário](ficha25_p2.png) | ![Rituais](ficha25_p3.png) |

![Na Base](ficha25_base.png)

## Também nesta rodada

- **Erro no dado:** quatro rituais tinham "instantâ nea" (com espaço) na duração. Foi corrigido no `rituais.json`.

## Testes

O `tests/unit/test_ficha_agente.gd` tem 4 testes:

- **Páginas:** as três, com os nomes da oficial.
- **Página 1:** todas as perícias e a Defesa com a conta.
- **Rituais:** um cartão por ritual conhecido, com custo e DT calculados e o filtro por elemento.
- **Sem rituais:** a explicação.

O teste da Base passou a conferir a ficha nova. Total: **480 testes**.

## Pendências

- **Descrição:** personalidade, histórico e objetivo não existem no agente. Seria um campo de texto livre na criação.
- **Base:** fica estreita para as duas colunas da página 1, então as perícias descem para baixo, com rolagem.
- **Ficha da criação:** a revisão do dossiê de criação ainda usa a ficha em texto. Ela poderia mostrar a página 1 da ficha nova.
