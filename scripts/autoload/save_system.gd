extends Node

const SAVE_PATH := "user://savegame.json"

func build_default_save_data() -> Dictionary:
    return {
        "schema_version": preload("res://scripts/save/save_migrator.gd").CURRENT_SCHEMA,
        "gold": int(SessionState.gold),
        "season": String(SessionState.season),
        "day": int(SessionState.day)
    }

func normalize_save_data(data: Dictionary) -> Dictionary:
    var migrator = preload("res://scripts/save/save_migrator.gd")
    return migrator.migrate(data)

func save_game(data: Dictionary = {}) -> Error:
    var payload := data
    if payload.is_empty():
        payload = build_default_save_data()

    payload = normalize_save_data(payload)

    var codec = preload("res://scripts/save/save_codec.gd")
    var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if save_file == null:
        return ERR_CANT_OPEN

    save_file.store_string(codec.encode(payload))
    return OK

func load_game() -> Error:
    var _loaded := load_game_data()
    return OK

func load_game_data() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var save_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if save_file == null:
        return {}

    var codec = preload("res://scripts/save/save_codec.gd")
    var decoded = codec.decode(save_file.get_as_text())
    if decoded.is_empty():
        return {}

    return normalize_save_data(decoded)

func save_exists() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func reset_with_defaults() -> void:
    save_game(build_default_save_data())

func import_save(raw_json: String) -> Error:
    var codec = preload("res://scripts/save/save_codec.gd")
    var decoded = codec.decode(raw_json)
    if decoded.is_empty():
        return ERR_PARSE_ERROR
    return save_game(decoded)

func export_save() -> String:
    var data := load_game_data()
    if data.is_empty():
        data = build_default_save_data()
    var codec = preload("res://scripts/save/save_codec.gd")
    return codec.encode(data)

func apply_to_session(data: Dictionary) -> void:
    SessionState.gold = int(data.get("gold", SessionState.gold))
    SessionState.day = int(data.get("day", SessionState.day))
    SessionState.season = StringName(data.get("season", SessionState.season))

func load_and_apply_to_session() -> Error:
    var data := load_game_data()
    if data.is_empty():
        return ERR_FILE_NOT_FOUND
    apply_to_session(data)
    return OK
