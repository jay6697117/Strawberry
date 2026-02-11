extends Sprite2D

const STYLE_PATH := "res://data/visual/player_style.json"
const DIRECTIONS: Array[String] = ["up", "down", "left", "right"]

var _style: Dictionary = {}
var _frames_config: Dictionary = {}
var _resolved_frames: Dictionary = {}
var _anim_clock: float = 0.0
var _frame_rate: float = 8.0

func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = true
    _load_style()
    _load_frame_textures()
    texture = _pick_texture("down", false, 0)

func update_from_motion(velocity: Vector2, facing: Vector2i, delta: float) -> void:
    _anim_clock += delta
    var moving := velocity.length_squared() > 1.0
    var direction := _facing_to_name(facing)
    var phase := int(floor(_anim_clock * _frame_rate))
    texture = _pick_texture(direction, moving, phase)

func _load_style() -> void:
    _style = {}
    _frames_config = {}
    _frame_rate = 8.0

    if not FileAccess.file_exists(STYLE_PATH):
        return

    var file := FileAccess.open(STYLE_PATH, FileAccess.READ)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    _style = parsed as Dictionary
    _frame_rate = maxf(2.0, float(_style.get("frame_rate", 8.0)))

    var frames_variant: Variant = _style.get("frames", {})
    if typeof(frames_variant) == TYPE_DICTIONARY:
        _frames_config = frames_variant as Dictionary

func _load_frame_textures() -> void:
    _resolved_frames.clear()

    for direction in DIRECTIONS:
        var direction_data: Dictionary = {}
        var raw_direction: Variant = _frames_config.get(direction, {})
        if typeof(raw_direction) == TYPE_DICTIONARY:
            direction_data = raw_direction as Dictionary

        var idle_path := String(direction_data.get("idle", ""))
        var walk_paths := _extract_string_array(direction_data.get("walk", []))

        var idle_texture := _load_sprite_texture(idle_path)
        var walk_textures: Array[Texture2D] = []
        for walk_path in walk_paths:
            walk_textures.append(_load_sprite_texture(walk_path))

        if walk_textures.is_empty():
            walk_textures.append(idle_texture)

        _resolved_frames[direction] = {
            "idle": idle_texture,
            "walk": walk_textures
        }

func _pick_texture(direction: String, moving: bool, phase: int) -> Texture2D:
    var frame_data: Variant = _resolved_frames.get(direction, {})
    if typeof(frame_data) != TYPE_DICTIONARY:
        return _build_fallback_texture(Color(0.9, 0.4, 0.7, 1.0))

    var frame_dict := frame_data as Dictionary
    var idle_variant: Variant = frame_dict.get("idle", null)
    var walk_variant: Variant = frame_dict.get("walk", [])

    if moving and typeof(walk_variant) == TYPE_ARRAY:
        var walk_array := walk_variant as Array
        if not walk_array.is_empty():
            var index := posmod(phase, walk_array.size())
            var picked: Variant = walk_array[index]
            if picked is Texture2D:
                return picked as Texture2D

    if idle_variant is Texture2D:
        return idle_variant as Texture2D

    return _build_fallback_texture(Color(0.9, 0.4, 0.7, 1.0))

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

func _load_sprite_texture(resource_path: String) -> Texture2D:
    if resource_path.is_empty() or not FileAccess.file_exists(resource_path):
        return _build_fallback_texture(Color(0.85, 0.7, 0.45, 1.0))

    var image := Image.new()
    var absolute_path := ProjectSettings.globalize_path(resource_path)
    var err := image.load(absolute_path)
    if err != OK:
        return _build_fallback_texture(Color(0.85, 0.7, 0.45, 1.0))
    return ImageTexture.create_from_image(image)

func _build_fallback_texture(color: Color) -> Texture2D:
    var image := Image.create(16, 24, false, Image.FORMAT_RGBA8)
    image.fill(Color(0.0, 0.0, 0.0, 0.0))
    for y in 20:
        for x in 10:
            image.set_pixel(x + 3, y + 2, color)
    return ImageTexture.create_from_image(image)

func _facing_to_name(facing: Vector2i) -> String:
    if facing == Vector2i.LEFT:
        return "left"
    if facing == Vector2i.RIGHT:
        return "right"
    if facing == Vector2i.UP:
        return "up"
    return "down"
