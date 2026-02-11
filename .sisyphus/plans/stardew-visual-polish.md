# Stardew Visual Polish Plan

## TL;DR

> **Quick Summary**: Lock runtime visuals to a Kenney-first pipeline, then densify farm composition through layered TileMap rendering and deterministic map dressing, while hardening camera/world-fit behavior so the scene fills width across common resolutions.
>
> **Deliverables**:
> - Kenney-first visual config with automated provenance checks
> - Denser farm composition via new TileMap layers and deterministic decoration pass
> - Camera/world-fit regression coverage for width-fill behavior
> - Full regression verification for gameplay loop and save compatibility
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 -> Task 2 -> Task 3 -> Task 4 -> Task 5

---

## Context

### Original Request
Continue prior work and execute next steps to make the game look much closer to Stardew reference visuals, including larger/full-width map presentation.

### Interview Summary
**Key Discussions**:
- Continue now with concrete next steps; no pause.
- Art direction is locked to **Kenney-first** (recommended path).
- Keep gameplay loop and save compatibility intact.

**Research Findings**:
- TileMap migration already exists and tests currently pass.
- Runtime visual config is driven from JSON files.
- Camera limits and viewport resize handling already exist and must be improved, not replaced blindly.

### Metis Review
**Identified Gaps (addressed in this plan)**:
- Missing explicit guardrails against gameplay/saves scope creep.
- Missing objective acceptance criteria for "closer to Stardew" and width-fit.
- Missing automated provenance checks to enforce Kenney-first active runtime assets.

---

## Work Objectives

### Core Objective
Deliver a materially denser, more Stardew-like farm visual presentation by standardizing art sources, enriching map composition, and ensuring camera/world-fit quality without breaking gameplay/save behavior.

### Concrete Deliverables
- Updated runtime visual configs in `data/visual/tileset_theme.json` and `data/visual/player_style.json` using Kenney-first assets.
- Extended farm render layering in `scenes/farm/farm_world.tscn` and `scripts/farm/farm_tilemap_view.gd`.
- Deterministic composition generation updates in `scripts/farm/farm_world.gd`.
- New/updated tests in `test/unit/test_visual_resource_pipeline.gd` and integration tests for composition density and camera fit.

### Definition of Done
- [x] `./start.sh test` exits 0.
- [x] Visual provenance test proves active runtime paths do not depend on `external_oga`.
- [x] Composition density integration test passes with explicit numeric thresholds.
- [x] Camera/world-fit integration test passes for target resolutions.
- [x] Save/load and farm runtime loop tests remain green.

### Must Have
- Kenney-first runtime visual assets for active tiles/player.
- Wider and denser farm composition with clear visual zones (paths/fields/tree belts/props/water edges).
- Width-fit behavior validated by automated tests.

### Must NOT Have (Guardrails)
- No changes to save schema or serialization contract.
- No new gameplay mechanics, economy changes, or interaction system expansions.
- No removal/rename of test-critical farm scene node contract.
- No dependence on subjective manual-only acceptance.

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> All acceptance criteria below are agent-executable via command/tool outputs. No human visual confirmation is required for pass/fail.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: YES (tests-after with targeted red/green for new contracts)
- **Framework**: GUT (Godot headless test runner)

### Agent-Executed QA Scenarios (MANDATORY)

Each task includes concrete scenarios with explicit commands/assertions and evidence paths under `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

Wave 1 (Start Immediately):
- Task 1 (Kenney-first provenance lock)
- Task 6 (final verification harness prep)

Wave 2 (After Wave 1):
- Task 2 (TileMap layer expansion)
- Task 4 (camera fit hardening baseline tests)

Wave 3 (After Wave 2):
- Task 3 (deterministic dense composition)
- Task 5 (integration regression + save compatibility)

Critical Path: 1 -> 2 -> 3 -> 4 -> 5

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|----------------------|
| 1 | None | 2, 3 | 6 |
| 2 | 1 | 3, 5 | 4 |
| 3 | 2 | 5 | None |
| 4 | 1 | 5 | 2 |
| 5 | 2, 3, 4 | None | None |
| 6 | None | None | 1 |

---

## TODOs

- [x] 1. Lock Kenney-First Runtime Asset Provenance

  **What to do**:
  - Update active runtime style paths in `data/visual/player_style.json` and `data/visual/tileset_theme.json` to Kenney-first sources.
  - Keep naming/contract stable so current loaders continue working.
  - Extend `test/unit/test_visual_resource_pipeline.gd` with assertions that active runtime style paths do not reference `external_oga`.

  **Must NOT do**:
  - Do not alter gameplay scripts or save behavior.
  - Do not introduce mixed runtime defaults that silently fall back to OGA.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: focused config and contract test updates.
  - **Skills**: `test-driven-development`, `systematic-debugging`
    - `test-driven-development`: enforce contract assertions first.
    - `systematic-debugging`: fast diagnosis if loader paths fail.
  - **Skills Evaluated but Omitted**:
    - `frontend-design`: not needed for non-UI config wiring.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 6)
  - **Blocks**: 2, 3
  - **Blocked By**: None

  **References**:
  - `data/visual/player_style.json` - active directional frame source paths.
  - `data/visual/tileset_theme.json` - active tile textures and crop stages.
  - `scripts/player/player_visuals.gd` - expected player style schema usage.
  - `scripts/farm/farm_tilemap_view.gd` - expected tile theme schema usage.
  - `test/unit/test_visual_resource_pipeline.gd` - contract test location.

  **Acceptance Criteria**:
  - [x] `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_visual_resource_pipeline.gd -gexit` exits 0.
  - [x] Added assertions verify active runtime style paths do not contain `external_oga`.
  - [x] Runtime loader still resolves all declared textures/frames.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Kenney provenance contract stays green
    Tool: Bash (GUT command)
    Preconditions: Repository root, Godot available, test file present
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_visual_resource_pipeline.gd -gexit
      2. Assert: process exit code is 0
      3. Assert: output includes test names for player style and tileset theme contracts
      4. Save output to: .sisyphus/evidence/task-1-provenance-test.log
    Expected Result: Unit visual pipeline tests pass with Kenney-first paths
    Failure Indicators: non-zero exit, missing frame/texture path errors, any `external_oga` assertion failure
    Evidence: .sisyphus/evidence/task-1-provenance-test.log

  Scenario: Runtime config JSON parse remains valid
    Tool: Bash
    Preconditions: Updated JSON files saved
    Steps:
      1. Run: python -m json.tool data/visual/player_style.json > /tmp/player_style.pretty.json
      2. Run: python -m json.tool data/visual/tileset_theme.json > /tmp/tileset_theme.pretty.json
      3. Assert: both commands exit 0
      4. Save terminal output to: .sisyphus/evidence/task-1-json-validate.log
    Expected Result: JSON files are syntactically valid
    Failure Indicators: parse errors, missing keys from prior contract
    Evidence: .sisyphus/evidence/task-1-json-validate.log
  ```

  **Commit**: YES
  - Message: `chore(visual): lock runtime assets to kenney-first`
  - Files: `data/visual/player_style.json`, `data/visual/tileset_theme.json`, `test/unit/test_visual_resource_pipeline.gd`
  - Pre-commit: unit visual pipeline test command above

- [x] 2. Expand TileMap Layer Contract for Dense Composition

  **What to do**:
  - Add non-gameplay visual layers in `scenes/farm/farm_world.tscn` (for example: `PathLayer`, `DecorLayer`, `WaterEdgeLayer`, `StructureLayer`) while preserving existing `GroundLayer`/`SoilLayer`/`CropLayer`.
  - Update `scripts/farm/farm_tilemap_view.gd` to configure and write cells for these layers.
  - Keep API compatibility for existing calls (`configure`, `apply_plot`, `apply_all_plots`).

  **Must NOT do**:
  - Do not break current node paths expected by integration tests.
  - Do not mix gameplay state into decorative-only layers.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: multi-file scene/script contract changes with regression risk.
  - **Skills**: `test-driven-development`, `systematic-debugging`
    - `test-driven-development`: protect node/layer contract with tests first.
    - `systematic-debugging`: fast triage for scene-node path breakages.
  - **Skills Evaluated but Omitted**:
    - `vue-best-practices`: not applicable to Godot GDScript scenes.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 4)
  - **Blocks**: 3, 5
  - **Blocked By**: 1

  **References**:
  - `scenes/farm/farm_world.tscn` - farm visual layer node structure.
  - `scripts/farm/farm_tilemap_view.gd` - tile write APIs and runtime tileset build.
  - `test/integration/test_main_bootstrap.gd` - current expected scene contract.
  - `scripts/farm/farm_world.gd` - caller integration points to render view.

  **Acceptance Criteria**:
  - [x] Existing integration tests for farm bootstrap still pass.
  - [x] New visual layers exist and are writable via render script.
  - [x] `configure/apply_plot/apply_all_plots` API remains backward compatible.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Layer contract integrity after expansion
    Tool: Bash (GUT command)
    Preconditions: Scene and tilemap view script updated
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_main_bootstrap.gd -gexit
      2. Assert: process exit code is 0
      3. Assert: output contains farm layer contract test names
      4. Save output to: .sisyphus/evidence/task-2-layer-contract.log
    Expected Result: Bootstrap contract remains valid with new layers added
    Failure Indicators: missing node path errors, type mismatch for TileMap layers
    Evidence: .sisyphus/evidence/task-2-layer-contract.log

  Scenario: TileMap view API compatibility retained
    Tool: Bash (GUT command)
    Preconditions: Unit or integration tests cover `configure/apply_plot/apply_all_plots`
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit
      2. Assert: exit code is 0
      3. Save output to: .sisyphus/evidence/task-2-api-compat.log
    Expected Result: Existing callers operate without API changes
    Failure Indicators: missing method errors, changed argument contract failures
    Evidence: .sisyphus/evidence/task-2-api-compat.log
  ```

  **Commit**: YES
  - Message: `feat(farm): add layered tilemap channels for dense composition`
  - Files: `scenes/farm/farm_world.tscn`, `scripts/farm/farm_tilemap_view.gd`, related tests
  - Pre-commit: integration bootstrap test

- [x] 3. Implement Deterministic Dense Farm Composition Pass

  **What to do**:
  - Extend `scripts/farm/farm_world.gd` with deterministic composition rules to stamp paths, field borders, tree belts, clustered props, and optional water-edge accents onto non-gameplay layers.
  - Keep playable farm plot coordinates and crop/soil semantics unchanged.
  - Add integration test `test/integration/test_farm_map_composition_density.gd` with numeric density thresholds (for example minimum used cells per decorative layers).

  **Must NOT do**:
  - Do not change save data interpretation of farm plot keys.
  - Do not add interactive/collision semantics to decorative stamps unless explicitly required later.

  **Recommended Agent Profile**:
  - **Category**: `ultrabrain`
    - Reason: rule design + deterministic constraints + regression-safe layout logic.
  - **Skills**: `test-driven-development`, `systematic-debugging`
    - `test-driven-development`: pin numeric composition contracts before refactor.
    - `systematic-debugging`: isolate coordinate and bounds bugs quickly.
  - **Skills Evaluated but Omitted**:
    - `frontend-ui-ux`: not primary for map generation logic.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3)
  - **Blocks**: 5
  - **Blocked By**: 2

  **References**:
  - `scripts/farm/farm_world.gd` - farm initialization and plot rendering lifecycle.
  - `scripts/farm/farm_tilemap_view.gd` - target API for layer cell writes.
  - `data/visual/tileset_theme.json` - tile texture keys available for stamps.
  - `test/integration/test_main_bootstrap.gd` - baseline world bootstrap behavior.
  - `scripts/autoload/session_state.gd` - plot state source to preserve.

  **Acceptance Criteria**:
  - [x] New integration test proves deterministic density thresholds (same seed/config => same used cell counts).
  - [x] Decorative layers show non-trivial occupancy (set concrete minimums in test).
  - [x] Existing farm plot apply behavior remains unchanged.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Deterministic density contract
    Tool: Bash (GUT command)
    Preconditions: New integration test implemented
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_farm_map_composition_density.gd -gexit
      2. Assert: process exit code is 0
      3. Assert: output includes thresholds (for example: decor_used_cells >= 300, path_used_cells >= 180)
      4. Save output to: .sisyphus/evidence/task-3-density.log
    Expected Result: Density thresholds pass and deterministic checks remain stable
    Failure Indicators: flaky counts across runs, below-threshold occupancy, out-of-bounds write errors
    Evidence: .sisyphus/evidence/task-3-density.log

  Scenario: Save plot semantics unchanged under dense composition
    Tool: Bash (GUT command)
    Preconditions: Existing save/session tests available
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit
      2. Assert: exit code is 0
      3. Save output to: .sisyphus/evidence/task-3-save-semantics.log
    Expected Result: Decorative composition does not alter plot serialization behavior
    Failure Indicators: changed plot key schema, mismatched plot restoration on load
    Evidence: .sisyphus/evidence/task-3-save-semantics.log
  ```

  **Commit**: YES
  - Message: `feat(farm): add deterministic dense map composition pass`
  - Files: `scripts/farm/farm_world.gd`, density integration test, related visual config updates
  - Pre-commit: density integration test

- [x] 4. Harden Camera/World-Fit for Width-Fill Behavior

  **What to do**:
  - Refine camera limits/zoom logic in `scripts/farm/farm_world.gd` so runtime view avoids horizontal void across target resolutions.
  - Add integration test `test/integration/test_farm_camera_world_fit.gd` for at least: 1280x720, 1536x960, 1920x1080, 2560x1080.
  - Keep viewport resize callbacks stable.

  **Must NOT do**:
  - Do not hardcode one-resolution assumptions.
  - Do not break existing camera follow behavior.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: camera math + multi-resolution contract verification.
  - **Skills**: `systematic-debugging`, `test-driven-development`
    - `systematic-debugging`: ideal for geometric edge-case failures.
    - `test-driven-development`: codify resolution-fit contracts first.
  - **Skills Evaluated but Omitted**:
    - `vercel-react-best-practices`: irrelevant to Godot camera logic.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 2)
  - **Blocks**: 5
  - **Blocked By**: 1

  **References**:
  - `scripts/farm/farm_world.gd` - camera limits and resize hook points.
  - `project.godot` - stretch and base viewport settings.
  - `scripts/farm/farm_tilemap_view.gd` - map dimensions used for bounds.

  **Acceptance Criteria**:
  - [x] Camera fit integration test passes all target resolutions.
  - [x] No horizontal blank-space condition detected by test assertions.
  - [x] Existing world bootstrap and loop tests remain green.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Multi-resolution width-fit contract
    Tool: Bash (GUT command)
    Preconditions: Camera fit test created
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_farm_camera_world_fit.gd -gexit
      2. Assert: process exit code is 0
      3. Assert: test output includes all target resolutions checked
      4. Save output to: .sisyphus/evidence/task-4-camera-fit.log
    Expected Result: Width-fit checks pass across all listed resolutions
    Failure Indicators: any resolution reports horizontal gap/void or invalid limits
    Evidence: .sisyphus/evidence/task-4-camera-fit.log

  Scenario: Viewport resize stability
    Tool: Bash (GUT command)
    Preconditions: Resize callback logic active
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_farm_camera_world_fit.gd -gexit
      2. Assert: no runtime errors during repeated resize events
      3. Save output to: .sisyphus/evidence/task-4-resize-stability.log
    Expected Result: Camera limits update cleanly on resize
    Failure Indicators: stale limits, exceptions, jitter-causing invalid limit values
    Evidence: .sisyphus/evidence/task-4-resize-stability.log
  ```

  **Commit**: YES
  - Message: `fix(camera): enforce width-fit contracts across target resolutions`
  - Files: `scripts/farm/farm_world.gd`, camera fit integration test
  - Pre-commit: camera fit integration test

- [x] 5. Add Regression Net for Gameplay Loop + Save Compatibility

  **What to do**:
  - Run and, if needed, strengthen tests covering save/load and farm runtime loop.
  - Ensure dense visual composition does not regress session state application.
  - Validate complete suite stays green after all visual/camera changes.

  **Must NOT do**:
  - Do not introduce save migration work unless tests prove necessary.
  - Do not alter business logic as a shortcut to satisfy visual tests.

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: test hardening and regression stabilization pass.
  - **Skills**: `systematic-debugging`, `verification-before-completion`
    - `systematic-debugging`: isolate regressions rapidly.
    - `verification-before-completion`: enforce evidence-before-claims discipline.
  - **Skills Evaluated but Omitted**:
    - `frontend-design`: no new presentation design decisions here.

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (Wave 3 end)
  - **Blocks**: Final handoff
  - **Blocked By**: 2, 3, 4

  **References**:
  - `scripts/autoload/save_system.gd` - serialization and save/load behavior.
  - `scripts/autoload/session_state.gd` - runtime state model.
  - `scripts/farm/farm_world.gd` - apply/save hooks and plot rendering flow.
  - `test/integration/test_main_bootstrap.gd` - baseline integration entry checks.
  - `test/unit/test_visual_resource_pipeline.gd` - visual contracts that must remain green.

  **Acceptance Criteria**:
  - [x] Save-related tests pass.
  - [x] Farm runtime loop integration tests pass.
  - [x] Full test command passes with exit code 0.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Full suite regression gate
    Tool: Bash
    Preconditions: All prior tasks complete
    Steps:
      1. Run: ./start.sh test
      2. Assert: process exit code is 0
      3. Assert: output reports zero failures
      4. Save output to: .sisyphus/evidence/task-5-full-suite.log
    Expected Result: Entire suite remains green after visual/camera changes
    Failure Indicators: any failing unit/integration test, runtime bootstrap errors
    Evidence: .sisyphus/evidence/task-5-full-suite.log

  Scenario: Save/load focused regression
    Tool: Bash (GUT command)
    Preconditions: Save tests available in repository
    Steps:
      1. Run: godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit
      2. Assert: exit code is 0
      3. Save output to: .sisyphus/evidence/task-5-save-regression.log
    Expected Result: Save/load behavior unchanged
    Failure Indicators: missing field persistence, wrong restored plot states
    Evidence: .sisyphus/evidence/task-5-save-regression.log
  ```

  **Commit**: YES
  - Message: `test(regression): harden save and farm runtime guards`
  - Files: integration/unit regression tests touched in this phase
  - Pre-commit: `./start.sh test`

- [x] 6. Evidence and Handoff Packaging

  **What to do**:
  - Collect logs from all scenario commands into `.sisyphus/evidence/`.
  - Prepare final verification summary listing command, result, and evidence path.
  - Ensure no unresolved TODO placeholders remain.

  **Must NOT do**:
  - Do not claim completion without command evidence.
  - Do not omit failed-command diagnostics.

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: verification artifact curation and concise handoff.
  - **Skills**: `verification-before-completion`
    - `verification-before-completion`: ensures factual completion report.
  - **Skills Evaluated but Omitted**:
    - `requesting-code-review`: optional post-plan, not required for evidence collation.

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 prep + final wrap
  - **Blocks**: none
  - **Blocked By**: none for prep; final summary waits for Task 5

  **References**:
  - `.sisyphus/evidence/` - canonical evidence artifact directory.
  - `README.md` - quick verification command conventions if needed.

  **Acceptance Criteria**:
  - [x] Evidence logs present for each task scenario.
  - [x] Final summary maps each acceptance criterion to a command and artifact path.

  **Agent-Executed QA Scenarios**:

  ```text
  Scenario: Evidence completeness check
    Tool: Bash
    Preconditions: Scenario logs generated
    Steps:
      1. Run: ls .sisyphus/evidence
      2. Assert: files exist for task-1 through task-5 scenario outputs
      3. Save listing to: .sisyphus/evidence/task-6-evidence-index.log
    Expected Result: Evidence folder contains traceable artifacts per acceptance criterion
    Failure Indicators: missing task evidence files, unnamed/ambiguous artifacts
    Evidence: .sisyphus/evidence/task-6-evidence-index.log
  ```

  **Commit**: NO

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `chore(visual): lock runtime assets to kenney-first` | visual JSON + unit test | visual pipeline unit test |
| 2 | `feat(farm): add layered tilemap channels for dense composition` | farm scene + tilemap view + tests | bootstrap integration test |
| 3 | `feat(farm): add deterministic dense map composition pass` | farm world + density test | density integration test |
| 4 | `fix(camera): enforce width-fit contracts across target resolutions` | farm world + camera fit test | camera fit integration test |
| 5 | `test(regression): harden save and farm runtime guards` | regression test files | `./start.sh test` |

---

## Success Criteria

### Verification Commands
```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_visual_resource_pipeline.gd -gexit
# Expected: exit 0

godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_main_bootstrap.gd -gexit
# Expected: exit 0

godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_farm_map_composition_density.gd -gexit
# Expected: exit 0

godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_farm_camera_world_fit.gd -gexit
# Expected: exit 0

./start.sh test
# Expected: exit 0
```

### Final Checklist
- [x] All Must Have conditions satisfied.
- [x] All Must NOT Have guardrails respected.
- [x] Kenney-first runtime provenance enforced by tests.
- [x] Width-fit behavior verified by automated integration checks.
- [x] Gameplay loop and save compatibility remain intact.
