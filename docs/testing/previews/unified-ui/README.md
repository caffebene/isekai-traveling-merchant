# 当前游戏 UI 基准

物品卡局部实际截图：[1600 基准](food-card-detail-1600x900.png)、[1440 基准](food-card-detail-1440x810.png)。

2026-10-02 · merchant-ledger-v2。当前参考为深色棕金物品卡；都市风格已归档。真实游戏截图；[总规范](../../../game-design/整体视觉与UI规范.md)，[验收记录](../../统一UI改版验收.md)。

| 状态 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 交易主界面 | [截图](01-trade-1600x900.png) | [截图](01-trade-1440x810.png) |
| 背包与交易多窗口 | [截图](02-inventories-1600x900.png) | [截图](02-inventories-1440x810.png) |
| 混合买卖 | [截图](03-mixed-trade-1600x900.png) | [截图](03-mixed-trade-1440x810.png) |
| 长交易清单 | [截图](04-long-list-1600x900.png) | [截图](04-long-list-1440x810.png) |
| 资金不足 | [截图](05-insufficient-gold-1600x900.png) | [截图](05-insufficient-gold-1440x810.png) |
| 设备加工窗口 | [截图](06-processing-1600x900.png) | [截图](06-processing-1440x810.png) |
| 锻造图示配方册 | [截图](07-recipe-1600x900.png) | [截图](07-recipe-1440x810.png) |
| 对白历史 | [截图](08-history-1600x900.png) | [截图](08-history-1440x810.png) |
| 本城商报与旅行 | [截图](09-market-1600x900.png) | [截图](09-market-1440x810.png) |
| 商车改装 | [截图](10-modules-1600x900.png) | [截图](10-modules-1440x810.png) |
| 探索准备 | [截图](11-exploration-ready-1600x900.png) | [截图](11-exploration-ready-1440x810.png) |
| 探索战斗 | [截图](12-exploration-battle-1600x900.png) | [截图](12-exploration-battle-1440x810.png) |
| 大背包与战利品 | [截图](13-loot-large-1600x900.png) | [截图](13-loot-large-1440x810.png) |
| 武器信息卡 | [截图](14-tooltip-1600x900.png) | [截图](14-tooltip-1440x810.png) |
| 战败 | [截图](15-defeat-1600x900.png) | [截图](15-defeat-1440x810.png) |
| 经营帮助 | [截图](16-help-1600x900.png) | [截图](16-help-1440x810.png) |
| 营业结束确认 | [截图](17-close-confirmation-1600x900.png) | [截图](17-close-confirmation-1440x810.png) |
| 购入价格信息卡 | [截图](18-purchased-item-1600x900.png) | [截图](18-purchased-item-1440x810.png) |
| 食物信息卡 | [截图](19-food-tooltip-1600x900.png) | [截图](19-food-tooltip-1440x810.png) |
| 窗口与对白遮挡 | [截图](20-window-overlap-1600x900.png) | [截图](20-window-overlap-1440x810.png) |
| 炼药图示配方册 | [截图](21-alchemy-notebook-1600x900.png) | [截图](21-alchemy-notebook-1440x810.png) |
| 配方册移动后 | [截图](22-notebook-moved-1600x900.png) | [截图](22-notebook-moved-1440x810.png) |
| 生肉生命恢复 | [截图](23-raw-meat-tooltip-1600x900.png) | [截图](23-raw-meat-tooltip-1440x810.png) |
| 无数值材料卡 | [截图](24-material-tooltip-1600x900.png) | [截图](24-material-tooltip-1440x810.png) |

新增道具图片的小尺寸展示：[图片预览](generated-items.png)。全部正式道具改用透明PNG，配方和物品卡截图已刷新。

长剑朝向修订：旅人长剑、辉铁剑已重绘为正面竖直并替换旧倾斜素材，直剑统一2×6占格。当前图片预览扩展为11张，首行展示两把新直剑；两种分辨率实机页面同步刷新。

交易账单：[出售全页1600×900](25-sale-invoice-1600x900.png) / [1440×810](25-sale-invoice-1440x810.png)；[出售局部](25-sale-invoice-detail-1600x900.png) / [小窗口局部](25-sale-invoice-detail-1440x810.png)；[混合买卖局部](03-mixed-trade-detail-1600x900.png)。

商报新基准：当前新闻与传闻并存 [1600×900局部](26-news-active-detail-1600x900.png) / [1440×810局部](26-news-active-detail-1440x810.png)；矿队新闻与存货来信 [1600×900局部](27-news-miners-detail-1600x900.png) / [1440×810局部](27-news-miners-detail-1440x810.png)；平静日与商路入口 [1600×900局部](28-news-quiet-detail-1600x900.png) / [1440×810局部](28-news-quiet-detail-1440x810.png)。对应完整页面为26、27、28同名截图。

T型武器占格与嵌套药剂：[1600×900局部](29-weapon-footprint-detail-1600x900.png) / [1440×810局部](29-weapon-footprint-detail-1440x810.png)，由 `tests/preview_weapon_footprints.gd` 实例化真实经营场景、背包与拖放绘制器生成；没有单独绘制示意UI。

## 胡闹森林基准

由 `tests/preview_boisterous_forest.gd` 运行真实游戏生成，检查见 [验收记录](../../胡闹森林验收.md)。11–15探索基准已同步刷新。

| 状态 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 讨开宝箱 | [截图](26-forest-chest-1600x900.png) | [截图](26-forest-chest-1440x810.png) |
| 事件结果 | [截图](27-forest-event-result-1600x900.png) | [截图](27-forest-event-result-1440x810.png) |
| 事件奖励 | [截图](28-forest-event-loot-1600x900.png) | [截图](28-forest-event-loot-1440x810.png) |
| 蘑菇法庭 | [截图](29-forest-court-1600x900.png) | [截图](29-forest-court-1440x810.png) |
| 青蛙神仙 | [截图](30-forest-frog-1600x900.png) | [截图](30-forest-frog-1440x810.png) |
| 许愿井 | [截图](31-forest-well-1600x900.png) | [截图](31-forest-well-1440x810.png) |
| 首领备战 | [截图](32-forest-boss-ready-1600x900.png) | [截图](32-forest-boss-ready-1440x810.png) |
| 首领出手 | [截图](33-forest-boss-debt-1600x900.png) | [截图](33-forest-boss-debt-1440x810.png) |
| 首领半血修补 | [截图](34-forest-boss-repair-1600x900.png) | [截图](34-forest-boss-repair-1440x810.png) |
| 首领胜利，可继续 | [截图](35-forest-finish-1600x900.png) | [截图](35-forest-finish-1440x810.png) |
| 扩容背包 | [截图](36-forest-large-bag-1600x900.png) | [截图](36-forest-large-bag-1440x810.png) |

当前无限探索基准替代七节点样板；事件选项没有下方提示或精确概率。下面是多页对白与真实前因的实际画面：

| 新故事基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 初遇对白 | [截图](37-forest-first-dialogue-1600x900.png) | [截图](37-forest-first-dialogue-1440x810.png) |
| 三次真实拒绝后的追随 | [截图](38-forest-chest-memory-1600x900.png) | [截图](38-forest-chest-memory-1440x810.png) |
| 结果阅读 | [截图](39-forest-result-dialogue-1600x900.png) | [截图](39-forest-result-dialogue-1440x810.png) |
| 前置蘑菇丛 | [截图](40-forest-mushrooms-1600x900.png) | [截图](40-forest-mushrooms-1440x810.png) |
| 首领后继续遭遇 | [截图](41-forest-after-boss-1600x900.png) | [截图](41-forest-after-boss-1440x810.png) |



当前顾客背包仅在售货顾客在场时显示，收购顾客不显示；加工原料共用“材料＋用途类型”标签。

| 新增材料卡基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 材料、燃料 | [截图](30-fuel-tooltip-detail-1600x900.png) | [截图](30-fuel-tooltip-detail-1440x810.png) |
| 材料、矿石 | [截图](18-purchased-item-detail-1600x900.png) | [截图](18-purchased-item-detail-1440x810.png) |

经营范围可运行 `godot --path . --resolution 1600x900 --script tests/preview_unified_ui.gd -- --shop-only`，1440×810替换分辨率即可。

前进虚化基准：[1600×900](42-forest-travel-blur-1600x900.png) / [1440×810](42-forest-travel-blur-1440x810.png)。事件结果不再显示行李清点页。

## 武器五档品质基准

- 五色背包轮廓：[1600×900](43-quality-bag-1600x900.png)、[1440×810](43-quality-bag-1440x810.png)。
- 金色四词条信息卡：[1600×900](43-quality-card-1600x900.png)、[1440×810](43-quality-card-1440x810.png)。
- 柜台与实例价格账单：[1600×900](43-quality-trade-1600x900.png)、[1440×810](43-quality-trade-1440x810.png)。
- 燃料详情（隐藏品质概率）：[1600×900](43-quality-fuel-1600x900.png)、[1440×810](43-quality-fuel-1440x810.png)。
- 配方册（隐藏品质概率）：[1600×900](43-quality-recipe-1600x900.png)、[1440×810](43-quality-recipe-1440x810.png)。
- 探索武器品质：[1600×900](43-quality-exploration-1600x900.png)、[1440×810](43-quality-exploration-1440x810.png)。
- 旋转与拖拽品质轮廓：[1600×900](43-quality-drag-1600x900.png)、[1440×810](43-quality-drag-1440x810.png)。
- 战利品品质轮廓：[1600×900](43-quality-loot-1600x900.png)、[1440×810](43-quality-loot-1440x810.png)。


配方燃料展示基准：不指定种类时只显示通用燃料图标与“任意燃料”，指定时显示具体道具图标与名称；配方燃料区不显示纯度等额外数值。

| 配方燃料页 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 任意燃料：锻造 | [截图](recipe-book-detail-1600x900.png) | [截图](recipe-book-detail-1440x810.png) |
| 任意燃料：炼药 | [截图](21-alchemy-notebook-detail-1600x900.png) | [截图](21-alchemy-notebook-detail-1440x810.png) |
| 指定古藤木 | [截图](31-specific-fuel-recipe-detail-1600x900.png) | [截图](31-specific-fuel-recipe-detail-1440x810.png) |


经营与战斗背包当前不显示腰包绿色区域、相邻连线、加成角标或组合面板，最终武器数值在共享详情卡展示。

| 背包基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 精简经营背包 | [截图](32-clean-backpack-1600x900.png) | [截图](32-clean-backpack-1440x810.png) |
| 武器最终数值 | [截图](33-bag-weapon-details-detail-1600x900.png) | [截图](33-bag-weapon-details-detail-1440x810.png) |
| 战斗背包与详情 | [截图](34-battle-weapon-details-1600x900.png) | [截图](34-battle-weapon-details-1440x810.png) |


加成道具在悬停/拖动时显示半透明黄色相邻格；非背包物品详情同样显示加成数值。

| 加成范围基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 经营悬停 | [截图](35-support-hover-1600x900.png) | [截图](35-support-hover-1440x810.png) |
| 经营拖动 | [截图](36-support-drag-1600x900.png) | [截图](36-support-drag-1440x810.png) |
| 战斗悬停 | [截图](37-battle-support-hover-1600x900.png) | [截图](37-battle-support-hover-1440x810.png) |
| 战斗拖动 | [截图](38-battle-support-drag-1600x900.png) | [截图](38-battle-support-drag-1440x810.png) |


燃料攻击间隔规则更新：粘液相邻-10%、古藤木相邻-20%，多份相乘并保留迅捷效果；矿石不影响间隔。武器卡显示实际秒数。

| 燃料范围与百分比详情 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 粘液悬停与范围 | [截图](39-fuel-interval-hover-1600x900.png) | [截图](39-fuel-interval-hover-1440x810.png) |
| 战斗武器最终间隔 | [截图](34-battle-weapon-details-1600x900.png) | [截图](34-battle-weapon-details-1440x810.png) |

工具采集与新居民基准由 `tests/preview_forest_resources.gd` 生成。使用真实工具选择、掉落收纳、添柴和交费入口；剧情与起始伤势为指定夹具。

| 事件扩展基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 枯树选项 | [截图](44-forest-logging-1600x900.png) | [截图](44-forest-logging-1440x810.png) |
| 多把斧头选择 | [截图](44-forest-tool-selection-1600x900.png) | [截图](44-forest-tool-selection-1440x810.png) |
| 砍伐表现 | [截图](44-forest-chopping-1600x900.png) | [截图](44-forest-chopping-1440x810.png) |
| 木料战利品 | [截图](44-forest-wood-loot-1600x900.png) | [截图](44-forest-wood-loot-1440x810.png) |
| 矿脉选项 | [截图](44-forest-mining-1600x900.png) | [截图](44-forest-mining-1440x810.png) |
| 矿脉落石结果 | [截图](44-forest-mining-result-1600x900.png) | [截图](44-forest-mining-result-1440x810.png) |
| 倒班篝火 | [截图](44-forest-camp-1600x900.png) | [截图](44-forest-camp-1440x810.png) |
| 实际添柴后的余火 | [截图](44-forest-camp-memory-1600x900.png) | [截图](44-forest-camp-memory-1440x810.png) |
| 首遇收费蜗牛 | [截图](44-forest-snail-1600x900.png) | [截图](44-forest-snail-1440x810.png) |
| 实际交费两次后相识 | [截图](44-forest-snail-memory-1600x900.png) | [截图](44-forest-snail-memory-1440x810.png) |

森林委托与同行由`tests/preview_forest_story.gd`生成，完整真实入口流程与夹具范围见[验收](../../森林委托与同行验收.md)。

| 林心之路基准 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 阅读希尔薇委托 | [截图](45-forest-request-1600x900.png) | [截图](45-forest-request-1440x810.png) |
| 受伤猎人选择 | [截图](45-forest-hunter-1600x900.png) | [截图](45-forest-hunter-1440x810.png) |
| 康复后营业回访 | [截图](45-forest-hunter-customer-1600x900.png) | [截图](45-forest-hunter-customer-1440x810.png) |
| Boss树心战利品 | [截图](45-forest-heart-loot-1600x900.png) | [截图](45-forest-heart-loot-1440x810.png) |
| 真实出售树心 | [截图](45-forest-heart-sale-1600x900.png) | [截图](45-forest-heart-sale-1440x810.png) |
| 空心鹿王 | [截图](45-forest-stag-ready-1600x900.png) | [截图](45-forest-stag-ready-1440x810.png) |
| 首击1生命 | [截图](45-forest-one-hp-1600x900.png) | [截图](45-forest-one-hp-1440x810.png) |
| 希尔薇救场回血 | [截图](45-forest-rescue-1600x900.png) | [截图](45-forest-rescue-1440x810.png) |
| 独立弓援护 | [截图](45-forest-ally-attack-1600x900.png) | [截图](45-forest-ally-attack-1440x810.png) |
| 战后邀请 | [截图](45-forest-victory-talk-1600x900.png) | [截图](45-forest-victory-talk-1440x810.png) |
| 可选角色卡片 | [截图](45-forest-companion-cards-1600x900.png) | [截图](45-forest-companion-cards-1440x810.png) |
| 下一次普通探索同行 | [截图](45-forest-next-outing-1600x900.png) | [截图](45-forest-next-outing-1440x810.png) |

## 顾客阵营与随机货品（2026-10-03）

生成入口 `tests/preview_customer_factions.gd`，1600×900及1440×810各13张，共26张。十人立绘为逐个选取的布局夹具；树心需求及两次引荐则通过真实交易触发，随机货物和预算来自种子81。抽样记录为 `46-customer-samples.json`，不把锁定角色布局夹具声称为自然随机来访。

| 场面 | 1600×900 | 1440×810 |
| --- | --- | --- |
| 希尔薇 | [截图](46-customers-sylvie-1600x900.png) | [截图](46-customers-sylvie-1440x810.png) |
| 莱昂 | [截图](46-customers-leon-1600x900.png) | [截图](46-customers-leon-1440x810.png) |
| 绫叶 | [截图](46-customers-aya-1600x900.png) | [截图](46-customers-aya-1440x810.png) |
| 布洛克 | [截图](46-customers-brock-1600x900.png) | [截图](46-customers-brock-1440x810.png) |
| 奥林 | [截图](46-customers-olin-1600x900.png) | [截图](46-customers-olin-1440x810.png) |
| 米菈 | [截图](46-customers-mila-1600x900.png) | [截图](46-customers-mila-1440x810.png) |
| 诺拉 | [截图](46-customers-nora-1600x900.png) | [截图](46-customers-nora-1440x810.png) |
| 阿雀 | [截图](46-customers-sparrow-1600x900.png) | [截图](46-customers-sparrow-1440x810.png) |
| 赫伯特 | [截图](46-customers-herbert-1600x900.png) | [截图](46-customers-herbert-1440x810.png) |
| 伊芙 | [截图](46-customers-eve-1600x900.png) | [截图](46-customers-eve-1440x810.png) |
| 成交后的树心需求 | [截图](46-customers-sylvie-request-after-trade-1600x900.png) | [截图](46-customers-sylvie-request-after-trade-1440x810.png) |
| 收矿引荐工头 | [截图](46-customers-foreman-introduction-1600x900.png) | [截图](46-customers-foreman-introduction-1440x810.png) |
| 供饭引荐互助会 | [截图](46-customers-supper-introduction-1600x900.png) | [截图](46-customers-supper-introduction-1440x810.png) |

逻辑与回归见[顾客阵营验收](../../顾客阵营验收.md)。
