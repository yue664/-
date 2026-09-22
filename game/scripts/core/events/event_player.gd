# EventPlayer.gd
# Sprint 1 D3（S1-05a）
# 主程：王码
# H 事件演出系统：加载剧本 JSON、播放分镜、立绘切换、语音
# 关联：H-ART-001 全流程演示（S1-02）

extends Control

signal event_finished(event_id: String)

var event_id: String = ""
var script_data: Dictionary = {}
var current_shot: int = 0

@onready var portrait_left: TextureRect = $CanvasLayer/Portraits/Left
@onready var portrait_right: TextureRect = $CanvasLayer/Portraits/Right
@onready var dialogue_label: RichTextLabel = $CanvasLayer/DialogueBox/Text
@onready var shot_indicator: Label = $CanvasLayer/ShotIndicator

## 加载并播放事件
func play(event_id_: String) -> void:
	event_id = event_id_
	script_data = _load_script(event_id_)
	current_shot = 0
	_play_next()

func _load_script(id: String) -> Dictionary:
	var path = "res://assets/events/%s/剧本.json" % id
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	return JSON.parse_string(f.get_as_text())

## 播放下一分镜
func _play_next() -> void:
	var shots = script_data.get("shots", [])
	if current_shot >= shots.size():
		event_finished.emit(event_id)
		return
	var shot = shots[current_shot]
	shot_indicator.text = "分镜 %d / %d" % [current_shot + 1, shots.size()]
	_apply_shot(shot)

## 应用单个分镜
func _apply_shot(shot: Dictionary) -> void:
	var portraits = shot.get("portraits", {})
	var left_id = portraits.get("left", "")
	var right_id = portraits.get("right", "")
	if left_id != "":
		portrait_left.texture = _load_portrait(left_id)
	if right_id != "":
		portrait_right.texture = _load_portrait(right_id)
	var lines = shot.get("lines", [])
	if lines.size() > 0:
		_play_lines(lines, 0)
	else:
		# 无台词分镜（纯 CG 展示），停顿 3 秒
		await get_tree().create_timer(3.0).timeout
		current_shot += 1
		_play_next()

func _play_lines(lines: Array, idx: int) -> void:
	if idx >= lines.size():
		await get_tree().create_timer(1.0).timeout
		current_shot += 1
		_play_next()
		return
	var line = lines[idx]
	dialogue_label.text = line.get("speaker", "") + ": " + line.get("text", "")
	# 分镜内换立绘（支持左右两侧）
	var switch_left = line.get("portrait_switch_left", "")
	var switch_right = line.get("portrait_switch_right", "")
	if switch_left != "":
		portrait_left.texture = _load_portrait(switch_left)
	if switch_right != "":
		portrait_right.texture = _load_portrait(switch_right)
	# 兼容旧版字段
	var switch_id = line.get("portrait_switch", "")
	if switch_id != "" and switch_left == "" and switch_right == "":
		portrait_left.texture = _load_portrait(switch_id)
	# 语音播放（Edge TTS 音频文件）
	var audio_path = line.get("audio", "")
	if audio_path != "":
		var audio = AudioStreamPlayer.new()
		add_child(audio)
		audio.stream = load("res://" + audio_path)
		audio.play()
		await audio.finished
	else:
		await get_tree().create_timer(2.0).timeout
	_play_lines(lines, idx + 1)

## 跳过当前分镜（Android 触控 R-018：长按 500ms + 二次确认）
func skip_current_shot() -> void:
	var shots = script_data.get("shots", [])
	if current_shot < shots.size() and shots[current_shot].get("skippable", false):
		current_shot += 1
		_play_next()

func _load_portrait(id: String) -> Texture2D:
	return load("res://assets/portraits/%s.png" % id)