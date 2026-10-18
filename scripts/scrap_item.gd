class_name ScrapItem
extends Node2D
## 废料（战利品）：走到附近自动拾取，计入本次运行战利品。


func _ready() -> void:
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-7, -7), Vector2(7, -7), Vector2(7, 7), Vector2(-7, 7)])
	vis.color = Color("ffd166")
	add_child(vis)


func _physics_process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	if global_position.distance_to(p.global_position) < 26.0:
		GameState.add_to_backpack("scrap")
		queue_free()