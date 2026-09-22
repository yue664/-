# Main.gd
# 主入口节点：负责初始化 + 平台检测 + 场景加载
# 维护人：王码
# 版本：v0.1（D2 骨架）

extends Node

func _ready() -> void:
	print("=== 《阿爾卡迪亞墮落者們》 v0.2.0 ===")
	print("[Main] platform=", PlatformManager._platform_name())
	print("[Main] touch=", PlatformManager.is_touch(), " 3d_cinematic=", PlatformManager.can_use_3d_cinematic())
	# MVP 阶段：直接进主菜单占位
	_show_placeholder()

func _show_placeholder() -> void:
	var label := Label.new()
	label.text = "Loading...\nPlatform: " + PlatformManager._platform_name()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
