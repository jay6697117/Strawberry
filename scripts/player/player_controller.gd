extends CharacterBody2D

@export var move_speed: float = 140.0

var _facing: Vector2i = Vector2i.DOWN

func _ready() -> void:
    set_physics_process(true)

func _physics_process(_delta: float) -> void:
    var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = move_input * move_speed

    if move_input.length_squared() > 0.0:
        _facing = _vector_to_facing(move_input)

    move_and_slide()
    queue_redraw()

func get_front_cell(tile_size: int) -> Vector2i:
    var targeting_script := preload("res://scripts/player/tool_targeting.gd")
    return targeting_script.compute_front_cell(global_position, _facing, tile_size)

func get_facing() -> Vector2i:
    return _facing

func _draw() -> void:
    draw_circle(Vector2.ZERO, 11.0, Color(0.91, 0.82, 0.66))
    draw_circle(Vector2.ZERO + Vector2(0.0, 2.0), 7.2, Color(0.14, 0.22, 0.41))
    var indicator := Vector2(_facing) * 12.0
    draw_line(Vector2.ZERO, indicator, Color(1.0, 0.93, 0.35), 2.0)

func _vector_to_facing(input_dir: Vector2) -> Vector2i:
    if absf(input_dir.x) >= absf(input_dir.y):
        if input_dir.x >= 0.0:
            return Vector2i.RIGHT
        return Vector2i.LEFT

    if input_dir.y >= 0.0:
        return Vector2i.DOWN
    return Vector2i.UP
