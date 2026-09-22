# test_battle_system.gd
# Sprint 1 D2（S1-01d）
# 主程：王码 / 测试：陈验
# 10 条 TC-BATTLE-xxx

extends GdUnitTestSuite

var bs: Node

func suite_setup() -> void:
	bs = load("res://scripts/core/combat/battle_system.gd").new()
	add_child(bs)

func suite_teardown() -> void:
	bs.queue_free()
	bs = null

## TC-BATTLE-001 初始化
func test_001_init() -> void:
	var sigs = []
	bs.turn_started.connect(func(who): sigs.append(who))
	bs.start_battle({"max_hp": 100, "atk": 10, "def": 5}, {"max_hp": 50, "atk": 8, "def": 0})
	assert_eq(bs.current_phase, 1)  # PLAYER_TURN
	assert_eq(bs.turn_count, 1)
	assert_eq(sigs.size(), 1)

## TC-BATTLE-002 玩家攻击扣血
func test_002_player_attack() -> void:
	bs.start_battle({"max_hp": 100, "atk": 20, "def": 5}, {"max_hp": 50, "atk": 8, "def": 0})
	var hp = bs.enemy["current_hp"]
	bs.player_attack("enemy")
	assert_lt(bs.enemy["current_hp"], hp)

## TC-BATTLE-003 敌方回合自动执行
func test_003_enemy_turn() -> void:
	bs.start_battle({"max_hp": 100, "atk": 10, "def": 5}, {"max_hp": 1000, "atk": 8, "def": 0})
	var tc = bs.turn_count
	bs.player_attack("enemy")
	assert_eq(bs.turn_count, tc + 1)

## TC-BATTLE-004 敌方死亡触发 WIN
func test_004_win() -> void:
	var result = []
	bs.battle_ended.connect(func(r): result.append(r))
	bs.start_battle({"max_hp": 100, "atk": 50, "def": 5}, {"max_hp": 1, "atk": 8, "def": 0})
	bs.player_attack("enemy")
	assert_eq(result[0], 3)  # WIN

## TC-BATTLE-005 玩家死亡触发 LOSE
func test_005_lose() -> void:
	var result = []
	bs.battle_ended.connect(func(r): result.append(r))
	bs.start_battle({"max_hp": 1, "atk": 0, "def": 0}, {"max_hp": 100, "atk": 50, "def": 0})
	bs.player_attack("enemy")
	assert_eq(result[0], 4)  # LOSE

## TC-BATTLE-006 非玩家回合攻击被拒
func test_006_reject_attack() -> void:
	bs.start_battle({"max_hp": 100, "atk": 10, "def": 5}, {"max_hp": 1000, "atk": 8, "def": 0})
	bs.current_phase = 2  # ENEMY_TURN
	var hp = bs.enemy["current_hp"]
	bs.player_attack("enemy")
	assert_eq(bs.enemy["current_hp"], hp)

## TC-BATTLE-007 伤害下限保护
func test_007_min_damage() -> void:
	bs.start_battle({"max_hp": 100, "atk": 0, "def": 0}, {"max_hp": 100, "atk": 0, "def": 0})
	var hp = bs.enemy["current_hp"]
	bs.player_attack("enemy")
	var dmg = hp - bs.enemy["current_hp"]
	assert_ge(dmg, 1)

## TC-BATTLE-008 伤害波动范围
func test_008_damage_range() -> void:
	bs.start_battle({"max_hp": 10000, "atk": 20, "def": 0}, {"max_hp": 10000, "atk": 0, "def": 0})
	for i in range(10):
		var hp = bs.enemy["current_hp"]
		bs.player_attack("enemy")
		var dmg = hp - bs.enemy["current_hp"]
		assert_ge(dmg, 18)
		assert_le(dmg, 22)

## TC-BATTLE-009 战斗结束后再攻击被拒
func test_009_after_end() -> void:
	bs.start_battle({"max_hp": 100, "atk": 50, "def": 5}, {"max_hp": 1, "atk": 8, "def": 0})
	bs.player_attack("enemy")
	var phase = bs.current_phase
	bs.player_attack("enemy")
	assert_eq(bs.current_phase, phase)

## TC-BATTLE-010 HP 不为负
func test_010_no_negative_hp() -> void:
	bs.start_battle({"max_hp": 100, "atk": 100, "def": 5}, {"max_hp": 3, "atk": 0, "def": 0})
	bs.player_attack("enemy")
	assert_eq(bs.enemy["current_hp"], 0)
	assert_ge(bs.enemy["current_hp"], 0)