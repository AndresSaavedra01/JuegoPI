extends GridMap

func _ready():
	var mesh_lib = mesh_library
	
	for item_id in mesh_lib.get_item_list():
		var mesh = mesh_lib.get_item_mesh(item_id)
		
		if mesh != null:
			# Obtener transformación COMPLETA (posición + escala)
			var transform = mesh_lib.get_item_mesh_transform(item_id)
			var scale = transform.basis.get_scale()
			var position_offset = transform.origin
			
			# Crear colisión que matchea el tamaño visual Y la posición
			var collision_shape = create_exact_collision(mesh, scale, position_offset)
			mesh_lib.set_item_shapes(item_id, [collision_shape])
	
	mesh_library = mesh_lib

func create_exact_collision(mesh: Mesh, scale: Vector3, position_offset: Vector3) -> BoxShape3D:
	var aabb = mesh.get_aabb()
	
	# Aplicar exactamente la misma escala que el mesh visual
	var collision_size = aabb.size * scale
	
	var box_shape = BoxShape3D.new()
	box_shape.size = collision_size
	
	# DEBUG: Ver qué está pasando
	print("AABB original: ", aabb)
	print("Escala: ", scale)
	print("Offset posición: ", position_offset)
	print("Tamaño colisión: ", collision_size)
	
	return box_shape
