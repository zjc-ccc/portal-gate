extends Node2D
## 现实世界 · 家园（占位）：仓库、购买弹药、进入反世界。


var info_label: Label
var result_label: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)

	var bg := ColorRect.new()
	bg.color = Color("121a22")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)

	var title := Label.new()
	title.text = "现实世界 · 家园（占位）"
	title.add_theme_font_size_override("font_size", 40)
	title.position = Vector2(60, 40)
	ui.add_child(title)

	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 22)
	info_label.position = Vector2(60, 130)
	ui.add_child(info_label)

	result_label = Label.new()
	result_label.add_theme_font_size_override("font_size", 22)
	result_label.modulate = Color("ffd166")
	result_label.position = Vector2(60, 190)
	ui.add_child(result_label)

	var buy := Button.new()
	buy.text = "购买弹药（+30，占位免费）"
	buy.position = Vector2(60, 270)
	buy.size = Vector2(340, 42)
	buy.pressed.connect(_on_buy_pressed)
	ui.add_child(buy)

	var go := Button.new()
	go.text = "进入反世界（传送门）"
	go.position = Vector2(60, 330)
	go.size = Vector2(340, 50)
	go.pressed.connect(_on_go_pressed)
	ui.add_child(go)

	var hint := Label.new()
	hint.text = "操作：WASD 移动 · 鼠标瞄准 · 左键射击 · R 换弹\n目标：找到「稳定核心」→ 带到传送门撤离 → 带回战利品"
	hint.add_theme_font_size_override("font_size", 16)
	hint.position = Vector2(60, 420)
	ui.add_child(hint)

	_refresh()


func _refresh() -> void:
	info_label.text = "仓库（保险箱）：废料 %d · 医疗包 %d · 备用弹药 %d" % [
		GameState.stash_scrap, GameState.stash_medkits, GameState.reserve_ammo]
	match GameState.last_result:
		"success":
			result_label.text = "上次撤离成功，战利品已入库。"
		"death":
			result_label.text = "上次死亡：本次战利品丢失，保险箱物品保留。"
		"timeout":
			result_label.text = "上次超时：侵蚀致死，战利品丢失。"
		_:
			result_label.text = ""


func _on_buy_pressed() -> void:
	GameState.reserve_ammo += 30
	_refresh()


func _on_go_pressed() -> void:
	GameState.reset_run()
	get_tree().change_scene_to_file("res://scenes/extraction.tscn")