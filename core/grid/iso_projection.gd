class_name IsoProjection
extends RefCounted
## Conversão entre coordenadas do grid lógico e coordenadas de mundo
## na projeção isométrica 2:1 (losangos com largura = 2 x altura).
##
## Convenção: o vértice superior da célula (0, 0) fica na origem do mundo.
## O eixo x do grid desce para a direita e o eixo y desce para a esquerda.

## Tamanho de um piso na tela, em pixels de mundo. Mudar aqui muda a escala de tudo.
const TILE_SIZE := Vector2(128.0, 64.0)
const HALF_TILE := TILE_SIZE / 2.0


## Vértice superior do losango da célula.
static func cell_top_vertex(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * HALF_TILE.x, (cell.x + cell.y) * HALF_TILE.y)


## Centro do losango da célula (onde objetos e personagens "pisam").
static func cell_center(cell: Vector2i) -> Vector2:
	return cell_top_vertex(cell) + Vector2(0.0, HALF_TILE.y)


## Ponto do mundo para uma posição fracionária no grid, em que o centro da
## célula (x, y) é Vector2(x, y). Usado para personagens andando entre pisos.
static func grid_point_to_world(point: Vector2) -> Vector2:
	return Vector2((point.x - point.y) * HALF_TILE.x, (point.x + point.y + 1.0) * HALF_TILE.y)


## Célula que contém o ponto do mundo. Pode retornar células fora do grid;
## quem chama decide se ela é válida.
static func world_to_cell(world: Vector2) -> Vector2i:
	var u := world.x / HALF_TILE.x
	var v := world.y / HALF_TILE.y
	return Vector2i(floori((u + v) / 2.0), floori((v - u) / 2.0))


## Os 4 vértices do losango (topo, direita, base, esquerda).
static func cell_polygon(cell: Vector2i) -> PackedVector2Array:
	var top := cell_top_vertex(cell)
	return PackedVector2Array([
		top,
		top + Vector2(HALF_TILE.x, HALF_TILE.y),
		top + Vector2(0.0, TILE_SIZE.y),
		top + Vector2(-HALF_TILE.x, HALF_TILE.y),
	])


## Retângulo do mundo que envolve um grid inteiro desse tamanho.
static func grid_bounds(grid_size: Vector2i) -> Rect2:
	var width := (grid_size.x + grid_size.y) * HALF_TILE.x
	var height := (grid_size.x + grid_size.y) * HALF_TILE.y
	return Rect2(Vector2(-grid_size.y * HALF_TILE.x, 0.0), Vector2(width, height))
