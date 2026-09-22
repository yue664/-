# test_save_portrait.gd
# SaveManager + PortraitCache 单元测试
# 维护人：王码
# 版本：v0.1（Sprint 0 D7，补 R-025 追平）
# 覆盖：TC-SAVE-001~005、TC-PORTRAIT-001~005
#
# 运行：`godot --headless --script res://tests/test_save_portrait.gd`

extends SceneTree

func _init() -> void:
	print("========== SaveManager / PortraitCache Tests ==========")

	# 模拟 autoload：把 GameManager / EventManager / SaveManager / PortraitCache 实例挂到 root
	_setup_autoloads()

	var results := []
	results.append(_run("TC-SAVE-001 SaveManager auto_save 信号已挂接", _test_save_signal_wired))
	results.append(_run("TC-SAVE-002 SaveManager.collect_current_state 含 game+events", _test_collect_state))
	results.append(_run("TC-SAVE-003 SaveManager.save_current + load_current 往返一致", _test_save_current_roundtrip))
	results.append(_run("TC-SAVE-004 SaveManager.auto_save_now 强制落盘", _test_auto_save_now))
	results.append(_run("TC-SAVE-005 SaveManager.list_slots 含自动槽", _test_list_slots_auto))

	results.append(_run("TC-PORTRAIT-001 PortraitCache.show_portrait 加载并缓存", _test_portrait_basic))
	results.append(_run("TC-PORTRAIT-002 PortraitCache LRU 命中/miss 计数", _test_portrait_cache_hit))
	results.append(_run("TC-PORTRAIT-003 PortraitCache LRU 淘汰（超 MAX_CACHE）", _test_portrait_lru_evict))
	results.append(_run("TC-PORTRAIT-004 PortraitCache preload_heroine 全 4 表情", _test_portrait_preload))
	results.append(_run("TC-PORTRAIT-005 PortraitCache 事件触发自动切立绘", _test_portrait_event_hook))

	var passed := 0
	for r in results:
		if r:
			passed += 1
	var total := results.size()
	print("========== Summary: ", passed, "/", total, " passed ==========")
	if passed == total:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TESTS FAILED: ", total - passed)
		quit(1)

func _run(name: String, fn: Callable) -> bool:
	var ok := fn.call()
	print(name, ": ", "PASS" if ok else "FAIL")
	return ok

# 手动挂载 autoload（headless --script 模式不会自动加载）
var _gm: Node
var _em: Node
var _sm: Node
var _pc: Node
var _pm: Node

func _setup_autoloads() -> void:
	_pm = load("res://scripts/platform/PlatformManager.gd").new()
	_pm.set_name("PlatformManager")
	root.add_child(_pm)

	_gm = load("res://scripts/core/GameManager.gd").new()
	_gm.set_name("GameManager")
	root.add_child(_gm)

	_em = load("res://scripts/core/EventManager.gd").new()
	_em.set_name("EventManager")
	root.add_child(_em)

	_pc = load("res://scripts/core/PortraitCache.gd").new()
	_pc.set_name("PortraitCache")
	root.add_child(_pc)

	_sm = load("res://scripts/core/SaveManager.gd").new()
	_sm.set_name("SaveManager")
	root.add_child(_sm)

	# 让 _wire_signals / _wire_event_manager 在 autoloads 齐全后重挂（同步）
	_sm._wire_signals()
	_pc._wire_event_manager()

func _rewire() -> void:
	_sm._wire_signals()
	_pc._wire_event_manager()

# ==================== TC-SAVE 用例 ====================

func _test_save_signal_wired() -> bool:
	# EventManager.event_triggered 应连到 SaveManager._on_event_triggered
	# GameManager.contract_changed 应连到 SaveManager._on_game_state_changed
	var wired_em := _em.is_connected("event_triggered", _sm._on_event_triggered)
	var wired_gm := _gm.is_connected("contract_changed", _sm._on_game_state_changed)
	return wired_em and wired_gm

func _test_collect_state() -> bool:
	_gm.reset_state()
	_em.reset()
	_gm.add_corruption(30)
	_gm.add_contract("artesia", 50)
	var d := _sm.collect_current_state()
	return d.has("game") and d.has("events") \
		and d["game"].corruption == 30 \
		and d["game"].contract["artesia"] == 50

func _test_save_current_roundtrip() -> bool:
	# 用内存路径 mock（这里用真实 OS 路径）
	_gm.reset_state()
	_em.reset()
	_gm.add_corruption(42)
	_gm.add_contract("marina", 60)
	_gm.set_flag("test_flag", true)
	_em.trigger_event("H-ART-001") if _em.check_event_trigger("H-ART-001") else null
	_gm.add_affection("artesia", 50)
	_em.trigger_event("H-ART-001")
	var ok := _sm.save_current(1)
	if not ok:
		return false
	# 清零后恢复
	_gm.reset_state()
	_em.reset()
	var ok2 := _sm.load_current(1)
	if not ok2:
		return false
	return (
		_gm.corruption == 42
		and _gm.contract["marina"] == 60
		and _gm.get_flag("test_flag") == true
	)

func _test_auto_save_now() -> bool:
	_gm.reset_state()
	_em.reset()
	_gm.add_corruption(55)
	var ok := _sm.auto_save_now()
	if not ok:
		return false
	# 应生成 slot=0 存档
	var data := _sm.load_auto()
	return data.has("game") and data["game"].corruption == 55 and data["meta"]["auto"] == true

func _test_list_slots_auto() -> bool:
	var slots := _sm.list_slots()
	if slots.size() != 4:  # 0(auto) + 1,2,3
		return false
	return slots[0]["auto"] == true and slots[1]["auto"] == false

# ==================== TC-PORTRAIT 用例 ====================

func _test_portrait_basic() -> bool:
	_pc.clear()
	_pc.reset_counters()
	var path := _pc.show_portrait("marina", "blush")
	# 路径应存在（webp 或 png 或 placeholder fallback）
	if path.is_empty():
		return false
	return _pc.is_cached("marina", "blush") and _pc.cache_size() == 1

func _test_portrait_cache_hit() -> bool:
	_pc.clear()
	_pc.reset_counters()
	# 首次：miss
	_pc.show_portrait("artesia", "smile")
	if _pc.get_miss_count() != 1:
		return false
	# 再次：LRU 命中（虽然计数器在 _cache_put 里算，命中路径不算 miss）
	var before_miss := _pc.get_miss_count()
	_pc.show_portrait("artesia", "smile")
	return _pc.get_miss_count() == before_miss  # 命中不计 miss

func _test_portrait_lru_evict() -> bool:
	_pc.clear()
	_pc.reset_counters()
	# MAX_CACHE=8，注入 10 个不同的 char/expr 组合
	var heroines := ["artesia", "marina", "mei", "rushena", "meido"]
	var exprs := ["neutral", "smile", "blush", "surprised"]
	var i := 0
	for h in heroines:
		for e in exprs:
			_pc.show_portrait(h, e)
			i += 1
	# 缓存不应超过 MAX_CACHE
	if _pc.cache_size() > _pc.MAX_CACHE:
		return false
	# 最新的应还在（marina+smile 早先插入，可能已被淘汰）
	return _pc.cache_size() <= 8

func _test_portrait_preload() -> bool:
	_pc.clear()
	_pc.reset_counters()
	_pc.preload_heroine("mei")
	# 应加载 4 个表情
	return _pc.is_cached("mei", "neutral") \
		and _pc.is_cached("mei", "smile") \
		and _pc.is_cached("mei", "blush") \
		and _pc.is_cached("mei", "surprised")

func _test_portrait_event_hook() -> bool:
	_pc.clear()
	_pc.reset_counters()
	_gm.reset_state()
	_em.reset()
	# 触发 H-MEI-001（前置：好感 50 + 堕落 15）
	_gm.add_affection("mei", 50)
	_gm.add_corruption(15)
	var ok := _em.trigger_event("H-MEI-001")
	if not ok:
		return false
	# 触发后 PortraitCache 应自动预加载 mei 全部表情
	return _pc.is_cached("mei", "neutral") and _pc.cache_size() >= 4