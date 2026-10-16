# Campanha — formato `campanha.json` v1 e "O Fundo da Represa"

A campanha é uma sequência fixa de missões com história. Cada missão é um arquivo no formato das [missões da comunidade](04-missoes-da-comunidade.md). O `campanha.json` junta essas missões e acrescenta os textos entre elas, as marcas que passam de uma missão para a seguinte e os recrutas que a história libera. A decisão está no [ADR 0006](adr/0006-campanha.md).

## Onde fica

`res://data/campanhas/<id>/campanha.json`, com os arquivos das missões na mesma pasta. A Base lista toda subpasta que tiver um `campanha.json`. As missões da campanha não aparecem soltas na lista da comunidade.

## Estrutura

```json
{
  "formato": "opn-campanha",
  "versao": 1,
  "id": "o_fundo_da_represa",
  "titulo": "O Fundo da Represa",
  "autor": "Equipe do projeto",
  "descricao": "Aparece quando não há prólogo.",
  "prologo": "Aparece na Base antes da primeira missão.",
  "epilogo": "Aparece no relatório quando a última missão é vencida.",
  "recrutas": [ { "nome": "Davi", "classe": "combatente", ... } ],
  "missoes": [ { "arquivo": "01_nivel_baixo.json", ... } ]
}
```

`formato`, `versao`, `id`, `titulo` e `missoes` são obrigatórios.

### `recrutas`

São fichas no mesmo formato de `data/jogo/recrutas.json`. Elas só entram na lista de recrutamento da Base depois que uma missão as libera em `recompensas`.

### Cada missão

```json
{
  "arquivo": "02_a_estrada_que_desce.json",
  "antes": "Texto de abertura, mostrado na Base.",
  "depois": "Interlúdio, mostrado no relatório depois da vitória.",
  "falha": "Mostrado no relatório depois da derrota.",
  "recompensas": {"recrutas": ["Davi"]},
  "marcas": {"onde": {"id": "planta_da_usina", "texto": "Mostrado no relatório."}},
  "efeitos_de_marcas": [
    {"marca": "nos_de_sete", "tipo": "membrana", "valor": 10, "texto": "Mostrado no registro da missão."}
  ]
}
```

- **`marcas`:** uma marca por pergunta do caso (`quem`, `oque` ou `onde`). Se o grupo responder à pergunta e vencer a missão, a marca fica guardada na carreira.
- **`efeitos_de_marcas`:** quando a missão começa, vale cada efeito cuja marca o grupo trouxe de uma missão anterior. Os tipos são:
  - `membrana`, com `valor` positivo ou negativo;
  - `chefe_enfraquecido`, com `valor` como fração dos PV do chefe (`0.2` tira 20%);
  - `revelar_objetivo`, sem valor.

### Regras

- **Vitória:** a campanha avança para a próxima missão. As marcas ganhas ficam guardadas, e os recrutas da recompensa entram na Base.
- **Derrota:** a campanha não avança. A mesma missão fica esperando outra tentativa, com o mesmo grupo ou com outro.
- **Fim:** vencer a última missão conclui a campanha, e o relatório mostra o epílogo. Iniciar de novo recomeça da primeira missão. As marcas são zeradas; os recrutas liberados continuam.
- PP, NEX, patente, mortes e Reforços da Ordem funcionam como em qualquer missão.
- A validação (`Campanha.validar`) confere o próprio arquivo e também cada missão, pelas regras da comunidade. Ela acusa recruta desconhecido, marca que nenhuma missão anterior deixa, tipo de efeito inválido e marca ligada a uma pergunta que não existe.

### Recursos de missão usados pela campanha

As missões da campanha usam dois campos que também valem para as missões da comunidade:
- `cenas`: cenas de investigação próprias da missão;
- `caso.resumo`: o resumo do caso.

Os dois estão descritos em [04-missoes-da-comunidade.md](04-missoes-da-comunidade.md).

---

## "O Fundo da Represa" (campanha original)

> ⚠️ Spoilers da campanha.

História original, sem relação com a trama das campanhas transmitidas (veja [03-legal-e-conteudo.md](03-legal-e-conteudo.md)). As ameaças do livro entram só pelo id; os números estão em `rulesets/op2022/ameacas.json`. Lugares e pessoas são inventados.

**Premissa:** Em março de 1979, a Represa do Jequiri, no interior de Goiás, cobriu a cidade de São Bento do Vale. Os moradores foram para Nova São Bento, no alto do morro. Hoje, uma seca histórica faz a torre da antiga Igreja Matriz reaparecer no meio do lago, e pescadores começam a sumir.

**Segredo:** Sob a Matriz havia um poço de Morte. O padre Anselmo Viana, último pároco da cidade, prendeu a coisa ao instante em que a água chegou: a própria inundação era o selo. Os **Remanescentes**, antigos moradores e seus filhos, ouvem a Matriz e querem a cidade "respirando" de novo. Para isso, precisam esvaziar a represa.

**Personagens:**
- **Celina Prado:** coordenadora da Ordem em Goiânia.
- **Davi Moura:** pescador; vira recruta depois da missão 1.
- **Iracema Leme:** filha do organista da Matriz e líder dos Remanescentes; é o chefe da missão 2.
- **Otávio Sarmento:** engenheiro-chefe da usina; é o chefe da missão 3.
- **Lúcia Arantes:** engenheira da usina; vira recruta depois da missão 3.
- **A Matriz:** a igreja tomada pelo Lodo; é o chefe final.

| # | Missão | NEX | Mapa | Chefe (VD) | Cena própria | Marca que deixa → efeito |
|---|---|---|---|---|---|---|
| 1 | Nível Baixo | 5% | Margem da represa e colônia de pescadores (16×10) | Vulto Encharcado / o Afogado do Cais (25), agarra | Colônia de pescadores | *oque* → laços de sete nós: Membrana +10 na missão 2 e +5 na 4 |
| 2 | A Estrada que Desce | 10% | Estrada velha descendo pelo leito seco até a praça (18×11) | Mulher de Luto / Iracema, a Organista (30), conjura Morte | Cemitério de São Bento | *onde* → planta da usina: o objetivo da missão 3 começa revelado |
| 3 | As Comportas | 15% | Barragem, usina e Vila do Porto (20×12) | Homem de Capacete Branco / Sarmento, o Engenheiro (45), revólver e rituais | Casa de máquinas | *oque* → relatório de 1979: a Matriz começa com 20% menos PV |
| 4 | A Matriz | 20% | A cidade afogada inteira fora d'água (20×12) | A Igreja Viva / A Matriz Afogada (60): resistência a dano, maré de lodo em área e enigma ("como o padre a prendeu?") que tira a resistência e 4 de Defesa | Casa paroquial | — |

Todas as missões usam `"surgimentos": "proprios"`: quando a Membrana enfraquece, aparecem só os encontros da própria missão.

**Balanceamento (piloto automático, que vai direto ao covil sem investigar):**
- Missões 1 a 3: o grupo vence na primeira tentativa.
- Missão 4, com 4 agentes de NEX 20%: 6 vitórias em 8 seeds. Com dois Esqueletos de Lodo na escolta, foram 0 em 8, e por isso a escolta final ficou com os últimos Remanescentes.
- Campanha inteira (`test_campanha.gd`, seeds 1 e 2): as 4 missões vencidas em sequência.

Quem investiga ganha bônus: o chefe enfraquecido, a Membrana mais forte, as marcas para as missões seguintes e a DT do enigma final 5 menor.
