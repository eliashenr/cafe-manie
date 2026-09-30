# Progressão

Referência: seções 22–24 e 119–120 do master prompt.

## Implementado (Fase 2)

- `data/progression/levels.tres` com os níveis 1–10. XP total por nível: 0, 30, 80, 160, 280, 450, 680, 980, 1360, 1830.
- **Fontes de XP:** retirar prato pronto do fogão (XP da receita) e cliente servido (3 XP).
- Subir de nível libera receitas (aviso "Nível N! Nova receita: …"). Móveis por nível chegam com a loja (Fase 3).

## Implementado (Fase 3/4)

- Móveis e expansões com nível mínimo (ver [economy.md](economy.md)).
- **Missões iniciais (seção 143)**, uma por vez, com dica sempre visível: são o tutorial (DT-019).

| # | Missão | Recompensa |
|---|---|---|
| 1 | Prepare 3 pratos | 30 ouro, 5 XP |
| 2 | Sirva 3 clientes | 30 ouro, 5 XP |
| 3 | Ganhe 100 Café Ouro em vendas | 40 ouro, 10 XP |
| 4 | Compre uma mesa | 20 ouro, 10 XP |
| 5 | Chegue ao nível 2 | 30 ouro |
| 6 | Expanda a cafeteria | 60 ouro, 20 XP |

O "jogador robô" do teste automático conclui as 6 em cerca de 5,5 minutos de jogo, chegando ao nível 4.

## Conquistas (seção 49)

| Conquista | Mede | Degraus (meta → título, ouro) |
|---|---|---|
| Clientes | clientes servidos | 1 → Primeiro Cliente (10) · 50 → Anfitrião (50) · 500 → Celebridade (200) |
| Pratos | pratos preparados | 10 → Chef Iniciante (15) · 100 → Chef Experiente (75) · 1000 → Chef Lendário (300) |
| Vendas | Café Ouro ganho em vendas | 500 → Empreendedor (25) · 5000 → Magnata (100) · 50000 → Lenda (500) |
| Expansões | expansões feitas | 1 → Primeira Expansão (20) · 2 → Crescendo (60) · 4 → Casa Cheia (150) |
| Beleza | maior beleza alcançada | 50 → Caprichoso (20) · 150 → Charmoso (60) · 300 → Deslumbrante (150) |
| Nível | maior nível | 3 → Aprendiz (20) · 5 → Gerente (50) · 10 → Dono de Sucesso (200) |
| Compras | móveis comprados | 1 → Primeira Compra (10) · 15 → Decorador (40) · 50 → Colecionador (150) |

## Recompensa diária (seção 51)

Sete dias seguidos, com o dia contado pela meia-noite local. Perder um dia volta ao Dia 1. Detalhes em [economy.md](economy.md) e DT-025.

## Decisões

- O sistema suporta até o nível 100, mas o conteúdo começa com os **níveis 1–10** e só expande depois de validado (seção 119).
- A curva de XP e os desbloqueios por nível ficam em dados. Nunca `if level == 27` no código (seção 83).
- Primeiro conteúdo planejado (seção 120): 6 receitas, 8 móveis, 2 tipos de cliente, 1 garçom e 6 missões iniciais (seção 143).
- As faixas de nível têm identidade própria (seção 23). Os nomes das faixas ainda são provisórios.
