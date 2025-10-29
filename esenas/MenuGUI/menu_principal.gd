extends Control

@export var play_button: Button
@export var settings_button: Button
@export var exit_button: Button


func _ready():
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://esenas/Level-1.tscn")
	
func _on_settings_button_pressed():
	get_tree().change_scene_to_file("res://esenas/MenuGUI/MenuOpciones.tscn")
	
func _on_exit_pressed():
	get_tree().quit()
