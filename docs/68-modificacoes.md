# As modificações do livro

> Status: **v0.1**, 22/10/2026. Continuação de docs/67: as modificações de armas, munições, proteções e acessórios (Tabelas 3.5, 3.7 e 3.9; p.70-74). A forma de guardar o item modificado está no ADR 0013.

## A regra do livro

- **Requisitar com modificação:** ao requisitar o equipamento, o agente pode pedir o item com uma ou mais modificações.
- **A categoria sobe:** cada modificação sobe a categoria do item em I. No exemplo do livro, uma katana (I) certeira e perigosa é um item de categoria III.
- **Sem repetir:** a mesma modificação não se aplica duas vezes no mesmo item.

## As modificações

| Para | Modificação | No jogo |
|---|---|---|
| Corpo a corpo e disparo | certeira | +2 no ataque |
| | cruel | +2 no dano |
| | perigosa | +2 na margem de ameaça |
| Arma de fogo | alongada | +2 no ataque |
| | calibre grosso | um dado de dano a mais (o revólver vai a 3d6) |
| | compensador | a rajada não tira dado; só em arma automática |
| | ferrolho automático | a arma vira automática |
| | mira laser | +2 na margem de ameaça |
| | mira telescópica | o alcance sobe uma categoria |
| | visão de calor | ignora a camuflagem do alvo |
| | silenciador | *ainda sem efeito* |
| Todas as armas | discreta | um espaço a menos |
| | tática | *ainda sem efeito* (o jogo não cobra ação para sacar) |
| Balas curtas e longas | dum dum | +1 no multiplicador de crítico |
| | explosiva | +2d6 de dano |
| Proteção pesada | antibombas | +5 nos testes de resistência contra efeitos de área |
| | blindada | resistência a dano 5 e um espaço a mais |
| Proteção leve | discreta | um espaço a menos |
| Qualquer proteção | reforçada | +2 na Defesa e um espaço a mais; não combina com discreta |
| Acessório | aprimorado | o bônus em perícia vai a +5 |
| | discreto | um espaço a menos |
| | função adicional | +2 em mais uma perícia, à escolha (menos Luta e Pontaria) |
| | instrumental | serve de kit de uma perícia (Crime, Enganação, Medicina ou Tecnologia) |

**Como os efeitos chegam ao jogo:**
- **Munição:** a munição modificada vai primeiro e passa o efeito para a arma que a dispara.
- **Antibombas:** vale contra granadas, a explosão da bazuca e rituais de área.
- **Instrumental:** tira o −5 de quem testa sem kit.

## A Oficina

No arsenal, o item requisitado que aceita modificação ganha o botão **Modificar**. Ele abre a Oficina:

- **As modificações:** uma lista das que servem para o item, cada uma com a descrição. A função adicional e o instrumental pedem a escolha da perícia.
- **Como o item fica:** o nome, a categoria e os espaços aparecem embaixo, conforme as marcações.
- **Se não cabe:** a Oficina diz o motivo e **Aplicar** fica desligado. O item pode não caber por três razões:
  - a patente não libera a categoria (duas modificações num machado fazem dele um item de categoria III, que o Operador não leva);
  - a cota da categoria já acabou;
  - a combinação fere o livro (compensador sem arma automática, discreta com reforçada).
- **Aplicar** troca o item da requisição pelo modificado. A etiqueta passa a mostrar o nome e os números novos.

![A Oficina no machado](i68_oficina.png)

![O machado certeiro na requisição](i68_requisicao.png)

## O que fica para depois

- **Calibre grosso** com munição própria: hoje ele usa a munição comum.
- **Os bônus para esconder o item:** o +5 em Crime das versões discretas.
- **Mira telescópica:** o Ataque Furtivo em qualquer alcance.
- **Silenciador e tática:** dependem de regras que o jogo ainda não tem (esconder-se depois de atirar, sacar a arma).
- **Aprimorado na função adicional:** o livro deixa aplicá-lo uma segunda vez, na função adicional.

## Onde está

- **Dados:** `equipamentos.json`, bloco `modificacoes`.
- **Regra:**
  - em `Ruleset`: `_montar_modificado`, `modificacoes_possiveis`, `classes_para_modificar`, `parametros_da_modificacao` e `base_do_item`;
  - em `Agente`: a munição modificada vai primeiro, e `modificar_ataque` soma o bônus de ataque e de dano da arma.
- **Tela:** a Oficina e o botão Modificar em `BaseOrdem`. As etiquetas reconhecem as versões de cada item pela base.

## Testes

Total: **704**. Arquivo novo, `test_modificacoes.gd`, com 10 testes:
- **A tabela:** está inteira.
- **O exemplo do livro:** a katana certeira e perigosa é de categoria III.
- **As regras de combinação:**
  - a mesma modificação não se repete;
  - cada modificação só serve para o seu tipo de item;
  - o compensador pede arma automática.
- **Armas de fogo:** o calibre grosso e a mira telescópica.
- **Proteções:** blindada, antibombas, discreta e reforçada.
- **Armas no ataque:** a certeira e a cruel.
- **Munição:** a explosiva e a dum dum.
- **Acessórios:** aprimorado, função adicional e instrumental.
- **A patente decide:** um Recruta não leva a pistola alongada, que é de categoria II.
