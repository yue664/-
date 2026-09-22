#!/usr/bin/env python3
"""
voice_generator.py — H 事件语音批量生成工具
维护人：王码
版本：v0.1（Sprint 0 D5 骨架）

用法：
    # 生成单个事件
    python tools/voice_generator.py --event H-ART-001

    # 强制覆盖已存在的 mp3
    python tools/voice_generator.py --event H-ART-001 --force

    # 批量生成所有事件（跳过无 dialog.json 的）
    python tools/voice_generator.py --all

依赖：
    pip install edge-tts

设计：
    - 读 assets/events/*/H-XXX-001/dialog.json
    - 按 speaker 匹配音色 ID
    - 支持 dialog.json 里每句的 "tts" 字段（pitch/rate/volume 情绪参数）
    - 输出 mp3 到 assets/events/{char}/H-XXX-001/audio/se/
    - 后续赵画可用 ffmpeg 批量转 ogg（audio 优化方案对齐）
"""

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path

try:
    import edge_tts
except ImportError:
    print("[ERROR] edge-tts not installed. Run: pip install edge-tts", file=sys.stderr)
    sys.exit(1)


# 角色音色映射（与 docs/tech/TTS调研.md 对齐）
VOICE_MAP = {
    "凯尔": "zh-CN-YunjianNeural",
    "主角": "zh-CN-YunjianNeural",
    "Artesia": "zh-CN-XiaoxiaoNeural",
    "Marina": "zh-CN-XiaoyiNeural",
    "Mei": "zh-CN-XiaohanNeural",
    "Rushena": "zh-CN-XiaoshuangNeural",
    "Meido": "zh-CN-XiaozhenNeural",
    "旁白": "zh-CN-YunxiNeural",
    "系统": "zh-CN-YunxiNeural",
}

DEFAULT_VOICE = "zh-CN-YunxiNeural"

# 默认情绪参数（按 expression 匹配）
EXPRESSION_TUNING = {
    "neutral": {"pitch": "+0Hz", "rate": "+0%", "volume": "+0%"},
    "smile": {"pitch": "+2Hz", "rate": "+5%", "volume": "+0%"},
    "blush": {"pitch": "+2Hz", "rate": "-10%", "volume": "-15%"},
    "pleasure": {"pitch": "+4Hz", "rate": "-20%", "volume": "+10%"},
    "mouth_open": {"pitch": "+4Hz", "rate": "-20%", "volume": "+5%"},
    "sigh_blush": {"pitch": "+2Hz", "rate": "-15%", "volume": "-10%"},
    "surprised": {"pitch": "+3Hz", "rate": "+15%", "volume": "+10%"},
}

# 项目根
ROOT = Path(__file__).parent.parent
ASSETS = ROOT / "assets" / "events"


def find_event_dirs(event_id=None, all_events=False):
    """查找 dialog.json 所在目录"""
    if not ASSETS.exists():
        print(f"[ERROR] assets/events not found: {ASSETS}", file=sys.stderr)
        sys.exit(1)
    if event_id:
        target = ASSETS / event_id.lower().split("-")[1] / event_id / "dialog.json"
        if not target.exists():
            print(f"[ERROR] dialog.json not found: {target}", file=sys.stderr)
            sys.exit(1)
        return [target.parent]
    if all_events:
        return [p.parent for p in ASSETS.glob("*/H-*/dialog.json")]
    return []


def resolve_tts_params(line):
    """从 dialog 行提取 TTS 参数（显式 tts 字段优先，否则按 expression 兜底）"""
    explicit = line.get("tts", {})
    expression = line.get("expression", "neutral")
    default = EXPRESSION_TUNING.get(expression, EXPRESSION_TUNING["neutral"])
    return {
        "pitch": explicit.get("pitch", default["pitch"]),
        "rate": explicit.get("rate", default["rate"]),
        "volume": explicit.get("volume", default["volume"]),
    }


async def generate_line(event_dir, scene_id, line_idx, line):
    speaker = line.get("speaker", "")
    text = line.get("text", "").strip()
    if not text:
        return None
    voice = VOICE_MAP.get(speaker, DEFAULT_VOICE)
    params = resolve_tts_params(line)

    out_dir = event_dir / "audio" / "se"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{event_dir.name}_{scene_id:02d}_{line_idx:03d}.mp3"

    # 跳过系统提示行（不生成语音）
    if speaker in ("系统",):
        return None
    # 跳过分镜/旁白（可选）
    if line.get("narration_skip", False):
        return None

    if out_path.exists():
        print(f"  [skip] {out_path.name} exists")
        return None

    communicate = edge_tts.Communicate(
        text,
        voice,
        pitch=params["pitch"],
        rate=params["rate"],
        volume=params["volume"],
    )
    await communicate.save(str(out_path))
    size_kb = out_path.stat().st_size / 1024
    print(f"  [gen]  {out_path.name} ({size_kb:.1f} KB) - {speaker}: {text[:30]}")
    return out_path


async def process_event(event_dir, force=False):
    dialog_path = event_dir / "dialog.json"
    if not dialog_path.exists():
        print(f"[skip] no dialog.json in {event_dir}")
        return
    print(f"\n[EVENT] {event_dir.name}")
    with open(dialog_path, "r", encoding="utf-8") as f:
        dialog = json.load(f)
    scenes = dialog.get("scenes", [])
    total = 0
    for scene in scenes:
        scene_id = scene.get("scene_id", 0)
        for i, line in enumerate(scene.get("dialog", [])):
            result = await generate_line(event_dir, scene_id, i, line)
            if result:
                total += 1
    print(f"  [done] {total} audio files generated for {event_dir.name}")


def main():
    parser = argparse.ArgumentParser(description="H 事件语音批量生成工具")
    parser.add_argument("--event", help="事件 ID，如 H-ART-001")
    parser.add_argument("--all", action="store_true", help="生成所有事件")
    parser.add_argument("--force", action="store_true", help="强制覆盖已存在的 mp3")
    args = parser.parse_args()

    if not args.event and not args.all:
        parser.print_help()
        sys.exit(1)

    dirs = find_event_dirs(args.event, args.all)
    if not dirs:
        print("[warn] no events found")
        sys.exit(0)

    for d in dirs:
        asyncio.run(process_event(d, force=args.force))


if __name__ == "__main__":
    main()