extends RefCounted
class_name ShippingBinService

var _pending: Dictionary = {}

func add_item(item_id: String, amount: int) -> void:
    _pending[item_id] = int(_pending.get(item_id, 0)) + amount

func pending_count() -> int:
    var count := 0
    for item_id in _pending.keys():
        count += int(_pending[item_id])
    return count

func settle(price_table: Dictionary) -> int:
    var total := 0
    for item_id in _pending.keys():
        var price := int(price_table.get(item_id, 0))
        total += int(_pending[item_id]) * price
    _pending.clear()
    return total

func settle_to_session(session_state: Node, price_table: Dictionary) -> int:
    var earned := settle(price_table)
    session_state.gold += earned
    return earned
