extends RefCounted
class_name DialogueService

func pick_dialogue(dialogues: Dictionary, friendship: int, season: String, key_prefix: String = "") -> Dictionary:
    for key in dialogues.keys():
        var key_str := String(key)
        if not key_prefix.is_empty() and not key_str.begins_with(key_prefix):
            continue

        var entry = dialogues[key]
        if typeof(entry) != TYPE_DICTIONARY:
            continue

        var conditions = entry.get("conditions", {})
        if typeof(conditions) != TYPE_DICTIONARY:
            return entry

        var min_friend := int(conditions.get("friendship_min", 0))
        var max_friend := int(conditions.get("friendship_max", 1000))
        var season_cond := String(conditions.get("season", season))

        if friendship >= min_friend and friendship <= max_friend and season == season_cond:
            return entry

    return {}
