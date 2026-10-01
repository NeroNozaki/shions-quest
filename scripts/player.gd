extends CharacterBody2D

class_name Player

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

#TODO: CHANGE THIS SHIT
const SPEED = 200.0
const JUMP_VELOCITY = -400.0


@onready var attack_a := $attackA
@onready var attack_a_shape := [
	$attackA/attackA_hitbox1,
	$attackA/attackA_hitbox2,
]
enum STATE {
	attacking,
	idle,
	jumping,
}

var player_state := STATE.idle

var facing_direction := 1
var can_attack = true
var attack_duration = 0.3 # how long the attack_a stays active
var attack_cooldown = 0.5 # time before you can attack again

func _ready():
	attack_a.collision_layer = 0
	attack_a.collision_mask = 0
	attack_a.monitoring = false
	for shape in attack_a_shape:
		shape.disabled = true

	# set layer (what the attack "is")
	attack_a.set_collision_layer_value(PhysicsLayers.PLAYER_ATTACK, true)

	# set mask (what it can hit)
	attack_a.set_collision_mask_value(PhysicsLayers.ENEMY_HURTBOX, true)

func _physics_process(delta):
	# gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# left / right
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		facing_direction = direction
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	attack_a.is_inside_tree()
	if can_attack:
		$player_animation._trigger_animation(velocity, facing_direction)
	move_and_slide()
	#TODO: CHANGE THIS SHIT AS WELL ^

	if Input.is_action_just_pressed("attack") and can_attack:
		attack()


func attack():
	can_attack = false
	player_state = STATE.attacking
	attack_a.monitoring = true
	for shape in attack_a_shape:
		shape.disabled = false

	$player_animation._trigger_animation(velocity, facing_direction)
	
	# turn attack_a off after a short time
	await get_tree().create_timer(attack_duration).timeout
	attack_a.monitoring = false
	for shape in attack_a_shape:
		shape.disabled = true
	
	# cooldown
	await get_tree().create_timer(attack_cooldown - attack_duration).timeout
	can_attack = true
	player_state = STATE.idle
