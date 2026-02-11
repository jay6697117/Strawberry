extends Node

signal gold_changed(new_gold: int)
signal day_changed(new_day: int)
signal season_changed(new_season: StringName)

var day: int = 1:
    set(value):
        day = maxi(value, 1)
        day_changed.emit(day)

var season: StringName = &"spring":
    set(value):
        season = value
        season_changed.emit(season)

var clock = preload("res://scripts/core/game_clock.gd").new()
var inventory = preload("res://scripts/inventory/inventory_model.gd").new(36)
var farm_plots: Array = []
var gold: int = 500:
    set(value):
        gold = max(value, 0)
        gold_changed.emit(gold)
