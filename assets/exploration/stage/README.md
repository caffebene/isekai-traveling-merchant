# 月下森林 · 历史分层素材

本目录保留旧版月下森林分层素材、Shader 和生成提示词，供对比和后续美术参考使用。旧的 `exploration_stage_world.tscn` 场景及其运行时包装脚本已经移除，不再作为游戏场景入口。

运行时使用 `stage/v4/` 中重新生成的 `forest-grove-mid.png`、`forest-grove-near.png`、`forest-grove-far.png`。每张素材都是主体居中的完整树丛，树冠、树干、岩石和底部植物有独立轮廓及透明边距。场景中的 `_L` 节点显示原图，对应 `_R` 节点使用 `flip_h` 镜像。`stage/v3/forest-ground-road.png` 仍是独立地面纹理，`stage/v3/forest-horizon.png` 负责天空、山脉和远处林线。旧素材保留在 v2/v3，方便对比。

v4 素材的生成提示词及项目统一正负面风格提示词记录在 `v4/prompts.md`。素材保持原始宽高比，通过 `pixel_size` 等比设置实际大小。

旧版分层方案曾使用独立 SubViewport、透视 Camera3D、远景天空、独立地面和多排左右镜像 Sprite3D 图层。当前运行时改用 `assets/battle/scene_layers/` 的 8 张战斗场景图，并以 `forest-distance.png` 作为透明开口下方的暗色远景底板，由 `scenes/battle_multilayer.tscn` 实现固定镜头过渡。

左右节点保持素材原始宽高比，没有非等比缩放。同类素材的每一排固定在相同的道路侧线：Mid 为左右 ±3.3、Near 为 ±5.1、Canopy 为 ±6.6；左侧使用负 X，右侧使用正 X。脚本读取编辑器中各节点的初始位置，仅在图层通过镜头前的最后一段计算画面边缘，让该排完整退出；下一排不进行额外横移。需要调整中央道路宽度时，在 `EditableLayers` 中成对调整同名 `_L` / `_R` 节点的 X 值，并保持各排同类素材的侧线一致。

角色与交互界面继续在 2D 层绘制。HUD 分区为背包与战利品窗口分列上方、旅行商人立绘与状态卡在左下、敌人与敌方状态卡在右侧、行动按钮与胜利文案居中位于画面下方。角色和背包不再互相覆盖，玩家血条跟随玩家立绘上方。前进期间暂停战斗和拖拽，抵达后再显示敌人并恢复战斗。战利品确认沿用原有逻辑。

验证：tests/test_exploration_travel.gd（含透视视差、镜头实际位移与五场流程）；tests/test_exploration.gd。视觉预览沿用 tests/preview_exploration.gd 与 tests/preview_exploration_travel.gd。
