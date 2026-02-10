extends GutTest

func test_till_then_water_changes_state() -> void:
    if not FileAccess.file_exists("res://scripts/farm/farm_grid_state.gd"):
        fail_test("res://scripts/farm/farm_grid_state.gd should exist")
        return

    var grid_state_script := load("res://scripts/farm/farm_grid_state.gd")
    assert_not_null(grid_state_script)
    if grid_state_script == null:
        return

    var grid = grid_state_script.new()
    var cell := Vector2i(10, 4)

    grid.till(cell)
    assert_eq(grid.get_plot(cell).soil_state, "dry")

    grid.water(cell)
    assert_eq(grid.get_plot(cell).soil_state, "wet")
