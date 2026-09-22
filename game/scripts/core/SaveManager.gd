# SaveManager.gd
# 存档管理：3 槽 + 自动存档 + 版本迁移
# 维护人：王码
# 版本：v0.2（Sprint 0 D7，补 auto_save 钩子）
# 关联：R-025 进度追平、张策 D6 派活

extends Node

const SAVE_VERSION := "0.2.0"
const SLOT_COUNT := 3
const AUTO_SLOT := 0  # 0 = 自动存档槽（独立于 1/2/3 手动槽）
const AUTO_SAVE_DEBOUNCE_MS := 2000  # 2 秒防抖，避免同一事件链多次触发

signal save_completed(slot: int, ok: bool)
signal auto_save_completed(ok: bool)

var migration_registry: Array = []  # [{from, to, func}]
var _auto_save_timer_ms: int = 0
var _auto_save_pending: bool = false

func _ready() -> void:
	register_migration("0.1.0", "0.2.0", _migrate_v01_to_v02)
	# 挂 GameManager/EventManager 信号（若已加载）
	_wire_signals()
	print("[SaveManager] init v=", SAVE_VERSION)

func _process(delta: float) -> void:
	# 防抖：2s 后落盘，避免事件链多次 auto_save
	if _auto_save_pending:
		_auto_save_timer_ms += int(delta * 1000.0)
		if _auto_save_timer_ms >= AUTO_SAVE_DEBOUNCE_MS:
			_auto_save_timer_ms = 0
			_auto_save_pending = false
			_execute_auto_save()

func register_migration(from: String, to: String, cb: Callable) -> void:
	migration_registry.append({"from": from, "to": to, "func": cb})

func _wire_signals() -> void:
	# GameManager 数值变化 → 排队自动存档
	var gm := get_node_or_null("/root/GameManager")
	if gm and not gm.is_connected("contract_changed", _on_game_state_changed):
		gm.connect("contract_changed", _on_game_state_changed)
		gm.connect("corruption_changed", _on_game_state_changed)
		gm.connect("affection_changed", _on_game_state_changed)
	# EventManager 事件触发 → 立即自动存档
	var em := get_node_or_null("/root/EventManager")
	if em and not em.is_connected("event_triggered", _on_event_triggered):
		em.connect("event_triggered", _on_event_triggered)

func _on_game_state_changed(_val) -> void:
	_schedule_auto_save()

func _on_event_triggered(_event_id: String) -> void:
	_schedule_auto_save()

# ==================== 手动存档 ====================

func _migrate_v01_to_v02(data: Dictionary) -> Dictionary:
	if not data.has("meta"):
		data["meta"] = {}
	data["meta"]["version"] = SAVE_VERSION
	return data

func save(slot: int, data: Dictionary) -> bool:
	if slot < 1 or slot > SLOT_COUNT:
		push_error("[SaveManager] invalid manual slot: ", slot)
		return false
	var path := PlatformManager.get_save_path(slot)
	data["meta"] = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"platform": PlatformManager._platform_name(),
		"slot": slot,
		"auto": false,
	}
	var ok := _write_file(path, data)
	save_completed.emit(slot, ok)
	return ok

# 存"当前游戏状态"到手动槽（自动组装 GameManager + EventManager）
func save_current(slot: int) -> bool:
	return save(slot, collect_current_state())

# ==================== 自动存档 ====================

func _schedule_auto_save() -> void:
	_auto_save_pending = true
	_auto_save_timer_ms = 0

func _execute_auto_save() -> void:
	var data := collect_current_state()
	data["meta"]["auto"] = true
	var ok := save(AUTO_SLOT, data)
	auto_save_completed.emit(ok)
	print("[SaveManager] auto_save ok=", ok)

# 立即触发（供关键节点强制存档，如事件结束、场景切换）
func auto_save_now() -> bool:
	_auto_save_pending = false
	_auto_save_timer_ms = 0
	return _execute_auto_save()

# ==================== 收集/恢复 ====================

func collect_current_state() -> Dictionary:
	var d := {}
	var gm := get_node_or_null("/root/GameManager")
	if gm:
		d["game"] = gm.to_dict()
	var em := get_node_or_null("/root/EventManager")
	if em:
		d["events"] = em.to_dict()
	return d

func load(slot: int) -> Dictionary:
	var path := PlatformManager.get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed := JSON.parse_string(text)
	if parsed == null:
		return {}
	var data: Dictionary = parsed
	data = _apply_migrations(data)
	return data

# 读取自动存档
func load_auto() -> Dictionary:
	return load(AUTO_SLOT)

# 恢复当前游戏状态
func restore(data: Dictionary) -> void:
	if data.has("game"):
		var gm := get_node_or_null("/root/GameManager")
		if gm:
			gm.from_dict(data["game"])
	if data.has("events"):
		var em := get_node_or_null("/root/EventManager")
		if em:
			em.from_dict(data["events"])

func load_current(slot: int) -> bool:
	var data := load(slot)
	if data.is_empty():
		return false
	restore(data)
	return true

func load_auto_current() -> bool:
	return load_current(AUTO_SLOT)

func _apply_migrations(data: Dictionary) -> Dictionary:
	var current_ver := _get_version(data)
	while current_ver != SAVE_VERSION:
		var applied := false
		for mig in migration_registry:
			if mig["from"] == current_ver:
				data = mig["func"].call(data)
				current_ver = mig["to"]
				applied = true
				break
		if not applied:
			push_warning("[SaveManager] no migration from ", current_ver, " to ", SAVE_VERSION)
			break
	return data

func _get_version(data: Dictionary) -> String:
	if data.has("meta") and data.meta.has("version"):
		return data.meta["version"]
	return "0.1.0"

func _write_file(path: String, data: Dictionary) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] cannot open: ", path, " err=", FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	return true

func delete(slot: int) -> bool:
	if slot < 0 or slot > SLOT_COUNT:
		return false
	var path := PlatformManager.get_save_path(slot)
	return DirAccess.remove_absolute(path) == OK

func list_slots() -> Array:
	var result: Array = []
	result.append({"slot": AUTO_SLOT, "exists": FileAccess.file_exists(PlatformManager.get_save_path(AUTO_SLOT)), "auto": true})
	for i in range(1, SLOT_COUNT + 1):
		result.append({"slot": i, "exists": FileAccess.file_exists(PlatformManager.get_save_path(i)), "auto": false})
	return result
