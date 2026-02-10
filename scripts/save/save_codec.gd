extends RefCounted
class_name SaveCodec

static func encode(data: Dictionary) -> String:
    return JSON.stringify(data)

static func decode(raw: String) -> Dictionary:
    var parsed = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed
