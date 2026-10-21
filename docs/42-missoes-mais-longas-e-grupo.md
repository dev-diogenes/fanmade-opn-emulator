# Missões mais longas e o aviso de grupo separado

> Status: **v0.1**, 21/10/2026. Os dois primeiros pontos do playtest (docs/41): missões curtas demais (3 a 6 turnos) e grupo separado que morre sem aviso.

## Covil selado

O covil precisa ser **encontrado**, como no livro: a pergunta "Onde fica o covil?" existe para isso.

- **Sem saber onde, não há entrada:** quem chega ao hex do covil sem saber onde procurar não acha a entrada. Não há luta, e o registro explica: "Responda 'Onde fica o covil?' na ficha".
- **O que abre o covil:**
  - a acusação certa do **onde**;
  - um evento que o revele (`revelar_objetivo`, como no carro abandonado ou com o morador);
  - uma marca de campanha.
- **Membrana rompida:** o covil **se abre à força**. A `membrana.json` já dizia que, rompida, "a missão entra no confronto final, preparada ou não". Agora isso acontece de fato, e ninguém fica preso.
- **No painel do caso:** o covil aparece como "desconhecido", "avistado, entrada escondida" ou "aberto: o confronto espera".
- **Na dica do hex:** "Entrada escondida: responda 'Onde fica o covil?'".
- **Missões da comunidade e de campanha:** o selo só vale se a definição pedir (`"covil_selado": true`), porque o conteúdo autoral pode não ter como responder "onde". As missões procedurais são seladas por padrão (`mapa.json`, `covil_selado`).
- **Saves antigos:** carregam com o covil já localizado, como antes.

## Mapa maior e mais conteúdo

| | Antes | Agora |
|---|---|---|
| Tamanho | 16×11 | **20×12** |
| Encontros | 7 | 9 |
| Eventos | 6 | 8 |
| Investigações | 3 | 4 |
| Vilas (descanso) | 1 | 2 |
| Ruínas / serras | 4 / 4 | 5 / 5 |

## Aviso de grupo separado

Só entra na luta quem está a até 2 hexes. No playtest, um agente sozinho caiu três vezes no 1º turno, e a missão acabou. Agora:

- **No mapa:** os destinos em que o agente ficaria **longe de todos** aparecem em **âmbar**, em vez de azul. A linha de baixo explica: "clique num hex azul (âmbar: longe do grupo)".
- **Na dica do destino:** "⚠ Longe do grupo: se houver luta, Mauro luta sozinho".
- **Nos hexes de encontro e de covil:** a dica mostra "Entrariam na luta: N agente(s)".
- **Ao terminar o movimento sozinho:** o registro avisa "⚠ Mauro está longe do grupo: numa luta, ninguém chega a tempo".

| Destinos: azul perto, âmbar longe | O covil avistado, com a entrada escondida |
|---|---|
| ![Destinos](sel42_destinos.png) | ![Covil](sel42_covil.png) |

## O piloto automático investiga

O piloto ia direto ao covil porque "sabia" onde ele ficava, o que um jogador não sabe. Agora ele faz o caminho de um jogador:

1. Com o covil fechado, vai atrás de investigações e eventos.
2. Acusa quando as pistas firmes deixam um só suspeito.
3. Sem nada mais a investigar, arrisca as acusações.

As acusações viram comandos `deduzir`, então entram no replay.

## Medido de novo (`dev/playtest_auto.gd`, 10 seeds; números brutos em `docs/playtest42.json`)

| | Antes (docs/41) | Agora |
|---|---|---|
| Turnos do mundo (investigador) | 4,2 (de 3 a 6) | **8,0 (de 6 a 12)** |
| Turnos do mundo (pressa) | 3,8 | **9,9 (de 6 a 13)** |
| Combates | 1,6 | 2,3 a 2,5 |
| Cenas de investigação | 1,6 | 2,6 a 3,8 |
| Eventos | 2,3 | 6,2 a 7,9 |
| Membrana no fim | 74 a 82 | **46 (investigador) e 16 (pressa)** |
| Caso solucionado | 90% e 0% | 100% e 80% |
| Vitória | 90% | 100% e 90% |

No piloto dos testes, cada missão leva de 8 a 13 turnos, com 2 a 4 combates, 3 a 8 eventos e 2 a 4 investigações. A campanha do piloto termina nas duas seeds, sem mortes.

A Membrana agora pesa: quem demora a deduzir chega ao fim perto de rompê-la.

**Efeito colateral:** com mais pistas, o PP sobe para 32 a 38 por missão. Corrigir o "PP por pista **adicional**" (item 4 do docs/41) ficou mais urgente.

## Testes

Total: **535**.
- **Ajustados:**
  - a missão do teste de rede começa com o covil localizado, porque o teste é da rede e não do selo;
  - a campanha do piloto automático continua terminando, agora investigando.
- **Cobertura:** o replay das missões do piloto e as 10 seeds do piloto (de 8 a 13 turnos) cobrem o selo.
