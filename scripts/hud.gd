extends CanvasLayer

@onready var score_label: Label = $score 

var score := 0

func _ready() -> void:
	# Format with 5 digits right from the start
	_update_score_display()
	
	# Connect to every enemy that already exists in the level
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("enemy_death"):
			enemy.enemy_death.connect(_on_enemy_death)
	
	# Also catch enemies that are spawned later
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("enemies") and node.has_signal("enemy_death"):
		node.enemy_death.connect(_on_enemy_death)


func _on_enemy_death() -> void:
	score += 100
	_update_score_display()


func _update_score_display() -> void:
	# Always show exactly 5 digits (00000, 00100, 01200, etc.)
	score_label.text = "%05d" % score
