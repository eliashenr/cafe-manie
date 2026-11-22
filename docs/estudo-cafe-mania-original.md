# Estudo do Café Mania original e direção da próxima revisão

Pesquisa de 22/11/2026, a pedido do PO. Objetivo: aprender com o original e reorganizar a apresentação do Café Manie, preservando sua estrutura aprovada. Este documento registra evidências e propostas; não altera regras, preços ou conteúdo.

## 1. Resultado e alcance

O ganho mais promissor está na leitura do café: ações claras, coleções coerentes, comida reconhecível e recompensas visíveis. Nossa estrutura já comporta isso. Não há motivo para começar outro redesenho geral do cenário aprovado.

Foram lidos os dois artigos indicados da Wikipédia, nove publicações oficiais identificadas abaixo, a galeria pública de fotos e portfólios dos próprios artistas, além de entrevista com um fundador e registros contemporâneos de jogadores. As imagens atuais do projeto e os arquivos de apresentação foram comparados com essas referências.

**Limites:** isso não é uma leitura de todo o histórico do Facebook. O feed passou a exigir login durante a rolagem; fotos e detalhes públicos continuaram acessíveis. A amostra oficial detalhada cobre fevereiro–novembro de 2014. O antigo blog da Vostu falhou ao abrir. Não foi recuperada uma tabela oficial completa de receitas, preços, câmbio de CaféGranas ou todas as missões. Resultados de busca sem página aberta e relatos de fãs são identificados como tais. Não se usaram remakes modernos como prova do original.

## 2. O avatar reprovado: diagnóstico e próximo critério de qualidade

O PO identificou corretamente o pescoço sobre a roupa e o chapéu colocado sobre a cabeça sem encaixe. A avaliação anterior do Codex deixou passar esses defeitos. Os 775 testes funcionais e as capturas sem cortes não comprovam que a roupa veste o personagem.

Em `scenes/ui/avatar_portrait.gd`, a roupa inteira é desenhada antes da face inteira, que inclui o pescoço. A calibração leva a base do pescoço a y=127 na caixa de 140×170. Há sobreposição opaca com a roupa de cerca de 11,25 pixels no centro, chegando a 16,5 nas laterais. Assim, a pele apaga a frente da gola. Desenhar a roupa inteira depois também não resolve: parte da gola deve ficar atrás do pescoço, parte à frente.

O chapéu usa uma imagem inteira e uma âncora fixa sobre todo o cabelo. Faltam abertura/volume de contato, borda traseira e frontal e cabelo acomodado sob a copa. A cabeleira também não distingue mechas traseiras e frontais. O pivô comum mantém as peças juntas, mas não produz essas relações de profundidade; o giro da cabeça com roupa respirando separadamente pode tornar a emenda ainda mais evidente.

**Próxima prova proposta:** um chef completo, parado, com cabelo curto, roupa branca e toque, produzido como uma composição única de anatomia, perspectiva, materiais e sombras de contato. Só derivar camadas quando a recomposição reproduzir esse conjunto. Se a separação não conservar os contatos, usar renderizações da combinação vestida em vez de insistir em peças genéricas sobrepostas. A solução técnica precisa preservar a personalização existente, seus IDs e saves.

Critérios visuais antes de qualquer expansão:

1. Nenhuma base horizontal do pescoço à vista; frente da gola por cima da pele e parte traseira por trás.
2. Chapéu acompanha a perspectiva e a largura do crânio; cabelo não atravessa a copa e não existe vão artificial.
3. Resultado convincente parado no tamanho real de 210×255 e em ampliação; animação não serve para esconder defeitos.
4. Recomposição fiel à referência completa; depois conferir todas as roupas e combinações previstas.
5. Piscada e gesto preservam gola, chapéu e contato com o corpo em todos os quadros.

A montagem DT-107 atual foi reprovada e permanece local. A unificação da Loja é uma mudança separada, ainda sem aceite próprio. As entregas DT-105/106 aprovadas permanecem na main.

## 3. Publicações oficiais do Facebook

Leitura direta no navegador, incluindo texto, data e imagens quando disponíveis. Os números são históricos, não parâmetros aprovados para Café Manie.

| Data | Evidência oficial | O que podemos aprender |
|---|---|---|
| 18/02/2014 | [Retorno do Papa dos Pudins](https://www.facebook.com/photo/?fbid=659682144074045): missões davam um Gerador Intergalático; anúncio permite dois ao mesmo tempo. Arte destaca energia e prazo de 19/02. | Apresentar personagem, tarefa, equipamento e benefício na mesma comunicação. Não foi confirmado o ritmo de geração de energia. |
| 17/03/2014 | [Meu Café ficou Show](https://www.facebook.com/photo/?fbid=672079092834350): concurso para decorar um palco e enviar uma captura; prêmios de 10.000, 5.000 ou 1.000 CaféGranas, prazo de 31/03/2014 às 23h59. | A decoração tinha valor como expressão do jogador. Uma prévia da coleção e um objetivo visual podem ser mais compreensíveis que uma lista abstrata de itens. |
| 28/03/2014 | [Lembrete do concurso e catálogo](https://www.facebook.com/photo/?fbid=677881158920810): imagem compacta de categorias e peças, com números 3 e 2 junto ao ícone de cédula e 100.000 em outro cartão. | Separar preço, moeda e requisito com clareza. A imagem não permite identificar com segurança todos os IDs ou a denominação de cada valor; não reconstruir uma tabela a partir dela. |
| 07/04/2014 | [Café premiado no concurso](https://www.facebook.com/photo/?fbid=682662931775966): salão com palco, mesas, buffet e decoração temática. | O jogador compunha áreas reconhecíveis. É uma criação da comunidade publicada oficialmente, não um layout padrão obrigatório. |
| 09/05/2014 | [Anúncio do segundo piso](https://www.facebook.com/photo/?fbid=698217760220483): novidade anunciada para breve. A arte contém uma casa e cédulas com “×50”. | Mostrar evolução espacial concreta. O “×50” sozinho não estabelece preço ou bônus. |
| 13/05/2014 | [Segundo piso disponível](https://www.facebook.com/photo/?fbid=700319103343682): publicação informa que a novidade chegou. | Diferenciar promessa, disponibilidade e desbloqueio nas telas. Não é proposta de acrescentar um piso ao projeto agora. |
| 03/07/2014 | [Barraquinha de Frios](https://www.facebook.com/photo/?fbid=729587217083537): missão para desbloquear pratos, prazo de 06/07. | Exibir a barraca e a comida como recompensa reconhecível, com prazo junto à ação. |
| 08/07/2014 | [Prato secreto](https://www.facebook.com/photo/?fbid=732635226778736): personagem e silhueta de prato anunciam uma novidade. | Usar mistério na apresentação de conteúdo futuro; quando já jogável, oferecer orientação clara para encontrá-lo. |
| 03/11/2014 | [Convite para encontrar vizinhos](https://www.facebook.com/photo/?fbid=789788304396761): comunicação voltada a relações entre jogadores. | Vizinhos pertencem a uma área social identificável; não precisam competir permanentemente com os controles do salão. |

**Leitura visual:** as campanhas observadas repetem um personagem, objeto/prato principal, frase curta, prazo e contraste forte. Nosso equivalente pode conservar a paleta creme/café e o acabamento já aprovado, usando cor intensa apenas no prêmio e na ação principal. Isso é uma proposta de design, não uma exigência do original.

## 4. História: o que as páginas indicadas ajudam a entender

O [artigo Café Mania](https://pt.wikipedia.org/wiki/Caf%C3%A9_Mania) descreve o ciclo de cozinhar, servir, decorar, ampliar e personalizar o chef, além de missões, popularidade e filial na praia. Também registra campanhas de Guaraná Antarctica, AdeS e Netflix. É um mapa inicial de assuntos, não uma especificação completa do jogo.

Há uma inconsistência de cronologia: a Wikipédia informa 03/07/2010 na ficha, mas a [reportagem da Folha de 20/06/2010](https://www1.folha.uol.com.br/fsp/mercado/me2006201016.htm) já descrevia o Café Mania como lançado havia uma semana. Portanto, o jogo já estava disponível em junho de 2010; não fixar um dia de lançamento sem outra evidência. A Folha também cita feijoada/vatapá e interação da equipe com jogadores. Seus exemplos de valores em reais são de itens da empresa sem identificação segura do jogo; não são preços confirmados do Café Mania.

O [artigo Vostu](https://pt.wikipedia.org/wiki/Vostu) contextualiza a empresa fundada em 2007, seus jogos sociais e encerramento em 2016, mas sinaliza insuficiência de referências. Explicações sobre declínio e números de usuários não devem virar premissas de produto sem confirmação independente.

## 5. O que aprendemos com quem trabalhou na Vostu

**Recompensa visual e colaboração.** Na [entrevista de outubro de 2011 com Mario Schlosser](https://www.jugend-forscht.de/alumni/alumni-netzwerk/alumni-news/02/10/2011/auf-den-spuren-von-mark-zuckerberg-co.html), o fundador descreve equipes de arte, tecnologia e análise e relata que a aparência dos itens influenciava escolhas de muitos jogadores. Ele também descreve observação contínua do uso e mudanças frequentes de conteúdo. Trata-se do relato da empresa naquele período, não de uma estatística universal. Aplicação proposta: manter a divisão Claude/Codex e validar cada conjunto pelo que o jogador vê e entende, além dos testes funcionais.

**Coleções como conjunto.** [Erica Perez](https://www.behance.net/gallery/49023909/Cafe-Mania-Vostu), em portfólio publicado em 18/02/2017, relata ter começado em 2010 como colorista, criando paletas para o clima de coleções temporárias e colaborando com conteúdo. O portfólio foi aberto no navegador e mostra estudo de máquina isométrica do esboço ao desenho final e personagens completos. Aplicação: manter uma ficha de coleção com paleta, materiais, proporção, câmera e objetos exemplares antes de criar peças isoladas.

**Interface e personagens.** O [portfólio de Mariano Martin Garnero, publicado em 19/03/2014](https://www.behance.net/gallery/15414597/Cafemania-Vostu), foi aberto e inspecionado. Nas telas de entrada e peças promocionais, personagens completos enquadram uma ação principal evidente. Isso é referência de composição e autoria, sem provar que toda tela do jogo tinha a mesma estrutura ou que a arte era montada pelo mesmo processo.

**Pistas adicionais, com acesso limitado.** O [portfólio de fogões de Pablo Andreetta](https://www.behance.net/gallery/13034859/Isometric-Stoves-Cafe-Mania-%28Vostu%29), de 12/12/2013, foi localizado pelo índice, mas não inspecionado integralmente nesta rodada. Não usar como evidência de detalhes que ainda não vimos.

## 6. Missões, moedas e preços: confiança da informação

O concurso de 2014 e as campanhas da tabela acima são fontes oficiais diretamente verificadas. Confirmam tipos de prêmio, alguns números e prazos; não uma economia completa. Falta comprovar uma tabela oficial de receitas, tempos, custos, rendimento, preços de pacotes em reais e requisitos de todas as missões.

Há pistas contemporâneas de fãs:

- [Registro de fevereiro de 2011](https://cafemanialoko.blogspot.com/2011/02/mais-uma-ai.html) descreve uma introdução com cinco nachos e limpeza de cinco fogões, remetendo ao antigo blog oficial. O texto tem inconsistências de nomenclatura; tratar como pista, não copiar como contrato.
- [Arquivo de atualizações de 2010](https://jogandocafemania.blogspot.com/search/label/Atualiza%C3%A7%C3%B5es) relata recarga de energia por quatro CaféGranas e sequência de prêmios diários. A origem oficial referida não foi recuperada para todos os números; manter como informação secundária.
- [Relato de 11/09/2010](https://dicas-cafemania.blogspot.com/2010_09_11_archive.html) associa fogões de 15/25 CaféGranas a reduções de tempo de 10%/20%. É testemunho de jogador, sem confirmação oficial independente nesta pesquisa.

**Encaminhamento para Claude:** caso esses sistemas entrem no planejamento, levantar cada dado com fonte, data e moeda; comparar com a progressão atual e testar o ritmo de aquisição. Melhorias de apresentação podem começar com os dados existentes. Nenhum valor desta pesquisa foi aplicado a `core/` ou `data/`.

## 7. Comparação com Café Manie e prioridades propostas

Referências de layout complementares: [screenshot de 13/07/2010](https://entraecurte.blogspot.com/2010/07/cafe-mania.html), [tutorial de 04/11/2010](https://cafemvicio.blogspot.com/2010/11/tutorial-cafe-maniacomo-comecar-jogar.html) e [coleção japonesa de 22/07/2010](https://jogandocafemania.blogspot.com/2010/07/chegaram-os-itens-do-japao.html). São publicações de jogadores da época: mostram status no topo, ferramentas inferiores, ações no fogão e coleções atravessando móveis/revestimentos/receitas. A estrutura atual já tem boa parte dessa organização. As propostas abaixo são julgamento do Codex, ainda não implementadas.

| Ordem | Ajuste proposto | Problema concreto e preservação |
|---|---|---|
| 1 | Refazer o encaixe do chef a partir de um personagem vestido completo | Corrigir gola, pescoço, cabelo e chapéu; avaliar parado antes de animar. Preservar identidade, personalização e save. |
| 2 | Facilitar encontrar janelas e portas dentro da Loja | `build_bar.gd::_shop_items` mistura revestimentos, portas e itens de parede na aba Paredes. Acrescentar filtros de tipo, mantendo os temas Japão/Brasil/etc. e os seis grupos atuais. Um único acesso à Loja. |
| 3 | Missão compacta com controle explícito de expandir | Hoje tocar no cartão o recolhe, mas a ação não é indicada. Mostrar seta/rótulo, título, progresso e prêmio; abrir detalhes sob demanda. Não alterar tarefas ou recompensas. |
| 4 | Navegação inferior menor e alinhada | Loja, Expandir, Garçom, Chef e Central têm distribuição desigual de título/custo. Padronizar duas linhas e reduzir espaço vazio, mantendo área de toque e informação necessária à compra. |
| 5 | Controles com significado inequívoco | A engrenagem atual chama `ask_restart`, que pergunta se deve apagar o progresso. Identificar a ação como Recomeçar ou colocá-la dentro de configurações explícitas; preservar confirmação e Cancelar. Agrupar pausa/abrir café, zoom e áudio por função. |
| 6 | Central identificada como Cidade, com Filial e Vizinhos | `city_dialog.gd` já contém essas duas áreas. Ajustar rótulo e descoberta, sem inventar outro módulo ou adicionar faixa social permanente. |
| 7 | Coleções e recompensas com composição própria | Mostrar conjuntos coerentes e prévia do prêmio com personagem, objetivo e prazo. Manter o cenário aprovado; reforçar contraste local dos alimentos e pontos de interação, sem aumentar ruído no ambiente. |

Beleza e Popularidade podem ser aproximadas visualmente numa rodada posterior, mantendo conceitos e valores distintos. O enquadramento isométrico, temas culturais, ações contextuais de cozinhar/servir e sistema de progressão permanecem.

## 8. Sequência de trabalho e critérios

Primeiro resolver uma prova estática do chef. Em paralelo de planejamento, preparar uma única revisão de navegação com filtros de parede e missão recolhível explícita. Depois avaliar barra inferior, controles e Cidade. Não executar todas as propostas como uma reforma simultânea.

Para cada rodada: um resultado pequeno, captura no tamanho real em 1280×720 e 960×540, verificação funcional apropriada, registro do aceite do PO. Testes de compra/save não substituem julgamento de encaixe e caimento. Exportações e imagens aprovadas anteriores devem permanecer preservadas.

**Divisão mantida:** Codex cuida da apresentação e registra contratos; Claude cuida de regras, economia, conteúdo e calendário. O Ano Novo permanece uma pendência já atribuída ao Claude no calendário; esta pesquisa não o implementa. Nesta rodada houve pesquisa e atualização documental, sem mudança nova no runtime, geração de arte, commit ou envio.
