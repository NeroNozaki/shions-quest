extends Node2D
class_name AttackManager

class Attack:
	var area: Area2D
	var hitboxes: Array = []
	var active: float
	var recovery: float
	var startup: float
	var total_duration: float
	var damage: int
	var knockback: Vector2

	func _init(
		p_area: Area2D,
		p_damage: int = 1,
		p_active: float = 0.22,
		p_recovery: float = 0.35,
		p_startup: float = 0.04,
		p_knockback: Vector2 = Vector2(180, -40)
	) -> void:

		self.area           = p_area
		self.damage         = p_damage
		self.active         = p_active
		self.recovery       = p_recovery
		self.startup        = p_startup
		self.knockback      = p_knockback
		self.total_duration = p_startup+p_active+p_recovery

		for child in area.get_children():
			if child is CollisionShape2D:
				child.disabled = true
				hitboxes.append(child)

	func ready():
		area.collision_layer = 0
		area.collision_mask = 0
		area.monitoring = false
		area.set_collision_layer_value(PhysicsLayers.PLAYER_ATTACK, true)
		area.set_collision_mask_value(PhysicsLayers.ENEMY_HURTBOX, true)
	
	func hitbox_enable():
		area.monitoring = true
		for hitbox in hitboxes:
			hitbox.disabled = false
	
	func hitbox_disable():
		area.monitoring = false
		for hitbox in hitboxes:
			hitbox.disabled = true
	




# these are the actual attacks
var A: Attack
var B: Attack
var C: Attack
var air: Attack


func _ready() -> void:
	A = Attack.new($attackA,
		1, 0.2, 0.4, 0.0, Vector2(180, -40)
	)

	B = Attack.new($attackB,
		1, 0.5, 0.6, 0.3, Vector2(180, -40)
	)

	# Air attack is the same as A
	air = A
