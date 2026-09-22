# S10-05 D3 Runner 骨架交付说明（2024-11-15）

- **任务**：S10-05 用例自动化脚本化（400 条并行 45min → 15min，预算 1,000 元）
- **里程碑**：D3 Runner 骨架（单机多进程跑通，演示 3 组并行冒烟）—— **✅ 达成**
- **负责人**：王码（主程）
- **关联风险**：R-050（自动化脚本化延期，D3 节点无延期）

---

## 一、交付物

| 文件 | 说明 |
|---|---|
| `tools/test_runner.py`（新增） | Runner 主脚本：分组/分片参数 + 多进程并行 + 结果聚合 + JSON 落盘 |
| 本说明文档 | D3 交付凭证 |

## 二、实现要点（对齐拆分方案 v0.1）

1. **分组映射**：GROUPS 字典直接按 D2 定稿的映射表 v0.1 四组（P0/P1/P2/P3）挂载现有 GDScript 单测。
   - P0：test_event_manager.gd（TC-VAL/H 事件）+ test_battle_system.gd（TC-BATTLE）
   - P1：test_save_portrait.gd（TC-SAVE）
   - P2：test_add_stat.gd（数值 clamp 边界）
   - P3：空组（D4 挂接 TC-CLOUD/TC-COMPAT）
2. **分片参数**：`--group P0 --shard 1/2` 形式，CI 侧按 shard 分发；`--shards N` 一组内自动切分。
3. **并行执行**：ThreadPoolExecutor 多 worker 并行起 godot 子进程，互不阻塞。
4. **结果聚合**：每分片输出 `result_{group}_{shard}.json`，控制台打点 + JSON 落盘（CI 收集用）。
5. **失败传播**：子进程退出码非 0 → 该条 FAIL → all_passed=False → 整体 exit 1（CI 红线）。

## 三、验证记录（mock 模式）

环境无 godot 可执行文件，用 mock godot 脚本验证调度层（并行/分片/聚合/失败传播）逻辑：

| 场景 | 命令 | 结果 |
|---|---|---|
| 全组并行 2 分片 | `--all --shards 2` | ✅ 4 组并行 1.03s，JSON 聚合正确 |
| 失败传播 | `--group P0 --shard 2/2`（mock 返回 FAIL）| ✅ exit=1，all_passed=False，summary 9/10 正确标记 |

> 注：mock 仅验证调度层；真实单测执行需 godot 可执行文件，D4 接入 CI 时以实机为准（与 D2"以实机复测为准"证据标准一致）。

## 四、D4 待办

- [ ] 接入 CI 分支：真实 godot 跑通 P0/P1/P2 现有单测
- [ ] 用例清单 JSON 化：从 testing/测试用例.md 生成 TC 清单（400 条），替换硬编码 GROUPS
- [ ] TC-CLOUD-001~005 挂接（P3 组，与陈验协作）
- [ ] 失败重试 1 次（区分 flaky 与真失败）

## 变更记录

- 2024-11-15：Runner 骨架落盘 + mock 验证通过（王码），D3 里程碑达成，R-050 应对进度正常。