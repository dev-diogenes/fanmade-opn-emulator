# ADR 0001: Engine Godot 4 com GDScript

- **Status:** Aceito
- **Data:** 14/10/2026

## Contexto

Precisamos de uma engine para um jogo **3D low poly** no PC (Steam), talvez portado para celular depois. O time é um desenvolvedor de experiência média, com fãs ajudando aos poucos. O projeto é gratuito e open source.

Surgiu a dúvida se alguma parte precisaria ser em Unity, porque os projetos tabletop do universo OP costumam usar o Tabletop Simulator.

## Opções

| | Godot 4 | Unity | Web (Three.js) |
|---|---|---|---|
| Custo e licença | MIT, sem royalties | Proprietária, com termos que mudam | Livre |
| Projeto aberto no GitHub | Leve, com cenas em texto (`.tscn`) e diffs legíveis | Projeto pesado, YAML ruidoso | Ótimo |
| 3D low poly | Suficiente | Excelente | Bom, mas sem editor |
| Curva para quem já criou coisas simples | GDScript é simples | C# é mais verboso | Exige montar a stack |
| Steam e celular | Exporta para os dois | Exporta para os dois | Precisa de wrapper |
| Facilidade para fãs contribuírem | Editor pequeno e gratuito | Download pesado e conta obrigatória | Média |

## Decisão

Usar **Godot 4.x estável**, com **GDScript**. Os testes usam o **GUT** (Godot Unit Test).

- O Tabletop Simulator **não influencia a escolha**: não reaproveitaríamos código Lua nem assets de lá, por licença e por técnica.
- As regras ficam isoladas em `game/scripts/rules/`, sem depender de nós de cena. Assim dá para testar e, se um dia precisar, portar.

## Consequências

- O 3D do Godot é menos maduro que o do Unity, mas atende ao estilo low poly do FTK.
- C# continua possível em módulos que precisem de desempenho, mas não é o padrão.
- O pipeline de assets é Blender → `.glb` → Godot, com os assets no **Git LFS**.
