# Playtest: notas de uma rodada de partidas

> Status: **v0.1**, 21/10/2026. Pedido: "tente jogar uma partida e vá anotando os pontos importantes".

## Como foi jogado

- **20 missões completas** com a lógica do jogo (mapa, eventos, cenas de investigação, combates, dedução e Conclusão do Caso), sem a interface. O script fica em `game/dev/playtest_auto.gd`, e os números brutos, em `docs/playtest41.json`.
- **Dois perfis:**

| Perfil | O que faz |
|---|---|
| **Investigador** | Vai primeiro aos hexes de investigação e de evento. Nos eventos, escolhe a opção em que é treinado, de preferência a que dá pista. Acusa quando as pistas firmes deixam um só suspeito e, antes do covil, arrisca o que der |
| **Pressa** | O piloto antigo: anda direto para o covil |

- **Os combates** foram resolvidos pela IA do jogo dos dois lados. Ela **não** usa manobras, golpe não letal, Fintar, Primeiros Socorros nem Acalmar, então essas partes não foram exercitadas aqui.
- **A interface** não foi jogada. As telas novas foram vistas só nas capturas das rodadas anteriores.

## Números (média de 10 missões por perfil)

| | Investigador | Pressa |
|---|---|---|
| Vitória | 90% | 90% |
| **Caso solucionado** | **90%** | **0%** |
| Turnos do mundo | 4,2 | 3,8 |
| Combates | 1,6 | 1,3 |
| Cenas de investigação | 1,6 | 0,1 |
| Eventos | 2,3 | 0,4 |
| Pistas firmes / incertas | 5,6 / 0,2 | 0,3 / 0,1 |
| Acusações certas / erradas | 3,2 / 0,3 | 0 / 0 |
| Reviravolta revelada | 90% | 0% |
| Turnos em que dava para escalar a serra | 2,4 | 2,3 |
| Subidas na serra | 0,2 | 0 |
| Membrana no fim | 74 | 82 |
| **PP no fim** | **+22,7** | **+0,7** |

## Pontos importantes

### 🔴 1. As missões são curtas demais
- O covil cai entre o **3º e o 6º turno do mundo**, com 1 ou 2 combates.
- Num For The King, a jornada é a maior parte da partida. Aqui, o mapa (16×11) e a distância até o covil acabam com a missão antes de a pressão da Membrana e dos surgimentos fazer efeito: a Membrana termina entre 74 e 82.
- **Sugestão:**
  - covil mais longe ou mapa maior;
  - um "selo" no covil que só abre com o "onde" respondido ou com N pistas;
  - mais encontros no meio do caminho.

### 🔴 2. Separar o grupo mata sem aviso
- Na semente 17, o Investigador perdeu a missão **no 1º turno**: cada agente foi para um lado, e só aliados a até 2 hexes entram no combate.
- Três lutas solo seguidas, três quedas, os reforços acabaram e a missão fracassou.
- **Sugestão:**
  - avisar ao mover para longe do grupo ("Mauro ficará sozinho a 3 hexes");
  - mostrar no hex de encontro quantos aliados entrariam.

### 🟡 3. A dedução está fácil
- **Uma cena** rende de 2 a 4 pistas, muitas vezes duas da mesma pergunta, o que já resolve a pergunta.
- Foram 3,2 acusações certas contra 0,3 erradas: o jogador quase nunca chega a duvidar.
- **Os depoimentos incertos quase não aparecem** (0,2 por missão): só testemunhas passando por menos de 5.
- **Sugestão:**
  - pontos de uma mesma cena espalhados entre as perguntas, no máximo 1 pista firme por pergunta por cena;
  - margem do depoimento firme maior (de 5 para 10);
  - mais pontos-testemunha.

### 🟡 4. PP demais por pista
- O investigador fecha com **+22,7 PP**, contra +0,7 de quem corre. A diferença é boa como incentivo.
- Mas a Tabela 3.2 dá +2 por "pista **adicional**", e o jogo conta **toda** pista. Com 9 pistas, são +18: a patente Operador (20 PP) chega numa missão só.
- **Sugestão:** contar só as pistas além das necessárias para as respostas, ou só as dos eventos (o "adicional" do livro).

### 🟡 5. A serra não tem motivo para ser escalada
- O 20 aparece em média 2,4 vezes por missão, mas o caminho quase nunca passa pela serra: subiram 0,2 vezes.
- Hoje a única recompensa é a vista.
- **Sugestão:** pôr algo lá em cima, como um evento exclusivo, uma pista ou um esconderijo com item.

### 🟢 6. O que funcionou
- **O caso dá sentido ao mapa:** quem investiga resolve 90% dos casos; quem corre, 0%. A Conclusão do Caso deixa isso visível.
- **A reviravolta aparece quase sempre** e costuma ser resolvida com os pontos que sobram. Ela estica a investigação sem travar.
- **Nenhuma missão travou.** As 20 terminaram, com 1 derrota em cada perfil.

### Ainda não exercitado
- **O que a IA de combate não faz:** manobras, Fintar, não letal e interrogatório, Primeiros Socorros e Acalmar. Ensinar a IA dos agentes (piloto e modo cooperativo) a usar ao menos Primeiros Socorros e o golpe não letal contra pessoas.
- **Pedido de socorro e inocentes:** o evento é sorteado entre 14, e não caiu em nenhuma das 20 missões.

## Prioridade sugerida

1. ✔ Missões mais longas: covil com selo, mapa maior e mais encontros (docs/42).
2. ✔ Aviso de grupo separado (docs/42).
3. Dedução mais difícil: pistas espalhadas por pergunta e mais testemunhas.
4. PP por pista adicional como no livro.
5. Recompensa no alto da serra.
6. IA dos agentes usando Primeiros Socorros e o golpe não letal.
