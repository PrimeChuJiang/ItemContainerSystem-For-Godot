# 物品行为类，这个类用于用户对所有的物品进行一个统一的行为配置
extends Resource

class_name ItemBehaviourData

# -------------------
# 我们规定：
# 1. 物品行为类必须继承自ItemBehaviourData
# 2. ItemBehaviourData类内的所有函数都需要按照如下的方式进行定义：
#    func fuc_name(item : Item, character_from : Node, character_to : Node) -> Variant:
#    	your code here
#    	return 
# -------------------

@export var tag : Tag
