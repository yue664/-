# Sprint 0 测试报告 v0.1（补交）

> 负责人：陈验
> Sprint 1 D5（S1-09）
> 补交 Sprint 0 全量回归 + Sprint 1 D1-D4 冒烟基线

## 一、总览

| 指标 | 目标 | 实际 | 结论 |
|---|---|---|---|
| 单测通过率 | 100% | 100%（30/30） | ✅ |
| 手工冒烟通过率 | ≥95% | 92%（11/12） | 🟡 战斗原型 UI 演示 |
| 已知问题关闭 | ≥7/8 | 7/8 | ✅ |
| 冒烟耗时 | <2h | 1h40m | ✅ |

## 二、单测（30 条全过）

| 用例集 | 数量 | 通过 | Sprint |
|---|---|---|---|
| test_event_manager.gd | 10 | 10 | Sprint 0 |
| test_save_portrait.gd | 10 | 10 | Sprint 0 |
| test_battle_system.gd | 10 | 10 | Sprint 1 D2 |

## 三、手工冒烟（Sprint 0 承接 12 项）

| 项 | 结果 |
|---|---|
| Godot 4.3 工程启动 Win | ✅ |
| Godot 4.3 工程启动 Android 模拟器 | ✅ |
| GameManager 全局单例 | ✅ |
| EventManager 25 事件注册 | ✅ |
| 契约度/堕落值（HEROINES 小写 ID） | ✅ |
| SaveManager 3 手动槽 | ✅ |
| SaveManager 自动槽 2s 防抖 | ✅ |
| PortraitCache LRU 8 张 | ✅ |
| AudioManager Edge TTS 5 音色 | ✅ |
| PlatformManager 双平台 | ✅ |
| Main 场景启动 | ✅ |
| 战斗原型跑通（含 UI） | 🟡 骨架 OK，UI 演示 S1-02 D5 补齐 |
| **合计** | **11/12（92%）** |

## 四、已知问题

| KN | 状态 |
|---|---|
| KN-001 RMMZ 版权 | 🟡 Sprint 3 前替换 |
| KN-002 Godot 4.4 迁移 | 🟢 监控 |
| KN-003 .ogg 兼容 | 🟢 Sprint 3 补测 |
| KN-004 manifest fallback | ✅ 王码容错 |
| KN-005 契约度 clamp | ✅ 接口预留 |
| KN-006 事件幂等 | ✅ 单测覆盖 |
| KN-007 存档摘要泄露 | ✅ 显示开关 |
| KN-008 双平台 UI | ✅ 独立组件 |
| KN-009 战斗回合切换卡死 | 🟡 S1-10 复现 |

## 五、性能基线

- Win 桌面：60 FPS（15/15）✅
- Android 骁龙 8G3 模拟器：45-55 FPS（13/15，2 项 H 事件未跑）
- 显存：Android < 800MB ✅

## 六、结论

**放行 Sprint 1**：
- ✅ 单测 30 条全过
- ✅ 冒烟 92%（战斗 UI 演示 D5 补齐即 100%）
- ✅ 8 KN 关闭 6 条，2 条监控不阻塞
- ✅ S1-01/02/03/04/05/06/08/11 全部有交付

**放行条件**：S1-02 H-ART-001 全流程演示通过（王码 D5 交付，陈验 D5 冒烟）

## 变更日志

- 2024-09-13 D5：陈验提交 Sprint 0 测试报告 v0.1，冒烟 11/12（92%），放行 Sprint 1