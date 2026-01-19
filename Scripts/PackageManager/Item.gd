# 物品计算类，这个类用于对物品进行实时计算
extends RefCounted

class_name Item

# 物品信息配置的引用（只读，不修改配置）
var data: ItemData:
	set(value):
		if _data == null:
			_data = value
	get:
		return _data
var _data: ItemData = null

# 物品行为配置引用（只读，不修改配置）
var behaviour: ItemBehaviourData:
	set(value):
		if _behaviour == null:
			_behaviour = value
	get:
		return _behaviour
var _behaviour: ItemBehaviourData = null

# 运行时动态数据（只有运行时才会变化的属性）
var stack_count: int = 1  # 当前堆叠数量

# 构造函数：通过【配置类】快速创建【运行类】实例
func _init(_data_: ItemData, _stack_count: int = 1):
	self.data = _data_
	self.behaviour = _data_.behaviour
	# self._stack_count = clamp(_stack_count, 1, _data_.max_stack)
	
# 触发behaviour内的函数
func triger_behaviour(func_name : String, character_from : Node, character_to : Node) -> Variant :
	if behaviour != null:
		print_debug("触发物品行为：", func_name, "，物品：", self)
		return behaviour.call(func_name, self, character_from, character_to)
	return null

# 快捷获取静态数据的封装（语法糖，调用更简洁）
func get_id() -> int: return data.id
func get_name() -> String: return data.name
func get_icon() -> Texture2D: return data.icon
func get_max_stack() -> int: return data.max_stack
