extends GutTest

func test_tileset_theme_declares_external_texture_paths() -> void:
    var path := "res://data/visual/tileset_theme.json"
    assert_true(FileAccess.file_exists(path))
    if not FileAccess.file_exists(path):
        return

    var file := FileAccess.open(path, FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    assert_true(typeof(parsed) == TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var data := parsed as Dictionary
    var textures: Variant = data.get("textures", {})
    assert_true(typeof(textures) == TYPE_DICTIONARY)
    if typeof(textures) != TYPE_DICTIONARY:
        return

    var tex_dict := textures as Dictionary
    assert_true(FileAccess.file_exists(String(tex_dict.get("backdrop", ""))))
    assert_true(FileAccess.file_exists(String(tex_dict.get("ground", ""))))
    assert_true(FileAccess.file_exists(String(tex_dict.get("soil_dry", ""))))
    assert_true(FileAccess.file_exists(String(tex_dict.get("soil_wet", ""))))

    var crop_stages: Variant = tex_dict.get("crop_parsnip_stages", [])
    assert_true(typeof(crop_stages) == TYPE_ARRAY)
    if typeof(crop_stages) != TYPE_ARRAY:
        return
    var stages := crop_stages as Array
    assert_eq(stages.size(), 5)
    for stage_path in stages:
        assert_true(FileAccess.file_exists(String(stage_path)))

func test_player_style_declares_external_sprite_frames() -> void:
    var path := "res://data/visual/player_style.json"
    assert_true(FileAccess.file_exists(path))
    if not FileAccess.file_exists(path):
        return

    var file := FileAccess.open(path, FileAccess.READ)
    assert_not_null(file)
    if file == null:
        return

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    assert_true(typeof(parsed) == TYPE_DICTIONARY)
    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var data := parsed as Dictionary
    var frames: Variant = data.get("frames", {})
    assert_true(typeof(frames) == TYPE_DICTIONARY)
    if typeof(frames) != TYPE_DICTIONARY:
        return

    for dir_name in ["up", "down", "left", "right"]:
        var dir_data: Variant = (frames as Dictionary).get(dir_name, {})
        assert_true(typeof(dir_data) == TYPE_DICTIONARY)
        if typeof(dir_data) != TYPE_DICTIONARY:
            continue
        var idle_path := String((dir_data as Dictionary).get("idle", ""))
        assert_true(FileAccess.file_exists(idle_path))

        var walk_frames: Variant = (dir_data as Dictionary).get("walk", [])
        assert_true(typeof(walk_frames) == TYPE_ARRAY)
        if typeof(walk_frames) != TYPE_ARRAY:
            continue
        var walk_array := walk_frames as Array
        assert_true(walk_array.size() >= 2)
        for frame_path in walk_array:
            assert_true(FileAccess.file_exists(String(frame_path)))
