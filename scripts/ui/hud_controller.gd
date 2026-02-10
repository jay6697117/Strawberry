extends Control

@onready var gold_label: Label = $GoldLabel
@onready var day_label: Label = $DayLabel
@onready var season_label: Label = $SeasonLabel

func bind_session(session_state: Node) -> void:
    if session_state.has_signal("gold_changed"):
        session_state.gold_changed.connect(_on_gold_changed)

    _on_gold_changed(int(session_state.gold))
    day_label.text = "Day %d" % int(session_state.day)
    season_label.text = String(session_state.season)

func _on_gold_changed(new_gold: int) -> void:
    gold_label.text = "%dG" % new_gold
