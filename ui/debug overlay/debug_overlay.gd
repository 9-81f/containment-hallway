class_name DebugOverlay extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var vbox: VBoxContainer = $PanelContainer/VBoxContainer
var _watched: Dictionary[String, String] = {}

func _ready() -> void:
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.scale = Vector2(0.3, 0.3)

func _process(_delta: float) -> void:
	visible = false if _watched.is_empty() else true
	
	for key in _watched:	
		var value := _watched[key]
		var label: Label = vbox.get_node_or_null(key)
		if label:
			label.text = "%s: %s" % [key, value]
		else:
			label = Label.new()
			label.name = key
			label.text = "%s: %s" % [key, value]
			vbox.add_child(label)
	
	for label in vbox.get_children():
		if !_watched.has(label.name):
			label.queue_free()
	
	
func watch(prop: String, value: String) -> void:
	_watched[prop] = value

func clear() -> void:
	_watched.clear()
	
