extends ItemContainer

class_name ItemContainerTest

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize(size, "", "", addable_tags)
	illegal_items_changed.connect(_on_illegal_items_changed)

func _input(_event):
	# if _event is InputEventKey:
	# 	if _event.pressed:
	# 		if _event.keycode == KEY_A:
	# 			var item_a = ItemContainerSystem.get_item_data_by_id(0)
	# 			add_item_by_itemdata(item_a)
	# 		if _event.keycode == KEY_B:
	# 			var item_b = ItemContainerSystem.get_item_data_by_id(1)
	# 			add_item_by_itemdata(item_b)
	# 		if _event.keycode == KEY_Q:
	# 			remove_item_in_position(0)
	# 		if _event.keycode == KEY_W:
	# 			get_item_in_position(0).use_item(self, self)
	# 	var item_in_pos_0 = get_item_in_position(0)
	# 	if item_in_pos_0 != null:
	# 		print("Position 0 has item:", item_in_pos_0)
	# 	else:
	# 		print("Position 0 is empty")
	pass

func _on_illegal_items_changed(illegal_items : Array[Item]):
	var msg = "Illegal items tried to be added: \n" 
	for item in illegal_items:
		msg += "  " + str(item) + "\n"
	print(msg)