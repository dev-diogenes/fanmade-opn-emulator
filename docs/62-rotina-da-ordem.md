# A rotina da Ordem: sinais, fachada e varredura

> Status: **v0.1**, 22/10/2026. Décima primeira fase, com três itens de prioridade 2 do relatório de pesquisa (seção "Ordem, Base e missões"):
> - casos que chegam como sinais (OR1);
> - briefing num local de fachada (OR3);
> - varredura do covil (OR5).
>
> A lore vem da wiki (Ordo Realitas, C.R.I.S., Casos Paranormais). Na Ordem:
> - um programa varre a internet atrás de padrões;
> - às vezes os recrutas vão só para saber se o caso é mesmo paranormal;
> - os encontros acontecem em lugares banais, com pedido-senha;
> - depois do caso, alguém precisa apagar tudo sem deixar rastro.
>
> Textos, fontes, lugares e senhas são nossos.

## O problema

- **A escolha:** a missão procedural chegava pronta. O jogador não escolhia o caso.
- **O encontro:** o briefing era um arquivo sem lugar.
- **O fim:** o caso acabava no instante em que o chefe caía. Depois da luta, não havia nada a decidir.

## O que mudou

### Sinais da rede (OR1)

A aba Missão da Base mostra **três sinais**, um de cada nível de confiança. Cada sinal tem:
- **uma fonte:** post viral, nota no jornal da cidade, boletim de ocorrência, áudio de WhatsApp, fórum de caçadores de fantasma ou ligação para a rádio local;
- **um relato:** sai do elemento do caso que a missão vai gerar, e os três sinais nunca repetem relato. Exemplos:
  - "Postes acendem e apagam sozinhos, e os celulares da praça descarregam juntos";
  - "Três pessoas da mesma rua acordam sem lembrar o próprio nome".

Escolher um sinal troca a missão: a região, o caso e o briefing mudam com ele.

| Confiança | Alarme falso | Se for real |
|---|---|---|
| Alta | nunca | — |
| Média | 15% | — |
| Baixa | 40% | +2 PP: "ninguém dava nada por esse sinal" |

**O alarme falso:**
- **O mapa:** os encontros de criatura viram de gente ou bicho, e o que surge também.
- **A revelação:** no primeiro lugar com pista (evento ou investigação), um papel mostra o que era de verdade:
  - um abatedouro clandestino;
  - um transformador com defeito;
  - um adolescente com um projetor;
  - um vazamento de gás;
  - e outros.
- **Pela Pesquisa (docs/61):** ligar para ela também revela que não é paranormal, pelo custo da orientação (a ação do turno).
- **A recompensa:** 2 PP. O **NEX não sobe**, porque ninguém tocou o paranormal.

O sinal e o alarme falso vão no save. No online, a missão já sai com eles.

![Os sinais na Base](o62_sinais.png)

### O ponto de encontro de fachada (OR3)

Todo briefing de missão procedural começa num lugar banal, com senha e resposta. Alguns exemplos:
- um lava-rápido na saída da cidade ("Vim lavar o Fusca azul." / "O azul só depois das seis.");
- uma borracharia de beira de estrada;
- uma farmácia 24 horas;
- uma sala comercial de contabilidade no décimo andar;
- um sebo perto da rodoviária.

São oito ao todo, sorteados pela semente. O ponto aparece no briefing da Base e no arquivo do caso, ao abrir a missão, junto do sinal que trouxe o grupo.

![O arquivo do caso, com o ponto de encontro](o62_briefing.png)

### A varredura do covil (OR5)

Quando o chefe do caso gerado cai, a missão ainda não acaba. No hex do covil, um papel pede a varredura:

| Escolha | Teste | Resultado |
|---|---|---|
| Varrer com o grupo | Investigação, DT 15 (a ajuda dos colegas vale, docs/59) | Passou: limpo. Falhou: algo fica para trás |
| Varrer pelos símbolos (só com Ocultismo treinado) | Ocultismo, DT 12 | Igual |
| Chamar a equipe de varredura | — | Sempre limpo; −2 PP de cada agente |
| Ir embora sem varrer | — | Algo fica para trás |

**Quando algo fica para trás, o efeito vem na missão seguinte:**
- a Membrana já começa 5 mais fina;
- perto do início, a 2 ou 3 hexes, surge o evento **"O que ficou no covil"**: o símbolo do último covil, desenhado na porta de uma casa;
- apagá-lo pede Vontade DT 15, e passar longe custa Membrana.

As campanhas escritas à mão continuam terminando quando o chefe cai. O relatório da Base mostra a varredura entre as linhas de PP.

![A varredura](o62_varredura.png) ![O alarme falso](o62_alarme.png)

### Um defeito corrigido

O briefing da Base mostrava o marcador "{sintomas}" cru. Agora a prévia gera o mesmo caso da missão e traz os sintomas do elemento.

## Equilíbrio

O playtest automático não passa pela Base, então não tem sinal nem alarme falso. A varredura entra no fim, e o piloto a resolve como qualquer evento. As 20 missões terminam, e o resultado é o mesmo:

| Perfil | Vitória | Turnos |
|---|---|---|
| Investigador | 100% | 6,9 |
| Pressa | 80% | 11,5 |

## O que fica para depois

- **Credencial de fachada** que se queima com o uso (OR4).
- **Base como salas que prestam serviços** (OR2).
- **Cultistas rendidos na contenção,** interrogáveis entre missões (OR8).
- **O piloto automático escolhendo sinais,** para medir quantos alarmes falsos o jogador encontra.

## Onde está

- **Dados:**
  - `data/jogo/sinais.json` (novo): fontes, relatos, explicações, confiança e fachadas;
  - `eventos.json`: `eventos_da_ordem`, com o alarme falso, a varredura e o eco do covil.
- **Regra:**
  - `Sinais` (novo);
  - `Missao`:
    - `sinal`, `alarme_falso`, `alarme_confirmado` e `varredura`;
    - `_tirar_o_paranormal`, `_abrir_varredura` e `plantar_eco_do_covil`;
    - os efeitos `alarme_falso` e `varredura`;
    - a Pesquisa no alarme falso;
  - `Carreira`: `iniciar_missao(…, sinal)`, `eco_do_covil` e o PP no fim;
  - `Jogo`: `iniciar_missao(…, sinal)`.
- **Tela:**
  - a Base: os sinais e o briefing com sinal e fachada;
  - o mapa: o arquivo do caso com o ponto de encontro.

## Testes

Total: **653**.
- **Arquivo novo, `test_rotina.gd`:**
  - **Sinais:**
    - três sinais, um de cada confiança, com relatos diferentes e do elemento do caso;
    - a confiança decide o alarme falso.
  - **Fachada:** a fachada com senha no briefing.
  - **Alarme falso:**
    - tira o paranormal do mapa, se revela no primeiro lugar, rende pouco PP e não dá NEX;
    - vai no save;
    - a Pesquisa o desmascara.
  - **Varredura:**
    - o chefe cai e vem a varredura; a equipe custa 2 PP;
    - a varredura malfeita volta na missão seguinte, uma vez, e vai no save.
  - **Prestígio:** o sinal fraco e real rende mais.
- **Testes antigos de vitória no covil:** agora resolvem a varredura antes de encerrar.
