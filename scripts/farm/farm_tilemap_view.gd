extends Node2D

const TILE_THEME_PATH := "res://data/visual/tileset_theme.json"
const DEFAULT_TILE_SIZE := 32

@onready var ground_layer: Node2D = $GroundLayer
@onready var soil_layer: Node2D = $SoilLayer
@onready var crop_layer: Node2D = $CropLayer

var _tile_size: int = DEFAULT_TILE_SIZE
var _grid_width: int = 32
var _grid_height: int = 18
var _plots: Dictionary = {}
var _theme: Dictionary = {}
var _palette: Dictionary = {}

var _ground_texture: Texture2D
var _dry_soil_texture: Texture2D
var _wet_soil_texture: Texture2D
var _crop_stage_textures: Array[Texture2D] = []

var _soil_sprites: Dictionary = {}
var _crop_sprites: Dictionary = {}

func _ready() -> void:
    _load_theme()

func configure(tile_size: int, grid_width: int, grid_height: int) -> void:
    _load_theme()
    var configured_tile_size := int(_theme.get("tile_size", tile_size))
    _tile_size = maxi(configured_tile_size, 8)
    _grid_width = maxi(grid_width, 1)
    _grid_height = maxi(grid_height, 1)

    _build_textures()
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
    _palette = {}
    if FileAccess.file_exists(TILE_THEME_PATH):
        var file := FileAccess.open(TILE_THEME_PATH, FileAccess.READ)
        if file != null:
            var parsed: Variant = JSON.parse_string(file.get_as_text())
            if typeof(parsed) == TYPE_DICTIONARY:
                _theme = Dictionary(parsed)
                var palette_data: Variant = _theme.get("palette", {})
                if typeof(palette_data) == TYPE_DICTIONARY:
                    _palette = Dictionary(palette_data)

func _build_textures() -> void:
    var grass_base := _color("grass_base", Color(0.46, 0.72, 0.37))
    var grass_shadow := _color("grass_shadow", Color(0.35, 0.57, 0.28))
    var grass_light := _color("grass_light", Color(0.56, 0.81, 0.42))
    var soil_dry_base := _color("soil_dry_base", Color(0.62, 0.43, 0.28))
    var soil_dry_shadow := _color("soil_dry_shadow", Color(0.46, 0.31, 0.19))
    var soil_wet_base := _color("soil_wet_base", Color(0.41, 0.29, 0.20))
    var soil_wet_shadow := _color("soil_wet_shadow", Color(0.31, 0.22, 0.15))

    _ground_texture = _create_soil_tile(grass_base, grass_shadow, grass_light)
    _dry_soil_texture = _create_soil_tile(soil_dry_base, soil_dry_shadow, soil_dry_base.lightened(0.1))
    _wet_soil_texture = _create_soil_tile(soil_wet_base, soil_wet_shadow, soil_wet_base.lightened(0.08))

    _crop_stage_textures.clear()
    for stage in 5:
        _crop_stage_textures.append(_create_crop_texture(stage))

func _create_soil_tile(base: Color, shadow: Color, highlight: Color) -> Texture2D:
    var image := Image.create(_tile_size, _tile_size, false, Image.FORMAT_RGBA8)
    image.fill(base)

    for y in _tile_size:
        for x in _tile_size:
            if ((x * 5 + y * 3) % 17) == 0:
                image.set_pixel(x, y, highlight)
            elif ((x * 7 + y * 11) % 23) == 0:
                image.set_pixel(x, y, shadow)

    var outline := _color("outline", Color(0.16, 0.21, 0.15))
    for i in _tile_size:
        image.set_pixel(i, 0, outline)
        image.set_pixel(i, _tile_size - 1, outline)
        image.set_pixel(0, i, outline)
        image.set_pixel(_tile_size - 1, i, outline)

    return ImageTexture.create_from_image(image)

func _create_crop_texture(stage: int) -> Texture2D:
    var transparent := Color(0.0, 0.0, 0.0, 0.0)
    var image := Image.create(_tile_size, _tile_size, false, Image.FORMAT_RGBA8)
    image.fill(transparent)

    var stem := _color("crop_stem", Color(0.30, 0.55, 0.25))
    var leaf := _color("crop_leaf", Color(0.45, 0.78, 0.37))
    var ripe := _color("crop_ripe", Color(0.95, 0.84, 0.42))

    var center := int(_tile_size / 2.0)
    var base_y := _tile_size - 8
    var height := 4 + stage * 4
    for i in height:
        image.set_pixel(center, base_y - i, stem)

    for offset in 2 + stage:
        var y := base_y - (offset * 2)
        if y < 2:
            continue
        image.set_pixel(center - 1, y, leaf)
        image.set_pixel(center + 1, y, leaf)

    if stage >= 4:
        image.set_pixel(center - 2, base_y - height + 2, ripe)
        image.set_pixel(center, base_y - height, ripe)
        image.set_pixel(center + 2, base_y - height + 2, ripe)

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

func _color(key: String, fallback: Color) -> Color:
    var value: Variant = _palette.get(key, "")
    if typeof(value) != TYPE_STRING:
        return fallback
    return Color.from_string(String(value), fallback)
