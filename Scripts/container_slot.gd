# 容器插槽UI组件 - 负责处理物品放置和交换逻辑
extends PanelContainer

class_name SampleContainerSlotUI

# 预加载物品UI场景
var item_ui_scene = preload("res://Scenes/Components/ItemUI.tscn")

# 子物品UI节点
var child_item_ui: SampleItemUI = null
# 插槽索引
var slot_index: int = -1
# 所属容器引用
var container: ItemContainer = null
# 是否需要检查Tag（背包需要，仓库不需要）
var check_tag: bool = false

# 信号：请求更新源插槽
# signal request_source_update(_source_slot: SampleContainerSlotUI)

func _ready() -> void:
	# 确保可以接收拖放
	mouse_filter = Control.MOUSE_FILTER_STOP

# 初始化插槽
func initialize(_container: ItemContainer, _slot_index: int, _check_tag: bool = false) -> void:
	container = _container
	slot_index = _slot_index
	check_tag = _check_tag
	
	# 连接容器的物品变更信号
	if not container.item_changed.is_connected(_on_item_changed):
		container.item_changed.connect(_on_item_changed)

# 响应容器物品变更信号
func _on_item_changed(is_add: bool, index: int, item: Item) -> void:
	if index != slot_index:
		return
	
	if is_add and item != null:
		# 添加或更新物品
		_update_or_create_item_ui(item)
	elif not is_add and item == null:
		# 移除物品
		_remove_item_ui()
	elif not is_add and item != null:
		# 物品数量减少但未完全移除
		_update_or_create_item_ui(item)

# 更新或创建物品UI
func _update_or_create_item_ui(item: Item) -> void:
	if child_item_ui == null:
		child_item_ui = item_ui_scene.instantiate() as SampleItemUI
		add_child(child_item_ui)
		child_item_ui.parent_slot = self
	child_item_ui.set_item_data(item)

# 移除物品UI
func _remove_item_ui() -> void:
	if child_item_ui != null:
		child_item_ui.queue_free()
		child_item_ui = null

# 检查是否可以放置数据
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data == null or not data is Dictionary:
		return false
	
	if not data.has("item") or data["item"] == null:
		return false
	
	var dragged_item: Item = data["item"]
	var source_slot: SampleContainerSlotUI = data.get("source_slot", null)
	
	# 如果是同一个插槽，不允许放置
	if source_slot == self:
		return false
	
	# 如果需要检查Tag，进行Tag验证
	if check_tag and container.addable_tags.size() > 0:
		var has_valid_tag = false
		for tag in dragged_item.data.tags:
			if tag in container.addable_tags:
				has_valid_tag = true
				break
		if not has_valid_tag:
			return false
	
	return true

# 处理放置数据
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data == null or not data is Dictionary:
		return
	
	var dragged_item: Item = data["item"]
	var source_slot: SampleContainerSlotUI = data.get("source_slot", null)
	
	if dragged_item == null or source_slot == null:
		return
	
	var source_container: ItemContainer = source_slot.container
	var source_index: int = source_slot.slot_index
	var dst_item: Item = container.get_item_in_position(slot_index)
	
	# 判断操作类型并执行
	_execute_drop_operation(source_container, source_index, dragged_item, dst_item, source_slot)

# 执行放置操作
func _execute_drop_operation(source_container: ItemContainer, source_index: int, 
		dragged_item: Item, dst_item: Item, source_slot: SampleContainerSlotUI) -> void:
	
	# 情况1：目标位置为空 - 直接移动
	if dst_item == null:
		_handle_move_to_empty(source_container, source_index, dragged_item)
		return
	
	# 情况2：目标位置有相同ID的物品 - 进行堆叠（不交换）
	if dst_item.get_id() == dragged_item.get_id():
		_handle_stack_merge(source_container, source_index, dragged_item, dst_item)
		return
	
	# 情况3：目标位置有不同ID的物品 - 交换
	_handle_swap(source_container, source_index, source_slot)

# 处理移动到空位
func _handle_move_to_empty(_source_container: ItemContainer, _source_index: int, _dragged_item: Item) -> void:
	# 使用 Swapper.move_item 进行移动
	var result = Swapper.move_item(_source_container, container, _dragged_item, -1, slot_index)
	if result != Swapper.SUCCESS:
		push_warning("ContainerSlot: 移动物品失败，错误码: ", result)

# 处理堆叠合并（同ID物品始终尝试堆叠，不交换）
func _handle_stack_merge(source_container: ItemContainer, source_index: int, 
		dragged_item: Item, dst_item: Item) -> void:
	
	var max_stack = dragged_item.get_max_stack()
	
	# 检查是否可以堆叠
	if max_stack == -1 or dst_item.stack_count < max_stack:
		# 有空间可以堆叠
		if source_container == container:
			# 同容器内合并堆叠
			var result = Swapper.merge_stack(container, source_index, slot_index)
			if result != Swapper.SUCCESS:
				push_warning("ContainerSlot: 合并堆叠失败，错误码: ", result)
		else:
			# 跨容器移动并堆叠
			var available_space = max_stack - dst_item.stack_count if max_stack != -1 else dragged_item.stack_count
			var move_count = min(dragged_item.stack_count, available_space)
			var result = Swapper.move_item(source_container, container, dragged_item, move_count, slot_index)
			if result != Swapper.SUCCESS:
				push_warning("ContainerSlot: 跨容器堆叠失败，错误码: ", result)
	else:
		# 堆叠已满，不执行任何操作（同ID物品不交换）
		push_warning("ContainerSlot: 目标位置堆叠已满，无法继续堆叠")

# 处理交换
func _handle_swap(source_container: ItemContainer, source_index: int, 
		source_slot: SampleContainerSlotUI) -> void:
	
	# 跨容器交换时需要检查Tag
	if source_container != container:
		var dst_item = container.get_item_in_position(slot_index)
		var source_check_tag = source_slot.check_tag if source_slot else false
		
		# 检查源容器是否允许接收目标物品
		if source_check_tag and source_container.addable_tags.size() > 0 and dst_item != null:
			var has_valid_tag = false
			for tag in dst_item.data.tags:
				if tag in source_container.addable_tags:
					has_valid_tag = true
					break
			if not has_valid_tag:
				push_warning("ContainerSlot: 源容器不接受该物品的Tag")
				return
	
	# 执行交换
	var result = Swapper.swap_positions(source_container, source_index, container, slot_index)
	if result != Swapper.SUCCESS:
		push_warning("ContainerSlot: 交换物品失败，错误码: ", result)

# 手动刷新UI（用于初始化时同步已有数据）
func refresh_ui() -> void:
	var item = container.get_item_in_position(slot_index)
	if item != null:
		_update_or_create_item_ui(item)
	else:
		_remove_item_ui()
