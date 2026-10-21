# -*- coding: utf-8 -*-
"""为 Portal-Gate 生成俯视角传送门像素图。

输出 128x128 RGBA 精灵(透明背景):
  - portal_cold_active.png  反世界·启动态
  - portal_cold_idle.png    反世界·待启动态
  - portal_warm_active.png  现实·启动态
  - portal_warm_idle.png    现实·待启动态
  - portal_preview.png      四合一预览图(3 倍放大)

同一套绘图逻辑,只换调色板/状态参数 —— 这就是脚本画图的优势。
"""
import math
import os
import random

from PIL import Image, ImageDraw, ImageFont

SIZE = 128
CX = CY = SIZE / 2.0
R_FRAME_IN = 40.0    # 石环内沿
R_FRAME_OUT = 52.0   # 石环外沿
R_GLOW = 63.0        # 底部光圈淡出半径
R_RIM = 3.0          # 内沿亮圈厚度

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "assets", "pixel")

# Bayer 4x4 抖动矩阵,做像素风渐变
BAYER4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
]


def bayer(x, y):
    return (BAYER4[y & 3][x & 3] + 0.5) / 16.0


def mix(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(3))


def ramp(colors, v):
    """把 [0,1) 的值映射到色阶列表中的一档。"""
    v = max(0.0, min(0.999, v))
    return colors[int(v * len(colors))]


# 冷色 = 反世界(灰紫 + 高饱和青),暖色 = 现实(琥珀)
COLD = {
    "frame_edge": (18, 20, 34),
    "frame_dark": (32, 34, 52),
    "frame_mid": (58, 63, 89),
    "frame_light": (86, 93, 124),
    "rim": (96, 244, 236),
    "rim_dim": (32, 140, 150),
    "vortex": [(10, 34, 48), (20, 84, 104), (42, 168, 184), (127, 244, 236)],
    "core": (215, 255, 252),
    "idle_floor": (15, 18, 32),
    "idle_dot": (30, 61, 74),
    "glow": (96, 244, 236),
}
WARM = {
    "frame_edge": (32, 24, 18),
    "frame_dark": (54, 41, 30),
    "frame_mid": (96, 73, 55),
    "frame_light": (132, 104, 78),
    "rim": (255, 190, 90),
    "rim_dim": (176, 108, 32),
    "vortex": [(48, 26, 12), (110, 62, 20), (204, 128, 44), (255, 218, 140)],
    "core": (255, 243, 214),
    "idle_floor": (32, 24, 15),
    "idle_dot": (92, 58, 30),
    "glow": (255, 190, 90),
}


def draw_portal(pal, active, seed):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    px = img.load()
    rng = random.Random(seed)

    for y in range(SIZE):
        for x in range(SIZE):
            dx = x + 0.5 - CX
            dy = y + 0.5 - CY
            r = math.hypot(dx, dy)
            if r >= R_GLOW:
                continue
            ang = math.atan2(dy, dx)
            color = None

            if r < R_FRAME_IN:
                if active:
                    if r >= R_FRAME_IN - R_RIM:
                        # 内沿亮圈,带角度闪烁感
                        v = 0.5 + 0.5 * math.sin(ang * 8.0)
                        if bayer(x, y) < 0.82:
                            color = mix(pal["rim_dim"], pal["rim"], v)
                        else:
                            color = mix(pal["vortex"][2], pal["rim_dim"], 0.5)
                    elif r < 9.0:
                        # 中心白炽核
                        color = pal["core"] if bayer(x, y) < 0.75 else pal["vortex"][3]
                    else:
                        # 螺旋涡流:3 条旋臂,越靠中心越亮
                        u = r / R_FRAME_IN
                        spiral = ang + 7.0 * (1.0 - u) ** 1.6
                        band = 0.5 + 0.5 * math.sin(spiral * 3.0)
                        val = band * 0.62 + (1.0 - u) * 0.45 + (bayer(x, y) - 0.5) * 0.16
                        color = ramp(pal["vortex"], val)
                else:
                    # 待启动:暗色池 + 微弱内沿
                    base = pal["idle_floor"]
                    if r >= R_FRAME_IN - R_RIM:
                        base = mix(base, pal["rim_dim"], 0.25)
                    jitter = max(0.0, (bayer(x, y) - 0.5)) * 0.10
                    color = mix(base, pal["frame_edge"], jitter)
            elif r < R_FRAME_OUT:
                # 石环:左上受光的明暗 + 抖动过渡
                t = (r - R_FRAME_IN) / (R_FRAME_OUT - R_FRAME_IN)
                shade = 0.5 + 0.5 * math.cos(ang + 2.356)  # 光源在左上
                v = shade * 0.65 + (1.0 - t) * 0.35 + (bayer(x, y) - 0.5) * 0.14
                levels = [pal["frame_edge"], pal["frame_dark"],
                          pal["frame_mid"], pal["frame_light"]]
                color = ramp(levels, v)
            else:
                # 底部光圈:向外的抖动淡出(启动亮 / 待机暗)
                t = (r - R_FRAME_OUT) / (R_GLOW - R_FRAME_OUT)
                strength = (1.0 - t) ** 1.5
                if not active:
                    strength *= 0.22
                level = max(0, min(5, int(strength * 6 + bayer(x, y))))
                a = (0, 40, 80, 130, 180, 225)[level]
                if a > 0:
                    color = pal["glow"] + (a,)

            if color is not None and len(color) == 3:
                color = color + (255,)
            if color is not None:
                px[x, y] = color

    # 石环上 8 颗铆钉
    for k in range(8):
        ba = k * math.pi / 4 + math.pi / 8
        bx = CX + math.cos(ba) * 46.0
        by = CY + math.sin(ba) * 46.0
        for oy in range(-3, 4):
            for ox in range(-3, 4):
                gx, gy = int(bx) + ox, int(by) + oy
                if 0 <= gx < SIZE and 0 <= gy < SIZE:
                    d = math.hypot(gx + 0.5 - bx, gy + 0.5 - by)
                    if d < 1.6:
                        px[gx, gy] = pal["frame_light"] + (255,)
                    elif d < 3.0:
                        px[gx, gy] = pal["frame_edge"] + (255,)

    if active:
        # 启动态:内部随机电火花
        for _ in range(30):
            sr = rng.uniform(4, R_FRAME_IN - 6)
            sa = rng.uniform(0, math.tau)
            sx = int(CX + math.cos(sa) * sr)
            sy = int(CY + math.sin(sa) * sr)
            if 0 <= sx < SIZE and 0 <= sy < SIZE:
                px[sx, sy] = pal["core"] + (255,)
                if rng.random() < 0.5:
                    ox, oy = rng.choice([(1, 0), (0, 1), (-1, 0), (0, -1)])
                    xx, yy = sx + ox, sy + oy
                    if 0 <= xx < SIZE and 0 <= yy < SIZE and \
                            math.hypot(xx + 0.5 - CX, yy + 0.5 - CY) < R_FRAME_IN - R_RIM:
                        px[xx, yy] = pal["rim"] + (255,)
    else:
        # 待机:内部暗尘 + 内沿几粒将熄的亮点
        for _ in range(46):
            sr = rng.uniform(0, R_FRAME_IN - 5)
            sa = rng.uniform(0, math.tau)
            sx = int(CX + math.cos(sa) * sr)
            sy = int(CY + math.sin(sa) * sr)
            if 0 <= sx < SIZE and 0 <= sy < SIZE:
                px[sx, sy] = pal["idle_dot"] + (255,)
        for _ in range(5):
            sa = rng.uniform(0, math.tau)
            rr = R_FRAME_IN - R_RIM / 2
            sx = int(CX + math.cos(sa) * rr)
            sy = int(CY + math.sin(sa) * rr)
            if 0 <= sx < SIZE and 0 <= sy < SIZE:
                px[sx, sy] = mix(pal["rim"], pal["rim_dim"], 0.4) + (255,)

    return img


def make_preview(images, names):
    """四合一预览图,3 倍最近邻放大。"""
    scale = 3
    cell = SIZE * scale
    pad = 16
    sheet = Image.new("RGBA", (cell * 2 + pad * 3, cell * 2 + pad * 3), (18, 18, 26, 255))
    pos = [(pad, pad), (pad * 2 + cell, pad),
           (pad, pad * 2 + cell), (pad * 2 + cell, pad * 2 + cell)]
    for im, p in zip(images, pos):
        sheet.alpha_composite(im.resize((cell, cell), Image.NEAREST), p)
    try:
        font = ImageFont.load_default(size=18)
    except TypeError:
        font = ImageFont.load_default()
    d = ImageDraw.Draw(sheet)
    for name, p in zip(names, pos):
        d.text((p[0] + 8, p[1] + 6), name, fill=(230, 230, 235, 255), font=font)
    return sheet


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    specs = [
        ("cold", COLD, True, 11),
        ("cold", COLD, False, 12),
        ("warm", WARM, True, 21),
        ("warm", WARM, False, 22),
    ]
    images, names = [], []
    for world, pal, active, seed in specs:
        im = draw_portal(pal, active, seed)
        state = "active" if active else "idle"
        name = "portal_{}_{}.png".format(world, state)
        im.save(os.path.join(OUT_DIR, name))
        images.append(im)
        names.append(name[:-4])
        print("saved", name)
    sheet = make_preview(images, names)
    sheet.save(os.path.join(OUT_DIR, "portal_preview.png"))
    print("saved portal_preview.png", sheet.size)


if __name__ == "__main__":
    main()
