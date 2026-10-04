extends Enemy

@export var hover_amplitude: float = 40.0
@export var hover_speed: float = 2.0

func _ready() -> void:
	is_flying = true
	super._ready()
	move_speed = 50.0
	patrol_distance = 100.0
	start = Vector2(global_position.x, global_position.y)

func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return

	time += delta
	patrol()

	# Simple up-and-down hover
	velocity.y = sin(time * hover_speed) * hover_amplitude

	# Play the fly animation
	if sprite.animation != "hit":
		if sprite.sprite_frames.has_animation("fly"):
			sprite.play("fly")
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

	super._physics_process(delta)
