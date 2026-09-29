# Progressão

Referência: seções 22–24 e 119–120 do master prompt.

## Implementado (Fase 2)

- `data/progression/levels.tres` com os níveis 1–10. XP total por nível: 0, 30, 80, 160, 280, 450, 680, 980, 1360, 1830.
- **Fontes de XP:** retirar prato pronto do fogão (XP da receita) e cliente servido (3 XP).
- Subir de nível libera receitas (aviso "Nível N! Nova receita: …"). Móveis por nível chegam com a loja (Fase 3).

## Decisões

- O sistema suporta até o nível 100, mas o conteúdo começa com os **níveis 1–10** e só expande depois de validado (seção 119).
- A curva de XP e os desbloqueios por nível ficam em dados. Nunca `if level == 27` no código (seção 83).
- Primeiro conteúdo planejado (seção 120): 6 receitas, 8 móveis, 2 tipos de cliente, 1 garçom e 6 missões iniciais (seção 143).
- As faixas de nível têm identidade própria (seção 23). Os nomes das faixas ainda são provisórios.
