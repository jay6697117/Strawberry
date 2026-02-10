extends RefCounted
class_name CropCatalog

const CROP_DATA_PATH := "res://data/crops.json"

func load_all() -> Dictionary:
    if not FileAccess.file_exists(CROP_DATA_PATH):
        return {}

    var file := FileAccess.open(CROP_DATA_PATH, FileAccess.READ)
    if file == null:
        return {}

    var parsed := JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return {}
    return parsed
