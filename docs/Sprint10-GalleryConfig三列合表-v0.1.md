# Sprint 10 GalleryConfig 三列合表 v0.1（D5 挂接输入）

- **任务**：S10-05 全量挂接 B 类 TC-GALLERY 输入——gallery_slot | 事件/结局ID | webp 路径
- **负责人**：王码（主程）
- **日期**：2024-11-19（D5）
- **来源**：线上仓库 GalleryConfig（build.yml 所在仓库，CI checkout 天然有源，KN-017 已澄清）+ asset_map_v0.1.json + 需求文档-V1.2.md 3.1 补单清单
- **状态**：✅ v0.1 落盘，18 张槽位全部终值化（去 TBD_ 前缀）

## 一、三列合表（18 张槽位终值化）

| 槽位 | 事件/结局 ID | WebP 路径 | 来源 | 备注 |
|---|---|---|---|---|
| GALLERY-01 | E-ART-A（S9 支线A） | assets/cg_2d/artesia/CG-EX-01.webp | asset_map 9 张已定 | CielArt |
| GALLERY-02 | E-MEI-B（S9 支线B） | assets/cg_2d/mei/CG-EX-02.webp | asset_map 9 张已定 | CielArt |
| GALLERY-03 | E-RU-C（S9 支线C） | assets/cg_2d/rushena/CG-EX-03.webp | asset_map 9 张已定 | CielArt |
| GALLERY-04 | E-MEI-B 追加 | assets/cg_2d/mei/CG-EX-04.webp | asset_map 9 张已定 | Indie-H |
| GALLERY-05 | E-RU-C 追加 | assets/cg_2d/rushena/CG-EX-05.webp | asset_map 9 张已定 | Indie-H |
| GALLERY-06 | E5 前庭 | assets/cg_2d/meido/CG-CH5-01.webp | asset_map 9 张已定 | CielArt |
| GALLERY-07 | E5 王座对峙 | assets/cg_2d/meido/CG-CH5-02.webp | asset_map 9 张已定 | CielArt |
| GALLERY-08 | E5-1 魔王加冕 | assets/cg_2d/meido/CG-CH5-03.webp | asset_map 9 张已定 | CielArt |
| GALLERY-09 | E5-5 混沌真结局 | assets/cg_2d/meido/CG-CH5-04.webp | asset_map 9 张已定 | CielArt |
| GALLERY-10 | H-MID-新1 | assets/cg_2d/meido/CG-CH5-05.webp | 需求文档-V1.2.md 3.1（CG-CH5-05） | Indie-H |
| GALLERY-11 | H-MID-新2 | assets/cg_2d/meido/CG-CH5-06.webp | 需求文档-V1.2.md 3.1（CG-CH5-06） | Indie-H |
| GALLERY-12 | H-RU-003 深渊使者 | assets/cg_2d/rushena/CG-CH5-07.webp | 需求文档-V1.2.md 3.1（CG-CH5-07） | Indie-H |
| GALLERY-13 | E5-3 全员堕落 | assets/cg_2d/meido/CG-CH5-08.webp | 需求文档-V1.2.md 3.1（CG-CH5-08） | Indie-H |
| GALLERY-14 | V1.1 结局画廊 S7-01 | assets/cg_2d/artesia/CG-S7-01.webp | 订单记录推导，LFS 实物确认 | CielArt |
| GALLERY-15 | V1.1 结局画廊 S7-02 | assets/cg_2d/mei/CG-S7-02.webp | 订单记录推导，LFS 实物确认 | CielArt |
| GALLERY-16 | V1.1 结局画廊 S7-03 | assets/cg_2d/rushena/CG-S7-03.webp | 订单记录推导，LFS 实物确认 | CielArt |
| GALLERY-17 | V1.1 结局画廊 S7-04 | assets/cg_2d/marina/CG-S7-04.webp | 订单记录推导，LFS 实物确认 | Indie-H |
| GALLERY-18 | V1.1 结局画廊 S7-05 | assets/cg_2d/meido/CG-S7-05.webp | 订单记录推导，LFS 实物确认 | Indie-H |

## 二、断言规格（对齐覆盖盘点 §六）

TC-GALLERY-001~018 逐槽位四连断言：

1. **文件存在**：webp_path 在 CI checkout + `git lfs pull` 后必须存在（build.yml 已加 LFS 三连）
2. **文件非空**：size > 0（排除 96 字节 LFS 指针文件）
3. **WebP 头**：RIFF....WEBP（偏移 0-3 = RIFF，8-11 = WEBP）
4. **体积红线**：< 1.2MB（对应 q=88 规范）

TC-GALLERY-019~020 = 端到端入廊链路（C 类手工，不占 15min 自动化时长）。

## 三、变更记录

- 2024-11-19：v0.1 落盘（王码）——18 张槽位全部终值化，9 张精确 ID + S8-05~08 拆 4 条独立 entry（CG-CH5-05~08 李游锁定）+ S7 5 张按订单记录推导（LFS 实物确认后改 ACCEPTED_VERIFIED）
