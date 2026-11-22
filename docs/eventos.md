# Calendário de eventos

Regra do PO (20/11/2026): **todo evento que vai acontecer tem de ser preparado dentro do jogo, sem o PO precisar lembrar.**
"Natal, ano novo, páscoa e etc."

## Como a regra funciona

1. **No início de toda sessão**, o Claude compara a data de hoje com a tabela abaixo.
2. Se um evento começa em **menos de 6 semanas** e ainda não existe em `data/events/`, ele avisa o PO e propõe prepará-lo antes de qualquer outra tarefa.
3. Cada evento usa o sistema que já existe (DT-063): historinha com retrato, 5 missões com prazo, um fogão de prêmio que sobe de nível e um enfeite final. Não é preciso sistema novo, só dados e arte.
4. O evento volta sozinho todo ano nas mesmas datas. Datas móveis (Carnaval e Páscoa) têm de ser conferidas a cada ano.
5. Dois eventos não podem ter dias em comum: o jogo mostra um evento por vez.

## Calendário

| Evento | Datas no jogo | Prepare até | Situação |
|---|---|---|---|
| Halloween | 20/10 a 03/11 | 08/09 | Pronto (DT-063) |
| Natal | 01/12 a 26/12 | 20/10 | **Pronto e aprovado pelo PO** (DT-100, 20/11/2026) |
| Ano Novo | 27/12 a 06/01 | 15/11 | **Atrasado:** preparar logo depois do Natal |
| Carnaval | 2027: 05/02 a 10/02 (sexta antes até a quarta de cinzas) | 25/12 | A fazer. Data móvel |
| Páscoa | 2027: 21/03 a 29/03 (a semana até a segunda depois do domingo de Páscoa, 28/03) | 07/02 | A fazer. Data móvel |
| Festa Junina | 01/06 a 30/06 | 20/04 | A fazer |
| Dia das Crianças | 05/10 a 12/10 | 24/08 | A fazer |

Datas móveis de 2028, para conferir no ano que vem: Carnaval de 25/02 a 01/03; Páscoa em 16/04.

## Cuidados

- **Ids estáveis:** o id do evento e o do fogão de prêmio nunca mudam depois que houver saves usando.
- **Teste de cada evento:** os dados são válidos, as datas não se cruzam com outro evento, as missões carregam e o fogão de prêmio sobe de nível (ver `tests/unit/test_events.gd`).
- **Aprovação visual:** a arte do fogão, do enfeite e do retrato passa pela revisão do PO, como todo o resto.
