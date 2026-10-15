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

### Base da Ordem (cena principal)

Ao apertar **Play (F5)**, abre a Base da Ordem, o hub da carreira:

- **Agentes:** roster persistente (começa com Mauro, Bianca e Rita; dá para recrutar mais até 8). Clique num agente para ver a ficha.
- **Escolhas de NEX:** quando um agente sobe de NEX, a ficha mostra o que escolher (trilha, poder, aumento de atributo, grau de treinamento).
- **Requisição:** marque armas, proteção e itens dentro do limite da patente (Recruta: 2 itens de categoria I) e da carga.
- **Missão:** escolha até 4 agentes e as opções da run (modo Normal com 2 Reforços da Ordem, ou Hardcore). Ao voltar, o relatório mostra PP, NEX e promoções.
- O jogo salva sozinho em `user://carreira.json` (no Windows: `%APPDATA%\Godot\app_userdata\Ordem Paranormal- Fanmade (WIP)`).

![Base da Ordem](docs/base_ordem.png)

### Missão no mapa

Uma missão acontece num mapa hexagonal em 3D low poly, gerado por seed. Câmera: **roda** = zoom, **botão direito** arrastando = girar, **botão do meio** ou **WASD/setas** = deslizar, **Q/E** = girar.

- Na vez de cada agente, **Rolar movimento**: 1 d20 por ponto de Agilidade (+1 por PE de Foco); cada resultado 11+ vale 1 passo, além do passo base.
- Clique num hex azul para andar. **?** são eventos (um teste de perícia), **!** são encontros (vão para o combate tático), **V** são vilas onde dá para **Descansar**, e **X** é o covil: vencê-lo cumpre a missão.
- Depois que todos jogam, o mundo age: a Membrana enfraquece e, conforme o estado dela, surgem ameaças perto do grupo.

![Mapa da missão](docs/mapa_mundo.png)

### Rituais

Ocultistas (Rita, Cecília) conhecem 3 rituais de 1º círculo e aprendem mais a cada NEX. Na arena, escolha o ritual no seletor e clique em **Conjurar**; rituais pessoais saem na hora, os outros pedem o alvo. Cada conjuração gasta PE pelo círculo, exige componentes ritualísticos do elemento (requisitados na Base), cobra o **Custo do Paranormal** (teste de Ocultismo; falhar custa Sanidade) e enfraquece a Membrana. Criaturas do elemento oprimido resistem pior (Morte contra Sangue, por exemplo).

### Poderes paranormais e itens amaldiçoados

Quem escolhe **Transcender** ao subir de NEX recebe um poder paranormal (Precognição, Sangue de Ferro, Golpe de Sorte…), mas não ganha a Sanidade daquele NEX. Em NEX 50% o agente escolhe uma **afinidade elemental**: pode pegar de novo um poder do elemento, para um efeito maior, e conjura rituais dele sem componentes. A partir de **Agente Especial** (50 PP), a Base libera os itens amaldiçoados (☠ no catálogo). Eles são fortes, mas cada falha num teste do atributo ligado ao elemento custa Sanidade.

### Investigação

Os hexes com o **anel verde-água** são cenas de investigação. Ao entrar, o grupo (agentes a até 2 hexes) vai para uma cena 3D escura, com a luz curta:

- Na vez de cada agente: **Procurar pistas** num ponto de interesse (clique no objeto; cada ponto aceita perícias com DTs diferentes), **Facilitar** (sucesso dá +2 aos aliados e ilumina a cena), **Ajudar** um aliado ou usar habilidades (Faro para Pistas, Perito, Eclético, Incansável…).
- A **urgência** limita as rodadas; a cada 3 falhas ao procurar, perde-se uma. Se o tempo acabar, há uma penalidade.
- As pistas respondem às perguntas da **ficha do caso**: descobrir *onde* revela o covil; *quem*, enfraquece o chefe; *o que*, fortalece a Membrana. Cada pista vale +2 PP no relatório.

![Investigação](docs/investigacao.png)

### Arena de Teste (combate tático)

Os encontros do mapa abrem o combate tático em 3D, com o grupo e as ameaças do encontro (mesmos controles de câmera). Abrindo `scenes/arena_teste.tscn` direto (F6), roda um combate de demonstração: 3 agentes (Mauro, Bianca e Rita) contra cultistas, um atirador e uma aberração.

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
