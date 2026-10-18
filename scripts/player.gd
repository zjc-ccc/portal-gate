class_name Player
extends CharacterBody2D
## 玩家：WASD 移动 + 鼠标瞄准 + 左键射击 + R 换弹。


signal died

const SPEED := 260.0
const MAX_HP := 100.0
const MAG_SIZE := 12

var hp: float = MAX_HP
var mag: int = MAG_SIZE
var fire_cd: float = 0.0
var gun_pivot: Node2D
var controls_enabled: bool = true  # 搜索界面打开时冻结移动/射击


func _ready() -> void:
	add_to_group("player")

	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 14.0
	shape.shape = c
	add_child(shape)

	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)])
	body.color = Color("3a86ff")
	add_child(body)

	gun_pivot = Node2D.new()
	add_child(gun_pivot)
	var gun := Polygon2D.new()
	gun.polygon = PackedVector2Array([Vector2(6, -3), Vector2(26, 0), Vector2(6, 3)])
	gun.color = Color("ffbe0b")
	gun_pivot.add_child(gun)

	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	add_child(cam)
	cam.make_current()


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return

	fire_cd -= delta

	var aim := get_global_mouse_position() - global_position
	if aim.length() > 1.0:
		gun_pivot.rotation = aim.angle()

	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1
	velocity = dir.normalized() * SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, -1200.0, 1200.0)
	global_position.y = clampf(global_position.y, -680.0, 680.0)

	if Input.is_physical_key_pressed(KEY_R) and mag < MAG_SIZE:
		_try_reload()

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and fire_cd <= 0:
		if mag > 0:
			mag -= 1
			fire_cd = 0.15
			_shoot(aim.normalized())
		else:
			_try_reload()


func _try_reload() -> void:
	var need := MAG_SIZE - mag
	var take := mini(need, GameState.reserve_ammo)
	if take > 0:
		mag += take
		GameState.reserve_ammo -= take


func _shoot(dir: Vector2) -> void:
	var b := Bullet.new()
	b.dir = dir
	get_parent().add_child(b)
	b.global_position = global_position + dir * 26.0


func take_damage(d: float) -> void:
	hp -= d
	if hp <= 0:
		hp = 0
		died.emit()


func heal(a: float) -> void:
	hp = minf(hp + a, MAX_HP)