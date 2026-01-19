extends ItemBehaviourData

class_name AppleBehaviour

# 使用函数，返回使用了多少个
func on_use(item : Item, character_from : Node, character_to : Node) -> int:
    print("AppleBehaviour: on_use", item.get_name(), character_from, character_to)
    return 1

# 获取函数，返回获取了多少个
func on_get() -> int:
    print("AppleBehaviour: on_get")
    return 1