# ADR 0012: o jogo sob a Licença da Comunidade

- **Status:** aceito, 22/10/2026
- **Contexto:**
  - a Licença da Comunidade de Ordem Paranormal, v1.0, de 28/06/2026 (ordemparanormal.com.br/licenca);
  - o relatório de pesquisa "Melhorias pelo universo de Ordem Paranormal" (notas em `research_notes/.../licenca_comunidade.md`);
  - a decisão do dono do projeto sobre nomes canônicos;
  - docs/60.
- **Substitui:** a regra 5 e a recomendação de distribuição de docs/03.

## Contexto

A licença é concedida pelo titular, e não pela editora. Ela vale para conteúdo de fã gratuito e para homebrew vendido, inclusive como aplicativo. Videogames não aparecem com todas as letras. Casos ambíguos são decididos pelo titular.

**O que ela proíbe:**
- a marca "Ordem Paranormal" no título, os logos e a identidade visual oficial;
- textos e imagens dos livros;
- nomes próprios do cânone;
- sugerir parceria ou aprovação;
- material gerado por IA em conteúdo vendido.

**O que ela exige:**
- o selo na capa, com ao menos 10% da largura e opaco;
- um aviso de conteúdo sensível;
- no conteúdo gratuito feito com IA, a frase "Contém material gerado por inteligência artificial" junto do selo;
- respeito à LGPD.

Antes desta fase, o jogo se chamava "Ordem Paranormal: Fanmade (WIP)", com o logo "ORDEM PARANORMAL" na tela de título. Os recrutas e as testemunhas usavam nomes que coincidiam com personagens do cânone.

## Decisão

- **Título de trabalho: "Membrana", com "Casos da Ordo Realitas" acima.** A licença libera Membrana e Ordo Realitas como termos do universo.
  - O título fica numa constante (`Licenca.TITULO`) e em `project.godot`.
  - **A descrição** "Um jogo inspirado no sistema de Ordem Paranormal" foi escolhida pelo dono do projeto (22/10/2026). Ela vai embaixo do título, em letra de texto, e na descrição do projeto, mas não no nome: na janela, no logo e no `config/name`, o nome é só "Membrana". Se o dono quiser a frase dentro do nome, a decisão é dele, contra a Parte 4 da licença.
  - A marca só aparece no nome da própria licença, na frase de conteúdo não oficial.
- **Selo:**
  - na tela de título, no canto de baixo à direita, com ao menos 10% da largura da tela (`Licenca.FRACAO_SELO`), e também no Sobre;
  - **junto dele,** o aviso de IA e uma linha de conteúdo sensível;
  - **o arquivo oficial** (`assets/licenca/selo.png`) foi baixado do site da licença, com a autorização do dono do projeto. Ele é preto com fundo transparente, então vai sobre um disco claro para ficar legível na capa escura;
  - **sem o arquivo,** a tela mostra um quadro do mesmo tamanho, que guarda o lugar.
- **Avisos:**
  - **conteúdo sensível:** um papel na primeira vez que o jogo abre, antes do aviso de flashes, com "Sair do jogo" como saída; o texto também fica no Sobre e numa linha da capa;
  - **conteúdo não oficial:** no rodapé da capa e no Sobre;
  - **IA:** junto do selo e no Sobre.
- **Tela "Sobre e licença"** no menu do título:
  - o que o jogo é e a licença;
  - o que vem do sistema;
  - os avisos de conteúdo sensível e de IA;
  - privacidade (o jogo não coleta dados, e o online liga os computadores direto);
  - créditos.
- **Ordo Realitas no lugar de "Ordem da Realidade"** nos cabeçalhos: é a organização que a licença libera pelo nome.
- **Nomes canônicos: saem os personagens.** Por decisão do dono do projeto, ameaças, criaturas, elementos e rituais ficam com o nome original. O texto da licença também cita entidades, lugares e eventos entre os nomes vedados. O risco está registrado e a decisão é revista se o titular pedir.
  - **Como se verificou:** cruzamos os nomes de gente do jogo com os 639 personagens da wiki (categoria Personagens e subcategorias), sem acento e com "th" = "t".
  - **Recrutas trocados:**
    - Mauro → Cléber (Mauro Nunes é personagem principal e aparece no livro);
    - Joana → Celeste;
    - Tiago → Ademir (soa como Thiago Fritz).
  - **Saves antigos** trocam esses nomes na carga.
  - **Campanha:**
    - Lúcia Arantes → Marisa Prates;
    - Davi → Gilson;
    - Seu Joaquim → Seu Belmiro;
    - Otávio Sarmento → Osmar Sarmento;
    - padre Anselmo → padre Ezequiel.
  - **Testemunhas:**
    - Fátima → Odete;
    - Jéssica → Denise;
    - Wagner → Benedito.
  - **Apelidos:**
    - Coruja → Bigorna;
    - Corvo → Anzol;
    - Tatu → Ponteiro.
  - **Teste de regressão:** `test_licenca.gd` guarda os primeiros nomes dos personagens principais e falha se um nome de gente do jogo coincidir.
- **O jogo é e continua gratuito.** Ele foi feito com assistência de IA, e conteúdo vendido não pode ter material gerado por IA.
- **LGPD:** o jogo não coleta nem envia dados. O online é ENet direto entre os computadores.

## Consequências

- **O jogo cumpre o que a licença exige na capa:** o selo oficial, o aviso de IA, o aviso de conteúdo e a frase de conteúdo não oficial.
- **O título "Membrana" é provisório.** Trocar é mexer em uma constante e em `project.godot`.
- **Nomes de criaturas e rituais do livro continuam no jogo.** Se o titular entender que são "entidades" do cânone, eles mudam para nomes próprios.
- **Os docs antigos** (docs/01 a docs/59) citam o Mauro e o título antigo como histórico. O jogo e os testes já usam os nomes novos.
- **A dúvida sobre videogames:** um jogo de fã está coberto pela licença? A resposta definitiva só vem do titular, pelo contato do site oficial.
