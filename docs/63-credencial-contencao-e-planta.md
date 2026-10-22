# A credencial, a contenção e a planta da Base

> Status: **v0.1**, 22/10/2026. Décima segunda fase, com mais três itens da seção "Ordem, Base e missões" do relatório de pesquisa:
> - credencial de fachada que se queima (OR4);
> - Base com salas que prestam serviços (OR2);
> - cultistas na contenção (OR8).
>
> A lore vem da wiki:
> - **a falsa divisão de polícia:** a Ordem a usa para ganhar acesso e jurisdição. O nome canônico fica fora, pela licença; o daqui é inventado.
> - **a Base:** um bar velho de fachada, com enfermaria, balcão de equipamentos, escritório com o quadro de fios vermelhos, sala de ocultismo, laboratório e celas.
> - **as celas:** vão de A a D, escuras, só com uma vela, para que os presos não se concentrem em símbolos.

## O problema

- **A credencial:** a Ordem se passa por polícia na lore, mas o jogo não tinha nada disso.
- **Os rendidos:** um cultista desacordado com dano não letal (docs/40) dava uma pista e sumia.
- **A Base:** eram abas de formulário, sem os lugares da Base.

## O que mudou

### A credencial de fachada (OR4)

A cada missão, o grupo recebe uma credencial da **Delegacia de Ocorrências Atípicas (DOA)**, com um nome inventado, como "Agente Moreira". O nome sai da semente e é o mesmo em todas as máquinas.

- **Onde vale:** nas testemunhas, isto é, nos pontos de depoimento. No bilhete de Procurar aparece o selo "✦ Credencial DOA (+5, depoimento firme · usos/3)".
- **O que dá:**
  - +5 no teste;
  - **o depoimento sai firme,** mesmo passando por pouco. Diante de uma "delegada", ninguém arrisca mentir.
- **Quanto dura:** um uso por teste.
- **Quando queima:** no **terceiro uso** no mesmo caso, alguém liga para a delegacia, e o número não existe. Daí em diante:
  - a credencial não vale mais nesta missão;
  - **uma patrulha** (o encontro de polícia que já existia) surge ao lado de onde a cena aconteceu.
- **No online:** a cena recebe o estado da credencial da Missão e devolve os usos no fim. O selo vai como opção do comando `procurar`, então dá o mesmo resultado em todas as máquinas.

![A credencial na testemunha](c63_credencial.png)

### Os cultistas na contenção (OR8)

- **A prisão:** quando um encontro termina com gente rendida, um deles vai algemado para a contenção. Ele recebe um nome de gente comum e o papel que tinha (iniciado, cultista…).
- **As celas:** na volta, ele ocupa a primeira cela livre (A a D), com dois segredos. Com as quatro celas cheias, o preso novo é transferido.
- **O interrogatório,** na sala Contenção da Base:
  - **quem:** o agente escolhido, uma vez por preso a cada visita;
  - **o teste:** a melhor perícia do agente entre Intimidação, Diplomacia e Intuição, contra DT 15;
  - **se passa:** o preso fala, e a **próxima missão começa com uma pista firme** na pergunta "quem" ("O preso da cela B falou: …"). Ele gasta um segredo e, sem segredos, é transferido;
  - **se falha:** o preso só repete um sigilo com o dedo na parede, e a vela treme.
- **No save:** os presos e a pista pendente vão no save.

### A planta da Base (OR2)

A Base ganhou a aba **Base**, a primeira, com nove salas em cartões de papel:

| Sala | O que faz |
|---|---|
| Bar de fachada | A entrada; leva à mesa dos jogadores |
| Escritório | As pastas dos agentes |
| Central de sinais | Os sinais da rede (docs/62) |
| Balcão de equipamentos | O arsenal por patente |
| Sala de ocultismo | Abre a sala de Transcender de quem tem escolha de NEX pendente |
| Enfermaria | Diz o que a volta cura: PV, PE, Sanidade, condições e efeitos de insanidade |
| **Laboratório** | **Novo:** as pistas além do necessário viram **amostras** (até 2 por missão, nada no alarme falso). Uma amostra diz se um sinal da rede é real ou alarme falso, e o resultado aparece também no botão do sinal |
| **Contenção** | **Novo:** os presos, as celas e o interrogatório |
| Memorial | A parede de memória (docs/59) |

A Base continua abrindo na aba Missão. As abas agora são encontradas pelo nome, não pela posição.

![A planta da Base](c63_planta.png)

## Equilíbrio

| Perfil | Vitória | Turnos |
|---|---|---|
| Investigador | 100% | 6,9 |
| Pressa | 80% | 11,5 |

O playtest automático ficou igual: o piloto não usa a credencial nem passa pela Base. A credencial é uma ferramenta forte e curta: três depoimentos firmes por caso, pagos com uma patrulha. A pista do preso vale uma por missão.

## O que fica para depois

- **A credencial em eventos com polícia** e na cena da delegacia, onde ela devia pesar mais (e a "cidade capturada pelo culto", em que ela vira risco).
- **Presos que fogem** se a vela apagar, ou que **voltam como inimigos**.
- **O laboratório transformando amostras em outros bônus,** como munição do elemento ou um ritual preparado.
- **A planta da Base em 3D,** em vez de cartões.

## Onde está

- **Dados:** `sinais.json`, com `credencial`, `contencao` e `laboratorio`.
- **Regra:**
  - `CenaInvestigacao`: `credencial`, `usos_credencial`, `pode_usar_credencial` e `_usar_credencial`;
  - `Missao`:
    - `credencial` e `presos`;
    - `_somar_usos_da_credencial`, `_levar_preso` e `receber_pista_do_preso`;
  - `Carreira`: `contencao`, `pista_do_preso`, `amostras`, `interrogar` e `analisar_sinal`.
- **Tela:**
  - `Investigacao`: o selo da credencial;
  - a Base: a aba e a planta (`_montar_planta`, `_sala_laboratorio`, `_sala_contencao`) e `ir_para_aba`.

## Testes

Total: **662**.
- **Arquivo novo, `test_contencao.gd`:**
  - **Credencial:**
    - tem nome inventado, igual no online e com órgão que não é o do cânone;
    - dá +5 e firma o depoimento;
    - queima no terceiro uso, traz a patrulha e vai no save.
  - **Contenção:**
    - o rendido vai para a cela A, com dois segredos, e vai no save;
    - com as celas cheias, o preso novo é transferido;
    - o interrogatório vale uma pista na próxima missão, uma vez por visita;
    - sem segredos, o preso é transferido.
  - **Laboratório:** uma amostra verifica um sinal.
  - **Planta:** tem as nove salas e leva às abas.
- **`test_visual.gd`:** a Base tem seis abas e abre na Missão, conferida pelo nome.
