extends Node

@onready var world_root: Node = $WorldRoot
@onready var ui_root: Control = $UIRoot

func _ready() -> void:
    assert(world_root != null)
    assert(ui_root != null)
