@tool
extends CharacterBody2D
class_name Enemy

enum AIState { PATROL, CHASE, ATTACK, HURT }
var state := AIState.PATROL
var previous_state = state

@export var max_health: int = 3
@export var knockback_force: Vector2 = Vector2(120, -80)
@export var move_speed: float = 40.0
@export var patrol_distance: float = 80.0

@export var start_facing_right := false:
	set(value):
		start_facing_right = value
		direction = 1 if value else -1
		_update_facing()


@export var detection_range: float = 160.0
@export var attack_range: float = 28.0
@export var attack_cooldown: float = 1.2

var attack_timer: float = 0.0
var player: Player = null

var hitstun_time: float = 0.0
const HITSTUN_DURATION := 0.25

var returning_home := false
var home: Vector2
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
	direction = 1 if start_facing_right else -1
	_update_facing()

	home = global_position
	health = max_health
	player = get_tree().get_first_node_in_group("player") as Player
	previous_state = state
	
	# Layer setup (universal)
	hurtbox.collision_layer = 0
	hurtbox.collision_mask = 0
	hurtbox.set_collision_layer_value(PhysicsLayers.ENEMY_HURTBOX, true)
	hurtbox.set_collision_mask_value(PhysicsLayers.PLAYER_ATTACK, true)   # only take damage from attacks
	hurtbox.set_collision_mask_value(PhysicsLayers.PLAYER_HURTBOX, true)  # detect player body (for contact damage later)
	
	# connecting signals (if any)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	if sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")
	else:
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	if is_dead:
		velocity.y += gravity * delta
		move_and_slide()
		return
	
	# skip AI behavior while in hitstun
	if hitstun_time > 0.0:
		hitstun_time -= delta
		_apply_physics(delta)
		return

	attack_timer = max(0.0, attack_timer - delta)
	
	# children implement their AI here
	_update_ai(delta)

	_apply_physics(delta)
	print_state_change()


func _apply_physics(delta:float):
	# Gravity
	if not is_flying:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0

	# Friction only when not being forced by AI
	if is_on_floor() and state == AIState.PATROL:
		velocity.x = move_toward(velocity.x, 0, 600 * delta)

	move_and_slide()

func _update_ai(delta:float):
	# this method is meant to be overriden by children
	pass

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	
	# Only react to player attacks
	if area.get_collision_layer_value(PhysicsLayers.PLAYER_ATTACK):
		var dmg: int = area.get_meta("damage", 1)
		take_damage(dmg, area)

func take_damage(amount: int, attack_area: Area2D = null) -> void:
	if is_dead or state == AIState.HURT:
		return
	
	attack_timer = 0.0
	health -= amount
	print(name, " took ", amount, " damage. Health left: ", health)
	
	var knock_dir := 1
	if attack_area:
		knock_dir = sign(global_position.x - attack_area.global_position.x)
		if knock_dir == 0:
			knock_dir = 1
	
	velocity = Vector2(knockback_force.x * knock_dir, knockback_force.y)
	hitstun_time = HITSTUN_DURATION
	_flash()

	state = AIState.HURT
	
	if health <= 0:
		die()
		return
	
	if sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		await get_tree().create_timer(HITSTUN_DURATION).timeout
		if not is_dead:
			# Let the child decide what to play after hit
			_on_hit_finished()

func _on_hit_finished() -> void:
	# Override this in children to get different behavior
	if is_flying and sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")
	else:
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
	if is_dead or hitstun_time > 0.0:
		return
	
	velocity.x = direction * move_speed
	
	# Turn around when we go too far from the starting point
	if abs(global_position.x - home.x) > patrol_distance and !returning_home:
		returning_home = true
		direction *= -1
		_update_facing()
		await get_tree().create_timer(0.5).timeout
		returning_home = false

func _update_facing() -> void:
	# Flip the whole sprite (and any child hitboxes that are under it)
	var s = get_node_or_null("enemy_animation") as AnimatedSprite2D
	if s == null: return
	s.flip_h = direction < 0
	notify_property_list_changed()

func print_state_change():
	if state != previous_state:
		print(name, ": ", AIState.keys()[state])
		previous_state = state
