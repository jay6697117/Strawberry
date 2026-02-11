
## 2026-02-11 - Task 1 Kenney-first provenance lock

- `player_style.json` runtime frame paths can be switched from `external_oga` to `res://assets/sprites/player/...` without loader changes because `player_visual.gd` only requires valid file paths and existing schema keys (`frame_rate`, `frames`, `idle`, `walk`).
- Adding a top-level `provenance` dictionary is loader-safe for both visual JSON files because loaders only read the expected keys (`frames` / `textures`) and ignore unknown fields.
- Provenance guard coverage is reliable when unit tests assert both path existence and `external_oga` exclusion for every active runtime path in player and tileset configs.

## 2026-02-11 - Task 4 camera/world-fit hardening

- Preserve a camera base zoom captured at scene init, then apply fit clamping per viewport (`min(map_width / viewport_width, map_height / viewport_height)`) so ultrawide widths avoid horizontal void while standard targets keep default framing.
- When fit clamping is active, subtracting a tiny epsilon (`0.0001`) from max-fit zoom avoids `ceil` rounding drifting one pixel beyond map bounds.
- Camera fit assertions should include offset allowance (`abs(camera.offset.x/y)`) because offset can visually exceed limits in Godot even when limit math is correct.
- Keeping `_configure_camera_limits` runtime call flow intact while allowing an override viewport size parameter provides deterministic multi-resolution integration tests without hardcoding one window setup.

## 2026-02-11 - Task 2 TileMap layer contract expansion

- `FarmTilemapView` can add decorative-only channels (`PathLayer`, `DecorLayer`, `WaterEdgeLayer`, `StructureLayer`) as `TileMap` nodes without breaking existing callers as long as `configure(tile_size, grid_width, grid_height)`, `apply_plot(cell, plot)`, and `apply_all_plots(plots)` signatures stay unchanged.
- Decorative textures are safest as optional `textures` keys (`path`, `decor`, `water_edge`, `structure`) with fallback texture generation, which keeps existing `tileset_theme.json` loaders backward compatible.
- Keeping decorative stamping in a dedicated static pass (`_paint_static_visual_layers`) and leaving `_rebuild_dynamic_layers` limited to soil/crop preserves non-gameplay, non-save-coupled behavior.

## 2026-02-11 - Task 3 deterministic dense composition pass

- `FarmWorld` can own deterministic map dressing without touching gameplay/save semantics by writing only to `PathLayer`, `DecorLayer`, `WaterEdgeLayer`, and `StructureLayer` after `FarmTilemapView.configure(...)`, while leaving `_grid_state` and `SessionState.farm_plots` flow unchanged.
- Deterministic density coverage is strongest when integration tests assert both numeric minima (`PATH >= 420`, `DECOR >= 300`, `WATER_EDGE >= 120`, `STRUCTURE >= 120`) and exact layer signature equality across two fresh world instances.
- For TileMap stamping in this repo, resolving source IDs via `tilemap.tile_set.get_source_id(0)` and guarding writes with `_is_inside_grid(...)` keeps composition deterministic and warning-clean in headless GUT runs.

## Save System Regression Testing
- Added `test/integration/test_save_load_roundtrip.gd` to provide a full regression net for the save/load cycle without relying on disk I/O.
- Validated that the save system correctly handles complex nested structures like `farm_plots` with crop metadata.
- Confirmed that the save schema (v0) is stable and compatible with the current gameplay loop state changes (end of day processing).
- Testing Strategy: Using in-memory serialization (via `build_default_save_data` and `apply_to_session`) is faster and safer than file-based tests for logic verification.

## 2026-02-11 - Task 6 Verification
- Use targeted integration tests (density, camera fit) for visual verification where unit tests are insufficient.
- Keep evidence logs concise and mapped 1:1 to acceptance criteria for fast review.
