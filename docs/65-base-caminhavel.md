# A Base como lugar: o bar caminhável

> Status: **v0.1**, 22/10/2026. Pedido do dono do projeto: a aba Base deve ser como a tela de investigação e a sala de Transcender. O agente anda com WASD, entra no bar de fachada, e cada seção leva a uma opção do menu, que continua no topo. A construção segue a crítica de design feita antes (skill design-critique), resumida abaixo.

## A crítica (resumo)

| Achado | Severidade | Como ficou |
|---|---|---|
| Nove cartões iguais: a Central (o próximo passo) pesava igual à Enfermaria (informativa) | Moderada | A Central fica no meio do salão, mais iluminada, com os monitores acesos |
| Seis cartões repetiam as abas do topo | Moderada | A seção é o lugar físico da aba: entrar nela abre a aba |
| O laboratório e a contenção, os únicos serviços, ficavam escondidos | Crítica | Viraram estações, com o bilhete do serviço por cima da cena |
| Só o Tab navegava | Moderada | WASD ou setas para andar, E ou Enter para entrar, 1 a 9 para ir direto a cada seção |
| A Base era a única tela de "lugar" em papel | Consistência | Mesmo rig de câmera, mesma figura do agente e mesmo aviso de proximidade da investigação e do Transcender |

## O que mudou

A aba **Base** é agora uma sala 3D: um bar velho de bairro na frente e, depois da meia parede, os fundos da Ordem.
- **Quem anda:** o agente escolhido nas outras abas.
- **A seção ao alcance:** a placa dela acende, a luz sobe, e o aviso embaixo diz "E · Entrar: Arsenal", com uma linha sobre o que há ali.

| Seção | Onde | Leva a |
|---|---|---|
| Bar de fachada (balcão, garrafas, banquetas) | frente, à direita | aba Jogadores |
| Escritório (mesa, arquivos, quadro de fios vermelhos) | frente, à esquerda | aba Agentes |
| Central de sinais (mapa aberto, três monitores, telefone) | centro | aba Missão |
| Balcão de equipamentos (painel de armas) | parede da esquerda | aba Arsenal |
| Enfermaria (maca e cortina) | parede da direita | bilhete com o que a volta cura |
| Laboratório (bancada, tubos, microscópio) | fundos, à esquerda | bilhete do laboratório (docs/63) |
| Memorial (fotos e velas) | fundos | aba Memorial |
| Sala de ocultismo (sigilo no chão, velas) | fundos | bilhete; Transcender, se alguém tem escolha de NEX |
| Contenção (grades, uma vela) | fundos, à direita | bilhete da contenção (docs/63) |

- **O bilhete do serviço:** abre do lado oposto ao do agente, para não cobrir a seção. Fecha com Esc.
- **O menu de abas:** continua no topo, como estava.
- **A abertura:** a Base ainda abre na aba Missão.

![O salão da Base](b65_central.png)

![A contenção, com o bilhete](b65_contencao.png)

## O que fica para depois

- **Animar as seções:** o telefone tocando quando chega sinal novo, a vela da contenção tremendo, o fliperama do bar.
- **Os outros agentes na Base,** parados nas seções (os que não estão sendo usados).
- **A Base como primeira tela** depois de cada missão, em vez da aba Missão.

## Onde está

- **Tela:**
  - `SalaBase` (novo): o salão, as nove seções, `mover`, `estacao_proxima`, `ir_para` e `trocar_agente`;
  - a Base: `_construir_sala_base`, `_entrar_estacao`, `_abrir_servico` e `_fechar_servico`, mais o andar em `_process` e as teclas em `_unhandled_input`.

## Testes

Total: **667**.
- **`test_contencao.gd`:**
  - a Base tem a sala com as nove seções;
  - o balcão leva ao Arsenal;
  - o laboratório abre o bilhete, e o bilhete fecha.
