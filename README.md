# ContainerSystem — Godot 4 容器/背包系统插件

一个专为 Godot 4 设计的运行时容器管理插件，适用于 RPG 背包、仓库、交易、掉落等一切需要物品存取的场景。核心特性包括 O(1) 的空位与物品位置查询、跨容器移动/交换/拆分/合并、层级化标签访问控制，以及不执行即可预览结果的模拟接口。

> 完整文档：[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/PrimeChuJiang/ItemContainerSystem)

---

## 特性一览

- **O(1) 高性能查询** — 空位、物品位置均由索引映射缓存驱动，无线性扫描
- **跨容器操作** — 通过 `Swapper` 统一编排移动、交换、拆分、合并，支持跨任意容器
- **模拟计算** — `simulate_move` / `simulate_swap` 返回预览数据，不修改实际状态，适合 UI 预览
- **层级化标签系统** — 标签支持树状层级（如 `Food.Fruit.Apple`），容器可按标签过滤允许存入的物品
- **智能堆叠分配** — 添加物品时自动优先填充已有未满堆叠，再占用新空位
- **容器动态缩放** — 运行时调整容器大小，自动重新分配溢出物品
- **信号驱动的 UI 解耦** — 所有数据变更通过信号广播，UI 只需订阅、响应即可
- **可扩展行为系统** — 继承 `ItemBehaviourData` 实现自定义物品使用效果

---

## 目录结构

```
addons/ContainerSystem/
├── core/
│   ├── ContainerSystem.gd      # Autoload 单例 — 物品模板注册与查询
│   ├── ItemData.gd             # 物品静态配置（Resource）
│   ├── Item.gd                 # 运行时物品实例（RefCounted）
│   ├── ItemContainer.gd        # 容器核心 — 存取、校验、索引维护、信号
│   ├── Swapper.gd              # 跨容器操作与模拟计算（静态工具类）
│   ├── Tag.gd                  # 层级化标签
│   ├── TagHierarchy.gd         # 标签层级存储
│   ├── TagManager.gd           # Autoload 单例 — 标签路径查询与层级遍历
│   ├── ItemDataMap.gd          # 物品数据映射表（Resource）
│   ├── ItemBehaviourData.gd    # 物品行为基类
│   └── PackageManager.gd       # 包管理工具
├── editor/
│   └── TagManagerPanel.gd      # 编辑器内的标签管理面板
├── classes/                    # 预设简化类
├── templates/                  # 模板资源与示例
└── plugin.cfg                  # 插件配置
```

---

## 核心架构

### 类职责

| 类 | 继承 | 职责 |
|---|---|---|
| `ItemData` | Resource | 物品静态模板 — 名称、图标、最大堆叠、标签、行为列表 |
| `Item` | RefCounted | 运行时物品实例 — 当前堆叠数、所在容器引用、位置索引 |
| `ItemContainer` | Node | 单容器管理 — 存取、标签校验、堆叠规则、O(1) 索引维护、信号广播 |
| `Swapper` | RefCounted | 跨容器编排 — 移动/交换/拆分/合并/模拟，所有操作的统一入口 |
| `Tag` | Resource | 层级标签 — 支持父子关系、路径匹配（如 `Food.Fruit`） |
| `TagManager` | Node | 全局标签注册表 — O(1) 路径查询、层级遍历 |
| `ContainerSystem` | Node | 全局物品注册表 — 按 ID/名称查询 ItemData 模板 |

### 数据流

```
UI 层（只触发操作 & 响应信号）
    │
    │  用户操作（拖拽、点击）
    ↓
Swapper API（编排数据操作）
    │
    ↓
ItemContainer（执行存取 & 维护索引）
    │
    │  信号（item_changed / size_changed / illegal_items_changed）
    ↓
UI 层（根据信号刷新显示）
```

**核心原则**：UI 永远不直接修改数据。所有变更经由 Swapper → ItemContainer，再由信号通知 UI 更新。

### O(1) 索引映射

`ItemContainer` 内部维护两个映射结构：

| 结构 | 类型 | 用途 |
|---|---|---|
| `item_id_pos_map` | `Dictionary { item_id → Array[int] }` | 根据物品 ID 即时定位所有槽位 |
| `item_empty_pos_map` | `Array[int]`（有序） | 即时获取第一个空位 |

---

## 快速开始

### 1. 安装插件

将 `addons/ContainerSystem/` 复制到项目的 `addons/` 目录下，然后在 **Project → Project Settings → Plugins** 中启用 `Container System`。

插件启用后会自动注册两个 Autoload 单例：
- `ItemContainerSystem` — 物品模板查询
- `TagManager` — 标签层级查询

### 2. 配置数据

在 **Project Settings** 中设置：
- `container_system/item_data_map` → 指向你的 `ItemDataMap` 资源
- `container_system/tag_hierarchy` → 指向你的 `TagHierarchy` 资源

### 3. 创建容器

```gdscript
var container := ItemContainer.new()
container.initialize(20, "背包", "玩家背包", addable_tags)
add_child(container)
```

### 4. 添加物品

```gdscript
# 通过全局单例获取物品模板
var item_data = ItemContainerSystem.get_item_data_by_id(0)

# 方式一：通过模板添加（自动创建 Item 实例）
container.add_item_by_itemdata(item_data, -1, true, 1)

# 方式二：手动创建 Item 后添加
var item := Item.new(item_data, container, -1, 3)
container.add_item(item)
```

### 5. 删除物品

```gdscript
container.remove_item_in_position(0, 1)   # 按位置删除指定数量
container.remove_item_by_id(item_id, 2)   # 按物品 ID 删除指定数量
```

### 6. 跨容器操作

```gdscript
# 移动物品到另一个容器
Swapper.move_item(src_container, dst_container, item, count, dst_index)
Swapper.move_by_id(bag, warehouse, item_id, 5)

# 交换两个位置
Swapper.swap_positions(container_a, index_a, container_b, index_b)

# 堆叠合并 / 拆分
Swapper.merge_stack(container, from_index, to_index)
Swapper.split_stack(container, index, split_count, dest_index)
```

### 7. 模拟预览（不执行）

```gdscript
var preview := Swapper.simulate_move(bag, warehouse, item_id, 5)
if preview["code"] == Swapper.SUCCESS:
    print("源容器变化: ", preview["src_changes"])
    print("目标容器变化: ", preview["dst_changes"])
```

### 8. 监听信号

```gdscript
container.item_changed.connect(_on_item_changed)
container.size_changed.connect(_on_size_changed)
container.illegal_items_changed.connect(_on_illegal_items)

func _on_item_changed(is_add: bool, index: int, item: Item):
    # 刷新对应槽位的 UI
    pass
```

---

## 信号参考

| 信号 | 参数 | 触发时机 |
|---|---|---|
| `item_changed` | `is_add: bool, index: int, item: Item` | 物品添加、移除、数量变更 |
| `illegal_items_changed` | `illegal_items: Array[Item]` | 容器缩容后溢出的物品 |
| `size_changed` | `new_size: int` | 容器大小变更 |

---

## 错误码参考

### ItemContainer（400 系列）

| 码值 | 常量 | 说明 |
|---|---|---|
| 200 | `SUCCESS` | 操作成功 |
| 400 | `CAN_ADD_ITEM_TAG_CONTAIN_ERROR` | 标签不匹配，物品被容器拒绝 |
| 401 | `CAN_ADD_ITEM_INDEX_ERROR` | 目标位置已被占用 |
| 402 | `CAN_ADD_ITEM_STACK_ERROR` | 堆叠数量超过上限 |
| 406 | `CAN_ADD_ITEM_INDEX_OUT_OF_RANGE_ERROR` | 索引越界 |
| 407 | `CAN_REMOVE_ITEM_NUM_ERROR` | 移除数量超过持有数量 |
| 408 | `CAN_REMOVE_ITEM_INDEX_NULL_ERROR` | 目标位置为空 |
| 409 | `CAN_ADD_ITEM_SPACE_ERROR` | 容器空间不足 |
| 410 | `ID_NOT_FOUND_ERROR` | 物品 ID 不存在 |

### Swapper（500 系列）

| 码值 | 常量 | 说明 |
|---|---|---|
| 500 | `ERROR_SRC_CONTAINER_NULL` | 源容器为空 |
| 501 | `ERROR_DST_CONTAINER_NULL` | 目标容器为空 |
| 502 | `ERROR_SRC_INDEX_INVALID` | 源索引无效 |
| 503 | `ERROR_DST_INDEX_INVALID` | 目标索引无效 |
| 504 | `ERROR_ITEM_NULL` | 物品为空 |
| 505 | `ERROR_SPLIT_NUM_INVALID` | 拆分数量无效 |
| 506 | `ERROR_SAME_POSITION` | 源与目标是同一位置 |
| 507 | `ERROR_PARTIAL_SUCCESS` | 批量操作部分成功 |

---

## 示例项目

项目包含一个完整的背包-仓库交互示例，运行 `Scenes/Container_Sample_01.tscn` 即可体验。

### UI 结构

```
ContainerSample（主场景）
├── Bagpack（背包面板 — 8 格，Tag 限制）
│   └── GridContainer
│       └── SampleContainerSlotUI × 8
│           └── SampleItemUI
├── Storehouse（仓库面板 — 16 格，无限制）
│   └── GridContainer
│       └── SampleContainerSlotUI × 16
│           └── SampleItemUI
└── ItemTooltip（物品详情悬浮框）
```

### 示例组件

| 组件 | 脚本 | 职责 |
|---|---|---|
| `ContainerSample` | `Scripts/container_sample.gd` | 初始化容器、绑定信号、管理 UI |
| `SampleContainerSlotUI` | `Scripts/container_slot.gd` | 槽位 UI，处理拖放与标签校验 |
| `SampleItemUI` | `Scripts/item_ui.gd` | 物品图标与数量渲染、拖拽预览 |
| `ItemTooltip` | `Scripts/item_tooltip.gd` | 悬浮详情面板、"使用"按钮 |

### 交互说明

| 操作 | 效果 |
|---|---|
| 点击"添加物品 A/B" | 向背包添加物品（需符合标签要求） |
| 拖拽物品到空位 | 移动物品 |
| 拖拽到同种物品 | 自动堆叠 |
| 拖拽到不同物品 | 交换位置 |
| 悬浮物品 1 秒 | 显示物品详情 |
| 点击"使用"按钮 | 消耗 1 个物品，触发物品行为 |

---

## 扩展指南

### 自定义物品行为

继承 `ItemBehaviourData`，重写 `use_item` 方法：

```gdscript
class_name MyBehaviour extends ItemBehaviourData

func use_item(item: Item, character_from, character_to, num: int):
    # 实现你的物品使用逻辑
    pass
```

### 标签访问控制

创建 `Tag` 资源并利用层级结构进行分类，然后将标签分配给容器的 `addable_tags`：

```gdscript
container.addable_tags = [fruit_tag, weapon_tag]
container.use_hierarchical_tags = true  # 启用层级匹配
```

### 常见扩展方向

- 重量 / 体积系统
- 自动整理与排序
- 交易 / 合成 / 掉落逻辑
- 物品冷却与耐久度
- 快捷栏绑定

---

## 版本与兼容性

- **引擎**：Godot 4.x（建议 4.4+）
- **语言**：GDScript
- **定位**：运行时逻辑层，UI 需自行实现（可参考示例项目）

## 许可证

MIT License
