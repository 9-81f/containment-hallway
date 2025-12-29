class_name MainMenu extends CanvasLayer

@onready var v_box: VBoxContainer = $PanelContainer/CenterContainer/VBoxContainer
@onready var ambient: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	ambient.play()
	
	var first_btn := v_box.get_child(1) as Button
	var exit_btn := v_box.get_child(2) as Button
	
	first_btn.grab_focus()
	
	first_btn.pressed.connect(
		func():
			get_tree().change_scene_to_file("res://main/Main.tscn")
	)
	
	exit_btn.pressed.connect(
		func():
			get_tree().quit()
	)
	
