class_name SearchUI
extends CanvasLayer
## 搜索界面：同时显示背包与容器；容器内物品逐格延迟显现，支持双击/拖拽拾取，Esc 关闭。


const REVEAL_TIME := 1.2       # 每个物品显现耗时（秒）
const BAG_SLOTS := 12          # 背包格数
const SPINNER := ["◐", "◓", "◑", "◒"]
const ITEM_DB := {
	"scrap":  {"name": "废料",   "hex": "ffd166"},
	"medkit": {"name": "医疗包", "hex": "ff5d8f"},
	"ammo":   {"name": "弹药",   "hex": "80ed99"},
	"parts":  {"name": "零件",   "hex": "4cc9f0"},
	"cloth":  {"name": "布料",   "hex": "b8b8d1"},
}

var container: LootContainer = null
var _spin: float = 0.0
var _elapsed: float = 0.0

var bag_grid: GridContainer
var cont_grid: GridContainer


func _ready() -> void:
	visible = false

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)

	var panel := VBoxContainer.new()
	panel.add_theme_constant_override("separation", 12)
	center.add_child(panel)

	var title := Label.new()
	title.text = "搜索"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	panel.add_child(row)

	var bag_box := VBoxContainer.new()
	bag_box.add_theme_constant_override("separation", 6)
	row.add_child(bag_box)
	var bag_title := Label.new()
	bag_title.text = "我的背包"
	bag_title.add_theme_font_size_override("font_size", 20)
	bag_box.add_child(bag_title)
	bag_grid = GridContainer.new()
	bag_grid.columns = 4
	bag_grid.add_theme_constant_override("h_separation", 6)
	bag_grid.add_theme_constant_override("v_separation", 6)
	bag_box.add_child(bag_grid)

	var cont_box := VBoxContainer.new()
	cont_box.add_theme_constant_override("separation", 6)
	row.add_child(cont_box)
	var cont_title := Label.new()
	cont_title.text = "容器"
	cont_title.add_theme_font_size_override("font_size", 20)
	cont_box.add_child(cont_title)
	cont_grid = GridContainer.new()
	cont_grid.columns = 4
	cont_grid.add_theme_constant_override("h_separation", 6)
	cont_grid.add_theme_constant_override("v_separation", 6)
	cont_box.add_child(cont_grid)

	var hint := Label.new()
	hint.text = "双击或拖拽物品到背包 · Esc 关闭（转圈期间也可退出）"
	hint.add_theme_font_size_override("font_size", 16)
	hint.modulate = Color(0.75, 0.78, 0.82)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)


func open(c: LootContainer) -> void:
	container = c
	_elapsed = 0.0
	visible = true
	_rebuild()


func close() -> void:
	container = null
	visible = false


func _process(delta: float) -> void:
	if not visible or container == null:
		return
	_spin += delta
	_elapsed += delta

	# 逐格显现：每个槽延迟 0.4s 依次开始，进度持久保存在容器上
	for i in container.reveal_progress.size():
		if container.reveal_progress[i] >= 1.0:
			continue
		if _elapsed > i * 0.4:
			container.reveal_progress[i] = minf(
				container.reveal_progress[i] + delta / REVEAL_TIME, 1.0)

	_refresh_cells()


func _rebuild() -> void:
	for ch in bag_grid.get_children():
		ch.queue_free()
	for ch in cont_grid.get_children():
		ch.queue_free()

	for i in BAG_SLOTS:
		var cell := InvCell.new()
		cell.ui = self
		cell.role = "bag"
		cell.slot = i
		bag_grid.add_child(cell)

	if container != null:
		for i in container.loot.size():
			var cell := InvCell.new()
			cell.ui = self
			cell.role = "container"
			cell.slot = i
			cont_grid.add_child(cell)

	_refresh_cells()


func _refresh_cells() -> void:
	for i in bag_grid.get_child_count():
		var cell := bag_grid.get_child(i) as InvCell
		if cell == null:
			continue
		if i < GameState.backpack.size():
			var it: String = GameState.backpack[i]
			cell.set_text(item_name(it))
			cell.set_color(item_color(it))
		else:
			cell.set_text("")
			cell.set_color(Color(0.5, 0.5, 0.5))

	if container == null:
		return
	for i in cont_grid.get_child_count():
		if i >= container.loot.size():
			break
		var cell := cont_grid.get_child(i) as InvCell
		if cell == null:
			continue
		var p: float = container.reveal_progress[i]
		var it: String = container.loot[i]
		if it == "":
			cell.set_text("")
			cell.set_color(Color(0.35, 0.35, 0.38))
		elif p >= 1.0:
			cell.set_text(item_name(it))
			cell.set_color(item_color(it))
		elif p > 0.0:
			var sp: String = SPINNER[int(_spin * 8.0) % SPINNER.size()]
			cell.set_text(sp)
			cell.set_color(Color("9ef01a"))
		else:
			cell.set_text("?")
			cell.set_color(Color(0.5, 0.5, 0.5))


func item_name(id: String) -> String:
	return ITEM_DB[id]["name"]


func item_color(id: String) -> Color:
	return Color(ITEM_DB[id]["hex"])


func container_item(slot: int) -> String:
	if container == null or slot >= container.loot.size():
		return ""
	return container.loot[slot]


func bag_item(slot: int) -> String:
	if slot >= 0 and slot < GameState.backpack.size():
		return GameState.backpack[slot]
	return ""


func container_slot_empty(slot: int) -> bool:
	if container == null or slot >= container.loot.size():
		return false
	return container.loot[slot] == ""


func is_revealed(slot: int) -> bool:
	if container == null or slot >= container.reveal_progress.size():
		return false
	return container.reveal_progress[slot] >= 1.0


func transfer_from_container(slot: int) -> void:
	if container == null:
		return
	var it: String = container.loot[slot]
	if it == "":
		return
	container.loot[slot] = ""
	container.reveal_progress[slot] = 0.0
	GameState.add_to_backpack(it)
	_rebuild()


func transfer_to_container(cont_slot: int, bag_slot: int) -> void:
	if container == null or cont_slot >= container.loot.size():
		return
	if container.loot[cont_slot] != "":
		return
	if bag_slot < 0 or bag_slot >= GameState.backpack.size():
		return
	var it: String = GameState.backpack[bag_slot]
	GameState.backpack.remove_at(bag_slot)
	container.loot[cont_slot] = it
	container.reveal_progress[cont_slot] = 1.0
	_rebuild()