# 立绘占位（S1-06）

> 负责人：赵画
> 周期：Sprint 1 D1-D2
> 数量：26 张（5 女主 × 5 表情 + 主角 1 张）

## 命名规范

```
assets/portraits/{heroine_id}_{expression}.png
```

- 尺寸：1024×1536（竖屏立绘占位）
- 格式：PNG 24 位，透明背景
- 占位版本用纯色底 + 文字标注即可，Sprint 2 替换正式素材

## 清单（26 张）

### Artesia（女仆，xiaoxiao 音色）

- art_normal.png — 常规
- art_smile.png — 微笑
- art_shy.png — 害羞（脸颊红晕）
- art_angry.png — 愤怒
- art_cry.png — 落泪

### Marina（人鱼，nanami 音色）

- ma_normal.png — 常规
- ma_smile.png — 娇笑
- ma_shy.png — 羞怯（湿发贴脸）
- ma_tentacle.png — 触手环绕（特殊状态）
- ma_cry.png — 眼泪化水

### Mei（混血吸血鬼，xiaohan 音色）

- mei_normal.png — 常规
- mei_smile.png — 优雅微笑
- mei_shy.png — 害羞（耳尖红）
- mei_angry.png — 冷怒
- mei_fangs.png — 露獠牙（特殊状态）

### Rushena（魅魔，naoy 音色）

- ru_normal.png — 常规
- ru_smile.png — 媚笑
- ru_shy.png — 罕见害羞
- ru_angry.png — 挑衅
- ru_wings.png — 双翼展开（特殊状态）

### Meido（最终 BOSS，yunxia 音色）

- mid_normal.png — 常规（冷艳）
- mid_smile.png — 极轻微笑
- mid_shy.png — 冰冷
- mid_angry.png — 威压
- mid_crown.png — 王冠显现（特殊状态）

### Hero（主角）

- hero_default.png — 默认（男性主角）

## 状态

- [x] 命名规范确认
- [x] 26 张占位 PNG 产出（D2 交付，纯色底+文字标注版）
- [x] manifest.json 更新 portraits 字段（D2）
- [ ] Sprint 2 正式素材替换

## 变更日志

- 2024-09-10：S1-06 D1 启动，命名规范确认，26 张清单确认
- 2024-09-11：S1-06b/c D2 完成，26 张占位 PNG 落盘，manifest 同步