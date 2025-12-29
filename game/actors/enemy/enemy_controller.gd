class_name EnemyController extends ActorController

@export var patrol_bounds := Vector2(50, 50)
var patrol_target: Vector2
var patrol_stop_distance := 5#px
var spawn_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D

##Debug
@onready var debug: DebugOverlay = $"../../../UI/DebugOverlay"

## Chase Settings
@onready var chase_area: Area2D = $ChaseArea
@onready var chase_detection: CollisionShape2D = $ChaseArea/CollisionShape2D
var is_chasing := false
var is_resting_from_chase := true

## Attack Detection Settings
@onready var attack_area: Area2D = $AttackArea
@onready var attack_detection: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurtbox: Area2D = $Hitbox
@onready var hitbox: Area2D = $Hitbox
var is_attacking := false

## Patrol Settings
var is_patrolling := false

## Audios
@onready var hit_impact_audio: AudioStreamPlayer2D = $HitImpactAudio
@onready var attack_audio: AudioStreamPlayer2D = $AttackAudio

## Components
@onready var health_comp: HealthComponent = $HealthComponent

func _ready() -> void:
	hitbox.monitoring = false
	anim_player.play("default")
	
	chase_area.body_entered.connect(_on_player_detected)
	chase_area.body_exited.connect(_on_player_escaped)
	
	attack_area.body_entered.connect(_on_player_vulnerable)
	attack_area.body_exited.connect(_on_player_evasion)
	
	if health_comp:
		health_comp.health_depleted.connect(_on_health_depleted)

func _can_patrol() -> bool:
	return !is_patrolling and !is_chasing and !is_attacking and is_resting_from_chase

func _physics_process(_delta: float) -> void:
	#debug.watch("enemy hitbox monitoring", str(hitbox.monitoring))
	#debug.watch("enemy direction", str(_direction))
	#debug.watch("enemy health", "%s/%s" % [str(health_comp.current_health), str(health_comp.max_health)])
	
	if _can_patrol():
		_patrol()
	
	push_movable()
	
	if is_knocked:
		velocity = velocity.lerp(Vector2.ZERO, 0.15) 
	elif is_attacking:
		velocity = Vector2.ZERO

	move_and_slide()
	
func _movement() -> void:
	velocity = _direction.normalized() * (run_speed if is_chasing else walk_speed)

func play_hit_impact_audio() -> void:
	hit_impact_audio.stop()
	hit_impact_audio.pitch_scale = randf_range(0.5, 1.2)
	hit_impact_audio.play(0.51)

func play_attack_audio() -> void:
	attack_audio.stop()
	attack_audio.pitch_scale = randf_range(0.5, 1.2)
	attack_audio.play()
	
func hit() -> void:
	if !is_attacking: return
	play_attack_audio()
	hitbox.monitoring = true

func _patrol() -> void:
	spawn_position = global_position
	
	is_patrolling = true
	
	var offset := Vector2(
		randf_range(-patrol_bounds.x, patrol_bounds.x),
		randf_range(-patrol_bounds.y, patrol_bounds.y)
	)
	
	patrol_target = spawn_position + offset
	
	while position.distance_to(patrol_target) > patrol_stop_distance and is_patrolling:
		_direction = patrol_target - position
		_movement()
		await get_tree().process_frame
	
	await _reset_patrol()

func _reset_patrol() -> void:
		velocity = Vector2.ZERO
		await get_tree().create_timer(3.0).timeout
		is_patrolling = false

func _player_check(body: Node2D) -> bool:
	return body is PlayerController

func _on_health_depleted() -> void:	
	stop_movement()
	collision_body.disabled = true
	anim_player.stop()
	hitbox.monitoring = false
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.5)
	await tween.finished
	queue_free()

func _on_player_detected(body: Node2D) -> void:
	## start chase
	if is_chasing: return
	if _player_check(body):
		is_chasing = true
		is_resting_from_chase = false
		is_patrolling = false
		is_attacking = false
		while position.distance_to(body.position) > 5 and is_chasing:
			_direction = body.position - position
			_movement()
			await get_tree().process_frame

func _on_player_escaped(body: Node2D) -> void:
	## stop chase
	if !is_chasing or is_resting_from_chase: return
	if _player_check(body):
		is_chasing = false
		
		while position.distance_to(spawn_position) > 5 and !is_resting_from_chase:
			_direction = spawn_position - position
			_movement()
			await get_tree().process_frame
		
		await _reset_patrol()
		
		is_resting_from_chase = true

func _on_player_vulnerable(body: Node2D) -> void:
	if is_attacking: return
	if _player_check(body):
		is_chasing = false
		is_resting_from_chase = true
		is_attacking = true
		anim_player.play("attack")
		chase_area.monitoring = false

func _on_player_evasion(body: Node2D) -> void:
	if !is_attacking: return
	if _player_check(body):
		is_attacking = false
		is_resting_from_chase = false
		anim_player.play_backwards("attack")
		anim_player.play("default")
		hitbox.monitoring = false
		chase_area.monitoring = true
