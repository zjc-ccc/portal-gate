extends Node
## 全局风：统一驱动所有树的摆动。风速 / 风向 / 摆幅 / 世界调色板都可全局调整。
## 具体写入 shader 的全局参数（见 project.godot 的 [shader_globals]），所有树共用同一份值。

var speed: float = 1.0                       # 风速倍率：0 = 静止，越大摆得越快
var strength: float = 1.0                    # 摆幅倍率：0 = 无风
var direction: Vector2 = Vector2(1.0, 0.0)    # 风向
var palette_dark: Color = Color(0.13, 0.32, 0.16)   # 调色板·暗部（默认现实暖绿）
var palette_light: Color = Color(0.47, 0.79, 0.36)  # 调色板·亮部
var time: float = 0.0                        # 累计风相位（秒）

var _dir_dirty: bool = true


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	time += delta * speed   # 连续累积 → 摆动永不跳帧，改风速也不会突跳
	_apply()


func set_direction(d: Vector2) -> void:
	direction = d
	_dir_dirty = true


func set_palette(dark: Color, light: Color) -> void:
	palette_dark = dark
	palette_light = light


func _apply() -> void:
	RenderingServer.global_shader_parameter_set("wind_time", time)
	RenderingServer.global_shader_parameter_set("wind_strength", strength)
	if _dir_dirty:
		RenderingServer.global_shader_parameter_set("wind_dir", direction.normalized())
		_dir_dirty = false
	RenderingServer.global_shader_parameter_set("palette_dark", palette_dark)
	RenderingServer.global_shader_parameter_set("palette_light", palette_light)
