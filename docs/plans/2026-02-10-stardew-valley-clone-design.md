# Strawberry Godot 4.3+ Farming RPG Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Godot 4.3+ 中实现一个可玩的星露谷核心循环 MVP：移动 -> 耕地 -> 种植 -> 浇水 -> 日终成长 -> 收获 -> 出货 -> 睡觉存档 -> 读档恢复。

**Architecture:** 采用“场景内聚 + 最小全局边界”架构：仅保留 `SessionState` 与 `SaveSystem` 两个 Autoload；系统之间优先使用信号通信；农场逻辑状态和 TileMap 显示状态分离，避免存档与瓦片资源强耦合。遵循 DRY、YAGNI、TDD、小步快提交流程。

**Tech Stack:** Godot 4.3+、GDScript 2.0、TileMapLayer、JSON（带 schema_version）+ 迁移器、GUT 9.4.x、Git

---

## 深度调研结论（先调研，再实施）

1. 场景组织：官方建议用 `Main -> World + GUI` 的根结构，切图只替换 `World` 下内容，UI 保持常驻，降低切场景副作用。
2. 解耦原则：场景尽量自给自足，必须依赖外部时由父节点注入（信号/Callable/引用），不要写死跨场景 NodePath。
3. Autoload 使用：Autoload 适合“全局且隔离”的系统，不适合“万能总线”。全局 EventBus 容易失控、难定位问题。
4. 逻辑时序：高频逻辑分清 `_process`、`_physics_process`、`_input`；需要可测和可复现的时间系统要用确定性 tick，而不是把业务绑死在 Timer 实时流逝上。
5. TileMapLayer：Godot 4 推荐多 TileMapLayer 分层，但“可视层”和“逻辑层”要分离；存档不要直接存 atlas/source id。
6. 存档：官方推荐 `Persist` 分组 + 节点自描述 `save()`；路径用 `user://`；复杂数据可转 binary，但 MVP 用 JSON 更易调试。
7. 项目结构：文件和资源按功能归类，文件夹/文件名统一 `snake_case`，规避跨平台大小写问题。
8. 性能策略：先 profile，再优化瓶颈；不要过早优化；大地图注意减少常驻处理节点。
9. 测试：Godot 官方 `--test` 主要面向引擎层，项目级 GDScript 自动化建议使用 GUT（Godot 4.x 可用，支持 CLI 和 JUnit XML）。

**主要参考（可直接打开）：**
- `https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html`
- `https://docs.godotengine.org/en/stable/tutorials/best_practices/scene_organization.html`
- `https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html`
- `https://docs.godotengine.org/en/stable/tutorials/best_practices/logic_preferences.html`
- `https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html`
- `https://docs.godotengine.org/en/stable/tutorials/2d/using_tilemaps.html`
- `https://docs.godotengine.org/en/stable/tutorials/performance/index.html`
- `https://github.com/godotengine/godot-demo-projects/tree/master/loading/serialization`
- `https://github.com/godotengine/godot-demo-projects/tree/master/2d/finite_state_machine`
- `https://gut.readthedocs.io/en/latest/Quick-Start.html`
- `https://gut.readthedocs.io/en/latest/Command-Line.html`

---

## 执行前置约束（必须）

- 在独立 worktree 执行（`@using-git-worktrees`）。
- 执行全流程时使用：`@test-driven-development`、`@systematic-debugging`、`@verification-before-completion`。
- 实施本计划时使用：`@executing-plans`。
- 每个 Task 完成后立刻提交（小提交，单一意图）。
- 不允许新增“全局万能管理器”；MVP 只保留 2 个 Autoload：`SessionState`、`SaveSystem`。

**一次性初始化命令（在开始 Task 1 前）：**

```bash
godot --version
```

Expected: 输出 `4.3` 或更高版本。

```bash
mkdir -p test/unit test/integration test/fixtures data/dialogues
```

Expected: 目录创建成功。

```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gh
```

Expected: 输出包含 `The GUT CLI`。

---

### Task 1: 项目骨架 + 最小全局边界

**Files:**
- Create: `project.godot`
- Create: `.gutconfig.json`
- Create: `scenes/main/main.tscn`
- Create: `scripts/autoload/session_state.gd`
- Create: `scripts/autoload/save_system.gd`
- Test: `test/unit/test_project_contract.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_main_scene_and_autoload_contract() -> void:
    assert_eq(ProjectSettings.get_setting("application/run/main_scene", ""), "res://scenes/main/main.tscn")
    assert_not_null(get_tree().root.get_node_or_null("SessionState"))
    assert_not_null(get_tree().root.get_node_or_null("SaveSystem"))
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_project_contract.gd -gexit`
Expected: FAIL，提示主场景或 Autoload 节点不存在。

**Step 3: Write minimal implementation**

```gdscript
# scripts/autoload/session_state.gd
extends Node
class_name SessionState

signal gold_changed(new_gold: int)

var day: int = 1
var season: StringName = &"spring"
var gold: int = 500:
    set(value):
        gold = max(value, 0)
        gold_changed.emit(gold)
```

```gdscript
# scripts/autoload/save_system.gd
extends Node
class_name SaveSystem

func save_game() -> Error:
    return OK

func load_game() -> Error:
    return OK
```

```ini
# project.godot (excerpt)
[application]
config/name="Strawberry"
run/main_scene="res://scenes/main/main.tscn"

[autoload]
SessionState="*res://scripts/autoload/session_state.gd"
SaveSystem="*res://scripts/autoload/save_system.gd"
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_project_contract.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add project.godot .gutconfig.json scenes/main/main.tscn scripts/autoload/session_state.gd scripts/autoload/save_system.gd test/unit/test_project_contract.gd
git commit -m "chore: bootstrap godot project contract and minimal autoloads"
```

### Task 2: Main 根场景装配（World/UI 解耦）

**Files:**
- Create: `scripts/main/main_root.gd`
- Create: `scenes/world/world_root.tscn`
- Create: `scenes/ui/ui_root.tscn`
- Modify: `scenes/main/main.tscn`
- Test: `test/integration/test_main_bootstrap.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_main_instantiates_world_and_ui() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main := add_child_autofree(packed.instantiate())
    assert_not_null(main.get_node_or_null("WorldRoot"))
    assert_not_null(main.get_node_or_null("UIRoot"))
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_main_bootstrap.gd -gexit`
Expected: FAIL，提示 `WorldRoot` 或 `UIRoot` 缺失。

**Step 3: Write minimal implementation**

```gdscript
# scripts/main/main_root.gd
extends Node

@onready var world_root: Node = $WorldRoot
@onready var ui_root: Control = $UIRoot

func _ready() -> void:
    assert(world_root != null)
    assert(ui_root != null)
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_main_bootstrap.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add scenes/main/main.tscn scenes/world/world_root.tscn scenes/ui/ui_root.tscn scripts/main/main_root.gd test/integration/test_main_bootstrap.gd
git commit -m "feat: assemble main root with separated world and ui branches"
```

### Task 3: 确定性时间系统（GameClock + DayTransaction）

**Files:**
- Create: `scripts/core/game_clock.gd`
- Create: `scripts/core/day_transaction_service.gd`
- Modify: `scripts/autoload/session_state.gd`
- Test: `test/unit/test_game_clock.gd`
- Test: `test/unit/test_day_transaction_order.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_clock_advances_in_10_minute_ticks() -> void:
    var clock := GameClock.new()
    clock.hour = 6
    clock.minute = 50
    clock.advance_tick()
    assert_eq(clock.hour, 7)
    assert_eq(clock.minute, 0)
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_game_clock.gd -gexit`
Expected: FAIL，提示 `GameClock` 或 `advance_tick` 不存在。

**Step 3: Write minimal implementation**

```gdscript
# scripts/core/game_clock.gd
extends RefCounted
class_name GameClock

signal time_tick(hour: int, minute: int)

const MINUTES_PER_TICK := 10
var day: int = 1
var hour: int = 6
var minute: int = 0

func advance_tick() -> void:
    minute += MINUTES_PER_TICK
    while minute >= 60:
        minute -= 60
        hour += 1
    time_tick.emit(hour, minute)
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_game_clock.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add scripts/core/game_clock.gd scripts/core/day_transaction_service.gd scripts/autoload/session_state.gd test/unit/test_game_clock.gd test/unit/test_day_transaction_order.gd
git commit -m "feat: add deterministic game clock and day transaction contract"
```

### Task 4: 玩家移动与工具目标格计算

**Files:**
- Create: `scenes/player/player.tscn`
- Create: `scripts/player/player_controller.gd`
- Create: `scripts/player/tool_targeting.gd`
- Test: `test/unit/test_tool_targeting.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_front_cell_uses_facing_direction() -> void:
    var target := ToolTargeting.compute_front_cell(Vector2(32, 32), Vector2i(1, 0), 16)
    assert_eq(target, Vector2i(3, 2))
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_tool_targeting.gd -gexit`
Expected: FAIL，提示 `ToolTargeting` 未定义。

**Step 3: Write minimal implementation**

```gdscript
# scripts/player/tool_targeting.gd
extends RefCounted
class_name ToolTargeting

static func compute_front_cell(global_pos: Vector2, facing: Vector2i, tile_size: int) -> Vector2i:
    var world_target := global_pos + Vector2(facing) * float(tile_size)
    return Vector2i(floor(world_target.x / tile_size), floor(world_target.y / tile_size))
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_tool_targeting.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add scenes/player/player.tscn scripts/player/player_controller.gd scripts/player/tool_targeting.gd test/unit/test_tool_targeting.gd
git commit -m "feat: implement player movement baseline and tool target calculation"
```

### Task 5: 农地逻辑状态机（逻辑层）与 TileMap 映射（显示层）

**Files:**
- Create: `scenes/farm/farm_world.tscn`
- Create: `scripts/farm/farm_grid_state.gd`
- Create: `scripts/farm/farm_tilemap_view.gd`
- Test: `test/unit/test_farm_grid_state_machine.gd`
- Modify: `scenes/world/world_root.tscn`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_till_then_water_changes_state() -> void:
    var grid := FarmGridState.new()
    var cell := Vector2i(10, 4)
    grid.till(cell)
    assert_eq(grid.get_plot(cell).soil_state, "dry")
    grid.water(cell)
    assert_eq(grid.get_plot(cell).soil_state, "wet")
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_farm_grid_state_machine.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/farm/farm_grid_state.gd
extends RefCounted
class_name FarmGridState

var _plots: Dictionary = {}

func till(cell: Vector2i) -> void:
    _plots[cell] = {"soil_state": "dry", "crop_id": "", "stage": 0, "watered": false}

func water(cell: Vector2i) -> void:
    if not _plots.has(cell):
        return
    _plots[cell]["soil_state"] = "wet"
    _plots[cell]["watered"] = true

func get_plot(cell: Vector2i) -> Dictionary:
    return _plots.get(cell, {})
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_farm_grid_state_machine.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add scenes/farm/farm_world.tscn scenes/world/world_root.tscn scripts/farm/farm_grid_state.gd scripts/farm/farm_tilemap_view.gd test/unit/test_farm_grid_state_machine.gd
git commit -m "feat: split farm logical state machine from tilemap rendering"
```

### Task 6: 作物成长与日终结算顺序

**Files:**
- Create: `data/crops.json`
- Create: `scripts/farm/crop_catalog.gd`
- Create: `scripts/farm/crop_growth_service.gd`
- Modify: `scripts/core/day_transaction_service.gd`
- Test: `test/unit/test_crop_growth_service.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_watered_crop_advances_one_stage_per_day() -> void:
    var service := CropGrowthService.new()
    var plot := {"crop_id": "parsnip", "stage": 1, "watered": true, "soil_state": "wet"}
    service.advance_plot_one_day(plot, "spring")
    assert_eq(plot["stage"], 2)
    assert_eq(plot["watered"], false)
    assert_eq(plot["soil_state"], "dry")
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_crop_growth_service.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/farm/crop_growth_service.gd
extends RefCounted
class_name CropGrowthService

func advance_plot_one_day(plot: Dictionary, season: String) -> void:
    if not plot.get("crop_id", "").is_empty() and plot.get("watered", false):
        plot["stage"] = int(plot.get("stage", 0)) + 1
    plot["watered"] = false
    plot["soil_state"] = "dry"
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_crop_growth_service.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add data/crops.json scripts/farm/crop_catalog.gd scripts/farm/crop_growth_service.gd scripts/core/day_transaction_service.gd test/unit/test_crop_growth_service.gd
git commit -m "feat: implement deterministic crop growth and day-end reset"
```

### Task 7: 背包与出货经济循环

**Files:**
- Create: `data/items.json`
- Create: `scripts/inventory/inventory_slot.gd`
- Create: `scripts/inventory/inventory_model.gd`
- Create: `scripts/economy/shipping_bin_service.gd`
- Modify: `scripts/autoload/session_state.gd`
- Test: `test/unit/test_inventory_model.gd`
- Test: `test/unit/test_shipping_bin_service.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_inventory_stacks_same_item() -> void:
    var inv := InventoryModel.new(36)
    inv.add_item("parsnip", 5)
    inv.add_item("parsnip", 7)
    assert_eq(inv.get_total("parsnip"), 12)
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_inventory_model.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/inventory/inventory_model.gd
extends RefCounted
class_name InventoryModel

var _slots: Array = []

func _init(slot_count: int = 36) -> void:
    _slots.resize(slot_count)
    for i in _slots.size():
        _slots[i] = {"item_id": "", "amount": 0}

func add_item(item_id: String, amount: int) -> void:
    for slot in _slots:
        if slot["item_id"] == item_id:
            slot["amount"] += amount
            return
    for slot in _slots:
        if slot["item_id"].is_empty():
            slot["item_id"] = item_id
            slot["amount"] = amount
            return

func get_total(item_id: String) -> int:
    var total := 0
    for slot in _slots:
        if slot["item_id"] == item_id:
            total += int(slot["amount"])
    return total
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_inventory_model.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add data/items.json scripts/inventory/inventory_slot.gd scripts/inventory/inventory_model.gd scripts/economy/shipping_bin_service.gd scripts/autoload/session_state.gd test/unit/test_inventory_model.gd test/unit/test_shipping_bin_service.gd
git commit -m "feat: add inventory stacking and shipping bin settlement"
```

### Task 8: 存档 Schema 与迁移（兼容优先）

**Files:**
- Create: `scripts/save/save_codec.gd`
- Create: `scripts/save/save_migrator.gd`
- Modify: `scripts/autoload/save_system.gd`
- Test: `test/unit/test_save_system.gd`
- Test: `test/fixtures/save_v0.json`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_save_migrates_to_current_schema() -> void:
    var raw := {"schema_version": 0, "gold": 500}
    var migrated := SaveMigrator.migrate(raw)
    assert_eq(migrated["schema_version"], SaveMigrator.CURRENT_SCHEMA)
    assert_true(migrated.has("season"))
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_save_system.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/save/save_migrator.gd
extends RefCounted
class_name SaveMigrator

const CURRENT_SCHEMA := 1

static func migrate(data: Dictionary) -> Dictionary:
    var out := data.duplicate(true)
    var version := int(out.get("schema_version", 0))
    while version < CURRENT_SCHEMA:
        if version == 0:
            out["season"] = String(out.get("season", "spring"))
            out["day"] = int(out.get("day", 1))
            out["schema_version"] = 1
        version = int(out["schema_version"])
    return out
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_save_system.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add scripts/save/save_codec.gd scripts/save/save_migrator.gd scripts/autoload/save_system.gd test/unit/test_save_system.gd test/fixtures/save_v0.json
git commit -m "feat: add versioned save schema with forward migration"
```

### Task 9: NPC 日程与对话最小闭环

**Files:**
- Create: `data/npcs.json`
- Create: `data/dialogues/merchant.json`
- Create: `scenes/npc/npc.tscn`
- Create: `scripts/npc/npc_schedule_service.gd`
- Create: `scripts/npc/dialogue_service.gd`
- Test: `test/unit/test_npc_schedule_service.gd`
- Test: `test/unit/test_dialogue_service.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_schedule_returns_expected_slot() -> void:
    var service := NpcScheduleService.new()
    var slot := service.resolve_slot(12, [
        {"time": 8, "location": "shop"},
        {"time": 12, "location": "square"}
    ])
    assert_eq(slot["location"], "square")
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_npc_schedule_service.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/npc/npc_schedule_service.gd
extends RefCounted
class_name NpcScheduleService

func resolve_slot(hour: int, schedule: Array) -> Dictionary:
    var chosen := {}
    for slot in schedule:
        if int(slot.get("time", 0)) <= hour:
            chosen = slot
    return chosen
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_npc_schedule_service.gd -gexit`
Expected: PASS。

**Step 5: Commit**

```bash
git add data/npcs.json data/dialogues/merchant.json scenes/npc/npc.tscn scripts/npc/npc_schedule_service.gd scripts/npc/dialogue_service.gd test/unit/test_npc_schedule_service.gd test/unit/test_dialogue_service.gd
git commit -m "feat: implement npc schedule resolution and dialogue selector"
```

### Task 10: 商店 + HUD + 全链路回归

**Files:**
- Create: `scenes/ui/hud.tscn`
- Create: `scenes/ui/shop_panel.tscn`
- Create: `scripts/ui/hud_controller.gd`
- Create: `scripts/economy/shop_service.gd`
- Modify: `scripts/main/main_root.gd`
- Test: `test/integration/test_full_day_loop.gd`

**Step 1: Write the failing test**

```gdscript
extends GutTest

func test_core_loop_from_seed_to_sell_updates_gold() -> void:
    var loop := CoreLoopHarness.new()
    loop.buy_seed("parsnip_seed", 1)
    loop.till_and_plant(Vector2i(5, 5), "parsnip")
    loop.water(Vector2i(5, 5))
    loop.sleep_until_mature()
    loop.harvest(Vector2i(5, 5))
    var before := loop.gold()
    loop.ship_item("parsnip", 1)
    loop.sleep_once()
    assert_gt(loop.gold(), before)
```

**Step 2: Run test to verify it fails**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_full_day_loop.gd -gexit`
Expected: FAIL。

**Step 3: Write minimal implementation**

```gdscript
# scripts/economy/shop_service.gd
extends RefCounted
class_name ShopService

func buy(session: SessionState, inventory: InventoryModel, item_id: String, price: int, amount: int) -> bool:
    var total := price * amount
    if session.gold < total:
        return false
    session.gold -= total
    inventory.add_item(item_id, amount)
    return true
```

**Step 4: Run test to verify it passes**

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_full_day_loop.gd -gexit`
Expected: PASS。

再跑一次全量：

Run: `godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit`
Expected: PASS（0 failed）。

**Step 5: Commit**

```bash
git add scenes/ui/hud.tscn scenes/ui/shop_panel.tscn scripts/ui/hud_controller.gd scripts/economy/shop_service.gd scripts/main/main_root.gd test/integration/test_full_day_loop.gd
git commit -m "feat: complete shop, hud, and full day-loop regression coverage"
```

---

## Definition of Done（每个 Task 都要满足）

- 指定测试先失败，再最小实现，再通过。
- 只实现当前 Task 必要能力（YAGNI）。
- 代码复用优先，不复制业务规则（DRY）。
- 每个 Task 独立 commit，提交信息清晰描述意图。
- 不允许用 `as any`、`@ts-ignore`（若后续引入 TS 工具链也同样适用）。

## 最终验收命令

```bash
godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gdir=res://test/integration -ginclude_subdirs -gexit
```

Expected: 全部通过，退出码为 0。
