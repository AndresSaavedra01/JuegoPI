extends Node3D

@export var proyectil: PackedScene

func ataquar(damage : float, knockbackForce : float, knockbackUpForce : float):
	var p : Proyectil = proyectil.instantiate()
	p.damage = damage
	p.knockbackForce = knockbackForce
	p.knockbackUpForce = knockbackUpForce
	get_tree().get_first_node_in_group("World").add_child(p)
	p.global_transform = global_transform
	p.apply_central_impulse(-global_transform.basis.z * -20)
	
