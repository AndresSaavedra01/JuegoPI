extends Proyectil

var scale_water := 1.0



func _physics_process(delta: float) -> void:
	var vector_scale = Vector3(scale_water,scale_water,scale_water)
	$CollisionShape3D.scale = vector_scale
	$MeshInstance3D.scale = vector_scale

func _ready():
	# Activar colisiones
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	gravity_scale = gravedad

	# Autodestruir tras vida segundos
	await get_tree().create_timer(vida).timeout
	if is_instance_valid(self):
		queue_free()



func _on_body_entered(body) -> void:
	var tween = get_tree().create_tween()
	pass
	tween.tween_property(self, "scale_water", 0.3, 1)
	
	if body is CharacterBody3D:
		var dir = body.global_position - global_position
		dir.y = 0
		dir = dir.normalized()
		print(dir)
		if body.has_method("hit"):
			body.hit(dir)
			queue_free()
	
	if body is CharacterBody3D and body is not player:
		var push_dir: Vector3 = linear_velocity.normalized()
		body.takeDamage(Vector3.ZERO, 1, knockbackForce, knockbackUpForce)
		if is_instance_valid(self):
			queue_free()
