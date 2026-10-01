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
- **A cadeira vira sozinha para a mesa** (decisão do PO): ao ser levada para o lado de uma mesa, ela já vem virada. Saves antigos viram as cadeiras uma vez, ao abrir (save versão 4). No save do PO as 4 cadeiras já olhavam para as mesas, então nada mudou nele.
- **Commits enviados ao GitHub** (`main`), com a autorização do PO.
- **Arte v3 no cenário (3ª parte da troca dos placeholders):**
  - piso de verdade nos 5 revestimentos (xadrez bege, assoalho cor de mel, xadrez bistrô, azulejo azul e mármore), com tapete listrado na entrada e a borda branca da laje na frente;
  - paredes nos 4 revestimentos (creme, listras menta, tijolinho e azul-marinho), com janelas de cortina, quadros, relógio e prateleira; a luz das janelas aparece no chão;
  - fora do salão: gramado, calçada, rua e um caminho de pedras até a entrada, cerquinha branca na frente (aberta no caminho), canteiros de flores e postes;
  - tudo acompanha a expansão da cafeteria.
- **Vitrine aceita piso e parede** (`tools/showcase.gd -- foto.png 0.75 floor_wood wall_mint_stripes`), para conferir cada revestimento.
- **Arte v3 na interface (5ª e última parte da troca dos placeholders):**
  - no alto: o Café Ouro no contador com a moeda, a barra de XP listrada com a estrela do chef e o nível grande, a beleza com a flor e o cronômetro do presente diário;
  - na esquerda, os medalhões Missões (com o cartão da missão), Presente e Conquistas; na direita, zoom, som e configurações;
  - embaixo, a faixa de ícones e a satisfação dos clientes em estrelas, com o nome da cafeteria;
  - a Loja abre como no jogo antigo, com abas coloridas (Salão, Cozinha, Decoração, Pisos, Paredes) e quadradinhos com o desenho e o preço;
  - os botões de móvel, construção e fogão são os quadrados brilhantes da arte, e as receitas aparecem com o desenho do prato;
  - as dicas das missões falam da interface nova ("Toque em Loja e escolha Mesa").
- **Arte v3 na cozinha (4ª parte da troca dos placeholders):**
  - o fogão que cozinha mostra a panela da receita com a chama e vapor, e o forno aceso quando a frente aparece;
  - em cima do fogão, o selo da arte: o prato, um anel de progresso e o tempo; quando fica pronto, "Pronto!" em verde, com brilho;
  - o balcão mostra a pilha de pratos com a comida e um número com as porções;
  - selos sempre por cima do salão, como os balões.

🟡 **EM ANDAMENTO**

- **Teste no celular de verdade:** roteiro "Android" em [qa.md](qa.md).

🔴 **BLOQUEADO**

- Nada bloqueado.

🧪 **TESTADO**

- **301 testes automatizados: PASSOU** no Windows. Os testes novos conferem:
  - se todo móvel tem arte nas 4 rotações, com a âncora e a escala certas, e se a cena e a prévia usam essa arte;
  - se todo cliente e o garçom têm todas as poses e toda receita tem prato;
  - se a direção e o espelho seguem o movimento e os passos se alternam;
  - se quem senta segue a cadeira e a expressão segue a paciência;
  - se o prato vai para a mesa certa e sai quando o cliente levanta;
  - se o balão fica por cima de tudo;
  - se a cadeira vira para a mesa no modo de construção e nos saves antigos, uma vez só, e respeita a escolha do jogador nos saves novos;
  - se todo revestimento tem arte, o xadrez alterna, as variações não mudam sozinhas e a parede tem janelas;
  - se a cena usa a arte e enquadra a parede mais alta, se a cerca abre só na entrada e se o exterior acompanha a expansão;
  - se toda receita tem panela, se o forno só acende de frente e se fogão e balcão mostram receita, tempo, "Pronto!" e porções;
  - na interface: a moeda com ponto de milhar, o nível, as estrelas pela satisfação, o presente com cronômetro, o zoom pelos botões, o medalhão de missões, a faixa de ícones e a loja que abre, fecha e some ao escolher um móvel.
- **Defeitos inseridos de propósito: 35 de 35 pegos** pelos testes novos (lista em [qa.md](qa.md)).
- **Revestimentos conferidos por foto:** os 4 conjuntos de piso e parede na vitrine e o save do PO com o cenário novo.
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
- **DT-032:** a cadeira vira sozinha para a mesa (decisão do PO). Save versão 4 vira as cadeiras dos saves antigos uma vez.
- **DT-033:** cenário da v3 montado por célula (piso, parede e enfeites). Rua e calçada do lado da entrada, por onde os clientes chegam. Cerca e canteiros na frente do salão.
- **DT-034:** cozinha da v3. Panela e forno aceso por cima do fogão, selo e número desenhados por código, pilha de pratos no balcão.
- **DT-035:** interface da v3 no formato do jogo antigo. A loja abre e fecha, e o que ainda não existe (vizinhos, grãos, correio) fica de fora.

➡️ **PRÓXIMO PASSO**

- **Conferência visual do PO** dos móveis e dos personagens (roteiro "Arte v3" em [qa.md](qa.md)).
- **A troca dos placeholders pela arte v3 terminou.** Próximos: gerar o `.exe` novo, a **conferência do PO**, as fontes das pranchas (Fredoka e Nunito, com autorização do PO) e o **FAÇA BALANCEAMENTO**.
- Instalar os export templates e gerar um `.exe` novo para o PO jogar.
- **FAÇA BALANCEAMENTO** e o teste no celular continuam na fila.
