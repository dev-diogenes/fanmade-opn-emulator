# As ameaças manobram

> Status: **v0.1**, 21/10/2026. Pedido: "faz as ameaças usarem as manobras (agarrar, derrubar, fintar)".

## Quem manobra

Só **pessoas**: ameaças que lutam com armas da tabela, como cultistas, bandidos, capangas e policiais. Criaturas e animais usam as habilidades da própria ficha.

A IA escolhe **no máximo uma manobra por rodada** por ameaça. A "sorte" da escolha sai de uma semente da rodada, da ameaça e do alvo: é igual nas duas máquinas do online e não gasta dados.

| Manobra | Quando a ameaça faz | Frequência |
|---|---|---|
| **Agarrar** | O agente ao lado **atira** ou **conjura rituais**: agarrado, ele perde 1 dado e fica preso | Metade das vezes |
| **Derrubar** | Outro aliado da ameaça também está ao lado do alvo: caído, o alvo fica com −5 na Defesa contra os dois | Um terço das vezes |
| **Fintar** | A chance de acertar está abaixo de 35%: no próximo ataque, o alvo fica desprevenido | Um terço das vezes |

Fora isso, a ameaça ataca como antes. Os agentes respondem com os botões que já existem:
- **Soltar-se**, num teste de manobra oposto;
- **Levantar-se**, com uma ação de movimento.

## Pendências de ficha resolvidas

| Ameaça | Habilidade (livro) | Agora |
|---|---|---|
| **Cão de Guarda** (p.288) | Derrubar: ao acertar a mordida, faz a manobra derrubar de graça, com +2 dados e +5 | ✔ |
| **Ocioso** (p.254) | O dano da Retaliação é não letal | ✔ Desacorda sem deixar morrendo, sem −5 (o golpe já é não letal por natureza) |

**Continuam pendentes:**
- **Empurrar e Atirar**, do policial de elite: uma ação completa com Fortitude e depois um tiro de fuzil;
- a **Rasteira de Tentáculo**, do Carente.

## Agentes no automático

Os agentes jogados pela IA (piloto, playtest e o modo autoplay da arena) tentam se soltar quando estão agarrados por manobra. No jogo normal, os agentes são sempre dos jogadores.

## Testes

Total: **545**.
- **Escolha da manobra:** em 30 rodadas, o bandido às vezes agarra a atiradora e às vezes só ataca. O zumbi nunca manobra. Só uma manobra por rodada.
- **Cão:** a mordida derruba.
- **Ajustado:** o teste do Ocioso agora espera dano não letal na Retaliação.
