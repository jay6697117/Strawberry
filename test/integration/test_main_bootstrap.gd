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
    assert_not_null(farm_view.get_node_or_null("PathLayer"))
    assert_not_null(farm_view.get_node_or_null("DecorLayer"))
    assert_not_null(farm_view.get_node_or_null("WaterEdgeLayer"))
    assert_not_null(farm_view.get_node_or_null("StructureLayer"))

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
    var path_layer := farm_view.get_node_or_null("PathLayer")
    var decor_layer := farm_view.get_node_or_null("DecorLayer")
    var water_edge_layer := farm_view.get_node_or_null("WaterEdgeLayer")
    var structure_layer := farm_view.get_node_or_null("StructureLayer")
    assert_true(ground is TileMap)
    assert_true(soil is TileMap)
    assert_true(crop is TileMap)
    assert_true(path_layer is TileMap)
    assert_true(decor_layer is TileMap)
    assert_true(water_edge_layer is TileMap)
    assert_true(structure_layer is TileMap)

func test_farm_view_api_remains_backward_compatible() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var farm_view := main.get_node_or_null("WorldRoot/FarmWorld/FarmTilemapView")
    assert_not_null(farm_view)
    if farm_view == null:
        return

    assert_true(farm_view.has_method("configure"))
    assert_true(farm_view.has_method("apply_plot"))
    assert_true(farm_view.has_method("apply_all_plots"))

    farm_view.call("configure", 32, 8, 6)
    farm_view.call("apply_plot", Vector2i(1, 1), {
        "soil_state": "wet",
        "crop_id": "",
        "stage": 0
    })
    farm_view.call("apply_all_plots", {
        Vector2i(2, 2): {
            "soil_state": "dry",
            "crop_id": "parsnip",
            "stage": 2
        }
    })

    var soil := farm_view.get_node_or_null("SoilLayer") as TileMap
    var crop := farm_view.get_node_or_null("CropLayer") as TileMap
    assert_not_null(soil)
    assert_not_null(crop)
    if soil == null or crop == null:
        return

    assert_ne(soil.get_cell_source_id(0, Vector2i(2, 2)), -1)
    assert_ne(crop.get_cell_source_id(0, Vector2i(2, 2)), -1)

func test_farm_view_decorative_layers_are_writable() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var farm_view := main.get_node_or_null("WorldRoot/FarmWorld/FarmTilemapView")
    assert_not_null(farm_view)
    if farm_view == null:
        return

    farm_view.call("configure", 32, 12, 8)

    var path_layer := farm_view.get_node_or_null("PathLayer") as TileMap
    var decor_layer := farm_view.get_node_or_null("DecorLayer") as TileMap
    var water_edge_layer := farm_view.get_node_or_null("WaterEdgeLayer") as TileMap
    var structure_layer := farm_view.get_node_or_null("StructureLayer") as TileMap
    assert_not_null(path_layer)
    assert_not_null(decor_layer)
    assert_not_null(water_edge_layer)
    assert_not_null(structure_layer)
    if path_layer == null or decor_layer == null or water_edge_layer == null or structure_layer == null:
        return

    assert_true(path_layer.get_used_cells(0).size() > 0)
    assert_true(decor_layer.get_used_cells(0).size() > 0)
    assert_true(water_edge_layer.get_used_cells(0).size() > 0)
    assert_true(structure_layer.get_used_cells(0).size() > 0)

func test_player_uses_visual_sprite_node() -> void:
    var packed := load("res://scenes/main/main.tscn") as PackedScene
    var main: Node = add_child_autofree(packed.instantiate())
    var player := main.get_node_or_null("WorldRoot/FarmWorld/Player")
    assert_not_null(player)
    if player == null:
        return

    var player_visual := player.get_node_or_null("PlayerVisual")
    assert_not_null(player_visual)
