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

func set_plot(cell: Vector2i, plot: Dictionary) -> void:
    _plots[cell] = plot

func clear_plot(cell: Vector2i) -> void:
    _plots.erase(cell)

func has_plot(cell: Vector2i) -> bool:
    return _plots.has(cell)

func get_plot(cell: Vector2i) -> Dictionary:
    return _plots.get(cell, {})

func get_all_plots() -> Dictionary:
    return _plots
