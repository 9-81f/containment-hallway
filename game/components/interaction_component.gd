class_name InteractionComponent extends Area2D

@export var owner_entity: Node2D
@onready var interaction_shapes: Dictionary[String, CollisionShape2D] = {
	"FRONT": $FrontShape,
	"BACK": $BackShape,
	"LEFT": $LeftShape,
	"RIGHT": $RightShape
}

## Interaction Settings
var interactions_in_range: Array[BaseInteractable]
var current_interaction: BaseInteractable

func _ready() -> void:
	area_entered.connect(_on_interactable_entered)
	area_exited.connect(_on_interactable_exited)
	
func _on_interactable_entered(area: Area2D) -> void:
	if area.get_parent() is BaseInteractable:
		var interactable: BaseInteractable = area.get_parent()
		interactable.show_outline()
		interactions_in_range.append(interactable)

func _on_interactable_exited(area: Area2D) -> void:
	if area.get_parent() is BaseInteractable:
		var interactable: BaseInteractable = area.get_parent()
		interactable.hide_outline()
		interactions_in_range.erase(interactable)
		
func _process(_delta: float) -> void:
	shape_direction_toggle()
	interactions_in_range.sort_custom(_sort_nearest)
	var closest := interactions_in_range[0] if interactions_in_range.size() > 0  else null
	if closest:
		#owner_entity.debug.watch("Can interact", str(closest.can_interact))
		current_interaction = closest
		if Input.is_action_just_pressed("interact") and closest.can_interact:
			_item_interaction(closest)
			_door_interaction(closest)
			closest.interact()

func _sort_nearest(a: BaseInteractable, b: BaseInteractable) -> bool:
	var a_distance := owner_entity.global_position.distance_to(a.global_position)
	var b_distance := owner_entity.global_position.distance_to(b.global_position)
	return a_distance < b_distance
	
func shape_direction_toggle() -> void:
	var facing: String = owner_entity.Facing.keys()[owner_entity.currently_facing]
	if owner_entity is PlayerController:
		for key in interaction_shapes.keys():
			var shape: CollisionShape2D = interaction_shapes[key]
			if key == facing:
				shape.disabled = false
			else:
				shape.disabled = true
			
func _item_interaction(interaction: BaseInteractable) -> void:
	if interaction is BaseItem:
		if owner_entity is PlayerController:
			owner_entity.inventory_comp.store(interaction)

func _door_interaction(interaction: BaseInteractable) -> void:
	if interaction is Door:
		if interaction.has_lock and interaction.lock_comp.key_type == LockComponent.KeyTypes.ACCESS_KEY:
			interaction.lock_comp.show_message_box("Searching for appropriate key...")
			await interaction.search_key((owner_entity as PlayerController).inventory_comp.get_key_items())

func _computer_interaction(interaction: BaseInteractable) -> void:
	if interaction is Computer:
		if interaction.has_lock and interaction.lock_comp.key_type == LockComponent.KeyTypes.ACCESS_KEY:
			interaction.lock_comp.show_message_box("Searching for appropriate key...")
			await interaction.search_key((owner_entity as PlayerController).inventory_comp.get_key_items())
