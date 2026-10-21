# Pendências e conteúdo novo

> Status: **v0.1**, 21/10/2026. Passos 3 e 4 do pedido "2, 3, 4 pode seguir": as pendências registradas nos docs 25 a 31 e mais conteúdo (casos, cenas e eventos), já no formato de dedução por indícios (docs/32, ADR 0010).

## Pendências resolvidas

| Pendência (doc) | O que mudou |
|---|---|
| **Teste intermitente** `test_investigacao_age_por_comandos` (30) | O teste lia o tamanho absoluto do registro da sessão. Se um teste anterior deixasse uma investigação pendente no `Jogo`, a tela usava a sessão dele, que já trazia comandos. Agora o teste compara com o tamanho antes da ação |
| **Recrutas prontos sem descrição** (26, 27) | Os 6 recrutas de `recrutas.json` têm conceito, idade, personalidade, histórico e objetivo, escritos para o jogo. `Carreira.recrutar` copia a descrição. Num save antigo, o recruta sem descrição recebe a dele ao carregar, se a classe e a origem ainda batem |
| **A sala de Transcender é igual para todos** (31) | Uma sala por classe, com o mesmo sigilo e as velas no meio (tabela abaixo) |
| **A cerimônia de NEX não leva à sala** (31) | O cartão de quem tem escolhas novas ganha **✦ Transcender agora**, que fecha o relatório e abre a sala do agente |

| Classe | Sala | Luz |
|---|---|---|
| Ocultista | A da referência: estante, atril com livro, crânio, gaiola e ervas | Vermelha |
| Combatente | Porão de treino: saco de pancada, suporte de armas, mesa com munição e um alvo de papel | Lâmpada laranja |
| Especialista | Escritório: computador aceso, arquivo de aço, caixas de processo e um quadro de cortiça com fios | Fluorescente fria |

| Combatente | Especialista |
|---|---|
| ![Sala do combatente](sala33_combatente.png) | ![Sala do especialista](sala33_especialista.png) |

**Ficam para depois:**
- **IPv6 na sala online** (29);
- **repetir o Treinamento em Perícia** na criação (28);
- a **pose de ajoelhar**: a KayKit não tem uma.

## Conteúdo novo

### Casos
O gerador passa de 80 para **210 combinações**. A regra da tabela continua valendo (dois candidatos dividem no máximo um traço), e o teste confere.

| Pergunta | Novos candidatos | Traços |
|---|---|---|
| Quem | o delegado da cidade | treino de campo · nome de família · **autoridade** |
| Quem | uma professora aposentada | idade avançada · autoridade · **perto de crianças** |
| O quê | quer escapar da morte a qualquer preço | sangue coletado · cativeiro · **não envelhece** |
| Onde | a escola rural fechada | longe da cidade · azulejo · **pó de giz** |
| Onde | o cemitério municipal | perto do centro · terra arada · **flores de velório** |

### Cenas de investigação
Duas cenas novas, cada uma com pontos para as três perguntas e pistas que trazem `{indicio}`:

- **Escola rural fechada** (campo, estrada): quadro-negro, diário de classe, cantina e a merendeira do bairro.
- **Posto de beira de estrada** (estrada, campo, cidade): câmera de segurança, caixa registradora, um caminhoneiro no pátio e o banheiro dos fundos.

Peças 3D novas:
- o quadro-negro ganha uma **lousa** num cavalete;
- a merendeira e o caminhoneiro são **pessoas**;
- o banheiro vira **alçapão** (o ralo);
- a cantina e o caixa são **mesas**.

![Posto de beira de estrada](cont33_posto.png)

### Eventos que dão pista
- **Novo efeito `pista`:** o evento revela um traço do caso, na pergunta pedida ou na pergunta aberta com menos pistas. O bilhete de desfecho mostra "Pista: idade avançada" num selo dourado.
- **Quatro eventos novos:** cada um tem opções que rendem pista, outras que só protegem o agente, e a de seguir em frente.
  - **Orelhão tocando:** atender, rastrear a ligação, arrancar o fone.
  - **Procissão sem rosto:** seguir de longe, rezar junto, observar quem vai na frente.
  - **O cachorro que não late:** seguir o olhar dele, examinar a coleira, espantar.
  - **Jornal de amanhã:** ler a manchete, analisar a tinta, queimar.
- **No carro abandonado,** mexer no painel agora também dá uma pista de onde.

A ficha de suspeitos acomoda os 7 suspeitos em três linhas:

![Ficha com 7 suspeitos](cont33_ficha.png)

## Testes

Total: **515** (eram 511).
- **Recrutas:** os prontos têm descrição, e o save antigo a recebe ao carregar.
- **Sala de Transcender:** uma por classe, com o sigilo em todas.
- **Cerimônia:** o atalho "Transcender agora".
- **Cenas:** toda cena responde quem, o quê e onde, e toda pista traz indício.
- **Eventos:** o efeito `pista` revela um traço do culpado verdadeiro.
- **Peças:** lousa e pessoa nas cenas novas.
