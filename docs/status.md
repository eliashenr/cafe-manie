# Status

## CAFÉ MANIE — STATUS (30/09/2026)

🟢 **CONCLUÍDO**

- **Projeto instalado no PC do PO:** histórico de 35 commits recuperado do bundle, ícone de volta à versão do repositório, bundle apagado e `main` enviada ao GitHub (`eliashenr/cafe-manie`).
- **Godot 4.7.2 instalada** em `C:\Godot`, baixada da página oficial e conferida pela soma SHA-512 publicada pela Godot.
- **Arte v3 nos móveis do jogo (1ª parte da troca dos placeholders):**
  - os 9 móveis do catálogo (cadeira, mesa, mesa longa, fogão, balcão, estante, planta, vaso de flores e luminária) aparecem com a arte aprovada, nas 4 rotações;
  - nas rotações que viram a frente para o fundo, o móvel aparece de costas;
  - o móvel selecionado ganha um contorno laranja no chão; a prévia de construção usa a mesma arte, em verde ou vermelho;
  - os sprites saem do mesmo código das pranchas (DT-030), em resolução dobrada, nítidos até o zoom máximo.
- **Ferramenta de foto do jogo** (`tools/screenshot.gd`) para a conferência visual.
- **Arte v3 nos personagens (2ª parte da troca dos placeholders):**
  - 12 clientes diferentes e o garçom Léo, desenhados com a arte aprovada;
  - andam alternando os pés, nas 4 direções, de frente ou de costas;
  - sentam do jeito que a cadeira está virada; de costas, o encosto fica na frente deles, como nas pranchas;
  - a cara muda com a paciência (feliz, preocupado, bravo) e quem come aparece comendo;
  - o prato de quem come fica na mesa, do lado da cadeira; o garçom leva o prato do pedido na bandeja;
  - o balão de pedido mostra o desenho do prato, com a barra de paciência em verde, amarelo ou vermelho, e fica sempre por cima do salão;
  - quem vai embora mostra uma carinha verde (satisfeito) ou vermelha (bravo).
- **Vitrine dos personagens** (`tools/showcase.gd`): monta uma cafeteria com gente em cada situação, para conferir a arte de uma vez.

🟡 **EM ANDAMENTO**

- **Troca dos placeholders pela arte v3:** faltam piso e paredes, os pratos no balcão e no fogão, e a interface (HUD e loja).
- **Teste no celular de verdade:** roteiro "Android" em [qa.md](qa.md).

🔴 **BLOQUEADO**

- Nada bloqueado.

🧪 **TESTADO**

- **277 testes automatizados: PASSOU** no Windows. Os testes novos conferem:
  - se todo móvel tem arte nas 4 rotações, com a âncora e a escala certas, e se a cena e a prévia usam essa arte;
  - se todo cliente e o garçom têm todas as poses e toda receita tem prato;
  - se a direção e o espelho seguem o movimento e os passos se alternam;
  - se quem senta segue a cadeira e a expressão segue a paciência;
  - se o prato vai para a mesa certa e sai quando o cliente levanta;
  - se o balão fica por cima de tudo.
- **Vitrine dos personagens** fotografada e conferida: cada situação aparece como nas pranchas.
- **Cena principal rodando 300 frames: PASSOU**, zero erros.
- **Foto do jogo** com uma cópia do save do PO: a arte aparece no lugar certo e fica nítida com zoom de 1,8×.
- **Sprites conferidos contra as pranchas:** cada um foi comparado lado a lado com o SVG desenhado pelo Chrome.
- **Pranchas do canvas:** geradas antes e depois da mudança no gerador e comparadas, byte a byte idênticas.
- **Exportação `.exe` e APK: NÃO TESTADA** nesta etapa. Os export templates ainda não estão instalados neste PC.

🐞 **BUGS**

- **Corrigido:** o teste de jogo novo lia o save de verdade de quem já jogou no PC e falhava (12 móveis e 282 de ouro no lugar dos valores de um jogo novo). Agora ele usa uma pasta própria.
- ⚠️ **Balanceamento:** o robô continua rápido (6 missões em 5,2 min). Fica para o **FAÇA BALANCEAMENTO**.

🏗️ **DECISÕES TÉCNICAS**

Detalhes em [decisions.md](decisions.md):

- **DT-030:** sprites gerados do código da arte v3. O Chrome ou o Edge converte para PNG, porque a Godot deixa vazio o gradiente de formas curvas. A Godot recorta e grava a âncora.
- **DT-031:** personagens com poses desenhadas e espelhadas no jogo. Quem senta segue a cadeira. Balões desenhados por código e sempre por cima.

➡️ **PRÓXIMO PASSO**

- **Conferência visual do PO** dos móveis e dos personagens.
- **Decisão do PO:** a cadeira deve já vir virada para a mesa ao ser posta do lado dela? Hoje cada cliente olha para onde a cadeira aponta, e no save do PO há cadeira de costas para a mesa.
- Continuar a troca: **piso e paredes**, depois **pratos e interface**.
- Instalar os export templates e gerar um `.exe` novo para o PO jogar.
- **FAÇA BALANCEAMENTO** e o teste no celular continuam na fila.
