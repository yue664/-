extends Node

# EventManager 单元测试（Godot Test Suite）
# 维护人：王码
# 版本：v0.1（Sprint 0 D5）
# 覆盖：R-009 溢出保护、R-010 事件幂等性、TC-VAL-001~008
#
# 运行：`godot --headless --script res://tests/test_event_manager.gd`

func _init() -> void:
	print("========== EventManager Tests ==========")
	
	var p1 := _run("TC-VAL-001 契约度 clamp 上限 100", _test_contract_clamp)
	var p2 := _run("TC-VAL-002 好感度 clamp 上限 100", _test_affection_clamp)
	var p3 := _run("TC-VAL-003 堕落值 clamp 上限 100", _test_corruption_clamp)
	var p4 := _run("TC-VAL-004 负数 delta 不崩溃", _test_negative_delta)
	var p5 := _run("TC-VAL-005 事件重复触发（幂等）", _test_event_idempotent)
	var p6 := _run("TC-VAL-006 契约度未达标拒绝触发", _test_event_condition_fail)
	var p7 := _run("TC-VAL-007 主角完全堕落触发结局", _test_fallen_ending)
	var p8 := _run("TC-VAL-008 5 位女主契约度全满存档", _test_full_contract_save)
	var p9 := _run("TC-VAL-009 H-ART-001 触发后契约+25 堕落+10", _test_h_art_001_effect)
	var p10 := _run("TC-VAL-010 EventManager 存档序列化", _test_event_serialization)
	
	var total := 10
	var success := (int(p1) + int(p2) + int(p3) + int(p4) + int(p5) + int(p6) + int(p7) + int(p8) + int(p9) + int(p10))
	print("========== Summary: ", success, "/", total, " passed ==========")
	if success == total:
		print("ALL TESTS PASSED")
		get_tree().quit(0)
	else:
		print("TESTS FAILED: ", total - success)
		get_tree().quit(1)

func _run(name: String, fn: Callable) -> bool:
	var ok := fn.call()
	print(name, ": ", "PASS" if ok else "FAIL")
	return ok

# ==================== 测试用例 ====================

func _test_contract_clamp() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_contract("artesia", 500)
	return GameManager.contract["artesia"] == 100

func _test_affection_clamp() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_affection("artesia", 500)
	return GameManager.affection["artesia"] == 100

func _test_corruption_clamp() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_corruption(500)
	return GameManager.corruption == 100

func _test_negative_delta() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_contract("artesia", -1000)
	GameManager.add_affection("artesia", -1000)
	GameManager.add_corruption(-1000)
	return (GameManager.contract["artesia"] == 0
		and GameManager.affection["artesia"] == 0
		and GameManager.corruption == 0)

func _test_event_idempotent() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	# 前置达标
	GameManager.add_affection("artesia", 100)
	# 首次触发成功
	var r1 := EventManager.trigger_event("H-ART-001")
	if not r1:
		return false
	# 幂等锁：再次触发应被拒
	var r2 := EventManager.trigger_event("H-ART-001")
	return r2 == false and EventManager.is_triggered("H-ART-001")

func _test_event_condition_fail() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	# H-ART-003 要求契约 45 + 好感 70，这里不达标
	var r := EventManager.trigger_event("H-ART-003")
	return r == false

func _test_fallen_ending() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_corruption(100)
	return GameManager.check_ending_condition() == "fallen"

func _test_full_contract_save() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	# 5 女主契约度全满
	for h in GameManager.HEROINES:
		GameManager.add_contract(h, 100)
		GameManager.add_affection(h, 100)
	GameManager.add_corruption(80)
	# 序列化/反序列化
	var d := GameManager.to_dict()
	GameManager.reset_state()
	GameManager.from_dict(d)
	var all_full := true
	for h in GameManager.HEROINES:
		if GameManager.contract[h] != 100 or GameManager.affection[h] != 100:
			all_full = false
	return all_full and GameManager.corruption == 80

func _test_h_art_001_effect() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	# H-ART-001 前置：契约 0 + 好感 50 + 堕落 0
	GameManager.add_affection("artesia", 50)
	var r := EventManager.trigger_event("H-ART-001")
	if not r:
		return false
	return (
		GameManager.contract["artesia"] == 25
		and GameManager.corruption == 10
		and EventManager.is_triggered("H-ART-001")
	)

func _test_event_serialization() -> bool:
	GameManager.reset_state()
	EventManager.reset()
	GameManager.add_affection("artesia", 50)
	EventManager.trigger_event("H-ART-001")
	var evd := EventManager.to_dict()
	# 反序列化
	EventManager.reset()
	EventManager.from_dict(evd)
	return (
		EventManager.is_triggered("H-ART-001")
		and EventManager.get_triggered_events().size() == 1
	)