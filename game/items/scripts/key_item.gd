class_name KeyItem extends BaseItem

@export var access_level := 1

class KeyItemData extends BaseItem.ItemData:
	var access_level := 0
	
	func map_item_to_key_item_data(item: BaseItem):
		item.droppable = false
		item.usable = false
		super.map_item_to_item_data(item)
		access_level = item.access_level
