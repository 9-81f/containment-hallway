class_name DecoDoor extends BaseInteractable

@onready var label: Label = $CanvasLayer/Label
@export var interaction_message: String = ''

func _ready() -> void:
	label.hide()

func interact() -> void:
	label.show()
	label.text = interaction_message
	await get_tree().create_timer(3.0).timeout
	label.hide()
