# ItemContainer 插件

面向 Godot 4 的运行时容器/背包系统插件，提供容器管理、物品堆叠与跨容器操作的基础能力。支持 O(1) 级别的空位与物品位置查询，并提供模拟计算接口用于 UI 预览。

官方文档参考（Godot 4.4）：https://docs.godotengine.org/zh-cn/4.4/index.html

## 功能概览

- 物品与容器分离的数据结构（`ItemData` / `Item` / `ItemContainer`）
- 物品堆叠、可添加标签校验、位置管理
- 容器容量变更与物品重分配
- O(1) 空位与物品位置查询（基于索引映射）
- 跨容器交换、移动、拆分/合并、批量操作（`Swapper`）
- 支持只计算不执行的模拟接口（UI 预览友好）

## 目录结构

- `addons/ContainerSystem/core/ItemContainer.gd`：容器核心逻辑
- `addons/ContainerSystem/core/Item.gd`：运行时物品实例
- `addons/ContainerSystem/core/Swapper.gd`：跨容器静态工具类
- `addons/ContainerSystem/core/ItemData*.gd`：物品静态配置（按项目实际文件为准）

## 核心类分工

- `ItemData`：物品静态配置（名称、图标、最大堆叠、标签、行为等）
- `Item`：运行时物品实例（堆叠数量、所在容器、位置）
- `ItemContainer`：单容器内的存取、校验、堆叠规则、信号广播与索引维护
- `Swapper`：跨容器与批量操作编排，提供 `simulate_*` 只读计算路径

## 快速开始

### 1. 创建容器并初始化

```gdscript
var container := ItemContainer.new()
container.initialize(20, "背包", "玩家背包", [], [])
```

### 2. 添加物品

```gdscript
var item := Item.new(item_data, container, -1, 3)
container.add_item(item) # 自动分配位置并堆叠
```

### 3. 删除物品

```gdscript
container.remove_item_in_position(0, 1)
container.remove_item_by_id(item_data.id, 2)
```

### 4. 跨容器移动

```gdscript
Swapper.move_by_id(bag, warehouse, item_data.id, 5)
```

### 5. 预览移动（不执行）

```gdscript
var preview := Swapper.simulate_move(bag, warehouse, item_data.id, 5)
if preview["code"] == Swapper.SUCCESS:
	print(preview["src_changes"], preview["dst_changes"])
```

## 重要信号

`ItemContainer` 内部维护以下信号用于 UI 或数据同步：

- `item_changed(is_add: bool, index: int, item: Item)`
- `illegal_items_changed(illegal_items: Array[Item])`
- `size_changed(new_size: int)`

## 容器容量变更逻辑

当容器缩小时，系统会尝试将被挤出的物品重新分配到容器内的可用位置或同 ID 堆叠中；无法分配的物品会通过 `illegal_items_changed` 广播。

## Swapper 使用场景

Swapper 适合做跨容器或批量编排逻辑，包括但不限于：

- 指定位置交换（同容器或跨容器）
- 按 ID 或按实例移动物品（自动堆叠与空位分配）
- 拆分/合并堆叠
- 批量操作与模拟计算（UI 预览）

## 设计原则

- **数据与逻辑分离**：`ItemData` 只描述静态数据，运行时行为由 `Item` 与 `ItemContainer` 管理
- **性能优先**：空位与物品位置使用索引映射缓存，减少线性扫描
- **可扩展**：Swapper 提供统一编排入口，可扩展交易、掉落、拾取等业务

## 常见扩展方向

- 权限/标签规则（容器限定标签、任务物品锁定）
- 重量/体积系统
- 自动整理与排序
- 交易/合成/掉落逻辑

## 版本与兼容性

- 目标引擎：Godot 4.x（建议 4.4）
- 本插件为运行时逻辑层，UI 需自行实现

