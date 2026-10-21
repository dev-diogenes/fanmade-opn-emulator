# Investigação ampliada

> Status: **v0.1**, 21/10/2026. Pedido: "faz a investigação ampliada (perguntas novas no meio do caso, como no livro)".

## A regra do livro (p.79)

Em casos extensos, o objetivo da missão pode ser ampliado ou alterado conforme os investigadores descobrem coisas. O exemplo do livro é um crime que, investigado, revela outra motivação por trás. O mestre então acrescenta perguntas novas à ficha de investigação.

## Como ficou no jogo

1. **Todo caso guarda uma reviravolta.** O caso escolhe uma reviravolta e o culpado dela já na geração, com uma semente do próprio caso. Por isso ela é igual nas duas máquinas do online e não gasta dados. Ela começa **escondida**.
2. **A primeira acusação certa revela a reviravolta.** Com ela, a ficha ganha uma **pergunta nova**, e o registro diz "A investigação se amplia.", com o texto da revelação e a pergunta.
   - Vale para qualquer pergunta: quem, o quê ou onde.
   - Vale na cena e no mapa.
   - A partir da segunda descoberta, nada mais se amplia.
3. **A pergunta nova funciona como as outras:**
   - candidatos com 3 traços, e dois candidatos nunca dividem mais de um traço;
   - acusação com custo;
   - efeito ao acertar.
4. **De onde vêm as pistas dela:**
   - os pontos de interesse cuja pergunta **já foi resolvida** passam a dar pistas da pergunta nova (o que se acha ali agora serve à reviravolta);
   - os eventos com efeito `pista` sem pergunta definida também caem nela, porque é a pergunta aberta com menos pistas;
   - os depoimentos incertos (docs/35) valem aqui também.

### As três reviravoltas (conteúdo original, `casos.json`, `ampliacoes`)

| Reviravolta | Pergunta | Candidatos | Ao acertar |
|---|---|---|---|
| Cúmplice | Quem é o cúmplice? | o vigia noturno, uma enfermeira do plantão, o coveiro, um taxista da rodoviária | Membrana +5 |
| Objeto | Que objeto amaldiçoado está em jogo? | um espelho de moldura dourada, uma câmera antiga, um disco de vinil sem rótulo, uma boneca de porcelana | O chefe começa mais fraco |
| Quando | Quando será o ritual? | na próxima lua cheia, no próximo velório, no aniversário da tragédia, na festa do padroeiro | Membrana +10 |

São 23 traços novos (molho de chaves, sedativos, reflexo errado, chiado, contagem, luto e outros), cada um com rótulo e uma frase de observação.

### Na tela
- **Quadro do caso:** o bilhete novo entra como mais uma coluna, com o seu **Deduzir**. O quadro **cresce 130 px** por pergunta a mais, então os bilhetes não estreitam. Na cena, ele se ajusta na hora da reviravolta (com o som do carimbo).
- **Ficha de suspeitos:** ganha uma aba com o nome curto da pergunta ("Quando?", "Cúmplice?", "Objeto?").
- **Painel do caso no mapa:** lista a pergunta nova com os traços encontrados.

| Quadro com a 4ª pergunta | Ficha da pergunta nova |
|---|---|
| ![Quadro](amp36_quadro.png) | ![Ficha](amp36_ficha.png) |

**Saves:** a reviravolta, o culpado dela e se ela já apareceu vão no save. Um save antigo sorteia a reviravolta ao carregar.

## Testes

Total: **523** (eram 520).
- **Regra da tabela:** vale nas três reviravoltas.
- **A primeira acusação certa amplia o caso:**
  - a pergunta nova tem os candidatos da reviravolta e o culpado sorteado;
  - os pontos de "quem" passam a responder a pergunta nova;
  - duas pistas firmes deixam um só suspeito também nela;
  - a segunda descoberta não amplia de novo.
- **Save:** o caso ampliado vai e volta.
- **Quadro:** a acusação certa amplia o caso, e o bilhete novo tem Deduzir.
