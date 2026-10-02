# 异世界旅商

原生 Godot 4 项目。用 Godot 打开 `project.godot`，按 F5 运行；或执行 `godot --path .`。

当前玩法包括空间库存、自由物理柜台、买卖与议价、跨日加工、城市行情、商车改装、跨城旅行和野外探索。玩法及版本范围见 [游戏 Wiki](docs/game-design/wiki/README.md)。当前不包含持久化存档。

## 统一设计

当前风格为“复古都市 × 异世界旅商”。唯一全局依据：[整体视觉与UI规范](docs/game-design/整体视觉与UI规范.md)。经营、探索、行情、改装、设备、对白、历史及悬停共用 `scripts/popup_style.gd`。生成美术前读取总规范，再读取 [场景提示词](docs/game-design/玩家主世界画风提示词.md) 或 [道具提示词](docs/game-design/道具生成提示词.md)。

运行资产与历史边界见 [美术资源](docs/game-design/美术资源.md)。旧概念稿和生成记录仅供追溯，不作为当前风格默认参考。

## 结构

- `scripts/trade_state.gd` 管理库存、交易、加工与物品数据；界面不改变规则。
- `scripts/shop.gd` 组织经营输入、窗口与实体道具；交易清单靠右、背包靠左，窗口可拖动且独立关闭。
- `scripts/scene_layers.gd` 保留内景、城市与顾客分层及替换接口；柜台支撑基线 y=485，主库存30×12、格子24 px。
- `scenes/battle_multilayer.tscn` 与森林空间层负责旅途画面；探索界面复用全局组件。
- [UI 工作区](docs/game-design/ui-workbench/索引.json) 记录当前语义和布局；玩家可感知改动同次同步 Wiki。

## 验证与预览

```sh
godot --headless --path . --script tests/test_trade.gd
godot --headless --path . --script tests/test_trade_overlay_interactions.gd
godot --headless --path . --script tests/test_workbench_window.gd
godot --headless --path . --script tests/test_exploration_interactions.gd
godot --path . --resolution 1600x900 --script tests/preview_unified_ui.gd
godot --path . --resolution 1440x810 --script tests/preview_unified_ui.gd
```

实际游戏基准保存在 `docs/testing/previews/unified-ui/`，检查记录见 [统一UI改版验收](docs/testing/统一UI改版验收.md)。历史预览仍保留，但不作为新风格依据。中文字体回退顺序为 PingFang SC / Noto Sans CJK SC / Microsoft YaHei。
