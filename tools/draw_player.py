# -*- coding: utf-8 -*-
"""为 Portal-Gate 生成俯视角玩家角色像素图(白色上衣、黑色长裤)——写实版。

写实化要点:
  - 头肩比约 1:3(真实俯视比例),露出脖子与衣领
  - 腿为整条胶囊体,从胯下伸出迈步,黑裤有圆柱光影
  - 5 档细腻色阶 + 全局左上光源(统一光照模型,避免部件接缝)
  - 头部投影(AO)、布料褶皱、柔和深灰描边,降低卡通感

方案 = 素材规格清单推荐的「旋转式」MVP:
  只画 1 个朝向(朝上,-Y 为前进方向),转向交给 Godot 节点 rotation,
  可实现 360 度无级平滑转身;走路用 6 帧循环。

输出(assets/characters/player/):
  player_idle.png        待机 1 帧
  player_walk_0..5.png   走路 6 帧循环
  player_preview.png     帧总览(2 倍放大)
  player_preview.gif     动图预览
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

SIZE = 128
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "characters", "player")

BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def bayer(x, y):
    return (BAYER4[y & 3][x & 3] + 0.5) / 16.0


def ramp(colors, v):
    v = max(0.0, min(0.999, v))
    c = colors[int(v * len(colors))]
    return (c[0], c[1], c[2], 255)


# 调色板(5 档细腻色阶,左上受光)
OUTLINE = (34, 32, 38)
SHIRT_RAMP = [(242, 244, 246), (224, 227, 231), (203, 208, 215), (178, 185, 195), (152, 160, 173)]
COLLAR_RAMP = [(180, 186, 197), (168, 175, 187), (150, 157, 170)]
TROUSERS_RAMP = [(58, 58, 72), (49, 49, 62), (40, 40, 52), (31, 31, 41)]
SHOE = (26, 26, 34)
SHOE_TIP = (64, 62, 66)
SKIN_RAMP = [(242, 194, 156), (233, 178, 138), (212, 152, 114)]
HAIR_RAMP = [(108, 82, 60), (90, 66, 48), (72, 51, 37), (57, 40, 29)]

BODY_C = (64.0, 63.0)  # 全局光照中心


def light(x, y):
    """全局左上光源明度 [0,1],所有部件共用,避免接缝。"""
    ang = math.atan2(y + 0.5 - BODY_C[1], x + 0.5 - BODY_C[0])
    return 0.5 + 0.5 * math.cos(ang + 2.356)


def fill_ellipse(img, cx, cy, rx, ry, color_fn, dilate=0.0):
    px = img.load()
    x0 = max(0, int(math.floor(cx - rx - dilate)))
    x1 = min(SIZE - 1, int(math.ceil(cx + rx + dilate)))
    y0 = max(0, int(math.floor(cy - ry - dilate)))
    y1 = min(SIZE - 1, int(math.ceil(cy + ry + dilate)))
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            nx = (x + 0.5 - cx) / (rx + dilate)
            ny = (y + 0.5 - cy) / (ry + dilate)
            if nx * nx + ny * ny <= 1.0:
                px[x, y] = color_fn(x, y)


def fill_capsule(img, ax, ay, bx, by, r, color_fn, dilate=0.0):
    px = img.load()
    x0 = max(0, int(math.floor(min(ax, bx) - r - dilate)))
    x1 = min(SIZE - 1, int(math.ceil(max(ax, bx) + r + dilate)))
    y0 = max(0, int(math.floor(min(ay, by) - r - dilate)))
    y1 = min(SIZE - 1, int(math.ceil(max(ay, by) + r + dilate)))
    rr = r + dilate
    dx, dy = bx - ax, by - ay
    l2 = dx * dx + dy * dy
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            fx, fy = x + 0.5, y + 0.5
            if l2 == 0:
                t = 0.0
            else:
                t = ((fx - ax) * dx + (fy - ay) * dy) / l2
                t = max(0.0, min(1.0, t))
            if math.hypot(fx - (ax + t * dx), fy - (ay + t * dy)) <= rr:
                px[x, y] = color_fn(x, y)


def blend_ellipse(img, cx, cy, rx, ry, color, alpha):
    """把半透明色以 Bayer 抖动混合进已有像素(AO / 褶皱用)。"""
    px = img.load()
    x0 = max(0, int(math.floor(cx - rx)))
    x1 = min(SIZE - 1, int(math.ceil(cx + rx)))
    y0 = max(0, int(math.floor(cy - ry)))
    y1 = min(SIZE - 1, int(math.ceil(cy + ry)))
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            nx = (x + 0.5 - cx) / rx
            ny = (y + 0.5 - cy) / ry
            if nx * nx + ny * ny <= 1.0 and px[x, y][3] > 0 and bayer(x, y) < alpha:
                cur = px[x, y]
                px[x, y] = tuple(int(cur[i] + (color[i] - cur[i]) * 0.85) for i in range(3)) + (255,)


def outline_fn(x, y):
    return OUTLINE + (255,)


def paint_shapes(img, shapes, color_fn, dilate=0.0):
    """shapes: ("e", cx, cy, rx, ry) 或 ("c", ax, ay, bx, by, r)。
    先画全部 dilate 轮廓层,再画填充层,避免组合形状内部出现接缝线。"""
    for sp in shapes:
        if sp[0] == "e":
            fill_ellipse(img, sp[1], sp[2], sp[3], sp[4], outline_fn, dilate)
        else:
            fill_capsule(img, sp[1], sp[2], sp[3], sp[4], sp[5], outline_fn, dilate)
    for sp in shapes:
        if sp[0] == "e":
            fill_ellipse(img, sp[1], sp[2], sp[3], sp[4], color_fn)
        else:
            fill_capsule(img, sp[1], sp[2], sp[3], sp[4], sp[5], color_fn)


def draw_player(stride):
    """stride ∈ [-1,1]:+1 = 左脚在前(画面上方),-1 = 右脚在前。"""
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))

    def pants_fn(x, y):
        return ramp(TROUSERS_RAMP, light(x, y) * 0.55 + 0.22 + (bayer(x, y) - 0.5) * 0.14)

    def shirt_fn(x, y):
        return ramp(SHIRT_RAMP, light(x, y) * 0.8 + 0.1 + (bayer(x, y) - 0.5) * 0.12)

    # ---- 1. 腿(整条黑裤)+ 鞋,走路时从衣摆下明显迈出 ----
    for s in (-1, 1):
        spread = 10.0 + 3.5 * abs(stride)
        foot = (64 + s * spread, 76 + s * 26 * stride)
        hip = (64 + s * 7, 72)
        fill_capsule(img, hip[0], hip[1], foot[0], foot[1] - 4, 4.2, outline_fn, dilate=1.2)
        fill_capsule(img, hip[0], hip[1], foot[0], foot[1] - 4, 4.2, pants_fn)
        fill_ellipse(img, foot[0], foot[1], 5.2, 7.5, outline_fn, dilate=1.2)
        fill_ellipse(img, foot[0], foot[1], 5.2, 7.5, lambda x, y: SHOE + (255,))
        fill_ellipse(img, foot[0], foot[1] - 4.6, 3.0, 1.7,
                     lambda x, y: SHOE_TIP + (255,))

    # ---- 2. 裤腰(衣摆下露出的黑裤臀部) ----
    fill_ellipse(img, 64, 75.5, 14, 5.5, outline_fn, dilate=1.2)
    fill_ellipse(img, 64, 75.5, 14, 5.5, pants_fn)

    # ---- 3. 上衣:背板 + 双肩三角肌 + 斜方肌,组合成真实肩线 ----
    shirt_shapes = [
        ("e", 64, 65.5, 17, 10.5),            # 背板
        ("e", 64 - 16.5, 59.5, 7.2, 7.2),     # 左肩
        ("e", 64 + 16.5, 59.5, 7.2, 7.2),     # 右肩
        ("e", 64 - 7, 56.5, 6, 4.2),          # 左斜方肌
        ("e", 64 + 7, 56.5, 6, 4.2),          # 右斜方肌
    ]
    paint_shapes(img, shirt_shapes, shirt_fn, dilate=1.2)

    # 布料褶皱(抖动混合,很淡)
    blend_ellipse(img, 64 - 9, 67, 2.0, 6.5, (120, 128, 142), 0.5)
    blend_ellipse(img, 64 + 9, 67, 2.0, 6.5, (120, 128, 142), 0.5)
    blend_ellipse(img, 64 + 3, 71, 1.6, 4.5, (250, 251, 253), 0.45)
    # 衣摆落在裤子上的投影
    blend_ellipse(img, 64, 76.5, 13, 2.6, (12, 12, 18), 0.5)

    # ---- 4. 衣领 + 头部投影 + 脖子 ----
    def collar_fn(x, y):
        return ramp(COLLAR_RAMP, light(x, y) * 0.6 + 0.2)

    fill_ellipse(img, 64, 56.8, 5.8, 3.2, collar_fn)
    blend_ellipse(img, 64, 56.5, 7.5, 3.0, (60, 58, 66), 0.55)  # 头投在领口的 AO
    fill_ellipse(img, 64, 54.5, 3.4, 3.4, outline_fn, dilate=1.1)

    def skin_fn(x, y):
        return ramp(SKIN_RAMP, light(x, y) * 0.55 + 0.3)

    fill_ellipse(img, 64, 54.5, 3.4, 3.4, skin_fn)

    # ---- 5. 头:头发(抖动发际线)+ 前额 + 鼻尖 ----
    fill_ellipse(img, 64, 47.5, 7.5, 7.5, outline_fn, dilate=1.2)

    def hair_fn(x, y):
        if y + 0.5 < 43.6 + 1.6 * bayer(x, y):
            return ramp(SKIN_RAMP, light(x, y) * 0.5 + 0.35)
        return ramp(HAIR_RAMP, light(x, y) * 0.55 + 0.2 + (bayer(x, y) - 0.5) * 0.1)

    fill_ellipse(img, 64, 47.5, 7.5, 7.5, hair_fn)
    fill_ellipse(img, 64, 39.3, 1.8, 1.8, outline_fn, dilate=1.1)
    fill_ellipse(img, 64, 39.3, 1.8, 1.8,
                 lambda x, y: ramp(SKIN_RAMP, 0.45) if bayer(x, y) < 0.5 else ramp(SKIN_RAMP, 0.6))

    # ---- 6. 手臂:长袖 + 手,与同侧脚反相摆动,带肘部微曲 ----
    for s in (-1, 1):
        swing = -s * stride
        sh = (64 + s * 16.5, 59.5)
        elbow = (64 + s * 20.5, 67 + 3 * swing)
        wrist = (64 + s * 21.5, 74 + 9 * swing)
        hand = (64 + s * 22, 78 + 10 * swing)
        arm_shapes = [
            ("c", sh[0], sh[1], elbow[0], elbow[1], 4.3),
            ("c", elbow[0], elbow[1], wrist[0], wrist[1], 4.0),
        ]
        paint_shapes(img, arm_shapes, shirt_fn, dilate=1.2)
        fill_ellipse(img, hand[0], hand[1], 3.6, 3.6, outline_fn, dilate=1.1)
        fill_ellipse(img, hand[0], hand[1], 3.6, 3.6, skin_fn)

    return img


def on_bg(im, color=(56, 58, 68)):
    bg = Image.new("RGBA", im.size, color + (255,))
    bg.alpha_composite(im)
    return bg


def make_sheet(images, names):
    """4 列网格总览,2 倍最近邻放大。"""
    scale = 2
    cell = SIZE * scale
    pad = 12
    cols = 4
    rows = (len(images) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell + (cols + 1) * pad,
                               rows * (cell + 22) + (rows + 1) * pad),
                      (56, 58, 68, 255))
    try:
        font = ImageFont.load_default(size=16)
    except TypeError:
        font = ImageFont.load_default()
    d = ImageDraw.Draw(sheet)
    for i, (im, name) in enumerate(zip(images, names)):
        cx = pad + (i % cols) * (cell + pad)
        cy = pad + (i // cols) * (cell + 22 + pad)
        sheet.alpha_composite(im.resize((cell, cell), Image.NEAREST), (cx, cy))
        d.text((cx + 4, cy + cell + 4), name, fill=(28, 28, 34, 255), font=font)
    return sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    idle = draw_player(0.0)
    idle.save(os.path.join(OUT_DIR, "player_idle.png"))
    print("saved player_idle.png")

    walk = []
    for p in range(6):
        stride = math.sin(2.0 * math.pi * (p + 0.5) / 6.0)
        im = draw_player(stride)
        name = "player_walk_{}.png".format(p)
        im.save(os.path.join(OUT_DIR, name))
        walk.append(im)
        print("saved", name)

    names = ["idle"] + ["walk_{}".format(p) for p in range(6)]
    sheet = make_sheet([idle] + walk, names)
    sheet.save(os.path.join(OUT_DIR, "player_preview.png"))
    print("saved player_preview.png", sheet.size)

    # 动图预览:待机 0.4s + 走路 6 帧
    frames = [on_bg(idle)] + [on_bg(f) for f in walk]
    frames[0].save(os.path.join(OUT_DIR, "player_preview.gif"),
                   save_all=True, append_images=frames[1:],
                   duration=[400] + [110] * 6, loop=0)
    print("saved player_preview.gif")


if __name__ == "__main__":
    main()
