extends RefCounted
class_name CropGrowthService

func advance_plot_one_day(plot: Dictionary, _season: String) -> void:
    if not String(plot.get("crop_id", "")).is_empty() and bool(plot.get("watered", false)):
        plot["stage"] = int(plot.get("stage", 0)) + 1

    plot["watered"] = false
    plot["soil_state"] = "dry"
