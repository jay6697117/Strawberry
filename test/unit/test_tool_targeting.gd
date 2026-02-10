extends GutTest

func test_front_cell_uses_facing_direction() -> void:
    if not FileAccess.file_exists("res://scripts/player/tool_targeting.gd"):
        fail_test("res://scripts/player/tool_targeting.gd should exist")
        return

    var targeting_script := load("res://scripts/player/tool_targeting.gd")
    assert_not_null(targeting_script)
    if targeting_script == null:
        return

    var target = targeting_script.compute_front_cell(Vector2(32, 32), Vector2i(1, 0), 16)
    assert_eq(target, Vector2i(3, 2))
