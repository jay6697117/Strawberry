extends RefCounted
class_name GameClock

signal time_tick(hour: int, minute: int)

const MINUTES_PER_TICK := 10

var day: int = 1
var hour: int = 6
var minute: int = 0

func advance_tick() -> void:
    minute += MINUTES_PER_TICK
    while minute >= 60:
        minute -= 60
        hour += 1
    time_tick.emit(hour, minute)
