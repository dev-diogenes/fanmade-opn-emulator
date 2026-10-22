# Testemunhas com nome e o momento da pista

> Status: **v0.1**, 22/10/2026. Quinta fase do plano (docs/51: close-up da pista e testemunhas com nome; relatório de pesquisa, itens IN3 e IN9). O livro guia o formato: os NPCs (p.163), os sentidos na descrição (p.161) e o terror indireto (p.163).

## O problema

Em docs/51, as testemunhas eram figuras sem rosto e sem nome ("Vizinha na janela", "Viúva"). E a descoberta, o melhor momento de um jogo de investigação, virava uma polaroide com uma palavra; o texto ficava no relatório recolhido.

## O que mudou

### Testemunhas com nome

Cada ponto de depoimento ganha uma pessoa, pelo roteiro de NPC do livro: **nome, função, um traço de aparência e um de jeito**.
- **Nomes, aparências e jeitos** saem de listas próprias, com nomes comuns do Brasil e não os da tabela do livro (`data/jogo/testemunhas.json`). Um em cada três vem com "Dona" ou "Seu".
- **O gênero** vem do nome do ponto: "Viúva" e "Bilheteira" são mulheres. Um campo `genero` no ponto manda, se houver.
- **A mesma pessoa:** a semente sai do caso, da cena e do ponto. É a mesma nas duas máquinas do online e se repete se a cena for reaberta.
- **O nome aparece no ponto:** "Dona Marlene · Viúva".
- **O depoimento começa por quem fala:** "Dona Marlene, de roupa de domingo, fora de hora, aperta as mãos até os dedos ficarem brancos. A viúva fala entre um soluço e outro…"

### Terror indireto: a testemunha que some

O livro sugere ferir **indiretamente**, por exemplo matando um NPC de quem o grupo gosta, para o jogador ficar esperando o próximo golpe (p.163). Aqui:
- As testemunhas que o grupo ouviu ficam guardadas na missão, com o save.
- **Quando a noite cai** e o caso ainda não está confirmado, **uma em três vezes**, uma delas some: "Dona Marlene, viúva que falou com vocês no velório…, não volta para casa esta noite. Na porta, só um sinal que ninguém da cidade sabe ler."
- **Custo:** a Membrana cai 2, porque o medo se espalha. Sem PP: ninguém podia impedir.
- O acaso sai da semente da missão e do turno, igual no online.

### O momento da pista

Quando um agente acha algo:
- **A câmera chega perto** do objeto, e os nomes dos pontos saem da frente.
- **Um bilhete em close-up** mostra:
  - **o título:** PISTA (ou DEPOIMENTO, se incerto) e o ponto;
  - **o carimbo do traço:** ✔ em verde, ou ? em âmbar no depoimento incerto;
  - **a lente:** com que se achou, pela perícia usada. Por exemplo, "Com a lanterna" (Percepção), "Com a câmera modificada" (Tecnologia), "Com o pó de sigilos" (Ocultismo) ou "Com a conversa" (Diplomacia);
  - **um sentido além da visão,** pelo elemento do caso (o livro pede isso na p.161):
    - Sangue: carne podre;
    - Morte: cinza, enxofre e mofo, e o ar que esfria;
    - Conhecimento: um sussurro sem língua;
    - Energia: um zumbido que arrepia;
  - **na Morte, a assinatura canônica da wiki para aquela lente:**
    - na câmera modificada, um vulto cinzento que repete o gesto;
    - pó branco em espirais;
    - o termômetro que cai;
    - o eco que chega antes do som;
  - **o texto da pista, datilografado.**
- **Some** em 4,5 segundos ou com um clique. Ao fechar, o quadro abre e prende a foto, como antes.

![O depoimento da viúva, num caso de Morte](t56_closeup.png)

## O que fica para depois

- Testemunhas que **voltam** em eventos, que **mandam mensagem** entre turnos ou que **são do culto** (relatório, IN9).
- **Lentes que dependem de item** (a lanterna UV, a câmera), e não só da perícia: pede itens novos no arsenal.

## Onde está

- **Dados:**
  - `data/jogo/testemunhas.json`: nomes, aparências, jeitos, lentes e o sumiço;
  - `casos.json`: `sentido` e `assinaturas` em cada elemento.
- **Regra:**
  - `CenaInvestigacao`: `_nomear_testemunhas`, `testemunhas`, `testemunhas_ouvidas` e `detalhes_da_pista`. A cena agora trabalha numa cópia dos dados, e `_encontrar_pista` guarda a perícia usada;
  - `Missao`: `testemunhas_vistas` e `_sumir_testemunha`.
- **Tela:**
  - `CloseupPista` (novo);
  - `Investigacao._mostrar_pista`: a câmera e os rótulos.

## Testes

Total: **609**. Arquivo novo `test_testemunhas.gd`:
- **Testemunhas:**
  - ganham nome, aparência e jeito, iguais no online, sem mudar os dados;
  - o depoimento começa por quem fala.
- **Close-up:**
  - os detalhes trazem a lente e o sentido, com a assinatura da Morte;
  - o bilhete mostra o achado.
- **Sumiço:**
  - uma testemunha some à noite e a Membrana cai 2;
  - com o caso fechado, ninguém some;
  - as testemunhas vão no save.
