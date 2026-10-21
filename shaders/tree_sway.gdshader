shader_type canvas_item;
// 俯视树摆动：树冠 / 树影两张静态图 + 本 shader。
// 所有树共用本 shader；每棵树以世界坐标为相位种子，一片树林自然错落。
// 驱动来自全局参数（项目设置 shader_globals），由 Wind 单例每帧统一写入。

// —— 全局风参数（全局可调） ——
global uniform float wind_time;     // 累计风相位（秒），由 Wind 推进 → 摆动连续、无限帧
global uniform float wind_strength; // 风速 / 摆幅倍率，0 = 无风静止
global uniform vec2 wind_dir;       // 风向（单位向量）
global uniform vec4 palette_dark;   // 世界调色板·暗部（现实暖 / 反世界冷）
global uniform vec4 palette_light;  // 世界调色板·亮部

// —— 图层参数（材质级，树冠与树影各一份共享材质） ——
uniform float sway_px = 1.8;        // 基础摆幅（纹理像素；随节点 scale 等比放大）
uniform float phase_offset = 0.0;   // 相位偏移（让树影滞后于树冠）
uniform float drop_alpha = 1.0;     // 透明度（削淡树影用）
uniform bool recolor = false;       // 是否按亮度重映射到世界调色板（冷色版复用）

void vertex() {
	// 世界坐标做相位种子：无需逐棵设参，树林自动错落
	vec2 wp = MODEL_MATRIX[3].xy;
	float seed = wp.x * 0.009 + wp.y * 0.013 + phase_offset;

	// 主摆动 + 叶丛高频抖动
	float main = sin(wind_time * 1.15 + seed);
	float leaf = sin(wind_time * 2.7 + seed * 1.7 + UV.x * 7.0 + UV.y * 5.0);

	// 越靠上摆得越多、底部锚定，得到"生根"感
	float up = clamp(1.0 - UV.y, 0.0, 1.0);
	float amp = sway_px * wind_strength * (0.35 + 0.65 * up);

	VERTEX += wind_dir * (main + 0.35 * leaf) * amp;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR; // COLOR 已含节点 modulate
	vec3 rgb = tex.rgb;
	if (recolor) {
		// 按亮度在两色之间重映射 = 换调色板（反世界冷色版复用同一张贴图）
		float lum = dot(rgb, vec3(0.299, 0.587, 0.114));
		rgb = mix(palette_dark.rgb, palette_light.rgb, lum);
	}
	COLOR = vec4(rgb, tex.a * drop_alpha);
}
