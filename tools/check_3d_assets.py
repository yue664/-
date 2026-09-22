#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/check_3d_assets.py — 3D 立绘/模型路径断言（TC-3D-001~008 / TC-SMOKE-011~018）
负责人：王码
版本：v0.1（2024-11-19 D5）

读 assets/cg_2d/asset_map_v0.1.json 的 entries（角色目录 + webp 路径），
逐条断言：
  ① 角色目录 assets/events/{char_dir}/ 存在（3D 立绘/模型挂载目录）
  ② webp_path 指向文件存在（2D 立绘）
  ③ char_dir 目录内至少 1 个 .png/.glb/.tres 文件（模型/立绘资源）

退出码：全绿 0 / 有红 1
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSET_MAP = os.path.join(ROOT, "assets", "cg_2d", "asset_map_v0.1.json")


def main() -> int:
    if not os.path.isfile(ASSET_MAP):
        print(f"[check_3d] ❌ asset_map_v0.1.json 不存在（{ASSET_MAP}）")
        return 1

    with open(ASSET_MAP, encoding="utf-8") as f:
        data = json.load(f)

    entries = data.get("entries", [])
    failures = []
    checked = 0
    for e in entries:
        char_dir = e.get("char_dir", "")
        webp = e.get("webp_path", "")
        checked += 1
        # ① 角色目录存在
        d_abs = os.path.join(ROOT, "assets", "events", char_dir)
        if not os.path.isdir(d_abs):
            failures.append(f"{char_dir or '(空)'}: 角色目录缺失")
            continue
        # ② webp 路径存在（2D）
        if webp and not os.path.isfile(os.path.join(ROOT, webp)):
            failures.append(f"{webp}: 2D 立绘缺失")
        # ③ 模型/立绘资源（png/glb/tres）至少 1 个
        assets = [
            f for f in os.listdir(d_abs)
            if f.lower().endswith((".png", ".glb", ".tres"))
        ]
        if not assets:
            failures.append(f"{char_dir}: 无模型/立绘资源")

    ok = not failures
    print(f"[check_3d] 检查 {checked} 条 entry | {'✅ 全绿' if ok else '❌ ' + str(len(failures)) + ' 条失败'}")
    for f in failures[:10]:
        print(f"  ❌ {f}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())