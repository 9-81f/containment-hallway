class_name Main extends Node

@onready var ambient: AudioStreamPlayer2D = $Ambient
@onready var alarm: AudioStreamPlayer2D = $Alarm

func _ready() -> void:
	ambient.play()
	alarm.play()
