# Sprint 1 战斗测试用例（S1-08b）

> 负责人：陈验
> Sprint 1 D2
> 覆盖：BattleSystem.gd 骨架 + 回合逻辑 + 信号
> 目标：10 条 TC-BATTLE-xxx，覆盖分支 + 边界 + 幂等

## 用例清单

| ID | 场景 | 前置 | 操作 | 预期 | 优先级 |
|---|---|---|---|---|---|
| TC-BATTLE-001 | 战斗初始化 | BattleSystem 挂载 | start_battle(player, enemy) | current_phase=PLAYER_TURN, turn_count=1, turn_started 信号触发 | P0 |
| TC-BATTLE-002 | 玩家攻击扣血 | 初始化完成 | player_attack("enemy") | enemy.current_hp 减少, hp_changed 信号触发 | P0 |
| TC-BATTLE-003 | 敌方回合自动执行 | 玩家攻击后 | （自动） | current_phase 切 ENEMY_TURN→PLAYER_TURN, turn_count+1 | P0 |
| TC-BATTLE-004 | 敌方死亡触发 WIN | enemy.current_hp=1 | player_attack("enemy") | battle_ended 信号 Phase.WIN | P0 |
| TC-BATTLE-005 | 玩家死亡触发 LOSE | player.current_hp=1 | 敌方回合 | battle_ended 信号 Phase.LOSE | P0 |
| TC-BATTLE-006 | 非玩家回合攻击被拒 | current_phase=ENEMY_TURN | player_attack("enemy") | 无操作，不扣血 | P1 |
| TC-BATTLE-007 | 伤害下限保护 | attacker.atk=0, def=0 | player_attack | 伤害 >= 1（不出现 0 伤害） | P1 |
| TC-BATTLE-008 | 伤害波动范围 | atk=20, def=0 | 连续 10 次攻击 | 每次伤害 ∈ [18,22] | P1 |
| TC-BATTLE-009 | 战斗结束后再攻击被拒 | battle_ended WIN 后 | player_attack | 无操作，phase 不变 | P1 |
| TC-BATTLE-010 | HP 不为负 | enemy.current_hp=3, dmg=10 | player_attack | current_hp=0，非负数 | P2 |

## 关联

- Sprint 0 单测基线 20 条（event_manager + save_portrait）+ Sprint 1 新增 10 条 = 30 条
- 覆盖率目标：BattleSystem 分支覆盖 100%，行覆盖 >= 90%
- KN-009 复现方式：连续打 5 场战斗，看 turn_started 信号是否有丢失

## 变更日志

- 2024-09-10 D2：陈验设计 10 条 TC-BATTLE 用例，同步为 test_battle_system.gd