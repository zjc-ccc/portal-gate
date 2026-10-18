class_name Bullet
extends Area2D
## 子弹：直线飞行，命中变异体造成伤害。


const SPEED := 900.0
const DAMAGE := 25.0

var dir: Vector2 = Vector2.RIGHT
var life: float = 1.5


func _ready() -> void:
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 4.0
	shape.shape = c
	add_child(shape)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)])
	vis.color = Color("ffd166")
	add_child(vis)

	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += dir * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(DAMAGE)
		queue_free()