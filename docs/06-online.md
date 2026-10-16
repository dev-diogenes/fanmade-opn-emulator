# Jogar online

Até 4 jogadores, cada um no seu computador. Uma pessoa **hospeda** com a carreira dela; as outras **entram** e jogam a vez dos agentes que o host der a elas. A arquitetura está no [ADR 0007](adr/0007-online-e-mestre.md).

## Hospedar

1. Na Base, em **Online**, deixe a porta (7777) e clique em **Hospedar**. A Base mostra os endereços desta máquina.
2. Passe o endereço e a porta para quem vai jogar.
3. Quem entra aparece em **Jogadores** como "online: nome".
4. No **Grupo da missão**, escolha o dono de cada agente.
5. Comece a missão como sempre. Os outros entram no mapa junto com você.
6. **Parar de hospedar** desconecta todo mundo.

A carreira é do host e só ele salva. Recrutar, requisitar e as escolhas de NEX acontecem na Base do host.

## Entrar

1. Na Base, em **Online**, escreva o IP do host e o seu nome e clique em **Entrar**. A porta é a do campo ao lado de Hospedar.
2. Você vai para o **saguão**. Lá aparecem os jogadores, os agentes da carreira do host (os seus vêm marcados) e a última missão.
3. Quando o host começa uma missão, o jogo vai sozinho para o mapa.
4. Na vez de um agente seu, você joga. Na dos outros, você assiste: a faixa amarela diz de quem é a vez.
5. **Sair da sessão** volta para a Base com a **sua** carreira, que ficou guardada e não muda.

## Modo Mestre

Na Base, em **Jogadores**, escolha quem é o **Mestre**. Pode ser você (host), alguém online ou alguém no mesmo PC.

- **Na vez das ameaças, o jogo espera o mestre** em todas as máquinas. Na arena, ele tem uma barra própria:
  - **Mover**;
  - **Atacar**, com o ataque da ficha escolhido;
  - **Usar** uma habilidade;
  - **IA joga o turno**;
  - **Encerrar turno**.
- **No mapa,** o botão **Painel do mestre** mostra as respostas do caso (quem, o quê, onde) e deixa:
  - narrar para o grupo (o texto aparece no registro de todos);
  - fortalecer ou enfraquecer a Membrana;
  - com "Clique no mapa escolhe o hex", pôr um encontro ou evento, revelar em volta ou limpar o hex;
  - curar, ferir ou mexer na Sanidade de um agente.
- **O mestre vê o mapa inteiro.** Os jogadores continuam com a névoa.
- **Se o mestre sair,** o host assume as ameaças, e a partida segue.
- **Sem mestre,** a IA joga as ameaças, como sempre.

O mestre pode usar as missões da comunidade como roteiro: o arquivo tem o briefing, o caso e os textos dos eventos ([formato](04-missoes-da-comunidade.md)).

## Rede

- **Mesma rede (LAN):** use o IP local do host (por exemplo, 192.168.0.10).
- **Pela internet:** o host precisa liberar a porta UDP no roteador (redirecionamento de porta) e passar o IP público. Outra opção é usar uma VPN de jogos, como ZeroTier ou Radmin VPN, e o IP que ela der.
- O firewall do Windows pode perguntar se o Godot pode usar a rede. Permita na rede privada.

## Como funciona (resumo)

- O jogo é igual em todas as máquinas: todas partem do mesmo estado e aplicam as mesmas decisões, na ordem que o host define. A IA das ameaças roda em cada máquina e chega ao mesmo resultado, porque os dados têm a mesma seed.
- Só viajam as decisões dos jogadores, que são pequenas. A carreira inteira viaja apenas quando alguém entra ou se perde.
- Cada decisão leva uma conferência (checksum). Se uma máquina sair de sincronia, ela pede o estado ao host e se refaz sozinha.
- Se um jogador cair, os agentes dele voltam para o Jogador 1, no host. Se o host cair, cada um volta para a própria Base.

## Teste automático com dois processos

`tools/teste_online.sh [semente] [tarde|mestre]` abre um host e um cliente sem janela. Os dois jogam uma missão pelas telas, cada um na vez dos próprios agentes, e o teste confere que terminam com o mesmo estado:

```bash
GODOT=/caminho/para/Godot_console.exe tools/teste_online.sh 7
```

- Com `tarde`, o cliente entra no meio da missão.
- Com `mestre`, o host é o mestre (joga as ameaças, narra e mexe na Membrana) e o cliente joga todos os agentes.
