class_name InvCell
extends Panel
## 背包 / 容器里的一格：负责显示、双击拾取、拖拽。


var ui = null             # SearchUI 引用
var role: String = "bag"  # "bag" / "container"
var slot: int = 0
var label: Label


func _init() -> void:
	custom_minimum_size = Vector2(80, 80)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.17, 0.21)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.30, 0.32, 0.38)
	add_theme_stylebox_override("panel", sb)

	label = Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	add_child(label)


func set_text(t: String) -> void:
	label.text = t


func set_color(c: Color) -> void:
	label.modulate = c


func _get_drag_data(_at_position: Vector2):
	if ui == null:
		return null
	var it: String = ""
	if role == "container":
		it = ui.container_item(slot)
		if it == "" or not ui.is_revealed(slot):
			return null
	elif role == "bag":
		it = ui.bag_item(slot)
		if it == "":
			return null
	else:
		return null
	var preview := ColorRect.new()
	preview.color = ui.item_color(it)
	preview.size = Vector2(48, 48)
	set_drag_preview(preview)
	return {"role": role, "slot": slot, "item": it}


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if ui == null or not (data is Dictionary):
		return false
	var src: String = data.get("role")
	if role == "bag":
		return src == "container"
	elif role == "container":
		return src == "bag" and ui.container_slot_empty(slot)
	return false


func _drop_data(_at_position: Vector2, data) -> void:
	if ui == null or not (data is Dictionary):
		return
	if role == "bag" and data.get("role") == "container":
		ui.transfer_from_container(data["slot"])
	elif role == "container" and data.get("role") == "bag":
		ui.transfer_to_container(slot, data["slot"])


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		if role == "container" and ui != null and ui.is_revealed(slot):
			accept_event()
			ui.transfer_from_container(slot)