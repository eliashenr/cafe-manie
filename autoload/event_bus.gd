extends Node
## Canal central de sinais entre sistemas.
##
## Sistemas emitem e escutam aqui em vez de se referenciarem diretamente,
## o que mantém os módulos desacoplados. Só declare aqui sinais que mais de
## um sistema precisa conhecer.

## Uma mensagem curta para o jogador (subiu de nível, ação recusada...).
## Quem mostra é o HUD; qualquer sistema pode publicar.
@warning_ignore("unused_signal")
signal message_posted(text: String)
