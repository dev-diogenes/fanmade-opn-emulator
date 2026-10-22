# Arsenal por agente

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: cada agente só requisita o que a patente e a carga deixam, pelo livro. As regras do livro:
> - **Patente:** itens por categoria, Tabela 3.1 (p.52).
> - **Capacidade de carga:** espaços de itens (p.53).
> - **Proficiência:** armas (p.53) e proteções (p.72).

## O problema

- **Tudo para todos:** a aba Arsenal mostrava o catálogo inteiro para todos.
- **O agente:** quem se equipava era escolhido em outra aba.
- **O limite:** só aparecia como erro depois de clicar em Requisitar.
- **A proficiência:** atacar com arma sem proficiência não custava nada, mas o livro pede −2 dados (p.53).

## O que mudou

### A aba Arsenal

**À esquerda,** a lista dos agentes, com a patente e a carga de cada um ("Cléber · Recruta, 3/15 espaços"). Escolher um agente aqui também o escolhe nas outras abas.

**À direita:**
- **Cotas da patente** (Tabela 3.1): "Cat. I 1/2", "Cat. II —"…
- **Carga** (p.53):
  - **capacidade:** 5 espaços por ponto de Força, ou 2 com Força 0;
  - **na barra:** fica âmbar quando passa da capacidade, com o aviso "sobrecarregado: −5 Defesa, −3 m";
  - **teto:** o dobro da capacidade.
- **Arma empunhada,** entre as armas que o agente leva.
- **Os itens agrupados por categoria:**
  - **categoria 0:** livre, só conta a carga;
  - **categorias I a IV:** com a cota da patente, ou "a patente ainda não libera".

**Marcar já requisita;** não há mais o botão Requisitar.

**O que não pode ser marcado fica apagado,** com o motivo na dica:
- a patente ainda não libera a categoria;
- a cota da categoria acabou ("Já leva 2 de 2 itens de categoria I");
- passaria do teto da carga;
- já leva uma proteção (só dá para vestir uma);
- é item amaldiçoado e o agente ainda não é Agente Especial.

**Sem proficiência,** a dica avisa sem bloquear. O livro permite usar, com penalidade.

![O arsenal da Bianca: Força 0, 2 espaços](a64_arsenal.png)

### A proficiência no combate

Atacar com uma arma sem proficiência agora custa **−2 dados** (p.53), no ataque e na chance mostrada nos alvos. Exemplo: um especialista com arma tática. A penalidade da proteção sem proficiência (p.72) já existia.

## O que fica para depois

- **O catálogo completo do livro:** as armas, as munições, o equipamento geral e os itens paranormais. Faz parte da revisão de itens, rituais e habilidades pelo livro, a próxima tarefa deste pedido.
- **Mãos:** empunhar no máximo dois itens (p.53), mostrado na ficha.

## Onde está

- **Regra (`Agente`):**
  - `motivo_bloqueio(item, lista)`, `aviso_item(item)` e `espacos_de(lista)`;
  - `dados_sem_proficiencia(arma)`, usado em `Combate.atacar` e em `chance_de_acerto`.
- **Tela (a Base):**
  - `_atualizar_arsenal`, `_marcar_item` e `_aplicar_requisicao`;
  - o texto do passo do tutorial.

## Testes

Total: **667**. Arquivo novo, `test_arsenal.gd`:
- **Patente:**
  - a recruta não tem categoria II, e o operador tem;
  - a cota da categoria I.
- **Carga:** a carga pela Força (2 com Força 0, 10 com Força 2) e o teto.
- **Proteção:** só uma.
- **Proficiência:** arma tática sem proficiência avisa e custa 2 dados; o combatente não sofre.
