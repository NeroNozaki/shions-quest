extends Enemy

func _ready() -> void:
	super._ready()          # important! runs the base Enemy _ready
	move_speed = 40.0
	patrol_distance = 80.0
	direction = 1
	start = Vector2(global_position.x, global_position.y)

func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	patrol()

	if abs(velocity.x) > 5 and sprite.animation != "hit":
		if sprite.sprite_frames.has_animation("walk"):
			sprite.play("walk")
	elif sprite.animation != "hit":
		sprite.play("idle")

	super._physics_process(delta)   # applies gravity + move_and_slide
