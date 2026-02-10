extends GutTest

func test_schedule_returns_expected_slot() -> void:
    if not FileAccess.file_exists("res://scripts/npc/npc_schedule_service.gd"):
        fail_test("res://scripts/npc/npc_schedule_service.gd should exist")
        return

    var schedule_script := load("res://scripts/npc/npc_schedule_service.gd")
    assert_not_null(schedule_script)
    if schedule_script == null:
        return

    var service = schedule_script.new()
    var slot = service.resolve_slot(12, [
        {"time": 8, "location": "shop"},
        {"time": 12, "location": "square"}
    ])
    assert_eq(slot["location"], "square")
