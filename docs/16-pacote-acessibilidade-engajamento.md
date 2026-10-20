# Pacote de acessibilidade e engajamento

> Status: **v0.1**, 20/10/2026. Implementa o pacote recomendado no [15-critica-acessibilidade-engajamento.md](15-critica-acessibilidade-engajamento.md): **E1, E3, E5, A1, A2 e A3**.

| # | O quê | Como ficou |
|---|---|---|
| **E1** | Bilhete de desfecho | Depois da rolagem de um evento, um bilhete em papel mostra o **título do evento**, o selo SUCESSO ou FALHA, o **texto do que aconteceu** (datilografado) e os **efeitos em selos coloridos**: perdas em vermelho (−3 PV, −2 SAN), ganhos em verde (+2 PE), a Membrana e o mapa em roxo ou na cor do sinal. `Missao.resolver_evento` passou a devolver os efeitos **como foram aplicados**, com os valores já rolados |
| **E3** | Rastreador do caso | Painel "O caso" no mapa, abaixo do turno: as 3 perguntas com ●○ (pistas encontradas e que faltam), ✔ e a resposta quando resolvidas, e "Covil: desconhecido" ou "localizado no mapa" |
| **E5** | Base abre na aba Missão | O grupo e o "Iniciar missão" ficam à vista. Se algum agente tiver escolha de NEX pendente, a Base abre na aba Agentes, nele |
| **A1** | Escala da interface | "Tamanho da interface" de 80% a 150% (pausa e Base, aba Jogadores), guardado nas preferências. A escala **não passa do que cabe na janela** (o HUD foi desenhado para 1280 × 720 lógicos): em 1280 × 720 fica em 100%; num monitor 1080p dá para usar até ~150%. Textos pequenos subiram: dicas e atalhos das cartas de 12 para 13 px, rótulos dos retratos de 12 para 13 px, legendas das fotos de 10 para 11 px. O espaço das cartas não permite chegar a 14 px; a escala compensa |
| **A2** | Motivo dos desabilitados e contraste | Tooltip com o **motivo** em todo botão bloqueado no mapa ("Só dá para descansar numa vila…", "A ação deste turno já foi usada", "Resolva o evento primeiro") e nas cartas de combate ("Bloqueado: sem ação padrão neste turno"). As cartas bloqueadas ganham um **cadeado desenhado**. Contraste: o texto desabilitado foi de 2,5:1 para **5:1**; no papel, de 2,0:1 para **4,9:1**; a borda dos campos foi de 2,2:1 para **3,8:1** (WCAG 1.4.11) |
| **A3** | Velocidade do texto e da rolagem | **Texto:** devagar, normal ou instantâneo (vale para toda a datilografia). **Resultados:** rápidos, normais ou **até clicar**: a rolagem central e o desfecho ficam na tela até um clique (ou Enter/Esc) |

O menu da pausa agora se chama **Ajustes** e reúne leitura, escala, volume, câmera e efeitos.

![Desfecho e rastreador do caso](desfecho_16.png)
![Ajustes](ajustes_16.png)
![Cartas com cadeado](cartas_16.png)

## Próxima rodada sugerida (docs/15)

- **E2:** criação de agente em dossiê.
- **E6:** sanidade com consequência visual.
- **A4:** remapeamento de teclas e folha de atalhos.
- **A5:** modo de fotossensibilidade.
- **A6:** paleta para daltonismo.
