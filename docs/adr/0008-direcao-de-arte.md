# ADR 0008: Direção de arte e pipeline de assets

- **Status:** Aceito
- **Data:** 20/10/2026

## Contexto

O ADR 0003 deixou o 3D funcionando só com primitivas do Godot. Já a interface usa o tema padrão do Godot, com cores soltas em cada tela. O resultado é "quadrado": não lembra o For The King 2, que é a referência visual do projeto.

O FTK2 tem uma linguagem visual clara:
- um diorama de mesa: hexágonos chanfrados com relevo, decoração densa e figuras que parecem peças de tabuleiro;
- low poly com cores chapadas e uma textura-paleta (atlas de cores), sem texturas realistas;
- luz quente com sombras suaves, névoa e um leve desfoque nas bordas (efeito maquete);
- interface em painéis ornamentados sobre o 3D, com tipografia de fantasia.

## Decisão

1. **Assets de terceiros CC0 como base.** Usamos os pacotes da KayKit (Kay Lousberg), CC0:
   - *Medieval Hexagon Pack*: tiles hexagonais e a natureza que os decora;
   - *Character Pack: Adventurers*: figuras dos agentes.

   Copiamos para `game/assets/models/` **só os `.gltf`/`.bin`/`.png` que o jogo usa**, nunca o pacote inteiro. Cada arquivo entra no `game/assets/CREDITS.md`. Os binários vão para o Git LFS (ver `.gitattributes`).
2. **Fallback por código.** `Pecas` tenta carregar o modelo do catálogo (`Catalogo`). Se o arquivo não existir (clone sem LFS, testes headless), cai na primitiva atual. O ADR 0003 continua valendo como plano B.
3. **Assets próprios de Ordem Paranormal** (sigilos, criaturas, a Base) são feitos no Blender com a mesma paleta, exportados em `.glb`.
4. **Ambiente padronizado.** `Pecas.ambiente` aplica:
   - luz direcional quente com sombras suaves;
   - céu em gradiente;
   - névoa de profundidade;
   - SSAO e glow;
   - tonemap ACES;
   - profundidade de campo leve nas bordas.
5. **Tema único da interface.** `Tema.criar()` monta um `Theme` em código, aplicado na janela raiz pelo autoload `Jogo`. Ele vale para todas as telas, que deixam de definir cores soltas.

   Paleta de Ordem Paranormal:
   - fundo quase preto azulado;
   - painéis em pedra escura, com borda dourada envelhecida;
   - vermelho-sangue para o perigo e o Outro Lado;
   - texto em pergaminho.

   As fontes, se forem adotadas, são OFL (Google Fonts) e também entram no `CREDITS.md`.

## Consequências

- O jogo continua rodando e testando sem nenhum asset, graças ao fallback.
- Trocar um asset é mudar uma linha no `Catalogo`.
- O pacote KayKit é medieval. Peças que destoam do horror contemporâneo de OP (castelos, catapultas) ficam de fora. A ambientação de OP virá de recolorir e de modelar no Blender.
- O LFS do GitHub tem cota gratuita de 1 GB. Os modelos low poly da KayKit somam poucos MB, então não preocupam.
