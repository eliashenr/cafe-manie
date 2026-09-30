# Status

## CAFÉ MANIE — STATUS (29/09/2026)

🟢 **CONCLUÍDO**

- **Vertical Slice validada pelo PO** ("joguei e gostei").
- **Paredes e revestimentos:**
  - duas paredes no fundo, que crescem com a expansão;
  - 5 pisos e 4 paredes, com compra única (pede confirmação) e troca grátis entre os já comprados;
  - a loja agora tem abas: Móveis, Decoração, Piso e Parede.
- **Decoração que conta (seção 35):**
  - 3 itens novos: vaso de flores, luminária e estante;
  - a **Beleza** aparece no HUD e deixa os clientes até 30% mais pacientes e as chegadas até 25% mais frequentes.
- **Vender móveis:** metade do preço, sempre com confirmação. O último fogão e o último balcão não podem ser vendidos, para o jogador nunca ficar sem como ganhar ouro.
- **Conquistas (seção 49):** 7 conquistas com 3 degraus cada (de "Primeiro Cliente" a "Lenda"), com prêmios em Café Ouro e um painel de progresso.
- **Recompensa diária (seção 51):** calendário de 7 dias, contado pela meia-noite local, com proteção contra relógio voltando para trás.
- **Nome da cafeteria** no primeiro acesso, mostrado no topo. Tocar nele troca o nome.
- **Sons de feedback** originais, gerados por código, com botão para ligar e desligar.
- **APK Android** (arm64, Android 7 ou mais novo, ~26 MB), com ícone provisório original.
- **Avisos em fila:** uma mensagem não apaga mais a outra.
- **Direção de arte:** plano em [art-direction.md](art-direction.md).

🟡 **EM ANDAMENTO**

- **Teste no celular de verdade:** roteiro "Android" em [qa.md](qa.md).
- **Capturas do Café Mania:** aguardando o PO para completar o guia de estilo.

🔴 **BLOQUEADO**

- **Envio para o GitHub:** o push continua recusado (403) até o app do Claude ser instalado na conta `eliashenr`. Todos os commits estão prontos localmente; o projeto vai em zip.

🧪 **TESTADO**

- **260 testes automatizados: PASSOU** (eram 191).
- **Verificação da suíte: PASSOU (20 de 20).** Bugs inseridos de propósito nas novidades foram todos pegos. Um deles (clientes não contados nas conquistas) só foi pego depois de eu escrever um teste novo.
- **Toque de verdade: PASSOU.** Botões da loja e das janelas respondem a toque, sem emulação de mouse, e o toque num botão não vaza para o piso.
- **Jogos exportados: PASSOU.** O conteúdo de dentro do `.exe` e do `.apk` foi aberto e jogado por 600 quadros sem janela: 9 móveis, 6 receitas, 9 revestimentos, 7 conquistas, 7 dias de recompensa e 7 sons carregados, zero erros.
- **Assinatura do APK: PASSOU** (`apksigner verify`, esquemas v2 e v3).
- **Cena principal rodando 300 frames: PASSOU**, zero erros.
- **Renderização real: PASSOU.** Capturas dos 4 estilos de piso e parede, do nome, da recompensa diária e do painel de conquistas.
- **Celular Android de verdade: NÃO FOI POSSÍVEL TESTAR** aqui. Não há celular nem emulador na nuvem.
- **`.exe` num Windows de verdade: confirmado por você** na entrega anterior; o processo de geração é o mesmo.

🐞 **BUGS** (corrigidos, com teste)

- 🐞 **HIGH (encontrado antes de chegar a você) — janela da recompensa diária ocupando a tela inteira:** o texto quebrava letra a letra e esticava a janela. A largura dos cartões agora é fixa.
- 🐞 **MEDIUM — duas janelas de pergunta ao mesmo tempo:** se a recompensa diária aparecesse com outra pergunta aberta (por exemplo, "Expandir?"), a Godot dava erro. Agora só abre uma janela por vez.
- 🐞 **MEDIUM (ferramenta de testes) — teste que não compila sumia da contagem:** um arquivo de teste com erro era ignorado em silêncio, e a suíte continuava "verde". Agora ele reprova a execução.
- 🐞 **LOW — avisos se apagando:** "Subiu de nível" era trocado na hora por outro aviso. Agora os avisos entram numa fila.
- ⚠️ **Balanceamento:** o robô continua rápido: 6 missões em 5,2 min, e nível 8 com 0 clientes irritados em 30 min. A beleza facilitou ainda mais. Fica para o **FAÇA BALANCEAMENTO**.

🏗️ **DECISÕES TÉCNICAS**

Detalhes em [decisions.md](decisions.md):

- **DT-021:** paredes e revestimentos.
- **DT-022:** efeito da beleza.
- **DT-023:** venda protegida.
- **DT-024:** conquistas por contadores.
- **DT-025:** recompensa diária pelo dia local.
- **DT-026:** nome da cafeteria.
- **DT-027:** sons gerados por código.
- **DT-028:** APK sem Gradle, com a chave de teste fora do repositório.

➡️ **PRÓXIMO PASSO**

- **Seu teste:** instale o APK no celular (README, "Jogar no celular Android") e siga os roteiros "Novidades" e "Android" em [qa.md](qa.md).
- **Mande as capturas do Café Mania** para eu completar o guia de estilo original.
- **FAÇA BALANCEAMENTO**, com as suas impressões de ritmo, dificuldade e preços.
- Depois disso: preparar o **backend** (Fase 6), porque amigos, visitas e rankings (Fase 5) dependem de servidor.
