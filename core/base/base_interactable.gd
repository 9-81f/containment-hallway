@abstract
class_name BaseInteractable extends Node2D

@onready var sprite: Node = null
@onready var interaction_area: Node = null
@onready var interaction_collision: CollisionShape2D = null
var can_interact := true

## Outline Shader Settings
@export var outline_color := Color.WHITE
@export var outline_width := 0.5
var outline_shader: Shader = preload("res://core/shaders/outline.gdshader")
var outline_material: ShaderMaterial = null

func _ready() -> void:
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			sprite = child
		if child is Area2D:
			interaction_area = child
			interaction_collision = child.get_node_or_null("CollisionShape2D")
			if !interaction_collision:
				push_error("CollisionShape2D for detection area is not found!")
	
	if !sprite:
		push_error("Either Sprite2D or AnimatedSprite2D is required!")
		return
	
	if !interaction_area:
		push_error("Area2D is required!")
		return
		
	_setup_outline()
	
func _process(_delta: float) -> void:
	if interaction_collision:
		if can_interact:
			interaction_collision.disabled = false
		else:
			interaction_collision.disabled = true

@abstract func interact() -> void

func _setup_outline() -> void:
	outline_material = ShaderMaterial.new()
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("outline_color", outline_color)
	outline_material.set_shader_parameter("outline_width", outline_width)
	
func show_outline() -> void:
	if sprite and outline_material:
		sprite.material = outline_material
	
func hide_outline() -> void:
	if sprite:
		sprite.material = null
