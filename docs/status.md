# Status

## CAFÉ MANIE — STATUS (30/09/2026)

🟢 **CONCLUÍDO**

- **Direção visual v3 aprovada pelo PO** ("Gostei! Agora sim começamos conversar"), no canvas "Café Manie — Direção Visual", refeita a partir das capturas e do retorno do PO:
  - **cores de dia claro e saturadas**: gramado verde-vivo, paredes brancas e menta, piso de madeira mel, cozinha em xadrez, móveis coloridos;
  - **sem árvores**: fora do salão ficam gramado, rua, calçada, canteiros e cerquinha;
  - **salão grande e lotado** (12×12), com cozinha completa, mesas compridas, 17 clientes sentados e gente chegando pela porta;
  - **interface no formato do jogo de 2010**: contadores com "+", barra de XP com estrela e nível, missões laterais em medalhões com fita, botões quadrados azuis, barra de ícones e faixa de vizinhos;
  - **loja em quadradinhos** com etiqueta de preço, selos, setas azuis, prévia e botão verde de comprar, e o móvel sendo posicionado no salão;
  - **personagens refeitos**: cabeça redonda centrada (sem o "corcunda"), olhos de desenho com pálpebra e brilho, 12 penteados em mechas, expressões, mãos e roupas com detalhe;
  - 6 pranchas: tela do jogo, loja, cardápio e cozinha, personagens, guia de estilo e cenário sem interface.
- **Gerador da arte v3** no repositório (`tools/art_direction/v3/`). O mesmo código vai exportar os sprites do jogo depois da aprovação.
- **Tudo do jogo que já existia continua igual**: paredes e revestimentos, beleza, venda, conquistas, recompensa diária, nome da cafeteria, sons e o APK Android.

🟡 **EM ANDAMENTO**

- **Teste no celular de verdade:** roteiro "Android" em [qa.md](qa.md).

✅ **RESOLVIDO EM 30/09/2026 (PC do PO)**

- **Mudança para o Claude Code:** histórico de 35 commits recuperado do bundle, ícone de volta à versão do repositório, bundle apagado.
- **Envio para o GitHub:** `main` enviada para `eliashenr/cafe-manie`.

🔴 **BLOQUEADO**

- **Godot 4.7.2 não está instalada no PC do PO.** Sem ela não dá para rodar os testes nem a cena, e nada do jogo pode ser declarado pronto (seção 91).

🧪 **TESTADO**

- **260 testes automatizados: PASSOU.**
- **Cena principal rodando 300 frames: PASSOU**, zero erros.
- **Pranchas da v3 conferidas por renderização:** cada prancha foi desenhada num navegador sem janela, com as fontes certas, e conferida por imagem antes de publicar. Os defeitos achados assim (brilhos opacos demais, letreiro de neon escondido atrás da janela, selos se sobrepondo, cartões de vizinhos cortados) foram corrigidos.
- **Gerador rodando de dentro do repositório: PASSOU.** As pranchas geradas ali são idênticas, byte a byte, às publicadas.
- **Celular Android de verdade: NÃO FOI POSSÍVEL TESTAR** aqui. Não há celular nem emulador na nuvem.

🐞 **BUGS**

- Nenhum bug novo no jogo: esta etapa mexeu só em arte e documentação.
- ⚠️ **Balanceamento:** o robô continua rápido (6 missões em 5,2 min; nível 8 com 0 clientes irritados em 30 min). Fica para o **FAÇA BALANCEAMENTO**.

🏗️ **DECISÕES TÉCNICAS**

Detalhes em [decisions.md](decisions.md):

- **DT-029:** direção visual v3 no formato do jogo antigo, com desenho 100% próprio (seção 5).

➡️ **PRÓXIMO PASSO**

- **Levar a arte v3 para o jogo**, exportando os sprites do gerador e trocando os placeholders da Godot.
- **Instalar a Godot 4.7.2** no PC do PO e confirmar os 260 testes no Windows.
- **FAÇA BALANCEAMENTO** e o teste no celular continuam na fila.
