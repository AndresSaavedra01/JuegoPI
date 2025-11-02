extends GridMap

func _ready():
	var mesh_lib = mesh_library  # Tu MeshLibrary actual
	
	# Aplicar colisión a TODOS los items
	for item_id in mesh_lib.get_item_list():
		var mesh = mesh_lib.get_item_mesh(item_id)
		
		if mesh != null:
			# Crear forma de colisión Trimesh
			var collision_shape = mesh.create_trimesh_shape()
			mesh_lib.set_item_shapes(item_id, [collision_shape])
	
	mesh_library = mesh_lib  
