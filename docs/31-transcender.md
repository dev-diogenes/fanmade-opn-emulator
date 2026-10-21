# Transcender: subir de NEX como ritual

> Status: **v0.1**, 21/10/2026. Pedido: o aumento de NEX deve ser parecido com a cena de investigação. Cada personagem entra numa sala e anda com WASD; no meio da sala há só um sigilo. A referência foi uma ilustração da Agata ajoelhada no círculo de runas, na sala dela.

## A cena

Quando um agente tem escolhas de NEX pendentes, o bilhete da Base ganha o botão **"✦ Transcender na sala de <nome>"**. Ele abre a cena por cima da Base (`Transcender`).

1. **A sala do agente** (`SalaTranscender`):
   - quarto fechado de paredes vermelho-escuras e chão de tábuas;
   - estante com livros e um livro aberto num atril, com luz roxa;
   - mesa com um crânio e uma vela, gaiola pendurada e ervas secas no teto;
   - uma lâmpada fraca perto da porta;
   - no meio do chão, o **sigilo**: o sigilo procedural da Ordem, dois anéis com runas entre eles e cinco velas em volta. Tudo pulsa devagar em dourado.
2. **O agente entra pela porta e anda com WASD** (ou as setas), relativo à câmera, como na investigação. O botão **"Ir ao sigilo"** (ou Enter) leva o agente sozinho, para quem não quer ou não pode usar o teclado.
3. **Pisou no sigilo:**
   - o agente vai ao centro e **ajoelha** (animação de sentar no chão da KayKit);
   - o círculo cresce e acende;
   - a luz da sala esquenta, a fita treme (pulso VHS) e toca o som de ritual;
   - a câmera chega perto e põe o agente à esquerda.
4. **As escolhas do novo NEX** aparecem num papel à direita ("NEX 10% — o que o Outro Lado deixou"). São as **mesmas escolhas da Base** (trilha, poder, atributo, ritual…), feitas pelo mesmo código (`BaseOrdem._montar_pendencia`, agora com a caixa como parâmetro). Cada escolha aplicada dá um pulso e um som.
5. **Feitas todas**, "Levantar e voltar à Base": o agente se levanta, o círculo apaga, e a cena fecha. Esc sai a qualquer momento: as escolhas continuam pendentes na Base.

| Entrada | Ritual |
|---|---|
| ![Entrada](transcender31_entrada.png) | ![Ritual](transcender31_ritual.png) |

**Desempenho:** a sala respeita a qualidade gráfica (docs/24). As velas e a luz do livro são luzes de clima, e a sombra da lâmpada sai no nível baixo.

## Correção: a suíte de testes sobrescrevia o save real

Investigando um teste que afetava outro, descobri que **rodar a suíte podia regravar o save do jogador** (`user://carreira.json`).

- **Causa:** o `Jogo` salva sempre que uma tela chama `salvar()`, e um teste antigo (`test_cena_da_base_abre`) terminava religando o salvamento automático.
- **O que se perdeu:** o save desta máquina, que às 10:53 tinha uma missão em andamento, foi substituído por uma carreira de teste às 11:00. Não há cópia anterior.
- **Correção:** quando o Godot roda o GUT, o `Jogo` passa a salvar a carreira em `user://teste_carreira.json` e as preferências em `user://teste_preferencias.json`. O caminho do save virou `Carreira.arquivo_padrao` e as funções usam ele quando não recebem um caminho.
- **Conferido:** depois da correção, uma rodada inteira da suíte não alterou mais o `carreira.json` real.

## Testes

O `tests/unit/test_transcender.gd` tem 2 testes, com uma Base falsa para não depender da carreira global:

- **Sala:** andar para o centro chega ao sigilo, e o agente não atravessa as paredes.
- **Ritual:** começa, o papel das escolhas aparece depois de ajoelhar, usa as escolhas da Base e, feitas todas, oferece "Levantar e voltar à Base".

Total: **504 testes**.

## Pendências

- **A pose:** é a de sentar no chão da KayKit (o pacote não tem uma de ajoelhar).
- **A sala:** é a mesma para todos os agentes. Variar por classe ou origem (um laboratório para o Acadêmico, uma oficina para o Engenheiro) daria mais personalidade.
- **A cerimônia de NEX** (docs/23) continua como relatório. Um próximo passo é levar dela direto à sala de quem subiu.
