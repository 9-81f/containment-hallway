class_name Level1 extends Node2D

@onready var win_area: Area2D = $WinArea

func _ready() -> void:
	win_area.body_entered.connect(
		func(body: Node2D):
			if body is PlayerController:
				get_tree().call_deferred("change_scene_to_file", "res://ui/menu/WinMenu.tscn")
)
