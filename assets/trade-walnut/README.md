# 已确认主图

2026-09-16：交易页改用拆分后的 `main-trade-background-split.png`（1672×941，运行时按 1600×900 视口缩放）作为纯商车内景；`main-trade-exterior-city.png`（1672×941）通过 `ArtLayers/Window/Exterior` 叠加到橱窗开口，可由 `ArtLayers.set_city(texture)` 运行时替换。柜台改为连续无格线物理台面，落台区域为 x=382、y=424、w=1032、h=96；橱柜区定位为 x=462、y=531（30×12），背景图不绘制格子。旧版 `main-trade-background.png`、`main-trade-background-1694x928.png`、`main-trade-background-previous.png`、`main-trade-background-v2.png`、`main-zzz-metal-zoomed-layout-preview.png`、`main-anime.png` 与原图均保留作版本归档。

`main.png` 原样复制自用户最终指定图片 `exec-6f3f5464-445b-4338-a71a-6234ece30c1a.png`，无再生成或改图。原始尺寸 1676×939，游戏视口 1600×900，沿用既有全画幅缩放。

## 运行时区域（1600×900）

- 窗口人物裁切：x328–1270，y82–400。人物独立贴图，底部止于柜台后沿。
- 柜台：连续台面 x382–1414、y424–520；不显示柜台格子，物品从上方连续区域落下并在台面/物品顶部停止。
- 橱柜：x462、y531，720×288，30×12 格；底边保持原位置，顶部增加两行格子。
- 左门：x0、y70，170×760；右卧铺：x1440、y375，160×375。
- 顾客背包与交易清单是独立窗口，不烘焙在主图里。

内景不再依赖固定小镇外景；橱窗开口由独立城市层填充。窗口裁切容器仍沿用既有对齐值，顾客立绘与卷帘门继续挂在同一窗口容器中。
