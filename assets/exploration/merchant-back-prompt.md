> 历史生成记录，不作为当前生成依据。全局规范：docs/game-design/整体视觉与UI规范.md。

# 旅商背面战斗素材

2026-09-11 已按 [低噪声 v2 提示词](prompts-clean-v2.json) 重新生成并替换；当前成品与检查记录见 [generation-results-hero.md](generation-results-hero.md)。以下是上一版素材的生成记录。

下一轮生图使用 [新版减噪提示词](prompts-clean-v2.json) 中的 merchant_back；下文保留已有素材的生成记录。

生成方式：内置 image_gen。沿用 merchant.png 的角色、服装与绘制风格。

## 初始提示词

Use case: stylized-concept. Game asset: isolated full-body traveling merchant battle sprite, actual transparent background alpha, no scenery, no ground, no shadow, no text. Reference image is identity/costume/art style reference. Create SAME young brown-haired male fantasy merchant, green short cloak, cream rolled sleeves, brown leather backpack with teal bedroll and brass lantern, brown trousers and boots, steel sword. Change camera to REAR THREE-QUARTER VIEW, looking away from viewer toward upper RIGHT, back and backpack dominant, only tiny right cheek profile visible. Full body feet entirely in frame, grounded ready stance, sword in right hand extending toward right, readable silhouette. Hand-painted detailed anime fantasy RPG illustration, warm sunset rim light, muted forest green and brown. Single character centered, fills 90% image height, transparent padding. No front-facing torso, no duplicate character. Output transparent PNG.

## 生产底色编辑提示词

Precise background replacement for production game compositing. Keep the SAME rear three-quarter merchant pose facing right, full body, identical character silhouette and clothing colors. Replace ALL gray checkerboard with perfectly flat solid vivid magenta RGB(255,0,255) #FF00FF, including all gaps between legs, under arm, between sword and body. Opaque solid magenta, absolutely no checkerboard, no shadow, no gradient, no texture, no translucent fringe. Character colors must not contain magenta. Do not change character. Clean sharp edges.

## 接入

工具的透明底请求返回了 RGB 棋盘格，故再生成纯品红底版本 merchant-back-chroma.png。通过 tools/bake_merchant.gd 和 scripts/merchant_cutout.gdshader，在 Godot 中烘焙为 merchant-back.png（930 × 1472，真实 RGBA），游戏直接加载透明 PNG，无运行时去底依赖。旧 merchant.png 保留。
