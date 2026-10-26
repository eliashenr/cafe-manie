# Economia

Referência: seções 25–31 e 84–86 do master prompt.

## Implementado (Fase 2)

- `Wallet` com saldo por moeda e registro das últimas 200 transações (origem, valor, saldo).
- **Entradas de Café Ouro:** ouro inicial (200) e pagamento dos clientes (preço da receita × multiplicador do tipo).
- **Saídas:** ingredientes ao começar a cozinhar.

## Implementado (Fase 3)

- **Entradas:** recompensas das missões iniciais.
- **Saídas:** móveis (cobrados ao confirmar a posição) e expansões (com confirmação).
- Móvel guardado vai para o inventário e volta de graça. Ainda não existe venda.

### Móveis (em `data/furniture/`)

| Móvel | Preço | Nível |
|---|---|---|
| Cadeira | 30 | 1 |
| Planta | 40 | 1 |
| Mesa | 60 | 1 |
| Balcão | 120 | 1 |
| Fogão | 150 | 1 |
| Mesa longa | 110 | 3 |

### Decoração nova (Fase 3)

| Item | Preço | Nível | Beleza |
|---|---|---|---|
| Vaso de flores | 55 | 1 | 18 |
| Luminária | 70 | 2 | 20 |
| Estante de livros (2×1) | 150 | 3 | 35 |

### Revestimentos (em `data/surfaces/`)

| Revestimento | Tipo | Preço | Nível | Beleza |
|---|---|---|---|---|
| Piso bege | piso | inicial | — | 0 |
| Assoalho de madeira | piso | 90 | 1 | 10 |
| Azulejo azul | piso | 160 | 2 | 15 |
| Xadrez bistrô | piso | 220 | 3 | 20 |
| Mármore | piso | 400 | 5 | 30 |
| Parede creme | parede | inicial | — | 0 |
| Tijolinho | parede | 120 | 1 | 10 |
| Listras menta | parede | 180 | 2 | 15 |
| Azul-marinho | parede | 250 | 4 | 20 |

Pisos novos (DT-089). O preço por piso pintado é cerca de 1/16 do preço da compra.

| Piso | Coleção | Preço | Por piso | Nível | Beleza |
|---|---|---|---|---|---|
| Carvalho Claro | Clássico | 130 | 8 | 2 | 13 |
| Carpete Laranja 70 | Anos 70 | 170 | 11 | 3 | 16 |
| Pedra de Fazenda | Country | 200 | 13 | 4 | 19 |
| Xadrez Pastel | Festa | 210 | 13 | 4 | 19 |
| Xadrez Vermelho | Americano | 210 | 13 | 4 | 20 |
| Ladrilho Clássico | Clássico | 240 | 15 | 4 | 21 |
| Cotto Toscano | Italiano | 250 | 16 | 5 | 22 |
| Azulejo Talavera | Mexicano | 290 | 18 | 6 | 25 |
| Porcelanato Branco | Clássico | 300 | 19 | 6 | 24 |
| Madeira Hinoki | Japonês | 340 | 21 | 7 | 27 |
| Parquê Escuro | Clássico | 360 | 23 | 7 | 28 |
| Grade Neon | Anos 80 | 360 | 23 | 7 | 28 |
| Ladrilho Hidráulico | Brasileiro | 400 | 25 | 8 | 30 |
| Madeira de Demolição | Anos 2010 | 440 | 28 | 9 | 31 |
| Ladrilho Parisiense | Francês | 460 | 29 | 9 | 32 |
| Piso Espelhado | Balada | 500 | 32 | 10 | 34 |
| Mármore Negro | Clássico | 520 | 33 | 10 | 34 |
| Granilite Rosa | Italiano | 560 | 35 | 11 | 35 |
| Mosaico Dourado | Clássico | 640 | 40 | 12 | 36 |
| Chevron Preto e Branco | Anos 2010 | 700 | 44 | 13 | 37 |
| Ônix Verde | Clássico | 760 | 48 | 14 | 38 |
| Pista Galáxia | Balada | 900 | 56 | 16 | 40 |

### Outras entradas e saídas

- **Venda de móveis:** devolve 50% do preço. O último fogão e o último balcão não podem ser vendidos.
- **Conquistas:** 7 conquistas com 3 degraus cada, de 10 a 500 de ouro por degrau (ver [progression.md](progression.md)).
- **Recompensa diária:** 7 dias. 50 ouro → 20 XP → Vaso de flores → 100 ouro → Tijolinho → 150 ouro + 30 XP → Estante de livros + 200 ouro.

### Expansões (em `data/config/expansions.tres`)

| Tamanho | Nível | Preço |
|---|---|---|
| 8×8 (inicial) | — | — |
| 10×8 | 2 | 150 |
| 10×10 | 3 | 300 |
| 12×10 | 5 | 600 |
| 12×12 | 7 | 1000 |

### Receitas (placeholders de balanceamento, em `data/recipes/`)

| Receita | Tempo | Porções | Custo | Preço/porção | Lucro da fornada | XP | Nível |
|---|---|---|---|---|---|---|---|
| Café | 0:15 | 6 | 6 | 3 | 12 | 2 | 1 |
| Pão de queijo | 0:40 | 8 | 15 | 4 | 17 | 4 | 1 |
| Misto-quente | 1:30 | 8 | 25 | 6 | 23 | 8 | 2 |
| Bolo de cenoura | 3:00 | 12 | 40 | 7 | 44 | 14 | 3 |
| Coxinha | 5:00 | 16 | 60 | 8 | 68 | 22 | 4 |
| Lasanha | 15:00 | 20 | 120 | 14 | 160 | 50 | 6 |

Receitas longas rendem mais por fornada e menos por minuto: premiam quem volta depois (o "cozinhar e sair" do gênero). Um teste garante que toda receita dá lucro quando vendida inteira.

### Primeiro dado de balanceamento

No teste de turno longo (30 min simulados, robô cozinhando sem parar, café inicial): 282 clientes servidos, 0 irritados, ouro 200 → ~750, nível 7, popularidade 100%. Isso indicava que o jogo estava **fácil demais** e subia de nível rápido demais. O balanceamento de 23/10 (abaixo) corrigiu.

## Balanceamento de 23/10 (DT-075)

Pedido do PO: "nível médio", para o jogador se prender sem passar raiva e sem conseguir tudo fácil.

### Como medir

```bash
godot --headless -s res://tools/balance_report.gd -- 10 0.25
```

- Um robô joga um jogo novo de verdade, com os dados reais, por 10 horas de jogo ativo (passo de 0,25 s).
- **O que o robô faz:** cozinha o que os clientes pediram (senão a receita mais lucrativa que fica pronta em até 3 minutos); compra mesas, fogões e balcões conforme sobe; contrata um garçom a cada 4 mesas; expande o café.
- **O que o robô não faz:** não compra enfeites nem luxo, e não cozinha pratos longos para sair do jogo.
- **O relatório mostra:** os minutos até cada nível, o ouro e os clientes por hora, a popularidade e o motivo de cada cliente irritado.
- **Leitura:** o robô joga sem parar e sem errar; uma pessoa leva cerca de 1,7 vez mais tempo.

### Antes e depois

| | Antes | Depois | Meta (robô) | Para uma pessoa |
|---|---|---|---|---|
| Nível 5 | 5 min | 1,5 min | rápido | ~5 min |
| Nível 8 | 28 min | 29 min | — | ~50 min |
| Nível 10 | 25 min* | 1 h 07 | ~1 h 10 | ~2 h |
| Nível 15 | 1 h 18* | 4 h 26 | ~4 h | ~7 h 30 |
| Nível 19 | 2 h 35* | 9 h 05 | — | ~15 h |
| Popularidade | 6% a 18% (robô antigo) | 68% a 100% | alta | — |
| Clientes irritados | 26% | 13% | baixo | — |

\* Com o robô novo e só a correção do cardápio, antes da curva nova.

- **Os irritados que sobraram** são pedidos rápidos (café, pão de queijo) feitos quando todos os fogões estavam ocupados ou os balcões cheios.
  - É pressão de jogo legítima: deixar café pronto no balcão resolve.

### Ouro

- **Jogo ativo só com pratos rápidos:** de 4.000 a 7.600 de ouro por hora (o robô).
  - O ouro por hora não sobe muito com o nível, porque o que limita são os clientes (mais de mil por hora) e o preço do prato rápido.
- **Pratos longos, cozinhados antes de sair, valem muito mais por cliente:** a picanha sai por 44 a porção, contra 3 do café.
  - Quem cozinha antes de sair e vende quando volta ganha bem mais: é o laço "cozinhar e sair" do gênero.
- **Preços contra o ouro de jogo ativo:**

  | Item | Nível | Preço | Tempo de jogo ativo |
  |---|---|---|---|
  | Portas | 3 a 7 | 450 a 700 | 5 a 10 min (enfeite com beleza) |
  | Peças do avatar | 3 a 12 | 300 a 800 | 5 a 15 min (cosmético) |
  | Coroa e dólmã dourado | 20 | 4.500 e 5.500 | ~1 h (prestígio) |
  | Balcão de Entregas | 8 | 1.500 | ~20 min |
  | Terraço | 10 | 3.000 | ~40 min |
  | Garçons | 3 a 18 | 500 a 14.000 | até ~3 h |
  | Filial na praia | 15 | 8.000 (abrir) | ~2 h |
  | Melhorias da filial | — | 12.000 a 45.000 | 3 a 10 h (meta de longo prazo) |

- Do nível 10 ao 15 o jogador ganha uns 18 mil de ouro e quer gastar uns 26 mil (expansões, terraço, garçom, filial, fogão temático). Ou seja, precisa escolher: é a tensão boa do "médio".

### Rendas extras (por dia, coletando com frequência)

| Fonte | Quanto | Comentário |
|---|---|---|
| Filial nível 1 / nível 4 | até 5.760 / até 23.000 | renda passiva; a abertura se paga em ~1,5 dia |
| Vizinhos | ~1.000 + 70 XP | pequeno, para voltar todo dia |
| Entregas | até ~8.000 com pratos caros | depende do que está no balcão |
| Chão sujo | 5 por mancha | só um agrado; o importante é a popularidade |

### Monetização

- Os pacotes de Café Ouro vão de 500 (R$ 4,90) a 15.000 (R$ 99,90), ou seja, de alguns minutos a umas 4 a 6 horas de jogo ativo.
- Quem paga compra conveniência; quem não paga progride (seção 86). Não mudou nada aqui.

## Decisões

- **IDs internos neutros:** `soft_currency` (moeda comum) e `premium_currency` (moeda premium). Os nomes exibidos ("Café Ouro" e "Café Grana", provisórios) ficam em dados, para que renomear não mexa em código. Ver o risco de marca em [roadmap.md](roadmap.md#riscos-acompanhados).
- **Toda alteração de moeda passa por um único serviço de transações**, que registra origem, valor e saldo resultante. No MVP roda localmente; na Fase 6 o servidor passa a validar (seção 62).
- **Preços, recompensas e pacotes são dados**, nunca números no código (seção 28).
- **Pagamentos reais não entram no protótipo.** Compras premium usam `TEST PURCHASE` (seção 150).

## Princípios de balanceamento

- Quem não paga precisa conseguir progredir; quem paga compra conveniência e personalização (seção 86).
- Sem vantagem competitiva direta comprável (seção 29).
