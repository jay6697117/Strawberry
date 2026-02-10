extends Node

@onready var world_root: Node = $WorldRoot
@onready var ui_root: Control = $UIRoot
@onready var hud: Control = $UIRoot/HUD
@onready var shop_panel: Control = $UIRoot/ShopPanel

func _ready() -> void:
    assert(world_root != null)
    assert(ui_root != null)
    assert(hud != null)
    assert(shop_panel != null)

    if hud.has_method("bind_session"):
        hud.bind_session(SessionState)

func open_shop() -> void:
    shop_panel.visible = true

func close_shop() -> void:
    shop_panel.visible = false
