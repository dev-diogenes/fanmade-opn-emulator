# Memorial, adereços e a ajuda dos colegas

> Status: **v0.1**, 22/10/2026. Oitava fase do plano. Ela fecha três itens do relatório de pesquisa:
> - a parede de memória com a despedida (AG1);
> - os adereços no lugar de biografia (AG2);
> - o apoio ao teste do colega (CO1).
>
> A regra de ajuda é a do livro (p.86), já usada nas cenas de investigação.

## O problema

Quem morria virava uma linha no rodapé ("Em memória: Rita"), e o memorial era uma lista de nomes no relatório. Os agentes não tinham nada que os distinguisse além da classe e da foto. Nos eventos do mapa, cada agente testava sozinho, mesmo com o grupo inteiro no mesmo hex.

## O que mudou

### Adereços no lugar de biografia

Todo agente tem três adereços:
- **um apelido:** palavras sem gênero, como "Prego", "Faísca", "Sete Vidas" ou "Sabiá";
- **uma cidade natal:** cidades reais do Brasil de hoje, como Mossoró (RN), Juiz de Fora (MG) ou Macapá (AP);
- **um objeto que leva sempre:** um terço que era da avó, o boné do time do coração, uma figurinha rara da Copa, um bilhete de ônibus guardado há anos…

Como funcionam:
- **De onde vêm:** de listas próprias (`data/jogo/pessoais.json`), pelo nome do agente. O mesmo agente tem os mesmos adereços em todas as máquinas do online e também em saves antigos.
- **Só apresentação:** as regras não leem nada disso.
- **Onde aparecem:**
  - **ficha:** "Conhecido como “Prego”. De Mossoró (RN). Leva sempre…";
  - **foto da cerimônia:** "Mauro “Vela”";
  - **memorial.**

### A parede de memória

A Base ganhou a aba **Memorial**. Cada agente que caiu tem um cartão em papel com:
- **a foto de luto:** em cinza, sem o amarelado das outras, com a fita preta no canto;
- **uma vela acesa,** que treme;
- **o nome com o apelido,** o NEX e a patente de quando caiu, e a cidade;
- **a missão e o lugar do caso;**
- **a causa e a data;**
- **o objeto que levava;**
- **o último registro em que o nome aparece,** sem o aviso de morte.

Quem caiu por último fica primeiro. Sem ninguém na parede, ela diz: "Ninguém na parede, ainda. Que continue assim."

![A parede de memória](m59_parede.png)

### A despedida

Na volta da missão, a cerimônia de NEX não joga mais quem morreu no rodapé. A pessoa fica **na mesma fileira de quem voltou**, com:
- a foto de luto;
- "EM MEMÓRIA";
- a causa;
- o que levava;
- a vela.

O resto da história fica na parede.

![A despedida na cerimônia](m59_despedida.png)

### A ajuda dos colegas nos eventos

A regra de ajuda do livro (p.86) agora vale nos testes de evento do mapa:
- **quem ajuda:** quem está no mesmo hex, vivo e de pé;
- **o teste:** cada ajudante testa a mesma perícia contra DT 10;
- **o bônus:** quem passa soma +1 no teste de quem enfrenta o evento, e mais +1 a cada 10 acima da DT;
- **quem não ajuda:**
  - quem não pode usar a perícia (sem treino, se ela exige);
  - um Teimoso, que não ajuda nem recebe ajuda;
- **na tela:** o painel do evento avisa quem está junto, e cada ajuda vai para o registro.

Vale andar em grupo, como em For The King. Separar-se continua tendo o custo de docs/42: ficar sozinho no mapa.

## Equilíbrio

Playtest automático, com 10 sementes em cada perfil:

| Perfil | Vitória | Turnos |
|---|---|---|
| Investigador | 100% | 6,9 |
| Pressa | 80% | 11,5 |

É o mesmo resultado da fase anterior. A ajuda só pesa quando o grupo anda junto, e o piloto automático se espalha.

## O que fica para depois

- **Apelido ganho por um feito:** quem resolve o Enigma de Medo vira "Chave"; quem volta de "morrendo" vira "Sete Vidas".
- **Escolher os adereços na criação:** hoje eles são sorteados pelo nome.
- **O objeto pessoal no modelo 3D** (o boné, o terço) e um apego que ajude no interlúdio, se o livro permitir.

## Onde está

- **Dados:** `data/jogo/pessoais.json` (novo).
- **Regra:**
  - `Agente`: `apelido`, `cidade`, `objeto`, `completar_pessoais` e `nome_com_apelido`;
  - `Carreira.entrada_do_memorial`;
  - `Missao`: `ajudantes_do_evento` e `_ajudar_no_evento`, chamado em `resolver_evento`.
- **Tela:**
  - `Memorial` (novo): a parede, o cartão e a despedida;
  - `Vela` (novo);
  - `FotoAgente.luto`;
  - a aba Memorial da Base;
  - a cerimônia de NEX;
  - a ficha;
  - o painel de evento do mapa.

## Testes

Total: **629**.
- **Arquivo novo, `test_memorial.gd`:**
  - os agentes ganham os adereços, iguais no online, no save e em saves antigos;
  - o memorial guarda a foto, o lugar, a data e o último registro sem marcas;
  - o cartão mostra o apelido, a causa com a data, o objeto, o último registro, a fita e a vela;
  - quem está no hex ajuda, quem está longe não;
  - a ajuda soma pela regra do livro.
- **`test_visual.gd`:** a Base tem 5 abas.
