# 物品最简单的数据结构，只有id和数量
@tool

extends Resource
class_name SimpleItemData

class SingleSimpleItemData:
    var id : int = 0
    var count : int = 1

    func _to_string() -> String:
        var name : String = ItemContainerSystem.get_item_data_by_id(id).name
        return "SingleSimpleItemData(id: %d, name: %s, count: %d)" % [id, name, count]

var item_save_datas : Array[SingleSimpleItemData] = []

func load_from_save_data() -> Array[Item] :
    var items : Array[Item] = []
    for i in range(item_save_datas.size()):
        var save_data : SingleSimpleItemData = item_save_datas[i]
        if save_data != null:
            var item_data := ItemContainerSystem.get_item_data_by_id(save_data.id)
            if item_data != null:
                var item := Item.new(item_data, save_data.count)
                items.append(item)
            else: 
                push_error("ItemSaveData: create: 无法通过ID %d 获取物品模板数据" % save_data.id)
                items.append(null)
        else:
            print("ItemSaveData: create: 第 %d 个保存数据为空" % i)
            items.append(null)
    return items

func save_to_save_data(items : Array[Item]) -> void:
    item_save_datas.clear()
    for i in range(items.size()):
        var item : Item = items[i]
        if item != null:
            var save_data := SingleSimpleItemData.new()
            save_data.id = item.data.id
            save_data.count = item.stack_count
            item_save_datas.append(save_data)
        else:
            item_save_datas.append(null)