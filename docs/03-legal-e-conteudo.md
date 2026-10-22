# Legal e Conteúdo

> Isto não é aconselhamento jurídico. São regras práticas para um projeto de fã ficar dentro da licença.

O universo de *Ordem Paranormal*, as marcas e os personagens pertencem ao seu criador e titular. O livro é publicado pela editora. Este é um **projeto de fã, não oficial e gratuito**. Ele é publicado sob a **Licença da Comunidade de Ordem Paranormal** (v1.0, de 28/06/2026, ordemparanormal.com.br/licenca). As decisões estão no [ADR 0012](adr/0012-licenca-da-comunidade.md) e em [docs/60](60-licenca-titulo-selo-e-avisos.md).

## Regras do repositório

1. **Nunca versionar o livro**, nem PDFs, prints, páginas ou texto extraído. Eles ficam em `reference/`, que é ignorada pelo Git.
2. **Mecânica, sim; texto, não.** Podemos registrar números e estruturas de regras (DTs, tabelas de progressão, custos). As **descrições são escritas com palavras próprias**, e cada entrada aponta a página do livro em `ref`.
3. **Nada de arte oficial**, logos, identidade visual ou imagens das campanhas. Os assets vêm de bancos livres, com a licença registrada em `game/assets/CREDITS.md`, ou são feitos por nós.
4. **A campanha é original.** Nada da trama, dos personagens ou dos spoilers das campanhas transmitidas.
5. **Sem personagens do cânone.**
   - Nenhum nome de gente do jogo (recrutas, testemunhas, campanha, apelidos) pode coincidir com um personagem da wiki. O `test_licenca.gd` verifica os principais.
   - Ameaças, criaturas, elementos e rituais do livro mantêm o nome original, por decisão do dono do projeto (ADR 0012).
6. **A marca fica fora do título.** O jogo se chama "Membrana" (título de trabalho, em `Licenca.TITULO`). "Ordem Paranormal" só aparece no nome da licença, na frase de conteúdo não oficial.
7. **O que a licença exige, na capa (tela de título):**
   - o selo, com ao menos 10% da largura e opaco;
   - o aviso "Contém material gerado por inteligência artificial" junto dele;
   - um aviso de conteúdo sensível;
   - a frase de conteúdo não oficial.
8. **Nunca sugerir parceria, aprovação ou supervisão do titular.**
9. **Gratuito, sempre.** O projeto usa assistência de IA, e a licença proíbe material gerado por IA em conteúdo vendido (venda, assinatura, financiamento coletivo).
10. **LGPD.** O jogo não coleta, não envia e não compartilha dados pessoais.
11. Se o titular pedir, o projeto **remove o conteúdo ou sai do ar**.

## Distribuição

- **Como publicar:** só como conteúdo de fã gratuito, no itch.io ou nas releases do GitHub. A capa da página leva o selo e o aviso de IA, com as mesmas regras da tela de título.
- **Steam:** quem publica precisa ter os direitos do conteúdo, então a Steam fica fora.
- **Dúvidas:** a licença não cita videogames com todas as letras e deixa os casos ambíguos para o titular. Uma confirmação vai pelo contato de ordemparanormal.com.br, e não pela editora, que não concede a licença.
- **Conteúdo da comunidade:** os termos do editor de missões proíbem texto copiado do livro, arte oficial e personagens do cânone.
