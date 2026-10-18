class_name Juice
extends RefCounted
## "Juice": animações curtas por Tween para as coisas não aparecerem secas (surgir, quicar, acender).
## Só mexem em escala e transparência dos nós de tela; a regra do jogo não fica sabendo.

## Surgir: começa menor e cresce passando um pouco do tamanho (TRANS_BACK), em segundos.
const POP_FROM := 0.55
const POP_TIME := 0.38
## Quicar: cresce este tanto e volta.
const BUMP_SCALE := 1.16
const BUMP_TIME := 0.32
## Acender: de transparente a opaco.
const FADE_IN_TIME := 0.18


## Surge crescendo a partir da base do nó (Node2D) ou do centro (Control).
static func pop_in(node: CanvasItem) -> Tween:
	_center_pivot(node)
	node.scale = Vector2.ONE * POP_FROM
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Quica uma vez (cresce e volta ao tamanho, com sobra).
static func bump(node: CanvasItem) -> Tween:
	_center_pivot(node)
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector2.ONE * BUMP_SCALE, BUMP_TIME * 0.35).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, BUMP_TIME * 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Acende de transparente a opaco.
static func fade_in(node: CanvasItem) -> Tween:
	node.modulate.a = 0.0
	var tween := node.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, FADE_IN_TIME).set_ease(Tween.EASE_OUT)
	return tween


## Anima uma propriedade numérica de [param from] até [param to] com sobra no fim (quique de chegada).
static func settle(node: Object, property: String, from: float, to: float, duration := POP_TIME) -> Tween:
	node.set(property, from)
	var tween := (node as Node).create_tween()
	tween.tween_property(node, property, to, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


static func _center_pivot(node: CanvasItem) -> void:
	if node is Control:
		(node as Control).pivot_offset = (node as Control).size / 2.0
