class_name ExtractItem
extends Node2D
## 启动物「稳定核心」：走到附近自动拾取，触发撤离许可。


func _ready() -> void:
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(18, 0), Vector2(0, 18), Vector2(-18, 0)])
	vis.color = Color("ffd60a")
	add_child(vis)


func _physics_process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	if global_position.distance_to(p.global_position) < 34.0:
		get_parent().on_artifact_picked()
		queue_free()