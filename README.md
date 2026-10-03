# 异世界旅商

原生 Godot 4 项目。用 Godot 打开 `project.godot`，按 F5 运行；或执行 `godot --path .`。

当前玩法包括空间库存、自由物理柜台、买卖与议价、跨日加工、城市行情、商车改装、跨城旅行和胡闹森林无限探索。玩法及版本范围见 [游戏 Wiki](docs/game-design/wiki/README.md)。当前不包含持久化存档。

## 统一设计

当前风格为“古典旅商账册”。唯一全局依据：[整体视觉与UI规范](docs/game-design/整体视觉与UI规范.md)。经营、探索、行情、改装、设备、对白、历史及悬停共用 `scripts/popup_style.gd`。生成美术前读取总规范，再读取 [场景提示词](docs/game-design/玩家主世界画风提示词.md) 或 [道具提示词](docs/game-design/道具生成提示词.md)。

运行资产与历史边界见 [美术资源](docs/game-design/美术资源.md)。旧概念稿和生成记录仅供追溯，不作为当前风格默认参考。

## 结构

- `scripts/trade_state.gd` 管理库存、交易、加工与物品数据；界面不改变规则。
- `scripts/shop.gd` 组织经营输入、窗口与实体道具；交易清单靠右、背包靠左。售货顾客的背包随到场显示、离开关闭；仅收购物品的顾客不显示背包，其余浮窗保留独立关闭。
- `scripts/market_board.gd` 以商报展示本城新闻、近期传闻与市集见闻，不提供价格表或精确预测；商路操作仍由报纸底部进入。
- `scripts/scene_layers.gd` 保留内景、城市与顾客分层及替换接口；柜台支撑基线 y=485，主库存30×12、格子24 px。
- `scenes/battle_multilayer.tscn` 与森林空间层负责旅途画面；探索界面复用全局组件。
- [UI 工作区](docs/game-design/ui-workbench/索引.json) 记录当前语义和布局；玩家可感知改动同次同步 Wiki。

## 验证与预览

```sh
godot --headless --path . --script tests/test_trade.gd
godot --headless --path . --script tests/test_trade_overlay_interactions.gd
godot --headless --path . --script tests/test_workbench_window.gd
godot --headless --path . --script tests/test_weapon_footprints.gd
godot --headless --path . --script tests/test_exploration_interactions.gd
godot --path . --resolution 1600x900 --script tests/preview_unified_ui.gd
godot --path . --resolution 1440x810 --script tests/preview_unified_ui.gd
```

实际游戏基准保存在 `docs/testing/previews/unified-ui/`，检查记录见 [统一UI改版验收](docs/testing/统一UI改版验收.md)。历史预览仍保留，但不作为新风格依据。中文字体回退顺序为 PingFang SC / Noto Sans CJK SC / Microsoft YaHei。

配方界面使用可拖动的图示册子，通过物品图标、数量与箭头展示加工过程；打开配方册时可以继续操作其他窗口。详情见 [加工与配方](docs/game-design/wiki/加工与配方.md)。

所有正式道具图标均使用透明PNG，统一由 `scripts/item_art.gd` 加载。新补全的锻造武器、矿石与废水图片和完整提示词见 [生成记录](assets/items/workbench/generated/generation.json)，小尺寸效果见 [图片预览](docs/testing/previews/unified-ui/generated-items.png)。

武器使用与外形匹配的占格轮廓：镐为T型，柄两侧空格可以嵌入小物品；放置、旋转、自动收纳、点击与相邻效果共用 `TradeState.footprint()`。[实际背包预览](docs/testing/previews/unified-ui/29-weapon-footprint-detail-1600x900.png)。

## 胡闹森林样板

车门进入“胡闹森林”，无限生成战斗与有前因、能记住真实选择的随机故事，首领后仍可继续。保留背包构筑和主动用物，事件奖励通过战利品区收纳。规则见 [探索与战斗](docs/game-design/wiki/探索与战斗.md)，美术与交付说明见 [设计文档](docs/game-design/胡闹森林.md)。

探索救助可解锁营业顾客。希尔薇树心委托以Boss掉落与真实出售推进，开启空心鹿王救场、战后入队及后续人物卡片选择；详见[森林委托与同行](docs/game-design/森林委托与同行.md)及[验收记录](docs/testing/森林委托与同行验收.md)。

```sh
godot --headless --path . --script tests/test_forest_events.gd
godot --headless --path . --script tests/test_exploration_travel.gd
godot --path . --resolution 1600x900 --script tests/preview_boisterous_forest.gd
godot --path . --resolution 1440x810 --script tests/preview_boisterous_forest.gd
```

随机经营来客：五个阵营、十位顾客（初始七位），按城市、交情与久未见抽取；货品与预算随机。供矿、供饭、换装可推进人物故事；希尔薇首次成功交易后才提出树心需求。见[顾客阵营与故事](docs/game-design/顾客阵营与故事.md)。
