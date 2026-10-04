extends CharacterBody2D
class_name Enemy

@export var max_health: int = 2
@export var knockback_force: Vector2 = Vector2(120, -80)
@export var move_speed: float = 40.0
@export var patrol_distance: float = 80.0

var hitstun_time: float = 0.0
const HITSTUN_DURATION := 0.25

var returning_home := false
var start: Vector2
var time: float = 0.0
var direction: int = 1

var health: int
var is_dead: bool = false
var is_flying := false

@onready var sprite: AnimatedSprite2D = $enemy_animation
@onready var hurtbox: Area2D = $hurtbox
@onready var hurtbox_shape: CollisionShape2D = $hurtbox/shape

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	_update_facing()
	start = Vector2(global_position.x, global_position.y)
	health = max_health
	
	# Layer setup (universal)
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	hurtbox.set_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX, true)
	hurtbox.set_collision_mask_value(PhysicsLayers.PLAYER_ATTACK, true)   # only take damage from attacks
	hurtbox.set_collision_mask_value(PhysicsLayers.PLAYER_HURTBOX, true)  # detect player body (for contact damage later)
	
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
	
	if hitstun_time > 0.0:
		hitstun_time -= delta

	# Gravity
	if !is_flying:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
	
	# Friction after knockback
	if is_on_floor() and hitstun_time <= 0.0:
		velocity.x = move_toward(velocity.x, 0, 600 * delta)
	
	move_and_slide()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	
	# Only react to player attacks
	if area.get_collision_layer_value(PhysicsLayers.PLAYER_ATTACK):
		var dmg: int = area.get_meta("damage", 1)
		take_damage(dmg, area)

func take_damage(amount: int, attack_area: Area2D = null) -> void:
	if is_dead:
		return
	
	health -= amount
	print(name, " took ", amount, " damage. Health left: ", health)
	
	var knock_dir := 1
	if attack_area:
		knock_dir = sign(global_position.x - attack_area.global_position.x)
		if knock_dir == 0:
			knock_dir = 1
	
	velocity = Vector2(knockback_force.x * knock_dir, knockback_force.y)
	_flash()
	hitstun_time = HITSTUN_DURATION
	
	if health <= 0:
		die()
		return
	
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		await sprite.animation_finished
		if not is_dead and sprite.animation == "hit":
			# Let the child decide what to play after hit
			_on_hit_finished()

func _on_hit_finished() -> void:
	# Override this in children if you want different behaviour
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _flash() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3, 3, 3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)

func die() -> void:
	is_dead = true
	
	hurtbox_shape.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
	
	velocity.y = -150
	
	await get_tree().create_timer(0.45).timeout
	queue_free()

func patrol() -> void:
	if is_dead and hitstun_time > 0.0:
		return
	
	velocity.x = direction * move_speed
	
	# Turn around when we go too far from the starting point
	if abs(global_position.x - start.x) > patrol_distance and !returning_home:
		returning_home = true
		direction *= -1
		_update_facing()
		await get_tree().create_timer(0.5).timeout
		returning_home = false

func _update_facing() -> void:
	# Flip the whole sprite (and any child hitboxes that are under it)
	sprite.scale.x = direction
