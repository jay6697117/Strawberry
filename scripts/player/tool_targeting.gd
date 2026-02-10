extends RefCounted
class_name ToolTargeting

static func compute_front_cell(global_pos: Vector2, facing: Vector2i, tile_size: int) -> Vector2i:
    var world_target := global_pos + Vector2(facing) * float(tile_size)
    return Vector2i(floor(world_target.x / tile_size), floor(world_target.y / tile_size))
