extends ItemBehaviourData

class_name TestBehaviourA

@export var behaviour_cost : int = -1

func use_item(item : Item, character_from : Node, character_to : Node, _num : int = -1) -> Variant:
	_do_use_item(item, character_from, character_to, behaviour_cost)
	return

func _do_use_item(item : Item, character_from : Node, character_to : Node, cost : int) -> void:
	print("TestBehaviourA: _do_use_item: 使用了物品:", item, "从角色:", character_from, "到角色:", character_to)
	if cost != -1:
		item.container.remove_item_in_position(item.position_in_container, cost)
	return 