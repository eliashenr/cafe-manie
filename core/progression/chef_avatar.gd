class_name ChefAvatar
extends RefCounted
## Avatar do chef (DT-070): as peças que o jogador já tem e a que está usando em cada parte do corpo.
## Só veste peça que já é dele; comprar é da simulação.

signal changed

## Parte do corpo (AvatarPartDefinition.Slot) -> id da peça vestida.
var _equipped := {}
## id -> true.
var _owned := {}


func owns(id: StringName) -> bool:
	return _owned.has(id)


func own(id: StringName) -> void:
	if not owns(id):
		_owned[id] = true
		changed.emit()


func owned() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_owned.keys())
	return result


## A peça vestida na parte do corpo (&"" se nenhuma).
func equipped(slot: AvatarPartDefinition.Slot) -> StringName:
	return _equipped.get(slot, &"")


## Veste a peça (só se já for do jogador). Retorna se vestiu.
func equip(part: AvatarPartDefinition) -> bool:
	if part == null or not owns(part.id):
		return false
	_equipped[part.slot] = part.id
	changed.emit()
	return true


func to_data() -> Dictionary:
	var equipped_data := {}
	for slot: int in _equipped:
		equipped_data[str(slot)] = String(_equipped[slot])
	return {"equipped": equipped_data, "owned": owned().map(func(id: StringName) -> String: return String(id))}


func restore(data: Dictionary) -> void:
	_owned.clear()
	for id in SafeValue.to_array(data.get("owned", [])):
		_owned[StringName(str(id))] = true
	_equipped.clear()
	var equipped_data: Variant = data.get("equipped", {})
	if equipped_data is Dictionary:
		for key in equipped_data:
			_equipped[int(str(key))] = StringName(str(equipped_data[key]))
	changed.emit()
