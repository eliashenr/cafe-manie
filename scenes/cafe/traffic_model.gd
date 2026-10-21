class_name TrafficModel
extends RefCounted
## Trânsito de enfeite em volta do café (só tela; as regras do jogo não sabem dele): carros andando nas
## faixas das duas ruas e o semáforo do cruzamento, que alterna qual rua passa. O carro para na faixa de
## parada quando o sinal da rua dele não está verde e ele ainda não entrou no cruzamento, e nunca encosta
## no carro da frente. Quem chega no fim da rua volta pelo começo.
##
## Posições em vértices do grid (como o ExteriorView): a rua A corre ao longo de y, na frente da entrada;
## a B ao longo de x, do outro lado da frente.

enum Light { GREEN, YELLOW, RED }
enum Phase { A_GREEN, A_YELLOW, A_CLEAR, B_GREEN, B_YELLOW, B_CLEAR }

## Duração de cada fase do semáforo (segundos), na ordem de Phase.
const PHASE_TIME: Array[float] = [9.0, 2.0, 1.2, 9.0, 2.0, 1.2]
## Velocidade dos carros (pisos/s) e a distância mínima até o carro da frente.
const SPEED := 1.7
const GAP := 1.6
## O meio do carro para a esta distância do cruzamento: a frente fica antes da faixa de parada pintada.
const STOP_MARGIN := 1.7


## Uma faixa: ao longo de qual eixo, para que lado, a coordenada fixa e o trecho da rua.
class Lane:
	extends RefCounted

	var street := 0  ## 0 = rua A (ao longo de y), 1 = rua B (ao longo de x)
	var direction := 1  ## +1 ou -1 ao longo do eixo da rua
	var fixed := 0.0  ## x da faixa (rua A) ou y (rua B)
	var start := 0.0
	var end := 0.0
	## Onde o cruzamento começa e termina ao longo da rua (no sentido de quem anda).
	var cross_from := 0.0
	var cross_to := 0.0

	## Faixa de parada: um pouco antes do cruzamento, no sentido da faixa.
	func stop_at() -> float:
		return cross_from - direction * STOP_MARGIN

	## Ponto no grid (vértices) da posição [param along] nesta faixa.
	func point(along: float) -> Vector2:
		return Vector2(fixed, along) if street == 0 else Vector2(along, fixed)

	## Já passou de [param a] no sentido da faixa?
	func past(along: float, a: float) -> bool:
		return (along - a) * direction > 0.0

	## Direção de andar, para escolher o desenho do carro ("+x", "-x", "+y" ou "-y").
	func heading() -> String:
		return ("+" if direction > 0 else "-") + ("y" if street == 0 else "x")


class Car:
	extends RefCounted

	var lane: Lane
	var along := 0.0
	var kind := 0  ## qual desenho (índice na lista de carros)
	var stopped := false

	func point() -> Vector2:
		return lane.point(along)


var lanes: Array[Lane] = []
var cars: Array[Car] = []
var phase := Phase.A_GREEN
var _phase_left: float = PHASE_TIME[0]


## Sinal da rua [param street] (0 = A, 1 = B) agora.
func light(street: int) -> Light:
	var green := Phase.A_GREEN if street == 0 else Phase.B_GREEN
	var yellow := Phase.A_YELLOW if street == 0 else Phase.B_YELLOW
	if phase == green:
		return Light.GREEN
	return Light.YELLOW if phase == yellow else Light.RED


func add_lane(street: int, direction: int, fixed: float, start: float, end: float, cross_from: float,
		cross_to: float) -> Lane:
	var lane := Lane.new()
	lane.street = street
	lane.direction = direction
	lane.fixed = fixed
	lane.start = start
	lane.end = end
	lane.cross_from = cross_from
	lane.cross_to = cross_to
	lanes.append(lane)
	return lane


func add_car(lane: Lane, along: float, kind := 0) -> Car:
	var car := Car.new()
	car.lane = lane
	car.along = along
	car.kind = kind
	cars.append(car)
	return car


## Anda [param delta] segundos: o semáforo e cada carro.
func step(delta: float) -> void:
	if delta <= 0.0:
		return
	_phase_left -= delta
	while _phase_left <= 0.0:
		phase = (phase + 1) % Phase.size() as Phase
		_phase_left += PHASE_TIME[phase]
	for car in cars:
		_move(car, delta)


func _move(car: Car, delta: float) -> void:
	var lane := car.lane
	var target := car.along + lane.direction * SPEED * delta
	# não encosta no carro da frente na mesma faixa
	var ahead := _car_ahead(car)
	if ahead != null:
		var limit := ahead.along - lane.direction * GAP
		if lane.past(target, limit):
			target = limit if lane.past(limit, car.along) else car.along
	# para na faixa quando o sinal não deixa e ainda não entrou no cruzamento
	var stop := lane.stop_at()
	if light(lane.street) != Light.GREEN and not lane.past(car.along, stop) and lane.past(target, stop):
		target = stop
	car.stopped = is_equal_approx(target, car.along)
	car.along = target
	if lane.past(car.along, lane.end):
		car.along = lane.start
		car.stopped = false


## O carro mais próximo à frente, na mesma faixa (null se não há).
func _car_ahead(car: Car) -> Car:
	var best: Car = null
	for other in cars:
		if other == car or other.lane != car.lane or not car.lane.past(other.along, car.along):
			continue
		if best == null or car.lane.past(best.along, other.along):
			best = other
	return best
