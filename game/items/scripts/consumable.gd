class_name Consumable extends BaseItem

enum Status {
	HEAL,
	SANITY,
}

@export var consumption_value := 10
@export var status: Status = Status.HEAL
	
class ConsumableData extends ItemData:
	var consumption_value: int
	var status: Status
	
	func map_item_to_consumable_data(item: Consumable) -> void:
		map_item_to_item_data(item)
		consumption_value = item.consumption_value
		status = item.status
		
