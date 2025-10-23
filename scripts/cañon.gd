extends Node3D

@export var proyectil: PackedScene

func ataquar():
	var p = proyectil.instantiate()
	get_tree().get_first_node_in_group("World").add_child(p)
	
	# Punto de salida del proyectil (puedes cambiarlo por un Marker3D en el arma)
	var spawn_pos = global_transform.origin
	
	# Obtener la mira (que puede estar al centro de la cámara)
	var mira = get_tree().get_first_node_in_group("Mira")
	
	# Dirección hacia donde apunta la mira (desde el punto de salida)
	var camera = get_tree().get_first_node_in_group("Camera")  # tu cámara actual
	var center = get_viewport().get_visible_rect().size / 2
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * 1000
	var dire = (to - spawn_pos).normalized()
	
	# Posicionar el proyectil en el punto de salida
	p.global_transform.origin = spawn_pos
	p.look_at(mira.global_transform.origin, Vector3.UP)
	
	# Aplicar impulso en dirección de la mira
	p.apply_central_impulse(dire * 20)  # Ajusta el multiplicador de fuerza según lo que necesites
