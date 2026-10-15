# Brainstorm de Design: Ordem Paranormal × For The King

> Cada tópico tem uma **decisão** (✅), uma **proposta** (💡, aguardando aprovação) ou uma **dúvida** (❓).
> As páginas citadas são do livro básico de 2022 (v1.3).

## 1. Teste = slots de d20 ✅

No OP (p.19), você rola 1d20 por ponto no atributo-base, vale o maior resultado e soma o bônus da perícia treinada. Esse número é comparado à DT.

**Tradução para FTK:** cada ponto de atributo vira **um slot**, e cada slot mostra um d20 rolando. A UI mostra lado a lado:

```
[d20][d20][d20]  ← AGI 3
maior: 14  +5 (Furtividade treinada)  = 19   vs  DT 20  ✗
```

- Com **atributo 0**, aparecem 2 slots vermelhos e vale o **menor**.
- **Por que não porcentagem?** O fã de OP já pensa em d20 e DT. Antes de rolar, a UI pode mostrar a "chance de passar" calculada como dica.

## 2. PE = Foco ✅ (como gastar 💡)

No FTK, o Foco garante sucesso em um slot. No OP, o PE é o recurso das habilidades e tem um **limite por turno** de acordo com o NEX (p.33).

| Opção | Efeito de gastar PE num teste | Prós | Contras |
|---|---|---|---|
| **A. +1 slot** 💡 | 1 PE adiciona um d20 extra ao teste | Usa a mecânica nativa ("mais dados"), escala bem e dá tensão | Atributo alto fica ainda melhor |
| B. Travar 1 slot | O slot vira "acerto garantido", como no FTK | Idêntico ao FTK | Não tem equivalente no OP. Com d20, "garantido" seria um 20 natural, forte demais |
| C. Rerrolar | 1 PE rerrola o pior slot | Simples | Menos dramático |

**Proposta:** opção **A**, respeitando o **limite de PE por turno** do NEX. As habilidades de classe continuam gastando PE normalmente, então o jogador escolhe entre "forçar este teste" e "guardar para a habilidade". ❓ O teste de Esforço precisa ser validado no playtest.

## 3. Investigação: zoom aproximado com a visão reduzida ✅ (formato 💡)

O livro já traz uma estrutura de investigação completa (p.89–91), que encaixa muito bem num jogo:

| Conceito do livro | No jogo |
|---|---|
| **Ficha de Investigação** do grupo: resumo, objetivo, perguntas | Diário compartilhado na UI, com as perguntas do caso |
| **Pista básica** no início de cada cena | Revelada automaticamente quando a cena começa |
| **Pistas complementares** | *Hotspots* no cenário |
| Ações: Procurar Pistas, Facilitar, Usar Habilidade/Item, Ajudar | Menu de ação por agente em cada rodada |
| DT 15 / 20 / 25+ conforme a abordagem | Cada hotspot aceita perícias diferentes, com DTs diferentes (Tecnologia no PC: DT 15; Percepção "genérica": DT 25) |
| **Urgência** (Muito baixo 6 → Muito alto 2 rodadas) | Contador de rodadas na tela. A cada 3 falhas, perde 1 rodada (regra opcional do livro) |
| Penalidade ao estourar a urgência | O chefe ganha PV, chegam reforços, o grupo não descansa |
| Conclusão do Caso → Prestígio | Tela de relatório. As respostas certas rendem PP |

**Câmera:** no mapa, a visão é aberta e isométrica, como no FTK. Ao entrar num hex de investigação, a câmera aproxima e o raio de visão encolhe (escuridão, lanterna, névoa). Os hotspots só aparecem dentro do campo de visão. Facilitar Investigação pode **aumentar o raio**, por exemplo acendendo a luz ou abrindo janelas, o que traduz a regra de "+2 para os aliados" num efeito visível.

💡 **A V1 também tem investigação**, numa versão simplificada: o livro de 2022 já a prevê. A V2 aprofunda o sistema (interrogatórios, quadro de conexões, falsas pistas).

## 4. Progressão: NEX ≠ nível ✅

O livro já faz essa separação, do jeito que você descreveu:

| Eixo | O que representa | Fonte | Como sobe | Efeito no jogo |
|---|---|---|---|---|
| **NEX** | Poder individual e exposição ao Outro Lado | p.33 | +5% por missão concluída | PV, PE e SAN; habilidades de classe; limite de PE |
| **Patente**, via **Pontos de Prestígio (PP)** | Posição na Ordem: a recompensa dada pela Ordem | p.61 | PP por missão, conforme a eficiência (tabela 3.2). **Pode cair** | Quantos itens de cada categoria a Ordem libera por missão, e o limite de crédito |

**No loop FTK:** o NEX faz o papel do "nível de personagem" do FTK, e a **Patente substitui ouro e loja**. Na Base da Ordem, antes da missão, o grupo requisita equipamento dentro do limite da patente. Ser rebaixado devolve itens, o que dá peso real a falhar uma missão.

💡 Recrutas (patente mais baixa) abrem o jogo e servem de tutorial.
❓ Como o NEX 99% e a Desconjuração (p.33) entram no jogo? Podem ser um "fim de carreira" ou um evento raro do sandbox.

## 5. Medidor de Caos → Membrana ✅

O medidor de Caos do FTK vira o **estado da Membrana** na região da missão (cap. 5, p.105).

- Ela enfraquece com o tempo (turnos no mapa), com rituais conjurados, com mortes de civis e com investigações que estouram a urgência.
- Ela se fortalece quando o grupo destrói itens amaldiçoados ou fecha portais.
- Em cada limiar, aparecem ameaças mais fortes, eventos do Outro Lado e manifestações do elemento **Medo**.

## 6. Grupo e combate ✅

- **Até 4 agentes** e **combate em grade com posicionamento**, como no FTK II.
- Ordem por Iniciativa, ações padrão, de movimento e livre, e reações, conforme o cap. 4 (p.92–99).
- PV 0 leva a *morrendo*. SAN 0 leva a *enlouquecendo* (p.98).
- **Rituais = habilidades** ✅, com custo em PE, elemento, componentes e risco de dano à Sanidade.

## 7. Missões procedurais 💡

A geração segue a **estrutura do Gerador de Missões** (p.165–167): `Sujeito + Ação + Local + Amigo + Objeto + Evento`.

- **Local** escolhe o bioma ou mapa. Habitado ou abandonado muda os encontros.
- **Sujeito + Ação** definem o chefe e o objetivo.
- **Amigo** é um NPC aliado que pode ser revelado como vilão (Evento 5).
- **Evento** é a reviravolta no meio ou no fim da missão.
- Uma **seed** reproduzível permite compartilhar missões geradas.

Como as **tabelas** do livro são conteúdo do livro, usamos a estrutura e escrevemos **tabelas próprias**. Veja o documento legal.

## 8. Missões da comunidade e Modo Mestre 💡

- **Formato:** um pacote (pasta zip) com `mission.json` (metadados, ficha de investigação, cenas, encontros, pistas) e, opcionalmente, assets próprios. O formato é **versionado** (`format_version`) e declara o **ruleset** (`op2022`, `op-v2`).
- **Sem mestre**, a IA arbitra: DTs e revelações vêm dos dados da missão.
- **Com mestre**, um jogador tem uma "ficha do mestre" com todas as pistas e decide DT, aparições, NPCs e quando liberar cada pista. Esse modo exige rede, e por isso fica na fase posterior.
- **Distribuição:** pasta local primeiro, Steam Workshop depois.

## 9. Ferramentas: Godot e o Tabletop Simulator ✅

Os projetos tabletop do universo OP costumam usar o **Tabletop Simulator**, um programa feito em Unity cujos mods são escritos em Lua. Isso **não nos obriga a usar Unity**: não reaproveitaríamos código nem assets de lá, por questões de licença e de técnica. Decisão completa no [ADR 0001](adr/0001-engine-godot.md).

## Questões em aberto

1. ❓ Quais itens e categorias a Patente libera em cada nível na V1? Implementar a tabela 3.1 inteira ou simplificar?
2. ❓ Os agentes morrem de vez? (FTK tem "vidas" do grupo.) Proposta: um contador de "reforços da Ordem" por missão.
3. ❓ Até quanto o tempo de investigação (rodadas) conversa com o tempo do mapa (turnos)?
4. ❓ O Medo entra como elemento jogável na V1 ou só como ameaça e evento?
5. ❓ Quais regras opcionais do cap. 6 ativar por padrão (Lesões, Contagem de Munição, Loucura Não Letal)?
6. ❓ O que muda na V2? Fica pendente até termos as regras novas.
