# GameManager.gd
# 游戏核心状态：数值/事件/契约度/堕落值等
# 维护人：王码
# 版本：v0.1（D2 骨架）

extends Node

signal hp_changed(val: int)
signal mp_changed(val: int)
signal contract_changed(val: int)
signal corruption_changed(val: int)
signal affection_changed(char_id: String, val: int)

# 主角数值（初始）
var hp: int = 100
var max_hp: int = 100
var mp: int = 50
var max_mp: int = 50
var atk: int = 20
var def: int = 15
var agi: int = 25
var level: int = 1
var xp: int = 0
var gold: int = 0
var corruption: int = 0   # 堕落值 0-100

# 契约度与好感度（每个女主独立）
var contract: Dictionary = {}
var affection: Dictionary = {}

# 5 位女主 ID（全小写，与事件系统/事件文件路径对齐）
# 版本 v0.2 起统一小写，旧代码若用 "Artesia" 需迁移
const HEROINES: Array = ["artesia", "marina", "mei", "rushena", "meido"]

# 显示用名称映射（UI/对白用）
const HEROINE_NAMES: Dictionary = {
	"artesia": "Artesia",
	"marina": "Marina",
	"mei": "Mei",
	"rushena": "Rushena",
	"meido": "Meido",
}

# 女主中文标签（存档摘要/UI 用）
const HEROINE_LABELS_ZH: Dictionary = {
	"artesia": "Artesia（契约女仆）",
	"marina": "Marina（人鱼）",
	"mei": "Mei（混血吸血鬼）",
	"rushena": "Rushena（魅魔）",
	"meido": "Meido（最终 BOSS 转化）",
}

func _ready() -> void:
	for h in HEROINES:
		contract[h] = 0
		affection[h] = 0
	print("[GameManager] init ok")

# 复位所有主角数值（单测/新游戏用）
func reset_state() -> void:
	hp = 100
	max_hp = 100
	mp = 50
	max_mp = 50
	atk = 20
	def = 15
	agi = 25
	level = 1
	xp = 0
	gold = 0
	corruption = 0
	flags.clear()
	for h in HEROINES:
		contract[h] = 0
		affection[h] = 0

func set_hp(v: int) -> void:
	hp = clampi(v, 0, max_hp)
	hp_changed.emit(hp)

func set_mp(v: int) -> void:
	mp = clampi(v, 0, max_mp)
	mp_changed.emit(mp)

func add_corruption(v: int) -> void:
	corruption = clampi(corruption + v, 0, 100)
	corruption_changed.emit(corruption)

# 通用数值增量接口（含 clamp 兜底，Sprint 2 D4 王码）
# key: "atk" / "def" / "agi" / "corruption" / "hp" / "mp" / 契约度/好感度需要走独立接口
# 返回最终值（便于测试断言）
func add_stat(key: String, delta: int) -> int:
	var max_val: int = -1
	var min_val: int = 0
	match key:
		"atk":
			max_val = 60
		"def":
			max_val = 60
		"agi":
			max_val = 60
		"corruption":
			max_val = 100
		"hp":
			max_val = max_hp
			min_val = 0
		"mp":
			max_val = max_mp
			min_val = 0
		_:
			push_warning("[GameManager] unknown stat key: %s" % key)
			return 0
	if max_val < 0:
		return 0
	var old: int = 0
	var new_val: int = 0
	if key == "atk":
		old = atk; atk = clampi(atk + delta, min_val, max_val); new_val = atk
	elif key == "def":
		old = def; def = clampi(def + delta, min_val, max_val); new_val = def
	elif key == "agi":
		old = agi; agi = clampi(agi + delta, min_val, max_val); new_val = agi
	elif key == "corruption":
		old = corruption; new_val = add_corruption(delta); new_val = corruption
	elif key == "hp":
		old = hp; new_val = set_hp(hp + delta); new_val = hp
	elif key == "mp":
		old = mp; new_val = set_mp(mp + delta); new_val = mp
	# clamp 生效日志（三方核对 R-022）
	if new_val != old + delta:
		print("[GameManager] clamp: %s %d+%d=%d" % [key, old, delta, new_val])
	return new_val

func add_affection(char_id: String, v: int) -> void:
	if affection.has(char_id):
		affection[char_id] = clampi(affection[char_id] + v, 0, 100)
		affection_changed.emit(char_id, affection[char_id])

func add_contract(char_id: String, v: int) -> void:
	if contract.has(char_id):
		contract[char_id] = clampi(contract[char_id] + v, 0, 100)
		contract_changed.emit(contract[char_id])

func is_fallen() -> bool:
	return corruption >= 100

# 判断某女主契约度是否达 100（结局条件）
func is_char_concluded(char_id: String) -> bool:
	return contract.get(char_id, 0) >= 100

# 结局判定（优先级：完全堕落 > 契约结局 > 中立 > 英雄）
# 返回值约定：
#   "fallen"    堕落值 >= 100（完全堕落结局）
#   "art"       Artesia 契约结局（堕落值 >= 70 + Artesia 契约 100）
#   "marina"    深渊结局
#   "mei"       永夜结局
#   "rushena"   恶魔结局（阈值 >= 80）
#   "meido"     堕落契约结局（阈值 >= 80）
#   "neutral"   中立结局（堕落值 50-69，无女主契约满）
#   "hero"      英雄结局（堕落值 < 50，无女主契约满）
#   ""          尚未达任何结局条件
func check_ending_condition() -> String:
	# 1. 完全堕落（P0 特殊结局，最高优先）
	if corruption >= 100:
		return "fallen"
	# 2. 契约结局（按女主 ID 遍历，注意用小写 id）
	if corruption >= 80 and is_char_concluded("meido"):
		return "meido"
	if corruption >= 80 and is_char_concluded("rushena"):
		return "rushena"
	if corruption >= 70 and is_char_concluded("artesia"):
		return "art"
	if corruption >= 70 and is_char_concluded("marina"):
		return "marina"
	if corruption >= 70 and is_char_concluded("mei"):
		return "mei"
	# 3. 中立结局
	if corruption >= 50:
		return "neutral"
	# 4. 英雄结局
	return "hero"

# 判断是否触发过任一结局（供 UI 决定是否进入结局演出）
func is_ending_triggered() -> bool:
	return check_ending_condition() != ""

# 剧情标志位（如"art_contract_signed"等，李游数值设计第八章）
var flags: Dictionary = {}

# 设置剧情标志位
func set_flag(key: String, value = true) -> void:
	flags[key] = value

func get_flag(key: String, default = false):
	return flags.get(key, default)

func has_flag(key: String) -> bool:
	return flags.has(key)

func to_dict() -> Dictionary:
	return {
		"hp": hp, "max_hp": max_hp, "mp": mp, "max_mp": max_mp,
		"atk": atk, "def": def, "agi": agi,
		"level": level, "xp": xp, "gold": gold, "corruption": corruption,
		"contract": contract.duplicate(true),
		"affection": affection.duplicate(true),
		"flags": flags.duplicate(true),
	}

func from_dict(d: Dictionary) -> void:
	if d.has("hp"): hp = d.hp
	if d.has("mp"): mp = d.mp
	if d.has("corruption"): corruption = d.corruption
	if d.has("contract"): contract = d.contract
	if d.has("affection"): affection = d.affection
	if d.has("flags"): flags = d.flags
	# 补齐缺失女主（旧档兼容）
	for h in HEROINES:
		if not contract.has(h):
			contract[h] = 0
		if not affection.has(h):
			affection[h] = 0