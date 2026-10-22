# Interlúdio pelo livro

> Status: **v0.1**, 21/10/2026. Pedido: "seguir à risca o sistema" (item 3 da lista: o descanso da vila pela regra do interlúdio, p.92-93).

## O que estava errado

Numa vila ou no ponto de encontro, o botão **Descansar** devolvia **25% do máximo** de PV, PE e SAN ao agente da vez, uma vez por visita. A regra não existe no livro. O livro tem o **interlúdio**: uma pausa de algumas horas em que **cada personagem faz até duas ações** de uma lista, e a recuperação depende do **limite de PE do NEX** e da **condição do descanso**.

## Como ficou

O botão virou **Interlúdio**. Ele abre uma folha com **todos os agentes que estão no hex** e ainda não fizeram interlúdio nessa visita. Cada um escolhe até duas ações, **por botões** (docs/47). Alimentar-se pede o prato e Revisar caso pede o ponto, também por botões. **Encerrar interlúdio** só acende com as escolhas completas.

![A folha do interlúdio: Mauro dorme e come o prato nutritivo; Bianca relaxa e revisa o livro de registros da capela; Rita relaxa e lê](int48_painel.png)

| Ação | O que faz no jogo | ref |
|---|---|---|
| Dormir | Recupera PV e PE iguais ao limite de PE do NEX, vezes a condição | p.93 |
| Relaxar | Recupera SAN igual ao limite de PE, vezes a condição, **+1 por agente que relaxar nesse interlúdio** (contando o próprio) | p.93 |
| Alimentar-se | Um prato (ver abaixo) | p.92-93 |
| Exercitar-se | Guarda **+1d6** para um teste de AGI, FOR ou VIG até o fim da missão. Acumula até o Vigor (mínimo 1); um por teste | p.93 |
| Ler | O mesmo para INT ou PRE. Acumula até o Intelecto (mínimo 1) | p.93 |
| Revisar caso | Volta a um ponto de investigação que **ficou para trás** numa cena já feita. Testa a melhor perícia do ponto contra a DT dele; passando, a pista entra no caso. Depoimento passando por menos de 10 entra duvidoso, como na cena (docs/35 e 44) | p.93 |

**Condição do descanso** (multiplica a recuperação): precária ×½, normal ×1, confortável ×2, luxuosa ×3. Hoje a vila e o ponto de encontro são **normais** (`condicao_por_lugar` em `mapa.json`). O livro liga a condição ao lugar e ao crédito; um lugar melhor fica para quando houver hospedagem no mapa.

**Pratos:**

| Prato | Efeito |
|---|---|
| Favorito | Relaxando, +2 SAN |
| Nutritivo | Dormindo, a recuperação de **PV** sobe um passo (normal → confortável) |
| Energético | Dormindo, a recuperação de **PE** sobe um passo |
| Rápido | +5 no teste de Revisar caso |

**Regras do mapa:**
- Cada agente faz **um interlúdio por visita** ao lugar.
- O interlúdio **encerra o movimento** do agente da vez.
- Os bônus guardados (exercício e leitura) **somem no fim da missão**.

### Exemplo, NEX 5% (limite de PE 1)

Mauro dorme com o prato nutritivo: +2 PV (passo confortável) e +1 PE. Bianca e Rita relaxam: cada uma recupera 1 + 2 = 3 SAN.

## Onde está

- **Regra:** `Missao.interludio(escolhas)`, `participantes_interludio()`, `condicao_interludio()`, `pontos_revisaveis()` e `_revisar_caso()`.
  - A cena de investigação devolve em `resultado()` os pontos que ficaram sem pista (`restantes`). A missão os guarda em `revisaveis`, que vai no save.
- **Bônus:** `Agente.bonus_exercicio` e `bonus_leitura`, gastos em `Agente.testar` conforme o atributo do teste. Vão no save; `Carreira` zera na volta.
- **Dados:** `interludio` em `data/jogo/mapa.json`: ações por agente, condição por lugar, multiplicadores, passos e pratos.
- **Online:** comando `interludio` (lockstep). As escolhas de todos vão num comando só.
- **Tela:** `PainelInterludio` (novo), aberto pelo botão **Interlúdio** do mapa.
- **Piloto e saves antigos:** `Missao.descansar()` continua existindo. É um interlúdio só do agente da vez, com Dormir e Relaxar.

## O que ficou de fora

- **Manutenção** (consertar um item quebrado): o jogo ainda não quebra itens.
- **Revisar caso duas vezes** no mesmo interlúdio: o livro permite; hoje cada ação entra uma vez.
- **Condições melhores que a normal** (pousada, hotel): falta o lugar no mapa e o gasto de crédito.

## Equilíbrio: não verificado

A recuperação ficou **bem menor** que a antiga. Em NEX 5%, dormir devolve 1 PV e 1 PE, contra uns 5 PV antes. É o que o livro diz, e empurra o grupo a curar com Primeiros Socorros, itens e rituais.

O playtest automático (`dev/playtest_auto.gd`, 10 sementes) deu vitória 0,9 e mortos 0,1, mas **nenhum descanso**. O perfil do piloto não volta à vila, então a nova recuperação ainda não foi posta à prova. Fica para o próximo playtest.

## Testes

Total: **553**.
- **Dormir e relaxar** pelo limite de PE; +1 SAN por agente que relaxou; prato favorito +2; uma vez por visita; o movimento acaba.
- **Exercício:** guarda 1d6, que é gasto no teste de Atletismo; a leitura fica para INT/PRE.
- **Revisar caso:** acha o ponto que tinha ficado para trás e a pista entra no caso.
- **Folha do interlúdio por seleção:** Encerrar só acende com o prato escolhido; o comando leva as escolhas.
