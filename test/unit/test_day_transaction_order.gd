extends GutTest

func test_day_transaction_emits_ordered_steps() -> void:
    if not FileAccess.file_exists("res://scripts/core/day_transaction_service.gd"):
        fail_test("res://scripts/core/day_transaction_service.gd should exist")
        return
    var day_tx_script := load("res://scripts/core/day_transaction_service.gd")
    assert_not_null(day_tx_script)
    if day_tx_script == null:
        return
    var service = day_tx_script.new()
    var steps: Array[String] = []

    service.step_executed.connect(func(step: String) -> void:
        steps.append(step)
    )

    service.end_day()

    assert_eq(steps, [
        "advance_date",
        "grow_crops",
        "reset_watering",
        "autosave"
    ])
