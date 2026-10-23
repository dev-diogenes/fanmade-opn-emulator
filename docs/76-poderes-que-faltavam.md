# Os poderes que faltavam

> Status: **v0.1**, 23/10/2026. Pedido do dono do projeto: "os 10 poderes de classe e os 6 de origem que faltam, com efeito igual ao do livro". Fecha a lista "Poderes sem efeito" do docs/69. A forma de guardar selos e achados está no ADR 0017.
>
> As regras são do livro (páginas na tabela), com texto próprio. Onde o livro deixa a decisão "a critério do mestre", a tabela diz o que o jogo escolheu.

## Poderes de classe

| Poder | Classe | Livro | No jogo |
|---|---|---|---|
| Golpe Demolidor | combatente | p.35 | Na manobra **quebrar**, 1 PE soma dois dados de dano da arma ao golpe no item |
| Saque Rápido | combatente | p.35 | **Sacar outra arma** é ação livre (sem o poder, de movimento, p.97). Uma vez por rodada, recarrega arco, besta ou balestra sem gastar ação |
| Mãos Rápidas | especialista | p.39 | Na investigação, por 1 PE, um teste de Crime não gasta a ação do turno |
| Mochila de Utilidades | especialista | p.39 | Um item marcado no Arsenal (não arma nem consumível) conta uma categoria abaixo e ocupa 1 espaço a menos |
| Movimento Tático | especialista | p.39 | 1 PE: até o fim do turno, terreno difícil e subir num ponto alto não custam deslocamento a mais. No mapa: todo hex custa 1 e dá para subir a serra |
| Nerd | especialista | p.39 | Uma vez por cena, 2 PE e Atualidades DT 20. Na investigação, +5 no próximo teste de procurar pistas do grupo. No combate, mostra as fraquezas de um inimigo |
| Camuflar Ocultismo | ocultista | p.43 | Sem componentes ritualísticos, conjura assim mesmo, por +2 PE (no combate e no mapa) |
| Criar Selo | ocultista | p.43, p.161 | Ação de interlúdio: fabrica o **selo** de um ritual que conhece, pagando o custo em PE. Máximo de selos: a Presença |
| Ferramentas Paranormais | ocultista | p.43 | Itens paranormais contam uma categoria abaixo e ativam sem gastar PE |
| Improvisar Componentes | ocultista | p.44 | Uma vez por cena, Investigação DT 15 acha componentes de um elemento escolhido, que servem até o fim da missão. No combate gasta a ação completa; no mapa, a ação do turno |

**Os sistemas que vieram junto:**
- **A manobra quebrar** (p.95, Tabela 4.5 da p.100): o golpe vai na arma que o alvo segura.
  - O dano (com a Força, no corpo a corpo) menos a resistência do objeto sai dos PV da arma.
  - A resistência e os PV dependem da empunhadura e do material: madeira tem 5 de RD, metal tem 10, e os PV vão de 2 a 20.
  - A 0 PV, a arma quebra e o alvo luta desarmado.
- **Sacar outra arma** (p.97): o botão **Arma ▾** do combate troca a arma da mão ou guarda a arma. Antes, a arma não mudava durante a luta.
- **Os selos** (p.161):
  - É um item do inventário, de categoria igual ao círculo do ritual.
  - No combate, aparece no bilhete de itens.
  - Ler o selo conjura o ritual sem PE e sem componentes e gasta ao menos a ação padrão. Depois, o selo se desfaz em cinzas.
  - Quem não conhece o ritual testa Ocultismo (DT 20 + custo).

## Poderes de origem

| Poder | Origem | Livro | No jogo |
|---|---|---|---|
| Vislumbres do Passado | amnésico | p.26 | Uma vez por missão, no mapa: Intelecto DT 10. Passando, 1d4 PE temporários e, como "informação útil", os hexes em volta revelados |
| Magnum Opus | artista | p.27 | Uma vez por missão, uma testemunha da investigação reconhece o agente: +5 nos testes de perícia de Presença contra ela |
| Ingrediente Secreto | chef | p.27 | No interlúdio, quem se alimenta junto com o chef ganha também o prato dele; o mesmo prato duas vezes acumula |
| O Crime Compensa | criminoso | p.28 | As armas de quem cai nos combates viram **achados** da missão. No Arsenal, o criminoso escolhe um para a próxima missão, fora da cota da patente; ele sai do inventário quando essa missão acaba |
| Ferramenta Favorita | engenheiro | p.28 | Um item marcado no Arsenal (não arma nem consumível) conta uma categoria abaixo |
| Patrocinador da Ordem | magnata | p.30 | O limite de crédito conta um nível acima |

**O crédito agora vale** (p.62): na vila, a hospedagem do interlúdio segue o limite de crédito de cada agente.
- Baixo: descanso normal.
- Médio: confortável.
- Alto ou ilimitado: luxuoso.

O ponto de encontro continua normal. Um Recruta não muda; um Operador passa a dormir melhor na vila. A ficha mostra o crédito com o Patrocinador.

## Na tela

![O Arsenal: o revólver de O Crime Compensa e a lanterna na Mochila de Utilidades](i76_arsenal.png)

![O interlúdio: a Rita cozinha e faz um selo](i76_interludio.png)

![Combate: o Cléber sacou o machete de graça e quebra o bastão do segurança](i76_quebrar.png)

![O selo no bilhete de itens da Rita](i76_selo.png)

![No mapa, o Movimento Tático no bilhete de ação](i76_mapa.png)

## Playtest

Uma sonda pela interface (1280×720), com os poderes dados ao grupo inicial e NEX 20:

1. **Arsenal:**
   - a Bianca (criminosa) escolheu o revólver dos achados, fora da cota, sem erro na requisição;
   - a lanterna tática na Mochila desceu para a categoria 0.
2. **Mapa:** a Bianca usou o Movimento Tático (1 PE), e a serra ficou liberada.
3. **Interlúdio:**
   - a Rita (chef) e a Bianca comeram o prato favorito duas vezes;
   - a Rita fez um selo de Eletrocussão.
4. **Combate:**
   - o Cléber sacou o machete sem gastar ação e quebrou com Golpe Demolidor o bastão do segurança da empresa;
   - a Bianca usou o Nerd (Atualidades 34 contra DT 20) e o Movimento Tático;
   - a Rita leu o selo: a Eletrocussão saiu sem gastar PE, e o selo sumiu.

**Playtest automático:** sem mudança (investigador 100% em 7,1 turnos; pressa 90% em 10,8). Os grupos começam como Recruta, sem esses poderes, e o crédito baixo dá o mesmo descanso de antes.

**Testes:** os novos estão em `test_poderes_do_livro.gd`, um ou mais por poder.

## O que ficou de fora

- **Golpe Demolidor contra objetos do cenário:** o livro também vale quando se ataca um objeto. A arena ainda não tem objetos que quebram, como portas e caixotes.
- **O resto de Camuflar Ocultismo:** esconder sigilos na pele e conjurar com as mãos presas não têm uso no jogo hoje. Nenhuma regra prende as mãos do agente.
- **Afortunado** (poder paranormal, docs/69) continua sem efeito.
