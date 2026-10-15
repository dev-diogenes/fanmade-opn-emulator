# Ordem Paranormal: Fanmade RPG (WIP)

RPG eletrônico **fanmade e gratuito** ambientado em *Ordem Paranormal*, com o estilo de jogo de *For The King* / *For The King II*: mapa hexagonal 3D low poly, grupo de até 4 agentes, combate por turnos em grade e testes de d20 mostrados como slots.

> ⚠️ Projeto **não oficial**, sem afiliação com Cellbit ou Jambô. *Ordem Paranormal* pertence aos seus detentores. Veja [docs/03-legal-e-conteudo.md](docs/03-legal-e-conteudo.md).

## Versões

| | Regras | Foco |
|---|---|---|
| **Versão I** | Livro básico de 2022 | Combate |
| **Versão II** | Regras novas | Investigação |

As duas usam o mesmo motor, com rulesets diferentes ([ADR 0002](docs/adr/0002-regras-como-dados.md)).

## Modos

- **Sandbox:** escolha seus agentes e jogue missões geradas proceduralmente.
- **Campanha:** história original.
- **Comunidade:** missões criadas por jogadores, com ou sem mestre.

## Estrutura

```
docs/                 Visão, brainstorm, roadmap, ADRs
game/                 Projeto Godot 4 (abra esta pasta no editor)
  scripts/rules/      Motor de regras (sem dependência de cena)
  scripts/core/       Mapa, turnos, save, rede
  scripts/ui/         Interface
  data/rulesets/      Regras em dados (op2022, op-v2…)
  data/missions/      Missões: procedural, campanha, comunidade
  assets/             Modelos, texturas, áudio (Git LFS)
  tests/              Testes automatizados (GUT)
tools/                Scripts auxiliares
reference/            Material pago LOCAL, ignorado pelo Git
```

## Como rodar

1. Instale o [Godot 4.x](https://godotengine.org/download) (versão estável, padrão, não a .NET).
2. Instale o [Git LFS](https://git-lfs.com) e rode `git lfs install`.
3. Clone o repositório e abra `game/project.godot` no Godot.

### Arena de Teste (primeira cena jogável)

Ao apertar **Play (F5)**, abre a Arena de Teste: 3 agentes (Mauro, Bianca e Rita) contra cultistas, um atirador e uma aberração, numa grade tática 2D provisória.

- Clique num ser para ver a ficha.
- **Mover**: clique numa célula azul. **Atacar**: clique num inimigo destacado em vermelho.
- **Foco**: PE gastos para somar +1 d20 ao ataque. **Ataque Especial**: só para combatentes.
- O painel mostra os slots de d20 do último teste e a Membrana, que cai a cada rodada.

![Arena de Teste](docs/arena_teste.png)

### Testes

Os testes usam o [GUT](https://github.com/bitwes/Gut) 9.6.1, que já vem em `game/addons/gut`. Para rodar:

- **No editor:** abra a aba **GUT** no painel inferior e clique em *Run All*.
- **No terminal:**

```bash
GODOT=/caminho/para/Godot_v4.6.1-stable_win64_console.exe tools/rodar_testes.sh
```

## Documentação

- [Visão e Spec](docs/00-visao-e-spec.md)
- [Brainstorm de Design](docs/01-brainstorm-design.md)
- [Roadmap](docs/02-roadmap.md)
- [Legal e Conteúdo](docs/03-legal-e-conteudo.md)
- [Decisões de arquitetura (ADRs)](docs/adr/)

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Idiomas

Português (BR). Outros idiomas, quando aparecerem, ficam marcados como **WIP**.
