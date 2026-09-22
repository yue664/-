# 赵画 → 王码：CG 资产对照表 TBD 补全交接单（D5 挂接前）

- **来源**：赵画 D4 机动产出（assets/cg_2d/asset_map_v0.1.json）
- **目的**：TC-GALLERY-001~020（B 类）挂接输入——**9 张已定 + 9 张 TBD 待补**
- **接收人**：王码（D5 全量挂接时从 gallery 配置导出补全）
- **状态**：🟡 9 张 TBD 待补

---

## 一、已定 9 张（可直接断言，无需补）

| gallery_slot | ending_id | webp_path | vendor | status |
|---|---|---|---|---|
| S9-01 | E-ART-A | assets/cg_2d/artesia/CG-EX-01.webp | CielArt | ACCEPTED_VERIFIED |
| S9-02 | E-MEI-B | assets/cg_2d/mei/CG-EX-02.webp | CielArt | ACCEPTED_VERIFIED |
| S9-03 | E-RU-C | assets/cg_2d/rushena/CG-EX-03.webp | CielArt | ACCEPTED_VERIFIED |
| S9-04 | E-MEI-B | assets/cg_2d/mei/CG-EX-04.webp | Indie-H-Comics | ACCEPTED_VERIFIED |
| S9-05 | E-RU-C | assets/cg_2d/rushena/CG-EX-05.webp | Indie-H-Comics | ACCEPTED_VERIFIED |
| S8-01 | E5 前庭 | assets/cg_2d/meido/CG-CH5-01.webp | CielArt | ACCEPTED_VERIFIED |
| S8-02 | E5 王座对峙 | assets/cg_2d/meido/CG-CH5-02.webp | CielArt | ACCEPTED_VERIFIED |
| S8-03 | E5-1 | assets/cg_2d/meido/CG-CH5-03.webp | CielArt | ACCEPTED_VERIFIED |
| S8-04 | E5-5 | assets/cg_2d/meido/CG-CH5-04.webp | CielArt | ACCEPTED_VERIFIED |

## 二、TBD 9 张（需王码 D5 从 gallery 挂接配置导出）

| 需补字段 | 说明 |
|---|---|
| **V1.1 结局画廊 5 张**（S7，CielArt 3 + Indie 2） | **gallery_slot + 事件 ID + 文件名（src_png）+ WebP 路径 + 角色目录**——清单只有"已入廊 5 张"，无精确 CG 文件名 |
| **Sprint 8 Indie 尾包 4 张**（S8-05..08，Indie-H-Comics） | 同上——S8 D8 验收记录确认入廊，但 CG ID（CG-INDIE-*？）在文档未列全 |

**导出来源**：王码 `game/scenes` 或 `scripts` 下画廊挂接配置（GalleryConfig / 15 结局解锁映射表）。我在工作区没定位到该配置文件实体（大概率走 Git LFS 未拉全），**王码 D5 从线上下拉后补三列合表**：

```
gallery_slot | 事件/结局 ID | 实际 webp 路径
```

## 三、D5 挂接断言红线（对齐王码 §六 规格）

1. **只登已验收入廊 CG**——V1.1 5 张 + S8 Indie 4 张确认入廊，补全即入表；未验收的**不写**
2. 逐槽位断言：**① 路径文件存在 ② 文件非空 ③ WebP 头校验（RIFF....WEBP）④ 体积 <1.2MB**（q=88 红线）
3. **Git LFS 拉取步骤**——build.yml unit-test job 需加 `git lfs pull`，否则 `assets/cg_2d/` 下文件不存在 → TC-GALLERY 必假绿（张策 D5 口径已钉死这条）
4. 补全后回填 `asset_map_v0.1.json` 的对应 TBD 条目，status 改 `ACCEPTED_VERIFIED`，赵画复核后 v0.2

## 四、变更记录

- 2024-11-16：交接单落盘（赵画），TBD 9 张待王码 D5 从 gallery 配置导出补全