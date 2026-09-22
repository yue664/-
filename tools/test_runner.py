#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/test_runner.py — S10-05 用例自动化 Runner（D5 v0.3 清单驱动，exec 去重）
负责人：王码
版本：v0.3（2024-11-19 D5）

v0.1（D3）：单机多进程并行 + 分组/分片参数 + 结果聚合（4 个 GDScript 硬编码）。
v0.2（D5）：改为读 tools/tc_manifest.json 清单驱动。
v0.3（D5）：修复执行语义 bug（陈验 400 口径复核抓出）——
  - expand_entries 按 exec 去重：每个唯一执行体跑 1 次，covered_count 累计覆盖条数
  - JSON 拆分 exec_count（执行体数）/ covered_count（覆盖用例数），分开报
  - 15min 对账用执行体耗时（真实 ~46s），覆盖条数单列，不混
  - 补 mixed 执行体（TC-V12 存量，复用 lint）
  - GROUPS 不再硬编码，按 manifest.groups[组].entries 展开
  - 每个 entry 的 exec 字段解析为真实执行体：
      gd:test_xxx        -> godot --headless --script res://tests/test_xxx.gd
      smoke              -> godot --headless --path game --run-tests --quit
      manifest_check     -> python3 tools/check_manifest.py（manifest.json 完整性）
      file_check:audio   -> python3 tools/check_files.py audio（语音/音频文件存在性）
      file_check:voice   -> python3 tools/check_files.py voice
      asset_3d           -> python3 tools/check_3d_assets.py（立绘/模型路径断言）
      benchmark          -> godot --headless --benchmark（耗时断言）
      gallery_check      -> python3 tools/check_gallery.py --strict（TC-GALLERY 四连）
      lint               -> python3 tools/lint.py（词条 lint CI 原生）
      manual             -> 不挂接（C 类手工，hook=false）
  - 统计 A+B 挂接率（hook=true 的 A/B 条数 / A+B 总数），对账 15min 目标
  - gallery_assert.strict_required=true 时 gallery_check 强制 --strict（陈验红线）

用法：
  python3 tools/test_runner.py --all --shards 2            # 全部四组并行
  python3 tools/test_runner.py --group P0 --shard 1/2      # CI 单分片
  python3 tools/test_runner.py --all --shards 2 --json out/all.json
  python3 tools/test_runner.py --dry-run                    # 只打印清单不执行
"""

import argparse
import json
import os
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME_DIR = os.path.join(ROOT, "game")
MANIFEST_PATH = os.path.join(ROOT, "tools", "tc_manifest.json")
GODOT_BIN = os.environ.get("GODOT_BIN", "godot")

# 执行体 -> 命令构造器（返回 argv 列表）
EXEC_BUILDERS = {
    # 注：run_cmd 用 cwd=ROOT 执行，--path 必须指向 game/ 否则 res:// 指向仓库根，
    # res://tests/*.gd 找不到脚本（与 smoke/benchmark 保持一致）
    "gd": lambda spec: [GODOT_BIN, "--headless", "--path", "game", "--script", f"res://tests/{spec}.gd"],
    "smoke": lambda _: [GODOT_BIN, "--headless", "--path", "game", "--run-tests", "--quit"],
    "manifest_check": lambda _: [sys.executable, "tools/check_manifest.py"],
    "file_check": lambda spec: [sys.executable, "tools/check_files.py", spec],
    "asset_3d": lambda _: [sys.executable, "tools/check_3d_assets.py"],
    "benchmark": lambda _: [GODOT_BIN, "--headless", "--path", "game", "--benchmark"],
    "gallery_check": lambda _: [sys.executable, "tools/check_gallery.py", "--strict"],
    "lint": lambda _: [sys.executable, "tools/lint.py"],
    "mixed": lambda _: [sys.executable, "tools/lint.py"],  # TC-V12 存量：词条/数值类，复用 lint 执行体
}


def load_manifest() -> dict:
    with open(MANIFEST_PATH, encoding="utf-8") as f:
        return json.load(f)


def build_cmd(exec_spec: str, group: str) -> list:
    """按 exec 字段构造真实命令。exec 形如 'gd:test_xxx' / 'file_check:audio' / 'smoke'。"""
    if ":" in exec_spec:
        kind, spec = exec_spec.split(":", 1)
    else:
        kind, spec = exec_spec, ""
    builder = EXEC_BUILDERS.get(kind)
    if not builder:
        raise ValueError(f"未知执行体类型: {exec_spec}（组 {group}）")
    return builder(spec)


def run_cmd(cmd: list, label: str, timeout: int = 300) -> dict:
    start = time.time()
    try:
        proc = subprocess.run(
            cmd, cwd=ROOT, capture_output=True, text=True, timeout=timeout
        )
        elapsed = round(time.time() - start, 2)
        output = (proc.stdout or "") + (proc.stderr or "")
        return {
            "label": label,
            "cmd": " ".join(cmd),
            "passed": proc.returncode == 0,
            "returncode": proc.returncode,
            "elapsed": elapsed,
            "tail": output[-2000:],
        }
    except subprocess.TimeoutExpired:
        return {
            "label": label, "cmd": " ".join(cmd),
            "passed": False, "returncode": -1,
            "elapsed": round(time.time() - start, 2),
            "tail": "TIMEOUT",
        }


def expand_entries(manifest: dict, group: str) -> list:
    """返回按 exec 去重后的执行条目列表（hook=true 的才有 exec）。

    v0.3 修复（陈验 400 口径复核抓出的执行语义 bug）：
      v0.2 把 count=N 展开成 N 个同命令条目 → 168 条 hook 跑 168 次、
      唯一执行体仅 15 个，假耗时 ~530s vs 真实 ~46s，15min 对账失真。
      现按 exec 去重：每个唯一执行体 1 条，covered_count 累计覆盖条数。
    """
    entries = manifest["groups"][group]["entries"]
    merged: dict = {}
    for e in entries:
        if not e.get("hook", False):
            continue
        key = e["exec"]
        count = e.get("count", 1)
        if key in merged:
            merged[key]["covered_count"] += count
        else:
            merged[key] = {
                "label": e["prefix"],
                "tier": e["tier"],
                "exec": e["exec"],
                "covered_count": count,
            }
    return list(merged.values())


def run_group(manifest: dict, group: str, shards: int = 1, shard_index: int = 0) -> dict:
    """运行一个组的分片，返回聚合结果。"""
    items = expand_entries(manifest, group)
    if not items:
        return {"group": group, "passed": True, "results": [], "note": "空组（无挂接条目）",
                "shard": f"{shard_index + 1}/{shards}", "items_count": 0, "elapsed": 0.0}

    my_items = items[shard_index::shards] if shards > 1 else items
    results = []
    for it in my_items:
        cmd = build_cmd(it["exec"], group)
        results.append(run_cmd(cmd, it["label"]))

    passed = all(r["passed"] for r in results)
    total_elapsed = round(sum(r["elapsed"] for r in results), 2)
    return {
        "group": group,
        "passed": passed,
        "shard": f"{shard_index + 1}/{shards}",
        "results": results,
        "exec_count": len(my_items),          # 本分片实际执行的执行体数
        "covered_count": sum(it["covered_count"] for it in my_items),  # 覆盖的用例条数
        "elapsed": total_elapsed,
    }


def stats(manifest: dict) -> dict:
    """A/B/C 分档 + 挂接率统计（对账口径：A+B 全量挂接 ≥90%）。"""
    s = {"A": 0, "B": 0, "C": 0, "A_hooked": 0, "B_hooked": 0}
    for g in manifest["groups"].values():
        for e in g["entries"]:
            tier = e["tier"]
            count = e.get("count", 1)
            if tier in ("A", "B", "C"):
                s[tier] += count
                if e.get("hook", False):
                    s[f"{tier}_hooked"] += count
            elif tier == "MIX":
                # TC-V12 存量：按 60/40 拆 A/B（映射表 v0.2 口径，逐条拆）
                a_part = int(count * 0.6)
                b_part = count - a_part
                s["A"] += a_part
                s["B"] += b_part
                if e.get("hook", False):
                    s["A_hooked"] += a_part
                    s["B_hooked"] += b_part
    total_ab = s["A"] + s["B"]
    hooked_ab = s["A_hooked"] + s["B_hooked"]
    rate = (hooked_ab / total_ab * 100) if total_ab else 0.0
    return {**s, "A_plus_B": total_ab, "hooked_AB": hooked_ab, "rate_pct": round(rate, 1)}


def main() -> int:
    parser = argparse.ArgumentParser(description="S10-05 用例自动化 Runner v0.2 清单驱动")
    parser.add_argument("--group", choices=["P0", "P1", "P2", "P3"], help="指定运行哪一组")
    parser.add_argument("--all", action="store_true", help="运行全部四组")
    parser.add_argument("--shards", type=int, default=1, help="每组内分片数（默认 1）")
    parser.add_argument("--shard", default=None, help="当前进程分片，如 1/3")
    parser.add_argument("--json", default=None, help="结果输出 JSON 路径（可选）")
    parser.add_argument("--dry-run", action="store_true", help="只打印清单不执行")
    args = parser.parse_args()

    manifest = load_manifest()
    st = stats(manifest)
    print(f"[test_runner] manifest v{manifest['manifest_version']} | "
          f"A {st['A']}(挂 {st['A_hooked']}) B {st['B']}(挂 {st['B_hooked']}) "
          f"C {st['C']} | A+B {st['A_plus_B']} 挂接 {st['hooked_AB']} 条 "
          f"挂接率 {st['rate_pct']}% (目标 ≥90%)")

    if args.dry_run:
        print("=" * 60)
        for g in manifest["groups"]:
            items = expand_entries(manifest, g)
            print(f"  [{g}] 挂接 {len(items)} 条目")
            for it in items[:5]:
                print(f"      - {it['label']}: {it['exec']}")
            if len(items) > 5:
                print(f"      ... 等共 {len(items)} 条")
        return 0

    if args.shard:
        idx_str, total_str = args.shard.split("/")
        shard_index, shards = int(idx_str) - 1, int(total_str)
        is_single_shard = True
    else:
        shard_index, shards = 0, args.shards
        is_single_shard = False

    groups_to_run = list(manifest["groups"].keys()) if args.all else [args.group]

    tasks = []
    for g in groups_to_run:
        if is_single_shard:
            tasks.append((g, shard_index))
        else:
            for s in range(shards):
                tasks.append((g, s))

    start_all = time.time()
    with ThreadPoolExecutor(max_workers=max(4, len(tasks))) as pool:
        futures = {pool.submit(run_group, manifest, g, shards, s): (g, s) for (g, s) in tasks}
        results = {}
        for fut in as_completed(futures):
            g, s = futures[fut]
            results[f"{g}/shard{s + 1}"] = fut.result()
    total_elapsed = round(time.time() - start_all, 2)

    all_passed = all(r.get("passed", False) for r in results.values())
    hooked_ok = st["rate_pct"] >= 90

    # 全局汇总（跨分片加总，而非取单个分片）
    total_exec = sum(r.get("exec_count", 0) for r in results.values())
    total_covered = sum(r.get("covered_count", 0) for r in results.values())

    print("=" * 60)
    print(f"[test_runner] 组: {groups_to_run} | 分片: {shard_index + 1}/{shards}")
    for g, r in results.items():
        status = "✅ PASS" if r.get("passed") else "❌ FAIL"
        print(f"  [{g}] {status} | 执行体 {r.get('exec_count', 0)} | 覆盖 {r.get('covered_count', 0)} 条 | {r.get('elapsed', 0)}s")
        for res in r.get("results", []):
            print(f"      - {res['label']}: {'✅' if res['passed'] else '❌'} {res['elapsed']}s | {res['cmd']}")
    print(f"[test_runner] 总耗时: {total_elapsed}s | 整体: {'✅ ALL PASSED' if all_passed else '❌ FAILED'}")
    print(f"[test_runner] 执行体 {total_exec} 个 | 覆盖 {total_covered} 条 | "
          f"A+B 挂接率 {st['rate_pct']}% (目标 ≥90%) → "
          f"{'✅ 达标' if hooked_ok else '❌ 未达标'}")
    print("=" * 60)

    if args.json:
        os.makedirs(os.path.dirname(args.json) or ".", exist_ok=True)
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({
                "manifest_version": manifest["manifest_version"],
                "stats": st,
                "hooked_rate_ok": hooked_ok,
                "exec_count": total_exec,
                "covered_count": total_covered,
                "groups": results,
                "all_passed": all_passed,
                "total_elapsed": total_elapsed,
                "ts": time.strftime("%Y-%m-%d %H:%M:%S"),
            }, f, ensure_ascii=False, indent=2)
        print(f"[test_runner] JSON 已写入: {args.json}")

    return 0 if (all_passed and hooked_ok) else 1


if __name__ == "__main__":
    sys.exit(main())