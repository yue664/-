# BattleScene.gd
# Sprint 1 D2（S1-01c）
# 主程：王码
# 战斗 UI 事件绑定：BattleSystem 信号 → 表现层

extends Control

@onready var battle_system: Node = preload("res://scripts/core/combat/battle_system.gd").new()
@onready var hp_player_label: Label = $Panel/VBox/HpBar_Player
@onready var hp_enemy_label: Label = $Panel/VBox/HpBar_Enemy
@onready var turn_label: Label = $Panel/VBox/TurnLabel
@onready var attack_button: Button = $Panel/VBox/AttackButton
@onready var result_label: Label = $ResultOverlay/ResultLabel

func _ready() -> void:
	add_child(battle_system)
	battle_system.turn_started.connect(_on_turn_started)
	battle_system.hp_changed.connect(_on_hp_changed)
	battle_system.battle_ended.connect(_on_battle_ended)
	attack_button.pressed.connect(_on_attack_pressed)
	result_label.visible = false
	battle_system.start_battle(
		{"max_hp": 100, "atk": 12, "def": 5, "name": "勇者"},
		{"max_hp": 60, "atk": 8, "def": 2, "name": "史莱姆"}
	)

func _on_turn_started(who: String) -> void:
	turn_label.text = "当前回合：%s" % ("玩家" if who == "player" else "敌人")
	attack_button.disabled = (who != "player")

func _on_hp_changed(unit_id: String, hp: int, max_hp: int) -> void:
	if unit_id == "player":
		hp_player_label.text = "勇者 HP %d / %d" % [hp, max_hp]
	else:
		hp_enemy_label.text = "敌人 HP %d / %d" % [hp, max_hp]

func _on_battle_ended(result: int) -> void:
	if result == 3:
		result_label.text = "胜利！"
	elif result == 4:
		result_label.text = "战败……"
	result_label.visible = true
	attack_button.disabled = true

func _on_attack_pressed() -> void:
	battle_system.player_attack("enemy")