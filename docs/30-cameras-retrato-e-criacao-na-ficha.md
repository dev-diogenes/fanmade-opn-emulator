# Câmeras próximas, retrato da vez e criação na própria ficha

> Status: **v0.1**, 21/10/2026. Pedidos do playtest: ajustar a 2ª e a 1ª pessoa, aumentar o retrato do agente da vez e criar o agente no formato da ficha (página Agente).

## Câmeras

| Modo | Antes | Agora |
|---|---|---|
| **2ª pessoa** | Na frente do agente, olhando para ele. No mapa, ficava acima da cabeça (a altura dos olhos era a da 1ª pessoa antiga, 2,3) | **Por cima do ombro:** atrás do agente, um pouco acima e de lado, olhando adiante dele. A distância acompanha a roda do mouse |
| **1ª pessoa** | No mapa, o olho ficava a 2,3 de altura e recuado, e a visão parecia vir do hex da frente | **Nos olhos:** na altura medida da miniatura e logo à frente do rosto, **virada para onde o agente olha** |

**Altura dos olhos:** medida nos modelos, fica em torno de 0,66 da escala da figura.

| Cena | Escala da figura | Olhos |
|---|---|---|
| Mapa | 0,75 | 0,5 |
| Investigação | 0,9 | 0,6 |
| Combate | 1,0 | 0,66 |

**Para onde a câmera olha:**
- A câmera vira para a frente da figura ao trocar de agente ou de modo, e quando a figura se vira ao andar no mapa. Entre os passos, o botão direito continua girando a visão.
- Na investigação, o WASD anda em relação à câmera; se ela acompanhasse cada virada, giraria sem parar ao andar de lado. Lá ela só se alinha ao trocar de agente ou de modo.
- No mapa, as peças nascem viradas para o centro do território. Assim, a 1ª pessoa começa vendo o mapa, não a borda.

**O que some nos modos próximos:**
- **Nos dois modos:** o marco flutuante do próprio hex (estrela, "?"), o anel da vez e os companheiros do mesmo hex.
- **Na 2ª pessoa:** também o nome do próprio agente.
- **Na 1ª pessoa:** também as casas e árvores do hex onde o agente está.

| 1ª pessoa | 2ª pessoa |
|---|---|
| ![1ª pessoa](cam30_primeira.png) | ![2ª pessoa](cam30_segunda.png) |

## Retrato da vez

O retrato do agente da vez (canto inferior esquerdo) **cresce**:
- a largura passa de 176 para 222, com animação;
- o nome vai para 20 px;
- as barras ficam mais altas e os números maiores;
- ganha um brilho dourado.

Quando a vez passa, ele volta ao tamanho normal. Antes, a mudança era só uma escala de 4%, quase invisível.

## Criação na própria ficha

A criação agora **é a ficha**, com as mesmas três páginas da ficha do jogo, editáveis. Os blocos levam os números do passo a passo do livro (p.23).

### Agente
- **① Conceito:**
  - Personagem e Conceito em campos com o rótulo preto da ficha;
  - Idade com o botão 2d6+15 e a regra opcional de idade variada (faixa e desvantagens logo abaixo).
- **② Atributos:**
  - o pentágono da ficha, com + e − ao lado de cada círculo;
  - "Pontos: x de 4 · máximo 3 · um em 0 dá +1".
- **③ Origem:** uma lista com as 26 origens. A dica de cada uma traz as perícias e o poder, e o poder escolhido aparece logo abaixo. Criança e adolescente escolhem ali os benefícios.
- **④ Classe:** uma lista, com "PV 16 + VIG · PE 3 + PRE · SAN 16". A trilha aparece em outra lista quando o NEX inicial é 10% ou mais.
- **Ao vivo:** NEX, PE/rodada e deslocamento; as caixas de PV, PE e SAN; a conta da Defesa e dos pontos (p.46); os ataques com a arma do kit.
- **⑤ Perícias:** a tabela da ficha, com Dados, Treino, Fonte e Perito.
  - As da origem e da classe vêm marcadas e travadas (a dica diz de onde vêm).
  - As livres e as escolhas (Luta ou Pontaria; origem com escolha) se marcam clicando.
  - No topo: "livres: 10/10 (classe + INT) · Perito: 2/2".

### Habilidades e inventário
- as habilidades;
- os poderes de classe da idade variada, com as escolhas extras (docs/28);
- a **Descrição**, com a foto 3x4 e os botões de modelo e tom, gênero, aparência, personalidade, histórico e objetivo;
- os pontos de prestígio, a patente e o **inventário inicial** da classe.

### Rituais
A escolha dos rituais do ocultista.

### Outros detalhes
- A antiga página Revisão saiu: a ficha se calcula enquanto é preenchida, e o rodapé diz o que falta.
- A coluna lateral da foto também saiu: a foto foi para a descrição, como na ficha, e a pasta ficou mais larga (1180).

| Agente | Habilidades e inventário |
|---|---|
| ![Agente](criacao30_p1.png) | ![Habilidades](criacao30_p2.png) |

## Testes

Total: **502 testes**.
- **Câmeras:** a 1ª pessoa olha para onde a figura olha, na altura dos olhos e logo à frente do rosto; a 2ª fica atrás e acima.
- **Retrato:** cresce na vez e volta.
- **Criação:** as páginas da ficha; o + do pentágono; marcar e desmarcar perícias livres; as perícias da origem travadas.
- **Ajustados:** os testes que usavam as abas antigas da criação.

## Pendências

- **Teste intermitente:** o `test_investigacao_age_por_comandos` falhou uma vez numa rodada e passou na seguinte, sem mudança de código. A causa ainda não foi achada.
- **Tabela de perícias:** é longa e rola dentro da página, com uma linha por perícia, como na ficha.
