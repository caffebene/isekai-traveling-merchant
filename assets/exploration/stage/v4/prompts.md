# 月下森林 v4 · 单侧完整树丛

生成方式：内置 ImageGen；每个素材独立生成，输出为真实 RGBA 透明图。右侧在 Godot 中镜像，无需另生成素材。

## 共用正面风格

干净的日式动画游戏美术，以大色块组织画面。每种材质只用底色、成组阴影和少量高光，通过形体表现体积。细节集中在辨识特征，其他区域保持安静。保留清晰轮廓，不靠模糊制造简洁感。

夜晚配色：深海军蓝、靛蓝、蓝绿色树叶，克制的冷色月光轮廓高光。正侧面观看，单独环境物件，真实透明背景；主体居中，完整展示树冠、枝干、树根、岩石和地表植物，不绘制天空、道路或延伸到画面之外的地面。

## 各素材主体

- `forest-grove-mid.png`：两棵中等高度的树组成一簇，连接少量灌木、岩石和小蘑菇；整体作为一座完整的林地小岛，树冠与基部都有独立轮廓。
- `forest-grove-near.png`：一棵高而结实的树、一棵较矮的伴生树、大块蓝灰岩石、前景灌木与少量蘑菇；适合近层，所有主要物体轮廓完整。
- `forest-grove-far.png`：三棵高低不一的纤细树、少量深色灌木与蓝色小岩石；色彩略暗、细节更安静，适合远层。

## 共用负面提示词

photorealistic, realistic photography, cyberpunk night city, dark dystopia, excessive neon lights, rainy night, gritty texture, dirty texture, noise, grain, film grain, dirty pixel, stray pixel, overly detailed texture, realistic concrete cracks, realistic rust, heavy bloom, excessive reflections, fog, blurry, depth of field blur, watercolor, oil painting, sketch, painterly texture, low saturation, medieval architecture, empty street, overcrowded pedestrians, distorted buildings, fisheye distortion, text artifacts, watermark

额外排除：假透明棋盘格、实色背景、文字、UI、贴边裁断的枝叶或树干、非等比压缩。
