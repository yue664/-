# Sprint 0 D2 交付记录

> 维护人：王码（主程）
> 日期：2024-09-09（Sprint 0 D2）
> 版本：v0.2（Android 骨架落地）

---

## 一、交付清单

### 1. Godot 4.3 工程骨架 ✅

```
game/
├── project.godot                     工程配置（4.3 + GL Compatibility + Autoload）
├── export_presets.cfg                5 个导出预设（Windows/Linux/macOS/Android/Web）
├── scenes/
│   └── main/Main.tscn                主入口场景
├── scripts/
│   ├── core/
│   │   ├── Main.gd                   主入口逻辑
│   │   ├── GameManager.gd            主角数值/契约度/堕落值/好感度
│   │   ├── SaveManager.gd            3 槽 + 自动 + 版本迁移框架
│   │   └── AudioManager.gd           BGM/SE 播放
│   ├── platform/
│   │   └── PlatformManager.gd        平台检测 + 3D 降级 + 触控 UI 开关
│   └── ui/
│       └── UIManager.gd              UI 层级 + 触控/鼠标模式
└── build/                            构建产物目录（.gitignore 排除）
```

### 2. Android 骨架 ✅

**PlatformManager.gd 核心能力**：
- 运行时检测 `OS.get_name() == "Android"`
- 手机端默认 `is_high_perf_3d = false`（关闭 3D 演出）
- 手机端默认 `use_touch_ui = true`（启用触控 UI）
- 存档目录按平台自动切换（Android 走 `OS.get_user_data_dir()`）
- 提供 `can_use_3d_cinematic()` / `is_touch()` 供全项目调用
- **不需要 `#ifdef` 宏**（GDScript 运行时判断更灵活）

**export_presets.cfg 的 Android preset**：
- 包名 `com.arkadia.fallers`，版本号 0.2.0
- `minSdk 24`（Android 7.0+），`targetSdk 34`
- 只打包 `arm64-v8a`（减体积）
- 沉浸式模式开启

### 3. CI 双平台分支 ✅

`.github/workflows/build.yml`：
- `unit-test` job：headless 跑单测
- `build-windows` job：Windows x86_64 导出
- `build-android` job：Android APK（含 JDK 17 + Android SDK + 导出模板下载）
- `build-web` job：Web 导出
- 全部产物上传 GitHub Actions artifact

### 4. 技术选型说明 ✅

`docs/tech/技术选型.md` v0.2：
- 引擎选型 + 目录结构 + 平台分层设计
- 第三方库清单（需张策审批的单独标注）
- Git 分支策略 + 代码规范
- 构建发布流程 + Android 前置
- 性能目标（对齐陈验 v0.2 基线）
- 后续 Sprint 技术任务

### 5. 开发规范 ✅

`docs/tech/开发规范.md` v0.1：
- GDScript 4.3 命名/类型/信号规范
- 场景命名约定
- Git 分支 + Commit 格式 + PR 审查清单
- 敏感信息管理（Keystore/API Key 走 CI Secrets）
- 构建流程 + 备份回滚 + 代码审查 SLA

### 6. .gitignore ✅

- 构建产物（exe/apk/pck/zip）
- Godot 缓存（.godot/）
- 本地密钥（*.keystore / keystore.properties）
- 平台专属（.DS_Store / .idea / .vscode）
- 第三方素材（`assets/third_party/` 版权隔离）

---

## 二、关键接口（供团队对接）

### 王码 → 赵画

| 接口 | 说明 |
|---|---|
| `PlatformManager.can_use_3d_cinematic()` | 返回 false 时，手机端强制走 2D CG 替代 |
| `assets/models/heroines/{char_id}/model.gltf` | 3D 模型路径约定（glTF 2.0） |
| `assets/shaders/cel_shading.gdshader` | Cel-Shading Shader 待实现（Sprint 2） |

### 王码 → 李游

| 接口 | 说明 |
|---|---|
| `GameManager.add_corruption(v)` | 剧情/战斗调用加堕落值 |
| `GameManager.add_contract(char_id, v)` | H 事件完成后加契约度 |
| `GameManager.add_affection(char_id, v)` | 对话选项加好感度 |
| `GameManager.is_fallen()` | 判断主角是否完全堕落（触发结局） |

### 王码 → 陈验

| 接口 | 说明 |
|---|---|
| `--run-tests --quit` | Godot headless 单测模式（CI 已配置） |
| SaveManager.save/load | 3 槽 + 版本迁移，可直接对接存档 TC-SAVE-* |
| PlatformManager._platform_name() | 用于 TC-COMPAT-* 平台识别 |

---

## 三、D2 未完成的项

- [ ] **Steamworks SDK 接入**（Sprint 3 评估，需张策批预算）
- [ ] **Firebase 云存档**（Sprint 4 评估，需张策批预算）
- [ ] **Cel-Shading Shader 实现**（Sprint 2 主程任务）
- [ ] **GUT 单测框架接入**（Sprint 1，陈验配合）
- [ ] **CI Secrets 配置**（等张策给 GitHub 仓库后配 Android keystore）
- [ ] **GitHub 仓库初始化**（等张策创建仓库 + 推送）

---

## 四、风险与 KN 应对

| KN | 状态 |
|---|---|
| KN-009（Cel-Shading 需自制） | 待实现，Sprint 2 |
| KN-010（模型风格统一） | 待评估，需赵画先建标杆 |
| KN-011（Shader 首次编译） | 待测，Sprint 0 D6 |
| KN-012（2D↔3D 切换黑屏） | 待测，混合演出实现时 |
| KN-013（缓存 LRU 未定） | 待实现，Sprint 2 |
| KN-014（Blend Shape 规范） | 待规范，赵画 |

| RISK | 状态 |
|---|---|
| R-013（Android 分级侧载） | 应对中，官网+CDN 预算走张策 |
| R-014（手机端 3D 性能） | ✅ 已通过 PlatformManager 关闭 3D 演出应对 |
| R-015（双平台维护） | 应对中，UI 独立组件（不做共用） |

---

## 五、Sprint 0 D3 计划

- [ ] 战斗原型（1v1 回合制）
- [ ] GodotTest 冒烟自动化骨架（陈验配合）
- [ ] 主菜单场景搭建
- [ ] 存档单元测试（SaveManager 迁移路径）

---

## 六、王码 · D2 收口

**Godot 4.3 双平台骨架已就位**。Steam PC 走完整管线，Android 走降级管线，切换由 `PlatformManager` 单点控制，未来加平台（Web/iOS）只需扩 enum + 分支即可。

**下一步 D3 见**，战斗原型开工。


<silent mood="working" as="D2 骨架完成" reason="Godot 4.3 + Android 双平台骨架一次到位" bg="#B3F2F2F2" tint="#027373"></silent>