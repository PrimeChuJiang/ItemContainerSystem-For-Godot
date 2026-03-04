# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Godot 4 addon for runtime inventory/container management. Provides O(1) container operations, cross-container item transfers, and simulation APIs for UI preview.

- **Engine**: Godot 4.x (tested with 4.4)
- **Language**: GDScript
- **Documentation**: https://deepwiki.com/PrimeChuJiang/ItemContainerSystem
- **Godot Docs Reference**: https://docs.godotengine.org/zh-cn/4.4/index.html

## Running the Project

Open in Godot 4.4+ and run `Scenes/Container_Sample_01.tscn` for the demo.

## Architecture

### Core Classes (addons/ContainerSystem/core/)

| Class | Role |
|-------|------|
| `ItemData` | Static item configuration (Resource) - StringName id, name, icon, max_stack, tags, behaviors |
| `Item` | Runtime item instance (RefCounted) - stack count, container reference, position |
| `ItemContainer` | Container logic (Node) - manages storage, emits signals, maintains index maps |
| `Swapper` | Static utility for cross-container operations - move, swap, merge, split, simulate |
| `Tag` | Access control classification (Resource) - parent_tag is runtime-only (not serialized) |
| `TagHierarchy` | Stores root tags, reconstructs parent refs on load via initialize_paths() |
| `TagManager` | Autoload singleton - O(1) tag path lookups and hierarchy traversal |
| `ContainerSystem` | Autoload singleton - maps StringName IDs/names to ItemData templates |

### Data Flow Pattern

```
UI Layer → Swapper API → ItemContainer → Signals → UI Updates
```

**Key principle**: UI never directly modifies data. All changes go through Swapper → ItemContainer, then UI reacts to signals.

### Performance: Index Mapping

ItemContainer uses two maps for O(1) lookups:
- `item_id_pos_map`: Dictionary mapping StringName(item_id) → Array[positions]
- `item_empty_pos_map`: Array[int] of free slot indices

### Signals (ItemContainer)

- `item_changed(is_add: bool, index: int, item: Item)` - Item add/remove/quantity change
- `illegal_items_changed(illegal_items: Array[Item])` - Items that failed to fit
- `size_changed(new_size: int)` - Container capacity changed

## Key APIs

### Adding Items
```gdscript
var item_data = ItemContainerSystem.get_item_data_by_id(&"apple")
container.add_item_by_itemdata(item_data, -1, true, 1)
```

### Cross-Container Operations
```gdscript
Swapper.move_item(src_container, dst_container, item, count, dst_index)
Swapper.swap_positions(container_a, idx_a, container_b, idx_b)
Swapper.merge_stack(container, from_idx, to_idx)
Swapper.split_stack(container, idx, split_count, dest_idx)
```

### Simulation (preview without executing)
```gdscript
var preview = Swapper.simulate_move(bag, warehouse, &"apple", 5)
if preview["code"] == Swapper.SUCCESS:
    print(preview["src_changes"], preview["dst_changes"])
```

## Error Codes

**ItemContainer**: 200 (SUCCESS), 400-410 (TAG_ERROR, INDEX_ERROR, STACK_ERROR, SPACE_ERROR, etc.)

**Swapper**: 500-507 (CONTAINER_NULL, INDEX_INVALID, ITEM_NULL, SPLIT_NUM_INVALID, etc.)

## Project Configuration

Autoload singleton path: `res://addons/ContainerSystem/core/ContainerSystem.gd`

Project settings:
- `container_system/item_data_map` - Path to ItemDataMap resource
- `container_system/tag_hierarchy` - Path to TagHierarchy resource (configured via Tag Manager panel on first use)

## Example Implementation

`Scripts/` directory contains working UI examples:
- `container_sample.gd` - Main scene orchestrator
- `container_slot.gd` - Slot UI with drag/drop
- `item_ui.gd` - Item rendering and drag preview
- `item_tooltip.gd` - Hover tooltip with "use" button

## Extending the System

- **Custom behaviors**: Extend `ItemBehaviourData`, implement `use_item(item, character_from, character_to, num)`
- **Tag restrictions**: Create Tag resources, assign to containers via `addable_tags`
- **Item templates**: Create ItemData resources in editor, add to ItemDataMap
