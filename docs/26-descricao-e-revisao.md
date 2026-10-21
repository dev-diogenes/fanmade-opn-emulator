# Descrição do agente e revisão com a ficha nova

> Status: **v0.1**, 21/10/2026. Continua o [25-ficha-no-formato-oficial.md](25-ficha-no-formato-oficial.md).

## Descrição

A ficha oficial tem um quadro **Descrição** com aparência, personalidade, histórico e objetivo. O jogo já tinha a aparência (a foto 3x4, docs/19). Agora tem os outros três:

- **No agente:** `Agente.personalidade`, `historico` e `objetivo`. É texto livre, só apresentação, e fica salvo no save. Saves antigos ficam em branco.
- **No dossiê de criação:** nova aba **Descrição**, entre Rituais e Revisão.
  - **Campos:** Personalidade e Objetivo têm uma linha; Histórico tem um campo maior.
  - **Exemplos:** cada campo traz uma sugestão de exemplo. Os campos são opcionais e não bloqueiam a assinatura.
  - **Troca de aba:** o texto sobrevive, porque os campos são reaproveitados, como o do nome.
- **Limites:** 140 caracteres (personalidade e objetivo) e 600 (histórico). `Carreira.recrutar_ficha` apara os espaços nas pontas e corta no limite.
- **Na ficha (página Habilidades e inventário):** cada campo preenchido aparece com o rótulo preto, ao lado da foto. Campo em branco não aparece.

![Aba Descrição](desc26_descricao.png)
![Descrição na ficha](desc26_p2.png)

## Revisão com a página 1 da ficha nova

A revisão do dossiê mostrava a ficha em texto corrido. Agora mostra a **página 1 da ficha nova** (`FichaAgente.pagina_um`), como o agente vai ficar:

- pentágono, PV/PE/SAN, Defesa com a conta e todas as perícias;
- **o equipamento inicial da classe já entra na prévia:** os ataques e a Defesa saem como na ficha de verdade;
- **a aparência escolhida** na foto;
- embaixo, o equipamento inicial em texto e o resumo da descrição (ou "em branco").

![Revisão](desc26_revisao.png)

## Testes

O `tests/unit/test_descricao.gd` tem 3 testes:

- **Agente e save:** a descrição chega ao agente e ao save, com espaços aparados, limite e saves antigos.
- **Dossiê:** as sete abas; o campo escreve na ficha e sobrevive à troca de aba; a revisão tem o pentágono e a tabela de ataques.
- **Ficha:** a página 2 mostra o que foi escrito e esconde o que ficou em branco.

Total: **483 testes**.

## Pendências

- **Edição depois:** a descrição só é escrita na criação. Editar depois, na Base, seria um botão "Editar descrição" na página 2.
- **Recrutas prontos:** os recrutas "prontos" e os da campanha vêm sem descrição.
