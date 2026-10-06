extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 180.0

func setup(dir: Vector2, spd: float) -> void:
	direction = dir
	speed = spd

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(PhysicsLayers.ENEMY_ATTACK, true)
	set_collision_mask_value(PhysicsLayers.GROUND, true)
	set_collision_mask_value(PhysicsLayers.PLAYER_HURTBOX, true)

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(_body: Node2D) -> void:
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	queue_free()
