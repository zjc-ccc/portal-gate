class_name Enemy
extends CharacterBody2D
## 变异体：追踪玩家，靠近后周期性造成伤害。


signal died(enemy: Enemy)

const SPEED := 130.0

var hp: float = 50.0
var damage: float = 10.0
var attack_cd: float = 0.0
var player: Player


func _ready() -> void:
	add_to_group("enemy")

	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	shape.shape = c
	add_child(shape)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-14, -10), Vector2(0, -14), Vector2(14, -10),
		Vector2(14, 10), Vector2(0, 14), Vector2(-14, 10)])
	vis.color = Color("e63946")
	add_child(vis)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	var to := player.global_position - global_position
	if to.length() > 4.0:
		velocity = to.normalized() * SPEED
		move_and_slide()

	attack_cd -= delta
	if to.length() < 32.0 and attack_cd <= 0.0:
		attack_cd = 0.7
		player.take_damage(damage)


func take_damage(d: float) -> void:
	hp -= d
	if hp <= 0:
		died.emit(self)
		queue_free()