> 历史生成记录，不作为当前生成依据。全局规范：docs/game-design/整体视觉与UI规范.md。

# 旅商背面立绘生成记录

- 生成方式：内置 `image_gen`（带本地参考图的重绘）
- 参考图：`assets/exploration/archive-v1/merchant-back.png`
- 生成输出源：`/Users/macmini/.codex/generated_images/01a090bf-15d7-7581-b5d4-d1349e7d7152/exec-5f6ca457-b808-401e-b99e-ca523cf2f85a.png`
- 项目目标：`assets/exploration/merchant-back.png`
- 提示词基线：`assets/exploration/prompts-clean-v2.json` 中 `assets.merchant_back.prompt`
- 本次优化重点：保留背面三分之四姿势、背包、卷毯、披风、提灯和长剑；改用大块连续色面、单组阴影和少量高光；删除皮革纹理、细密缝线、重复高光、逐根发丝和全身密集内线；要求真实透明 alpha，不含棋盘格、地面、阴影、光晕、文字或 UI。
- 输出检查：997 × 1578 PNG，8-bit RGBA，`sips` 报告 `hasAlpha: yes`；四周为透明背景，未发现绘制棋盘格。
- 目标 SHA-256：`c6f3dec5c6efb6adc4e6345ae3571226de4be7704d0f64d597ffde4e87ea954d`
