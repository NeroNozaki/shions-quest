extends CharacterBody2D
class_name Player

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var attack_manager: AttackManager = $Attack

var current_attack: AttackManager.Attack

enum State {
	IDLE,
	RUN,
	FALL,
	LAND,
	ATTACK_GROUND,
	ATTACK_AIR,
	# HURT,
	# DEAD,
}

const SPEED = 190.0
const JUMP_VELOCITY = -450.0
const JUMP_CUT_MULTIPLIER := 0.25   # this controls how fast the player decelerates when cutting the jump
const MIN_JUMP_TIME := 0.09         # minimum time the button must be held
const BUFFER_WINDOW := 0.1

var jump_held_time := 0.0
var is_jumping := false

var jump_buffer := 0.0
var attack_buffer := 0.0

var jump_start_duration := 0.03

var state: State = State.IDLE
var previous_state: State
var facing_direction := 1

var attack_id := 0;
var active_attack_id := 0;
var can_attack := true
var can_move := true
var was_on_floor := true

func _ready():
	$player_animation.play("idle")

	previous_state = state

func _physics_process(delta):
	# input buffer. add other actions later
	if Input.is_action_just_pressed("jump"):
		jump_buffer = BUFFER_WINDOW
	if Input.is_action_just_pressed("attack"):
		attack_buffer = BUFFER_WINDOW
		
	attack_buffer = max(0.0, attack_buffer - delta)
	jump_buffer = max(0.0, jump_buffer - delta)

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Horizontal movement
	var direction = Input.get_axis("left", "right")
	if can_move:
		if direction != 0:
			velocity.x = direction * SPEED
			if state not in [State.ATTACK_GROUND, State.ATTACK_AIR]:
				facing_direction = int(direction)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Variable jump height
	if is_jumping:
		jump_held_time += delta
	
		if velocity.y < 0:
			if not Input.is_action_pressed("jump") and jump_held_time >= MIN_JUMP_TIME:
				velocity.y *= JUMP_CUT_MULTIPLIER
				is_jumping = false
		else:
			is_jumping = false

	
	# Cancel air attack on the moment of landing
	if state == State.ATTACK_AIR and is_on_floor():
		cancel_attack()

	try_buffered_action()
	update_state()

	was_on_floor = is_on_floor()

	move_and_slide()
	print_state_change()


func update_state():
	# Don't override locked states
	if state in [State.ATTACK_GROUND, State.ATTACK_AIR]:
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
	return state not in [State.ATTACK_GROUND, State.ATTACK_AIR]

func can_start_jump() -> bool:
	return is_on_floor() and state not in [State.ATTACK_GROUND, State.ATTACK_AIR]

func start_attack():
	attack_id+=1
	var this_attack_id = attack_id
	active_attack_id = this_attack_id

	can_attack = false
	if is_on_floor():
		state = State.ATTACK_GROUND
		if Input.is_action_pressed("down"):
			current_attack = attack_manager.B
			can_move = false
		else:
			current_attack = attack_manager.A
	else:
		state = State.ATTACK_AIR
		current_attack = attack_manager.air
		current_attack.area.position.y = -4

	if current_attack.has_windup:
		$player_animation.start_windup(current_attack.startup)

	# wait for startup
	if current_attack.startup > 0.0:
		await get_tree().create_timer(current_attack.startup).timeout
		if this_attack_id != active_attack_id:
			return

	# Enable hitbox
	if (current_attack != null):
		current_attack.hitbox_enable()

	var active := current_attack.active
	var recovery := current_attack.recovery

	# keep hitbox on for duration of attack
	await get_tree().create_timer(active).timeout
	
	# if canceled while waiting, just exit
	if state != State.ATTACK_GROUND and state != State.ATTACK_AIR:
		return

	# if another attack is triggered, exit
	if this_attack_id != active_attack_id:
		return

	current_attack.hitbox_disable()

	# Cecovery
	await get_tree().create_timer(recovery - active).timeout
	
	# if another attack is triggered, exit
	if this_attack_id != active_attack_id:
		return

	can_attack = true
	current_attack.area.position.y = 0
	if current_attack == attack_manager.B: can_move = true
	current_attack = null

	# Return to a normal state after attack finishes
	if is_on_floor():
		state = State.IDLE if abs(velocity.x) < 10 else State.RUN
	else:
		state = State.FALL

func cancel_attack() -> void:
	if is_on_floor():
		state = State.LAND
	else:
		state = State.FALL

	active_attack_id = -1
	current_attack.hitbox_disable()
	current_attack = null
	can_attack = true


func start_jump():
	velocity.y = JUMP_VELOCITY
	is_jumping = true
	jump_held_time = 0.0
	state = State.FALL
	

func print_state_change():
	if state != previous_state:
		print("State: ", State.keys()[state])
		previous_state = state
		if state in [State.ATTACK_GROUND, State.ATTACK_AIR]:
			print("	Attack: ", current_attack.area.name)
