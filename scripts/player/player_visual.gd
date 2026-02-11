extends Sprite2D

const STYLE_PATH := "res://data/visual/player_style.json"

var _style: Dictionary = {}
var _palette: Dictionary = {}
var _frames: Dictionary = {}
var _anim_clock: float = 0.0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = true
    _load_style()
    _build_frames()
    texture = _frame_for("down", false, 0)

func update_from_motion(velocity: Vector2, facing: Vector2i, delta: float) -> void:
    _anim_clock += delta
    var moving := velocity.length_squared() > 1.0
    var facing_name := _facing_to_name(facing)
    var phase := int(floor(_anim_clock * 8.0)) % 2
    texture = _frame_for(facing_name, moving, phase)

func _load_style() -> void:
    _style = {}
    _palette = {}
    if FileAccess.file_exists(STYLE_PATH):
        var file := FileAccess.open(STYLE_PATH, FileAccess.READ)
        if file != null:
            var parsed: Variant = JSON.parse_string(file.get_as_text())
            if typeof(parsed) == TYPE_DICTIONARY:
                _style = Dictionary(parsed)
                var palette_data: Variant = _style.get("palette", {})
                if typeof(palette_data) == TYPE_DICTIONARY:
                    _palette = Dictionary(palette_data)

func _build_frames() -> void:
    _frames.clear()
    var directions: Array[String] = ["down", "up", "left", "right"]
    var movement_states: Array[bool] = [false, true]
    for direction in directions:
        for moving in movement_states:
            for phase in 2:
                var key := _frame_key(direction, moving, phase)
                _frames[key] = _create_player_texture(direction, moving, phase)

func _frame_for(direction: String, moving: bool, phase: int) -> Texture2D:
    var key := _frame_key(direction, moving, phase)
    if _frames.has(key):
        return _frames[key] as Texture2D
    return _create_player_texture("down", false, 0)

func _frame_key(direction: String, moving: bool, phase: int) -> String:
    var movement := "idle"
    if moving:
        movement = "walk"
    return "%s_%s_%d" % [direction, movement, phase]

func _create_player_texture(direction: String, moving: bool, phase: int) -> Texture2D:
    var width := int(_style.get("width", 16))
    var height := int(_style.get("height", 24))
    var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.0, 0.0, 0.0, 0.0))

    var outline := _color("outline", Color(0.12, 0.16, 0.18))
    var skin := _color("skin", Color(0.94, 0.79, 0.64))
    var hair := _color("hair", Color(0.38, 0.27, 0.20))
    var shirt := _color("shirt", Color(0.31, 0.47, 0.73))
    var shirt_shadow := _color("shirt_shadow", Color(0.21, 0.35, 0.58))
    var pants := _color("pants", Color(0.25, 0.33, 0.50))
    var boots := _color("boots", Color(0.30, 0.23, 0.19))
    var accent := _color("accent", Color(0.95, 0.89, 0.54))

    var cx := int(width / 2.0)
    var leg_shift := 0
    if moving:
        leg_shift = -1 if phase == 0 else 1
    var arm_shift := -leg_shift

    _paint_rect(image, cx - 3, 4, 6, 2, hair)
    _paint_rect(image, cx - 3, 6, 6, 5, skin)

    if direction == "up":
        _paint_rect(image, cx - 3, 6, 6, 4, hair)
        _paint_rect(image, cx - 2, 11, 4, 1, accent)
    elif direction == "down":
        _paint_rect(image, cx - 2, 8, 4, 1, accent)
    elif direction == "left":
        _paint_rect(image, cx - 3, 8, 2, 1, accent)
    else:
        _paint_rect(image, cx + 1, 8, 2, 1, accent)

    _paint_rect(image, cx - 4, 12, 8, 5, shirt)
    _paint_rect(image, cx - 4, 16, 8, 1, shirt_shadow)
    _paint_rect(image, cx - 5 + arm_shift, 13, 1, 4, skin)
    _paint_rect(image, cx + 4 + arm_shift, 13, 1, 4, skin)

    _paint_rect(image, cx - 3, 17, 6, 4, pants)
    _paint_rect(image, cx - 3 + leg_shift, 21, 2, 2, boots)
    _paint_rect(image, cx + 1 - leg_shift, 21, 2, 2, boots)

    _paint_outline(image, outline)
    return ImageTexture.create_from_image(image)

func _paint_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
    for yy in h:
        var py := y + yy
        if py < 0 or py >= image.get_height():
            continue
        for xx in w:
            var px := x + xx
            if px < 0 or px >= image.get_width():
                continue
            image.set_pixel(px, py, color)

func _paint_outline(image: Image, color: Color) -> void:
    var width := image.get_width()
    var height := image.get_height()
    var transparent := Color(0.0, 0.0, 0.0, 0.0)
    var offsets: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]

    for y in height:
        for x in width:
            var pixel := image.get_pixel(x, y)
            if pixel.a <= 0.0:
                continue
            for neighbor_offset in offsets:
                var nx: int = x + neighbor_offset.x
                var ny: int = y + neighbor_offset.y
                if nx < 0 or ny < 0 or nx >= width or ny >= height:
                    continue
                if image.get_pixel(nx, ny) == transparent:
                    image.set_pixel(nx, ny, color)

func _facing_to_name(facing: Vector2i) -> String:
    if facing == Vector2i.LEFT:
        return "left"
    if facing == Vector2i.RIGHT:
        return "right"
    if facing == Vector2i.UP:
        return "up"
    return "down"

func _color(key: String, fallback: Color) -> Color:
    var value: Variant = _palette.get(key, "")
    if typeof(value) != TYPE_STRING:
        return fallback
    return Color.from_string(String(value), fallback)
