extends Node3D

@export var proyectil: PackedScene
@export var ray: RayCast3D
@export var speed := 10.0
var apuntando := false

func ataquar(damage : float, knockbackForce : float, knockbackUpForce : float):
	var p : Proyectil = proyectil.instantiate()
	p.damage = damage
	p.knockbackForce = knockbackForce
	p.knockbackUpForce = knockbackUpForce
	get_tree().get_first_node_in_group("World").add_child(p)
	var spawn_pos = global_transform.origin
	p.global_transform.origin = spawn_pos
	var camera = get_tree().get_first_node_in_group("Camera")
	var center = get_viewport().get_visible_rect().size / 2
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * 1000
	var direction: Vector3

	if apuntando:
		if ray.is_colliding():
			var hit_point = ray.get_collision_point()
			direction = (hit_point - spawn_pos).normalized()
		else:
			direction = (to - from).normalized()
	else:
		direction = global_transform.basis.z
	p.look_at(p.global_transform.origin + direction, Vector3.UP)
	p.apply_central_impulse(direction * speed)


func _on_camara_pivot_apuntado(apun) -> void:
	apuntando = apun
