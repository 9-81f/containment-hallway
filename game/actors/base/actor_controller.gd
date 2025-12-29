class_name ActorController extends CharacterBody2D

#NOTE: For future improvements follow node based FSM

enum State {
	IDLE,
	WALK,
	RUN,
	PUSH,
	ATTACK,
}

enum Facing {
	FRONT,
	BACK,
	LEFT,
	RIGHT,
}

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_body: CollisionShape2D = $CollisionShape2D

## State Variables
var current_state: State = State.IDLE

## Movement Settings
@export_group("Movement Settings")
@export var walk_speed := 80.0
@export var run_speed := 100.0

## Directional Variables
var _direction := Vector2.ZERO
var last_facing_prefix := "f"
var currently_facing: Facing = Facing.FRONT
var is_knocked := false

##Push Movable Settings
var movable: Movable
var is_pushing := false

func _movement() -> void:
	pass

func stop_movement() -> void:
	velocity = Vector2.ZERO

func set_state(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state

func _state_machine() -> void:
	if is_pushing:
		set_state(State.PUSH)
		return
	
	if velocity.length() > 0.0 && velocity.length() <= walk_speed:
		set_state(State.WALK)
	elif velocity.length() > walk_speed:
		set_state(State.RUN)
	else:
		set_state(State.IDLE)

func get_direction_prefix() -> String:
	var x := _direction.x
	var y := _direction.y
	var prefix := ""
	
	if _direction == Vector2.ZERO:
		return last_facing_prefix
		
	if abs(y) > abs(x):
		if y > 0:
			prefix = "f"
			currently_facing = Facing.FRONT
		else:
			prefix = "b"
			currently_facing = Facing.BACK
		anim_sprite.flip_h = false
	else:
		prefix = "s"
		anim_sprite.flip_h = x < 0
		if x < 0:
			currently_facing = Facing.LEFT
		else:
			currently_facing = Facing.RIGHT
	
	last_facing_prefix = prefix
	
	return prefix

func push_movable() -> void:
	if movable and velocity == Vector2.ZERO:
		stop_pushing()
		return
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Movable:
			var push_dir := -collision.get_normal()
			if push_dir.dot(_direction.normalized()) > 0.7:
				movable = collider
				movable.push(push_dir, self)
				is_pushing = true
				return
	
	stop_pushing()
	
func stop_pushing() -> void:
	if movable:
		is_pushing = false
		movable.stop()
		movable = null
	
func knockback(direction: Vector2, force: float) -> void:
	is_knocked = true
	velocity = direction.normalized() * force
	is_knocked = false
	
func play_hit_flash() -> void:
	var mat = anim_sprite.material as ShaderMaterial
	var parameter :=  "enabled"
	mat.set_shader_parameter(parameter, true)
	await get_tree().create_timer(0.2).timeout
	mat.set_shader_parameter(parameter, false)
	
