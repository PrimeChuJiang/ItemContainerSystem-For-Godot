# 物品详情悬浮提示UI
extends PanelContainer

class_name ItemTooltip

# 物品数据引用
var item_data: Item = null

# UI节点引用
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel
@onready var stack_label: Label = $MarginContainer/VBoxContainer/StackLabel
@onready var use_button: Button = $MarginContainer/VBoxContainer/UseButton

# 信号
signal use_item_requested(item: Item)

func _ready() -> void:
	# 确保鼠标事件不穿透
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 连接按钮信号
	if use_button:
		use_button.pressed.connect(_on_use_button_pressed)

# 设置物品数据并更新显示
func set_item_data(_item_data: Item) -> void:
	item_data = _item_data
	_update_display()

# 更新显示内容
func _update_display() -> void:
	if item_data == null:
		return
	
	if name_label:
		name_label.text = item_data.get_name()
	
	if desc_label:
		desc_label.text = item_data.data.description if item_data.data.description else "无描述"
	
	if stack_label:
		var max_stack = item_data.get_max_stack()
		var max_stack_text = "无限" if max_stack == -1 else str(max_stack)
		stack_label.text = "数量: %d / %s" % [item_data.stack_count, max_stack_text]
	
	if use_button:
		# 如果物品有行为则显示使用按钮
		use_button.visible = item_data.behaviours.size() > 0

# 使用按钮点击事件
func _on_use_button_pressed() -> void:
	if item_data != null:
		use_item_requested.emit(item_data)

# 更新位置（跟随鼠标但不超出屏幕）
func update_position(global_mouse_pos: Vector2) -> void:
	var viewport_size = get_viewport_rect().size
	var tooltip_size = size
	
	# 默认显示在鼠标右下方
	var new_pos = global_mouse_pos + Vector2(15, 15)
	
	# 检查是否超出右边界
	if new_pos.x + tooltip_size.x > viewport_size.x:
		new_pos.x = global_mouse_pos.x - tooltip_size.x - 15
	
	# 检查是否超出下边界
	if new_pos.y + tooltip_size.y > viewport_size.y:
		new_pos.y = global_mouse_pos.y - tooltip_size.y - 15
	
	# 确保不超出左上边界
	new_pos.x = max(0, new_pos.x)
	new_pos.y = max(0, new_pos.y)
	
	global_position = new_pos

