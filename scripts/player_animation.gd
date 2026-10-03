extends AnimatedSprite2D

@onready var player: Player = get_parent()

var current_anim: StringName = &""

func _process(_delta: float) -> void:
	update_animation(player.facing_direction)

func update_animation(direction: int) -> void:
	if direction != 0:
		scale.x = direction
		player.attack_manager.scale.x = direction

	var desired_anim: StringName = get_desired_animation()

	# Only change animation when it actually needs to change
	if desired_anim != current_anim:
		current_anim = desired_anim
		play(desired_anim)

		# Special handling for windup attacks
		if desired_anim == &"attackB" and player.current_attack:
			start_windup(player.current_attack.startup)


func get_desired_animation() -> StringName:
	match player.state:
		player.State.IDLE:
			return &"idle"
		player.State.RUN:
			return &"run"
		player.State.FALL:
			return &"fall"
		player.State.LAND:
			return &"land"
		player.State.ATTACK_GROUND:
			if player.current_attack == player.attack_manager.B:
				match_attack_animation("attackB", player.attack_manager.B.cooldown)
				return &"attackB"
			# elif player.current_attack == player.attack_manager.C:
			# 	return &"attackC"
			else:
				match_attack_animation("attackA", player.attack_manager.A.cooldown)
				return &"attackA"
		player.State.ATTACK_AIR:
			return &"attackAir"
		_:
			return &"idle"


func start_windup(startup_time: float) -> void:
	if startup_time <= 0.0:
		return

	pause()
	frame = 0

	await get_tree().create_timer(startup_time).timeout

	# Only resume if we’re still supposed to be playing this attack
	if current_anim == &"attackB" and player.state == player.State.ATTACK_GROUND:
		play()

func match_attack_animation(anim_name: StringName, desired_cooldown: float) -> void:
	var frames = sprite_frames.get_frame_count(anim_name)
	var speed = frames / desired_cooldown
	sprite_frames.set_animation_speed(anim_name, speed)
