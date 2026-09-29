# Decisões técnicas

Registro no formato da seção 99 do master prompt. As mais recentes ficam no topo.

---

## DT-006 — Entrada de toque sem emulação de mouse

**Problema:** por padrão a Godot gera um evento de mouse para cada toque. A câmera trata mouse e toque separadamente, então cada gesto seria processado duas vezes.

**Opção A:** manter a emulação e tratar só eventos de mouse.
**Opção B:** desligar a emulação (`input_devices/pointing/emulate_mouse_from_touch=false`) e tratar mouse e toque cada um no seu caminho.

**Impactos:** A perde a pinça com dois dedos, porque mouse só tem um ponteiro. B exige tratar os dois tipos de evento.

**Recomendação:** B.
**Motivo:** a pinça é essencial no celular (seção 41), e o tratamento duplo é pequeno e coberto por testes.

---

## DT-005 — Executor de testes próprio em vez de GUT

**Problema:** o discovery previa usar GUT (Godot Unit Test) para testes automatizados.

**Opção A:** instalar o GUT como addon.
**Opção B:** manter um executor próprio e mínimo (`tests/run_tests.gd`, cerca de 100 linhas).

**Impactos:** o GUT traz relatórios e mocks, mas é uma dependência externa que precisa acompanhar cada versão da Godot. O executor próprio não tem dependência, roda sem interface e reprova o teste quando ocorre um erro de script (verificado com um teste de sanidade propositalmente quebrado).

**Recomendação:** B por enquanto.
**Motivo:** regra de simplicidade (seção 94). Se precisarmos de mocks ou relatórios em CI, migrar para GUT é barato, porque os testes já seguem o mesmo formato (`test_*`).

---

## DT-004 — Piso desenhado por código no protótipo

**Problema:** como desenhar o piso isométrico antes de existir arte.

**Opção A:** `TileMapLayer` isométrico com um tileset placeholder.
**Opção B:** desenhar os losangos por código (`FloorView._draw`).

**Impactos:** A exige criar e manter um arquivo de tileset só para placeholder. B não usa nenhum asset e depende do mesmo `IsoProjection` que a lógica de clique usa, então visual e clique nunca divergem.

**Recomendação:** B agora. Reavaliar `TileMapLayer` quando chegar a arte final de pisos (Fase 8).
**Motivo:** o que importa no protótipo é o clique cair no piso certo, e isso fica garantido por construção.

---

## DT-003 — Grid lógico cartesiano com projeção isométrica separada

**Problema:** onde vive a "verdade" sobre posições de objetos.

**Opção A:** usar coordenadas do `TileMap` como verdade.
**Opção B:** grid lógico próprio (`CafeGrid`) em coordenadas inteiras, com conversão para tela em `IsoProjection`.

**Impactos:** B é testável sem tela, serve de base direta para `AStarGrid2D` no pathfinding e pode ser validado no servidor.

**Recomendação:** B.
**Motivo:** seções 15, 16, 62 e 152.

---

## DT-002 — Formato de dados de conteúdo

**Problema:** formato de receitas, móveis e níveis.

**Opção A:** JSON.
**Opção B:** Custom Resources da Godot (`.tres`).

**Impactos:** Resources são tipados, editáveis no inspetor e acusam erro de campo claramente. JSON é melhor para trafegar pela rede.

**Recomendação:** Resources para conteúdo e JSON para save e sincronização.
**Motivo:** o PO consegue balancear preços e tempos direto no editor, sem abrir código. *Aplicação a partir da Fase 1 (móveis).*

---

## DT-001 — Código no GitHub, testes na nuvem, teste visual no PC do PO

**Problema:** onde o código vive e como o PO testa.

**Decisão do PO:** repositório `eliashenr/cafe-manie` no GitHub.

**Como funciona:** o Claude desenvolve e roda os testes automatizados num ambiente próprio, com Godot 4.7.2 sem interface, e envia os commits ao GitHub. O PO baixa o projeto e roda na Godot do próprio PC para o teste visual e de sensação.
