# Licença: título, selo, avisos e nomes

> Status: **v0.1**, 22/10/2026. Nona fase do plano, a última: o jogo passa a ser publicado sob a Licença da Comunidade de Ordem Paranormal (v1.0, de 28/06/2026). As decisões estão no [ADR 0012](adr/0012-licenca-da-comunidade.md), e as regras práticas, em [docs/03](03-legal-e-conteudo.md).

## O problema

- **O título:** o jogo se chamava "Ordem Paranormal: Fanmade (WIP)" e abria com o logo "ORDEM PARANORMAL". A licença não deixa usar a marca no título.
- **Os avisos:** faltavam o selo, o aviso de conteúdo sensível e o aviso de IA.
- **Os nomes:** o agente-símbolo do grupo inicial se chamava Mauro, e Mauro Nunes é personagem principal do cânone, com presença no livro.

## O que mudou

### O título: "Membrana"

- **"Membrana"**, com "Casos da Ordo Realitas" acima. A licença libera os dois termos.
- **Título provisório,** numa constante só (`Licenca.TITULO`) e em `project.godot`.
- **A frase de conteúdo não oficial** fica no rodapé: "Conteúdo não oficial, publicado sob a Licença da Comunidade de Ordem Paranormal. Sem parceria, aprovação ou supervisão do titular dos direitos."
- **Nos cabeçalhos,** "Ordem da Realidade" virou **Ordo Realitas**, a organização que a licença libera pelo nome:
  - no relatório de progressão;
  - no relatório de operação;
  - na transição para a Base.

![A tela de título](l60_titulo.png)

### O selo e o aviso de IA

- **O selo:** no canto de baixo, à direita, com ao menos 10% da largura da tela, como a licença pede para a capa.
- **Junto dele:** "Contém material gerado por inteligência artificial" e a linha de conteúdo sensível.
- **O arquivo oficial** (`game/assets/licenca/selo.png`, 1920 × 1920) foi baixado do site da licença com a sua autorização. Ele é preto, com o fundo transparente; sobre a capa escura, o anel de fora sumia. Por isso vai sobre um disco claro, opaco e legível, como a licença pede. Os mipmaps evitam o serrilhado na redução.
- **Sem o arquivo,** um quadro do mesmo tamanho guarda o lugar.

### O aviso de conteúdo

- **Quando aparece:** na primeira vez que o jogo abre, antes do aviso de flashes.
- **O que diz:** que o jogo é de terror, com violência, sangue, mortes de personagens, cultos, perda de sanidade, possessão e criaturas que perseguem o grupo.
- **As saídas:** "Entendi" ou "Sair do jogo".
- **Onde mais aparece:** na capa, numa linha curta, e no Sobre.

![O aviso de conteúdo](l60_aviso.png)

### Sobre e licença

Um item novo no menu do título abre uma folha com sete seções:
- o que o jogo é;
- a licença, com versão e endereço;
- o que vem do sistema (números e estruturas; descrições com palavras próprias);
- conteúdo sensível;
- IA;
- privacidade (sem coleta de dados; o online liga os computadores direto);
- créditos (Godot, GUT, KayKit, as fontes, os sons sintetizados).

![Sobre e licença](l60_sobre.png)

### Sem personagens do cânone

Você decidiu que só os personagens saem: ameaças, criaturas, elementos e rituais mantêm o nome original.

**Como se verificou:** os nomes de gente do jogo foram cruzados com os 639 personagens da wiki, sem acento e com "th" = "t".

**O que mudou:**

| Onde | Antes | Agora | Por quê |
|---|---|---|---|
| Recruta | Mauro | Cléber | Mauro Nunes, personagem principal, está no livro |
| Recruta | Joana | Celeste | Joana é personagem do mestre |
| Recruta | Tiago | Ademir | soa como Thiago Fritz |
| Campanha | Lúcia Arantes | Marisa Prates | Lúcia; Herman Arantes |
| Campanha | Davi, Seu Joaquim, Otávio Sarmento, padre Anselmo | Gilson, Seu Belmiro, Osmar Sarmento, padre Ezequiel | primeiros nomes de personagens |
| Testemunhas | Fátima, Jéssica, Wagner | Odete, Denise, Benedito | personagens com esses nomes |
| Apelidos | Coruja, Corvo, Tatu | Bigorna, Anzol, Ponteiro | Coruja e Corvo são personagens; Tatu Peba também |

- **Saves antigos:** os recrutas trocam de nome na carga.
- **O editor de missões** lembra, ao compartilhar: nada de texto copiado do livro, arte oficial ou personagens do cânone.

## O que fica para depois

- **Confirmar o título** ou escolher outro.
- **Pedir ao titular a confirmação** de que um videogame de fã está coberto pela licença, pelo contato do site oficial.
- **A capa da página de distribuição** (itch.io) com o selo e o aviso de IA.

## Onde está

- **Tela:**
  - `Licenca` (novo): o título, os avisos e o selo com a largura mínima;
  - `PainelSobre` (novo);
  - `Titulo`: a capa, o selo, os avisos e o botão Sobre;
  - `Preferencias`: `aviso_conteudo_visto`.
- **Regra:** `Carreira.RENOMEADOS`, que troca o nome dos recrutas de saves antigos.
- **Dados:**
  - `recrutas.json` e `grupo_inicial.json`;
  - `testemunhas.json` e `pessoais.json`;
  - a campanha O Fundo da Represa.
- **Projeto:** `project.godot` (o nome e a descrição).

## Testes

Total: **633**. Arquivo novo, `test_licenca.gd`:
- **Nomes:**
  - nenhum nome de gente do jogo coincide com os personagens principais do cânone;
  - um save antigo troca o nome do recruta.
- **Capa:** o título não tem a marca; a capa mostra o título, o selo oficial (não o quadro reservado) com 10% da largura, o aviso de IA, a frase de conteúdo não oficial e o botão Sobre.
- **Sobre:** mostra a licença, o aviso de conteúdo e o aviso de IA, e o tour espera por ele.
