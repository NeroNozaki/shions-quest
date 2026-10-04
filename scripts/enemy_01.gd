extends Enemy

@export var hover_amplitude: float = 40.0
@export var hover_speed: float = 2.0

func _ready() -> void:
	is_flying = true
	max_health = 2
	move_speed = 50.0
	patrol_distance = 100.0

	super._ready()

	home = global_position

func _physics_process(delta: float) -> void:
	if is_dead:
		super._physics_process(delta)
		return
	# up-and-down hover
	time += delta
	velocity.y = sin(time * hover_speed) * hover_amplitude
	super._physics_process(delta)

func _update_ai(delta:float):
	match state:
		AIState.PATROL:
			_patrol_logic()
		AIState.HURT:
			_hurt_logic()

func _patrol_logic():
	patrol()
	
	# animation
	if hitstun_time <= 0.0 and sprite.animation != "hit":
		if abs(velocity.x) > 5:
			sprite.play("fly")
		else:
			sprite.play("idle")

func _hurt_logic():
	state = AIState.PATROL
