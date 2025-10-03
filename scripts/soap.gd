extends Proyectil



func _on_ray_cast_3d_body_entered(body: Node3D) -> void:
	$CollisionShape3D.disabled = true
	$Node3D.visible = true
	await $Timer.timeout 
	queue_free()
