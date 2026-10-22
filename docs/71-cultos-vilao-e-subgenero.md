# Cultos, o vilão que liga os casos e o subgênero da missão

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: "foque em Cultos e campanhas: um gerador de cultos em cinco eixos, com um vilão que liga os casos, e um modificador de subgênero por missão" (OR6 e OR7 do relatório). A decisão de estrutura está no ADR 0014.
>
> **Não é regra do livro.** É lore da wiki transformada em sistema. Nomes de cultos, de empresas e os textos são nossos: nenhum culto canônico aparece no jogo.

## Os cultos (OR6)

Todo caso procedural agora tem um culto por trás, sorteado da semente do caso:

| Eixo | Exemplos | O que faz no jogo |
|---|---|---|
| Elemento | o do caso | o nome e o sinal visual combinam com ele |
| Fachada | academia de bairro, igreja num galpão, rádio comunitária, cooperativa rural… (10) | aparece no quadro e nos recortes |
| Estrutura | células sem líder, hierarquia, mente coletiva mascarada, família, empresa | quanto o cultista preso conta na contenção (docs/63): células −1 segredo, mente coletiva −2, hierarquia e empresa +1 |
| Método | manda na polícia, transmite os rituais, sacrifícios, faz gente sumir, festas | autoridades: a credencial se queima um uso antes; transmissões: Membrana −6; festas: Membrana −3; sacrifícios: chefe +10% de PV; sumiços: as testemunhas somem uma noite em duas, e não em três |
| Sinal visual | arame farpado nos postes, relógios ao contrário, sigilos dourados nos muros… (3 por elemento) | aparece no quadro do caso desde o começo |

**O nome** junta um prefixo e um núcleo do elemento: "Irmandade do Relógio Parado", "Coletivo da Faísca".

**No quadro do caso:** o bilhete do objetivo ganha uma linha, "Nos muros e nas portas: …", com o sinal visual. Quando a ficha responde **quem**, ganha outra com o nome, a fachada e a estrutura do culto.

## O vilão (OR6)

Cada carreira tem uma **empresa de fachada** que patrocina cultos isolados: "Construtora Bezerra & Filhos", "Fundação Monte Azul".

1. **Os casos ligados:** metade das missões, pela semente, tem o culto ligado a ela. Não há aviso antes.
2. **Os recortes:** fechar um caso ligado rende um **recorte de jornal** no quadro do escritório, por exemplo: "Nota fiscal liga uma rádio comunitária a uma conta da Fundação Monte Azul". O relatório da missão conta o recorte.
3. **A sede:** com **três recortes**, a Base mostra um **quarto sinal**, a sede da empresa, com confiança "certeza":
   - o chefe tem +25% de PV;
   - a Membrana começa 5 mais fraca.
4. **A queda:** vencer e fechar esse caso derruba o vilão e rende +5 PP. Os recortes saem do quadro, e um vilão novo assume o próximo arco.

Na aba Missão, embaixo dos sinais, o **Quadro do escritório** mostra os recortes como papéis de jornal e diz quantos faltam.

![A aba Missão com o sinal da sede do vilão](i71_missao.png)

## O subgênero (OR7)

Cada sinal da rede traz um subgênero, mostrado no cartão do sinal, na dica e no briefing:

| Subgênero | Peso | Efeito |
|---|---|---|
| Investigação | 50% | nenhum: o caso de sempre |
| Perseguição | 20% | algo caça o grupo. A noite dura 3 turnos (e não 2), a caça enxerga a 9 hexes (e não 6), o rastro dura 3 turnos e a caça não descansa depois de uma luta |
| Isolados | 15% | cada turno é um dia inteiro (dia e noite se alternam a cada turno), e o interlúdio dá uma ação por agente (e não duas) |
| Transmissão | 15% | alguém transmite o ritual: a Membrana cai mais 1 a cada turno do mundo |

**Onde vale:**
- **No mapa:** o subgênero só vale na missão do sinal, e volta a valer ao carregar o save. As outras missões e o `mapa.json` não mudam.
- **No registro:** o registro da missão abre com o nome e o texto do subgênero.

## Medido

O playtest automático tem 10 sementes por perfil, sem sinal, e por isso não sorteia subgênero:

| Perfil | Antes | Agora, com o culto |
|---|---|---|
| Investigador | vitória 1,0 em 6,9 turnos (2,5 combates) | vitória 1,0 em 6,8 turnos (2,3 combates) |
| Pressa | vitória 0,8 em 11,5 turnos (3,1 combates) | vitória 0,8 em 10,5 turnos (2,8 combates) |

Numa sonda com o perfil investigador e 5 sementes por subgênero:
- **Perseguição:** vitória 1,0 em 6,0 turnos;
- **Isolados:** vitória 1,0 em 6,6 turnos;
- **Transmissão:** vitória 1,0 em 6,2 turnos.

Nenhum erro. A Perseguição ainda não ficou mais difícil para quem joga com cuidado: vale um playtest próprio.

## O que fica para depois

- **Inimigos:** a estrutura do culto ainda não muda os cultistas dos encontros (quantos, de que tipo).
- **Investigação:**
  - o sinal visual podia virar pista com Ocultismo (EL5 do relatório: o símbolo do culto com um anel traduzível);
  - os recortes podiam aparecer também nas cenas, como notícia no celular de uma testemunha.
- **Perseguição:** um caçador único e persistente, que volta depois de derrotado.
- **Campanha:** a campanha escrita à mão não tem culto sorteado. Um culto autoral por campanha seria outro passo.

## Onde está

- **Dados:** `data/jogo/cultos.json` (eixos, nomes, vilão, recortes) e `data/jogo/subgeneros.json`.
- **Regra:**
  - `Culto` (novo): `gerar`, `resumo`, `vilao`, `recorte`, `liga_ao_vilao`, `subgenero` e `mesclar`;
  - `Caso.culto`;
  - `Missao`: `aplicar_efeitos_do_culto`, `_aplicar_culto_e_subgenero` e `subgenero`; a Membrana por turno da Transmissão; o sumiço das testemunhas;
  - `Carreira`: `vilao`, `recortes`, `_ligar_ao_vilao`, `vilao_encontrado`, `sinal_do_vilao` e `_fechar_vilao`;
  - `Sinais.de` traz o subgênero;
  - a credencial guarda o próprio `limite`.
- **Tela:**
  - Base: o quarto sinal, a dica do subgênero, o briefing e o Quadro do escritório;
  - mapa: o quadro do caso com o sinal visual e o culto.

## Testes

Total: **744**. Arquivo novo, `test_cultos.gd`:
- **O culto:** tem os cinco eixos, sai da semente e volta igual do save (e de um save antigo).
- **Os efeitos:** o método mexe na Membrana, na credencial e no chefe só nas missões da carreira, e a estrutura muda o que o preso conta.
- **O subgênero:** vale só na missão, sem mudar o `mapa.json`, e o sinal o traz.
- **O vilão:** três casos ligados rendem três recortes, a sede aparece e cai, e o vilão é salvo. A missão sem ligação não rende recorte.

O teste da contenção passou a considerar a estrutura do culto.
