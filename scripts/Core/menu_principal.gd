extends Control

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button
@export var tween_intensity: float
@export var tween_duration: float

var music_menu: AudioStreamPlayer

func _ready():
	var animator = ButtonAnimator.new()
	add_child(animator)
	
	AudioController.play_music("res://audio/Menu.mp3")
	
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	for button in [play_button, settings_button, exit_button]:
		button.mouse_entered.connect(_on_button_hovered.bind(button, true))
		button.mouse_exited.connect(_on_button_hovered.bind(button, false))
	
	var buttons: Array = animator.get_all_buttons(self)
	await get_tree().process_frame
	buttons.sort_custom(animator.buttons_array_sorting)
	await animator.animate_buttons(buttons.duplicate(),true,0.16, Vector2(-20,0), Vector2.ZERO, 0.5)

func start_tween(object: Object, property: String, final_val: Variant, duration: float):
	var tween = create_tween()
	tween.tween_property(object, property, final_val, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_button_hovered(button: Button, hovered: bool):
	button.pivot_offset = button.size / 2
	if hovered:
		start_tween(button, "scale", Vector2.ONE * tween_intensity, tween_duration)
	else:
		start_tween(button, "scale", Vector2.ONE, tween_duration)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/WorldMap.tscn")
	
func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuOpciones.tscn")
	
func _on_exit_pressed():
	get_tree().quit()
