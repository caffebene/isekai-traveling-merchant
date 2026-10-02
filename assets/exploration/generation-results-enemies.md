> 历史生成记录，不作为当前生成依据。全局规范：docs/game-design/整体视觉与UI规范.md。

# 低噪声怪物素材生成记录

本轮使用 [prompts-clean-v2.json](prompts-clean-v2.json) 中的 `slime`、`wolf`、`golem`、`red_wolf`、`treant` 提示词，通过内置 image_gen 重新生成并替换了游戏中的五种怪物素材；棋盘格预览由 [remove_checkerboard.py](../../tools/remove_checkerboard.py) 转为真实 RGBA。

提示词统一要求：大块面、成组阴影、少量高光、轮廓清楚；把细节限制在眼睛、嘴部、主要关节和剪影识别点；禁止逐根毛发、碎石、颗粒、密集划线、斑驳和全身高频纹理。

输出文件：

- [slime.png](slime.png) — RGBA，已去除生成器棋盘格
- [wolf.png](wolf.png) — RGBA，已去除生成器棋盘格
- [golem.png](golem.png) — RGBA，已去除生成器棋盘格
- [red_wolf.png](red_wolf.png) — RGBA，已去除生成器棋盘格
- [treant.png](treant.png) — RGBA，已去除生成器棋盘格

原始素材保存在 [archive-v1](archive-v1/)。生成器返回的棋盘格预览保存在 `archive-v2-raw/slime.png`；其余素材在项目内只保留去底后的最终文件。
