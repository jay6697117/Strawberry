extends GutTest

const PATH_MIN_USED_CELLS := 420
const DECOR_MIN_USED_CELLS := 300
const WATER_EDGE_MIN_USED_CELLS := 120
const STRUCTURE_MIN_USED_CELLS := 120

func test_dense_composition_populates_non_gameplay_layers_above_thresholds() -> void:
    SessionState.farm_plots = []
    var farm_world := _spawn_farm_world()
    var layers := _fetch_layers(farm_world)

    assert_true(layers.has("path"))
    assert_true(layers.has("decor"))
    assert_true(layers.has("water"))
    assert_true(layers.has("structure"))
    if not layers.has("path") or not layers.has("decor") or not layers.has("water") or not layers.has("structure"):
        return

    var path_layer := layers["path"] as TileMap
    var decor_layer := layers["decor"] as TileMap
    var water_edge_layer := layers["water"] as TileMap
    var structure_layer := layers["structure"] as TileMap
    if path_layer == null or decor_layer == null or water_edge_layer == null or structure_layer == null:
        fail_test("Expected all non-gameplay TileMap layers to exist")
        return

    var path_used_cells := path_layer.get_used_cells(0).size()
    var decor_used_cells := decor_layer.get_used_cells(0).size()
    var water_edge_used_cells := water_edge_layer.get_used_cells(0).size()
    var structure_used_cells := structure_layer.get_used_cells(0).size()

    assert_true(
        path_used_cells >= PATH_MIN_USED_CELLS,
        "path_used_cells=%d should be >= %d" % [path_used_cells, PATH_MIN_USED_CELLS]
    )
    assert_true(
        decor_used_cells >= DECOR_MIN_USED_CELLS,
        "decor_used_cells=%d should be >= %d" % [decor_used_cells, DECOR_MIN_USED_CELLS]
    )
    assert_true(
        water_edge_used_cells >= WATER_EDGE_MIN_USED_CELLS,
        "water_edge_used_cells=%d should be >= %d" % [water_edge_used_cells, WATER_EDGE_MIN_USED_CELLS]
    )
    assert_true(
        structure_used_cells >= STRUCTURE_MIN_USED_CELLS,
        "structure_used_cells=%d should be >= %d" % [structure_used_cells, STRUCTURE_MIN_USED_CELLS]
    )

func test_dense_composition_is_deterministic_for_same_world_config() -> void:
    SessionState.farm_plots = []
    var world_a := _spawn_farm_world()
    var world_b := _spawn_farm_world()

    var layers_a := _fetch_layers(world_a)
    var layers_b := _fetch_layers(world_b)
    var layer_keys := ["path", "decor", "water", "structure"]

    for layer_key in layer_keys:
        assert_true(layers_a.has(layer_key), "world_a should include layer key %s" % layer_key)
        assert_true(layers_b.has(layer_key), "world_b should include layer key %s" % layer_key)
        if not layers_a.has(layer_key) or not layers_b.has(layer_key):
            continue

        var layer_a := layers_a[layer_key] as TileMap
        var layer_b := layers_b[layer_key] as TileMap
        assert_not_null(layer_a)
        assert_not_null(layer_b)
        if layer_a == null or layer_b == null:
            continue

        var signature_a := _layer_signature(layer_a)
        var signature_b := _layer_signature(layer_b)
        assert_eq(signature_a.size(), signature_b.size())
        assert_eq(signature_a, signature_b)

func _spawn_farm_world() -> Node2D:
    var packed := load("res://scenes/farm/farm_world.tscn") as PackedScene
    return add_child_autofree(packed.instantiate())

func _fetch_layers(farm_world: Node) -> Dictionary:
    if farm_world == null:
        return {}
    var farm_view := farm_world.get_node_or_null("FarmTilemapView")
    if farm_view == null:
        return {}

    return {
        "path": farm_view.get_node_or_null("PathLayer"),
        "decor": farm_view.get_node_or_null("DecorLayer"),
        "water": farm_view.get_node_or_null("WaterEdgeLayer"),
        "structure": farm_view.get_node_or_null("StructureLayer")
    }

func _layer_signature(layer: TileMap) -> PackedStringArray:
    var cells := layer.get_used_cells(0)
    var signature := PackedStringArray()
    signature.resize(cells.size())

    for idx in cells.size():
        var cell: Vector2i = cells[idx]
        signature[idx] = "%d:%d" % [cell.x, cell.y]

    signature.sort()
    return signature
