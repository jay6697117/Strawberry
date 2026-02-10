extends RefCounted
class_name SaveMigrator

const CURRENT_SCHEMA := 1

static func migrate(data: Dictionary) -> Dictionary:
    var out := data.duplicate(true)
    var version := int(out.get("schema_version", 0))

    while version < CURRENT_SCHEMA:
        if version == 0:
            out["season"] = String(out.get("season", "spring"))
            out["day"] = int(out.get("day", 1))
            out["schema_version"] = 1

        version = int(out.get("schema_version", 0))

    return out
