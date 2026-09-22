#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/aggregate_results.py — S10-05 分片结果聚合（CI unit-aggregate job 用）
负责人：王码（v0.1）/ 周野（v0.2 字段补齐）
版本：v0.2（2024-11-19 D5）

v0.1（D4）：合并分片 JSON groups + all_passed + total_elapsed + shard_files。
v0.2（D5）：补齐顶层字段以适配 runner v0.3——
  - 合并 exec_count（执行体数）/ covered_count（覆盖条数）
  - 合并 manifest_version / hooked_rate_ok / stats
  - 输出可读摘要（"执行体 N / 覆盖 M 条"），便于 CI 日志直接读

用法：
  python3 tools/aggregate_results.py --input out/ --output out/aggregate.json
  默认从当前目录的 out/ 下读取 */*.json（含子目录，CI artifact 下载结构），
  合并后写 aggregate.json，整体失败时 exit 1（CI 门禁）。
"""

import argparse
import glob
import json
import os
import sys
import time


def collect(files):
    """合并多个分片 JSON，返回聚合 dict。

    v0.2：顶层字段除 groups/all_passed/total_elapsed 外，
    额外汇总 exec_count（执行体数）/ covered_count（覆盖条数），
    并透传 manifest_version / hooked_rate_ok / stats（取首个非空分片的值）。
    """
    merged = {
        "groups": {},
        "all_passed": True,
        "total_elapsed": 0.0,
        "exec_count": 0,
        "covered_count": 0,
        "manifest_version": None,
        "hooked_rate_ok": None,
        "stats": None,
    }
    for fp in sorted(files):
        try:
            with open(fp, encoding="utf-8") as f:
                data = json.load(f)
        except (json.JSONDecodeError, OSError) as e:
            print(f"[aggregate] WARN 跳过 {fp}: {e}")
            continue
        # 顶层分片元数据（runner v0.3 输出）
        merged["exec_count"] += data.get("exec_count", 0)
        merged["covered_count"] += data.get("covered_count", 0)
        if merged["manifest_version"] is None:
            merged["manifest_version"] = data.get("manifest_version")
        if merged["hooked_rate_ok"] is None:
            merged["hooked_rate_ok"] = data.get("hooked_rate_ok")
        if merged["stats"] is None:
            merged["stats"] = data.get("stats")
        # 分片组内字段（v0.3：每组也有 exec_count/covered_count）
        for key, r in data.get("groups", {}).items():
            # 同名 key 覆盖：取最新（shard 粒度 key 如 P0/shard1 不会重复）
            merged["groups"][key] = r
            merged["all_passed"] = merged["all_passed"] and r.get("passed", False)
            merged["total_elapsed"] += r.get("elapsed", 0.0)
    merged["shard_files"] = len(files)
    merged["ts"] = time.strftime("%Y-%m-%d %H:%M:%S")
    return merged


def main() -> int:
    parser = argparse.ArgumentParser(description="S10-05 分片结果聚合")
    parser.add_argument("--input", default="out", help="分片 JSON 目录（递归）")
    parser.add_argument("--output", default="out/aggregate.json", help="聚合输出路径")
    args = parser.parse_args()

    pattern = os.path.join(args.input, "**", "*.json")
    # 排除聚合输出本身 + 备份类文件（bak_*/backup_*），避免 glob 扫入非分片产物
    out_abs = os.path.abspath(args.output)
    files = [
        f for f in glob.glob(pattern, recursive=True)
        if os.path.abspath(f) != out_abs
        and not os.path.basename(f).startswith(("bak_", "backup_", "aggregate"))
    ]
    if not files:
        print(f"[aggregate] ERROR 未找到分片 JSON（{pattern}）")
        return 1

    merged = collect(files)
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)

    print(f"[aggregate] 合并 {merged['shard_files']} 个分片 | 组数 {len(merged['groups'])} | "
          f"执行体 {merged['exec_count']} / 覆盖 {merged['covered_count']} 条 | "
          f"总耗时 {round(merged['total_elapsed'], 2)}s | 整体: "
          f"{'ALL PASSED' if merged['all_passed'] else 'FAILED'}")
    print(f"[aggregate] 输出: {args.output}")
    return 0 if merged["all_passed"] else 1


if __name__ == "__main__":
    sys.exit(main())