extends Node2D

const TILE_THEME_PATH := "res://data/visual/tileset_theme.json"
const DEFAULT_TILE_SIZE := 32
const REQUIRED_STAGE_COUNT := 5

@onready var ground_layer: Node2D = $GroundLayer
@onready var soil_layer: Node2D = $SoilLayer
@onready var crop_layer: Node2D = $CropLayer

var _tile_size: int = DEFAULT_TILE_SIZE
var _grid_width: int = 32
var _grid_height: int = 18
var _plots: Dictionary = {}
var _theme: Dictionary = {}

var _ground_texture: Texture2D
var _dry_soil_texture: Texture2D
var _wet_soil_texture: Texture2D
var _crop_stage_textures: Array[Texture2D] = []

var _soil_sprites: Dictionary = {}
var _crop_sprites: Dictionary = {}

func configure(tile_size: int, grid_width: int, grid_height: int) -> void:
    _load_theme()

    var configured_tile_size: int = int(_theme.get("tile_size", tile_size))
    _tile_size = maxi(configured_tile_size, 8)
    _grid_width = maxi(grid_width, 1)
    _grid_height = maxi(grid_height, 1)

    _load_external_textures()
    _rebuild_ground_layer()
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

    _ground_texture = _load_png_texture(String(textures.get("ground", "")), Color(0.45, 0.72, 0.37))
    _dry_soil_texture = _load_png_texture(String(textures.get("soil_dry", "")), Color(0.62, 0.43, 0.28))
    _wet_soil_texture = _load_png_texture(String(textures.get("soil_wet", "")), Color(0.42, 0.31, 0.22))

    _crop_stage_textures.clear()
    var stage_paths := _extract_string_array(textures.get("crop_parsnip_stages", []))
    for stage_path in stage_paths:
        _crop_stage_textures.append(_load_png_texture(stage_path, Color(0.40, 0.73, 0.34, 0.9)))

    while _crop_stage_textures.size() < REQUIRED_STAGE_COUNT:
        var fallback_color := Color(0.40, 0.73, 0.34, 0.9)
        _crop_stage_textures.append(_build_fallback_texture(fallback_color))

func _extract_string_array(raw_value: Variant) -> Array[String]:
    var out: Array[String] = []
    if typeof(raw_value) != TYPE_ARRAY:
        return out

    var as_array: Array = raw_value
    for value in as_array:
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

func _rebuild_ground_layer() -> void:
    _clear_layer_children(ground_layer)
    for y in _grid_height:
        for x in _grid_width:
            var sprite := Sprite2D.new()
            sprite.texture = _ground_texture
            sprite.position = _cell_center(Vector2i(x, y))
            sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            ground_layer.add_child(sprite)

func _rebuild_dynamic_layers() -> void:
    _clear_sprite_map(_soil_sprites)
    _clear_sprite_map(_crop_sprites)

    for cell in _plots.keys():
        _refresh_cell(cell)

func _refresh_cell(cell: Vector2i) -> void:
    var plot := Dictionary(_plots.get(cell, {}))
    if plot.is_empty():
        _erase_sprite(_soil_sprites, cell)
        _erase_sprite(_crop_sprites, cell)
        return

    var soil_state := String(plot.get("soil_state", "dry"))
    var soil_texture: Texture2D = _dry_soil_texture
    if soil_state == "wet":
        soil_texture = _wet_soil_texture
    _set_sprite(_soil_sprites, soil_layer, cell, soil_texture)

    var crop_id := String(plot.get("crop_id", ""))
    if crop_id.is_empty():
        _erase_sprite(_crop_sprites, cell)
        return

    var stage := clampi(int(plot.get("stage", 0)), 0, _crop_stage_textures.size() - 1)
    _set_sprite(_crop_sprites, crop_layer, cell, _crop_stage_textures[stage])

func _set_sprite(sprite_map: Dictionary, layer: Node2D, cell: Vector2i, texture: Texture2D) -> void:
    var sprite: Sprite2D
    if sprite_map.has(cell):
        sprite = sprite_map[cell] as Sprite2D
    else:
        sprite = Sprite2D.new()
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        layer.add_child(sprite)
        sprite_map[cell] = sprite

    sprite.position = _cell_center(cell)
    sprite.texture = texture

func _erase_sprite(sprite_map: Dictionary, cell: Vector2i) -> void:
    if not sprite_map.has(cell):
        return
    var sprite := sprite_map[cell] as Sprite2D
    if sprite != null:
        sprite.queue_free()
    sprite_map.erase(cell)

func _clear_sprite_map(sprite_map: Dictionary) -> void:
    for key in sprite_map.keys():
        var sprite := sprite_map[key] as Sprite2D
        if sprite != null:
            sprite.queue_free()
    sprite_map.clear()

func _clear_layer_children(layer: Node2D) -> void:
    for child in layer.get_children():
        child.queue_free()

func _cell_center(cell: Vector2i) -> Vector2:
    return Vector2((float(cell.x) + 0.5) * _tile_size, (float(cell.y) + 0.5) * _tile_size)
