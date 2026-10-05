class_name CollectionDefinition
extends Resource
## Coleção de itens da loja (dado de conteúdo, em res://data/collections):
## um estilo ou uma cultura, como "Anos 80", "Country" ou "Japonês". Móveis e
## revestimentos dizem a que coleção pertencem; a loja filtra por ela.

## Identificador único e estável. Nunca mude depois que houver itens usando.
@export var id: StringName
@export var display_name := ""
## Cor do botão da coleção na loja.
@export var color := Color.WHITE
## Posição na lista da loja (menor vem antes).
@export var order := 0


func is_valid() -> bool:
	return id != &"" and not display_name.is_empty()
