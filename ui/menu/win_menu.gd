class_name WinMenu extends CanvasLayer

@onready var replay_btn: Button = $PanelContainer/CenterContainer/VBoxContainer/Replay
@onready var back_btn: Button = $PanelContainer/CenterContainer/VBoxContainer/BackToMainMenu
@onready var win_audio: AudioStreamPlayer2D = $WinAudio

func _ready() -> void:
	win_audio.play()
	
	replay_btn.grab_focus()
	
	replay_btn.pressed.connect(
		func():
			get_tree().change_scene_to_file("res://main/Main.tscn")
	)
	
	back_btn.pressed.connect(
		func():
			get_tree().change_scene_to_file("res://ui/menu/MainMenu.tscn")
	)
	
