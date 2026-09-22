# S10-05 用例分组映射表 v0.2（D5 全量挂接定稿）

- **任务**：S10-05 用例自动化脚本化——D5 里程碑：全量 400 条 A/B/C 分档挂接定稿
- **负责人**：王码（主程）+ 陈验（QA 验收）+ 李游（TC 前缀规则）+ 赵画（资产对照表输入）
- **状态**：✅ v0.2 定稿（A/B/C 档位列，供 runner 清单驱动）
- **对账口径**：15min 只算 A+B 自动化执行时长，C 类手工单列；A+B 全量挂接 ≥90% 达标则 Sprint 10 收官

---

## 一、A/B/C 三档总表（对齐覆盖盘点 v0.1 + 李游拆档建议）

| 档 | 定义 | 挂接方式 | 分组归属 | 条数估算 |
|---|---|---|---|---|
| **A** | 纯逻辑/数值/状态机/脚本类 | GDScript headless / 脚本直接跑 | P0/P1/P2/P3 均含 | ~180 |
| **B** | 依赖资产名/挂接状态/资源清单 | 脚本 + 资产对照表（asset_map_v0.1 + 三列合表 v0.1）| P2 为主 | ~56 |
| **C** | 外部服务/多端/实机/主观听感 | 模拟桩抽样 + 手工回归保留 | P1/P3 为主 | ~164 |

**A+B 合计 ~236 条**，挂接率目标 ≥90%（即 ≥212 条自动化挂接）。

## 二、逐组挂接明细（D5 定稿）

### P0 组（冒烟+战斗/H，PC 主线程 + Android 分片）
| TC 范围 | 档位 | 挂接状态 | 说明 |
|---|---|---|---|
| TC-SMOKE-001~010 | A | ✅ 已挂 | 主链路冒烟，headless |
| TC-SMOKE-011~018 | B | ✅ 已挂 | 3D 渲染专项，读资产表断言 |
| TC-SMOKE-019 | B | ✅ 已挂 | 素材完整性，manifest.json 核对 |
| TC-SMOKE-020 | A | ✅ 已挂 | 版本号/资源加载 |
| TC-BATTLE-001~010 | A | ✅ 已挂 | 战斗状态机（test_battle_system.gd）|
| TC-H-001~010 | A | ✅ 已挂 | 契约度/堕落值数值校验 |
| TC-CH5-001~008 | A | ✅ 已挂 | 第五章 BOSS 状态机 |
| TC-BOSS-001~005 | A | ✅ 已挂 | Meido 三阶段+分支判定 |

### P1 组（存档/UI/音频，PC 2 线程）
| TC 范围 | 档位 | 挂接状态 | 说明 |
|---|---|---|---|
| TC-SAVE-001~023 | A | ✅ 已挂 | 存档核心（test_save_portrait.gd）|
| TC-SAVE-MIG-001~008 | C | 🟡 模拟桩抽样 | 双端迁移留手工 |
| TC-UI-001~006（状态机） | A | ✅ 已挂 | 焦点切换/对话框流转 headless |
| TC-UI-014~018（视觉/适配） | C | 🟡 手工截图画廊 | 视觉断言留手工 |
| TC-AUDIO-001~005（文件完整性） | A | ✅ 已挂 | 语音包文件/词条存在性 |
| TC-AUDIO 听感部分 | C | 🟡 手工 | 主观听感保留 |

### P2 组（3D/边界/性能/画廊，PC 3 线程）
| TC 范围 | 档位 | 挂接状态 | 说明 |
|---|---|---|---|
| TC-3D-001~008 | B | ✅ 已挂 | 立绘/模型路径断言（asset_map）|
| TC-BOUND-001~010 | A | ✅ 已挂 | 数值边界（test_add_stat.gd）|
| TC-PERF-001~010（benchmark） | A | ✅ 已挂 | --headless --benchmark 耗时断言 |
| TC-PERF-011~015（FPS/显存/内存） | C | 🟡 实机专属 | 不上 headless（李游拆档确认）|
| TC-GALLERY-001~018 | B | ✅ 已挂 | 18 张槽位四连断言（三列合表 v0.1）|
| TC-GALLERY-019~020 | C | 🟡 手工 | 端到端入廊链路 |
| TC-V12 存量 | 逐条拆 | ✅ 已挂 | 按实际前缀归 A/B/C |

### P3 组（兼容/跨版本/云存档/脚本类，Android + 多配置）
| TC 范围 | 档位 | 挂接状态 | 说明 |
|---|---|---|---|
| TC-COMPAT-001~010 | C | 🟡 手工矩阵 | 多机/多分辨率保留手工 |
| TC-SUB-001~018 | C（A 部分拆出）| 🟡 部分挂接 | 词条存在性可脚本，体验留手工 |
| TC-LINT-001~012 | A | ✅ 已挂 | 词条 lint CI 原生执行 |
| TC-VOICE-001~010（下载/完整性） | A | ✅ 已挂 | 语音包下载校验 |
| TC-VOICE 听感部分 | C | 🟡 手工 | 主观听感保留 |
| TC-STORE-001~005 | C | 🟡 手工 | 外部平台 |
| TC-CLOUD-001~005 | C（模拟桩 A 部分）| 🟡 桩挂接 | 挂载超时/损坏注入跑主体逻辑，端到端手工 |

## 三、TC-GALLERY 18 张槽位 ↔ 三列合表对齐（B 类核心）

| 槽位 | 事件/结局 ID | WebP 路径 | 断言状态 |
|---|---|---|---|
| GALLERY-01 | E-ART-A | assets/cg_2d/artesia/CG-EX-01.webp | ✅ 待 LFS 实物四连 |
| GALLERY-02 | E-MEI-B | assets/cg_2d/mei/CG-EX-02.webp | ✅ 待 LFS 实物四连 |
| GALLERY-03 | E-RU-C | assets/cg_2d/rushena/CG-EX-03.webp | ✅ 待 LFS 实物四连 |
| GALLERY-04 | E-MEI-B 追加 | assets/cg_2d/mei/CG-EX-04.webp | ✅ 待 LFS 实物四连 |
| GALLERY-05 | E-RU-C 追加 | assets/cg_2d/rushena/CG-EX-05.webp | ✅ 待 LFS 实物四连 |
| GALLERY-06 | E5 前庭 | assets/cg_2d/meido/CG-CH5-01.webp | ✅ 待 LFS 实物四连 |
| GALLERY-07 | E5 王座对峙 | assets/cg_2d/meido/CG-CH5-02.webp | ✅ 待 LFS 实物四连 |
| GALLERY-08 | E5-1 魔王加冕 | assets/cg_2d/meido/CG-CH5-03.webp | ✅ 待 LFS 实物四连 |
| GALLERY-09 | E5-5 混沌真结局 | assets/cg_2d/meido/CG-CH5-04.webp | ✅ 待 LFS 实物四连 |
| GALLERY-10 | H-MID-新1 | assets/cg_2d/meido/CG-CH5-05.webp | ✅ 待 LFS 实物四连 |
| GALLERY-11 | H-MID-新2 | assets/cg_2d/meido/CG-CH5-06.webp | ✅ 待 LFS 实物四连 |
| GALLERY-12 | H-RU-003 | assets/cg_2d/rushena/CG-CH5-07.webp | ✅ 待 LFS 实物四连 |
| GALLERY-13 | E5-3 全员堕落 | assets/cg_2d/meido/CG-CH5-08.webp | ✅ 待 LFS 实物四连 |
| GALLERY-14 | V1.1 S7-01 | assets/cg_2d/artesia/CG-S7-01.webp | 🟡 订单推导，LFS 实物确认 |
| GALLERY-15 | V1.1 S7-02 | assets/cg_2d/mei/CG-S7-02.webp | 🟡 订单推导，LFS 实物确认 |
| GALLERY-16 | V1.1 S7-03 | assets/cg_2d/rushena/CG-S7-03.webp | 🟡 订单推导，LFS 实物确认 |
| GALLERY-17 | V1.1 S7-04 | assets/cg_2d/marina/CG-S7-04.webp | 🟡 订单推导，LFS 实物确认 |
| GALLERY-18 | V1.1 S7-05 | assets/cg_2d/meido/CG-S7-05.webp | 🟡 订单推导，LFS 实物确认 |

**四连断言**：① 文件存在（LFS pull 后）② 非空（>0，排除 96B 指针）③ WebP 头 RIFF....WEBP ④ 体积 <1.2MB。

## 四、变更记录

- 2024-11-19：v0.2 定稿（王码）——A/B/C 三档总表 + 逐组挂接明细 + TC-GALLERY 18 槽位对齐三列合表 v0.1；A+B ~236 条，挂接率目标 ≥90%