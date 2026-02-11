extends RefCounted
class_name SaveMigrator

const CURRENT_SCHEMA := 2

static func migrate(data: Dictionary) -> Dictionary:
    var out := data.duplicate(true)
    var version := int(out.get("schema_version", 0))

    while version < CURRENT_SCHEMA:
        if version == 0:
            out["season"] = String(out.get("season", "spring"))
            out["day"] = int(out.get("day", 1))
            out["schema_version"] = 1
        elif version == 1:
            out["inventory"] = _normalize_inventory(out.get("inventory", {}))
            out["farm_plots"] = _normalize_farm_plots(out.get("farm_plots", []))
            out["schema_version"] = 2
        else:
            out["schema_version"] = CURRENT_SCHEMA

        version = int(out.get("schema_version", 0))

    out["gold"] = int(out.get("gold", 500))
    out["day"] = maxi(int(out.get("day", 1)), 1)
    out["season"] = String(out.get("season", "spring"))
    out["inventory"] = _normalize_inventory(out.get("inventory", {}))
    out["farm_plots"] = _normalize_farm_plots(out.get("farm_plots", []))
    out["schema_version"] = CURRENT_SCHEMA

    return out

static func _normalize_inventory(raw: Variant) -> Dictionary:
    if typeof(raw) != TYPE_DICTIONARY:
        return {}

    var out: Dictionary = {}
    for key in raw.keys():
        var item_id := String(key)
        if item_id.is_empty():
            continue
        var amount := int(raw[key])
        if amount <= 0:
            continue
        out[item_id] = amount
    return out

static func _normalize_farm_plots(raw: Variant) -> Array:
    if typeof(raw) != TYPE_ARRAY:
        return []

    var out: Array = []
    for entry in raw:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var cell_x := 0
        var cell_y := 0
        if entry.has("x") and entry.has("y"):
            cell_x = int(entry.get("x", 0))
            cell_y = int(entry.get("y", 0))
        elif entry.has("cell") and typeof(entry.get("cell")) == TYPE_ARRAY:
            var cell: Array = entry.get("cell", [])
            if cell.size() >= 2:
                cell_x = int(cell[0])
                cell_y = int(cell[1])
            else:
                continue
        else:
            continue

        var plot_data: Variant = entry.get("plot", {})
        if typeof(plot_data) != TYPE_DICTIONARY:
            continue
        out.append({
            "x": cell_x,
            "y": cell_y,
            "plot": Dictionary(plot_data).duplicate(true)
        })
    return out
