# A Pesquisa, o mapa de rumores e o som em duas camadas

> Status: **v0.1**, 22/10/2026. Décima fase, com os últimos itens de prioridade 1 do relatório de pesquisa: o mapa de rumores e o contato da Pesquisa (IN5), e o som em duas camadas (AU1).
>
> Bases:
> - a lore: na wiki, a equipe de pesquisa da Ordem trabalha a distância e manda fichas, fotos e listas por telefone;
> - o design: os rumores ligados entre si do log de Outer Wilds e as dicas por rádio de *Enigma do Medo*, que orientam sem dar a solução;
> - o som: na wiki, cada elemento tem uma sonoridade, e o jogo oficial mistura piano e sintetizadores.

## O problema

- **Sem saída:** quando o grupo ficava sem pista, a única ajuda era a linha "há algo a nordeste, na névoa" (docs/53).
- **Pistas soltas:** elas não se juntavam em lugar nenhum do mapa. O jogador anotava de cabeça onde tinha achado cada uma.
- **Som:** o ambiente era um drone só, que subia com a Membrana. A Realidade não tinha som próprio.

## O que mudou

### Ligar para a Pesquisa

O quadro do caso ganhou o botão **☎ Pesquisa**, ao lado de Deduzir. A ligação trata da **pergunta mais fraca** do caso (a que tem menos traços firmes). Cada pergunta tem três camadas, e cada uma custa mais que a anterior:

| Camada | O que a Pesquisa manda | Custo |
|---|---|---|
| 1 · Orientação | Qual pergunta pesa menos e para onde há um lugar com pista ainda sem visita | A ação do turno do agente |
| 2 · Cruzamento | Um candidato errado, que ainda batia com os traços, sai da lista (fica riscado na ficha de suspeitos) | Ruído: o que caça ouve a ligação e anda um passo; o próximo surgimento chega um turno antes |
| 3 · Ficha | Um traço verdadeiro chega por mensagem, como **pista firme** | 5 de Membrana: cavar fundo chama a atenção do Outro Lado |

Como as camadas funcionam:
- **Sem atalho para o culpado:** o cruzamento nunca risca o culpado. Se não sobra candidato errado para riscar, a ligação vai direto à ficha.
- **A camada 1** só vale com a ação do turno livre.
- **No online:** a ligação é um comando de lockstep (`pesquisa`). Os sorteios saem da semente, sem gastar os Dados, então dão o mesmo resultado em todas as máquinas.
- **Antes de ligar,** um papel mostra o pedido, o ganho e o custo. **A resposta** vem num segundo papel e vai para o registro.

![Ligar para a Pesquisa](p61_ligar.png)

### O mapa de rumores

Cada lugar onde o grupo acha pista firme vira um rumor:
- o evento;
- a cena de investigação;
- o Revisar Caso do interlúdio;
- a ficha da Pesquisa.

Com dois rumores em lugares diferentes, o mapa desenha:
- **um fio tracejado vermelho** de cada lugar até um **"?"**, que flutua devagar sobre a região onde o covil deve estar;
- **um anel fino no chão,** que marca o tamanho da região.

| Rumores | Raio da região |
|---|---|
| 2 | 3 hexes |
| 3 | 2 hexes |
| 4 ou mais | 1 hex |

- **O covil está sempre dentro dela.** O centro é sorteado pela semente, perto do covil, mas nem sempre em cima dele.
- **Quando "onde" é respondida,** o "?" sai: o covil já aparece no mapa.

Os rumores e as camadas usadas vão no save.

![O mapa de rumores](p61_rumores.png)

### O som em duas camadas

- **A Realidade é acústica:** um piano esparso em lá menor, sintetizado em código (ataque de martelo, cauda longa, parciais um pouco desafinados), num laço de 16 s.
- **Ele toca baixo** (−20 dB) com a Membrana inteira e **some** (−60 dB) quando a intensidade passa de 0,7.
- **O Outro Lado é sintético:** o drone e os sussurros de docs/11, que crescem enquanto o piano some.
- **Por cima:** as assinaturas de cada elemento (docs/54) e a trilha do chefe (docs/58).
- **Na Base,** que é segura, o piano se ouve inteiro.

## Equilíbrio

O playtest automático não usa a Pesquisa, e o resultado é o mesmo da fase anterior:

| Perfil | Vitória | Turnos |
|---|---|---|
| Investigador | 100% | 6,9 |
| Pressa | 80% | 11,5 |

A Pesquisa é uma válvula para quem travou. O custo crescente impede que ela substitua a investigação.

## O que fica para depois

- **O piloto automático usando a Pesquisa** quando trava, para medir o efeito dela no ritmo.
- **Os fios do mapa ligados às polaroides do quadro de investigação,** a mesma teia nas duas telas.
- **Timbres por elemento no piano** (relatório, AU1): metal no Sangue, notas invertidas na Morte, coro no Conhecimento, guitarra na Energia, piano solo no Medo.

## Onde está

- **Dados:** `casos.json`, com `pesquisa` (as camadas e os textos).
- **Regra (`Missao`):**
  - `proxima_pesquisa` e `ligar_pesquisa`;
  - `rumores`, `_anotar_rumor` e `regiao_dos_rumores`;
  - `pesquisa` e `rumores` vão no save.
- **Online:** o comando `pesquisa` em `Comandos`.
- **Tela:**
  - `MapaMundo._pedir_pesquisa` e o botão ☎;
  - `Mapa3D.atualizar_rumores`;
  - `Som`: a camada `piano` e `volume_da_realidade`.

## Testes

Total: **643**. Arquivo novo, `test_pesquisa.gd`:
- **Camadas:**
  - a camada 1 orienta e gasta a ação, e sem ação não liga;
  - a camada 2 risca um errado (nunca o culpado), faz ruído e risca o mesmo no online;
  - a camada 3 dá pista firme, custa Membrana e vira rumor;
  - sem o que riscar, a ligação vai direto à ficha.
- **Rumores:**
  - a região encolhe com mais rumores, sempre contém o covil e some com "onde" respondida;
  - o mapa desenha os fios, o anel e o "?".
- **Save e online:** a Pesquisa e os rumores vão no save, e o comando `pesquisa` funciona.
- **Som:** as duas camadas, com o piano sumindo quando a Membrana racha.
