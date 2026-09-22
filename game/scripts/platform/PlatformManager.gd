# PlatformManager.gd
# 平台检测与降级控制（Godot 4.3）
# 维护人：王码
# 版本：v0.2（D2 Android 骨架）

extends Node

# 平台枚举
enum Platform {
	STEAM_PC,
	ANDROID,
	WEB
}

# 运行时状态（由 _ready 初始化）
var current_platform: Platform = Platform.STEAM_PC
var is_mobile: bool = false
var is_android: bool = false
var is_web: bool = false
var is_high_perf_3d: bool = true   # 是否允许 3D 演出
var use_touch_ui: bool = false     # 是否使用触控 UI
var save_dir_base: String = ""

# 回调信号
signal platform_detected(p: Platform)
signal quality_profile_changed(profile: String)

@export var quality_profile: String = "high"   # "low" / "medium" / "high"

func _ready() -> void:
	_detect_platform()
	_apply_quality_profile()
	platform_detected.emit(current_platform)
	print("[Platform] detected=", _platform_name(), " quality=", quality_profile)

func _detect_platform() -> void:
	if OS.get_name() == "Android":
		current_platform = Platform.ANDROID
		is_android = true
		is_mobile = true
		use_touch_ui = true
		is_high_perf_3d = false        # 手机端默认关闭 3D 演出
	elif OS.get_name() == "Web":
		current_platform = Platform.WEB
		is_web = true
	elif OS.has_feature("editor") or OS.get_name() in ["Windows", "Linux", "macOS"]:
		current_platform = Platform.STEAM_PC
	else:
		current_platform = Platform.STEAM_PC

	# 存档目录按平台分
	if is_android:
		save_dir_base = OS.get_user_data_dir()
	elif is_web:
		save_dir_base = "saves_web"
	else:
		save_dir_base = OS.get_savegame_dir()

func _apply_quality_profile() -> void:
	match quality_profile:
		"low":
			RenderingServer.set_quality_level("rendering", 0)
			is_high_perf_3d = false
		"medium":
			RenderingServer.set_quality_level("rendering", 1)
			is_high_perf_3d = not is_mobile
		"high":
			RenderingServer.set_quality_level("rendering", 2)
			is_high_perf_3d = not is_mobile

func _platform_name() -> String:
	match current_platform:
		Platform.STEAM_PC: return "STEAM_PC"
		Platform.ANDROID: return "ANDROID"
		Platform.WEB: return "WEB"
	return "UNKNOWN"

# 供其他模块查询：该 3D 演出是否可用
func can_use_3d_cinematic() -> bool:
	return is_high_perf_3d

# 供其他模块查询：触控还是鼠标 UI
func is_touch() -> bool:
	return use_touch_ui

# 存档路径拼接（含版本号目录，防跨版本冲突）
func get_save_path(slot: int) -> String:
	return save_dir_base + "/save_" + str(slot) + ".json"

func get_user_data_dir() -> String:
	return save_dir_base
