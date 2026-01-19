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
