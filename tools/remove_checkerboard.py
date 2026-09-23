"""Convert image_gen's painted checkerboard previews into real RGBA sprites.

The generated images are treated as source material only. Background pixels are
found as light, near-neutral regions connected to the image border; neutral
character details enclosed by the dark silhouette stay intact.
"""
from pathlib import Path
import sys

import numpy as np
from PIL import Image
from scipy import ndimage


def remove(path: Path) -> None:
    rgb = np.asarray(Image.open(path).convert("RGB"), dtype=np.uint8)
    maxc = rgb.max(axis=2).astype(np.int16)
    minc = rgb.min(axis=2).astype(np.int16)
    mean = rgb.mean(axis=2)
    # Both white and gray checkerboards are nearly neutral.  The lower bound
    # keeps dark hair, fur and outlines from joining the border component.
    neutral = (maxc - minc <= 24) & (mean >= 100)
    labels, count = ndimage.label(neutral, structure=np.ones((3, 3), dtype=np.uint8))
    border_labels = np.unique(
        np.concatenate((labels[0], labels[-1], labels[:, 0], labels[:, -1]))
    )
    background = np.isin(labels, border_labels[border_labels != 0])
    # Remove the pale fringe left by the generated checkerboard, but do not
    # erode the dark silhouette.  A one-pixel closing fills tiny holes in the
    # exterior grid without touching enclosed neutral details.
    background = ndimage.binary_dilation(background, iterations=1)
    alpha = np.where(background, 0, 255).astype(np.uint8)
    rgba = np.dstack((rgb, alpha))
    # Trim only fully transparent padding; keep a small 8 px breathing room.
    ys, xs = np.where(alpha > 0)
    if len(xs):
        x0, x1 = max(0, xs.min() - 8), min(rgb.shape[1], xs.max() + 9)
        y0, y1 = max(0, ys.min() - 8), min(rgb.shape[0], ys.max() + 9)
        rgba = rgba[y0:y1, x0:x1]
    Image.fromarray(rgba, "RGBA").save(path)
    print(f"{path}: {rgb.shape[1]}x{rgb.shape[0]} -> {rgba.shape[1]}x{rgba.shape[0]}")


if __name__ == "__main__":
    for name in sys.argv[1:]:
        remove(Path(name))
