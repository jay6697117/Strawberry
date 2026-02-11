extends Node

@onready var world_root: Node = $WorldRoot
@onready var farm_world: Node2D = $WorldRoot/FarmWorld
@onready var ui_root: Control = $UIRoot
@onready var hud: Control = $UIRoot/HUD
@onready var shop_panel: Control = $UIRoot/ShopPanel

func _enter_tree() -> void:
    if SaveSystem != null and SaveSystem.has_method("load_and_apply_to_session"):
        SaveSystem.load_and_apply_to_session()

func _ready() -> void:
    assert(world_root != null)
    assert(farm_world != null)
    assert(ui_root != null)
    assert(hud != null)
    assert(shop_panel != null)

    if hud.has_method("bind_session"):
        hud.bind_session(SessionState)

    if hud.has_method("bind_world"):
        hud.bind_world(farm_world)

    if farm_world.has_method("request_hud_sync"):
        farm_world.request_hud_sync()

func open_shop() -> void:
    shop_panel.visible = true

func close_shop() -> void:
    shop_panel.visible = false
