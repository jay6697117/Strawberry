extends Control

@onready var gold_label: Label = $GoldLabel
@onready var day_label: Label = $DayLabel
@onready var season_label: Label = $SeasonLabel
@onready var inventory_label: Label = $InventoryLabel
@onready var status_label: Label = $StatusLabel

func bind_session(session_state: Node) -> void:
    if session_state.has_signal("gold_changed"):
        if not session_state.gold_changed.is_connected(_on_gold_changed):
            session_state.gold_changed.connect(_on_gold_changed)

    if session_state.has_signal("day_changed"):
        if not session_state.day_changed.is_connected(_on_day_changed):
            session_state.day_changed.connect(_on_day_changed)

    if session_state.has_signal("season_changed"):
        if not session_state.season_changed.is_connected(_on_season_changed):
            session_state.season_changed.connect(_on_season_changed)

    _on_gold_changed(int(session_state.gold))
    _on_day_changed(int(session_state.day))
    _on_season_changed(StringName(session_state.season))

func bind_world(world_node: Node) -> void:
    if world_node.has_signal("status_changed"):
        if not world_node.status_changed.is_connected(_on_status_changed):
            world_node.status_changed.connect(_on_status_changed)

    if world_node.has_signal("inventory_changed"):
        if not world_node.inventory_changed.is_connected(_on_inventory_changed):
            world_node.inventory_changed.connect(_on_inventory_changed)

func _on_gold_changed(new_gold: int) -> void:
    gold_label.text = "%dG" % new_gold

func _on_day_changed(new_day: int) -> void:
    day_label.text = "Day %d" % new_day

func _on_season_changed(new_season: StringName) -> void:
    season_label.text = String(new_season)

func _on_inventory_changed(seed_count: int, crop_count: int, pending_count: int) -> void:
    inventory_label.text = "Seeds: %d | Crop: %d | Bin: %d" % [seed_count, crop_count, pending_count]

func _on_status_changed(text: String) -> void:
    status_label.text = text
