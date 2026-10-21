# Sala online por código e saguão animado

> Status: **v0.1**, 21/10/2026. Implementa o **C8** da [crítica 20](20-critica-pos-acessibilidade.md) e fecha os achados da [crítica 15](15-critica-acessibilidade-engajamento.md) sobre os termos de rede (7777, 127.0.0.1) e o saguão vazio.

## Código da sala

**Antes:** quem hospedava via "porta 7777" e uma lista de IPs. Quem entrava digitava "127.0.0.1" e a porta.

**Agora**, na aba Jogadores:

- **Criar sala:**
  - abre a sala e mostra um **código de 10 símbolos** (ex.: `R2M04-VRYC4`) para cada rede da máquina;
  - cada código tem o nome da rede ("rede local (Wi-Fi ou cabo)", "Radmin VPN", "Tailscale ou ZeroTier"…), com a rede local primeiro;
  - o botão **Copiar** confirma com "Copiado ✓";
  - um aviso diz onde o código vale. "Fechar a sala" encerra.
- **Entrar na sala:** um campo para o código, outro para o nome, e o botão.
  - **Tolerância a erros de digitação:** aceita minúsculas, espaço no lugar do hífen e as trocas O→0, I/L→1, U→V.
  - **Código com erro:** mostra "Código não reconhecido…" antes de tentar conectar.
- **Avançado** (uma caixa, fechada por padrão):
  - a porta usada ao criar a sala;
  - no lugar do código, o campo também aceita "IP" ou "IP:porta".

### Como o código funciona (`CodigoSala`)

- **Conteúdo:** o código guarda o **IPv4 (4 bytes) e a porta (2 bytes)**, mais **2 bits de conferência**. São 50 bits, escritos em **base 32 de Crockford**: 10 símbolos sem I, L, O e U.
- **Erro de digitação:** trocar um símbolo nunca leva a outra sala por engano. A conferência ou a decodificação recusam o código (há um teste que troca cada posição).
- **Limite honesto:** **não há servidor de salas**. O código é só o endereço, mais fácil de ditar. Quem entra precisa alcançar o host:
  - na mesma rede;
  - numa VPN de jogos (ZeroTier, Radmin, Tailscale, Hamachi);
  - ou pela internet, com a porta aberta no roteador.

  A tela diz isso. Um serviço de salas pela internet (relay, NAT punch) seria outro projeto, com servidor próprio.

| Sem sala | Sala aberta |
|---|---|
| ![Jogadores](sala29_fechada.png) | ![Sala aberta](sala29_host.png) |

## Saguão animado

**Antes:** uma folha de papel vazia com "Conectando a 127.0.0.1:7777…". Parecia travado.

**Agora**, enquanto espera, o saguão mostra:

- o **código da sala**;
- "Conectando à sala…", sem o IP;
- uma linha de **escuta**: "● REC 00:09" e "Procurando a sala…", com pontos que andam. Depois de conectar, a linha vira "Aguardando o host abrir a operação…".
- **depois de 8 s sem conectar**, o que conferir: o código, se a sala está aberta e se os jogadores estão na mesma rede ou VPN;
- no papel, o que vai aparecer ali (jogadores, agentes, de quem é cada um), em vez da folha vazia;
- ao fundo, o sigilo, que gira e pulsa devagar. Ele não pisca, para respeitar o modo suave de flashes.

![Saguão](sala29_saguao.png)

## Verificação

- **Teste online de ponta a ponta** (`tools/teste_online.sh`): o robô cliente agora **entra pelo código da sala** (`FW000-0B2SX`), como um jogador faria. A missão inteira terminou com o mesmo estado no host e no cliente (hash 1736821944, 0 dessincronias).
- **Testes unitários** (`tests/unit/test_sala.gd`, 6 testes):
  - o código vai e volta em cinco endereços;
  - tolera minúsculas, espaço e as trocas O/0 e L/1;
  - recusa um símbolo trocado em todas as posições;
  - aceita o atalho por IP;
  - o texto da espera muda com o tempo e a conexão;
  - a rede local fica primeiro.

  Total: **500 testes**.

## Pendências

- **IPv6:** não é suportado. O código só guarda IPv4, e o jogo já listava só os endereços IPv4.
- **Rotulagem das redes:** é por faixa de endereço. "10.x" pode ser rede local ou VPN, e a tela diz as duas coisas.
