extends RefCounted
class_name InventoryModel

var _slots: Array = []

func _init(slot_count: int = 36) -> void:
    _slots.resize(slot_count)
    for i in _slots.size():
        _slots[i] = {"item_id": "", "amount": 0}

func add_item(item_id: String, amount: int) -> void:
    for slot in _slots:
        if slot["item_id"] == item_id:
            slot["amount"] += amount
            return

    for slot in _slots:
        if slot["item_id"].is_empty():
            slot["item_id"] = item_id
            slot["amount"] = amount
            return

func remove_item(item_id: String, amount: int) -> bool:
    var remain := amount
    for slot in _slots:
        if slot["item_id"] != item_id:
            continue
        var taken := mini(int(slot["amount"]), remain)
        slot["amount"] -= taken
        remain -= taken
        if int(slot["amount"]) <= 0:
            slot["item_id"] = ""
            slot["amount"] = 0
        if remain <= 0:
            return true
    return false

func get_total(item_id: String) -> int:
    var total := 0
    for slot in _slots:
        if slot["item_id"] == item_id:
            total += int(slot["amount"])
    return total

func to_item_totals() -> Dictionary:
    var totals: Dictionary = {}
    for slot in _slots:
        var item_id := String(slot.get("item_id", ""))
        var amount := int(slot.get("amount", 0))
        if item_id.is_empty() or amount <= 0:
            continue
        totals[item_id] = int(totals.get(item_id, 0)) + amount
    return totals

func replace_with_item_totals(totals: Dictionary) -> void:
    for i in _slots.size():
        _slots[i] = {"item_id": "", "amount": 0}

    for item_id in totals.keys():
        var amount := int(totals[item_id])
        if amount <= 0:
            continue
        add_item(String(item_id), amount)
