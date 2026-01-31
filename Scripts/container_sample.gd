# 容器示例场景脚本 - 演示背包和仓库的交互
extends Control

class_name ContainerSample

# 预加载插槽场景
var slot_scene = preload("res://Scenes/Components/ContainerSlot.tscn")

# 背包容器（有Tag控制）
var backpack_container: ItemContainer = null
# 仓库容器（无Tag控制）
var storehouse_container: ItemContainer = null

# 背包可添加的Tag（用于测试）
@export var backpack_tags: Array[Tag] = []

# 配置
@export var backpack_size: int = 8
@export var storehouse_size: int = 16
@export var backpack_columns: int = 4
@export var storehouse_columns: int = 4

# UI节点引用
@onready var backpack_grid: GridContainer = $Bagpack/VBoxContainer/Bagpack
@onready var storehouse_grid: GridContainer = $Storehouse2/VBoxContainer/Storehouse
@onready var btn_add_item_a: Button = $HBoxContainer/ButtonAddItemA
@onready var btn_add_item_b: Button = $HBoxContainer/ButtonAddItemB
@onready var info_label: RichTextLabel = $RichTextLabel
@onready var hp_label: Label = $PanelContainer/VBoxContainer/Label_HP
@onready var mana_label: Label = $PanelContainer/VBoxContainer/Label_Mana

# 玩家状态（用于演示物品使用效果）
var player_hp: int = 100
var player_mana: int = 50

func _ready() -> void:
	# 初始化容器
	_init_containers()
	# 创建UI插槽
	_create_slot_uis()
	# 连接按钮信号
	_connect_signals()
	# 更新状态显示
	_update_player_stats()
	# 更新信息文本
	_update_info_text()

# 初始化容器
func _init_containers() -> void:
	# 创建背包容器（有Tag控制）
	backpack_container = ItemContainer.new()
	backpack_container.initialize(backpack_size, "背包", "玩家的背包", backpack_tags)
	add_child(backpack_container)
	
	# 创建仓库容器（无Tag控制）
	storehouse_container = ItemContainer.new()
	storehouse_container.initialize(storehouse_size, "仓库", "玩家的仓库", [])
	add_child(storehouse_container)
	
	# 连接非法物品信号
	backpack_container.illegal_items_changed.connect(_on_backpack_illegal_items)
	storehouse_container.illegal_items_changed.connect(_on_storehouse_illegal_items)

# 创建UI插槽
func _create_slot_uis() -> void:
	# 设置Grid列数
	backpack_grid.columns = backpack_columns
	storehouse_grid.columns = storehouse_columns
	
	# 创建背包插槽（check_tag = true）
	for i in range(backpack_size):
		var slot = slot_scene.instantiate() as SampleContainerSlotUI
		slot.custom_minimum_size = Vector2(64, 64)
		backpack_grid.add_child(slot)
		slot.initialize(backpack_container, i, true)  # 背包需要检查Tag
	
	# 创建仓库插槽（check_tag = false）
	for i in range(storehouse_size):
		var slot = slot_scene.instantiate() as SampleContainerSlotUI
		slot.custom_minimum_size = Vector2(64, 64)
		storehouse_grid.add_child(slot)
		slot.initialize(storehouse_container, i, false)  # 仓库不检查Tag

# 连接信号
func _connect_signals() -> void:
	btn_add_item_a.pressed.connect(_on_add_item_a_pressed)
	btn_add_item_b.pressed.connect(_on_add_item_b_pressed)

# 添加物品A到背包
func _on_add_item_a_pressed() -> void:
	var item_data = ItemContainerSystem.get_item_data_by_id(0)
	if item_data != null:
		# 背包添加物品需要检查Tag
		var result = backpack_container.add_item_by_itemdata(item_data, -1, true, 1)
		if result == ItemContainer.CAN_ADD_ITEM_SUCCESS:
			print("成功添加物品A到背包")
		else:
			print("添加物品A失败，错误码: ", result)
			# 如果背包不能添加，尝试添加到仓库
			var result2 = storehouse_container.add_item_by_itemdata(item_data, -1, false, 1)
			if result2 == ItemContainer.CAN_ADD_ITEM_SUCCESS:
				print("已将物品A添加到仓库")

# 添加物品B到背包
func _on_add_item_b_pressed() -> void:
	var item_data = ItemContainerSystem.get_item_data_by_id(1)
	if item_data != null:
		# 背包添加物品需要检查Tag
		var result = backpack_container.add_item_by_itemdata(item_data, -1, true, 1)
		if result == ItemContainer.CAN_ADD_ITEM_SUCCESS:
			print("成功添加物品B到背包")
		else:
			print("添加物品B失败，错误码: ", result)
			# 如果背包不能添加，尝试添加到仓库
			var result2 = storehouse_container.add_item_by_itemdata(item_data, -1, false, 1)
			if result2 == ItemContainer.CAN_ADD_ITEM_SUCCESS:
				print("已将物品B添加到仓库")

# 背包非法物品回调
func _on_backpack_illegal_items(_illegal_items: Array[Item]) -> void:
	for item in _illegal_items:
		print("背包拒绝物品: ", item.get_name(), " (Tag不匹配)")

# 仓库非法物品回调
func _on_storehouse_illegal_items(_illegal_items: Array[Item]) -> void:
	for item in _illegal_items:
		print("仓库空间不足: ", item.get_name())

# 更新玩家状态显示
func _update_player_stats() -> void:
	if hp_label:
		hp_label.text = "生命：%d" % player_hp
	if mana_label:
		mana_label.text = "魔法值：%d" % player_mana

# 更新信息文本
func _update_info_text() -> void:
	if info_label:
		var info_text = """[b]背包仓库交互示例[/b]

[color=yellow]功能说明：[/color]
1. 点击按钮添加物品到背包
2. 拖拽物品可以移动位置
3. 拖拽到有物品的位置会交换
4. 同类物品拖拽会尝试堆叠

[color=cyan]容器规则：[/color]
• [b]背包[/b]：有Tag控制
  只能存放带有匹配Tag的物品
• [b]仓库[/b]：无Tag控制
  可以存放任何物品

[color=green]操作提示：[/color]
• 直接拖拽物品到目标位置
• 相同物品会自动堆叠
• 不同物品会交换位置
• 空位置直接放置"""
		info_label.text = info_text

# 处理输入（可选：使用物品）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# 按空格使用背包第一个物品
		if event.keycode == KEY_SPACE:
			var item = backpack_container.get_item_in_position(0)
			if item != null:
				item.use_item(self, self)
				print("使用物品: ", item.get_name())

