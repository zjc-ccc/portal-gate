class_name MedkitItem
extends Node2D
## 医疗包：走到附近自动拾取，回复生命并计入本次战利品。


func _ready() -> void:
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])
	vis.color = Color("ff5d8f")
	add_child(vis)
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([
		Vector2(-2, -8), Vector2(2, -8), Vector2(2, 8), Vector2(-2, 8)])
	mark.color = Color.WHITE
	add_child(mark)


func _physics_process(_delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as Player
	if p == null:
		return
	if global_position.distance_to(p.global_position) < 30.0:
		p.heal(30.0)
		GameState.add_to_backpack("medkit")
		queue_free()