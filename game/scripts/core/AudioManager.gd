# AudioManager.gd
# BGM / SE 播放与淡入淡出
# 维护人：王码
# 版本：v0.1（D2 骨架）

extends Node

var bgm_player: AudioStreamPlayer
var se_players: Array = []
var fade_duration: float = 1.0
var current_bgm: String = ""

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -20.0
	add_child(bgm_player)
	# 4 个 SE 通道
	for i in range(4):
		var p := AudioStreamPlayer.new()
		p.volume_db = -10.0
		add_child(p)
		se_players.append(p)
	print("[AudioManager] init")

func play_bgm(path: String, fade: float = 1.0) -> void:
	if current_bgm == path:
		return
	var stream = load(path) as AudioStream
	if stream == null:
		push_warning("[AudioManager] BGM not found: ", path)
		return
	fade_duration = fade
	bgm_player.stream = stream
	bgm_player.play()
	current_bgm = path

func stop_bgm(fade: float = 1.0) -> void:
	fade_duration = fade
	# 淡出后停止（简化：立即停）
	bgm_player.stop()
	current_bgm = ""

func play_se(path: String, channel: int = 0) -> void:
	var stream = load(path) as AudioStream
	if stream == null:
		return
	if channel < 0 or channel >= se_players.size():
		channel = 0
	se_players[channel].stream = stream
	se_players[channel].play()

func set_bgm_volume(db: float) -> void:
	bgm_player.volume_db = db

func set_se_volume(db: float) -> void:
	for p in se_players:
		p.volume_db = db
