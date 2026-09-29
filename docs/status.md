# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- **Vertical Slice jogável (seção 81)** no ciclo cozinhar → servir → ganhar → subir de nível → comprar → posicionar → expandir → salvar → reabrir.
- **Loja:**
  - móveis custam Café Ouro e exigem nível;
  - o botão mostra o preço, "Nível N" ou "N guardado(s)";
  - a cobrança acontece só ao confirmar a posição, e cancelar não custa nada.
- **Inventário:** **Guardar** (antes "Remover") leva o móvel ao inventário; recolocar é grátis.
- **Expansão:** 4 etapas (10×8 → 12×12), com nível e preço em dados e confirmação antes de cobrar (Cancelar já selecionado). O piso e a câmera acompanham a ampliação.
- **6 missões iniciais (seção 143) como tutorial:**
  - uma de cada vez, com dica sempre visível no canto direito;
  - ao concluir, aparece o aviso com a recompensa.
- **Save versão 2** com inventário e missões. Um save antigo é migrado sozinho.
- **Build para Windows:** `CafeManie.exe`, um arquivo só, sem precisar da Godot.

🟡 **EM ANDAMENTO**

- **Validação da Vertical Slice pelo PO:** roteiro "Vertical Slice (o `.exe`)" em [qa.md](qa.md). É o marco de saída da Fase 4.

🔴 **BLOQUEADO**

- **Envio para o GitHub:** o push continua recusado (403) até o app do Claude ser instalado na conta `eliashenr`. Todos os commits estão prontos localmente; o projeto vai em zip enquanto isso.

🧪 **TESTADO**

- **191 testes automatizados: PASSOU** (eram 180; 11 novos de cena para loja, inventário, expansão e missões).
- **O "jogador robô" joga a slice inteira: PASSOU.** Ele conclui as 6 missões em 5,5 min de jogo e chega ao nível 4.
- **Verificação da suíte: PASSOU (5 de 5).** Bugs inseridos de propósito foram todos pegos:
  - móvel novo saindo de graça;
  - inventário sem salvamento automático;
  - piso sem acompanhar a expansão;
  - expansão sem confirmação;
  - Guardar destruindo o móvel.
- **Cena principal rodando 300 frames: PASSOU**, zero erros.
- **Build exportado: PASSOU.** O conteúdo de dentro do `.exe` foi aberto e jogado por 600 quadros sem janela:
  - todos os móveis, receitas, clientes, missões e expansões carregaram;
  - zero erros.
  - Um build de propósito sem a pasta de missões **reprovou** na mesma checagem, o que confirma que ela funciona.
- **Renderização real: PASSOU.** Capturas da loja com preços, do cartão de missão, da confirmação de expansão, da cafeteria ampliada e da compra.
- **O `.exe` rodando num Windows de verdade: NÃO FOI POSSÍVEL TESTAR** aqui. O emulador de Windows da nuvem (Wine) trava até com a Godot original, sem nenhuma alteração nossa. O programa em si é o executável oficial da Godot, e o conteúdo que colocamos nele foi verificado. Falta só o seu clique duplo.

🐞 **BUGS**

- Nenhum bug novo de jogo nesta etapa.
- 🐞 **LOW (aviso) — Windows SmartScreen:** na primeira vez, o Windows mostra "O Windows protegeu o computador", porque o `.exe` não tem assinatura digital paga. O README e a mensagem de entrega explicam como seguir.
- ⚠️ **Balanceamento:** a slice parece rápida demais: 6 missões em 5,5 min, e nível 8 em 30 min no turno longo. Fica para o **FAÇA BALANCEAMENTO**, com as suas impressões.

🏗️ **DECISÕES TÉCNICAS**

Detalhes em [decisions.md](decisions.md):

- **DT-017:** loja cobra só ao confirmar, e Guardar em vez de vender.
- **DT-018:** a expansão cresce sem mover nada, e a entrada acompanha a borda.
- **DT-019:** missões como tutorial, uma por vez.
- **DT-020:** `.exe` único, com checagem automática do build.

➡️ **PRÓXIMO PASSO**

- **Seu teste:** abra o `CafeManie.exe` e siga o roteiro "Vertical Slice" em [qa.md](qa.md). A pergunta mais importante é se dá vontade de continuar jogando.
- Depois: **FAÇA BALANCEAMENTO**, com as suas impressões. Ou aprove a slice para seguirmos para conquistas, arte e o build Android.
