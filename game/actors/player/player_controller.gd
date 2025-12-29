class_name PlayerController extends CharacterBody2D

enum PlayerState {
	IDLE,
	WALK,
	RUN,
	PUSH,
	ATTACK,
	KNOCKED,
	DEATH
}

enum Facing {
	FRONT,
	BACK,
	LEFT,
	RIGHT
}

@onready var camera: PlayerCamera = $Camera2D

## Animation Settings
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer

## Debug
@onready var debug: DebugOverlay = $"../../../UI/DebugOverlay"

## Components
@onready var health_comp: HealthComponent = $HealthComponent
@onready var interaction_comp: InteractionComponent = $InteractionComponent
@onready var inventory_comp: InventoryComponent = $InventoryComponent
@onready var combat_comp: CombatComponent = $CombatComponent

## Detections (NOTE: Use component pattern in the future)
@onready var hurtbox: Area2D = $Hurtbox

## Audios
@onready var hurt_grunt_audio: AudioStreamPlayer2D = $HurtGruntAudio

## Movement Settings
var current_state: PlayerState = PlayerState.IDLE
const WALK_SPEED := 80.0
const RUN_SPEED := 100.0
var _applied_speed := 0.0
var _direction := Vector2.ZERO
var last_facing_prefix := "f"
var currently_facing: Facing = Facing.FRONT
var is_knocked := false

## Equipment Settings
var has_weapon_equipped := false

## Move Objects Settings
var movable: Movable = null
var _is_pushing := false

func _ready() -> void:
	if inventory_comp:
		inventory_comp.item_used.connect(_on_inventory_item_usage)
	
	if combat_comp:
		combat_comp.weapon_equipped.connect(func(): has_weapon_equipped = true)
		combat_comp.weapon_unequipped.connect(func(): has_weapon_equipped = false)
	
	if health_comp:
		health_comp.health_depleted.connect(_on_death)
	
	if hurtbox:
		hurtbox.area_entered.connect(_on_hit_entered)
	
	anim_player.animation_finished.connect(
		func(anim_name: String): 
			if "_melee" in anim_name or "_ranged" in anim_name:
				anim_player.stop()
	)
	
func _physics_process(_delta: float) -> void:
	_state_machine()
	
	#//debug.watch("Current State", PlayerState.keys()[current_state])
	#debug.watch("Currently Facing", Facing.keys()[currently_facing])
	#debug.watch("Inventory", str(inventory_comp.inventory))
	#debug.watch("Current Health", str(health_comp.current_health) + "/" + str(health_comp.max_health))
	
	if movable and _direction == Vector2.ZERO:
		_stop_pushing()
	
	if current_state == PlayerState.KNOCKED:
		_stop_pushing()
		velocity = velocity.lerp(Vector2.ZERO, 0.15) 
	elif current_state == PlayerState.ATTACK:
		_stop_pushing()
		_play_melee_animation()
		velocity = Vector2.ZERO
	else:	
		_basic_movement()
		_push_movables()
	
	move_and_slide()
	

func _set_state(new_state: PlayerState) -> void:
	if current_state != new_state:
		current_state = new_state

func _state_machine() -> void:
	if is_knocked:
		_set_state(PlayerState.KNOCKED)
		return
	
	if combat_comp.is_attacking:
		_set_state(PlayerState.ATTACK)
		return
		
	if _is_pushing:
		_set_state(PlayerState.PUSH)
		return

	if velocity.length() == 0.0:
		_set_state(PlayerState.IDLE)
	elif velocity.length() > 0.0 && velocity.length() <= WALK_SPEED:
		_set_state(PlayerState.WALK)
	elif velocity.length() > WALK_SPEED:
		_set_state(PlayerState.RUN)

func _basic_movement() -> void:
	_direction = Input.get_vector("left", "right", "up", "down")
	_applied_speed = (RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED)
	velocity = _direction * _applied_speed
	
	if !has_weapon_equipped or _is_pushing:
		_movement_animations()
	else:
		_movement_with_weapon()
		
func _push_movables() -> void:
	if _direction == Vector2.ZERO: 
		_stop_pushing()
		return
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is Movable:
			var push_dir := -collision.get_normal()
			if push_dir.dot(_direction.normalized()) > 0.7:
				movable = collider
				movable.push(push_dir, self)
				_is_pushing = true
				return
	
	_stop_pushing()

func _stop_pushing() -> void:
	if movable:
		movable.stop()
		movable = null
		_is_pushing = false

func _get_direction_prefix() -> String:
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
		
func _movement_animations() -> void:
	var state_name: String = PlayerState.keys()[current_state].to_lower()
	anim_sprite.play("%s_%s" % [_get_direction_prefix(), state_name])

func _on_inventory_item_usage(item_data: BaseItem.ItemData, amount: int) -> void:
	if item_data is Consumable.ConsumableData:
		_use_consumables(item_data, amount)
	if item_data is Weapon.WeaponData:
		_equip_weapon_item(item_data)
				
func _use_consumables(item_data: BaseItem.ItemData, amount: int) -> void:
	match item_data.status:
		Consumable.Status.HEAL:
			_use_health_item(item_data, amount)
		Consumable.Status.SANITY:
			_use_sanity_item(item_data, amount)
				
func _use_health_item(item_data: Consumable.ConsumableData, amount: int) -> void:
	if health_comp.current_health < health_comp.max_health:
		health_comp.heal(item_data.consumption_value * amount)
		inventory_comp.info_text = "Health healed by %s pts.!" % item_data.consumption_value
		inventory_comp.drop_item()
	else:
		inventory_comp.info_text = "Health is full!"
		
func _use_sanity_item(_item_data: Consumable.ConsumableData, _amount: int) -> void:
	pass
	
func _equip_weapon_item(item_data: Weapon.WeaponData) -> void:
	if !item_data: return
	if has_weapon_equipped:
		combat_comp.unequip()
	else:
		combat_comp.equip_weapon(item_data)

func _movement_with_weapon() -> void:
	var state_name: String = PlayerState.keys()[current_state].to_lower()
	anim_sprite.play("%s_weapon_%s" % [_get_direction_prefix(), state_name])

func _play_melee_animation() -> void:
	if current_state != PlayerState.ATTACK: return
	
	if anim_sprite.is_playing():
		anim_sprite.stop()
	
	var anim_name := "%s_melee" % last_facing_prefix
	
	if anim_player.current_animation != anim_name:
		anim_player.play(anim_name)

func _on_hit_entered(area: Area2D) -> void:
	if area.name != "Hitbox": 
		return
	else:
		if area.monitoring:
			var body: Node = area.get_parent()
			if body is EnemyController:
				camera.shake()
				health_comp.hurt(5)
				play_hit_flash()
				knockback(global_position - body.global_position, 400)
				
func knockback(direction: Vector2, force: float) -> void:
	is_knocked = true
	play_hurt_audio()
	velocity = direction.normalized() * force
	await get_tree().create_timer(1.0).timeout
	is_knocked = false
	
func play_hurt_audio() -> void:
	hurt_grunt_audio.stop()
	hurt_grunt_audio.pitch_scale = randf_range(0.9, 1.2)
	hurt_grunt_audio.play()
	
func play_hit_flash() -> void:
	var mat = anim_sprite.material as ShaderMaterial
	var parameter :=  "enabled"
	mat.set_shader_parameter(parameter, true)
	await get_tree().create_timer(0.2).timeout
	mat.set_shader_parameter(parameter, false)
	
func _on_death() -> void:
	hurtbox.monitoring = false
	velocity = Vector2.ZERO
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.5)
	await tween.finished
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://ui/menu/GameOver.tscn")
