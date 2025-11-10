extends CharacterBody3D

@export var hit_knockback_distance := 0.5   # qué tanto se mueve hacia atrás
@export var hit_duration := 0.15            # duración del retroceso
@export var hit_recovery := 0.1    
@export var max_life := 100
var life

var is_hit := false

func _ready() -> void:
	$SubViewport/TextureProgressBar.max_value = max_life
	$SubViewport/TextureProgressBar.value = max_life
	life = max_life

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta 
	move_and_slide()
	$Sprite3D.look_at(get_tree().get_first_node_in_group("Camera").global_position, Vector3.UP, true)
	


func hit(dir: Vector3):
	
	if is_hit:
		return # evita repetir si ya está siendo golpeado

	is_hit = true

	# Normaliza la dirección y calcula posición final del empuje
	var knockback_dir = dir.normalized()
	var start_pos = global_position
	var end_pos = start_pos + knockback_dir * hit_knockback_distance

	# Crea el tween
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# 1️⃣ Empuja al personaje
	tween.tween_property(self, "global_position", end_pos, hit_duration)

	# 2️⃣ Regresa al punto original suavemente
	tween.tween_property(self, "global_position", start_pos, hit_recovery)

	# 3️⃣ Marca cuando termina la animación
	tween.tween_callback(func():
		is_hit = false
	)
	
	life -= 10
	
	get_tree().create_tween().tween_property($SubViewport/TextureProgressBar, "value", life, 0.3)
	if $SubViewport/TextureProgressBar.value == 0:
		life = max_life
		get_tree().create_tween().tween_property($SubViewport/TextureProgressBar, "value", life, 0.5)

	# Opcional: reproducir animación o sonido de golpe
