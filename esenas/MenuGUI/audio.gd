extends VBoxContainer

@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider

const MIN_DB = -60.0
const MAX_DB = 0

func _ready():
	_sync_sliders()
	
	master_slider.value_changed.connect(func(value): AudioController.set_volume("Master", value))
	music_slider.value_changed.connect(func(value): AudioController.set_volume("Music", value))
	sfx_slider.value_changed.connect(func(value): AudioController.set_volume("SFX", value))

func _sync_sliders():
	master_slider.value = AudioController.get_volume("Master")
	music_slider.value = AudioController.get_volume("Music")
	sfx_slider.value = AudioController.get_volume("SFX")
