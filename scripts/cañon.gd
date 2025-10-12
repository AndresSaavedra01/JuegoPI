extends Node3D

@export var proyectil: PackedScene

func ataquar():
	var p = proyectil.instantiate()
	get_tree().get_first_node_in_group("World").add_child(p)
	p.global_transform = global_transform
	p.apply_central_impulse(-global_transform.basis.z * -20)
	
