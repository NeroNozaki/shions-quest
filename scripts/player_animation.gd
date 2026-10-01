extends AnimatedSprite2D


@onready var player: Player = get_parent()

func _trigger_animation(velocity:Vector2, direction:int):
	if direction != 0:
		player.attack_a.scale.x = direction
		scale.x = direction
	if player.player_state == player.STATE.attacking:
		play("attackA")
	else:
		play("idle")
	
	
