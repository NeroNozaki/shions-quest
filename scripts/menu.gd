extends Control

@onready var music = $audio
func _ready():
	music.play()
	
func _on_play_pressed() -> void:
	music.stop()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
	
func _on_exit_pressed() -> void:
	get_tree().quit()
