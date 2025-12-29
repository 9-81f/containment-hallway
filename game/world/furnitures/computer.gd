class_name Computer extends BaseInteractable

@onready var label: Label = $CanvasLayer/Label
@onready var lock_comp: LockComponent = $LockComponent
@export var spawn_item: PackedScene
signal item_printed(item: BaseItem)
var has_printed := false

func interact() -> void:
	if !can_interact: return

	if lock_comp and lock_comp.enabled:
		if lock_comp.is_locked:
			match lock_comp.key_type:
				lock_comp.KeyTypes.PASSCODE:
					lock_comp.show_passcode_ui()
				lock_comp.KeyTypes.ACCESS_KEY:
					show_message_box("Keycard Level 1 required")
			return
	
	if has_printed:
		show_message_box("This stuff is too fancy for this simple task...")
		return
		
	has_printed = true
	show_message_box("Printing Keycard Level 2...")
	await get_tree().create_timer(1.5).timeout
	show_message_box("Task Complete!")
	var printed := spawn_item.instantiate()
	item_printed.emit(printed)
	
func search_key(keys: Array[KeyItem.KeyItemData]) -> void:
	if keys.is_empty(): 
		lock_comp.show_message_box("No clearance items found!")
		return
		
	for key in keys:
		if lock_comp.accept_clearance(key):
			break

func _on_clearance_accepted() -> void:
	show_message_box("Keycard Level 1 Accepted!")

func show_message_box(message: String) -> void:
	label.text = message
	label.show()
	await get_tree().create_timer(2.0).timeout
	label.hide()
	label.text = ""
