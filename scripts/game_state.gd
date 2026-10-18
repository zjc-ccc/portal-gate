extends Node
## 跨场景持久状态：现实（家园）与反世界之间共享。


# —— 保险箱 / 仓库：现实中安全存量的东西，撤离成功或死亡都保留 ——
var stash_scrap: int = 0      # 已安全入库的废料
var stash_medkits: int = 0    # 已安全入库的医疗包
var reserve_ammo: int = 60    # 备用弹药（在现实世界购买）

# —— 本次运行（反世界内）背包里的物品 id 列表（临时，撤离成功才并入仓库） ——
var backpack: Array = []

# —— 上一次运行结果，用于家园提示 ——
var last_result: String = ""  # "success" / "death" / "timeout"


func reset_run() -> void:
	backpack = []


func add_to_backpack(item_id: String) -> void:
	backpack.append(item_id)


func commit_run() -> void:
	# 撤离成功：背包物品入库
	for it in backpack:
		match it:
			"scrap":
				stash_scrap += 1
			"medkit":
				stash_medkits += 1
			"ammo":
				reserve_ammo += 8
	backpack = []


func lose_run() -> void:
	# 死亡 / 超时：本次背包装备丢失，仓库（保险箱）保留
	backpack = []