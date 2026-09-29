class_name TestCase
extends RefCounted
## Base dos testes. Cada método que começa com "test_" é um teste e roda
## numa instância nova desta classe. Pode usar await (testes de cena).

## Árvore de cena, para testes de integração que precisam instanciar cenas.
var tree: SceneTree

var failures: Array[String] = []
var _nodes_to_free: Array[Node] = []


## Adiciona um nó à árvore e garante que ele seja liberado ao fim do teste.
func add_to_tree(node: Node) -> Node:
	tree.root.add_child(node)
	_nodes_to_free.append(node)
	return node


func cleanup() -> void:
	for node in _nodes_to_free:
		if is_instance_valid(node):
			node.queue_free()
	_nodes_to_free.clear()


func assert_true(condition: bool, message := "") -> void:
	if not condition:
		_fail("esperado verdadeiro", message)


func assert_false(condition: bool, message := "") -> void:
	if condition:
		_fail("esperado falso", message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("esperado %s, obtido %s" % [_describe(expected), _describe(actual)], message)


func assert_almost_eq(actual: float, expected: float, tolerance := 0.001, message := "") -> void:
	if absf(actual - expected) > tolerance:
		_fail("esperado %f (±%f), obtido %f" % [expected, tolerance, actual], message)


func assert_vec_almost_eq(actual: Vector2, expected: Vector2, tolerance := 0.01, message := "") -> void:
	if not (absf(actual.x - expected.x) <= tolerance and absf(actual.y - expected.y) <= tolerance):
		_fail("esperado %s (±%f), obtido %s" % [expected, tolerance, actual], message)


## Objetos viram só nome e id: serializar um objeto com referências cruzadas estoura a recursão.
func _describe(value: Variant) -> String:
	if value is Object:
		return str(value)
	return var_to_str(value)


func _fail(reason: String, message: String) -> void:
	failures.append(reason if message.is_empty() else "%s: %s" % [message, reason])
