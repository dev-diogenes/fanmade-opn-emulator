# Gente de hoje: agentes, cultistas, polícia, bichos e criaturas

> Status: **v0.1**, 22/10/2026. Quarta fase do plano. Pedido do autor: "Ordem é um RPG brasileiro, contemporâneo… não existe relação com algo medieval". É o 🔴 de identidade de docs/51.

## O problema

As miniaturas eram do pacote **KayKit Adventurers**, de fantasia medieval: cavaleiro de elmo, ranger de capuz, maga de chapéu pontudo e bárbaro. Os cultistas e até o **cão de guarda** apareciam como gente encapuzada em vermelho, e as criaturas eram esqueletos com elmo de chifres. Num jogo de Ordem Paranormal, a primeira coisa que um fã nota é isso.

## A solução, sem baixar nada

Os quatro modelos da KayKit dividem o **mesmo esqueleto** (com ossos de cabeça, peito e mãos) e **76 animações**. E o que é de fantasia está em **malhas separadas**: elmo, chapéu, capa, escudos e armas. Então:

1. **Tirar a fantasia:** elmo, chapéu, capa (menos o sobretudo), escudos e armas somem.
2. **Vestir com roupa de hoje** (`roupa_contemporanea.gdshader`). A textura da KayKit é uma paleta de gradientes, e o shader troca cada cor pelo seu papel, mantendo o gradiente:
   - o **tom de pele** vira um de seis, do mais claro ao mais escuro, sorteado pelo nome do agente;
   - os **cinzas claros** (a armadura, a túnica) viram a **roupa de cima**;
   - os **escuros** viram a **calça**;
   - na cabeça, os cinzas viram o **cabelo e a barba**, numa cor também sorteada;
   - o resto (couro, botões) fica, um pouco dessaturado.

   Um brilho leve e um contorno de luz evitam que a miniatura suma na noite do mapa.
3. **Acessórios presos aos ossos**, que acompanham as animações.

### Os quatro visuais (as chaves antigas de aparência continuam valendo)

| Aparência (era) | Agora | Roupa | Acessório |
|---|---|---|---|
| Armadura | **Colete tático** | jaqueta grafite, calça cargo oliva | colete com bolsos |
| Capuz | **Moletom** | moletom verde, jeans | mochila. O rosto vem de outro modelo, porque o capuz original traz um pano no rosto, que agora fica para os cultistas |
| Chapéu | **Sobretudo** | casaco marrom (a capa do mago vira a aba), calça escura | bolsa a tiracolo |
| Rústico | **Jaqueta de couro** | jaqueta, jeans | boné |

**Na mão, pela classe:**
- combatente: pistola;
- especialista: lanterna, com a ponta acesa;
- ocultista: caderno;
- mundano: celular.

### As ameaças que são gente ou bicho

| Quem | Como aparece |
|---|---|
| **Cultistas** (iniciado, investido, líder) | túnica vinho, o capuz, e **o pano preto recortado nos olhos**, com dois pontos vermelhos. É o indício "Esconde o rosto" dos casos |
| **Polícia** | farda azul, quepe e pistola |
| **Crime** (bandido, capanga, assassino, mercenários) | moletom cinza, jeans e celular |
| **Bichos** (cão, javaporco, onça, sucuri, jacaré, enxames) | **figuras de bicho por código**: quatro patas, cabeça, focinho, orelhas, rabo, as pintas da onça, a cobra em gomos, o enxame em pontos. Antes eram gente encapuzada |

### Criaturas

- **Sem elmo de chifres.**
- **Silhueta do elemento, pela wiki:**
  - Sangue: baixa e larga;
  - Morte: alta e magra;
  - Conhecimento: ereta, com uma máscara dourada;
  - Energia e Medo ficam com a cor e a luz de docs/54.

![Vitrine: na frente, os agentes; no meio, culto, polícia, crime e bichos; atrás, as criaturas por elemento](vitrine55.png)

![Um combate com as figuras novas](d55_combate.png)

## Limites

- **O rosto é o da KayKit:** só há quatro cabeças (três de homem e uma de mulher). A variedade vem da pele, do cabelo e da roupa.
  - **Próximo passo possível:** escolher o rosto na criação e trocar a cabeça como no moletom.
  - **Para ir além:** um pacote CC0 de pessoas modernas (por exemplo, da Quaternius), com sua confirmação do download.
- **De cima, na câmera do mapa, o cabelo domina.** A base colorida e o brilho seguram a leitura, mas jogue e diga se quer mais contraste.
- **Os esqueletos continuam esqueletos.** Criaturas de verdade por elemento pedem modelos próprios.

## Onde está

- **`Pecas`:**
  - `agente` (com `semente`), `vestir` e `trocar_cabeca`;
  - os acessórios: `_acessorio` e `_na_mao`;
  - as pessoas e os bichos: `pessoa`, `bicho` e `visual_de_pessoa`;
  - a silhueta das criaturas: `_silhueta_do_elemento`;
  - as tabelas: `VISUAL_CONTEMPORANEO`, `PELES`, `CABELOS` e `ITEM_POR_CLASSE`.
- **Shader:** `assets/shaders/roupa_contemporanea.gdshader`.
- **Fotos:** a foto do agente (criação, ficha e cerimônia de NEX) usa a semente do nome.

## Testes

Total: **602**. Arquivo novo `test_figuras.gd`:
- **Agentes:**
  - sem elmo, chapéu e capa;
  - a roupa vem do shader;
  - a capa do mago fica;
  - o moletom ganha rosto, mochila e lanterna presas aos ossos;
  - o tom de pele vem da semente.
- **Ameaças:**
  - quem é quem: culto, polícia, bicho e crime;
  - o cão é um bicho;
  - o cultista tem o pano nos olhos;
  - as criaturas não têm elmo.
