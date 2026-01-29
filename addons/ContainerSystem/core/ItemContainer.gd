# 容器类
extends Node

class_name ItemContainer

# 物品列表
var item_list : Array[Item] = []

# 容器可添加的物品标签
@export var addable_tags : Array[Tag] = []

# 容器大小
@export var size : int = 0		

# 容器描述
@export var description : String = ""

# 容器名称
@export var container_name : String = ""

# 容器内非法物品变更信号，illegal_items表示不能添加的物品列表
signal illegal_items_changed(illegal_items : Array[Item])
# 容器内物品变更信号，is_add表示是添加还是移除物品，index表示物品所在位置，item表示变更后的物品信息
signal item_changed(is_add : bool, index: int, item: Item)
# 容器大小变更信号，new_size表示新的容器大小
signal size_changed(new_size : int)

# 容器初始化函数
func initialize(_size : int = 0, _container_name : String = "", _description : String = "", _addable_tags : Array[Tag] = [], _item_list : Array[Item] = []):
	self.container_name = _container_name
	self.description = _description
	self.addable_tags = _addable_tags
	self.item_list = _item_list
	_set_item_list_size(_size)

# 设置容器大小
func _set_item_list_size(new_size : int) -> bool:
	if new_size < 0:
		push_error("ItemContainer: set_item_list_size: 容器大小不能为负数")
		return false
	if item_list.resize(new_size) != OK:
		push_error("ItemContainer: set_item_list_size: 容器大小设置失败")
		return false
	size = new_size
	return true

# ---------------
# 物品能否加入和移除容器相关code注释
# 200 - 成功添加/移除物品
# 400 - 物品标签不在容器可添加的标签列表中
# 401 - 物品添加的位置处已存在物品
# 402 - 物品堆叠数量超过最大堆叠数量
# 403 - 容器设置为check_tag为true，但是容器没有设置可添加的标签列表
# 404 - 物品内没有设置标签
# 405 - 物品所在位置已存在物品，但是物品id不同
# 406 - 指定的位置索引超出容器大小
# 407 - 物品的删除数量大于当前背包内的物品堆叠数量
# 408 - 指定的删除的index处的物品不存在

const CAN_ADD_ITEM_SUCCESS = 200
const CAN_ADD_ITEM_TAG_CONTAIN_ERROR = 400
const CAN_ADD_ITEM_INDEX_ERROR = 401
const CAN_ADD_ITEM_STACK_ERROR = 402
const CAN_ADD_ITEM_TAG_LIST_ERROR = 403
const CAN_ADD_ITEM_TAG_NULL_ERROR = 404
const CAN_ADD_ITEM_ID_CONFLICT_ERROR = 405
const CAN_ADD_ITEM_INDEX_OUT_OF_RANGE_ERROR = 406
const CAN_REMOVE_ITEM_SUCCESS = 200
const CAN_REMOVE_ITEM_NUM_ERROR = 407
const CAN_REMOVE_ITEM_INDEX_NULL_ERROR = 408

# ---------------

# 查看是否能够添加指定物品
func can_add_item(item : Item , index : int = -1, check_tag : bool = false) -> int:
	# 首先检查物品的标签，是否在容器可添加的标签列表中
	if check_tag:
		if item.data.tags.size() > 0:
			var has_valid_tag = false
			if addable_tags.size() > 0:
				for tag in item.data.tags:
					if tag in addable_tags:
						has_valid_tag = true
						break
			if not has_valid_tag:
				push_error("ItemContainer: can_add_item: 物品", item, "标签不在容器可添加的标签列表中")
				return CAN_ADD_ITEM_TAG_CONTAIN_ERROR
		else:
			push_error("ItemContainer: can_add_item: 物品", item, "没有标签")
			return CAN_ADD_ITEM_TAG_LIST_ERROR
	# 先查是否有指定物品的摆放位置
	if index == -1 :
		index = item_list.find(null)
		if index == -1:
			index = find_position_by_id(item.data.id)
			if index == -1:
				push_error("ItemContainer: can_add_item: 容器", self, "没有空位置可以添加物品")
				return CAN_ADD_ITEM_INDEX_ERROR
	if index >= size:
		push_error("ItemContainer: can_add_item: 索引", index, "超出容器大小")
		return CAN_ADD_ITEM_INDEX_OUT_OF_RANGE_ERROR
	# 然后检查物品所在位置是否已经存在了别的物品
	if item_list[index] != null:
		var existing_item = item_list[index]
		if existing_item.data.id == item.data.id:
			# 如果是相同的id，那么我们查看是否有超出堆叠要求
			if item.get_max_stack() != -1 and item.get_max_stack() < existing_item.stack_count + item.stack_count:
				push_error("ItemContainer: can_add_item: 物品", item, "堆叠数量超过最大堆叠数量")
				return CAN_ADD_ITEM_STACK_ERROR
			else: 
				return CAN_ADD_ITEM_SUCCESS
		else:
			push_error("ItemContainer: can_add_item: 物品", item, "所在位置已存在物品，但是物品id不同")
			return CAN_ADD_ITEM_ID_CONFLICT_ERROR
	# 如果物品所在位置为空，那么我们可以直接添加
	else:
		return CAN_ADD_ITEM_SUCCESS

# 查找指定物品id的可用位置，返回第一个空位置或者是相同id的位置
func find_position_by_id(item_id : int) -> int:
	var index = -1
	for i in range(size):
		if item_list[i] == null and index == -1:
			index = i
		elif item_list[i] != null and item_list[i].data.id == item_id:
			index = i
	return index

# 查看是否能够移除指定位置上的指定格数的物品
func can_remove_item(index : int = -1, num : int = 1) -> int :
	# 先检查index是否合法
	if index >= size or index == -1 :
		push_error("ItemContainer: can_remove_item: 索引", index, "超出容器大小")
		return CAN_ADD_ITEM_INDEX_OUT_OF_RANGE_ERROR
	# 检查指定的位置上是否有物品
	if item_list[index] == null :
		push_error("ItemContainer: can_remove_item: 索引", index, "处的物品不存在")
		return CAN_REMOVE_ITEM_INDEX_NULL_ERROR
	else :
		# 检查是否有足够的物品可以移除
		if item_list[index].stack_count < num:
			push_error("ItemContainer: can_remove_item: 索引", index, "处的物品堆叠数量不足，当前只有", item_list[index].stack_count, "个，需要移除", num, "个")
			return CAN_REMOVE_ITEM_NUM_ERROR
		else:
			return CAN_ADD_ITEM_SUCCESS

# 添加物品到容器
func add_item(item : Item, index : int = -1, check_tag : bool = false) -> int:
	# 先检查是否能够添加物品
	var can_add = can_add_item(item, index, check_tag)
	if can_add != CAN_ADD_ITEM_SUCCESS:
		push_error("ItemContainer: add_item: 物品", item, "不能添加到容器，错误码：", can_add)
		var illegal_items : Array[Item] = []
		illegal_items.append(item)
		illegal_items_changed.emit(illegal_items)
		return can_add
	if index == -1 :
		index = find_position_by_id(item.data.id)
	if item_list[index] == null:
		item_list[index] = item
		item.container = self
		item.position_in_container = index
		# 触发信号
		item_changed.emit(true, index, item_list[index])
	else: 
		item_list[index].stack_count += item.stack_count
		# 触发信号
		item_changed.emit(true, index, item_list[index])
	return can_add

# 一次性添加多个物品到容器内
func add_multi_items(_items : Array[Item]) -> Array[int] :
	var results : Array[int] = []
	var illegal_items : Array[Item] = []
	for _item in _items:
		var code = add_item(_item)
		if code != CAN_ADD_ITEM_SUCCESS:
			push_error("ItemContainer: add_items: 物品", _item, "不能添加到容器，错误码：", code)
			illegal_items.append(_item)
		results.append(code)
	if illegal_items.size() > 0:
		illegal_items_changed.emit(illegal_items)
	return results

# 通过物品模板添加物品实例到容器内
func add_item_by_itemdata(item_data: ItemData, index : int = -1, check_tag : bool = false, stack_count : int = 1) -> int :
	return add_item(Item.new(item_data, self, index, stack_count), index, check_tag)

# 删除指定位置的物品
func remove_item_in_position(index : int = -1, num : int = 1) -> int:
	# 先检查是否能够移除物品
	var can_remove = can_remove_item(index, num)
	if can_remove != CAN_REMOVE_ITEM_SUCCESS:
		push_error("ItemContainer: remove_item: 索引", index, "处的物品不能移除，错误码：", can_remove)
		return can_remove
	# 如果物品堆叠数量大于移除数量，那么我们只减少堆叠数量
	if item_list[index].stack_count > num:
		item_list[index].stack_count -= num
		# 触发信号
		item_changed.emit(false, index, item_list[index])
	# 如果物品堆叠数量等于移除数量，那么我们直接移除物品
	else:
		item_list[index] = null
		# 触发信号
		item_changed.emit(false, index, item_list[index])
	return CAN_REMOVE_ITEM_SUCCESS
	
# ---------------
# 查看物品是否存在以及数量是否足够相关code注释
# 200 - 物品存在，数量足够
# 301 - 指定位置为空
# 302 - 指定位置物品不同
# 303 - 物品存在但数量不足
# 304 - 指定索引超出容器大小
# 305 - 容器内没有该物品

const HAS_ITEM_SUCCESS = 200
const HAS_ITEM_INDEX_NULL_ERROR = 301
const HAS_ITEM_ID_CONFLICT_ERROR = 302
const HAS_ITEM_NUM_ERROR = 303
const HAS_ITEM_INDEX_OUT_OF_RANGE_ERROR = 304
const HAS_ITEM_NOT_FOUND_ERROR = 305
# ---------------

# 查看容器内是否有指定物品
func has_item(item : Item, index : int = -1, check_num : bool = false) -> int :
	if index != -1:
		# 检查索引是否超出容器大小
		if index <0 or index >= size:
			push_error("ItemContainer: has_item: 索引", index, "超出容器大小")
			return HAS_ITEM_INDEX_OUT_OF_RANGE_ERROR
		# 检查指定位置是否有物品
		var existing_item = item_list[index]
		if existing_item == null:
			push_error("ItemContainer: has_item: 索引", index, "处为空")
			return HAS_ITEM_INDEX_NULL_ERROR
		# 检查物品id是否相同
		if existing_item.data.id != item.data.id:
			push_error("ItemContainer: has_item: 索引", index, "处的物品id为", existing_item.data.id, "，与指定物品id", item.data.id, "不同")
			return HAS_ITEM_ID_CONFLICT_ERROR
		# 如果需要检查数量，那么检查堆叠数量是否足够
		if check_num:
			if existing_item.stack_count < item.stack_count:
				push_error("ItemContainer: has_item: 索引", index, "处的物品堆叠数量为", existing_item.stack_count, "，不足指定数量", item.stack_count)
				return HAS_ITEM_NUM_ERROR
		# 如果以上检查都通过，那么物品存在且数量足够
		return HAS_ITEM_SUCCESS
	else:
		# 检查容器内是否有该物品
		if item_list.find(item) == -1:
			push_error("ItemContainer: has_item: 容器", self, "内没有物品", item)
			return HAS_ITEM_NOT_FOUND_ERROR
		var existing_item = item_list[index]
		# 如果需要检查数量，那么检查堆叠数量是否足够
		if check_num:
			if item.stack_count > existing_item.stack_count:
				push_error("ItemContainer: has_item: 容器", self, "内物品", item, "堆叠数量为", existing_item.stack_count, "，不足指定数量", item.stack_count)
				return HAS_ITEM_NUM_ERROR
		# 如果以上检查都通过，那么物品存在且数量足够
		return HAS_ITEM_SUCCESS

# 变更容器到指定大小
func change_size(new_size : int) -> bool:
	if _set_item_list_size(new_size):
		size_changed.emit(new_size)
		return true
	return false

# 获取容器内指定位置的物品
func get_item_in_position(index : int) -> Item:
	if index >= size or index < 0:
		push_error("ItemContainer: get_item_in_position: 索引", index, "超出容器大小")
		return null
	return item_list[index]
