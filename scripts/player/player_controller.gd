extends CharacterBody2D

@export var move_speed: float = 100.0

func _physics_process(_delta: float) -> void:
    velocity = Vector2.ZERO
