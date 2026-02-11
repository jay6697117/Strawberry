extends Node2D

signal status_changed(text: String)
signal inventory_changed(seed_count: int, crop_count: int, pending_count: int)

const TILE_SIZE := 32
const GRID_WIDTH := 64
const GRID_HEIGHT := 36
const MAX_CROP_STAGE := 4

@onready var farm_tilemap_view: Node2D = $FarmTilemapView
@onready var player: CharacterBody2D = $Player

var _grid_state := FarmGridState.new()
var _growth_service := CropGrowthService.new()
var _shipping_bin := ShippingBinService.new()
var _day_tx := DayTransactionService.new()
var _crop_catalog := CropCatalog.new()
var _crop_data: Dictionary = {}
var _day_steps: Array[String] = []
var _latest_status: String = ""
var _camera_ref: Camera2D

func _ready() -> void:
    _crop_data = _crop_catalog.load_all()
    _ensure_input_actions()
    _initialize_player()
    _initialize_view()
    _bootstrap_inventory()
    _restore_world_from_session()
    _day_tx.step_executed.connect(_on_day_step)

    _emit_inventory_metrics()
    _emit_status("Ready")

func request_hud_sync() -> void:
    _emit_inventory_metrics()
    if _latest_status.is_empty():
        _emit_status("Ready")
    else:
        status_changed.emit(_latest_status)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("farm_till"):
        _on_till_request()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("farm_water"):
        _on_water_request()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("farm_plant"):
        _on_plant_request()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("farm_harvest"):
        _on_harvest_request()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("farm_end_day"):
        _on_end_day_request()
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("farm_ship"):
        _on_ship_request()
        get_viewport().set_input_as_handled()

func _initialize_player() -> void:
    player.global_position = _cell_center(Vector2i(6, 6))

func _initialize_view() -> void:
    if farm_tilemap_view.has_method("configure"):
        farm_tilemap_view.configure(TILE_SIZE, GRID_WIDTH, GRID_HEIGHT)

    var camera := player.get_node_or_null("Camera2D") as Camera2D
    if camera != null:
        _camera_ref = camera
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 6.0
        _configure_camera_limits(camera)

        var viewport := get_viewport()
        if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
            viewport.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
    if _camera_ref != null:
        _configure_camera_limits(_camera_ref)

func _configure_camera_limits(camera: Camera2D) -> void:
    var map_width := GRID_WIDTH * TILE_SIZE
    var map_height := GRID_HEIGHT * TILE_SIZE
    var viewport_size := get_viewport_rect().size

    var half_width := int(ceil((viewport_size.x * 0.5) * camera.zoom.x))
    var half_height := int(ceil((viewport_size.y * 0.5) * camera.zoom.y))

    if map_width <= half_width * 2:
        camera.limit_left = 0
        camera.limit_right = map_width
    else:
        camera.limit_left = half_width
        camera.limit_right = map_width - half_width

    if map_height <= half_height * 2:
        camera.limit_top = 0
        camera.limit_bottom = map_height
    else:
        camera.limit_top = half_height
        camera.limit_bottom = map_height - half_height

func _bootstrap_inventory() -> void:
    if SessionState.inventory.get_total("parsnip_seed") <= 0:
        SessionState.inventory.add_item("parsnip_seed", 15)

func _on_till_request() -> void:
    var cell := _player_front_cell()
    if not _is_inside_grid(cell):
        _emit_status("Out of farm bounds")
        return
    if not _grid_state.has_plot(cell):
        _grid_state.till(cell)
        _apply_plot_to_view(cell)
        _sync_plots_to_session()
        _emit_status("Tilled plot at [%d, %d]" % [cell.x, cell.y])
        return

    var plot := _grid_state.get_plot(cell)
    if String(plot.get("crop_id", "")).is_empty():
        plot["soil_state"] = "dry"
        plot["watered"] = false
        _grid_state.set_plot(cell, plot)
        _apply_plot_to_view(cell)
        _sync_plots_to_session()
        _emit_status("Reset soil at [%d, %d]" % [cell.x, cell.y])
    else:
        _emit_status("Plot already has a crop")

func _on_water_request() -> void:
    var cell := _player_front_cell()
    if not _grid_state.has_plot(cell):
        _emit_status("Till soil first")
        return
    _grid_state.water(cell)
    _apply_plot_to_view(cell)
    _sync_plots_to_session()
    _emit_status("Watered plot at [%d, %d]" % [cell.x, cell.y])

func _on_plant_request() -> void:
    var cell := _player_front_cell()
    if not _grid_state.has_plot(cell):
        _emit_status("Till soil before planting")
        return

    var plot := _grid_state.get_plot(cell)
    if not String(plot.get("crop_id", "")).is_empty():
        _emit_status("Crop already planted")
        return

    if SessionState.inventory.get_total("parsnip_seed") <= 0:
        _emit_status("No parsnip seeds left")
        return
    if not SessionState.inventory.remove_item("parsnip_seed", 1):
        _emit_status("Failed to consume seed")
        return

    plot["crop_id"] = "parsnip"
    plot["stage"] = 0
    _grid_state.set_plot(cell, plot)
    _apply_plot_to_view(cell)
    _sync_plots_to_session()
    _emit_inventory_metrics()
    _emit_status("Planted parsnip at [%d, %d]" % [cell.x, cell.y])

func _on_harvest_request() -> void:
    var cell := _player_front_cell()
    if not _grid_state.has_plot(cell):
        _emit_status("Nothing to harvest")
        return

    var plot := _grid_state.get_plot(cell)
    var crop_id := String(plot.get("crop_id", ""))
    if crop_id.is_empty():
        _emit_status("No crop planted")
        return

    var stage := int(plot.get("stage", 0))
    var required_stage := _crop_ready_stage(crop_id)
    if stage < required_stage:
        _emit_status("Crop not ready yet")
        return

    SessionState.inventory.add_item(crop_id, 1)
    plot["crop_id"] = ""
    plot["stage"] = 0
    _grid_state.set_plot(cell, plot)
    _apply_plot_to_view(cell)
    _sync_plots_to_session()
    _emit_inventory_metrics()
    _emit_status("Harvested 1 %s" % crop_id)

func _on_end_day_request() -> void:
    _day_steps.clear()
    var plots := _grid_state.get_all_plots()
    for cell in plots.keys():
        var plot := _grid_state.get_plot(cell)
        _growth_service.advance_plot_one_day(plot, String(SessionState.season))
        _grid_state.set_plot(cell, plot)
        _apply_plot_to_view(cell)
    _sync_plots_to_session()

    var earned := _settle_shipping_bin()
    _day_tx.end_day()
    SessionState.day += 1
    if SaveSystem.has_method("save_game"):
        SaveSystem.save_game()

    if earned > 0:
        _emit_status("Day %d ended, shipping +%dG" % [SessionState.day, earned])
    else:
        _emit_status("Day %d ended" % SessionState.day)
    _emit_inventory_metrics()

func _on_ship_request() -> void:
    var amount := SessionState.inventory.get_total("parsnip")
    if amount <= 0:
        _emit_status("No parsnips to ship")
        return
    if not SessionState.inventory.remove_item("parsnip", amount):
        _emit_status("Failed to move crop into shipping bin")
        return

    _shipping_bin.add_item("parsnip", amount)
    _emit_inventory_metrics()
    _emit_status("Queued %d parsnip(s) for day-end shipping" % amount)

func _settle_shipping_bin() -> int:
    if _shipping_bin.pending_count() <= 0:
        return 0
    var price := _sell_price("parsnip")
    return _shipping_bin.settle_to_session(SessionState, {"parsnip": price})

func _crop_ready_stage(crop_id: String) -> int:
    if _crop_data.has(crop_id):
        var data := Dictionary(_crop_data[crop_id])
        var stages := int(data.get("stages", MAX_CROP_STAGE + 1))
        return maxi(stages - 1, 1)
    return MAX_CROP_STAGE

func _sell_price(crop_id: String) -> int:
    if _crop_data.has(crop_id):
        return int(Dictionary(_crop_data[crop_id]).get("sell_price", 0))
    return 0

func _on_day_step(step: String) -> void:
    _day_steps.append(step)

func _apply_plot_to_view(cell: Vector2i) -> void:
    if farm_tilemap_view.has_method("apply_plot"):
        farm_tilemap_view.apply_plot(cell, _grid_state.get_plot(cell))

func _player_front_cell() -> Vector2i:
    if player.has_method("get_front_cell"):
        return player.get_front_cell(TILE_SIZE)
    return Vector2i.ZERO

func _is_inside_grid(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_WIDTH and cell.y < GRID_HEIGHT

func _cell_center(cell: Vector2i) -> Vector2:
    return Vector2((float(cell.x) + 0.5) * TILE_SIZE, (float(cell.y) + 0.5) * TILE_SIZE)

func _emit_inventory_metrics() -> void:
    inventory_changed.emit(
        SessionState.inventory.get_total("parsnip_seed"),
        SessionState.inventory.get_total("parsnip"),
        _shipping_bin.pending_count()
    )

func _emit_status(text: String) -> void:
    _latest_status = text
    status_changed.emit(text)

func _restore_world_from_session() -> void:
    var entries := SessionState.farm_plots
    if typeof(entries) != TYPE_ARRAY or entries.is_empty():
        return

    for entry in entries:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var plot_data: Variant = entry.get("plot", {})
        if typeof(plot_data) != TYPE_DICTIONARY:
            continue

        var cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
        if not _is_inside_grid(cell):
            continue
        _grid_state.set_plot(cell, Dictionary(plot_data).duplicate(true))

    if farm_tilemap_view.has_method("apply_all_plots"):
        farm_tilemap_view.apply_all_plots(_grid_state.get_all_plots())

func _sync_plots_to_session() -> void:
    SessionState.farm_plots = _serialize_grid_plots()

func _serialize_grid_plots() -> Array:
    var out: Array = []
    var all_plots := _grid_state.get_all_plots()
    for cell in all_plots.keys():
        var plot_data := Dictionary(all_plots[cell]).duplicate(true)
        out.append({
            "x": int(cell.x),
            "y": int(cell.y),
            "plot": plot_data
        })
    return out

func _ensure_input_actions() -> void:
    _ensure_key_actions("move_left", [KEY_A, KEY_LEFT])
    _ensure_key_actions("move_right", [KEY_D, KEY_RIGHT])
    _ensure_key_actions("move_up", [KEY_W, KEY_UP])
    _ensure_key_actions("move_down", [KEY_S, KEY_DOWN])
    _ensure_key_actions("farm_till", [KEY_F])
    _ensure_key_actions("farm_water", [KEY_G])
    _ensure_key_actions("farm_plant", [KEY_H])
    _ensure_key_actions("farm_harvest", [KEY_J])
    _ensure_key_actions("farm_end_day", [KEY_K])
    _ensure_key_actions("farm_ship", [KEY_L])

func _ensure_key_actions(action: StringName, keys: Array[Key]) -> void:
    for key in keys:
        _ensure_key_action(action, key)

func _ensure_key_action(action: StringName, keycode: Key) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)

    for event in InputMap.action_get_events(action):
        if event is InputEventKey and event.physical_keycode == keycode:
            return

    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action, input_event)
