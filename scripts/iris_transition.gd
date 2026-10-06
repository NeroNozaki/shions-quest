extends CanvasLayer

signal closed

@onready var color_rect: ColorRect = $ColorRect
var mat: ShaderMaterial

func _ready() -> void:
	mat = color_rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	visible = false

func play_close(player: Player, duration: float = 1.8) -> void:
	visible = true

	# fallback
	var center_uv := Vector2(0.5, 0.5)

	if player:
		var viewport := get_viewport()
		var screen_pos: Vector2 = viewport.get_canvas_transform() * player.global_position
		screen_pos.y -= 23
		var viewport_size: Vector2 = viewport.get_visible_rect().size
		center_uv = screen_pos / viewport_size

	mat.set_shader_parameter("center", center_uv)

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_method(_set_progress, 0.0, 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	closed.emit()

func _set_progress(value: float) -> void:
	mat.set_shader_parameter("progress", value)
	
	
