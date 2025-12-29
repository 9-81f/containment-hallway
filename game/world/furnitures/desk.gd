class_name Desk extends Node2D

@onready var item_container = $ItemContainer
var computer: Computer = null

func _ready() -> void:
	for item in item_container.get_children():
		if item is Computer:
			computer = item
			computer.item_printed.connect(
				func(printed_item: BaseItem):
					item_container.add_child(printed_item)
			)
