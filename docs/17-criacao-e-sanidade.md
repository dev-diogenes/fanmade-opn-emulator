# Criação de agente e sanidade com consequência

> Status: **v0.1**, 20/10/2026. Implementa o **E2** e o **E6** do [15-critica-acessibilidade-engajamento.md](15-critica-acessibilidade-engajamento.md).

## E2: criação de agente em dossiê

Na Base, aba Agentes: **"+ Novo agente (criar ficha)"**. Abre uma pasta com seis abas em papel:

| Aba | O que se escolhe |
|---|---|
| **Identidade** | Nome e **origem**: as 26 origens do ruleset. O tooltip mostra as perícias e o poder; o rodapé descreve o poder da escolhida |
| **Classe** | Combatente, Especialista ou Ocultista, com a descrição e as bases de PV, PE e SAN |
| **Atributos** | − e + para cada atributo, com os pontos restantes e o que cada atributo faz (todos começam em 1, 4 pontos, máximo 3, um pode ir a 0 para dar +1 ponto) |
| **Perícias** | As da origem e da classe já marcadas; as escolhas da classe (Luta ou Pontaria…); as **livres** (base da classe + Intelecto, com contagem do que falta); a escolha da origem quando existe (Amnésico); o **Perito** para o Especialista |
| **Rituais** | Ocultista: 3 rituais de 1º círculo (os sem efeito no jogo marcados com *). Para as outras classes, a aba explica que elas aprendem rituais mais tarde |
| **Revisão** | A ficha montada (a mesma da tecla F) e o equipamento inicial, ou a lista do que falta |

- **Validação ao vivo:** quem valida a ficha é o `CriacaoAgente`, a mesma regra dos recrutas e das missões da comunidade. O rodapé mostra "Faltam N ajustes: …", e **"Assinar e arquivar"** só libera sem erros (o motivo aparece no tooltip).
- **Arquivamento:** `Carreira.recrutar_ficha` dá um id ao agente e o **kit inicial da classe** (o do recruta pronto da mesma classe). O agente entra no arquivo, com o som do carimbo.
- **Regras:** nome repetido (no arquivo ou no memorial), arquivo cheio ou missão em andamento impedem a criação.

![Identidade](criacao_identidade_17.png)
![Atributos](criacao_atributos_17.png)
![Perícias](criacao_pericias_17.png)

## E6: sanidade com consequência visual

Quando o **agente da vez** está **perturbado** (SAN abaixo da metade, a condição das regras), a cena enlouquece com ele. A intensidade vai de 0 (SAN na metade) a 1 (SAN zerada, enlouquecendo ou insano) e entra e sai devagar.

| Efeito | Como |
|---|---|
| **A imagem respira e ondula** | Shader do véu (`loucura`): ondulação, "respiração" (zoom leve), uma **segunda imagem fantasma** deslocada e um pulso avermelhado |
| **Sussurros** | O som ambiente de sussurros sobe com a loucura |
| **Vultos** | De tempos em tempos, um vulto encapuzado e escuro aparece perto do grupo, olhando para ele, e some em menos de um segundo (com um estalo de fita) |
| **Frases** | Frases soltas surgem datilografadas no meio da tela e se apagam ("Eles sabem o seu nome.", "Olhe para trás.", "A Membrana está fina aqui."…). São 10 frases, todas originais |
| **Retrato** | O retrato do agente **treme** de leve, o nome fica vermelho e o rótulo vira **SAN!**, para não depender só da cor. O tooltip explica |

- **Onde vale:** no mapa, no combate e na investigação (`Alucinacoes`), acompanhando o agente da vez.
- **Só apresentação:** as regras de sanidade não mudam.
- **Acessibilidade:** com "Glitch de VHS e tremores" desligado nos Ajustes, a ondulação cai para 25% e os estalos somem. Os vultos e as frases continuam, porque são o conteúdo.

![Loucura no mapa](loucura_17.png)
