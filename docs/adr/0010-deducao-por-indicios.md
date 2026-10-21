# ADR 0010: dedução por indícios no caso

- **Status:** aceito, 21/10/2026
- **Contexto:** docs/32 (crítica de envolvimento e investigação)

## Contexto

O caso sorteia um sujeito, uma ação e um local. Até aqui:

- a pista dizia a resposta no próprio texto ("{sujeito}", "{local}");
- a 2ª pista de uma pergunta a resolvia sozinha (`Caso.registrar_pista` marcava `respondida`).

O jogador nunca raciocinava sobre o caso: a investigação era só uma sequência de testes.

## Decisão

- **Traços nos dados.** Cada candidato de `casos.json` (sujeitos, ações, locais) ganha 3 `indicios`. Os textos ficam em `casos.indicios` (rótulo curto e frase de observação).
- **Regra da tabela:** dois candidatos da mesma pergunta dividem **no máximo um** traço. Assim, duas pistas diferentes sempre deixam um só candidato. Um teste verifica a regra nos dados.
- **A pista revela um traço.** O texto do ponto usa `{indicio}`. A ordem dos traços do culpado verdadeiro é embaralhada por pergunta com uma semente tirada do próprio caso, não dos `Dados` da missão. Assim ela sai igual nas duas máquinas do online e não gasta rolagens.
- **A pergunta só se resolve por acusação:** `Caso.deduzir(pergunta, candidato)`, com ao menos uma pista.
  - **Errar:** custa Membrana (`casos.penalidade_palpite`) e risca o candidato.
  - **Acertar:** aplica o efeito da pergunta.
- **Acusar é um comando de lockstep (`deduzir`)** nos dois contextos:
  - **Na cena de investigação:** o efeito vai no resultado da cena, como antes. Acusar não gasta a vez.
  - **No mapa:** o efeito vale na hora (`Missao._aplicar_efeito_pergunta`).
- **Interface:** `PainelDeducao`, a ficha de suspeitos. Abre pelo botão "Deduzir" dos bilhetes do quadro e do painel do caso no mapa. Os traços achados acendem com ✔ e cor; a carta do suspeito **não** acende sozinha: cruzar os traços é a parte do jogador.
- **Compatibilidade:** um save antigo sem traços nem ordem é completado ao carregar (`Caso.de_dicionario`). As pistas `{sujeito}`/`{acao}`/`{local}` de missões da comunidade continuam funcionando.

## Consequências

- **Bom:**
  - o jogador decide e arrisca;
  - acusar cedo, com 1 pista, é uma aposta (às vezes certa: alguns traços só um candidato tem);
  - o quadro de cortiça vira mesa de trabalho.
- **Custo:**
  - cada caso novo precisa respeitar a regra da tabela;
  - o conteúdo de pistas fica um pouco mais genérico (o lugar onde se acha + o traço).
- **Próximo:** pistas duvidosas (um traço falso marcado com "?") e depoimentos que se contradizem (docs/32, Mistério).
