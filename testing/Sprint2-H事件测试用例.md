# Sprint 2 H 事件测试用例（S2-07 UI 演示前）

> 负责人：陈验
> Sprint 2 D3
> 覆盖：H-ART-001 / H-MID-001 / H-MA-001 / H-RU-001 四场

## 通用用例（每场必跑）

| ID | 用例 | 预期 |
|---|---|---|
| TC-EVT-COM-01 | 剧本 JSON 加载 | 无报错，触发幂等锁 |
| TC-EVT-COM-02 | 分镜顺序播放 | 按 shot 顺序推进 |
| TC-EVT-COM-03 | 立绘切换 | portrait_switch 生效 |
| TC-EVT-COM-04 | 数值结算 | settlement 正确 clamp |
| TC-EVT-COM-05 | Android 降级 | can_use_3d_cinematic()=false 时走 fallback |
| TC-EVT-COM-06 | 跳过按钮 | skippable_shot 生效 |
| TC-EVT-COM-07 | 幂等锁 | 二次触发被拦截 |
| TC-EVT-COM-08 | 剧本缺失 | 优雅降级不崩溃 |

## H-ART-001（契约女仆，Sprint 1 已交付）

| ID | 用例 | 预期 |
|---|---|---|
| TC-ART-01 | 5 分镜播放完整 | 全 5 shot |
| TC-ART-02 | 契约度+15/堕落+10 | GameManager.heroines["artesia"] |
| TC-ART-03 | 解锁 Artesia | unlock 列表包含 artesia |

## H-MID-001（战败捕获，李游 v0.2）

| ID | 用例 | 预期 |
|---|---|---|
| TC-MID-01 | 4 分镜播放完整 | 全 4 shot，20 句台词 |
| TC-MID-02 | 触发条件 | 主角战败 + 堕落<100 + 幂等锁 |
| TC-MID-03 | 数值结算 | 堕落+40 / 契约+30 / 力量-5 |
| TC-MID-04 | 暗黑路线 | 主线分支变更，结局 5/15 可达 |
| TC-MID-05 | mid_crown 立绘 | 分镜 2 王冠切换正确 |
| TC-MID-06 | 力量-5 clamp | 不越界（基础 25→20） |
| TC-MID-07 | Android 降级 | 铁链音效保留，王冠静态贴图 |

## H-MA-001（人鱼诱捕，李游 v0.1）

| ID | 用例 | 预期 |
|---|---|---|
| TC-MA-01 | 4 分镜播放完整 | 全 4 shot，18 句台词 |
| TC-MA-02 | 触发条件 | 主线第二章 + Marina 契约>=40 + 堕落<=60 |
| TC-MA-03 | 数值结算 | 契约+25 / 好感+15 / 堕落+15 / 敏捷+3 |
| TC-MA-04 | 敏捷 clamp（R-029） | 20+3=23 被 clamp 到 20 |
| TC-MA-05 | 深海结局铺垫 | 契约度>=80 触发 H-MA-002 前置 |
| TC-MA-06 | 水波特效 | 分镜 3 特效正常（PC），Android 静态 |
| TC-MA-07 | 分镜 4 可跳过 | skippable_shot=4 生效 |
| TC-MA-08 | 人鱼珍珠 | items: ["pearl_x1"] 正确入包 |

## H-RU-001（魅魔契约，Sprint 1 已交付）

| ID | 用例 | 预期 |
|---|---|---|
| TC-RU-01 | 5 分镜播放完整 | 全 5 shot，27 句台词 |
| TC-RU-02 | 契约度+20/堕落+15 | 契约/堕落正确 |
| TC-RU-03 | 分镜 5 跳过 | skippable 生效 |

## 汇总

| 项目 | 数量 |
|---|---|
| 通用用例 | 8 |
| H-ART-001 | 3 |
| H-MID-001 | 7 |
| H-MA-001 | 8 |
| H-RU-001 | 3 |
| **合计** | **29** |

## 回归顺序

1. H-ART-001（Sprint 1 已过，Sprint 2 冒烟重跑）
2. H-MID-001（新增，重点）
3. H-MA-001（新增，重点，含 R-029 clamp）
4. H-RU-001（Sprint 1 已过，Sprint 2 冒烟重跑）

## 变更日志

- 2024-09-16 D3：29 条用例就位，S2-07 UI 完善后执行
