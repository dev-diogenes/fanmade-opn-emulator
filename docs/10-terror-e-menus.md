# Terror investigativo nos menus e na interface

> Status: **v0.1**, 20/10/2026. Continua o [09-identidade-visual-op.md](09-identidade-visual-op.md). Pedido do autor: sem 3D elaborado por enquanto; foco nos menus e no design, para o jogo parecer um terror sobrenatural investigativo.

## Princípio

O terror não vem de mais escuridão, e sim de **ritmo e de documentos**:
- cada tela "abre um arquivo";
- cada decisão importante é um bilhete;
- cada desfecho é um relatório carimbado;
- quando o paranormal aparece, a "fita" falha.

## O que entrou

| Peça | Onde | Como |
|---|---|---|
| **Estática entre as telas** (`Transicao`) | Toda cena nova | Estática de TV com o nome do arquivo datilografado ("OPERAÇÃO EM CAMPO", "CENA DE INVESTIGAÇÃO"…), que se desfaz em 0,5 s. O autoload `Jogo` cria a transição quando uma cena entra na raiz, sem mudar as 18 chamadas de troca de cena |
| **Datilografia** (`Tema.datilografar`) | Diálogos, briefing, relatórios e estática | O texto aparece letra a letra (até 1,6–1,8 s) |
| **Diálogo em papel** (`DialogoPapel`) | Nova carreira (título e Base), saídas da pausa | Substitui a janela padrão do Godot. A Base passou a **pedir confirmação** antes de apagar o save, o que antes não fazia |
| **Arquivo do caso** | Abertura de uma missão nova (mapa) | Briefing datilografado: resumo, objetivo e as perguntas em aberto, com "Iniciar operação" |
| **Relatório carimbado** (`RelatorioFim`) | Fim do mapa, do combate e da investigação | Folha datilografada com o resumo (turnos, Membrana, pistas, perguntas; rodadas e ameaças; pistas da cena). O carimbo bate por cima: "CASO ENCERRADO", "MISSÃO FRACASSADA", "VITÓRIA DA ORDEM", "OS AGENTES CAÍRAM", "CENA ENCERRADA" |
| **Pausa** (`MenuPausa`, Esc) | Mapa, combate e investigação | "Operação pausada", com Continuar e Ajustes de efeitos. No mapa também há Voltar à Base e Menu principal. No combate, Esc primeiro cancela o modo ou o bilhete. O jogo não congela: o online segue em lockstep |
| **Ajustes de efeitos** (`Preferencias.efeito`) | Pausa | Liga e desliga: granulação e vinheta, glitch de VHS e tremores, estática entre as telas. Ficam em `user://preferencias.json`. É a acessibilidade prometida no docs/08 |
| **Membrana que racha** (`BarraMembrana`) | Mapa e combate | Rachaduras escuras atravessam a barra conforme ela cai. Abaixo de 25, ficam vermelhas e tremem |
| **Falha no logo** | Título | A cada 4–9 s, cópias vermelha e ciano do logo saltam por um instante (desliga com o glitch) |

![Estática entre as telas](estatica.png)
![Arquivo do caso](briefing.png)
![Pausa com ajustes de efeitos](pausa.png)
![Relatório carimbado](relatorio_fim.png)

## Ainda não

- **Áudio:** sussurros, estática de rádio, máquina de escrever. Fica para a fase de áudio.
- **Tooltips do tutorial datilografados:** o tour já usa papel e moldura.
- **Combate online:** sair no meio do combate não é oferecido, porque o estado do combate não é salvo.
