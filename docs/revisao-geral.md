# Revisão geral do Café Manie e plano de desenvolvimento (11/11/2026)

Pedido do PO: revisar o código e o jogo, e estruturar a melhor forma de desenvolver, a melhor qualidade gráfica e a melhor jogabilidade.

Este documento diz o que está bom, o que precisa mudar e em que ordem. O guia de retomada, passo a passo, está em [continuar.md](continuar.md).

## Como esta revisão foi feita, e o que ela não cobre

- **Li:** a simulação central, a camada de cenas, o carregamento da arte, o executor de testes, os dados de `data/`, o `project.godot`, as exportações e os documentos.
- **Medi:** tamanho do código, das fotos e do repositório, e o peso das fotos na memória de vídeo.
- **Vi no jogo:** fotos do café com os pisos e as paredes novos, tiradas sem janela.
- **Não fiz:**
  - não joguei uma sessão inteira à mão, então as notas de jogabilidade vêm das regras, dos dados e do QA anterior;
  - não li linha por linha os 31 mil de código e testes;
  - não medi o desempenho de novo: os números são do QA de 23/10;
  - não testei em celular, porque isso só o PO consegue fazer.

## Resumo

| Área | Nota | Em uma frase |
|---|---|---|
| Regras do jogo (`core/`) | Boa | Separadas da tela, guiadas por dados e com 739 testes. O ponto fraco é um arquivo central grande demais |
| Telas (`scenes/`) | Média | Funcionam e estão testadas, mas três arquivos concentram quase toda a interface |
| Arte | Em transição | Móveis e personagens novos estão num padrão alto; pisos, paredes, comidas e retratos ainda são da linguagem antiga |
| Jogabilidade | Rica, não validada | Há muito conteúdo e sistemas, mas o jogo nunca rodou num celular de verdade e não tem evento ativo |
| Processo | Bom, com riscos | O fluxo por etapas com aprovação funciona. Faltam testes automáticos no GitHub, e a versão principal está muito atrás |

**As três coisas que mais importam agora:**

1. **Testar no celular.** O jogo é para Android e toda medição até hoje foi no PC. Este é o maior risco do projeto.
2. **Terminar a troca da arte** (pisos, paredes, portas, comidas, retratos), para o jogo ter uma linguagem só.
3. **Juntar o trabalho na versão principal** depois da aprovação visual, com os testes rodando sozinhos a cada envio.

## 1. Código

### O que está bom e deve ser mantido

- **Regra separada da tela.** As regras ficam em `core/` e rodam sem janela. Por isso existem 739 testes e por isso o redesenho da arte não quebrou nada.
- **Conteúdo em dados.** São 130 móveis, 39 receitas, 55 revestimentos, 27 itens de parede e 13 portas em arquivos `.tres`. Nenhum preço está escrito no código.
- **Save robusto.** Tem versão (está na 24), migração, gravação atômica, cópia de segurança e leitura tolerante a arquivo estragado.
- **Tempo por horário, não por quadros.** O preparo continua com o jogo fechado, e o relógio pode vir de um servidor depois.
- **Regras do projeto respeitadas.** Não achei `TODO` esquecido, e só um uso direto do relógio do sistema em `core/` (no nome do arquivo de quarentena do save, que é inofensivo).

### Achados

| # | Achado | Evidência | Risco | O que fazer | Prioridade |
|---|---|---|---|---|---|
| C1 | Um arquivo central faz tudo | `core/service/cafe_simulation.gd` tem 2.596 linhas, cerca de 250 funções e mais de 40 sinais. Atendimento, loja, reforma, eventos, crítico, filial, entregas e avatar passam por ele | Cada recurso novo aumenta a chance de quebrar outro, e a leitura fica cara para qualquer sessão | Extrair por assunto, um por vez, mantendo `CafeSimulation` como fachada: primeiro o atendimento (clientes, garçons, pedidos), depois compras e reforma, depois eventos e crítico. Os testes atuais são a rede de segurança | Alta, depois da arte |
| C2 | Três arquivos concentram a interface | `scenes/ui/build_bar.gd` (1.643 linhas), `scenes/cafe/cafe.gd` (1.445) e `scenes/ui/game_hud.gd` (1.414). Só existe uma cena `.tscn`; o resto é montado em código | Mexer na loja pode afetar a reforma, que mora no mesmo arquivo | Dividir por tela: loja, reforma, móvel selecionado e cozinha, cada uma no seu arquivo. Manter a montagem em código, que é o que permite trabalhar sem o editor | Média |
| C3 | Checagens lentas rodam a cada quadro | `tick()` chama, todo quadro, a virada de missões, o evento, a noite, a comida estragada e as entregas; copia a lista de clientes e refiltra a fila várias vezes | No PC sobra folga (176 quadros por segundo). No celular, espera-se de 3 a 5 vezes menos | Passar as checagens de calendário para uma vez por segundo e calcular a fila uma vez por `tick`. Medir antes e depois com `tools/perf_check.gd` | Média, junto com o teste no celular |
| C4 | A arte não tinha teste de sanidade | Os pisos novos saíram todos pretos por um defeito na gravação da textura, e nenhum teste acusou. Só as fotos no jogo mostraram | Uma foto vazia ou preta pode chegar ao jogo | Criar um teste que abre cada foto de piso e de parede e reprova se ela estiver vazia, preta ou estourada | Alta, é pequeno |
| C5 | Arquivos órfãos na pasta da arte | 112 arquivos `.import` em `art/sprites` sem a foto correspondente (poses antigas dos personagens) | Só sujeira, mas confunde e pesa no repositório | Apagar num commit `chore:` separado, depois de conferir que nenhum nome aparece no `sprites.json` | Baixa |
| C6 | Documentos desatualizados | `architecture.md` ainda chama as telas de "placeholder" e não lista uns 30 módulos; `gameplay.md` diz que conquistas faltam; `progression.md` fala em níveis 1 a 10 (são 30); `status.md` tem 1.034 linhas | A próxima sessão lê informação errada e perde tempo | Reescrever os três primeiros a partir do código, e mover o histórico antigo do `status.md` para `docs/historico.md` | Média |
| C7 | Dois processos do Blender ao mesmo tempo corrompiam a leitura do manifesto | Aconteceu nesta sessão: um processo leu o `sprites.json` pela metade e parou | Perda de âncoras das fotos | **Corrigido hoje:** a gravação agora é atômica. A regra passa a ser um processo do Blender por vez | Feito |
| C8 | Scripts de conferência viviam em pasta temporária | Os scripts de foto, folha e revisão ficavam fora do repositório | Sumiriam com a limpeza do Windows | **Corrigido hoje:** estão em `tools/revisao/` | Feito |

### O que eu não mudaria

- **Godot e GDScript.** Atendem bem a um jogo 2D isométrico, e trocar agora custaria meses sem ganho visível.
- **Fotos de modelos 3D em vez de 3D em tempo real.** É o que permite materiais ricos num celular simples.
- **A regra de aprovação visual por etapa.** Foi ela que evitou seguir com a primeira amostra, que não atingia o objetivo.

## 2. Qualidade gráfica

### Onde a arte está

| Grupo | Situação |
|---|---|
| Móveis (130), clientes (12) e garçom | Linguagem nova, aprovados pelo PO |
| Pisos (37 fora da amostra), paredes (14), itens de parede (21), portas (12) e terraço | Modelos novos escritos; rascunho gerado nesta sessão, aguardando conferência e revisão do PO |
| Panelas (39), pratos (39), bebidas, frutas e temperos | Desenho antigo em 2D |
| Retratos do avatar (35), vizinhos (7), crítico | Desenho antigo em 2D |
| Ícones e botões da interface | Desenho antigo em 2D, coerente com a interface escura |
| Cidade (prédios, carros, rua) | 3D da fase anterior, com a luz antiga |

### Achados

| # | Achado | Por que importa | O que fazer | Prioridade |
|---|---|---|---|---|
| G1 | Duas linguagens na mesma tela | Um prato desenhado a traço em cima de uma mesa fotorrealista quebra a ilusão. É o defeito visual mais visível depois dos pisos | Depois dos pisos e portas: panelas e pratos em 3D, na mesma luz, com os mesmos nomes de arquivo. Depois os retratos | Alta |
| G2 | Cidade com a luz antiga | Os prédios usam a luz fria do catálogo antigo, e o salão usa a quente. De dia a diferença é aceitável; perto do salão, destoa | Refazer as fotos da cidade com a luz nova e fachadas no padrão da referência A | Média |
| G3 | Personagens com poucas poses | Cada cliente tem andar (8 quadros), em pé e 4 poses sentado. Não há quadros de comer, conversar ou reagir | Acrescentar de 2 a 4 quadros de comer e um de reação. É onde o jogo ganha vida com menos custo | Média |
| G4 | Peso das fotos na memória de vídeo | São 1.160 fotos, 50 milhões de pixels. Sem compressão, isso dá 191 MB, ou 255 MB com as versões reduzidas, se tudo for carregado. Um celular simples tem pouca folga | Primeiro medir no celular. Se faltar memória: juntar as fotos pequenas em folhas (atlas), soltar da memória o que não está em uso, e testar a compressão ASTC nos pisos e paredes | Média, depende do teste no celular |
| G5 | Nitidez no zoom máximo | As fotos têm 2 pixels por pixel de mundo e o zoom vai até 2 vezes. Em telas de celular de alta densidade, isso fica no limite | Conferir no celular. Se borrar, limitar o zoom ou gerar as fotos dos personagens com densidade 3 | Baixa |
| G6 | Sem comparação automática de imagens | Cada etapa é conferida olhando fotos. Uma regressão num item já aprovado pode passar | Guardar fotos de referência com a câmera fixa (`tools/art_sample.gd` já tem o modo `fixa`) e comparar a cada etapa, avisando quando a diferença passar de um limite | Média |
| G7 | "Janela com Cortina" sem cortina | A janela da amostra aprovada tem caixilho e peitoril, mas não tem cortina | Perguntar ao PO na próxima revisão: acrescentar a cortina ou manter | Baixa |

### Técnica nova desta sessão

Os pisos e as paredes passaram a usar **texturas pintadas por código com período exato de uma célula**. O ruído é gerado de um jeito que dá a volta na borda, então o piso vizinho continua o desenho sem emenda, inclusive pedra, granilite e calçada portuguesa. Antes, só padrões geométricos fechavam sem emenda.

## 3. Jogabilidade

### O que o jogo já tem

- **Ciclo central:** cozinhar, servir, ganhar ouro e experiência, decorar e expandir. Validado pelo PO em 29/09.
- **Profundidade:** 30 níveis, 39 receitas de 1 minuto a 12 horas, domínio de receita, temperos, troféus, fogões com função, bebidas com energia, fila, garçons contratáveis.
- **Motivos para voltar:** presente diário, missões diárias e semanais, crítico diário, comida que estraga, noite com cardápio próprio.
- **Extras:** entregas, filial na praia, vizinhos, plantação, atrações, palco, avatar, terraço, evento de Halloween.

### Achados

| # | Achado | Por que importa | O que fazer | Prioridade |
|---|---|---|---|---|
| J1 | Nunca foi jogado num celular | Toque, tamanho dos botões, calor, bateria e desempenho só aparecem no aparelho. O roteiro existe em `qa.md` e nunca foi feito | Gerar o APK e o PO seguir o roteiro "Android". É o item mais importante desta revisão | Máxima |
| J2 | Não há evento ativo | O Halloween acabou em 03/11 e é o único evento. Jogo de cafeteria vive de calendário | Criar o evento de Natal com os mesmos mecanismos do Halloween: uma história, 5 missões, um fogão de prêmio e um enfeite. É conteúdo em dados, sem sistema novo | Alta |
| J3 | Muitos sistemas para quem começa | São mais de 15 sistemas e o tutorial tem 6 missões. Não verifiquei, jogando, como cada sistema é apresentado | Fazer uma sessão de QA de primeira hora, anotando onde o jogador fica sem saber o que fazer. Onde faltar, liberar o sistema por nível com um aviso de apresentação | Alta |
| J4 | Só dois tipos de cliente | `data/customers` tem "regular" e "apressado". Os 12 visuais não mudam o comportamento | Acrescentar tipos em dados: o que paga mais e espera menos, o que pede bebida, o grupo que ocupa a mesa inteira. O sistema já aceita | Média |
| J5 | Sem aviso quando o prato fica pronto | Com o jogo fechado, nada chama o jogador de volta. Em jogos desse tipo, o aviso do celular é o principal motivo de retorno | Notificação local do Android para prato pronto e presente diário, com opção de desligar | Alta, depois do teste no celular |
| J6 | Som feito por código | A música e os efeitos são sintetizados. Funciona e não tem risco de direito autoral, mas tem teto de qualidade | Manter até a arte fechar. Depois, trocar por áudio gravado com licença livre, primeiro os efeitos mais ouvidos | Baixa |
| J7 | Social sem servidor | Vizinhos e ranking são locais. O social de verdade depende do servidor (Fase 6) e de validação jurídica | Não começar antes do teste no celular e da arte | Depois |
| J8 | Compra de moedas sem pagamento real | Os pacotes aparecem e explicam que o pagamento depende da Play Store e da revisão jurídica | Manter como está até a Fase 7 | Depois |

### O que eu não acrescentaria agora

Sistema novo. O jogo já tem mais sistemas do que foi validado com jogadores. O ganho agora vem de **polir, apresentar bem e testar no celular** o que existe.

## 4. Forma de desenvolver

### O que manter

- **Etapas pequenas com aprovação do PO**, uma por vez: "Pode começar", construção, revisão no jogo, "Pode enviar".
- **Nada pronto sem testes e sem a cena principal subindo.**
- **Nada na tela do PO** enquanto o trabalho roda.
- **Save pessoal intocado**, com dados isolados.

### O que mudar

| # | Mudança | Por quê | Como |
|---|---|---|---|
| P1 | Testes automáticos no GitHub | Hoje os testes só rodam quando uma sessão lembra. No GitHub, cada envio seria testado sozinho, de graça | Um arquivo de fluxo do GitHub Actions que baixa a Godot 4.7.2 e roda os testes sem janela. Precisa do "pode" do PO, porque mexe na configuração do repositório |
| P2 | Juntar o redesenho na versão principal | `main` parou no commit `bb843d6`. Todo o trabalho de arte está em `arte-3d` e `amostra-a-2`. Quanto mais tempo separado, mais difícil juntar | Quando pisos, paredes e portas forem aprovados: juntar `amostra-a-2` em `main` e seguir com ramos curtos por etapa |
| P3 | Fotos fora do histórico comum | O repositório tem 161 MB, e cada etapa de arte troca cerca de 100 fotos. Ele vai crescer rápido | Avaliar o Git LFS depois da junção. Não é urgente |
| P4 | Guia de retomada sempre atualizado | Uma sessão que termina sem aviso perde o contexto | Manter [continuar.md](continuar.md): a seção "Onde paramos" é reescrita no fim de cada sessão |
| P5 | Um processo do Blender por vez | Dois juntos disputam o `sprites.json` | Regra registrada no guia e no próprio código |
| P6 | Conferência por lotes com fotos no jogo | Folhas soltas não mostram emendas nem a luz do salão | Usar `tools/revisao/superficies.gd` e os outros scripts de conferência antes de chamar o PO |

## 5. Plano em ordem

Cada etapa só começa com a liberação do PO e só termina com a aprovação dele.

| Ordem | Etapa | Pronto quando |
|---|---|---|
| 1 | **Pisos, paredes, itens de parede, portas e terraço** (em andamento) | Fotos finais geradas, conferidas no jogo de dia e de noite, testes passando e o PO aprovar na janela de revisão |
| 2 | **Teste de sanidade da arte** (C4) | Um teste novo reprova foto vazia, preta ou estourada |
| 3 | **Teste no celular** (J1) | APK gerado, roteiro do `qa.md` feito pelo PO e os achados anotados |
| 4 | **Panelas e pratos em 3D** (G1) | As 39 receitas com prato e panela novos, nos mesmos nomes, aprovados pelo PO |
| 5 | **Retratos, crítico e vizinhos** (G1) | Avatar, crítico e vizinhos na linguagem nova, aprovados pelo PO |
| 6 | **Juntar na versão principal e ligar os testes no GitHub** (P1, P2) | `main` com o redesenho inteiro e os testes rodando a cada envio |
| 7 | **Evento de Natal** (J2) | Evento em dados, testado, com a arte do fogão e do enfeite aprovada |
| 8 | **QA da primeira hora e apresentação dos sistemas** (J3) | Lista de pontos de confusão resolvida |
| 9 | **Ajustes do celular** (C3, G4, J5) | Desempenho e memória medidos no aparelho, e notificação de prato pronto |
| 10 | **Dividir os arquivos grandes** (C1, C2) | `cafe_simulation.gd` e os três arquivos de interface divididos por assunto, com os mesmos testes passando |
| 11 | **Documentos em dia** (C6) e **limpeza** (C5) | Arquitetura, jogabilidade e progressão reescritas a partir do código |
| 12 | **Cidade com a luz nova e mais poses** (G2, G3) | Aprovados pelo PO |

A ordem 3 pode andar em paralelo com a 1 e a 2, porque depende só do PO e de um APK.
