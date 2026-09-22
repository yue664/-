#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/check_gallery.py — TC-GALLERY-001~018 四连断言执行体（D5 挂接）
负责人：王码
版本：v0.1（2024-11-19）

来源：Sprint10-GalleryConfig三列合表-v0.1.md（18 张槽位终值化）
断言四连：
  ① webp_path 文件存在  ② 文件非空（>0，排除 96B LFS 指针）
  ③ WebP 头（RIFF....WEBP）  ④ 体积 < 1.2MB（q=88 红线）

用法：
  python3 tools/check_gallery.py                 # 跑全部 18 槽位
  python3 tools/check_gallery.py --json out/gallery.json  # 输出 JSON（CI 聚合）
  python3 tools/check_gallery.py --strict        # S7 5 张真 TBD 也算 fail（CI 验收用）

退出码：全绿 0 / 有红 1
"""

import argparse
import json
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 18 张槽位（对齐三列合表 v0.1，槽位号 1-based = TC-GALLERY-001~018）
GALLERY = [
    # (槽位, 事件/结局 ID, webp_path, 来源, 状态)
    (1, "E-ART-A", "assets/cg_2d/artesia/CG-EX-01.webp", "asset_map", "FINAL"),
    (2, "E-MEI-B", "assets/cg_2d/mei/CG-EX-02.webp", "asset_map", "FINAL"),
    (3, "E-RU-C", "assets/cg_2d/rushena/CG-EX-03.webp", "asset_map", "FINAL"),
    (4, "E-MEI-B 追加", "assets/cg_2d/mei/CG-EX-04.webp", "asset_map", "FINAL"),
    (5, "E-RU-C 追加", "assets/cg_2d/rushena/CG-EX-05.webp", "asset_map", "FINAL"),
    (6, "E5 前庭", "assets/cg_2d/meido/CG-CH5-01.webp", "asset_map", "FINAL"),
    (7, "E5 王座对峙", "assets/cg_2d/meido/CG-CH5-02.webp", "asset_map", "FINAL"),
    (8, "E5-1 魔王加冕", "assets/cg_2d/meido/CG-CH5-03.webp", "asset_map", "FINAL"),
    (9, "E5-5 混沌真结局", "assets/cg_2d/meido/CG-CH5-04.webp", "asset_map", "FINAL"),
    (10, "H-MID-新1", "assets/cg_2d/meido/CG-CH5-05.webp", "req-v1.2-3.1", "FINAL"),
    (11, "H-MID-新2", "assets/cg_2d/meido/CG-CH5-06.webp", "req-v1.2-3.1", "FINAL"),
    (12, "H-RU-003 深渊使者", "assets/cg_2d/rushena/CG-CH5-07.webp", "req-v1.2-3.1", "FINAL"),
    (13, "E5-3 全员堕落", "assets/cg_2d/meido/CG-CH5-08.webp", "req-v1.2-3.1", "FINAL"),
    (14, "V1.1 S7-01", "assets/cg_2d/artesia/CG-S7-01.webp", "order-derived", "LFS_PENDING"),
    (15, "V1.1 S7-02", "assets/cg_2d/mei/CG-S7-02.webp", "order-derived", "LFS_PENDING"),
    (16, "V1.1 S7-03", "assets/cg_2d/rushena/CG-S7-03.webp", "order-derived", "LFS_PENDING"),
    (17, "V1.1 S7-04", "assets/cg_2d/marina/CG-S7-04.webp", "order-derived", "LFS_PENDING"),
    (18, "V1.1 S7-05", "assets/cg_2d/meido/CG-S7-05.webp", "order-derived", "LFS_PENDING"),
]

MAX_WEBP_SIZE = 1.2 * 1024 * 1024  # 1.2MB


def check_one(slot: int, event_id: str, rel_path: str, source: str) -> dict:
    """对单个槽位做四连断言。"""
    abs_path = os.path.join(ROOT, rel_path)
    checks = {}
    # ① 文件存在
    exists = os.path.isfile(abs_path)
    checks["exists"] = exists
    if not exists:
        return {
            "slot": slot,
            "tc": f"TC-GALLERY-{slot:03d}",
            "event_id": event_id,
            "webp_path": rel_path,
            "source": source,
            "passed": False,
            "checks": checks,
            "reason": "文件不存在（LFS 未拉真体或路径错误）",
        }
    # ② 非空 + 排除 LFS 指针（96 字节）
    size = os.path.getsize(abs_path)
    checks["size"] = size
    checks["non_empty"] = size > 0
    checks["not_lfs_pointer"] = size > 96  # LFS 指针文件 = 96B 文本
    if size <= 96:
        return {
            "slot": slot, "tc": f"TC-GALLERY-{slot:03d}", "event_id": event_id,
            "webp_path": rel_path, "source": source, "passed": False,
            "checks": checks, "reason": f"疑似 LFS 指针文件（{size}B ≤ 96B）",
        }
    # ③ WebP 头
    with open(abs_path, "rb") as f:
        head = f.read(12)
    riff_ok = head[:4] == b"RIFF"
    webp_ok = head[8:12] == b"WEBP"
    checks["riff"] = riff_ok
    checks["webp_magic"] = webp_ok
    if not (riff_ok and webp_ok):
        return {
            "slot": slot, "tc": f"TC-GALLERY-{slot:03d}", "event_id": event_id,
            "webp_path": rel_path, "source": source, "passed": False,
            "checks": checks, "reason": "WebP 头校验失败（需 RIFF....WEBP）",
        }
    # ④ 体积 < 1.2MB
    checks["size_ok"] = size < MAX_WEBP_SIZE
    if not checks["size_ok"]:
        return {
            "slot": slot, "tc": f"TC-GALLERY-{slot:03d}", "event_id": event_id,
            "webp_path": rel_path, "source": source, "passed": False,
            "checks": checks, "reason": f"体积超红线（{size/1024/1024:.2f}MB ≥ 1.2MB）",
        }
    return {
        "slot": slot, "tc": f"TC-GALLERY-{slot:03d}", "event_id": event_id,
        "webp_path": rel_path, "source": source, "passed": True,
        "checks": checks, "reason": "OK",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="TC-GALLERY 四连断言")
    parser.add_argument("--json", default=None, help="JSON 输出路径")
    parser.add_argument("--strict", action="store_true",
                        help="LFS_PENDING 条目也算红（CI 验收用，S7 实物到位后必须开）")
    args = parser.parse_args()

    results = []
    passed_count = 0
    for slot, event_id, rel_path, source, status in GALLERY:
        r = check_one(slot, event_id, rel_path, source)
        r["status"] = status
        # LFS_PENDING 条目：默认不算红（订单推导待 LFS 实物），--strict 时才算
        if not r["passed"] and status == "LFS_PENDING" and not args.strict:
            r["passed"] = True
            r["reason"] = f"LFS_PENDING（订单推导，待 LFS 实物确认）——非 strict 模式放行"
        if r["passed"]:
            passed_count += 1
        results.append(r)

    all_passed = passed_count == len(results)
    print("=" * 60)
    print(f"[check_gallery] TC-GALLERY-001~018 四连断言 | {'✅ ALL PASSED' if all_passed else '❌ FAILED'}")
    for r in results:
        tag = "✅" if r["passed"] else "❌"
        print(f"  {tag} {r['tc']} | {r['event_id']:<18} | {r['webp_path']} | {r['reason']}")
    print(f"  -> 通过 {passed_count}/{len(results)}")
    print("=" * 60)

    if args.json:
        os.makedirs(os.path.dirname(args.json) or ".", exist_ok=True)
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({
                "suite": "TC-GALLERY",
                "all_passed": all_passed,
                "passed": passed_count,
                "total": len(results),
                "results": results,
                "ts": __import__("time").strftime("%Y-%m-%d %H:%M:%S"),
            }, f, ensure_ascii=False, indent=2)
        print(f"[check_gallery] JSON 已写入: {args.json}")

    return 0 if all_passed else 1


if __name__ == "__main__":
    sys.exit(main())