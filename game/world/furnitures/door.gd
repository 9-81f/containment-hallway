class_name Door extends BaseInteractable

@export var sprite_frames: SpriteFrames
@export var has_lock: bool = false

@onready var static_body_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var lock_comp: LockComponent = $LockComponent 

signal opened

func _ready() -> void:
	super._ready()
	
	if sprite is AnimatedSprite2D:
		sprite.sprite_frames = sprite_frames
	
	if lock_comp:
		lock_comp.enabled = has_lock
		lock_comp.unlocked.connect(_on_clearance_accepted)
		
func interact() -> void:
	if !can_interact: return

	if lock_comp and lock_comp.enabled:
		if lock_comp.is_locked:
			match lock_comp.key_type:
				lock_comp.KeyTypes.PASSCODE:
					lock_comp.show_passcode_ui()
				lock_comp.KeyTypes.ACCESS_KEY:
					lock_comp.show_message_box("Clearance level %d is required!" % lock_comp.clearance_level)
			return
			
	if sprite is AnimatedSprite2D:
		sprite.play("open")
		opened.emit()
		can_interact = false
		static_body_collision.disabled = true
	else: 
		push_error("No AnimatedSprite2D found!")

func search_key(keys: Array[KeyItem.KeyItemData]) -> void:
	if keys.is_empty(): 
		lock_comp.show_message_box("No clearance items found!")
		return
		
	for key in keys:
		if lock_comp.accept_clearance(key):
			break

func _on_clearance_accepted() -> void:
	lock_comp.show_message_box("Access Cleared!")
