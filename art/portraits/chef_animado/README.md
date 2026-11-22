# Chef animado — DT-110

O PO aprovou o chef parado DT-109 e a animação DT-110 em 22/11/2026, mantendo o rosto e os encaixes. Também autorizou a publicação do chef junto à interface DT-111 (Loja/Reforma, HUD e Cidade). O aceite abrange este chef canônico; não aprova as variantes do compositor modular DT-107. Commit, envio e integração ainda não são resultados registrados neste documento.

## Fonte preservada

`art/avatar/chef_vestido_v1.png` é a base canônica aprovada e permanece intacta (SHA-256 em `proveniencia.json`). Rosto, cabelo, chapéu, pescoço, gola, lenço e roupa pertencem à mesma textura. A respiração e o cumprimento movem uma malha contínua, sem remontar partes separadas.

## Piscada

`chef_blink_half_v1.png` e `chef_blink_closed_v1.png` foram geradas pela ferramenta de imagens integrada da OpenAI, usando a base aprovada como alvo de edição. `prompts.json` guarda os dois pedidos exatos; `proveniencia.json` guarda origem e hashes. São PNGs originais RGBA 1122×1402, copiados sem processamento posterior.

**Não usar esses retratos inteiros como quadros.** A geração altera detalhes fora dos olhos. O shader lê somente as duas regiões de pálpebras configuradas em `art/avatar/chef_blink_v1.json`; fora delas usa os pixels da base aprovada. O alfa vem sempre da base, inclusive dentro das regiões. Máscaras elípticas inscritas nas caixas suavizam a borda em pele adjacente. As amostragens ocorrem antes de decisões por pixel para evitar derivadas inconsistentes na filtragem.

Contrato de configuração, versão 1:

- `half_texture` e `closed_texture`: caminhos `res://` das fontes importadas.
- `eyes.left/right`: esquerda/direita do observador. Cada olho tem `destination`, `half_source`, `closed_source` em `[x,y,w,h]` normalizados na respectiva imagem.
- `feather`: fração local da borda de cada região com mistura suave.
- Candidato atual: esquerda `[502,522,125,86]`, direita `[666,501,91,87]` em pixels da fonte 1122×1402, mistura 0,10. Apenas a região delimitada pode mudar durante a piscada.

## Componente e revisão

`scenes/ui/chef_animated_portrait.gd` e `art/shaders/chef_portrait_motion.gdshader` são independentes do compositor modular DT-107 reprovado. Cada retrato possui seu material/tempo. `animated=false` volta ao original; `paused=true` congela o quadro; ocultar interrompe processamento sem acumular tempo oculto. `set_sample(time_seconds, greeting_age=-1, blink=-1)` fornece amostras reproduzíveis para capturas, com piscada forçada 0/0,5/1. A área de toque permanece fixa.

A caixa desenhada reproduz o arredondamento inteiro de `TextureRect.KEEP_ASPECT_CENTERED`. O filtro é Linear, igual ao viewport próprio do AcceptDialog da prova aprovada. Não confundir esse padrão com o filtro Linear Mipmap configurado para o viewport raiz do projeto: forçá-lo no retrato muda a nitidez que o PO aprovou.

`Revisar Chef Animado.cmd` abre a prova no café real, minimizada e sem salvar. O iniciador isola APPDATA/LOCALAPPDATA em `build/chef-animado/`. O botão Chef reabre a prova nesta sessão. A demonstração não oferece o presente diário ao restaurar a janela. A prova estática DT-109 permanece disponível; a integração DT-111 reutiliza este componente para o chef canônico sem alterar IDs ou saves.

Capturas e testes constam do topo de `docs/status.md`; os logs e quadros ficam em `build/chef-animado/`. Comparar sempre original, olhos abertos/meios/fechados e extremos do cumprimento, no tamanho do jogo e ampliado. A animação recebeu avaliação visual própria do PO após a prova estática.

Reprodução das provas, a partir da raiz (dados isolados automaticamente):

```powershell
& ./tools/revisao/revisar_chef_animado.ps1 -Mode foto -View suite -Resolution 1280x720 -Out build/chef-animado/capturas/final/chef_1280.png
& ./tools/revisao/revisar_chef_animado.ps1 -Mode foto -View suite -Resolution 960x540 -Out build/chef-animado/capturas/final/chef_960.png
& ./tools/revisao/revisar_chef_animado.ps1 -Mode foto -View movimento -Detail -Out build/chef-animado/capturas/movimento-final/chef.png
```

`suite` grava 11 fotos por resolução; `movimento`, capa e 180 quadros a 30 fps, com cumprimento em 0,8 s e piscada automática. A revisão interativa oferece Pausar/Retomar, Cumprimentar e Ver original aprovado; espaço pausa, G cumprimenta, D amplia, C reabre e N alterna dia/noite. Os atalhos de movimento são consumidos antes da GUI, para não acionar simultaneamente um botão focado.

Validação da DT-110: 779 testes gerais, quatro focados repetidos após filtro final, cena principal e 22 verificações de interação passaram. A pose neutra final coincide pixel a pixel com o retrato histórico aprovado; alfa e área fora dos olhos permanecem idênticos na prova GPU. 203 capturas finais do café (incluindo capas) e verificação independente dos extremos do movimento. Animação aprovada pelo PO; publicação autorizada junto à DT-111. Os resultados posteriores da interface ficam nos documentos da DT-111.
