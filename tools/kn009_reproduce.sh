#!/bin/sh
# tools/kn009_reproduce.sh
# Sprint 2 D2（S2-08a）
# 负责人：陈验
# 用途：KN-009 战斗回合切换偶现卡死复现脚本
# 策略：连续跑 10 场战斗，统计 turn_started 信号丢失情况

set -e

echo "=== KN-009 复现脚本 ==="
echo "策略：10 场连续战斗，检查 turn_started 信号计数"
echo

# 生成测试战斗数据
mkdir -p /tmp/kn009_logs

PASS=0
FAIL=0

for i in $(seq 1 10); do
	echo "=== 第 $i / 10 场 ==="
	LOG="/tmp/kn009_logs/battle_$i.log"

	# 运行单场战斗（王码 BattleSystem + BattleScene）
	# 用 gdunit4 触发 start_battle → player_attack → _enemy_turn 循环
	if godot --headless -s res://tests/test_battle_system.gd --args single=$i 2>&1 > "$LOG"; then
		# 统计 turn_started 信号
		ACTUAL=$(grep -c "turn_started" "$LOG" || echo 0)
		EXPECTED=$(grep -c "EXPECTED_TURN" "$LOG" || echo 0)
		if [ "$ACTUAL" -ge "$EXPECTED" ] && [ "$EXPECTED" -gt 0 ]; then
			echo "  ✅ 第 $i 场通过（turn_started: $ACTUAL / $EXPECTED）"
			PASS=$((PASS + 1))
		else
			echo "  ❌ 第 $i 场失败（turn_started: $ACTUAL / $EXPECTED）"
			FAIL=$((FAIL + 1))
		fi
	else
		echo "  ❌ 第 $i 场异常退出"
		FAIL=$((FAIL + 1))
	fi
done

echo
echo "=== 汇总 ==="
echo "通过: $PASS / 10"
echo "失败: $FAIL / 10"

if [ "$FAIL" -gt 0 ]; then
	echo "⚠ KN-009 复现！登记 BUG-BATTLE-001"
	exit 1
else
	echo "✅ KN-009 未复现，持续监控"
	exit 0
fi