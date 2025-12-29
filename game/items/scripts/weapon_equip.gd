class_name WeaponEquip extends Node2D

var weapon_data: Weapon.WeaponData

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var swing_audio: AudioStreamPlayer2D = $SwingAudio

signal att_started
signal att_finished
signal hit_made

var is_attacking := false

func _ready() -> void:
	anim_player.animation_finished.connect(_on_swing_finished)
	hitbox.area_entered.connect(_on_area_entered)
	hitbox.monitoring = false

func set_weapon_data(item_data: Weapon.WeaponData) -> void:
	weapon_data = item_data

func hold(direction_prefix: String, holder_state: String) -> void:
	var valid_states = ["idle", "walk", "run"]
	if holder_state not in valid_states: return
	
	var anim_name := "%s_%s" % [direction_prefix, holder_state]
		
	if anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.play(anim_name)
	else:
		push_warning("Animation not found :", anim_name)
	
func melee(direction_prefix: String) -> void:
	is_attacking = true
	att_started.emit()
	anim_sprite.stop()
	anim_player.play("%s_swing" % direction_prefix)
	swing_audio.pitch_scale = randf_range(0.7, 1.2)
	swing_audio.play()

func hit() -> void:
	hitbox.monitoring = true
	
func stop_hit() -> void:
	hitbox.monitoring = false

func _on_area_entered(area: Area2D) -> void:
	if area.name != "Hurtbox": 
		return
		
	var body: Node2D = area.get_parent()
	if body is EnemyController:
		hit_made.emit()
		body.play_hit_impact_audio()
		body.hit_impact_audio.play(0.51)
		body.play_hit_flash()
		body.health_comp.hurt(weapon_data.damage)
		var knockback_dir := body.global_position - global_position
		body.knockback(knockback_dir, 400.0)
	
func _on_swing_finished(anim_name: String) -> void:
	if "_swing" in anim_name:
		is_attacking = false
		stop_hit()
		anim_player.stop()
		att_finished.emit()
