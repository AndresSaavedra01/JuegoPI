extends Control

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider
@export var salir_button: Button
@export var reanudar_button: Button
@export var reiniciar_button: Button


const MIN_DB = -60.0
const MAX_DB = 0

func _ready():
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	_sync_sliders()
	
	master_slider.value_changed.connect(func(value): AudioController.set_volume("Master", value))
	music_slider.value_changed.connect(func(value): AudioController.set_volume("Music", value))
	sfx_slider.value_changed.connect(func(value): AudioController.set_volume("SFX", value))
	
	salir_button.pressed.connect(_on_exit_pressed)
	reanudar_button.pressed.connect(_on_resume_pressed)
	reiniciar_button.pressed.connect(_on_restart_pressed)
	

func _sync_sliders():
	
	master_slider.value = AudioController.get_volume("Master")
	music_slider.value = AudioController.get_volume("Music")
	sfx_slider.value = AudioController.get_volume("SFX")
	

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://esenas/MenuGUI/WorldMap.tscn")

func _on_resume_pressed():
	get_tree().paused = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_restart_pressed():
	get_tree().paused = false
	var current_scene = get_tree().current_scene
	get_tree().reload_current_scene()
