# Relatório à Ordem e elemento do caso

> Status: **v0.1**, 22/10/2026. Primeira fase do plano que junta docs/51 e o relatório de pesquisa "Melhorias pelo universo de Ordem Paranormal" (itens IN1, IN2, EL3). Decisão em ADR 0011.

## O problema

Na partida de docs/51, o caso se resolveu no turno 5:
- **Uma pista bastava:** de 10% a 50% dos traços eram de um candidato só.
- **O chute compensava:** errar custava 5 de Membrana por pergunta.
- **Todo caso era de Sangue.** O elemento, o eixo da lore, não pesava em nada.

## O que mudou

### Uma pista nunca basta

Todo traço agora aparece em **dois candidatos ou mais**, e dois candidatos continuam dividindo no máximo um traço. Assim, duas pistas firmes diferentes deixam um só suspeito.

| Pergunta | Estrutura | Depois de uma pista |
|---|---|---|
| Quem (7 suspeitos) | Plano de Fano: cada traço em 3 suspeitos, cada par divide um | restam 3 |
| O quê (5 ações) | "Sangue coletado" em três ações, os outros traços em pares | restam 2 ou 3 |
| Onde (6 locais) | Bipartido: prédios fechados (frigorífico, hospital, escola) × lugares abertos (igreja, fazenda, cemitério) | restam 3 |
| Reviravoltas (4 candidatos) | Cada par divide exatamente um traço | restam 2 |

Alguns traços novos foram escritos para servir a todos os que o têm. Por exemplo, "Cheiro de carne" vale para o frigorífico e para o cemitério, e "Sino na gravação" para a igreja e para a escola. Os que não têm mais candidato saíram da tabela.

### Relatório à Ordem

**Quem, o quê e onde vão juntos**, como os destinos em Return of the Obra Dinn:
- Na ficha de suspeitos, clicar num candidato só o põe no relatório, com o selo "NO RELATÓRIO".
- A barra embaixo mostra "Quem: … · O quê: … · Onde: …". O **Enviar relatório** só acende com os três, cada um com ao menos uma pista.
- **Aceito:** as três perguntas se resolvem, os efeitos valem (chefe mais fraco, Membrana, covil revelado) e a reviravolta aparece.
- **Recusado:** a Membrana cai 5, uma vez só.
  - No modo normal, a Ordem diz quantas respostas se sustentam ("1 de 3"); no hardcore, nada.
  - O mesmo relatório não pode ser mandado de novo.
- **A reviravolta** continua com a acusação avulsa, que risca o suspeito.

![A ficha montando o relatório: quem e o quê escolhidos, falta onde](rel52_ficha.png)

### O elemento do caso

- **Sorteio:** cada caso tem um elemento, **Sangue, Morte, Conhecimento ou Energia**, tirado de uma semente do caso (igual no online, sem gastar dados).
- **Sintomas no briefing:** o briefing não diz o elemento, só os sinais, tirados da wiki:
  - **Sangue:** desaparecimentos, sangue seco, animais sem uma gota de sangue.
  - **Morte:** gente que envelheceu de um dia para o outro, relógios parados, poeira cinza em espirais.
  - **Conhecimento:** moradores repetindo frases alheias, símbolos dourados nos muros, gente que esqueceu o próprio nome.
  - **Energia:** aparelhos que ligam sozinhos, quedas de luz em sequência, queimaduras sem fogo.
- **Confirmação:** o relatório aceito responde "o quê" e **confirma o elemento**. O quadro do mapa passa a mostrá-lo na cor dele, e o registro dá o ciclo do livro (p.98, p.118): "O elemento é Energia: no covil, rituais de Conhecimento têm vantagem e os de Energia, desvantagem".
- **O caso inteiro segue o elemento:**
  - **Covil:** o do elemento do caso, com chefes próprios do mesmo porte do Horror Carmesim (45 PV, VD 25):
    - Morte: **A Casa Parada**, com o **Arauto Cinzento**;
    - Conhecimento: **O Arquivo Dourado**, com a **Máscara Dourada**;
    - Energia: **A Subestação**, com a **Estática Viva**.

    Cada chefe é vulnerável ao elemento opressor. O Horror Carmesim ganhou a vulnerabilidade a Morte.
  - **Encontros no mapa:** os paranormais de outro elemento viram um do elemento do caso, de nível e VD até os do original. Os de gente e bichos ficam.
  - **Ameaças que surgem:** só de gente e bichos, do elemento do caso ou do Medo, que só vem com a Membrana fina (EL3 do relatório).

![O quadro do caso com o elemento confirmado](rel52_elemento.png)

## Medido (`dev/playtest_auto.gd`, 10 seeds)

| Perfil | Vitória | Solucionado | Turnos | PP | Mortos | Relatórios recusados |
|---|---|---|---|---|---|---|
| Investigador | 0,9 | 0,9 | 6,6 (era 6,3) | 13,7 | 0,1 | 0 |
| Pressa | 0,7 | 0,2 | 9,8 | 12,9 | 0,3 | 0 |

- **Um erro de calibragem, corrigido:** a primeira versão usava criaturas do livro como chefes (o Succ tem 65 PV), e a vitória caiu para 0,2, com 0,8 morte por missão. Os chefes próprios trouxeram de volta a vitória de 0,9.
- **O investigador mal mudou de ritmo:** ele manda o relatório assim que tem duas pistas firmes por pergunta, o que duas cenas dão. O que mudou foi o **chute**, que deixou de compensar.
- **O "pressa" quase não soluciona mais** (0,2): sem as pistas, não manda relatório e vai ao covil quando a Membrana rompe. É o castigo de correr.
- Se jogadores de verdade ainda fecharem o caso cedo, o próximo passo é a **cena focar duas perguntas** (docs/51). A pressão de tempo vem na fase seguinte (noite e ameaças que caçam).

## Onde está

- **Dados:**
  - `casos.json`: os traços novos, `elementos` com nome e sintomas, o resumo com `{sintomas}` e as notas;
  - `encontros.json`: o `elemento` dos covis e os três covis novos;
  - `ameacas.json`: os três chefes e as três armas.
- **Regra:**
  - `Caso`: `elemento`, `relatar`, `perguntas_do_relatorio`, `relatorios_recusados`, `elemento_confirmado`;
  - `Missao`: `relatar`, `covil_para(grupo, elemento)`, `elemento_do_encontro`, `_ajustar_encontros_ao_elemento`, `elemento_opressor`, `linha_do_elemento`;
  - `CenaInvestigacao.relatar`;
  - comando `relatar` no mapa e na cena.
- **Tela:** `PainelDeducao` (o relatório) e o quadro do caso no mapa (o elemento).
- **Piloto e playtest:** `PilotoMissao.lote_para_relatar`.

## Testes

Total: **578**.
- **Arquivo novo `test_caso_elemento.gd`:**
  - o elemento varia e o briefing não o nomeia;
  - o covil segue o elemento;
  - encontros e surgimentos seguem o elemento;
  - o ciclo dos elementos aparece no texto do covil;
  - a ficha monta o relatório;
  - o piloto relata.
- **`test_investigacao.gd`:**
  - todo traço em dois candidatos ou mais;
  - uma pista nunca basta;
  - relatório certo e errado;
  - relatório no mapa, no hardcore e na cena.
- **Testes de covil e reviravolta:** passaram a fixar o elemento ou a usar o relatório.
