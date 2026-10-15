# ADR 0003: Peças low poly geradas por código na fatia vertical

- **Status:** Aceito
- **Data:** 15/10/2026

## Contexto

A Fase 2.4 leva o mapa-múndi e o combate tático para 3D low poly, no estilo For The King. O pipeline previsto no ADR 0001 é Blender → `.glb` → Godot, com Git LFS. Isso exige modelar cada peça (tiles, árvores, casas, figuras, criaturas) antes de qualquer coisa aparecer na tela.

## Decisão

Na fatia vertical, as peças são **geradas por código** a partir das malhas primitivas do Godot, em `scripts/ui/visual/pecas.gd`:

- tiles do mapa como prismas hexagonais (`CylinderMesh` com 6 lados);
- árvores (cones), casas (caixa e prisma), rochas, pilares, capim, caixotes e paredes;
- figuras dos agentes (peões) e criaturas angulosas;
- anéis de destaque, marcadores e rótulos.

A apresentação fica separada da lógica:

- `Mapa3D` e `Tabuleiro3D` só desenham o estado de `Missao` e `Combate`/`Grade`;
- `CameraRig` cuida da câmera (zoom, giro, deslize e o "raio até o chão" do clique).

## Consequências

- O 3D funciona sem nenhum asset externo, roda nos testes headless e não pesa no Git LFS.
- O visual é simples, mas coerente com o low poly. Cada função de `Pecas` pode ser trocada por um `.glb` do Blender sem mexer no resto: quem chama recebe um `Node3D`.
- A seleção por clique não usa física: o raio da câmera cruza o plano do chão e a posição é convertida em hex ou quadrado. É mais simples e determinístico.
