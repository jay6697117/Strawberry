extends Node

signal gold_changed(new_gold: int)

var day: int = 1
var season: StringName = &"spring"
var clock = preload("res://scripts/core/game_clock.gd").new()
var inventory = preload("res://scripts/inventory/inventory_model.gd").new(36)
var gold: int = 500:
    set(value):
        gold = max(value, 0)
        gold_changed.emit(gold)
