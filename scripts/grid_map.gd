extends GridMap

func _ready():
	# ELIMINAR colisiones de MeshLibrary
	var mesh_lib = mesh_library
	for item_id in mesh_lib.get_item_list():
		mesh_lib.set_item_shapes(item_id, [])
	mesh_library = mesh_lib
	
	# Crear colisiones MANUALES por cada celda
	for cell in get_used_cells():
		create_simple_collision(cell)

func create_simple_collision(cell: Vector3i):
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	
	# Usar el tamaño de celda (siempre funciona)
	box_shape.size = cell_size * 0.9  # Ligeramente más pequeño
	
	collision_shape.shape = box_shape
	static_body.add_child(collision_shape)
	add_child(static_body)
	static_body.position = map_to_local(cell)
