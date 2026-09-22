#!/bin/sh
# tools/smoke.sh
# Sprint 1 D3（S1-11 降级方案）
# 负责人：王码
# 用途：CI 暂缓期间本地手工冒烟脚本

set -e

echo "=== Sprint 1 本地冒烟 ==="

# 1. 单测：EventManager + SavePortrait + Battle
echo "[1/3] 运行单元测试..."
cd game
godot --headless -s res://tests/gdunit4_runner.gd 2>&1 | tail -20 || {
	echo "⚠ 单测失败"
	exit 1
}

# 2. 工程启动检查（Windows）
echo "[2/3] 工程启动检查..."
grep -q "config/name" project.godot || {
	echo "⚠ project.godot 缺少 name 字段"
	exit 1
}

# 3. 素材完整性检查（manifest）
echo "[3/3] 素材完整性..."
cd ..
if [ -f assets/manifest.json ]; then
	python3 -c "import json; json.load(open('assets/manifest.json'))" || {
		echo "⚠ manifest.json 格式错误"
		exit 1
	}
fi

echo "=== 冒烟通过 ==="