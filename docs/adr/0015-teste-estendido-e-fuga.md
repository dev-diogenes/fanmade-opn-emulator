# ADR 0015: o teste estendido como peça de regra e a fuga como fim de combate

- **Status:** aceito, 22/10/2026
- **Contexto:**
  - o pedido de "fugir e caçada, semelhante ao livro";
  - teste estendido (p.86-87);
  - interrogatório (docs/40);
  - docs/72.

## Contexto

O combate só acabava de dois jeitos: um lado de pé ou ninguém. Fugir pedia um terceiro fim. Esse fim precisava atravessar quatro camadas:
- `Combate`;
- a arena;
- o `Jogo`;
- a `Missao`, onde o encontro tem que ficar no mapa.

O livro não tem regra de perseguição no núcleo, mas tem o teste estendido, que serve a qualquer esforço longo do grupo.

## Decisão

- **`TesteEstendido`** (`scripts/rules/teste_estendido.gd`) é lógica pura e reutilizável.
  - Recebe DT, complexidade e uma lista de perícias, e conta sucessos e falhas.
  - Lembra quais perícias cada agente já usou, para que cada um use a melhor ainda não usada.
  - Fuga e caçada são os primeiros usos. Outros esforços longos podem usar a mesma peça.
- **"fuga" é um vencedor** de `Combate.lado_vencedor()`.
  - Quando `Combate.fugiram` é verdadeiro, `_verificar_fim()` encerra a luta como "fuga".
  - O sinal `combate_encerrado("fuga")` leva o resultado pelo mesmo caminho dos outros fins.
- **Quem sai da luta sem cair** fica marcado em `mods_cena`:
  - `fugiu`, para a ameaça que foge;
  - `escapou`, para o fugitivo que a caçada não pegou;
  - `rendido` e `algemado`, como antes.
  - `Ser.encerrar_cena()` preserva essas marcas, para a arena contá-las depois do fim.
- **A missão recebe os escapados.**
  - A assinatura passa a ser `Missao.concluir_encontro(vencedor, rendidos, escapados)`, e `Jogo.voltar_do_combate` repassa o novo parâmetro.
  - Com vencedor "fuga", o encontro fica no mapa e o grupo recua um hex.
- **Comandos:** "fugir" e "cacar" entram em `ACOES_COMBATE`, para que a fuga e a caçada passem pela sessão como qualquer ação (ADR 0007).

## Consequências

- **Saves antigos** não mudam: `fugiu` e `escapou` só existem durante e logo depois do combate.
- **O padrão do parâmetro:** quem chamar `concluir_encontro` com dois argumentos continua funcionando, porque `escapados` vale 0.
- **Quem escuta `combate_encerrado`** precisa tratar "fuga". A arena trata, com o carimbo próprio no relatório.
