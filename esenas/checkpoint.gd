extends Area3D

@export var checkpoint_position := Vector3.ZERO
@onready var flag_mesh = $CollisionShape3D/Flag

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		print("Checkpoint activado")
		body.respawn = global_transform.origin
		var material = flag_mesh.get_active_material(0)
		if material:
			material.albedo_color = Color(0, 1, 0)  # Cambia el color a rojo
