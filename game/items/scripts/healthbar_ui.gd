class_name HealthbarUI extends Control

@export var health_data_source: HealthComponent
@onready var progress_bar: ProgressBar = $ProgressBar
var health_percentage: float = 0.0

func _ready() -> void:
	hide()
	if health_data_source:
		health_data_source.health_changed.connect(_on_health_changed, CONNECT_DEFERRED)
		progress_bar.value = 100.0
	else:
		push_error("Health Data Source Not Found!")
		return

func _get_health_percentage(current_h: float, max_h: float) -> float:
	return (current_h / max_h) * 100

func render_ui() -> void:
	modulate.a = 1
	show()
	if progress_bar.value <= 0:
		progress_bar.value = 0.0
	else:
		progress_bar.value = health_percentage
		var secs := 3.0
		var tween := create_tween()
		tween.tween_interval(secs)
		tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.5)
		await tween.finished
		hide()
	
func _on_health_changed(current_health: float, max_health: float) -> void:
	health_percentage = _get_health_percentage(current_health, max_health)
	call_deferred("render_ui")
