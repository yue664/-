#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/check_manifest.py — 素材完整性断言（TC-SMOKE-019）
负责人：王码
版本：v0.1（2024-11-19 D5）

断言 assets/manifest.json：
  ① 文件存在且 JSON 可解析
  ② files 段为列表（如存在），逐个断言相对路径文件存在
退出码：全绿 0 / 有红 1
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "assets", "manifest.json")


def main() -> int:
    if not os.path.isfile(MANIFEST):
        print(f"[check_manifest] ❌ assets/manifest.json 不存在")
        return 1
    try:
        with open(MANIFEST, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"[check_manifest] ❌ JSON 解析失败: {e}")
        return 1

    files = data.get("files", [])
    missing = []
    if isinstance(files, list):
        for rel in files:
            if not os.path.isfile(os.path.join(ROOT, rel)):
                missing.append(rel)
    else:
        print(f"[check_manifest] ⚠ files 段非列表（{type(files).__name__}），跳过逐文件断言")

    ok = not missing
    print(f"[check_manifest] {'✅' if ok else '❌'} manifest.json 解析正常 | files {len(files)} 条 | "
          f"缺失 {len(missing)} 条")
    for m in missing[:10]:
        print(f"  ❌ {m}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())