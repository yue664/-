# BattleSystem.gd
# Sprint 1 D1（S1-01）战斗原型骨架
# 主程：王码
# 状态：骨架，回合逻辑 D2 补完

extends Node

## 战斗状态
enum Phase { IDLE, PLAYER_TURN, ENEMY_TURN, WIN, LOSE }

signal turn_started(who: String)
signal hp_changed(unit_id: String, hp: int, max_hp: int)
signal battle_ended(result: Phase)

## 战斗单位数据
var player: Dictionary = {}
var enemy: Dictionary = {}
var current_phase: Phase = Phase.IDLE
var turn_count: int = 0

## 初始化战斗
func start_battle(player_data: Dictionary, enemy_data: Dictionary) -> void:
	player = _clone_unit(player_data)
	enemy = _clone_unit(enemy_data)
	current_phase = Phase.PLAYER_TURN
	turn_count = 1
	emit_signal("turn_started", "player")

func _clone_unit(d: Dictionary) -> Dictionary:
	var u = d.duplicate(true)
	u["current_hp"] = u.get("max_hp", 100)
	return u

## 玩家攻击
func player_attack(target_id: String) -> void:
	if current_phase != Phase.PLAYER_TURN:
		return
	var dmg = _calc_damage(player, enemy)
	enemy["current_hp"] = max(0, enemy["current_hp"] - dmg)
	emit_signal("hp_changed", target_id, enemy["current_hp"], enemy.get("max_hp", 100))
	if enemy["current_hp"] <= 0:
		_end_battle(Phase.WIN)
	else:
		current_phase = Phase.ENEMY_TURN
		emit_signal("turn_started", "enemy")
		_enemy_turn()

## 敌方回合
func _enemy_turn() -> void:
	var dmg = _calc_damage(enemy, player)
	player["current_hp"] = max(0, player["current_hp"] - dmg)
	emit_signal("hp_changed", "player", player["current_hp"], player.get("max_hp", 100))
	if player["current_hp"] <= 0:
		_end_battle(Phase.LOSE)
	else:
		turn_count += 1
		current_phase = Phase.PLAYER_TURN
		emit_signal("turn_started", "player")

## 伤害公式
func _calc_damage(attacker: Dictionary, defender: Dictionary) -> int:
	var atk = attacker.get("atk", 10)
	var def = defender.get("def", 0)
	var base = max(1, atk - def)
	var variance = randi_range(-2, 2)
	return max(1, base + variance)

func _end_battle(result: Phase) -> void:
	current_phase = result
	emit_signal("battle_ended", result)