class_name Portal
extends Node2D
## 传送门（撤离点）：待启动 / 已启动 两种视觉。


var active: bool = false
var _pulse: float = 0.0


func _process(delta: float) -> void:
	_pulse += delta * 4.0
	queue_redraw()


func _draw() -> void:
	var r := 60.0 + sin(_pulse) * 5.0
	draw_circle(Vector2.ZERO, r, Color(0.08, 0.1, 0.2, 0.4))
	var c := Color(0.2, 1.0, 0.5) if active else Color(0.4, 0.55, 1.0)
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, c, 5.0)
	draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 48, Color(c.r, c.g, c.b, 0.6), 3.0)