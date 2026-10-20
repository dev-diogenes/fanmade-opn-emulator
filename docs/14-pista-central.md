# Pista central (inspirada no GUMSHOE)

> Status: **v0.1**, 20/10/2026. É **design do jogo**, não regra do livro. Saiu da proposta do [13-ajustes-de-playtest.md](13-ajustes-de-playtest.md), aprovada pelo autor.

## Ideia

Ordem Paranormal nasceu inspirado no sistema GUMSHOE (*The Esoterrorists*). A regra de ouro do GUMSHOE é que **a investigação não trava por um dado ruim**: quem tem a habilidade certa e está no lugar certo encontra a pista. Os dados ficam para o perigo e para o tempo.

## Regra

| Situação | O que acontece |
|---|---|
| O agente tem **treino** numa perícia do ponto e está **perto** dele (WASD) | Pode **Examinar**: encontra a pista do ponto **sem teste** |
| A perícia tem DT 15 (simples) | Examinar é **de graça** |
| A perícia tem DT 20 ou 25 (complexa, muito complexa) | Examinar custa **1 PE a cada 5 de DT acima de 15** (1 PE na DT 20, 2 PE na DT 25), como os pontos de habilidade do GUMSHOE |
| O agente **não tem treino** em nenhuma perícia do ponto | Só **Procurar**, com teste, como antes. Falhas ainda custam rodadas |
| Em qualquer caso | Examinar **gasta a ação** do agente e tira o ponto da cena. A urgência continua apertando |

O que **não muda**:
- Facilitar, Ajudar, as habilidades (Faro para Pistas, Perito, Eclético, Na Trilha Certa), a urgência e o Medo continuam com os testes de sempre.
- A pista examinada conta para a ficha do caso como qualquer outra (as perguntas, o PP).

## Implementação

- **Regra:** `CenaInvestigacao.custo_examinar`, `melhor_pericia_para_examinar` e `examinar`.
- **Comando online:** `examinar` (lockstep).
- **Tela:** o bilhete de Procurar mostra primeiro os botões **✦ Examinar com <perícia> — pista garantida (n PE)**, depois "Ou procurar com teste". A rolagem central mostra "Pista central · <atributo> — Sem dados: o treino basta". A foto vai para o quadro.
- **Tutorial:** o passo "Procurar pistas" explica o Examinar.
- **Testes:** em `test_investigacao.gd`: sem treino não pode; DT maior custa PE; DT simples é de graça.

![Examinar](examinar_14.png)
![Pista central](pista_central_14.png)
