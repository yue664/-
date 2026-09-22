# EventManager.gd
# 事件系统框架：H 事件注册/触发判定/幂等锁/结局判定
# 维护人：王码
# 版本：v0.1（Sprint 0 D5）
# 关联：R-009 溢出保护、R-010 事件幂等性、李游数值设计 v0.1
#
# 使用：
#   auto_load EventManager
#   EventManager.register_event("H-ART-001", {...})
#   if EventManager.check_event_trigger("H-ART-001"):
#       EventManager.mark_event_triggered("H-ART-001")
#       # 播放事件
#
# 事件元数据结构（与 assets/events/*/meta.json 对齐）：
#   {
#     "char_id": "artesia",
#     "contract_min": 0,
#     "affection_min": 50,
#     "corruption_min": 0,
#     "contract_delta": 25,
#     "corruption_delta": 10,
#     "tier": "T0",
#     "unlocks": ["H-ART-002"]
#   }

extends Node

signal event_registered(event_id: String)
signal event_triggered(event_id: String)
signal event_available(event_id: String)

const AUTOLOAD_PATH := "res://assets/events/"

# 事件注册表：event_id -> meta
var EVENT_REGISTRY: Dictionary = {}
# 已触发事件（幂等锁）：event_id -> true
var EVENT_STATE: Dictionary = {}
# 已解锁事件池：event_id -> true（未触发的可候选）
var EVENT_UNLOCKED: Dictionary = {}

func _ready() -> void:
	# 默认注册 25 事件（从数值设计阈值表硬编码，后续可改为运行时从 meta.json 加载）
	_register_builtin_events()
	print("[EventManager] init, registered ", EVENT_REGISTRY.size(), " events")

# ==================== 事件注册 ====================

func register_event(event_id: String, meta: Dictionary) -> void:
	if EVENT_REGISTRY.has(event_id):
		push_warning("[EventManager] event re-registered: ", event_id)
		return
	# 补齐默认字段，避免策划漏填
	var norm := {
		"char_id": meta.get("char_id", ""),
		"contract_min": int(meta.get("contract_min", 0)),
		"affection_min": int(meta.get("affection_min", 0)),
		"corruption_min": int(meta.get("corruption_min", 0)),
		"contract_delta": int(meta.get("contract_delta", 0)),
		"corruption_delta": int(meta.get("corruption_delta", 0)),
		"affection_delta": int(meta.get("affection_delta", 0)),
		"tier": meta.get("tier", "T1"),
		"unlocks": meta.get("unlocks", []),
		"permanent_close": bool(meta.get("permanent_close", false)),
	}
	EVENT_REGISTRY[event_id] = norm
	event_registered.emit(event_id)

func _register_builtin_events() -> void:
	# 李游阈值表 25 事件，此处硬编码避免启动时读文件阻塞
	_register_batch([
		["H-ART-001", "artesia", 0,  50, 0,  25, 10, 0, "T0", []],
		["H-ART-002", "artesia", 25, 60, 5,  20, 5,  0, "T1", []],
		["H-ART-003", "artesia", 45, 70, 15, 20, 10, 0, "T1", []],
		["H-ART-004", "artesia", 0,  10, 0,  5,  0,  0, "T2", []],
		["H-ART-005", "artesia", 70, 80, 40, 30, 30, 0, "T0", []],
		["H-MA-001",  "marina",  0,  50, 10, 25, 10, 0, "T0", []],
		["H-MA-002",  "marina",  25, 60, 15, 20, 5,  0, "T1", []],
		["H-MA-003",  "marina",  45, 70, 20, 20, 10, 0, "T1", []],
		["H-MA-004",  "marina",  0,  10, 0,  5,  0,  0, "T2", []],
		["H-MA-005",  "marina",  70, 80, 40, 30, 30, 0, "T0", []],
		["H-MEI-001", "mei",     0,  50, 15, 25, 10, 0, "T0", []],
		["H-MEI-002", "mei",     25, 60, 20, 20, 5,  0, "T1", []],
		["H-MEI-003", "mei",     45, 70, 25, 20, 10, 0, "T1", []],
		["H-MEI-004", "mei",     0,  10, 0,  5,  0,  0, "T2", []],
		["H-MEI-005", "mei",     70, 80, 45, 30, 30, 0, "T0", []],
		["H-RU-001",  "rushena", 0,  50, 20, 25, 10, 0, "T0", []],
		["H-RU-002",  "rushena", 25, 60, 25, 20, 5,  0, "T1", []],
		["H-RU-003",  "rushena", 45, 70, 30, 20, 10, 0, "T1", []],
		["H-RU-004",  "rushena", 0,  10, 0,  5,  0,  0, "T2", []],
		["H-RU-005",  "rushena", 70, 80, 50, 30, 30, 0, "T0", []],
		["H-MID-001", "meido",   0,  0,  30, 25, 15, 0, "T0", []],
		["H-MID-002", "meido",   25, 40, 35, 20, 5,  0, "T1", []],
		["H-MID-003", "meido",   45, 60, 45, 20, 10, 0, "T1", []],
		["H-MID-004", "meido",   0,  10, 30, 5,  0,  0, "T2", []],
		["H-MID-005", "meido",   70, 80, 60, 30, 40, 0, "T0", []],
	])

func _register_batch(batch: Array) -> void:
	for row in batch:
		var id := row[0]
		register_event(id, {
			"char_id": row[1],
			"contract_min": row[2],
			"affection_min": row[3],
			"corruption_min": row[4],
			"contract_delta": row[5],
			"corruption_delta": row[6],
			"affection_delta": row[7],
			"tier": row[8],
			"unlocks": row[9],
		})

# 从 meta.json 加载事件（运行时用，供 H-ART-001 标杆事件测试）
func load_event_from_json(event_id: String) -> bool:
	var path := AUTOLOAD_PATH + event_id.to_lower() + "/" + event_id.to_lower().split("-")[1] + "/" + event_id + "/meta.json"
	if not FileAccess.file_exists(path):
		# fallback 到已知的 artesia 目录（H-ART-001 已落地）
		path = "res://assets/events/artesia/H-ART-001/meta.json"
	if not FileAccess.file_exists(path):
		push_warning("[EventManager] meta.json not found: ", event_id)
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("[EventManager] JSON parse fail: ", event_id)
		return false
	register_event(event_id, parsed)
	return true

# ==================== 触发判定 ====================

func is_event_registered(event_id: String) -> bool:
	return EVENT_REGISTRY.has(event_id)

func get_event_meta(event_id: String) -> Dictionary:
	return EVENT_REGISTRY.get(event_id, {})

func is_triggered(event_id: String) -> bool:
	return EVENT_STATE.has(event_id)

func is_unlocked(event_id: String) -> bool:
	return EVENT_UNLOCKED.has(event_id)

# 检查是否可触发（阈值达标 + 未触发过）
func check_event_trigger(event_id: String) -> bool:
	if not EVENT_REGISTRY.has(event_id):
		return false
	if EVENT_STATE.has(event_id):
		return false
	var e := EVENT_REGISTRY[event_id]
	var gm := _game_manager()
	if gm == null:
		return false
	var char_contract := gm.contract.get(e.char_id, 0)
	var char_affection := gm.affection.get(e.char_id, 0)
	return (
		char_contract >= e.contract_min and
		char_affection >= e.affection_min and
		gm.corruption >= e.corruption_min
	)

# 触发事件（应用数值 + 幂等锁 + 解锁下游）
func trigger_event(event_id: String, choice_index: int = -1) -> bool:
	if not check_event_trigger(event_id):
		push_warning("[EventManager] cannot trigger (condition fail): ", event_id)
		return false
	if EVENT_STATE.has(event_id):
		push_warning("[EventManager] duplicate trigger blocked: ", event_id)
		return false
	var e := EVENT_REGISTRY[event_id]
	var gm := _game_manager()
	if gm == null:
		return false
	# 幂等锁先写，防止回调内再触发
	EVENT_STATE[event_id] = true
	# 应用数值
	if e.contract_delta != 0:
		gm.add_contract(e.char_id, e.contract_delta)
	if e.corruption_delta != 0:
		gm.add_corruption(e.corruption_delta)
	if e.affection_delta != 0:
		gm.add_affection(e.char_id, e.affection_delta)
	# 解锁下游事件
	var new_unlocks := 0
	for u in e.unlocks:
		if not EVENT_UNLOCKED.has(u):
			EVENT_UNLOCKED[u] = true
			new_unlocks += 1
	# 首次触发时所有 T0/T1 起始事件也应进解锁池（默认解锁起始 T0）
	_on_event_unlock_check()
	event_triggered.emit(event_id)
	print("[EventManager] triggered: ", event_id, " (choice=", choice_index, ", new_unlocks=", new_unlocks, ")")
	return true

# 事件完成后标记触发（幂等锁，供剧本执行完后调用）
func mark_event_triggered(event_id: String) -> void:
	if not EVENT_REGISTRY.has(event_id):
		push_warning("[EventManager] unknown event id: ", event_id)
		return
	if EVENT_STATE.has(event_id):
		return
	EVENT_STATE[event_id] = true
	# 应用解锁
	var e := EVENT_REGISTRY[event_id]
	for u in e.unlocks:
		if not EVENT_UNLOCKED.has(u):
			EVENT_UNLOCKED[u] = true
	event_triggered.emit(event_id)

# 首次调用时把 T0 起始事件（H-xxx-001）加入解锁池
func _on_event_unlock_check() -> void:
	if EVENT_UNLOCKED.size() == 0:
		for id in EVENT_REGISTRY:
			var e := EVENT_REGISTRY[id]
			if e.tier == "T0" and id.ends_with("-001"):
				EVENT_UNLOCKED[id] = true

# 列出当前可触发事件（供 UI 显示"待触发事件"列表）
func list_available_events() -> Array:
	var result: Array = []
	for id in EVENT_REGISTRY:
		if check_event_trigger(id):
			result.append(id)
	return result

# 列出已触发事件（存档用）
func get_triggered_events() -> Array:
	return EVENT_STATE.keys()

# ==================== 存档接口 ====================

func to_dict() -> Dictionary:
	return {
		"triggered": EVENT_STATE.keys(),
		"unlocked": EVENT_UNLOCKED.keys(),
	}

func from_dict(d: Dictionary) -> void:
	EVENT_STATE.clear()
	EVENT_UNLOCKED.clear()
	if d.has("triggered"):
		for id in d.triggered:
			EVENT_STATE[id] = true
	if d.has("unlocked"):
		for id in d.unlocked:
			EVENT_UNLOCKED[id] = true

func reset() -> void:
	EVENT_STATE.clear()
	EVENT_UNLOCKED.clear()
	_on_event_unlock_check()

# ==================== 内部工具 ====================

func _game_manager() -> Node:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		push_error("[EventManager] GameManager autoload not found")
	return gm