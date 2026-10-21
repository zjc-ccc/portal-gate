class_name ForestTree
extends Node2D
## 俯视树：树冠 + 树影两张静态图，共用同一 shader，靠全局风参数（Wind）摆动。
## 每棵树不设自己的相位——shader 用世界坐标做种子，一片树林自动错落。

const CANOPY_TEXTURE := "res://assets/props/tree_warm_top.png"
const SHADOW_TEXTURE := "res://assets/props/tree_shadow.png"
const TREE_SCALE := 2.0   # 64px 素材 ×2 → 与 128px 角色同尺度（整数倍，像素不糊）

# 树冠 / 树影各自一份"共享"材质：所有树复用同一实例，改一次即全局生效
static var _canopy_material: ShaderMaterial
static var _shadow_material: ShaderMaterial


static func _ensure_materials() -> void:
	if _canopy_material != null:
		return
	var shader: Shader = load("res://shaders/tree_sway.gdshader")

	_canopy_material = ShaderMaterial.new()
	_canopy_material.shader = shader
	_canopy_material.set_shader_parameter("sway_px", 3.2)
	_canopy_material.set_shader_parameter("phase_offset", 0.0)
	_canopy_material.set_shader_parameter("drop_alpha", 1.0)
	_canopy_material.set_shader_parameter("recolor", true)   # 树冠随世界调色板换色

	_shadow_material = ShaderMaterial.new()
	_shadow_material.shader = shader
	_shadow_material.set_shader_parameter("sway_px", 2.0)
	_shadow_material.set_shader_parameter("phase_offset", -1.1)   # 树影滞后于树冠
	_shadow_material.set_shader_parameter("drop_alpha", 0.9)
	_shadow_material.set_shader_parameter("recolor", false)


func _ready() -> void:
	ForestTree._ensure_materials()

	var shadow := Sprite2D.new()
	shadow.texture = load(SHADOW_TEXTURE)
	shadow.material = ForestTree._shadow_material
	shadow.scale = Vector2(TREE_SCALE, TREE_SCALE)
	shadow.position = Vector2(10.0, 16.0)   # 略偏移，做出日照投影
	shadow.z_index = 0
	add_child(shadow)

	var canopy := Sprite2D.new()
	canopy.texture = load(CANOPY_TEXTURE)
	canopy.material = ForestTree._canopy_material
	canopy.scale = Vector2(TREE_SCALE, TREE_SCALE)
	canopy.z_index = 5   # 树冠盖在角色之上（俯视穿林感）
	add_child(canopy)
