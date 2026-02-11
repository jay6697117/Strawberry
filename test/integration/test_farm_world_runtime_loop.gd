extends GutTest

func test_shipping_settles_on_end_day_instead_of_immediately() -> void:
    SessionState.gold = 500
    SessionState.farm_plots = []
    if SessionState.inventory.has_method("replace_with_item_totals"):
        SessionState.inventory.replace_with_item_totals({})

    var farm_world := _spawn_farm_world()
    SessionState.inventory.add_item("parsnip", 2)

    var before := SessionState.gold
    farm_world.call("_on_ship_request")
    assert_eq(SessionState.gold, before)

    farm_world.call("_on_end_day_request")
    assert_eq(SessionState.gold, before + 70)

func test_resetting_soil_clears_watered_flag() -> void:
    SessionState.farm_plots = []
    if SessionState.inventory.has_method("replace_with_item_totals"):
        SessionState.inventory.replace_with_item_totals({})

    var farm_world := _spawn_farm_world()
    farm_world.call("_on_till_request")
    farm_world.call("_on_water_request")
    farm_world.call("_on_till_request")

    var plot := _find_plot(SessionState.farm_plots, 6, 7)
    assert_false(bool(plot.get("watered", true)))
    assert_eq(String(plot.get("soil_state", "")), "dry")

func _spawn_farm_world() -> Node:
    var packed := load("res://scenes/farm/farm_world.tscn") as PackedScene
    return add_child_autofree(packed.instantiate())

func _find_plot(entries: Array, x: int, y: int) -> Dictionary:
    for entry in entries:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        if int(entry.get("x", -1)) == x and int(entry.get("y", -1)) == y:
            return Dictionary(entry.get("plot", {}))
    return {}
