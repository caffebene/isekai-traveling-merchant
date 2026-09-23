# 分层环境切片提示词

## v2：单侧远景切片

v2 的每张 PNG 只生成左侧环境，右侧由 Godot `Sprite3D.flip_h` 镜像，不再在图片中重复绘制两侧。画面中的树干、岩石和叶簇按远景比例缩小，左侧只占画布约 30%–45%，其余区域必须是真正的透明 alpha；不能把棋盘格绘制进 PNG。地面不放入切片，单独使用 `forest-ground-road.png`。

## forest-side-near.png

Use case: stylized-concept. Asset type: transparent RGBA game environment layer. Generate a restrained LEFT-SIDE edge frame for a moonlit Japanese-animation forest road. Keep the visible foliage and one slim trunk within the left 30%–38% of a 1536x1024 canvas; leave the right 62%–70% as real alpha 0. Moderately distant scale, no giant trunk, no oversized rock, no road, no floor, no center scenery. Clean irregular inner edge for horizontal mirroring. Night indigo, blue-green and muted teal cel-shaded shapes.

## forest-side-mid.png

Use case: stylized-concept. Asset type: transparent RGBA game environment layer. Generate a DISTANT LEFT-SIDE midground forest bank for a moonlit Japanese-animation road. Keep the visible tree line, small rocks and sparse mushrooms within the left 38%–45% of a 1536x1024 canvas; leave the remaining area as real alpha 0. Use small layered silhouettes rather than close-up trunks or leaves. No road, no floor, no center scenery, no characters or UI.

## forest-side-canopy.png

Use case: stylized-concept. Asset type: transparent RGBA game environment layer. Generate a DISTANT LEFT-SIDE overhead canopy frame. Keep slender branches and small leaf clusters concentrated in the top-left and left 30%–40% of a 1536x1024 canvas, with most of the lower area and all of the right side as real alpha 0. No solid banner, no large foreground trunk, no road, no floor, no text.

## forest-ground-road.png

Use case: stylized-concept. Asset type: opaque tileable ground texture. Generate only a moonlit blue-green stone-and-dirt forest road surface, square 1:1, with broad grouped shadows and sparse grass tufts. No trees, side walls, horizon, sky, characters or UI. The Godot ground shader masks this texture into a centered road shape.

## forest-horizon.png

Use case: stylized-concept. Asset type: opaque distant backdrop. Generate only a centered crescent moon, stars, atmospheric blue mountains and a low distant tree-line silhouette. Keep the lower area as a quiet deep-blue gradient with no road, ground, rocks or close foliage.

以上 v2 资产均追加项目统一正面提示词与负面提示词；原始完整左右切片提示词保留在下方作为历史记录。

三张切片都追加当前项目的正面提示词与负面提示词（原文保存在 `prompts.json`）。重点约束是：每张素材必须是单张完整横向环境，左右两侧环境同时出现，中间保留透明道路窗口；必须是真实 RGBA 透明，不绘制棋盘格。

## forest-layer-near.png

Use case: stylized-concept. Asset type: transparent wide game scenery cutout for a 3D paper-theater layer. Create ONE complete wide environmental slice, landscape 3:2. NIGHTTIME enchanted forest path. The entire image must be a single coherent layer containing BOTH the left and right sides: huge dark teal tree trunks rising along the extreme left and extreme right edges, twisted roots and clusters of ferns framing the lower corners, a few hanging leaves at the side edges. Leave a large clean transparent opening through the middle 45% of the image so the distant path can be seen behind it; no object may cross the central opening. The cutout should feel like a foreground gate around a road, symmetrical in visual weight but with natural asymmetry in branches. Real transparent alpha background, not a checkerboard drawing. No complete floor plane, no horizon, no standalone floating objects, no text. Crisp cel-shaded shapes, moonlit blue-green palette, small restrained cool highlights.

## forest-layer-mid.png

Use case: stylized-concept. Asset type: transparent wide game scenery cutout for a 3D paper-theater layer. Create ONE complete wide environmental slice, landscape 3:2. NIGHTTIME woodland corridor. The entire image contains BOTH left and right sides as one connected composition: medium-distance tree walls, layered blue-green shrubs, smooth slate rocks, small pale mushrooms and fern silhouettes on both lower sides, with branches reaching inward only near the far upper corners. Keep the central 42% as a large open transparent road-shaped window, with no character and no painted background behind it. This is a midground parallax layer placed over a distant moonlit plate. Real transparent alpha background, never a checkerboard pattern. Natural asymmetry, readable grouped shapes, no floor plane, no horizon, no text.

## forest-layer-canopy.png

Use case: stylized-concept. Asset type: transparent wide game scenery cutout for a 3D paper-theater layer. Create ONE complete wide overhead environmental slice, landscape 3:2. NIGHTTIME enchanted forest canopy framing a road. Both left and right sides are included in the same asset: large dark branches and leafy silhouettes descend from upper left and upper right corners, with a few thin vines at the edges; the middle 50% must remain transparent and open so the moonlit sky and road show through. Add only small edge leaves near the opening, never a solid banner across the center. Real transparent alpha background, no checkerboard drawn, no background color, no text. Crisp navy, teal and muted moonlit green cel-shaded shapes, calm readable silhouette.
