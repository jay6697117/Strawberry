extends RefCounted
class_name DayTransactionService

signal step_executed(step: String)

func end_day() -> void:
    step_executed.emit("advance_date")
    step_executed.emit("grow_crops")
    step_executed.emit("reset_watering")
    step_executed.emit("autosave")

func apply_growth_on_plot(plot: Dictionary, season: String) -> void:
    var growth_service = preload("res://scripts/farm/crop_growth_service.gd").new()
    growth_service.advance_plot_one_day(plot, season)
