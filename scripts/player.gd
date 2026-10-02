extends CharacterBody2D
class_name Player

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#TODO: CHANGE THIS SHIT
const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const BUFFER_WINDOW := 0.1

var jump_buffer := 0.0
var attack_buffer := 0.0

@onready var attack_manager: AttackManager = $Attack

var current_attack: AttackManager.Attack

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	LAND,
	ATTACK_GROUND,
	ATTACK_AIR,
	# HURT,
	# DEAD,
}

var jump_start_duration := 0.03

var state: State = State.IDLE
var previous_state: State
var facing_direction := 1
var attack_duration := 0.3
var attack_cooldown := 0.5

var can_attack := true
var was_on_floor := true

func _ready():
	$player_animation.play("idle")

	previous_state = state

func _physics_process(delta):
	# input buffer. add other actions later
	if Input.is_action_just_pressed("jump"):
		jump_buffer = BUFFER_WINDOW
	if Input.is_action_just_pressed("attack"):
		current_attack = attack_manager.A
		attack_buffer = BUFFER_WINDOW
		
	attack_buffer = max(0.0, attack_buffer - delta)
	jump_buffer = max(0.0, jump_buffer - delta)

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		facing_direction = int(direction)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	try_buffered_action()
	update_state()

	# Animation
	$player_animation.update_animation(facing_direction)

	was_on_floor = is_on_floor()
	move_and_slide()
	print_state_change()

func update_state():
	# Don't override locked states
	if state in [State.ATTACK_GROUND, State.ATTACK_AIR, State.JUMP]:
		return

	if is_on_floor():
		if not was_on_floor:
			state = State.LAND
		elif abs(velocity.x) > 10:
			state = State.RUN
		else:
			state = State.IDLE
	else:
		state = State.FALL

func try_buffered_action():
	# if buffer is >0, and can start action, start action.
	if jump_buffer > 0.0 and can_start_jump():
		jump_buffer = 0.0
		start_jump()
	if attack_buffer > 0.0 and can_start_attack():
		attack_buffer = 0.0
		start_attack()
	
func can_start_attack() -> bool:
	return state not in [State.ATTACK_GROUND, State.ATTACK_AIR, State.JUMP]

func can_start_jump() -> bool:
	return is_on_floor() and state not in [State.ATTACK_GROUND, State.ATTACK_AIR, State.JUMP]

func start_attack():
	can_attack = false
	current_attack.ready();

	if is_on_floor():
		state = State.ATTACK_GROUND
	else:
		state = State.ATTACK_AIR

	# Enable hitbox
	if state == State.ATTACK_AIR:
		current_attack.position.y = -4
	current_attack.hitbox_enable()

	# Disable hitbox after duration
	await get_tree().create_timer(attack_duration).timeout
	current_attack.hitbox_disable()

	# Cooldown
	await get_tree().create_timer(attack_cooldown - attack_duration).timeout
	can_attack = true
	current_attack.position.y = 0

	# Return to a normal state after attack finishes
	if is_on_floor():
		state = State.IDLE if abs(velocity.x) < 10 else State.RUN
	else:
		state = State.FALL if velocity.y > 0 else State.JUMP


func start_jump():
	state = State.JUMP
	await get_tree().create_timer(jump_start_duration).timeout

	if state == State.JUMP:
		velocity.y = JUMP_VELOCITY
		state = State.FALL
	

func print_state_change():
	if state != previous_state:
		print("State: ", State.keys()[state])
		previous_state = state
