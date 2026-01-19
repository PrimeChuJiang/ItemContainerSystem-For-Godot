extends ItemContainer

class_name ItemContainerTest

var apple = preload("res://Test/Items/apple.tres")

# Called when the node enters the scene tree for the first time.
func _ready():
	var _apple = Item.new(apple)
	item_list.append(_apple)

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				var num = item_list[0].triger_behaviour("on_use", self, self);
				print("use num: ", num)
