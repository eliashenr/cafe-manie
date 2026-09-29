# Economia

Referência: seções 25–31 e 84–86 do master prompt. **Nada implementado ainda** (entra na Fase 2).

## Decisões

- **IDs internos neutros:** `soft_currency` (moeda comum) e `premium_currency` (moeda premium). Os nomes exibidos ("Café Ouro" e "Café Grana", provisórios) ficam em dados, para que renomear não mexa em código. Ver o risco de marca em [roadmap.md](roadmap.md#riscos-acompanhados).
- **Toda alteração de moeda passa por um único serviço de transações**, que registra origem, valor e saldo resultante. No MVP roda localmente; na Fase 6 o servidor passa a validar (seção 62).
- **Preços, recompensas e pacotes são dados**, nunca números no código (seção 28).
- **Pagamentos reais não entram no protótipo.** Compras premium usam `TEST PURCHASE` (seção 150).

## Princípios de balanceamento

- Quem não paga precisa conseguir progredir; quem paga compra conveniência e personalização (seção 86).
- Sem vantagem competitiva direta comprável (seção 29).
