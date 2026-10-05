@tool
extends Enemy

func _ready() -> void:
	max_health = 3
	move_speed = 40.0
	patrol_distance = 80.0
	direction = 1

	super._ready()

	home = global_position


func _update_ai(delta:float):
	match state:
		AIState.PATROL:
			_patrol_logic()
		AIState.CHASE:
			_chase_logic()
		AIState.ATTACK:
			_attack_logic()
		AIState.HURT:
			_hurt_logic()

func _can_see_player() -> bool:
	if player == null or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= detection_range

func _patrol_logic():
	sprite.speed_scale = 1.0
	patrol()
	
	# animation
	if hitstun_time <= 0.0 and sprite.animation != "hit":
		if abs(velocity.x) > 5 and sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
		else:
			sprite.play("idle")

	# check for player
	if _can_see_player():
		state = AIState.CHASE

func _chase_logic():
	if not _can_see_player():
		home = global_position
		state = AIState.PATROL
		return
	
	var dist_to_player = player.global_position.x - global_position.x

	# turn towards player
	var dir_to_player = sign(dist_to_player)
	if dir_to_player != 0:
		direction = dir_to_player
		_update_facing()

	# faster when chasing
	velocity.x = direction * move_speed * 1.4

	# animation
	if hitstun_time <= 0.0 and sprite.animation != "hit":
		sprite.speed_scale = 1.4
		sprite.play("walk")

	# close enough to player?
	if abs(dist_to_player) <= attack_range and attack_timer <= 0.0:
		_start_attack()
	
func _attack_logic():
	# don't move during attack
	velocity.x = 0

	# actual attack is handled in _start_attack()

func _start_attack():
	attack_timer = attack_cooldown
	state = AIState.ATTACK
	sprite.play("attack")

	# this allows the attack to be interrupted
	while state == AIState.ATTACK and not is_dead:
		if not is_inside_tree():
			return
		if not sprite.is_playing():
			break
		await get_tree().process_frame

	#TODO: enable enemy attack hitboxes here

	if is_dead or not is_inside_tree(): return

	# after attack, decide what to do
	state = AIState.CHASE if _can_see_player() else AIState.PATROL

func _hurt_logic():
	if _can_see_player():
		state = AIState.CHASE
	else:
		home = global_position
		state = AIState.PATROL
