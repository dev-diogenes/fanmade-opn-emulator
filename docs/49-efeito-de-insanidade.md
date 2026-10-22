# Efeito de insanidade ao ficar perturbado

> Status: **v0.1**, 21/10/2026. Pedido: "faz o efeito de insanidade ao ficar Perturbado pela primeira vez (p.111)".

## O que o livro diz (p.111-113)

- **Perturbado** é ter menos da metade da SAN. **Não tem efeito mecânico direto**: nada de penalidade nos testes. Algumas criaturas tiram proveito dele.
- Na **primeira vez que o personagem fica perturbado numa cena**, ele rola **1d20 na Tabela 5.1** (vinte efeitos de insanidade). Enquanto estiver perturbado, percebe o mundo daquele jeito.
- Se chegar a **enlouquecendo** (SAN 0), o efeito que era temporário passa a durar **até o fim da missão**, mesmo que o personagem seja acalmado.
- Um personagem pode **somar efeitos** na mesma missão, ficando perturbado de novo em outra cena.

## Como estava

O jogo já mostrava o perturbado: o retrato treme, o rótulo vira **SAN!** e a tela ondula, com vultos e sussurros genéricos (docs/17). Faltava o **efeito rolado**: todo agente perturbado alucinava igual.

## Como ficou

### A regra

- **`data/rulesets/op2022/insanidade.json`**: os 20 efeitos da Tabela 5.1, com nome, descrição e frases **escritos para o jogo** (ref p.113).
- **`Agente`** rola o efeito quando **passa a estar perturbado**, uma vez por cena:
  - Deixando de estar perturbado (por Relaxar no interlúdio, por exemplo), o efeito temporário **some**.
  - Ao **enlouquecer**, os efeitos ficam **até o fim da missão**. Na Base (`Carreira._restaurar`), tudo some.
  - O mesmo número outra vez não traz efeito novo.
- **O que conta como cena:** um combate (até `encerrar_cena`) e, no mapa, **cada turno do agente**.
- **O 1d20** sai da semente da missão, do agente e de quantas vezes ele já rolou. É igual nos dois lados do online e não gasta a fila de dados (o mesmo padrão da "sorte" das outras decisões).
- **Sem efeito mecânico**, como no livro. Um teste mostra que a rolagem e a Defesa não mudam.

### Na tela

- **Nota de insanidade:** um bilhete escuro com borda de sangue cai no alto da tela, com o agente, o **1d20**, o nome datilografado, a descrição e a duração ("enquanto a SAN estiver abaixo da metade" ou "até o fim da missão"). Uma linha lembra que não muda os testes.
  - Vem com um pulso de fita (VHS) e o som de interferência.
  - Some sozinha em 8 s ou com um clique, e não bloqueia o jogo.
  - Aparece no mapa, no combate e na investigação.
- **Registro:** "Sanidade abaixo da metade: Bianca rola um efeito de insanidade (1d20: 6), **Olhos nas sombras**…", no relatório de campo e no registro do combate.
- **Alucinações** (docs/17), na vez de quem tem efeito:
  - Os sussurros saem **das frases do efeito** (7 em cada 10). Quem tem "A voz que acusa" ouve "Mentiroso."; quem tem "Mãos furadas", "Cadê? Estava aqui.".
  - **Olhos nas sombras** chama vultos com o dobro da frequência.
  - Um efeito que dura até o fim da missão mantém **um pouco de loucura** na tela mesmo com a SAN de volta.
- **Retrato:** a dica do retrato lista os efeitos e a duração de cada um.

![A nota de insanidade no mapa](insan49_nota.png)

## Os vinte efeitos

| 1d20 | Nome no jogo |
|---|---|
| 1 | Sede de dor |
| 2 | Rostos misturados |
| 3 | Vozes de criatura |
| 4 | A voz que acusa |
| 5 | Sangue quente |
| 6 | Olhos nas sombras (mais vultos) |
| 7 | Fome sem fundo |
| 8 | Gosto de ferro |
| 9 | Luz que queima |
| 10 | Boca alheia |
| 11 | Coceira nos olhos |
| 12 | Memória furada |
| 13 | Emoções trocadas |
| 14 | Narrador grotesco |
| 15 | Vermes |
| 16 | Falso poder |
| 17 | Mãos furadas |
| 18 | Tudo é sorte |
| 19 | Dor que agrada |
| 20 | Celebrar o fim |

As descrições são nossas e mais curtas que as do livro. Os efeitos mais pesados (1, 11 e 20) ficaram sem detalhe gráfico.

## Onde está

- **Regra:**
  - `Ser._atualizar_san` chama os ganchos `_mudou_perturbado` e `_comecou_a_enlouquecer`; `Agente` os implementa.
  - `Agente.efeitos_insanidade`, `insanidades()`, `linha_insanidade()`, `nova_cena_de_insanidade()` e `limpar_insanidade()`, com o sinal `ganhou_insanidade`.
  - Os efeitos vão no save.
- **Tabela:** `Ruleset.efeitos_insanidade()` e `efeito_insanidade(n)`.
- **Registro:** `Missao._vincular` (mapa) e `Combate.adicionar` (combate).
- **Tela:** `NotaInsanidade` (novo). `Alucinacoes` agora recebe a lista de agentes, para avisar o efeito novo, e usa as frases do efeito. Na `CartaoAgente`, só a dica.

## Testes

Total: **562**. Arquivo `test_insanidade.gd`:
- **Tabela:** tem os 20 efeitos, com nome e frases.
- **Rolagem:**
  - Ficar perturbado rola um efeito; na metade exata ainda não.
  - A mesma semente dá o mesmo 1d20.
- **Duração:**
  - Uma vez por cena; o efeito some quando a SAN volta; outra cena rola de novo.
  - Enlouquecer fixa o efeito até o fim da missão; a Base limpa.
- **Sem efeito mecânico:** mesmo total no teste e mesma Defesa.
- **Save:** salva e carrega.
- **Registro:** o do combate e o do mapa contam o efeito.
- **Tela:** as frases vêm do efeito, e a nota mostra o nome.
