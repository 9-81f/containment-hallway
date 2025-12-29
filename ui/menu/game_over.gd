class_name GameOverMenu extends CanvasLayer

@onready var game_over_audio: AudioStreamPlayer2D = $GameOverAudio
@onready var back_btn: Button = $PanelContainer/CenterContainer/VBoxContainer/Back

func _ready() -> void:
	game_over_audio.play()
	back_btn.pressed.connect(
		func():
			get_tree().call_deferred("change_scene_to_file", "res://ui/menu/MainMenu.tscn")
	)
	back_btn.grab_focus()
