extends Node2D

signal status_changed(text: String)
signal inventory_changed(seed_count: int, crop_count: int, pending_count: int)

const TILE_SIZE := 32
const GRID_WIDTH := 64
const GRID_HEIGHT := 36
const MAX_CROP_STAGE := 4
const PATH_COLUMN_STRIDE := 8
const PATH_ROW_STRIDE := 6

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
var _camera_base_zoom := Vector2.ONE

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
    _apply_dense_composition_pass()

    var camera := player.get_node_or_null("Camera2D") as Camera2D
    if camera != null:
        _camera_ref = camera
        _camera_base_zoom = camera.zoom
        camera.position_smoothing_enabled = true
        camera.position_smoothing_speed = 6.0
        _configure_camera_limits(camera)

        var viewport := get_viewport()
        if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
            viewport.size_changed.connect(_on_viewport_size_changed)

func _apply_dense_composition_pass() -> void:
    if farm_tilemap_view == null:
        return

    var path_layer := farm_tilemap_view.get_node_or_null("PathLayer") as TileMap
    var decor_layer := farm_tilemap_view.get_node_or_null("DecorLayer") as TileMap
    var water_edge_layer := farm_tilemap_view.get_node_or_null("WaterEdgeLayer") as TileMap
    var structure_layer := farm_tilemap_view.get_node_or_null("StructureLayer") as TileMap
    if path_layer == null or decor_layer == null or water_edge_layer == null or structure_layer == null:
        return

    var path_source_id := _primary_source_id(path_layer)
    var decor_source_id := _primary_source_id(decor_layer)
    var water_source_id := _primary_source_id(water_edge_layer)
    var structure_source_id := _primary_source_id(structure_layer)
    if path_source_id < 0 or decor_source_id < 0 or water_source_id < 0 or structure_source_id < 0:
        return

    path_layer.clear()
    decor_layer.clear()
    water_edge_layer.clear()
    structure_layer.clear()

    _stamp_path_network(path_layer, path_source_id)
    _stamp_field_borders(structure_layer, structure_source_id)
    _stamp_tree_belts(decor_layer, decor_source_id)
    _stamp_prop_clusters(decor_layer, structure_layer, decor_source_id, structure_source_id)
    _stamp_water_edge_accents(water_edge_layer, water_source_id)

func _primary_source_id(tilemap: TileMap) -> int:
    var tile_set := tilemap.tile_set
    if tile_set == null:
        return -1
    if tile_set.get_source_count() <= 0:
        return -1
    return int(tile_set.get_source_id(0))

func _stamp_path_network(path_layer: TileMap, source_id: int) -> void:
    for x in range(GRID_WIDTH):
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(x, 0))
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(x, GRID_HEIGHT - 1))

    for y in range(GRID_HEIGHT):
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(0, y))
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(GRID_WIDTH - 1, y))

    for y in range(PATH_ROW_STRIDE, GRID_HEIGHT - 1, PATH_ROW_STRIDE):
        for x in range(1, GRID_WIDTH - 1):
            _set_non_gameplay_cell(path_layer, source_id, Vector2i(x, y))

    for x in range(PATH_COLUMN_STRIDE, GRID_WIDTH - 1, PATH_COLUMN_STRIDE):
        for y in range(1, GRID_HEIGHT - 1):
            _set_non_gameplay_cell(path_layer, source_id, Vector2i(x, y))

    var center_y := int(GRID_HEIGHT / 2.0)
    var center_x := int(GRID_WIDTH / 2.0)

    for x in range(1, GRID_WIDTH - 1):
        if x % 5 == 0:
            continue
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(x, center_y))

    for y in range(1, GRID_HEIGHT - 1):
        if y % 4 == 1:
            continue
        _set_non_gameplay_cell(path_layer, source_id, Vector2i(center_x, y))

func _stamp_field_borders(structure_layer: TileMap, source_id: int) -> void:
    var field_rects: Array[Rect2i] = [
        Rect2i(Vector2i(6, 5), Vector2i(14, 9)),
        Rect2i(Vector2i(24, 5), Vector2i(14, 9)),
        Rect2i(Vector2i(42, 5), Vector2i(14, 9)),
        Rect2i(Vector2i(15, 19), Vector2i(18, 10)),
        Rect2i(Vector2i(37, 19), Vector2i(18, 10))
    ]

    for rect in field_rects:
        _stamp_rect_outline(structure_layer, source_id, rect)

func _stamp_rect_outline(tilemap: TileMap, source_id: int, rect: Rect2i) -> void:
    var left := rect.position.x
    var top := rect.position.y
    var right := rect.position.x + rect.size.x - 1
    var bottom := rect.position.y + rect.size.y - 1

    for x in range(left, right + 1):
        _set_non_gameplay_cell(tilemap, source_id, Vector2i(x, top))
        _set_non_gameplay_cell(tilemap, source_id, Vector2i(x, bottom))

    for y in range(top + 1, bottom):
        _set_non_gameplay_cell(tilemap, source_id, Vector2i(left, y))
        _set_non_gameplay_cell(tilemap, source_id, Vector2i(right, y))

func _stamp_tree_belts(decor_layer: TileMap, source_id: int) -> void:
    for y in range(2, GRID_HEIGHT - 2):
        if y % 2 != 0 and y % 3 != 0:
            continue
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(2, y))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(3, y))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(GRID_WIDTH - 4, y))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(GRID_WIDTH - 3, y))

    for x in range(4, GRID_WIDTH - 4):
        if x % 2 != 0:
            continue
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(x, 2))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(x, 3))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(x, GRID_HEIGHT - 4))
        _set_non_gameplay_cell(decor_layer, source_id, Vector2i(x, GRID_HEIGHT - 3))

    for y in range(8, GRID_HEIGHT - 8, 4):
        for x in range(8, GRID_WIDTH - 8, 6):
            if (x + y) % 3 == 1:
                continue
            _set_non_gameplay_cell(decor_layer, source_id, Vector2i(x, y))

func _stamp_prop_clusters(
    decor_layer: TileMap,
    structure_layer: TileMap,
    decor_source_id: int,
    structure_source_id: int
) -> void:
    var anchors: Array[Vector2i] = [
        Vector2i(10, 10),
        Vector2i(22, 11),
        Vector2i(34, 10),
        Vector2i(46, 12),
        Vector2i(14, 24),
        Vector2i(28, 23),
        Vector2i(42, 24),
        Vector2i(54, 22)
    ]

    var decor_offsets: Array[Vector2i] = [
        Vector2i(-2, 0),
        Vector2i(-1, 0),
        Vector2i(1, 0),
        Vector2i(2, 0),
        Vector2i(0, -2),
        Vector2i(0, -1),
        Vector2i(0, 1),
        Vector2i(0, 2),
        Vector2i(-1, -1),
        Vector2i(1, -1),
        Vector2i(-1, 1),
        Vector2i(1, 1)
    ]
    var structure_offsets: Array[Vector2i] = [
        Vector2i.ZERO,
        Vector2i(1, 0),
        Vector2i(0, 1)
    ]

    for anchor in anchors:
        for offset in decor_offsets:
            _set_non_gameplay_cell(decor_layer, decor_source_id, anchor + offset)
        for offset in structure_offsets:
            _set_non_gameplay_cell(structure_layer, structure_source_id, anchor + offset)

func _stamp_water_edge_accents(water_edge_layer: TileMap, source_id: int) -> void:
    var shore_y := GRID_HEIGHT - 2
    for x in range(GRID_WIDTH):
        _set_non_gameplay_cell(water_edge_layer, source_id, Vector2i(x, shore_y))

    var river_x := GRID_WIDTH - 2
    for y in range(GRID_HEIGHT):
        _set_non_gameplay_cell(water_edge_layer, source_id, Vector2i(river_x, y))

    var accent_rows := [GRID_HEIGHT - 5, GRID_HEIGHT - 7]
    for row in accent_rows:
        for x in range(1, GRID_WIDTH - 1):
            if x % 2 != 0 and x % 3 != 0:
                continue
            _set_non_gameplay_cell(water_edge_layer, source_id, Vector2i(x, row))

    for y in range(2, GRID_HEIGHT - 2):
        if y % 2 == 0:
            continue
        _set_non_gameplay_cell(water_edge_layer, source_id, Vector2i(1, y))

func _set_non_gameplay_cell(tilemap: TileMap, source_id: int, cell: Vector2i) -> void:
    if source_id < 0:
        return
    if not _is_inside_grid(cell):
        return
    tilemap.set_cell(0, cell, source_id, Vector2i.ZERO)

func _on_viewport_size_changed() -> void:
    if _camera_ref != null:
        _configure_camera_limits(_camera_ref)

func _configure_camera_limits(camera: Camera2D, override_viewport_size: Vector2 = Vector2.ZERO) -> void:
    var map_width := GRID_WIDTH * TILE_SIZE
    var map_height := GRID_HEIGHT * TILE_SIZE
    var viewport_size := override_viewport_size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        viewport_size = get_viewport_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return

    var base_zoom := _camera_base_zoom
    if base_zoom.x <= 0.0 or base_zoom.y <= 0.0:
        base_zoom = camera.zoom
    if base_zoom.x <= 0.0 or base_zoom.y <= 0.0:
        base_zoom = Vector2.ONE

    var base_zoom_value := minf(base_zoom.x, base_zoom.y)
    var max_zoom_x := float(map_width) / viewport_size.x
    var max_zoom_y := float(map_height) / viewport_size.y
    var max_zoom_for_fit := minf(max_zoom_x, max_zoom_y)
    var fit_zoom_value := maxf(base_zoom_value, 0.01)
    if max_zoom_for_fit < base_zoom_value:
        fit_zoom_value = maxf(max_zoom_for_fit - 0.0001, 0.01)
    camera.zoom = Vector2(fit_zoom_value, fit_zoom_value)

    var half_width := int(ceil((viewport_size.x * 0.5) * camera.zoom.x))
    var half_height := int(ceil((viewport_size.y * 0.5) * camera.zoom.y))

    if map_width <= half_width * 2:
        var center_x := int(map_width * 0.5)
        camera.limit_left = center_x
        camera.limit_right = center_x
    else:
        camera.limit_left = half_width
        camera.limit_right = map_width - half_width

    if map_height <= half_height * 2:
        var center_y := int(map_height * 0.5)
        camera.limit_top = center_y
        camera.limit_bottom = center_y
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
