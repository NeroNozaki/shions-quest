@tool
extends Enemy

var is_attacking: bool = false
@export var hover_amplitude: float = 40.0
@export var hover_speed: float = 2.0
@export var projectile_scene: PackedScene
@export var orbit_distance: float = 100.0   # how close it gets before switching to orbit/shoot
var projectile_spawn_percent: float = 0.80   # 0.8 = 80%, 0.9 = 90%, etc.

var locked_aim_dir: Vector2 = Vector2.RIGHT
var locked_rotation: float = 0.0
var orbiting := false


func _ready() -> void:
	state = AIState.PATROL
	projectile_scene = load("res://scenes/enemies/bat_projectile.tscn")
	is_flying = true
	max_health = 2
	move_speed = 50.0
	patrol_distance = 100.0
	detection_range = 220.0
	attack_range = orbit_distance * 1.2
	attack_cooldown = 3.0

	super._ready()
	home = global_position

func hover(delta:float):
	time += delta
	velocity.y = sin(time * hover_speed) * hover_amplitude

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if is_dead:
		super._physics_process(delta)
		return

	# continuous hover (Y only)
	hover(delta)

	super._physics_process(delta)

func _update_ai(delta: float) -> void:

	match state:
		AIState.PATROL:
			_patrol_logic()
		AIState.CHASE:
			_chase_logic()
		AIState.ORBIT:
			_orbit_logic(delta)
		AIState.ATTACK:
			_attack_logic()
		AIState.HURT:
			_hurt_logic()

func _can_see_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= detection_range

func _patrol_logic() -> void:
	if _can_see_player():
		state = AIState.ORBIT
	else:
		patrol()   # base left/right movement around home

func _orbit_logic(delta:float) -> void:
	if player == null:
		return

	# Desired horizontal distance (a bit less than the distance that triggers orbit)
	var desired_dist: float = orbit_distance

	hover(delta)

	var to_player = player.global_position - global_position
	if global_position.distance_to(player.global_position) <= attack_range: state = AIState.ATTACK
	var horizontal_dist = abs(to_player.x)

	# Decide whether we need to get closer or farther
	var move_dir: float = 0.0

	if horizontal_dist > desired_dist + 10.0:
		# Too far → move toward the player
		move_dir = sign(to_player.x)
	elif horizontal_dist < desired_dist - 10.0:
		# Too close → move away from the player
		move_dir = -sign(to_player.x)
	else:
		# Roughly good distance → small random drift so it doesn't look robotic
		move_dir = direction   # keep whatever direction it already had

	# Move 40% faster than normal
	velocity.x = move_dir * move_speed * 1.4

	# Always face the player (not the movement direction)
	direction = 1 if to_player.x >= 0 else -1
	_update_facing()

	# animation
	if hitstun_time <= 0.0 and sprite.animation != "hit":
		if abs(velocity.x) > 5 and sprite.sprite_frames.has_animation("fly"):
			sprite.play("fly")
		else:
			sprite.play("idle")

	# spotted the player?
	if not _can_see_player():
		state = AIState.PATROL

func _chase_logic() -> void:
	if not _can_see_player():
		# lost the player → go back to patrol from current position
		home = global_position
		state = AIState.PATROL
		return

	# fly straight toward the player
	var dir = (player.global_position - global_position).normalized()
	velocity.x = dir.x * move_speed * 1.3
	# (Y is already handled by the hover)

	# face the movement direction with the old flip system
	direction = 1 if dir.x >= 0 else -1
	_update_facing()

	# animation
	if hitstun_time <= 0.0 and sprite.animation != "hit":
		if sprite.sprite_frames.has_animation("fly"):
			sprite.play("fly")

	# close enough → lock a new home and start orbiting + shooting
	if global_position.distance_to(player.global_position) <= attack_range:
		home = global_position
		state = AIState.ATTACK

func _attack_logic() -> void:
	# Lock completely only while the attack animation is playing
	if is_attacking or sprite.animation == "attack":
		velocity = Vector2.ZERO
	else:
		state = AIState.ORBIT

	# Animation while waiting between shots
	if hitstun_time <= 0.0 and not is_attacking and sprite.animation != "hit":
		if sprite.sprite_frames.has_animation("fly"):
			sprite.play("fly")

	# Lost the player?
	if not _can_see_player():
		_reset_rotation()
		home = global_position
		state = AIState.PATROL
		return

	# Attack when cooldown is ready
	if attack_timer <= 0.0 and not is_attacking and sprite.animation != "attack":
		_start_ranged_attack()


func _start_ranged_attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	state = AIState.ATTACK

	# 1. Lock the REAL direction to the player FIRST
	locked_aim_dir = (player.global_position - global_position).normalized()
	locked_rotation = locked_aim_dir.angle()

	# 2. Now visually aim (this can change rotation / flip for looks)
	_aim_at_player_upright()

	# 3. Play attack animation
	if not sprite.sprite_frames.has_animation("attack"):
		_spawn_projectile()
		_finish_attack()
		return

	sprite.play("attack")

	# 4. Wait until the desired % of the animation
	var anim_length = sprite.sprite_frames.get_frame_count("attack") / float(sprite.sprite_frames.get_animation_speed("attack"))
	var spawn_delay = anim_length * projectile_spawn_percent

	await get_tree().create_timer(spawn_delay).timeout

	# Abort if interrupted
	if is_dead or not is_inside_tree() or not is_attacking or sprite.animation != "attack":
		_finish_attack()
		return

	# 5. Spawn using the LOCKED values
	_spawn_projectile()

	# 6. Wait for the rest of the animation
	if sprite.is_playing() and sprite.animation == "attack":
		await sprite.animation_finished

	_finish_attack()

func _finish_attack() -> void:
	is_attacking = false
	_reset_rotation()

	if is_dead or not is_inside_tree():
		return

	if _can_see_player():
		state = AIState.ATTACK
	else:
		home = global_position
		state = AIState.PATROL

	if sprite.sprite_frames.has_animation("fly"):
		sprite.play("fly")


func _aim_at_player_upright() -> void:
	if player == null:
		return

	var aim_dir = (player.global_position - global_position).normalized()
	var angle = aim_dir.angle()

	# Keep right-side up
	if abs(angle) > PI * 0.5:
		sprite.flip_h = true
		rotation = angle - PI * sign(angle)
	else:
		sprite.flip_h = false
		rotation = angle

	sprite.scale.x = 1


func _reset_rotation() -> void:
	rotation = 0.0
	sprite.flip_h = direction < 0
	sprite.scale.x = 1

func _spawn_projectile() -> void:
	if projectile_scene == null:
		return

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position

	# Use the direction we locked when the enemy first snapped
	proj.rotation = locked_rotation

	if proj.has_method("setup"):
		proj.setup(locked_aim_dir, 180.0)
	else:
		proj.direction = locked_aim_dir

func _hurt_logic() -> void:
	# Reset angle as soon as we enter hurt
	is_attacking = false
	_reset_rotation()

	if _can_see_player():
		if global_position.distance_to(player.global_position) <= attack_range:
			home = global_position
			state = AIState.ATTACK
		else:
			state = AIState.CHASE
	else:
		home = global_position
		state = AIState.PATROL
