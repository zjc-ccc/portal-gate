extends Node2D
## 反世界场景总控：搭建世界、生成敌人、搜索容器、倒计时、撤离判定与结算。


var player: Player
var portal: Portal
var artifact: ExtractItem
var search_ui: SearchUI
var enemies: Array[Enemy] = []
var containers: Array[LootContainer] = []

var time_left: float = 180.0   # 侵蚀倒计时
var has_artifact: bool = false
var evacuate_left: float = 0.0
var phase: String = "active"   # active / evacuating

var hp_label: Label
var ammo_label: Label
var loot_label: Label
var time_label: Label
var msg_label: Label
var prompt_label: Label


func _ready() -> void:
	_build_world()
	_build_hud()
	_spawn_enemies()
	_spawn_containers()

	search_ui = SearchUI.new()
	add_child(search_ui)

	msg_label.text = "目标：搜索容器获取物资 → 找到「稳定核心」→ 带到传送门撤离。"


const WORLD_HALF_W := 1500.0   # 地图半宽（世界单位）
const WORLD_HALF_H := 900.0    # 地图半高
const GROUND_TILE := 480.0     # 每块地面贴图显示尺寸


func _build_world() -> void:
	_build_ground()

	player = Player.new()
	player.position = Vector2.ZERO
	add_child(player)
	player.died.connect(_on_player_died)

	portal = Portal.new()
	portal.position = Vector2(900, 500)
	add_child(portal)

	artifact = ExtractItem.new()
	artifact.position = Vector2(-700, -400)
	add_child(artifact)


func _build_ground() -> void:
	# 用一张可平铺的地面贴图，铺满整张地图。简单、可复用，方便以后换素材。
	var tex := load("res://assets/antiworld_ground_tile.jpg") as Texture2D
	if tex == null:
		return
	var g := Sprite2D.new()
	g.texture = tex
	g.centered = false           # 从左上角开始铺
	g.z_index = -10
	g.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	g.region_enabled = true
	var s: float = GROUND_TILE / tex.get_width()   # 把贴图缩到指定世界尺寸
	g.scale = Vector2(s, s)
	g.position = Vector2(-WORLD_HALF_W, -WORLD_HALF_H)
	g.region_rect = Rect2(0, 0, (WORLD_HALF_W * 2.0) / s, (WORLD_HALF_H * 2.0) / s)
	add_child(g)


func _spawn_enemies() -> void:
	var spots := [
		Vector2(-500, 500), Vector2(500, 450), Vector2(-300, -500),
		Vector2(700, -300), Vector2(0, 550)]
	for s in spots:
		var e := Enemy.new()
		e.position = s
		add_child(e)
		e.player = player
		e.died.connect(_on_enemy_died)
		enemies.append(e)


func _spawn_containers() -> void:
	var defs := [
		[Vector2(-300, -200), ["scrap", "scrap", "medkit"]],
		[Vector2(400, 300), ["ammo", "parts", "cloth", "scrap"]],
		[Vector2(-600, 400), ["medkit", "medkit"]],
		[Vector2(600, -200), ["parts", "cloth", "scrap", "scrap", "ammo"]],
	]
	for d in defs:
		var c := LootContainer.new()
		c.loot = d[1]
		c.position = d[0]
		add_child(c)
		containers.append(c)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hp_label = _mk_label(layer, Vector2(20, 20), 24, Color.WHITE)
	ammo_label = _mk_label(layer, Vector2(20, 50), 24, Color.WHITE)
	loot_label = _mk_label(layer, Vector2(20, 80), 24, Color.WHITE)
	time_label = _mk_label(layer, Vector2(20, 110), 26, Color("ffd166"))
	msg_label = _mk_label(layer, Vector2(20, 160), 20, Color("9ef01a"))
	prompt_label = _mk_label(layer, Vector2(20, 200), 20, Color("80ed99"))


func _mk_label(p: Node, pos: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.modulate = col
	p.add_child(l)
	return l


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			if not search_ui.visible:
				var c := _nearest_container()
				if c != null:
					_open_search(c)
		elif event.keycode == KEY_ESCAPE:
			if search_ui.visible:
				_close_search()


func _nearest_container() -> LootContainer:
	var best: LootContainer = null
	var best_d := 80.0
	for c in containers:
		var d := player.global_position.distance_to(c.global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func _open_search(c: LootContainer) -> void:
	search_ui.open(c)
	player.controls_enabled = false
	prompt_label.text = ""


func _close_search() -> void:
	search_ui.close()
	player.controls_enabled = true


func _physics_process(delta: float) -> void:
	if phase == "active":
		time_left -= delta
		if time_left <= 0.0:
			_finish("timeout")
			return
	elif phase == "evacuating":
		evacuate_left -= delta
		if evacuate_left <= 0.0:
			_finish("success")
			return
		if player.global_position.distance_to(portal.global_position) > 90.0:
			phase = "active"
			portal.active = false
			msg_label.text = "撤离中断，请留在传送门范围内。"

	if phase == "active" and has_artifact \
			and player.global_position.distance_to(portal.global_position) < 90.0:
		phase = "evacuating"
		evacuate_left = 6.0
		portal.active = true
		msg_label.text = "传送门启动，撤离中... 请留在光圈内。"

	_update_hud()


func on_artifact_picked() -> void:
	has_artifact = true
	msg_label.text = "已获得启动物「稳定核心」→ 前往传送门撤离。"


func _on_enemy_died(e: Enemy) -> void:
	enemies.erase(e)
	var s := ScrapItem.new()
	s.position = e.global_position
	add_child(s)


func _on_player_died() -> void:
	_finish("death")


func _update_hud() -> void:
	hp_label.text = "生命：%d" % int(player.hp)
	ammo_label.text = "弹药：%d / 备用 %d" % [player.mag, GameState.reserve_ammo]
	loot_label.text = "背包：%d 件" % GameState.backpack.size()
	if phase == "evacuating":
		time_label.text = "撤离中：%.1f" % evacuate_left
	else:
		time_label.text = "侵蚀倒计时：%d" % int(time_left)
	if not search_ui.visible:
		prompt_label.text = "按 F 搜索容器" if _nearest_container() != null else ""


func _finish(result: String) -> void:
	if result == "success":
		GameState.commit_run()
		GameState.last_result = "success"
	elif result == "death":
		GameState.lose_run()
		GameState.last_result = "death"
	else:
		GameState.lose_run()
		GameState.last_result = "timeout"
	get_tree().change_scene_to_file("res://scenes/home.tscn")