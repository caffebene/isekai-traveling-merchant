# Project Context

<!-- unity-onboarding:generated:start -->

## Project Summary

- Project root: `/Users/macmini/Open/异世界旅商`
- Last analyzed: 2026-09-16
- Repository: no Git metadata detected at project root
- Important correction: this workspace is a Godot project, not a Unity project. The filename is retained for compatibility with the onboarding workflow.

## Confirmed Environment

- Engine: Godot 4.7, GL Compatibility renderer
- Main viewport: 1600 × 900; canvas-items stretch
- Input: Godot legacy `InputEvent` handling in GDScript; no Input Map actions detected in the inspected settings
- Target platforms: unknown; desktop-style 1600 × 900 presentation is confirmed

## Important Packages And Frameworks

| Area | Finding | Confidence | Evidence |
| --- | --- | --- | --- |
| Engine | Godot 4.7 | confirmed | `project.godot` |
| Rendering | GL Compatibility; 2D UI with an isolated fixed-camera 3D paper-theater battle stage composited over a dark distant-forest plate | confirmed | `project.godot`, `scripts/battle_space_stage.gd`, `scripts/exploration.gd`, `scenes/battle_multilayer.tscn` |
| External packages | None declared in a package manifest | confirmed | no `Packages/manifest.json`; no Godot add-on manifest found in inspected tree |

## Directory Structure

| Path | Purpose | Confidence | Evidence |
| --- | --- | --- | --- |
| `main.tscn` | Existing shop/management entry scene | confirmed | scene resource and `project.godot` |
| `scripts/` | Runtime GDScript for shop, trade state, exploration, UI styling, and art helpers | confirmed | inspected scripts |
| `scenes/` | Standalone multi-layer battle scene | confirmed | `scenes/battle_multilayer.tscn` |
| `assets/` | Runtime art, item textures, characters, enemies, and layered forest assets | confirmed | asset inventory |
| `tests/` | Headless logic checks and preview scripts | confirmed | test/preview scripts |
| `docs/` | Game design, testing previews, and technical documentation | confirmed | README and file inventory |

## Scene And Startup Flow

- Main scene: `res://main.tscn`
- Existing shop flow creates `scripts/exploration.gd` at runtime from the door interaction.
- Existing exploration rendering uses `scenes/battle_multilayer.tscn` through `scripts/battle_space_stage.gd`; it loads eight scene-layer PNGs as a fixed-camera `Sprite3D` queue with a `TransitionGhost` for continuous layer transitions, composited over `assets/exploration/stage/forest-distance.png` as the dark distant background plate. The exploration presenter keeps the backpack and loot windows near the upper left/right center and supports automatic loot pickup through double-click or Ctrl+click.
- Exploration encounters are unlimited and use an explicit `ready` preparation phase before `battle`; fleeing from preparation randomly removes one travel-bag item, battle auto-attacks only with weapons, consumables are double-click-only, victory offers return/continue actions, and defeat clears the travel bag behind a defeat popup.
- The old `scenes/exploration_stage_world.tscn` battle-stage entry and `scripts/exploration_stage.gd` wrapper have been removed; legacy stage assets remain only as art references.
- New battle scene work should remain standalone and must not instance or reference `main.tscn` or the removed legacy stage.

## Architecture

| Pattern | Finding | Confidence | Evidence |
| --- | --- | --- | --- |
| State/presentation split | `TradeState` and `exploration_state.gd` own rules while `shop.gd`/`exploration.gd` render and handle input | confirmed | inspected scripts |
| Runtime composition | Shop adds exploration UI at runtime and injects the shared trade state | confirmed | `scripts/shop.gd` |
| Rendering | `Control`-based custom drawing plus `TextureRect`/`TextureButton`; exploration has an isolated `SubViewport` and 3D sprite layers | confirmed | inspected scripts/scenes |
| Data model | Dictionaries and `RefCounted` state; no ECS or dependency-injection framework | confirmed | `scripts/trade_state.gd`, `scripts/exploration_state.gd` |

## Coding Conventions

- GDScript with tabs/indentation as present in existing files, typed local variables where useful, `snake_case` methods/variables, and Chinese-facing strings.
- UI colors and drawing helpers are colocated in feature scripts or `popup_style.gd`.
- User-facing behavior is represented by direct Godot signals/callbacks and custom `_draw()` methods.
- No namespace or assembly system applies.

## Testing And Validation

- Headless logic tests: `tests/test_trade.gd`, `tests/test_counter_physics.gd`, `tests/test_exploration.gd`, `tests/test_exploration_travel.gd`, `tests/test_exploration_interactions.gd`, `tests/test_trade_overlay_interactions.gd`.
- Preview scripts generate PNGs under `docs/testing/previews/`.
- `tests/test_exploration_loot_autopick.gd` verifies double-click/Ctrl+click pickup placement and the full-bag notice.
- Standard commands are documented in `README.md`, using `godot --headless --path .` and `godot --path .`.
- A new battle scene should add a focused headless smoke test when its interaction logic is non-trivial.

## Available Unity Tooling

| Capability | Status | Evidence |
| --- | --- | --- |
| Unity editor/MCP | not applicable | project is Godot; no Unity project markers or Unity bridge detected |
| Godot editor/MCP | unverified | no Godot MCP tool is available in this thread |
| Repository/headless validation | available | Godot CLI and existing test scripts are present |

## Important Constraints

- Preserve existing shop and exploration behavior.
- Keep new battle work independent from the old scene when requested.
- Reuse existing `exploration_state.gd`, `TradeState`, item art, enemy art, and preview/test conventions where appropriate.
- Do not introduce packages or rework the existing scene hierarchy for this isolated addition.

## Unknowns And Confidence

- Unity-specific details are not applicable because the actual project is Godot.
- Godot editor live state and runtime console were not inspected through MCP.
- The eight external scene images are visually consistent transparent-frame forest compositions; their intended depth order is inferred from composition and will be exposed as a configurable layer sequence in the new scene.

## Source Files Inspected

- `project.godot`
- `README.md`
- `main.tscn`
- `scripts/shop.gd`
- `scripts/exploration.gd`
- `scripts/exploration_state.gd`
- `scripts/battle_space_stage.gd`
- `scenes/battle_multilayer.tscn`
- `scripts/trade_state.gd`
- `scripts/item_art.gd`
- `tests/test_exploration.gd`
- `tests/preview_exploration.gd`

<!-- unity-onboarding:generated:end -->
