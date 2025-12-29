class_name LockComponent extends CanvasLayer

enum KeyTypes {
	PASSCODE,
	ACCESS_KEY
}

@export var key_type: KeyTypes
@export var clearance_level: int = 0
@export var passcode: String

@onready var overlay: ColorRect = $ColorRect
@onready var passcode_ui: CenterContainer = $CenterContainer
@onready var buttons: Array[Node] = $CenterContainer/PanelContainer/VBoxContainer/GridContainer.get_children()
@onready var input_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Label
@onready var message_box: Label = $MessageBox

const MAX_LENGTH := 6
const WAIT_TIME := 1.5

var enabled: bool
var _is_ui_open := false
var is_locked := true
var info_text: String = ''

signal unlocked

func _ready() -> void:
	overlay.hide()
	passcode_ui.hide()
	message_box.hide()
	
	if key_type == KeyTypes.PASSCODE and passcode.is_empty():
		push_warning("Fill in the passcode!")
		
	for button in buttons:
		if button is Button:
			if button.name == "Clear":
				button.pressed.connect(_on_clear_pressed)
			elif button.name == "Enter":
				button.pressed.connect(_on_enter_pressed)
			else:
				button.pressed.connect(_on_numpad_pressed.bind(button.name))
	
func _process(_delta: float) -> void:
	if !enabled: return
	if key_type == KeyTypes.PASSCODE and _is_ui_open and can_process(): 
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			hide_passcode_ui()

func show_message_box(message: String) -> void:
	message_box.text = message
	message_box.show()
	await get_tree().create_timer(WAIT_TIME).timeout
	message_box.hide()
	message_box.text = ""
	
func show_passcode_ui() -> void:
	_is_ui_open = true
	overlay.show()
	passcode_ui.show()
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	if !buttons.is_empty():
		(buttons[0] as Button).grab_focus()
	get_tree().paused = true

func hide_passcode_ui() -> void:
	passcode_ui.hide()
	overlay.hide()
	_is_ui_open = false
	
	await get_tree().process_frame
	
	process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	_clear_input()

func _clear_input() -> void:
	input_label.text = ""
	
func accept_clearance(item_data: KeyItem.KeyItemData) -> bool:
	if item_data.access_level == clearance_level:
		is_locked = false
		unlocked.emit()
		return true
	return false
	
func _on_numpad_pressed(value: String) -> void:
	if input_label.text.length() >= MAX_LENGTH: return
	input_label.text += value
	
func _on_enter_pressed() -> void:
	if input_label.text == passcode:
		is_locked = false
		input_label.text = "UNLOCKED!"
		unlocked.emit()
		await get_tree().create_timer(WAIT_TIME).timeout
		hide_passcode_ui()
	else:
		input_label.text = "WRONG!"
		await get_tree().create_timer(WAIT_TIME).timeout
		_clear_input()
	
func _on_clear_pressed() -> void:
	_clear_input()
