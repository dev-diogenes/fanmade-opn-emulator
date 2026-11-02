# Local vasculhado e abertura da missão

> Status: **v0.1**, 02/11/2026. São os extras da Sprint 01 ([sprints/sprint-01.md](sprints/sprint-01.md)): o IN6 e o AU6 do relatório de pesquisa (`reports/`). Pedido do dono do projeto: "Sim, adiante os extras".

## IN6: local vasculhado

**O problema:** o jogador não sabe se vale voltar a um lugar investigado. As críticas do Enigma do Medo citadas no relatório apontam isso como a fonte de "voltas à toa".

**No jogo:**
- **A missão guarda cada local investigado:** a cena, o hex e quantos pontos ficaram para trás (`Missao.locais_investigados`, que vai no save).
- **O Revisar Caso do interlúdio (docs/48)** desconta os pontos que vai achando. Quando não sobra nenhum, o local fica vasculhado.
- **A dica do hex no mapa** mostra "✔ Vasculhado: não há mais nada a achar aqui" quando o local acabou. Se ainda há pontos, mostra "Investigado: ficaram N ponto(s) (Revisar Caso, no interlúdio)".
- **Na cena de investigação**, quando o último ponto sai, o carimbo **VASCULHADO** aparece sob o nome do lugar, com o som de carimbo e a dica "dá para sair sem perder nada".

O "Modo Detetive" do mesmo item, em que o quadro não liga as pistas sozinho, ficou para depois dos playtests.

## AU6: frase-tema e premissa na abertura

Os sinais da rede (docs/62) já tinham o "lugar banal e evento estranho" no relato, e a fonte dizia quem chamou. Faltava a abertura juntar isso numa linha e ter uma frase própria. Agora o arquivo do caso da missão procedural começa assim:

1. A **frase-tema** do elemento do caso, entre aspas. São frases nossas, de duas a três por elemento, mais uma geral, em `data/jogo/abertura.json`. **Nenhuma** é a frase de abertura da série.
2. **O CASO:** o relato do sinal, mais "Quem chamou a Ordem: (fonte) (confiança …)". Essa linha substitui a antiga linha SINAL.
3. Em seguida, o que já existia: ponto de encontro, senha, resumo, objetivo e perguntas.

A escolha da frase depende da semente: a mesma missão tem sempre a mesma abertura (`Sinais.abertura`).

## Correção: o arquivo do caso não abria

Para abrir o briefing, o mapa conferia se o registro da missão estava vazio. Desde o docs/71, o culto e o subgênero escrevem no registro quando a missão é criada, então nas missões procedurais da carreira o arquivo do caso **não aparecia sozinho**. Quem jogava começava sem o objetivo na tela.

Agora vale a marca `Missao.briefing_visto`, guardada no save. Ela fica fora do hash do online: é da tela de cada jogador, não do estado do jogo. Nos saves antigos, uma missão com turno maior que 1 ou com mais de 3 linhas no registro conta como briefing já visto.

Havia um segundo defeito, também desde o docs/71. O arquivo do caso reconhecia a missão procedural por `extras` vazio, mas o culto passou a morar em `extras.culto`. Com isso, o ponto de encontro, a senha e o sinal **sumiram** do briefing. Agora a missão é procedural quando não é da comunidade (`extras.id`) nem da campanha (`extras.campanha`).

## Testes

São 3 testes novos em `test_investigacao.gd`:

- o local fica investigado com 1 ponto e, depois de revisado, vasculhado (inclusive no save);
- uma cena sem pontos restantes já sai vasculhada;
- a abertura tem a frase do elemento e a premissa com a fonte, é sempre a mesma para a mesma semente, e não tem premissa quando não há sinal.
