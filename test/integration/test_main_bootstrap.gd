extends GutTest

func test_main_instantiates_world_and_ui() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    assert_not_null(main.get_node_or_null("WorldRoot"))
    assert_not_null(main.get_node_or_null("UIRoot"))

func test_world_contains_playable_farm_nodes() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    assert_not_null(main.get_node_or_null("WorldRoot/FarmWorld/FarmTilemapView"))
    assert_not_null(main.get_node_or_null("WorldRoot/FarmWorld/Player"))

func test_farm_world_emits_runtime_hud_signals() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var farm_world := main.get_node_or_null("WorldRoot/FarmWorld")
    assert_not_null(farm_world)
    if farm_world == null:
        return

    assert_true(farm_world.has_signal("status_changed"))
    assert_true(farm_world.has_signal("inventory_changed"))

func test_player_and_hud_runtime_nodes_are_wired() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var player := main.get_node_or_null("WorldRoot/FarmWorld/Player")
    var hud := main.get_node_or_null("UIRoot/HUD")
    assert_not_null(player)
    assert_not_null(hud)
    if player == null or hud == null:
        return

    assert_true(player.has_method("get_front_cell"))
    assert_not_null(hud.get_node_or_null("InventoryLabel"))
    assert_not_null(hud.get_node_or_null("StatusLabel"))

func test_farm_view_uses_layered_resource_nodes() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var farm_view := main.get_node_or_null("WorldRoot/FarmWorld/FarmTilemapView")
    assert_not_null(farm_view)
    if farm_view == null:
        return

    assert_not_null(farm_view.get_node_or_null("GroundLayer"))
    assert_not_null(farm_view.get_node_or_null("SoilLayer"))
    assert_not_null(farm_view.get_node_or_null("CropLayer"))

func test_farm_view_layers_are_tilemaps() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var farm_view := main.get_node_or_null("WorldRoot/FarmWorld/FarmTilemapView")
    assert_not_null(farm_view)
    if farm_view == null:
        return

    var ground := farm_view.get_node_or_null("GroundLayer")
    var soil := farm_view.get_node_or_null("SoilLayer")
    var crop := farm_view.get_node_or_null("CropLayer")
    assert_true(ground is TileMap)
    assert_true(soil is TileMap)
    assert_true(crop is TileMap)

func test_player_uses_visual_sprite_node() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var player := main.get_node_or_null("WorldRoot/FarmWorld/Player")
    assert_not_null(player)
    if player == null:
        return

    var player_visual := player.get_node_or_null("PlayerVisual")
    assert_not_null(player_visual)
