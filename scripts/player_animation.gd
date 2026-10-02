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
		player.State.JUMP:
			play("jump_start")
		player.State.FALL:
			play("fall")
		player.State.LAND:
			play("land")
		player.State.ATTACK_GROUND:
			play("attackA")
		player.State.ATTACK_AIR:
			play("attackAir")
