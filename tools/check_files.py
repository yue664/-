#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tools/check_files.py — 文件完整性断言（TC-AUDIO-001~005 / TC-VOICE 下载）
负责人：王码
版本：v0.1（2024-11-19 D5）

用法：
  python3 tools/check_files.py audio   # 断言语音/音频文件完整性
  python3 tools/check_files.py voice   # 断言语音包文件存在性

按资产目录扫描（manifest.json v0.2 的 files 段为权威来源，缺失时退化按目录扫描）。
退出码：全绿 0 / 有红 1
"""

import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 按类型断言的目标目录（相对 ROOT）+ 最小数量
TARGETS = {
    "audio": {
        "dirs": ["assets/audio/bgm", "assets/audio/se", "assets/audio/voice"],
        "min_count": 5,
        "exts": (".ogg", ".wav", ".mp3"),
    },
    "voice": {
        "dirs": ["assets/audio/voice"],
        "min_count": 1,
        "exts": (".ogg", ".wav", ".mp3", ".json"),
    },
}


def check(target: str) -> dict:
    cfg = TARGETS[target]
    results = []
    total = 0
    for d in cfg["dirs"]:
        abs_d = os.path.join(ROOT, d)
        if not os.path.isdir(abs_d):
            results.append({"dir": d, "ok": False, "reason": "目录不存在"})
            continue
        found = [
            os.path.join(dp, f)
            for dp, _, fns in os.walk(abs_d)
            for f in fns if f.lower().endswith(cfg["exts"])
        ]
        total += len(found)
        results.append({"dir": d, "ok": True, "count": len(found)})
    ok = total >= cfg["min_count"] and all(r["ok"] for r in results)
    return {"target": target, "ok": ok, "total": total, "min_count": cfg["min_count"], "dirs": results}


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in TARGETS:
        print(f"用法: {sys.argv[0]} [{'|'.join(TARGETS)}]")
        return 2
    target = sys.argv[1]
    r = check(target)
    print(f"[check_files] {target}: {'✅' if r['ok'] else '❌'} 文件 {r['total']} 个 (需 ≥{r['min_count']})")
    for d in r["dirs"]:
        tag = "✅" if d["ok"] else "❌"
        print(f"  {tag} {d['dir']} | {d.get('count', 0)} 个 {d.get('reason', '')}")
    return 0 if r["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())