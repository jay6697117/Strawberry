extends GutTest

func test_main_instantiates_world_and_ui() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    assert_not_null(main.get_node_or_null("WorldRoot"))
    assert_not_null(main.get_node_or_null("UIRoot"))
