extends AnimatedSprite2D

@onready var player: Player = get_parent()

var current_anim: StringName = &""
var attack_start := false

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
		if attack_start == true and player.current_attack:
			match_attack_animation(desired_anim, player.current_attack.total_duration)
			attack_start = false

		play(desired_anim)



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
			attack_start = true
			if player.current_attack == player.attack_manager.B:
				return &"attackB"
			# elif player.current_attack == player.attack_manager.C:
			# 	return &"attackC"
			else:
				return &"attackA"
		player.State.ATTACK_AIR:
			attack_start = true
			return &"attackAir"
		_:
			return &"idle"


func start_windup(startup_time:float) -> void:
	if startup_time <= 0.0:
		return

	pause()
	frame = 0

	await get_tree().create_timer(startup_time).timeout

	# Only resume if we’re still supposed to be playing this attack
	if current_anim == &"attackB" and player.state == player.State.ATTACK_GROUND:
		play()

func match_attack_animation(anim_name: StringName, desired_total_duration: float) -> void:
	var frames = sprite_frames.get_frame_count(anim_name)
	var speed = frames / desired_total_duration
	sprite_frames.set_animation_speed(anim_name, speed)
