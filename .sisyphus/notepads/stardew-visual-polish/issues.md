
## 2026-02-11 - Godot 4.x pitfalls to watch

- `TileMap` is deprecated in 4.6, but this repo still relies on `TileMap` nodes and tests assert that contract; migrating directly to `TileMapLayer` in-place will break scene/test contracts unless tests and node paths are updated together (sources: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_tilemap.rst#L16-L17, `test/integration/test_main_bootstrap.gd:52`).
- Camera limits can appear to fail if `offset` is used for shake/look-ahead, because offset is allowed to push the camera past `limit_*`; assertions must account for this (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_camera2d.rst#L511-L583).
- `limit_smoothed` does nothing unless `position_smoothing_enabled` is true; enabling one without the other creates misleading behavior during resize/limit tests (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_camera2d.rst#L534-L600).
- Y-sorted and non-Y-sorted tile layers sharing the same Z bucket can produce undesirable sorting artifacts; keep them on separate Z/index plans (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_tilemap.rst#L1037-L1040).
- TileMap built-in navigation has practical limitations, and stacking 2D nav meshes on one nav map causes merge/pathfinding errors; decorative layer expansion must avoid accidental nav-layer stacking (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/tutorials/2d/using_tilemaps.rst#L86-L92).
- Runtime tile-data hooks are expensive and can mutate shared TileSet sub-resources if used incorrectly; only opt in per-cell when needed and call `notify_runtime_tile_data_update()` sparingly (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_tilemaplayer.rst#L468-L518, https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_tilemaplayer.rst#L812-L819).
- Integer stretch scaling improves pixel crispness but can introduce black bars and clipping when window size drops below base viewport; this conflicts with strict fill-width expectations if not tested explicitly (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/classes/class_projectsettings.rst#L5023-L5035, https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/tutorials/rendering/multiple_resolutions.rst#L327-L337).
- `Detect 3D` import behavior can silently switch textures toward VRAM-compressed paths that harm pixel-art quality; keep compression policy explicit for 2D assets (source: https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/tutorials/assets_pipeline/importing_images.rst#L118-L135, https://github.com/godotengine/godot-docs/blob/bf0ea4d3d4935249c7e30078ff0445f7f030ac20/tutorials/assets_pipeline/importing_images.rst#L158-L185).

## 2026-02-11 - Task 1 execution notes

- GDScript LSP diagnostics could not run for `test/unit/test_visual_resource_pipeline.gd` because configured server `my-server` (`my-lsp`) is not installed in this environment; JSON diagnostics succeeded and the GUT headless test command was used as runtime verification evidence.

## 2026-02-11 - Task 4 execution notes

- GDScript LSP diagnostics remain unavailable for `scripts/farm/farm_world.gd` and `test/integration/test_farm_camera_world_fit.gd` because configured server `my-server` (`my-lsp`) is not installed; verification was completed with headless GUT integration and full-suite runs.

## 2026-02-11 - Task 2 gotchas

- GUT treats some engine warnings as test failures: integer/int division in GDScript (`_grid_height / 2`) triggered `INTEGER_DIVISION` unexpected-error failures during integration runs. Use explicit float division + cast (`int(_grid_height / 2.0)`) for warning-clean execution.
- GDScript LSP diagnostics remain blocked in this environment because `my-lsp` is not installed; verification has to rely on headless Godot test execution until the server is available.

## 2026-02-11 - Task 3 unresolved risk

- GDScript LSP diagnostics are still unavailable for `scripts/farm/farm_world.gd` and `test/integration/test_farm_map_composition_density.gd` because configured server `my-server` (`my-lsp`) is not installed; static diagnostics could not be collected, so verification depended on headless GUT targeted + full-suite execution.

## 2026-02-11 - Task 6 Verification
- GDScript LSP missing; relying on GUT command-line output for verification is slower but reliable.
