# 物品UI组件 - 负责显示物品和处理拖拽
extends MarginContainer

class_name SampleItemUI

# 预加载详情提示场景
var tooltip_scene = preload("res://Scenes/Components/ItemTooltip.tscn")

# 物品数据引用
var item_data: Item = null
# 所属的插槽
var parent_slot: SampleContainerSlotUI = null

# 悬浮提示相关
var tooltip_instance: ItemTooltip = null
var hover_timer: Timer = null
var is_hovering: bool = false
const HOVER_DELAY: float = 1.0  # 悬浮1秒后显示

@onready var texture_rect: TextureRect = $TextureRect
@onready var count_label: Label = $Label

func _ready() -> void:
	# 确保可以拖拽
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 创建悬浮计时器
	hover_timer = Timer.new()
	hover_timer.one_shot = true
	hover_timer.wait_time = HOVER_DELAY
	hover_timer.timeout.connect(_on_hover_timer_timeout)
	add_child(hover_timer)
	
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _exit_tree() -> void:
	_hide_tooltip()

func set_item_data(_item_data: Item) -> void:
	self.item_data = _item_data
	update_ui()

func update_ui() -> void:
	if item_data != null and item_data is Item:
		if texture_rect:
			texture_rect.texture = item_data.get_icon()
		if count_label:
			count_label.text = "x" + str(item_data.stack_count)
			# 如果数量为1则隐藏数量显示
			count_label.visible = item_data.stack_count > 1
	else:
		if texture_rect:
			texture_rect.texture = null
		if count_label:
			count_label.text = ""
			count_label.visible = false

# 鼠标进入事件
func _on_mouse_entered() -> void:
	is_hovering = true
	if item_data != null:
		hover_timer.start()

# 鼠标离开事件
func _on_mouse_exited() -> void:
	is_hovering = false
	hover_timer.stop()
	_hide_tooltip()

# 悬浮计时器超时 - 显示详情
func _on_hover_timer_timeout() -> void:
	if is_hovering and item_data != null:
		_show_tooltip()

# 显示详情提示
func _show_tooltip() -> void:
	if tooltip_instance != null:
		return
	
	# 创建提示实例
	tooltip_instance = tooltip_scene.instantiate() as ItemTooltip
	
	# 添加到根节点，确保显示在最上层
	var root = get_tree().root
	root.add_child(tooltip_instance)
	
	# 设置数据
	tooltip_instance.set_item_data(item_data)
	
	# 连接使用按钮信号
	tooltip_instance.use_item_requested.connect(_on_tooltip_use_item)
	
	# 设置位置：显示在物品UI右侧
	var item_global_pos = global_position
	var item_size_val = size
	tooltip_instance.update_position(Vector2(item_global_pos.x + item_size_val.x + 5, item_global_pos.y))

# 隐藏详情提示
func _hide_tooltip() -> void:
	if tooltip_instance != null:
		tooltip_instance.queue_free()
		tooltip_instance = null

# 处理提示框的使用物品请求
func _on_tooltip_use_item(_item: Item) -> void:
	if _item != null and parent_slot != null:
		# 使用物品
		_item.use_item(parent_slot, parent_slot)
		
		# 消耗1个物品
		var container = parent_slot.container
		var index = parent_slot.slot_index
		if container != null:
			container.remove_item_in_position(index, 1)
		
		# 隐藏提示
		_hide_tooltip()

# 不再在_process中更新位置，详情框显示后固定不动

# 拖放支持 - 委托给父插槽处理
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# 委托给父插槽判断
	if parent_slot != null:
		return parent_slot._can_drop_data(at_position, data)
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	# 委托给父插槽处理
	if parent_slot != null:
		parent_slot._drop_data(at_position, data)

# 拖拽相关函数
func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_data == null:
		return null
	
	# 开始拖拽时隐藏提示
	_hide_tooltip()
	hover_timer.stop()
	
	# 创建拖拽预览
	var preview = _create_drag_preview()
	set_drag_preview(preview)
	
	# 返回拖拽数据
	var data = {
		"item": item_data,
		"source_slot": parent_slot,
		"source_ui": self
	}
	
	# 拖拽开始时使当前UI半透明
	modulate.a = 0.5
	
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		# 拖拽结束时恢复透明度
		modulate.a = 1.0

# 创建拖拽预览
func _create_drag_preview() -> Control:
	var preview = TextureRect.new()
	preview.texture = item_data.get_icon()
	preview.custom_minimum_size = Vector2(64, 64)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate.a = 0.8
	return preview
