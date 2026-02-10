extends GutTest

func test_dialogue_service_picks_matching_dialogue() -> void:
    if not FileAccess.file_exists("res://scripts/npc/dialogue_service.gd"):
        fail_test("res://scripts/npc/dialogue_service.gd should exist")
        return

    var dialogue_script := load("res://scripts/npc/dialogue_service.gd")
    assert_not_null(dialogue_script)
    if dialogue_script == null:
        return

    var service = dialogue_script.new()
    var dialogues := {
        "merchant_greeting": {
            "conditions": {
                "friendship_min": 0,
                "friendship_max": 199,
                "season": "spring"
            },
            "text": "hello"
        },
        "merchant_other": {
            "conditions": {
                "friendship_min": 200,
                "friendship_max": 399,
                "season": "spring"
            },
            "text": "other"
        }
    }

    var picked = service.pick_dialogue(dialogues, 50, "spring", "merchant")
    assert_eq(picked["text"], "hello")
