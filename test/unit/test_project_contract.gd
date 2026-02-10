extends GutTest

func test_main_scene_and_autoload_contract() -> void:
    assert_eq(ProjectSettings.get_setting("application/run/main_scene", ""), "res://scenes/main/main.tscn")
    assert_not_null(get_tree().root.get_node_or_null("SessionState"))
    assert_not_null(get_tree().root.get_node_or_null("SaveSystem"))
