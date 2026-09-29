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

No teste de turno longo (30 min simulados, robô cozinhando sem parar, café inicial): 282 clientes servidos, 0 irritados, ouro 200 → ~750, nível 7, popularidade 100%. Isso indica que o jogo está **fácil demais** e sobe de nível rápido demais. Os números ficam como estão até o PO jogar e pedir **FAÇA BALANCEAMENTO**.

## Decisões

- **IDs internos neutros:** `soft_currency` (moeda comum) e `premium_currency` (moeda premium). Os nomes exibidos ("Café Ouro" e "Café Grana", provisórios) ficam em dados, para que renomear não mexa em código. Ver o risco de marca em [roadmap.md](roadmap.md#riscos-acompanhados).
- **Toda alteração de moeda passa por um único serviço de transações**, que registra origem, valor e saldo resultante. No MVP roda localmente; na Fase 6 o servidor passa a validar (seção 62).
- **Preços, recompensas e pacotes são dados**, nunca números no código (seção 28).
- **Pagamentos reais não entram no protótipo.** Compras premium usam `TEST PURCHASE` (seção 150).

## Princípios de balanceamento

- Quem não paga precisa conseguir progredir; quem paga compra conveniência e personalização (seção 86).
- Sem vantagem competitiva direta comprável (seção 29).
