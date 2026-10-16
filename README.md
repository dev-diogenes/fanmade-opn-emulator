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
- **Campanha:** *O Fundo da Represa*, história original em 4 missões.
- **Comunidade:** missões criadas por jogadores, com ou sem mestre.
- **Online:** até 4 jogadores, cada um no seu computador ([como jogar](docs/06-online.md)).

## Estrutura

```
docs/                 Visão, brainstorm, roadmap, ADRs
game/                 Projeto Godot 4 (abra esta pasta no editor)
  scripts/rules/      Motor de regras (sem dependência de cena)
  scripts/core/       Mapa, turnos, save, rede
  scripts/ui/         Interface
  data/rulesets/      Regras em dados (op2022, op-v2…)
  data/missoes/       Missões da comunidade que vêm com o jogo
  data/campanhas/     Campanhas (uma pasta por campanha)
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

### Rituais de área e o Medo

No seletor da arena, cada ritual aparece também nas formas **discente** e **verdadeira** que o NEX permite (a verdadeira costuma exigir afinidade). Rituais de área pedem um ponto no tabuleiro e atingem **todos** na área, aliados inclusive; explosões saem ao redor do conjurador. Algumas áreas ficam no chão, coloridas pelo elemento: Poeira da Podridão, Purgatório e Tentáculos de Lodo agem a cada turno enquanto durarem.

O **Medo** é só ameaça: ao ver criaturas, cada agente testa Vontade contra a **Presença Perturbadora** (falhar custa Sanidade; NEX alto dá imunidade). A **Sombra Sussurrante** não sofre dano até alguém usar **Decifrar enigma**, e as pistas da missão ajudam. Com a Membrana Fina surgem eventos de pavor; Rompendo, o Medo ataca a Sanidade de todos a cada turno do mundo.

### Ameaças

Os encontros usam as fichas do livro (zumbis de Sangue, esqueletos de Lodo, vultos, cultistas que conjuram rituais, policiais, onças…), cada uma com as próprias habilidades: esqueletos viram poça e voltam se você não usar fogo ou Energia, a aberração agarra e abocanha, o succ prende a vítima até alguém ferir ele. O tamanho do encontro segue a regra do livro: a soma do VD das ameaças fica perto da soma do NEX de quem entra no combate. Com o grupo mais experiente aparecem ameaças maiores: o titã de Sangue, a múmia que ainda age a 0 PV, o viajante invisível que devora memórias, líderes de culto que cobrem o campo de Poeira da Podridão e enxames que ferem quem está por perto.

Algumas criaturas só caem quando o grupo resolve o **Enigma de Medo** delas (botão do enigma na arena, que mostra o próximo passo): fingir dormir e fechar a fresta do Espreitador, fechar o registro e abrir as torneiras contra a Mulher Afogada, fotografar o Viajante, tocar a melodia proibida por 4 rodadas enquanto o Escutado se multiplica. O Carniçal hipnotiza agentes, que passam a lutar do lado dele até se libertarem.

Granadas (de fragmentação, incendiária e de atordoamento) são requisitadas na Base e usadas pelo seletor de itens da arena: atingem todos num raio de 6 m, aliados inclusive. O fogo é a única coisa que fere a Aracnasita e ajuda a murchar uma das flores da Dama de Sangue; as outras flores murcham com fertilizante, agrotóxico, um bulbo raro ou água corrente. O covil do fim da missão muda com a experiência do grupo: Portão do Inferno, o Julgamento do Anjo, o Apocalipse da Aniquilação, o Deus da Morte e, para um grupo no auge (NEX somado 390), O Pacto com o Diabo — que só cede a uma força de Morte equivalente.

### Missões da comunidade

Na Base, em **Missão**, escolha entre a missão procedural e as missões da comunidade (a de exemplo é "A Capela do Morro"). O botão **Editor de missões** abre um editor simples: pinte o terreno hex a hex, ponha início, covil, vilas, encontros, eventos e investigações, crie eventos próprios, escolha as ameaças do covil e salve. As missões ficam em `user://missoes/` e também podem ser escritas à mão: o formato está em [docs/04-missoes-da-comunidade.md](docs/04-missoes-da-comunidade.md).

### Campanha: O Fundo da Represa

Na Base, em **Missão**, escolha **Campanha: O Fundo da Represa**. É uma história original em 4 missões, numa cidade do interior de Goiás que uma represa afogou em 1979 e que a seca está trazendo de volta. O quadro da missão mostra o prólogo e o texto de abertura da próxima missão. Depois de cada vitória, o relatório traz o que aconteceu, as **marcas** que o grupo ganhou e os recrutas que a história libera.

- Responder às perguntas do caso numa missão deixa marcas que ajudam nas seguintes: a Membrana mais forte, o covil já revelado, o chefe final mais fraco.
- Perder não avança a campanha: a mesma missão espera outra tentativa.
- O formato está em [docs/05-campanha.md](docs/05-campanha.md).

### Online

Na Base, em **Online**, uma pessoa clica em **Hospedar** (porta 7777) e as outras escrevem o IP dela e clicam em **Entrar**. Quem entra espera no saguão. O host escolhe o dono de cada agente no grupo e começa a missão; cada um joga a vez dos seus agentes. A carreira é do host; quem entrou volta para a própria carreira ao sair. Detalhes, rede e o teste com dois processos estão em [docs/06-online.md](docs/06-online.md).

### Co-op local (até 4 jogadores)

Na Base, em **Jogadores (co-op local)**, adicione jogadores e escolha o dispositivo de cada um (teclado e mouse ou um controle). No grupo da missão, cada agente ganha um dono. Na vez de um agente, só o dispositivo do dono funciona, e uma faixa amarela avisa de quem é a vez. Com controle: o direcional e A/B navegam os botões, LB/RB trocam o foco, e depois de rolar o movimento (ou num modo de ataque, movimento ou ritual na arena) o direcional ou o analógico movem um cursor pelo tabuleiro, A confirma e B volta para os botões. Na investigação, "Próximo ponto" troca o ponto de interesse.

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
- [Missões da comunidade](docs/04-missoes-da-comunidade.md)
- [Campanha](docs/05-campanha.md)
- [Jogar online](docs/06-online.md)
- [Decisões de arquitetura (ADRs)](docs/adr/)

## Contribuindo

Veja [CONTRIBUTING.md](CONTRIBUTING.md).

## Idiomas

Português (BR). Outros idiomas, quando aparecerem, ficam marcados como **WIP**.
