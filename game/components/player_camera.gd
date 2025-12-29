class_name PlayerCamera extends Camera2D

@export var max_shake := 10.0
@export var shake_decay := 10.0

var _shake_str: float

func shake() -> void:
	_shake_str = max_shake
	
func _process(delta: float) -> void:
	if _shake_str > 0:
		_shake_str = lerp(_shake_str, 0.0, shake_decay * delta)
		offset = Vector2(
			randf_range(-_shake_str, _shake_str),
			randf_range(-_shake_str, _shake_str)
		)
