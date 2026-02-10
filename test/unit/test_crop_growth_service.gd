extends GutTest

func test_watered_crop_advances_one_stage_per_day() -> void:
    if not FileAccess.file_exists("res://scripts/farm/crop_growth_service.gd"):
        fail_test("res://scripts/farm/crop_growth_service.gd should exist")
        return

    var growth_service_script := load("res://scripts/farm/crop_growth_service.gd")
    assert_not_null(growth_service_script)
    if growth_service_script == null:
        return

    var service = growth_service_script.new()
    var plot := {
        "crop_id": "parsnip",
        "stage": 1,
        "watered": true,
        "soil_state": "wet"
    }

    service.advance_plot_one_day(plot, "spring")

    assert_eq(plot["stage"], 2)
    assert_eq(plot["watered"], false)
    assert_eq(plot["soil_state"], "dry")
