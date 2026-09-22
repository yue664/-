# PortraitCache.gd
# 立绘 + 表情差分缓存（LRU），事件/H 触发器切换用
# 维护人：王码
# 版本：v0.1（Sprint 0 D7）
# 关联：R-025 进度追平、赵画 D6 立绘占位 PNG 规范
#
# 使用：
#   auto_load PortraitCache
#   PortraitCache.show_portrait("marina", "blush")   # 切表情差分
#   PortraitCache.show_portrait("artesia")            # 默认 neutral
#   PortraitCache.clear()                              # 事件结束后清缓存
#
# 命名规则（赵画 D6 立绘占位 PNG）：
#   assets/portraits/{char}_placeholder.png          立绘基础
#   assets/portraits_expressions/{char}_{expr}.webp  表情差分

extends Node

signal portrait_changed(char_id: String, expression: String, path: String)

const DEFAULT_EXPRESSION := "neutral"
const MAX_CACHE := 8  # LRU 缓存 8 张（对齐资源优化方案 WebP <1.2MB 假设）

const EXPRESSIONS: Array = ["neutral", "smile", "blush", "surprised"]
const HEROINES: Array = ["artesia", "marina", "mei", "rushena", "meido"]
const PORTRAIT_DIR := "res://assets/portraits/"
const EXPRESSION_DIR := "res://assets/portraits_expressions/"

# LRU 缓存：char_id/expr -> {path, Texture2D, last_use_ms}
var _cache: Dictionary = {}
var _tick_ms: int = 0
var _current_char: String = ""
var _current_expr: String = ""

func _ready() -> void:
	_wire_event_manager()
	print("[PortraitCache] init, max_cache=", MAX_CACHE)

func _process(delta: float) -> void:
	_tick_ms += int(delta * 1000.0)

# 获取某 char+expr 的纹理路径
func get_texture_path(char_id: String, expression: String = DEFAULT_EXPRESSION) -> String:
	# 表情差分优先，缺失 fallback 到立绘 placeholder
	var expr_path := EXPRESSION_DIR + char_id.to_lower() + "_" + expression + ".webp"
	if ResourceLoader.exists(expr_path):
		return expr_path
	var png_path := EXPRESSION_DIR + char_id.to_lower() + "_" + expression + ".png"
	if ResourceLoader.exists(png_path):
		return png_path
	# fallback 到 placeholder
	return PORTRAIT_DIR + char_id.to_lower() + "_placeholder.png"

# 显示立绘（LRU 命中/预加载/加载）
func show_portrait(char_id: String, expression: String = DEFAULT_EXPRESSION) -> String:
	var key := _cache_key(char_id, expression)
	_tick_ms += 1
	# LRU 命中
	if _cache.has(key):
		_cache[key]["last_use_ms"] = _tick_ms
		_current_char = char_id
		_current_expr = expression
		return _cache[key]["path"]
	# 未命中：加载
	var path := get_texture_path(char_id, expression)
	_cache_put(key, path)
	_current_char = char_id
	_current_expr = expression
	portrait_changed.emit(char_id, expression, path)
	print("[PortraitCache] load ", path)
	return path

# 显示立绘纹理（返回 Texture2D 供 TextureRect/精灵用）
func get_texture(char_id: String, expression: String = DEFAULT_EXPRESSION) -> Texture2D:
	var path := show_portrait(char_id, expression)
	var tex := load(path)
	if tex == null:
		push_error("[PortraitCache] failed to load texture: ", path)
	return tex

# LRU 命中查询（单测用）
func is_cached(char_id: String, expression: String = DEFAULT_EXPRESSION) -> bool:
	return _cache.has(_cache_key(char_id, expression))

# 缓存大小（单测用）
func cache_size() -> int:
	return _cache.size()

# 缓存命中次数（性能监控用）
var _hit_count: int = 0
var _miss_count: int = 0

func get_hit_count() -> int: return _hit_count
func get_miss_count() -> int: return _miss_count

func reset_counters() -> void:
	_hit_count = 0
	_miss_count = 0

# 切换事件时批量预加载某女主全部表情（可选）
func preload_heroine(char_id: String) -> void:
	for expr in EXPRESSIONS:
		if not is_cached(char_id, expr):
			show_portrait(char_id, expr)

# 清空缓存（事件结束、场景切换用）
func clear() -> void:
	_cache.clear()
	_current_char = ""
	_current_expr = ""

# ==================== 事件触发器接入 ====================
# EventManager 触发事件时，PortraitCache 自动切到该事件的女主立绘
func _wire_event_manager() -> void:
	var em := get_node_or_null("/root/EventManager")
	if em and not em.is_connected("event_triggered", _on_event_triggered):
		em.connect("event_triggered", _on_event_triggered)

func _on_event_triggered(event_id: String) -> void:
	var em := get_node_or_null("/root/EventManager")
	if em == null:
		return
	var meta := em.get_event_meta(event_id)
	if meta.is_empty():
		return
	var char_id := meta.get("char_id", "")
	if char_id.is_empty():
		return
	# 事件触发时预加载该女主全部表情
	preload_heroine(char_id)
	# 默认切 neutral（后续对白播放时再切具体表情）
	show_portrait(char_id, DEFAULT_EXPRESSION)

# ==================== 内部工具 ====================

func _cache_key(char_id: String, expression: String) -> String:
	return char_id.to_lower() + "/" + expression

func _cache_put(key: String, path: String) -> void:
	# 超过容量则淘汰最久未使用
	while _cache.size() >= MAX_CACHE:
		var oldest_key := ""
		var oldest_ms := _tick_ms
		for k in _cache:
			if _cache[k]["last_use_ms"] < oldest_ms:
				oldest_ms = _cache[k]["last_use_ms"]
				oldest_key = k
		if oldest_key == "":
			break
		_cache.erase(oldest_key)
	_miss_count += 1
	_cache[key] = {"path": path, "last_use_ms": _tick_ms}

func on_cache_hit() -> void:
	_hit_count += 1