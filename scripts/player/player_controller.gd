extends CharacterBody2D

@export var move_speed: float = 140.0

var _facing: Vector2i = Vector2i.DOWN

@onready var player_visual: Node = $PlayerVisual

func _ready() -> void:
    set_physics_process(true)
    _sync_visual(Vector2.ZERO, 0.0)

func _physics_process(delta: float) -> void:
    var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = move_input * move_speed

    if move_input.length_squared() > 0.0:
        _facing = _vector_to_facing(move_input)

    move_and_slide()
    _sync_visual(velocity, delta)

func get_front_cell(tile_size: int) -> Vector2i:
    var targeting_script := preload("res://scripts/player/tool_targeting.gd")
    return targeting_script.compute_front_cell(global_position, _facing, tile_size)

func get_facing() -> Vector2i:
    return _facing

func _sync_visual(current_velocity: Vector2, delta: float) -> void:
    if player_visual != null and player_visual.has_method("update_from_motion"):
        player_visual.update_from_motion(current_velocity, _facing, delta)

func _vector_to_facing(input_dir: Vector2) -> Vector2i:
    if absf(input_dir.x) >= absf(input_dir.y):
        if input_dir.x >= 0.0:
            return Vector2i.RIGHT
        return Vector2i.LEFT

    if input_dir.y >= 0.0:
        return Vector2i.DOWN
    return Vector2i.UP
