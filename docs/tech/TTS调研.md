# TTS 接入调研 v0.1（S0-07a）

> 维护人：王码（主程）
> 版本：v0.1（Sprint 0 D5）
> 关联：R-021（TTS 配音占位）
> 需求：600 句首发语音，中文为主，日文备用，情绪多变（含 H 事件喘息/呻吟）

---

## 一、三家方案对比

| 维度 | Azure TTS（推荐） | Edge TTS（免费占位） | 讯飞语音 |
|---|---|---|---|
| **免费额度** | 50 万字符/月免费（付费 4 元/万字符） | 完全免费（Edge 浏览器调用） | 免费 3 万字符/日 |
| **中日文音色** | ✅ 丰富（zh-CN-XiaoxiaoNeural、ja-JP-NanamiNeural） | ✅ 有（zh-CN-XiaoxiaoNeural、ja-JP-NanamiNeural） | ✅ 中文为主 |
| **情绪支持** | ✅ SSML 支持 angry/sad/happy/sad | ⚠️ 部分支持（需参数调 pitch/rate） | ❌ 需付费接口 |
| **网络依赖** | 需网络（可本地缓存 ogg） | 需网络（微软服务） | 需网络 |
| **稳定性** | 高（企业级） | 中（微软官方免费，无 SLA） | 中 |
| **集成难度** | 低（Python SDK） | 极低（edge-tts Python 包） | 中 |
| **商用许可** | 商用需付费订阅（Free F0 tier 允许 ≤50 万字符/月） | 微软 ToS 未明确禁止商用，风险中 | 商用需认证 |
| **延迟** | 800ms-2s/句 | 500ms-1.5s/句 | 500ms-1.5s/句 |

---

## 二、结论

**首发 MVP 用 Edge TTS（免费，无风险）**，V5+ 真人配音时替换。

**理由**：
1. 完全免费，600 句约 15,000 字符，远低于任何额度
2. Python 一行调用：`edge_tts.Communicate(text, voice).save("out.mp3")`
3. 音色覆盖中日文，情绪通过 `pitch`/`rate` 参数调
4. 微软 ToS 未明确禁止单机游戏配音用途（比 Azure Free Tier 宽松）
5. 若首发后用户反馈 TTS 太机械，切 Azure 付费版即可（API 兼容）

---

## 三、音色映射

| 角色 | 音色 ID | 备注 |
|---|---|---|
| 主角凯尔（男） | `zh-CN-YunjianNeural` | 青年男声，稍带磁性 |
| Artesia（女） | `zh-CN-XiaoxiaoNeural` | 温柔女声，女仆感 |
| Marina（女） | `zh-CN-XiaoyiNeural` | 少女音，水灵 |
| Mei（女） | `zh-CN-XiaohanNeural` | 冷艳御姐 |
| Rushena（女） | `zh-CN-XiaoshuangNeural` | 活泼魅魔 |
| Meido（女） | `zh-CN-XiaozhenNeural` | 高冷女帝 |
| 系统旁白 | `zh-CN-YunxiNeural` | 中性旁白 |

---

## 四、集成方式

### 4.1 生成脚本 `tools/voice_generator.py`

**依赖**：
```bash
pip install edge-tts pymp3
```

**核心逻辑**：
- 读 `dialog.json` 中所有 `speaker` + `text` 字段
- 按角色音色 ID 生成 mp3
- 文件命名：`{event_id}_{scene_id}_{line_index}.mp3`
- 输出到 `assets/events/{char}/H-XXX-001/audio/se/`

### 4.2 参数调优（情绪）

| 场景 | pitch | rate | volume |
|---|---|---|---|
| 平静对话 | +0Hz | +0% | +0% |
| 害羞/低语 | +2Hz | -10% | -15% |
| 喘息/呻吟 | +4Hz | -20% | +10% |
| 哭喊 | -2Hz | +15% | +20% |
| 愤怒 | +2Hz | +10% | +15% |

**dialog.json 扩展字段**（赵画/李游加）：
```json
{
  "speaker": "Artesia",
  "expression": "blush",
  "text": "……主人……",
  "tts": {
    "pitch": "+2Hz",
    "rate": "-10%",
    "volume": "-15%"
  }
}
```

### 4.3 批量生成流程

```
李游写完剧本 → 提交 dialog.json
    ↓
王码跑 `python tools/voice_generator.py --event H-ART-001`
    ↓
输出 mp3 到 assets/events/artesia/H-ART-001/audio/se/
    ↓
赵画校对发音/情绪，标注需要重生的行
    ↓
王码重跑 --event --force 覆盖
```

---

## 五、性能与体积

| 项 | 数值 |
|---|---|
| 单句 mp3 平均大小（5-10s） | ~80KB |
| 600 句总大小 | ~48MB |
| 转换 ogg（音频优化方案 v0.1 标准） | ~30MB |
| Android APK 增量 | +30MB（仍在 120MB 预算内） |
| 生成耗时（600 句） | ~30 分钟（含网络延迟） |

**结论**：APK 体积可控，走 ogg 64kbps 压缩（赵画资源优化方案对齐）。

---

## 六、风险

| 风险 | 应对 |
|---|---|
| Edge TTS 服务被墙/不稳定 | 备用 Azure TTS（需付费订阅，Sprint 2 决定） |
| 音色不符角色气质 | Sprint 1 首 10 句试听，必要时换音色 |
| 商用 ToS 风险 | 首发单机版无商业分发（Steam 侧也单机），V5+ 若商业化切付费 Azure |
| 情绪参数调节难 | 首批生成后赵画校对 + 迭代参数 |
| 网络依赖导致 CI 阻塞 | 本地生成一次入库 Git LFS，CI 只测试加载不生成 |

---

## 七、执行计划

| 阶段 | 任务 | 时间 |
|---|---|---|
| D5 | 调研结论（本文档） | ✅ 本次 |
| D6 | `voice_generator.py` 骨架 | 王码 |
| Sprint 1 D1 | 生成 H-ART-001 24 句语音 | 王码 |
| Sprint 1 D2 | 赵画校对 + 情绪参数迭代 | 赵画+王码 |
| Sprint 1 D3 | 全 25 事件 600 句生成 | 王码 |

---

## 八、给团队

**张策**：
- 走 Edge TTS 免费方案，0 元成本
- 若首发后有付费商业化需求，切换 Azure 付费版（4 元/万字符，约 60 元总成本）

**赵画**：
- dialog.json 加 `tts` 字段（情绪参数）
- Sprint 1 D2 校对首轮生成结果

**李游**：
- H-ART-001 dialog.json 已可配合 TTS 生成（当前无 `tts` 字段，默认参数即可跑通）

---

## 变更日志

- 2024-09-09 v0.1：初版，Edge TTS 定为首发方案，Azure/讯飞备用