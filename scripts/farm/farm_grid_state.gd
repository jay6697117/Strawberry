extends RefCounted
class_name FarmGridState

var _plots: Dictionary = {}

func till(cell: Vector2i) -> void:
    _plots[cell] = {
        "soil_state": "dry",
        "crop_id": "",
        "stage": 0,
        "watered": false
    }

func water(cell: Vector2i) -> void:
    if not _plots.has(cell):
        return
    _plots[cell]["soil_state"] = "wet"
    _plots[cell]["watered"] = true

func get_plot(cell: Vector2i) -> Dictionary:
    return _plots.get(cell, {})
