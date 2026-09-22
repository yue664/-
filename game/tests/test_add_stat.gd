# test_add_stat.gd
# Sprint 2 D4（S2-03+R-022）
# 主程：王码 / 测试：陈验
# add_stat 通用数值接口 + clamp 兜底 用例
# 关联：R-022 三方核对 / R-029 修正

extends SceneTree

func _init():
	var pass_cnt = 0
	var fail_cnt = 0

	# TC-STAT-001 atk 增量正常
	var gm = _new_gm()
	var v = gm.add_stat("atk", 5)
	if v == 25: pass_cnt += 1; print("TC-STAT-001 ✅")
	else: fail_cnt += 1; print("TC-STAT-001 ❌ got=%d" % v)

	# TC-STAT-002 atk clamp 到 60
	gm = _new_gm()
	gm.atk = 55
	v = gm.add_stat("atk", 10)
	if v == 60: pass_cnt += 1; print("TC-STAT-002 ✅")
	else: fail_cnt += 1; print("TC-STAT-002 ❌ got=%d" % v)

	# TC-STAT-003 def 增量正常
	gm = _new_gm()
	v = gm.add_stat("def", 3)
	if v == 18: pass_cnt += 1; print("TC-STAT-003 ✅")
	else: fail_cnt += 1; print("TC-STAT-003 ❌ got=%d" % v)

	# TC-STAT-004 agi 增量正常（H-MA-001 场景）
	gm = _new_gm()
	v = gm.add_stat("agi", 3)
	if v == 28: pass_cnt += 1; print("TC-STAT-004 ✅ (25+3=28)")
	else: fail_cnt += 1; print("TC-STAT-004 ❌ got=%d" % v)

	# TC-STAT-005 agi 负值 clamp 到 0
	gm = _new_gm()
	v = gm.add_stat("agi", -50)
	if v == 0: pass_cnt += 1; print("TC-STAT-005 ✅")
	else: fail_cnt += 1; print("TC-STAT-005 ❌ got=%d" % v)

	# TC-STAT-006 corruption 增量
	gm = _new_gm()
	v = gm.add_stat("corruption", 15)
	if v == 15: pass_cnt += 1; print("TC-STAT-006 ✅")
	else: fail_cnt += 1; print("TC-STAT-006 ❌ got=%d" % v)

	# TC-STAT-007 corruption clamp 到 100
	gm = _new_gm()
	gm.corruption = 95
	v = gm.add_stat("corruption", 20)
	if v == 100: pass_cnt += 1; print("TC-STAT-007 ✅")
	else: fail_cnt += 1; print("TC-STAT-007 ❌ got=%d" % v)

	# TC-STAT-008 hp 增量 clamp 到 max_hp
	gm = _new_gm()
	v = gm.add_stat("hp", -150)
	if v == 0: pass_cnt += 1; print("TC-STAT-008 ✅")
	else: fail_cnt += 1; print("TC-STAT-008 ❌ got=%d" % v)

	# TC-STAT-009 mp 增量 clamp
	gm = _new_gm()
	v = gm.add_stat("mp", 30)
	if v == 50: pass_cnt += 1; print("TC-STAT-009 ✅")
	else: fail_cnt += 1; print("TC-STAT-009 ❌ got=%d" % v)

	# TC-STAT-010 未知 key 返回 0 不崩溃
	gm = _new_gm()
	v = gm.add_stat("unknown", 5)
	if v == 0: pass_cnt += 1; print("TC-STAT-010 ✅")
	else: fail_cnt += 1; print("TC-STAT-010 ❌ got=%d" % v)

	print("")
	print("=== add_stat 用例汇总 ===")
	print("通过: %d / 10" % pass_cnt)
	print("失败: %d / 10" % fail_cnt)
	quit(0 if fail_cnt == 0 else 1)

func _new_gm():
	var Script = load("res://scripts/core/GameManager.gd")
	return Script.new()