# ContainerSystem 插件

面向 Godot 4 的运行时容器/背包系统插件，提供容器管理、物品堆叠与跨容器操作的基础能力。支持 O(1) 级别的空位与物品位置查询，并提供模拟计算接口用于 UI 预览。

想要理解完整的系统是如何实现以及如何使用？参考这个文档：https://deepwiki.com/PrimeChuJiang/ItemContainerSystem

## 功能概览

- 物品与容器分离的数据结构（`ItemData` / `Item` / `ItemContainer`）
- 物品堆叠、可添加标签校验、位置管理
- 容器容量变更与物品重分配
- O(1) 空位与物品位置查询（基于索引映射）
- 跨容器交换、移动、拆分/合并、批量操作（`Swapper`）
- 支持只计算不执行的模拟接口（UI 预览友好）

## 目录结构

```
addons/ContainerSystem/
├── core/
│   ├── ContainerSystem.gd    # 单例，管理物品数据映射表
│   ├── Item.gd               # 运行时物品实例
│   ├── ItemBehaviourData.gd  # 物品行为基类
│   ├── ItemContainer.gd      # 容器核心逻辑
│   ├── ItemData.gd           # 物品静态配置
│   ├── ItemDataMap.gd        # 物品数据映射表
│   ├── Swapper.gd            # 跨容器静态工具类
│   ├── SwaperTool.gd         # 交换工具（旧版兼容）
│   └── Tag.gd                # 标签类
├── classes/                  # 预设类
├── templates/                # 模板资源
└── plugin.cfg               # 插件配置
```

## 核心类分工

| 类名 | 职责 |
|------|------|
| `ItemData` | 物品静态配置（名称、图标、最大堆叠、标签、行为等） |
| `Item` | 运行时物品实例（堆叠数量、所在容器、位置） |
| `ItemContainer` | 单容器内的存取、校验、堆叠规则、信号广播与索引维护 |
| `Swapper` | 跨容器与批量操作编排，提供 `simulate_*` 只读计算路径 |
| `Tag` | 物品标签，用于容器访问控制 |
| `ContainerSystem` | 全局单例，维护物品ID/名称映射表 |

## 快速开始

### 1. 启用插件

在 `project.godot` 中配置：

```ini
[autoload]
ItemContainerSystem="*res://addons/ContainerSystem/core/ContainerSystem.gd"

[container_system]
item_data_map="res://Resources/test_item_data_map.tres"
```

### 2. 创建容器并初始化

```gdscript
var container := ItemContainer.new()
container.initialize(20, "背包", "玩家背包", addable_tags)
add_child(container)
```

### 3. 添加物品

```gdscript
# 通过物品模板添加
var item_data = ItemContainerSystem.get_item_data_by_id(0)
container.add_item_by_itemdata(item_data, -1, true, 1)

# 或通过Item实例添加
var item := Item.new(item_data, container, -1, 3)
container.add_item(item)
```

### 4. 删除物品

```gdscript
container.remove_item_in_position(0, 1)  # 按位置删除
container.remove_item_by_id(item_id, 2)  # 按ID删除
```

### 5. 跨容器移动

```gdscript
Swapper.move_item(source_container, dest_container, item, count, dest_index)
Swapper.move_by_id(bag, warehouse, item_id, 5)
```

### 6. 交换与堆叠

```gdscript
# 交换两个位置的物品
Swapper.swap_positions(container_a, index_a, container_b, index_b)

# 合并堆叠
Swapper.merge_stack(container, from_index, to_index)

# 拆分堆叠
Swapper.split_stack(container, index, split_count, dest_index)
```

### 7. 预览操作（不执行）

```gdscript
var preview := Swapper.simulate_move(bag, warehouse, item_id, 5)
if preview["code"] == Swapper.SUCCESS:
    print(preview["src_changes"], preview["dst_changes"])
```

## 重要信号

`ItemContainer` 内部维护以下信号用于 UI 或数据同步：

| 信号 | 说明 |
|------|------|
| `item_changed(is_add: bool, index: int, item: Item)` | 物品添加/移除/数量变更 |
| `illegal_items_changed(illegal_items: Array[Item])` | 无法添加的物品列表 |
| `size_changed(new_size: int)` | 容器大小变更 |

---

## 示例项目

项目包含一个完整的背包-仓库交互示例，演示如何使用插件API实现物品管理系统。

### 示例场景

运行 `Scenes/Container_Sample_01.tscn` 查看示例。

### UI 层级结构

```
ContainerSample (主场景)
├── Bagpack (背包面板)
│   └── GridContainer
│       └── SampleContainerSlotUI (插槽) × 8
│           └── SampleItemUI (物品UI)
├── Storehouse (仓库面板)
│   └── GridContainer
│       └── SampleContainerSlotUI (插槽) × 16
│           └── SampleItemUI (物品UI)
└── ItemTooltip (物品详情悬浮框)
```

### 示例组件说明

| 组件 | 文件 | 职责 |
|------|------|------|
| `ContainerSample` | `Scripts/container_sample.gd` | 主场景脚本，初始化容器和UI |
| `SampleContainerSlotUI` | `Scripts/container_slot.gd` | 插槽UI，处理拖放逻辑 |
| `SampleItemUI` | `Scripts/item_ui.gd` | 物品UI，显示图标和拖拽 |
| `ItemTooltip` | `Scripts/item_tooltip.gd` | 物品详情悬浮提示 |

### 功能特性

#### 1. 物品拖拽
- 拖拽物品到空位：直接移动
- 拖拽到相同物品：自动堆叠
- 拖拽到不同物品：交换位置

#### 2. Tag 控制
- **背包**：有 Tag 控制，只能存放带有匹配 Tag 的物品
- **仓库**：无 Tag 控制，可以存放任何物品

#### 3. 物品详情
- 鼠标悬浮物品 1 秒后显示详情面板
- 详情面板包含：物品名称、描述、数量
- 点击"使用"按钮可使用物品

### 数据流设计原则

```
┌─────────────────┐      API 调用      ┌──────────────────┐
│     UI 层       │  ───────────────→  │   Swapper API    │
│ (不直接改数据)   │                    │   (数据操作)      │
└─────────────────┘                    └──────────────────┘
         ↑                                      │
         │              信号通知                 │
         └──────────────────────────────────────┘
```

**核心原则**：UI 层只负责触发操作和响应信号，所有数据操作通过 `Swapper` API 完成。

### 操作指南

| 操作 | 说明 |
|------|------|
| 点击"添加物品A/B" | 向背包添加物品（需符合Tag） |
| 拖拽物品 | 移动、交换或堆叠物品 |
| 悬浮物品 1 秒 | 显示物品详情 |
| 点击"使用"按钮 | 使用并消耗 1 个物品 |

---

## 设计原则

- **数据与逻辑分离**：`ItemData` 只描述静态数据，运行时行为由 `Item` 与 `ItemContainer` 管理
- **性能优先**：空位与物品位置使用索引映射缓存，减少线性扫描
- **可扩展**：Swapper 提供统一编排入口，可扩展交易、掉落、拾取等业务
- **UI 与数据解耦**：UI 通过信号响应数据变化，不直接操作数据

## 常见扩展方向

- 权限/标签规则（容器限定标签、任务物品锁定）
- 重量/体积系统
- 自动整理与排序
- 交易/合成/掉落逻辑
- 物品冷却系统
- 快捷栏绑定

## 错误码参考

### ItemContainer 错误码

| 码值 | 常量 | 说明 |
|------|------|------|
| 200 | `SUCCESS` | 操作成功 |
| 400 | `CAN_ADD_ITEM_TAG_CONTAIN_ERROR` | Tag 不匹配 |
| 401 | `CAN_ADD_ITEM_INDEX_ERROR` | 位置已占用 |
| 402 | `CAN_ADD_ITEM_STACK_ERROR` | 堆叠超限 |
| 406 | `CAN_ADD_ITEM_INDEX_OUT_OF_RANGE_ERROR` | 索引越界 |
| 407 | `CAN_REMOVE_ITEM_NUM_ERROR` | 数量不足 |
| 409 | `CAN_ADD_ITEM_SPACE_ERROR` | 空间不足 |

### Swapper 错误码

| 码值 | 常量 | 说明 |
|------|------|------|
| 500 | `ERROR_SRC_CONTAINER_NULL` | 源容器为空 |
| 501 | `ERROR_DST_CONTAINER_NULL` | 目标容器为空 |
| 502 | `ERROR_SRC_INDEX_INVALID` | 源索引无效 |
| 503 | `ERROR_DST_INDEX_INVALID` | 目标索引无效 |
| 504 | `ERROR_ITEM_NULL` | 物品为空 |
| 505 | `ERROR_SPLIT_NUM_INVALID` | 拆分数量无效 |

## 版本与兼容性

- 目标引擎：Godot 4.x（建议 4.4+）
- 本插件为运行时逻辑层，UI 需自行实现（可参考示例项目）

## 许可证

MIT License
