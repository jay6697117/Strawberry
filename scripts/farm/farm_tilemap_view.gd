extends Node2D

const TILE_THEME_PATH := "res://data/visual/tileset_theme.json"
const DEFAULT_TILE_SIZE := 32
const REQUIRED_STAGE_COUNT := 5

@onready var backdrop: Sprite2D = $Backdrop
@onready var ground_layer: TileMap = $GroundLayer
@onready var path_layer: TileMap = $PathLayer
@onready var soil_layer: TileMap = $SoilLayer
@onready var water_edge_layer: TileMap = $WaterEdgeLayer
@onready var structure_layer: TileMap = $StructureLayer
@onready var decor_layer: TileMap = $DecorLayer
@onready var crop_layer: TileMap = $CropLayer

var _tile_size: int = DEFAULT_TILE_SIZE
var _grid_width: int = 32
var _grid_height: int = 18
var _plots: Dictionary = {}
var _theme: Dictionary = {}

var _backdrop_texture: Texture2D
var _ground_texture: Texture2D
var _path_texture: Texture2D
var _dry_soil_texture: Texture2D
var _wet_soil_texture: Texture2D
var _water_edge_texture: Texture2D
var _structure_texture: Texture2D
var _decor_texture: Texture2D
var _crop_stage_textures: Array[Texture2D] = []

var _ground_source_id: int = -1
var _path_source_id: int = -1
var _soil_source_ids: Array[int] = []
var _water_edge_source_id: int = -1
var _structure_source_id: int = -1
var _decor_source_id: int = -1
var _crop_source_ids: Array[int] = []

func configure(tile_size: int, grid_width: int, grid_height: int) -> void:
    _load_theme()

    var configured_tile_size: int = int(_theme.get("tile_size", tile_size))
    _tile_size = maxi(configured_tile_size, 8)
    _grid_width = maxi(grid_width, 1)
    _grid_height = maxi(grid_height, 1)

    _load_external_textures()
    _setup_backdrop()
    _setup_tilemaps()
    _paint_ground_layer()
    _paint_static_visual_layers()
    _rebuild_dynamic_layers()

func apply_plot(cell: Vector2i, plot: Dictionary) -> void:
    if plot.is_empty():
        _plots.erase(cell)
    else:
        _plots[cell] = plot.duplicate(true)

    _refresh_cell(cell)

func apply_all_plots(plots: Dictionary) -> void:
    _plots.clear()
    for cell in plots.keys():
        _plots[cell] = Dictionary(plots[cell]).duplicate(true)

    _rebuild_dynamic_layers()

func _load_theme() -> void:
    _theme = {}
    if not FileAccess.file_exists(TILE_THEME_PATH):
        return

    var file := FileAccess.open(TILE_THEME_PATH, FileAccess.READ)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        _theme = Dictionary(parsed)

func _load_external_textures() -> void:
    var textures_variant: Variant = _theme.get("textures", {})
    var textures: Dictionary = {}
    if typeof(textures_variant) == TYPE_DICTIONARY:
        textures = Dictionary(textures_variant)

    _backdrop_texture = _load_png_texture(String(textures.get("backdrop", "")), Color(0.42, 0.69, 0.38))
    _ground_texture = _load_png_texture(String(textures.get("ground", "")), Color(0.45, 0.72, 0.37))
    _path_texture = _load_png_texture(String(textures.get("path", "")), Color(0.73, 0.66, 0.48))
    _dry_soil_texture = _load_png_texture(String(textures.get("soil_dry", "")), Color(0.62, 0.43, 0.28))
    _wet_soil_texture = _load_png_texture(String(textures.get("soil_wet", "")), Color(0.42, 0.31, 0.22))
    _water_edge_texture = _load_png_texture(String(textures.get("water_edge", "")), Color(0.27, 0.52, 0.71, 0.9))
    _structure_texture = _load_png_texture(String(textures.get("structure", "")), Color(0.62, 0.47, 0.36))
    _decor_texture = _load_png_texture(String(textures.get("decor", "")), Color(0.36, 0.67, 0.30, 0.95))

    _crop_stage_textures.clear()
    var stage_paths := _extract_string_array(textures.get("crop_parsnip_stages", []))
    for stage_path in stage_paths:
        _crop_stage_textures.append(_load_png_texture(stage_path, Color(0.40, 0.73, 0.34, 0.9)))

    while _crop_stage_textures.size() < REQUIRED_STAGE_COUNT:
        _crop_stage_textures.append(_build_fallback_texture(Color(0.40, 0.73, 0.34, 0.9)))

func _setup_backdrop() -> void:
    backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    backdrop.centered = false
    backdrop.position = Vector2.ZERO
    backdrop.texture = _backdrop_texture

func _setup_tilemaps() -> void:
    var ground_setup := _build_tileset([_ground_texture])
    ground_layer.tile_set = ground_setup["tileset"] as TileSet
    _ground_source_id = int((ground_setup["source_ids"] as Array)[0])

    var path_setup := _build_tileset([_path_texture])
    path_layer.tile_set = path_setup["tileset"] as TileSet
    _path_source_id = int((path_setup["source_ids"] as Array)[0])

    var soil_setup := _build_tileset([_dry_soil_texture, _wet_soil_texture])
    soil_layer.tile_set = soil_setup["tileset"] as TileSet
    _soil_source_ids = _to_int_array(soil_setup["source_ids"] as Array)

    var water_edge_setup := _build_tileset([_water_edge_texture])
    water_edge_layer.tile_set = water_edge_setup["tileset"] as TileSet
    _water_edge_source_id = int((water_edge_setup["source_ids"] as Array)[0])

    var structure_setup := _build_tileset([_structure_texture])
    structure_layer.tile_set = structure_setup["tileset"] as TileSet
    _structure_source_id = int((structure_setup["source_ids"] as Array)[0])

    var decor_setup := _build_tileset([_decor_texture])
    decor_layer.tile_set = decor_setup["tileset"] as TileSet
    _decor_source_id = int((decor_setup["source_ids"] as Array)[0])

    var crop_setup := _build_tileset(_crop_stage_textures)
    crop_layer.tile_set = crop_setup["tileset"] as TileSet
    _crop_source_ids = _to_int_array(crop_setup["source_ids"] as Array)

    _configure_tilemap(ground_layer, 0)
    _configure_tilemap(path_layer, 1)
    _configure_tilemap(soil_layer, 2)
    _configure_tilemap(water_edge_layer, 3)
    _configure_tilemap(structure_layer, 4)
    _configure_tilemap(decor_layer, 5)
    _configure_tilemap(crop_layer, 6)

func _build_tileset(textures: Array[Texture2D]) -> Dictionary:
    var tile_set := TileSet.new()
    tile_set.tile_size = Vector2i(_tile_size, _tile_size)
    var source_ids: Array[int] = []

    for texture in textures:
        var source := TileSetAtlasSource.new()
        source.texture = texture
        source.texture_region_size = Vector2i(_tile_size, _tile_size)
        source.create_tile(Vector2i.ZERO)

        var source_id := tile_set.get_next_source_id()
        tile_set.add_source(source, source_id)
        source_ids.append(source_id)

    return {
        "tileset": tile_set,
        "source_ids": source_ids
    }

func _configure_tilemap(tilemap: TileMap, z_index_value: int) -> void:
    tilemap.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tilemap.y_sort_enabled = false
    tilemap.z_index = z_index_value

func _paint_ground_layer() -> void:
    ground_layer.clear()
    for y in _grid_height:
        for x in _grid_width:
            ground_layer.set_cell(0, Vector2i(x, y), _ground_source_id, Vector2i.ZERO)

func _paint_static_visual_layers() -> void:
    path_layer.clear()
    water_edge_layer.clear()
    structure_layer.clear()
    decor_layer.clear()

    var center_y := int(_grid_height / 2.0)
    var path_stride := 3
    for y in _grid_height:
        for x in _grid_width:
            var cell := Vector2i(x, y)
            if x == 0 or y == 0 or x == _grid_width - 1 or y == _grid_height - 1:
                _set_visual_cell(path_layer, _path_source_id, cell)
                continue
            if y == center_y and x % path_stride != 1:
                _set_visual_cell(path_layer, _path_source_id, cell)

    if _grid_height > 2:
        var shore_y := _grid_height - 2
        for x in _grid_width:
            _set_visual_cell(water_edge_layer, _water_edge_source_id, Vector2i(x, shore_y))
    if _grid_width > 2:
        var edge_x := _grid_width - 2
        for y in _grid_height:
            _set_visual_cell(water_edge_layer, _water_edge_source_id, Vector2i(edge_x, y))

    var structure_cells: Array[Vector2i] = [
        Vector2i(2, 2),
        Vector2i(_grid_width - 3, 2),
        Vector2i(2, _grid_height - 3),
        Vector2i(_grid_width - 3, _grid_height - 3)
    ]
    for cell in structure_cells:
        _set_visual_cell(structure_layer, _structure_source_id, cell)

    for y in _grid_height:
        for x in _grid_width:
            if x < 2 or y < 2 or x > _grid_width - 3 or y > _grid_height - 3:
                continue
            if (x + (y * 2)) % 11 == 0:
                _set_visual_cell(decor_layer, _decor_source_id, Vector2i(x, y))

func _rebuild_dynamic_layers() -> void:
    soil_layer.clear()
    crop_layer.clear()

    for cell in _plots.keys():
        _refresh_cell(cell)

func _refresh_cell(cell: Vector2i) -> void:
    var plot := Dictionary(_plots.get(cell, {}))
    if plot.is_empty():
        _erase_tile(soil_layer, cell)
        _erase_tile(crop_layer, cell)
        return

    var soil_state := String(plot.get("soil_state", "dry"))
    var soil_source := _soil_source_ids[0]
    if soil_state == "wet" and _soil_source_ids.size() > 1:
        soil_source = _soil_source_ids[1]
    soil_layer.set_cell(0, cell, soil_source, Vector2i.ZERO)

    var crop_id := String(plot.get("crop_id", ""))
    if crop_id.is_empty():
        _erase_tile(crop_layer, cell)
        return

    var stage := clampi(int(plot.get("stage", 0)), 0, _crop_source_ids.size() - 1)
    crop_layer.set_cell(0, cell, _crop_source_ids[stage], Vector2i.ZERO)

func _erase_tile(tilemap: TileMap, cell: Vector2i) -> void:
    tilemap.set_cell(0, cell, -1)

func _set_visual_cell(tilemap: TileMap, source_id: int, cell: Vector2i) -> void:
    if source_id < 0:
        return
    if not _is_inside_view_bounds(cell):
        return
    tilemap.set_cell(0, cell, source_id, Vector2i.ZERO)

func _is_inside_view_bounds(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.y >= 0 and cell.x < _grid_width and cell.y < _grid_height

func _to_int_array(values: Array) -> Array[int]:
    var out: Array[int] = []
    for value in values:
        out.append(int(value))
    return out

func _extract_string_array(raw_value: Variant) -> Array[String]:
    var out: Array[String] = []
    if typeof(raw_value) != TYPE_ARRAY:
        return out

    var source: Array = raw_value
    for value in source:
        var path := String(value)
        if path.is_empty():
            continue
        out.append(path)
    return out

func _load_png_texture(resource_path: String, fallback_color: Color) -> Texture2D:
    if resource_path.is_empty() or not FileAccess.file_exists(resource_path):
        return _build_fallback_texture(fallback_color)

    var image := Image.new()
    var absolute_path := ProjectSettings.globalize_path(resource_path)
    var err := image.load(absolute_path)
    if err != OK:
        return _build_fallback_texture(fallback_color)
    return ImageTexture.create_from_image(image)

func _build_fallback_texture(color: Color) -> Texture2D:
    var image := Image.create(_tile_size, _tile_size, false, Image.FORMAT_RGBA8)
    image.fill(color)
    return ImageTexture.create_from_image(image)
