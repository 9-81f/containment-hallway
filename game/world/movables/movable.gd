class_name Movable extends CharacterBody2D

@export var texture: Texture2D
@onready var sprite: Sprite2D = $Sprite2D

const _PUSH_SPEED := 20.0
const _FRICTION := 500.0

var pusher: CharacterBody2D
var is_being_pushed := false
var _push_direction := Vector2.ZERO

func _ready() -> void:
	sprite.texture = texture

func _physics_process(delta: float) -> void:
	if is_being_pushed:
		velocity = _push_direction * _PUSH_SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, _FRICTION * delta)
	
	move_and_slide()
	
	## Check if there's any collision happening
	if get_slide_collision_count() > 0:
		## Loop through any possible collision
		for i in get_slide_collision_count():
			## Get a single collision by collision index
			var collision := get_slide_collision(i)
			## Check collider instance
			## If collider is not assigned pusher actor (e.g: walls, desks, and other bodies with collision shapes)
			## break the loop
			if collision.get_collider() != pusher:
				stop()
				break
	
func push(direction: Vector2, actor: CharacterBody2D) -> void:
	is_being_pushed = true
	_push_direction = direction.normalized()
	pusher = actor
	
func stop() -> void:
	is_being_pushed = false
	_push_direction = Vector2.ZERO
	pusher = null
