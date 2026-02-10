extends GutTest

func test_clock_advances_in_10_minute_ticks() -> void:
    if not FileAccess.file_exists("res://scripts/core/game_clock.gd"):
        fail_test("res://scripts/core/game_clock.gd should exist")
        return
    var game_clock_script := load("res://scripts/core/game_clock.gd")
    assert_not_null(game_clock_script)
    if game_clock_script == null:
        return
    var clock = game_clock_script.new()
    clock.hour = 6
    clock.minute = 50
    clock.advance_tick()
    assert_eq(clock.hour, 7)
    assert_eq(clock.minute, 0)
