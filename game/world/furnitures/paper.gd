class_name Paper extends BaseInteractable

@export_multiline var paper_text: String = ""

@onready var paper_ui: CanvasLayer = $PaperUI
@onready var paper_rich_text_label: RichTextLabel = $PaperUI/CenterContainer/VBoxContainer/PanelContainer/RichTextLabel

var _is_ui_open: bool = false

func _ready() -> void:
	super._ready()
	
	if paper_ui:
		paper_ui.hide()
		_is_ui_open = false
	
	if paper_text:
		paper_rich_text_label.text = paper_text

func _process(_delta: float) -> void:
	if _is_ui_open:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact") or  Input.is_action_just_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_hide_ui()
	
func _open_ui() -> void:
	_is_ui_open = true
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	paper_ui.show()
	paper_rich_text_label.grab_focus()
	hide_outline()
	get_tree().paused = true
	
func _hide_ui() -> void:
	_is_ui_open = false
	paper_ui.hide()
	show_outline()
	
	await get_tree().process_frame
	
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_INHERIT

func interact() -> void:
	if !_is_ui_open:
		_open_ui()
