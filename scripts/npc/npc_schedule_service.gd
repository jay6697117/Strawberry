extends RefCounted
class_name NpcScheduleService

func resolve_slot(hour: int, schedule: Array) -> Dictionary:
    var chosen := {}
    for slot in schedule:
        if int(slot.get("time", 0)) <= hour:
            chosen = slot
    return chosen
