# Combate: terreno, Fintar, dano não letal e arrasto

> Status: **v0.1**, 21/10/2026. Item 2 dos próximos passos: o que faltava da conferência do combate com o livro (docs/38 e 39).

## Posição elevada e camuflagem leve (p.89)

A arena ganhou dois tipos de casa, sorteados pelo terreno do hex (`mapa.json`, `arena`):

| Casa | Efeito | Onde aparece |
|---|---|---|
| **Elevado** (bloco de pedra ou escombro) | Quem ataca dali um alvo que **não** está no alto ganha **+1 dado**. Subir custa o dobro, como terreno difícil (design do jogo) | Morro (4), ruínas (3), serra (6) |
| **Camuflagem** (moita com neblina baixa) | Ataques contra quem está ali **erram com 1 ou 2 num d10** (20%), mesmo acertando | Mata (6), pântano (5), ruínas (2) |

- **A chance mostrada no alvo já conta os dois:** +1 dado do alto, ×0,8 com camuflagem.
- **No tabuleiro:** a figura fica em cima do bloco.

![Bloco elevado e moitas](ter40_tabuleiro.png)

## Fintar (p.86)

- **O teste:** ação padrão; **Enganação** contra **Reflexos** de um inimigo em alcance curto.
- **Se passar:** o alvo fica **desprevenido contra o seu próximo ataque** (−5 na Defesa e libera o Ataque Furtivo). A finta acaba quando você ataca ou no fim do seu próximo turno.
- **Na tela:** está no menu **Manobra ▾**, como "Fintar (Enganação)".

## Dano não letal (p.88)

- **Como funciona:** o dano não letal soma com o letal para deixar **inconsciente**, mas **não** para deixar morrendo. A cura tira primeiro o não letal.
- **O padrão de cada arma:** o desarmado é não letal; as armas são letais. Trocar o padrão custa **−5 no ataque**, e só vale no corpo a corpo.
- **Na tela:** o botão **Golpe não letal (−5)**, que vira **Golpe letal (−5)** quando o agente está desarmado.
- **Design do jogo:**
  - criaturas paranormais não desmaiam: contra elas, o golpe é sempre letal, sem penalidade;
  - ataques que carregam um ritual também são letais;
  - o dano não letal some no fim da cena.
- **Rendidos viram pista:** pessoas, como os cultistas, desacordadas com dano não letal são **interrogadas depois da vitória**. O caso ganha uma pista (uma por encontro), e o registro avisa "Interrogatório: 1 rendido acorda algemado e fala". Assim, poupar dá ao jogador um motivo de investigação, não só de moral.

## Arrastar quem está agarrado (p.85)

Quem agarra por manobra agora **anda metade do deslocamento, arrastando a vítima**, que vai para a casa livre ao lado mais perto de onde estava. Sem casa livre, ela escapa no tranco. Antes, mover soltava.

## O que ainda fica de fora

- Quebrar e atropelar.
- A mão ocupada de quem agarra.
- Os 50% de chance de acertar o alvo errado ao atirar em alguém agarrado.

## Testes

Total: **535**.
- **Fintar:** −5 na Defesa contra o próximo ataque, e só nele.
- **Terreno:** do alto, a chance sobe; a camuflagem dá 20% de erro; subir custa o dobro.
- **Não letal:** desacorda sem deixar morrendo e sem tirar PV letal; quem desmaia entra na lista de rendidos; a cura tira o não letal primeiro.
- **Arrasto:** quem agarra anda e a vítima vem junto, ainda agarrada.
- **Ajustado:** o teste do enxame de ratos agora pede golpe letal, já que o soco passou a ser não letal, como no livro.
