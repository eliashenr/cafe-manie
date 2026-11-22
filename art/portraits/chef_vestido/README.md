# Chef vestido — prova estática DT-109

Pedido do PO em 22/11/2026: primeiro refazer o chef completo e mostrá-lo parado no jogo, com roupa e chapéu encaixados. Essa prova estática foi aprovada, seguida pelo aceite da animação DT-110. A publicação do chef junto à interface DT-111 (Loja/Reforma, HUD e Cidade) está autorizada; este documento ainda não registra commit, envio ou integração.

## Arte

Fonte única: `art/avatar/chef_vestido_v1.png`, PNG RGBA 1122×1402. É a imagem original gerada, copiada sem pintura, remoção de fundo, recorte, mudança de escala ou composição posterior. O alfa é nativo. A gola traseira envolve a nuca, a gola dianteira encobre a base do pescoço e o toque/cabelo foram desenhados juntos. Esta prova não usa o compositor modular reprovado.

Geração pela ferramenta de imagens da OpenAI integrada ao Codex, com a identidade visual de `art/portraits/avatar_modular/referencia_rosto.png`. Essa referência é um arquivo histórico local, não incluído no pacote publicado e não necessário para executar ou revisar o chef; seu hash e tamanho ficam registrados em `proveniencia.json`. A pasta modular reprovada não integra esta entrega. Prompt exato em `prompt.txt`; identificação e SHA-256 da fonte canônica em `proveniencia.json`. A geração é probabilística: o PNG, e não uma futura regeneração pelo mesmo prompt, é a fonte canônica desta prova.

## Revisão no jogo

`Revisar Chef Vestido.cmd` abre o café real minimizado, com dados em memória e APPDATA/LOCALAPPDATA isolados em `build/chef-vestido/interactive/`. O diálogo usa o tema do jogo e uma única TextureRect estática: 210×255 unidades lógicas, ampliável para 336×408. C reabre a prova, D alterna o detalhe e N troca dia/noite. O botão Chef também abre esta prova, sem expor o editor modular antigo nesta sessão.

Capturas ocultas reproduzíveis, a partir da raiz:

```powershell
& ./tools/revisao/revisar_chef_vestido.ps1 -Mode foto -View suite -Resolution 1280x720 -Out build/chef-vestido/capturas/chef_1280.png
& ./tools/revisao/revisar_chef_vestido.ps1 -Mode foto -View suite -Resolution 960x540 -Out build/chef-vestido/capturas/chef_960.png
```

O PO **aprovou o retrato parado em 22/11/2026**: “Agora sim, ficou muito bom!” Depois aprovou a animação DT-110 mantendo esse rosto e os encaixes, e autorizou sua publicação junto à DT-111. Esses aceites não concluem todas as peças, cores ou expressões. A prova DT-109 não alterou save, IDs, compras, runtime de personalização ou sprites aprovados; a integração DT-111 reutiliza a composição canônica no jogo. As opções modulares reprovadas permanecem fora do aceite desta arte.
