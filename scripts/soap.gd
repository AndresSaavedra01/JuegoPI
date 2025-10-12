extends Proyectil

@export var explosion : PackedScene


func _on_area_3d_body_entered(body: Node3D) -> void:
	var explosion_in = explosion.instantiate()
	explosion_in.position = position
	get_tree().get_first_node_in_group("World").add_child(explosion_in)
	
	queue_free()
