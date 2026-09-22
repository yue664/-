# Sprint 2 冒烟测试报告

> 负责人：陈验
> Sprint 2 D5（S2-11）
> 关联：Sprint 2 收口会

## 覆盖范围

- H 事件（H-ART-001 / H-MID-001 / H-MA-001 / H-RU-001）
- 战斗系统（BattleSystem 回合逻辑）
- 立绘切换（portrait_switch + portrait_switch_left/right）
- 数值系统（GameManager.add_stat + clamp）
- UI（主菜单 3D/2D + 角色详情）
- 存档（SaveManager v0.2）
- Android 降级（PlatformManager.can_use_3d_cinematic）

## 测试结果

### H 事件（29 条用例）

| 组 | 数量 | 通过 | 失败 | 备注 |
|---|---|---|---|---|
| 通用（TC-EVT-COM） | 8 | 8 | 0 | 剧本 JSON / 分镜 / 立绘 / 数值 / Android 降级 / 跳过 / 幂等 / 缺失 |
| H-ART-001 | 3 | 3 | 0 | Sprint 1 已过，冒烟重跑 |
| H-MID-001 | 7 | 7 | 0 | 新增，重点 |
| H-MA-001 | 8 | 8 | 0 | 新增，含 R-029 clamp |
| H-RU-001 | 3 | 3 | 0 | Sprint 1 已过 |
| **合计** | **29** | **29** | **0** | 100% ✅ |

### 战斗系统（10 条 TC-BATTLE）

| 用例 | 结果 |
|---|---|
| 初始化 | ✅ |
| 扣血 | ✅ |
| 胜负判定 | ✅ |
| 边界（HP=1） | ✅ |
| 幂等锁 | ✅ |
| 回合切换 | ✅（KN-009 未复现） |
| 伤害公式波动 | ✅ |
| 下限 1 保护 | ✅ |
| 信号触发 | ✅ |
| 全场景 | ✅ |
| **合计** | **10/10 通过** ✅ |

### 数值系统（10 条 TC-STAT）

| 用例 | 结果 |
|---|---|
| atk 增量 | ✅ |
| atk clamp | ✅ |
| def 增量 | ✅ |
| agi 增量（H-MA-001 场景） | ✅ |
| agi 负值 clamp | ✅ |
| corruption 增量 | ✅ |
| corruption clamp | ✅ |
| hp clamp | ✅ |
| mp clamp | ✅ |
| 未知 key | ✅ |
| **合计** | **10/10 通过** ✅ |

### UI 完善

| 用例 | 结果 |
|---|---|
| 主菜单 3D（Steam） | ✅ |
| 主菜单 2D（Android） | ✅ |
| 角色详情面板 | ✅ |
| 契约度条形图 | ✅ |
| 好感度条形图 | ✅ |
| 堕落值条形图 | ✅ |
| 触控优化 | ✅ |

### Android 性能（骁龙 8G3）

| 场景 | FPS | 内存 | 状态 |
|---|---|---|---|
| 主菜单 | 60 | 240MB | ✅ |
| 战斗 | 57 | 380MB | ✅ |
| H 事件 | 55 | 385MB | ⚠️ 临界 |
| SaveManager 2s 防抖 | < 1ms | — | ✅ |
| EventManager 幂等锁 | < 0.5ms | — | ✅ |

## KN-009 复现结果（10 场连续）

- 通过：10/10
- 失败：0/10
- **结论**：未复现，持续监控

## 已知问题（承接 Sprint 3）

| 问题 | 说明 |
|---|---|
| Android H 事件 55 FPS 临界 | 需 Sprint 3 优化（立绘压缩、音频预热） |
| 立绘正式素材 21 张（Sprint 3 外包） | R-028 已批，Sprint 3 执行 |
| CG 首包 4 张延期 | R-027 应对中，Sprint 3 由 Indie-H-Comics 补齐 |

## 陈验放行结论

- ✅ Sprint 2 冒烟全部通过（29/29 + 10/10 + 10/10 = 49/49）
- ✅ Android 骁龙 8G3 战斗 57 FPS，H 事件 55 FPS（临界，需 Sprint 3 优化）
- ✅ KN-009 未复现
- ✅ UI 完善主菜单 + 角色详情全部达标
- 🟢 **Sprint 2 放行，可进入 Sprint 3**

## 变更日志

- 2024-09-18 D5：Sprint 2 冒烟测试报告，49/49 通过，放行 Sprint 3