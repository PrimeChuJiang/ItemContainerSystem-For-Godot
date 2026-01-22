# Container System单例，会放到audoLoad内，该单例负责维护ItemDataMap，方便用户随时通过ID获取物品的模板数据
extends Node

class_name ContainerSystem

var _item_map : Dictionary = {}

func _ready():
	var raw_resource_path = ProjectSettings.get_setting("container_system/item_data_map")

	var item_map_data = load(raw_resource_path) as ItemDataMap
	if item_map_data == null:
		push_error("ContainerSystem: _ready: 物品数据地图设置错误")
		return
	else :
		for item_data in item_map_data.item_data_map :
			_item_map[item_data.id] = item_data
		print("ContainerSystem: _ready: 物品数据地图加载成功")

# 通过ID获取物品模板数据
func get_item_data_by_id(id : int) -> ItemData:
	if _item_map.has(id):
		return _item_map[id]
	else :
		return null
