class_name Fridge extends Node2D

@onready var static_body: StaticBody2D = $StaticBody2D
@onready var shelves: Array[Node] = $ItemContainer.get_children()
@onready var door: Door = $Door

@export var shelf_items: Array[PackedScene]

func _ready() -> void:
	door.opened.connect(_toggle_interact_items)
	_spawn_shelf_items()
					
func _spawn_shelf_items() -> void:
	for shelf in shelves:
		var total_amount_to_spawn = randi_range(0, 5)
		var amount_to_spawn = randi_range(0, total_amount_to_spawn)
		var x_offset := -10
		var spacing := 4
		for amount in amount_to_spawn:
			if amount > 0:
				var item_dice = randi_range(0, shelf_items.size() - 1)
				var item = shelf_items[item_dice].instantiate()
				if item is BaseInteractable:
					item.can_interact = false
					shelf.add_child(item)
					item.position.x = x_offset
					x_offset += spacing

func _toggle_interact_items() -> void:
	for shelf in shelves:
		for item in shelf.get_children():
			if item is BaseInteractable:
				item.can_interact = true
