extends AnimatedSprite2D

@onready var player: Player = get_parent()

func update_animation(direction: int):
	# Flip sprite + attack hitbox
	if direction != 0:
		scale.x = direction
		player.attack_manager.scale.x = direction

	# Play animation based on current state
	match player.state:
		player.State.IDLE:
			play("idle")
		player.State.RUN:
			play("run")
		player.State.FALL:
			play("fall")
		player.State.LAND:
			play("land")
		player.State.ATTACK_GROUND:
			match_attack_animation("attackA", player.attack_manager.A.cooldown)
			play("attackA")
		player.State.ATTACK_AIR:
			match_attack_animation("attackAir", player.attack_manager.air.cooldown)
			play("attackAir")
	if player.is_on_floor() and player.velocity.y < 0:
		play("jump_start")


func match_attack_animation(anim_name: StringName, desired_cooldown: float) -> void:
	var frames = sprite_frames.get_frame_count(anim_name)
	var speed = frames / desired_cooldown
	sprite_frames.set_animation_speed(anim_name, speed)

