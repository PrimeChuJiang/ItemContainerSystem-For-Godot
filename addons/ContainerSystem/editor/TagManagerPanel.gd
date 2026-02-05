# Tag Manager 编辑器面板
@tool
extends PanelContainer

var tag_tree: Tree
var add_root_btn: Button
var add_child_btn: Button
var delete_btn: Button
var hierarchy: TagHierarchy
var hierarchy_path: String

var selected_item: TreeItem = null
var selected_tag: Tag = null

func _init() -> void:
	# 在 _init 中设置 name，确保在添加到 dock 之前就有名称
	name = "Tag Manager"

func _ready() -> void:
	custom_minimum_size = Vector2(200, 300)
	_setup_ui()
	_load_hierarchy()
	_populate_tree()

func _setup_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 标题
	var title_label = Label.new()
	title_label.text = "Tag Manager"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	# 工具栏
	var toolbar = HBoxContainer.new()

	add_root_btn = Button.new()
	add_root_btn.text = "添加根标签"
	add_root_btn.pressed.connect(_on_add_root_pressed)
	toolbar.add_child(add_root_btn)

	add_child_btn = Button.new()
	add_child_btn.text = "添加子标签"
	add_child_btn.pressed.connect(_on_add_child_pressed)
	add_child_btn.disabled = true
	toolbar.add_child(add_child_btn)

	delete_btn = Button.new()
	delete_btn.text = "删除"
	delete_btn.pressed.connect(_on_delete_pressed)
	delete_btn.disabled = true
	toolbar.add_child(delete_btn)

	main_vbox.add_child(toolbar)

	# 分隔线
	var separator = HSeparator.new()
	main_vbox.add_child(separator)

	# 标签树
	tag_tree = Tree.new()
	tag_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tag_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_tree.item_selected.connect(_on_item_selected)
	tag_tree.item_edited.connect(_on_item_edited)
	tag_tree.item_activated.connect(_on_item_activated)  # 双击时触发
	tag_tree.set_column_expand(0, true)
	main_vbox.add_child(tag_tree)

	add_child(main_vbox)

func _load_hierarchy() -> void:
	hierarchy_path = ProjectSettings.get_setting(
		"container_system/tag_hierarchy",
		"res://addons/ContainerSystem/templates/TagHierarchy.tres"
	)
	if ResourceLoader.exists(hierarchy_path):
		hierarchy = load(hierarchy_path) as TagHierarchy
		if hierarchy:
			hierarchy.initialize_paths()
	if not hierarchy:
		hierarchy = TagHierarchy.new()
		_save_hierarchy()

func _save_hierarchy() -> void:
	if hierarchy == null:
		return
	# 确保目录存在
	var dir = hierarchy_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	hierarchy.take_over_path(hierarchy_path)
	var err = ResourceSaver.save(hierarchy, hierarchy_path)
	if err != OK:
		push_error("TagManagerPanel: 保存 TagHierarchy 失败，错误码: " + str(err))

func _populate_tree() -> void:
	tag_tree.clear()
	var root = tag_tree.create_item()
	root.set_text(0, "所有标签")
	root.set_selectable(0, false)

	if hierarchy:
		for tag in hierarchy.root_tags:
			_add_tag_to_tree(root, tag)

func _add_tag_to_tree(parent_item: TreeItem, tag: Tag) -> TreeItem:
	if tag == null:
		return null
	var item = tag_tree.create_item(parent_item)
	item.set_text(0, tag.name)
	# 不设置 editable，双击时才启用编辑
	item.set_meta("tag", tag)

	# 显示完整路径作为提示
	if tag.tag_path.is_empty():
		tag._update_path()
	item.set_tooltip_text(0, tag.tag_path)

	for child_tag in tag.child_tags:
		_add_tag_to_tree(item, child_tag)

	return item

func _on_item_selected() -> void:
	selected_item = tag_tree.get_selected()
	if selected_item and selected_item.has_meta("tag"):
		selected_tag = selected_item.get_meta("tag")
		add_child_btn.disabled = false
		delete_btn.disabled = false
	else:
		selected_tag = null
		add_child_btn.disabled = true
		delete_btn.disabled = true

func _on_item_activated() -> void:
	# 双击时进入编辑模式
	var item = tag_tree.get_selected()
	if item and item.has_meta("tag"):
		item.set_editable(0, true)
		tag_tree.edit_selected()
		# 编辑完成后会触发 _on_item_edited

func _on_item_edited() -> void:
	var item = tag_tree.get_edited()
	if item and item.has_meta("tag"):
		var tag: Tag = item.get_meta("tag")
		var new_name = item.get_text(0)
		# 编辑完成后禁用编辑状态
		item.set_editable(0, false)
		if new_name.is_empty():
			# 不允许空名称，恢复原名
			item.set_text(0, tag.name)
			return
		if new_name != tag.name:
			tag.name = new_name
			tag._update_path()
			item.set_tooltip_text(0, tag.tag_path)
			_save_hierarchy()

func _on_add_root_pressed() -> void:
	var new_tag = Tag.new()
	new_tag.name = "NewTag"
	new_tag.tag_path = "NewTag"
	hierarchy.add_root_tag(new_tag)
	_save_hierarchy()
	_populate_tree()

func _on_add_child_pressed() -> void:
	if not selected_tag:
		return
	var new_tag = Tag.new()
	new_tag.name = "NewTag"
	new_tag.parent_tag = selected_tag
	new_tag._update_path()
	selected_tag.child_tags.append(new_tag)
	_save_hierarchy()
	_populate_tree()

func _on_delete_pressed() -> void:
	if not selected_tag:
		return
	hierarchy.remove_tag(selected_tag)
	selected_tag = null
	selected_item = null
	add_child_btn.disabled = true
	delete_btn.disabled = true
	_save_hierarchy()
	_populate_tree()

# 刷新面板 (外部调用)
func refresh() -> void:
	_load_hierarchy()
	_populate_tree()
