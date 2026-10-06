extends Area2D

@export var victory_music: AudioStream
@export var main_menu_path: String = "res://scenes/start_menu.tscn"

@onready var audio: AudioStreamPlayer = $audio

var triggered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered:
		return
	if body.is_in_group("player"):
		triggered = true
		_start_end_sequence()

func _start_end_sequence() -> void:
	# 1. Stop gameplay
	get_tree().paused = true

	for player in get_tree().get_nodes_in_group("music"):
		if player is AudioStreamPlayer:
			player.stop()

	if victory_music:
		audio.stream = victory_music
		audio.play()
	else:
		audio.play()

	var transition = preload("res://scenes/iris_transition.tscn").instantiate()
	get_tree().root.add_child(transition)
	var player = get_tree().get_first_node_in_group("player")
	transition.play_close(player)

	# Wait until the circle is fully closed, then show the button
	await transition.closed
	_show_return_button()
	
func _show_return_button() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 128
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(ui)

	var btn := Button.new()
	btn.text = "Return to Main Menu"

	var custom_font: Font = load("res://assets/Fonts/font.ttf")
	btn.add_theme_font_override("font", custom_font)
	btn.add_theme_font_size_override("font_size", 24)

	btn.custom_minimum_size = Vector2(280, 60)

	btn.set_anchors_preset(Control.PRESET_CENTER)
	btn.offset_left   = -140
	btn.offset_right  =  140
	btn.offset_top    = -30
	btn.offset_bottom =  30

	ui.add_child(btn)

	btn.pressed.connect(_on_return_pressed.bind(ui))


func _on_return_pressed(ui: CanvasLayer) -> void:
	get_tree().paused = false
	ui.queue_free()
	# also free the iris transition if it’s still around
	for child in get_tree().root.get_children():
		if child.name.begins_with("Iris") or child is CanvasLayer and child != ui:
			if child.has_method("queue_free"):
				child.queue_free()

	get_tree().change_scene_to_file(main_menu_path)
