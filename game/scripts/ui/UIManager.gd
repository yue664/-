# UIManager.gd
# UI 层级管理：主菜单 / 对话 / 战斗 HUD / H 事件面板
# 平台感知：触控 UI 或 鼠标 UI
# 维护人：王码
# 版本：v0.1（D2 骨架）

extends Node

enum UIState { MENU, DIALOG, BATTLE, H_EVENT, INVENTORY, SAVE, SETTINGS }

var current_state: UIState = UIState.MENU
var ui_layers: Dictionary = {}

func _ready() -> void:
	current_state = UIState.MENU
	# 触控 UI 提示
	if PlatformManager.is_touch():
		print("[UIManager] touch UI mode")
	else:
		print("[UIManager] mouse UI mode")

func set_state(s: UIState) -> void:
	current_state = s
	_apply_touch_scaling()

func _apply_touch_scaling() -> void:
	# 触控模式下 UI 元素统一放大 1.2x
	# 实际由各 UI 场景读取 PlatformManager.use_touch_ui 自行调整
	pass

func register_layer(name: String, node: Node) -> void:
	ui_layers[name] = node

func unregister_layer(name: String) -> void:
	ui_layers.erase(name)
