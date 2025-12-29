class_name BaseItem extends BaseInteractable

@export var icon: Texture2D
@export var item_name: String
@export var quantity: int = 1
@export var max_quantity: int = 20
@export_multiline var description: String
var droppable := true
var usable := true

func interact() -> void:
	if can_interact:
		queue_free()
		
class ItemData:
	var icon: Texture2D
	var item_name: String
	var description: String
	var quantity: int
	var max_quantity: int
	var droppable: bool
	var usable: bool
	
	func map_item_to_item_data(item: BaseItem) -> void:
		icon = item.icon
		item_name = item.item_name
		description = item.description
		quantity = item.quantity
		max_quantity = item.max_quantity
		droppable = item.droppable
		usable = item.usable
