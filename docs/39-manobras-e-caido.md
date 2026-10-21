# Manobras de combate e a condição caído

> Status: **v0.1**, 21/10/2026. Pedido: "implementa as manobras de combate (agarrar, derrubar, desarmar, empurrar) com a condição caído". Regras do livro, p.85-86 (manobras), p.84 (levantar-se) e p.310 (caído).

## Como funciona

**A regra geral (p.85):** a manobra é um ataque corpo a corpo que, em vez de causar dano, faz outra coisa.

- **O teste:** o atacante faz um teste de **Luta** contra a **Luta** do alvo, e um empate se rola de novo. Os modificadores de ataque corpo a corpo entram no teste: flanquear dá +1 dado; estar caído tira 2 dados; estar agarrado tira 1.
- **Custo:** gasta a **ação padrão**.
- **Alcance:** só contra inimigo **ao lado**. Manobra à distância não existe.

| Manobra | Vencendo o teste |
|---|---|
| **Agarrar** | O alvo fica **agarrado**: desprevenido, sem se mover e com −1 dado no ataque (a condição que o jogo já tinha). Agarrar de novo quem você já segura **esmaga**: dano de impacto de um ataque desarmado (1d3 + Força) |
| **Derrubar** | O alvo fica **caído**. Vencendo por 5 ou mais, ele também é arrastado 1 quadrado |
| **Desarmar** | A arma cai no espaço do alvo, e ele **luta desarmado** até pegá-la (ação de movimento). Contra criaturas, só funciona se o ataque for uma arma da tabela: garras não caem |
| **Empurrar** | Empurra 1,5 m, mais 1,5 m a cada 5 pontos de diferença, até um obstáculo |

- **Para se soltar:** quem está agarrado por manobra usa **Soltar-se** (ação padrão), com outro teste de manobra oposto.
- **Quando a vítima sai sozinha:** se quem agarra cai fora de combate.

### Caído (p.310)

| Efeito | Valor |
|---|---|
| Ataques corpo a corpo de quem está caído | **−2 dados** |
| Deslocamento | **1,5 m** (1 quadrado) |
| Defesa contra ataques corpo a corpo | **−5** |
| Defesa contra ataques à distância | **+5** |
| Levantar-se | **Ação de movimento** (botão **Levantar-se**) |

A condição termina no fim da cena. As ameaças caídas levantam no começo do turno, e as desarmadas pegam a arma se ainda tiverem ação de movimento.

## Na tela

- **Manobra ▾**, ao lado do Foco: escolhe Agarrar, Derrubar, Desarmar ou Empurrar e depois o inimigo ao lado. Fica apagado sem ação padrão.
- **Levantar-se** e **Pegar a arma** aparecem só quando servem.
- **No tabuleiro:** quem está caído aparece deitado, com "— no chão" no rótulo, em âmbar.
- **No registro:** o teste ("Manobra: Mauro 24 contra Cultista 9") e o resultado.
- **Online:** os comandos `manobra`, `levantar` e `pegar_arma` funcionam em lockstep.

![Cultista no chão e o botão Manobra](man39_combate.png)

## Simplificações (fora por enquanto)

- Quem agarra **solta** a vítima ao se mover. No livro, ele a arrasta com metade do deslocamento.
- A mão ocupada de quem agarra e os 50% de acertar o alvo errado ao atirar em quem está agarrado não entram.
- Desarmar com folga (5 ou mais) não joga a arma para outro quadrado: ela fica aos pés do alvo.
- Ao empurrar, o atacante não avança junto. Quebrar e atropelar continuam fora.

## Testes

Total: **531**.
- **Derrubar:** deixa caído (−2 dados no corpo a corpo, 1 quadrado de deslocamento) e gasta a ação padrão. Levantar tira a condição e gasta a ação de movimento.
- **Desarmar:** a adaga de ficha (que não é arma da tabela) não cai. A faca cai, o cultista luta desarmado e pega a arma de volta.
- **Empurrar:** afasta o alvo na direção oposta.
- **Agarrar:** exige estar ao lado; o agarrado não anda; quem agarra e se move solta.
