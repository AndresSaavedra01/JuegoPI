extends Node3D

@onready var menu_pausa = $MenuPausa

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):  # Escape
		_toggle_pause()

func _toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		menu_pausa.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		get_tree().paused = true
		menu_pausa.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
