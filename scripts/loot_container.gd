class_name LootContainer
extends StaticBody2D
## 可搜索容器（箱子）：有碰撞阻挡；持有物品列表，物品按单局持久逐步显现。


var loot: Array = []            # 物品 id 列表
var reveal_progress: Array = [] # 每格显现进度 0~1（单局内持久）


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(44, 44)
	shape.shape = rect
	add_child(shape)

	for _i in loot.size():
		reveal_progress.append(0.0)

	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-22, -22, 44, 44), Color(0.55, 0.40, 0.20))
	draw_rect(Rect2(-22, -22, 44, 44), Color(0.82, 0.64, 0.36), false, 3.0)