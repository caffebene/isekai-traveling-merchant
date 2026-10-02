# 统一 UI 改版验收

日期：2026-10-02。风格基准：`urban-fantasy-v1`，依据 [整体视觉与 UI 规范](../game-design/整体视觉与UI规范.md)。

## 改动范围

经营 HUD、侧区交易清单、旅行/顾客背包、设备窗口、配方、对白、历史、行情、改装、探索背包、战利品、状态、战败及悬停统一使用 `scripts/popup_style.gd`。暖白标题条、石墨色正文区、橙色主操作、粗体标题与宽窗双斜线统一了层级；窗口保持 8 px 切角，次按钮使用近黑底。普通浮窗可并行打开，模态与探索层阻止底层操作穿透。

复用既有都市、人物与森林分层，替换史莱姆粘液、古藤木、工作台与炼药器四个冲突图标；像素树怪改用已有动画树怪图。生成记录见 `assets/items/unified-generation.json`。新道具全部为 RGBA、透明四角，按既有占格输出 192×192、384×384、288×384，不改物品身份、容量与规则。

## 实际游戏截图

[基准索引](previews/unified-ui/README.md) 包含 1600×900 与 1440×810 两种实际窗口，共 34 张截图。由 `tests/preview_unified_ui.gd` 实例化真实主场景、使用既有入口和状态后截图；没有额外的界面复刻渲染器。脚本仅构造可重复的验收状态，不是玩家存档。

覆盖经营首页、多窗口并存、混合买卖、长交易清单、资金不足、设备加工区、配方、历史、行情、改装、探索准备、战斗、大背包战利品、悬停、战败、帮助及结束营业确认。

逐页检查两种分辨率下的文字、金额列、关闭热区、顾客可见空间、设备网格、模态层级与提示框边界。固定场景与自由物理柜台沿用原有坐标，改变窗口位置时同步更新实际投放区和关闭控件。

## 现有自动检查

Godot 4.7.1，无新增简单配色测试。12 组现有检查全部通过，共 516 项；原始结果见 [测试结果](统一UI测试结果.json)。

| 程序 | 检查数 | 结果 |
| --- | ---: | --- |
| test_trade | 110 | 通过 |
| test_counter_physics | 9 | 通过 |
| test_trade_overlay_interactions | 51 | 通过 |
| test_workbench_window | 41 | 通过 |
| test_alchemy | 159 | 通过 |
| test_dialogue | 11 | 通过 |
| test_game_depth | 31 | 通过 |
| test_game_depth_ui | 10 | 通过 |
| test_exploration | 46 | 通过 |
| test_exploration_interactions | 19 | 通过 |
| test_exploration_loot_autopick | 6 | 通过 |
| test_exploration_travel | 23 | 通过 |

两项既有检查原先使用早期手机尺寸及旧柜台高度，在改版前基线运行同样失败。本次更新测试断言为当前场景的手机比例，以及 alpha 碰撞轮廓与真实柜台基线的接触/防穿透检查；保留弹性、旋转、取消和窗口遮挡验证，没有为通过测试改动物理规则。

另检查脚本导入无编译错误、结构合约 JSON 可解析、新透明图标尺寸与 alpha 正确、`git diff --check` 无空白错误。截图是静态视觉基准；自动交互检查覆盖点击遮挡、拖动、拖放和快捷操作，不代表长期游戏平衡测试。

## 重现

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script tests/test_trade_overlay_interactions.gd
godot --headless --path . --script tests/test_counter_physics.gd
godot --headless --path . --script tests/test_workbench_window.gd
godot --headless --path . --script tests/test_exploration_interactions.gd
godot --path . --resolution 1600x900 --script tests/preview_unified_ui.gd
godot --path . --resolution 1440x810 --script tests/preview_unified_ui.gd
```

后续风格改动同时更新总规范、共享实现、生成分支与本目录截图。旧预览保留历史意义，不是当前验收基准。
