# Roadmap

Baseado na seção 82 do master prompt. Uma fase só termina quando cumpre seu marco de saída.

| Fase | Entrega | Marco de saída | Status |
|---|---|---|---|
| 0 — Fundação | Git, projeto Godot, estrutura, docs, testes rodando | Projeto abre sem erros e os testes passam | ✅ Concluída |
| 1 — Protótipo | Grid isométrico, câmera, seleção, móveis genéricos no grid | O PO posiciona móveis com mouse e toque | 🟡 Em andamento |
| 2 — Core gameplay | Cozinha, balcão, cliente, garçom, Café Ouro, XP | O loop completo roda sozinho | ⏳ |
| 3 — Cafeteria | Loja, inventário, decoração, expansão | Comprar → posicionar → salvar | ⏳ |
| 4 — Progressão | Níveis 1–10, missões, tutorial, conquistas | **Vertical Slice validada** (seção 81) | ⏳ |
| 5 — Social | Amigos, visitas, mapa, rankings | Só depois da slice validada e divertida | ⏳ |
| 6 — Backend | Autenticação, cloud save, economia no servidor | | ⏳ |
| 7 — Monetização | Café Grana, loja premium, compras de teste | Revisão jurídica feita antes (ver riscos) | ⏳ |
| 8 — Conteúdo | Níveis, receitas, móveis, personagens, eventos | Plano de arte definido | ⏳ |
| 9 — QA | Testes, performance, segurança, regressão | | ⏳ |
| 10 — Release | Android, publicação, analytics | | ⏳ |

## Fase 1 — detalhamento

- [x] Grid lógico 8×8 com ocupação, colisão e expansão
- [x] Projeção isométrica com clique preciso
- [x] Câmera: arrastar, zoom com roda e pinça, limites
- [x] Seleção de piso com destaque
- [ ] Definição de móvel por dados (Resource) e instância no grid
- [ ] Modo de construção: escolher um móvel, ver prévia verde/vermelha e posicionar
- [ ] Mover e remover móveis
- [ ] Ordenação de desenho isométrico (y-sort) com objetos de várias células
- [ ] Validação: nenhum móvel pode bloquear o caminho da entrada até mesas, balcão e fogões

## Riscos acompanhados

| Risco | Mitigação | Quando tratar |
|---|---|---|
| Nome "Café Manie" e moedas "Café Ouro/Grana" parecidos com o Café Mania original | IDs internos neutros; nomes na tela ficam em dados. Busca no INPI | Antes da Fase 7 |
| Arte 2D isométrica consistente é o maior gargalo | Plano de arte (artista, pacote licenciado ou IA com revisão) | Antes da Fase 8 |
| Menores + compras + chat (classificação 12 anos, ECA Digital) | Validação jurídica | Antes das Fases 5 e 7 |
| Pathfinding com layout editável (garçom preso) | Validação de caminho ao posicionar + testes | Fases 1–2 |
| Desempenho em Android de entrada | Medir num aparelho real a partir da Fase 2 | Fase 2 em diante |
