extends Node2D
class_name AttackManager

class Attack extends Area2D:
	var hitboxes: Array = []
	var duration: float
	var cooldown: float
	var startup: float
	var damage: int
	var knockback: Vector2

	func _init(
		p_hitboxes: Array,
		p_damage: int = 1,
		p_duration: float = 0.22,
		p_cooldown: float = 0.35,
		p_startup: float = 0.04,
		p_knockback: Vector2 = Vector2(180, -40)
	) -> void:
		self.hitboxes	= p_hitboxes
		self.damage		= p_damage
		self.duration	= p_duration
		self.cooldown	= p_cooldown
		self.startup  	= p_startup
		self.knockback	= p_knockback

	func ready():
		collision_layer = 0
		collision_mask = 0
		monitoring = false
		set_collision_layer_value(PhysicsLayers.PLAYER_ATTACK, true)
		set_collision_mask_value(PhysicsLayers.ENEMY_HURTBOX, true)
	
	func hitbox_enable():
		monitoring = true
		for hitbox in hitboxes:
			hitbox.disabled = true
	
	func hitbox_disable():
		monitoring = false
		for hitbox in hitboxes:
			hitbox.disabled = false


# these are the actual attacks
var A: Attack
var B: Attack
var C: Attack
var air: Attack


func _ready() -> void:
	A = Attack.new(
		[$attackA/hitbox1, $attackA/hitbox2],
		1, 0.3, 0.5, 0.04, Vector2(180, -40)
	)

	# Air attack is the same as A
	air = A
