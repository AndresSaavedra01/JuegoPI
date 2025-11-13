extends Node

const MIN_DB = -60.0
const MAX_DB = 0.0

var volumes := {
	"Master": 100.0,
	"Music": 100.0,
	"SFX": 100.0
}

var music_player: AudioStreamPlayer

func _ready():
	# Crear y configurar el reproductor de música global
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	_load_volumes()

# 🎵 Reproducir música (ruta del archivo)
func play_music(path: String):
	if not music_player:
		return
	var new_stream = load(path)
	if new_stream == null:
		push_warning("No se encontró la música: %s" % path)
		return

	# Si ya se está reproduciendo la misma canción, no reiniciar
	if music_player.stream == new_stream and music_player.playing:
		return

	music_player.stream = new_stream
	music_player.play()

# ⏹️ Detener música
func stop_music():
	if music_player and music_player.playing:
		music_player.stop()

# ⚙️ Control de volúmenes (mismo código de antes)
func set_volume(bus_name: String, value: float):
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("El bus '%s' no existe en el AudioServer." % bus_name)
		return

	volumes[bus_name] = value
	var db = _slider_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)
	AudioServer.set_bus_mute(bus_index, db <= MIN_DB)
	_save_volumes()


func get_volume(bus_name: String) -> float:
	return volumes.get(bus_name, 100.0)

func _slider_to_db(value: float) -> float:
	if value <= 0.0:
		return MIN_DB
	var linear = value / 100.0
	return clamp(linear_to_db(linear), MIN_DB, MAX_DB)

func _db_to_slider(db: float) -> float:
	if db <= MIN_DB:
		return 0.0
	var linear = db_to_linear(db)
	return clamp(linear * 100.0, 0.0, 100.0)

func _save_volumes():
	var config = ConfigFile.new()
	for key in volumes.keys():
		config.set_value("audio", key, volumes[key])
	config.save("user://volumes.cfg")

func _load_volumes():
	var config = ConfigFile.new()
	var err = config.load("user://volumes.cfg")
	if err == OK:
		for key in volumes.keys():
			if config.has_section_key("audio", key):
				volumes[key] = config.get_value("audio", key)
				self.set_volume(key, volumes[key])
