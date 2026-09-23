# 道具候选库

这里保留道具图候选与运行时批次。运行时当前使用 `ordinary-fantasy-v2` 普通异世界批次；开源试用批次位于 `../opensource/raw`，此前生成图备份位于 `../archive/generated-v1`。

- `ordinary-fantasy-v2/`：当前启用的 14 个普通异世界道具 PNG 源文件。
- `generated/`：运行时加载的 `ordinary-fantasy-v2` 副本。
- `../opensource/raw/`：本次接入的开源原图与资源包裁切结果。

切换素材只需修改 `scripts/item_art.gd` 顶部的 `ITEM_TEXTURES` 映射，不改变占格、拖拽或交易逻辑。
