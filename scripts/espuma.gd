extends Area3D

@export var knockbackForce : float = 3
@export var knockbackUpForce : float = 5
@export var damage : float = 25

func _ready() -> void:
	$GPUParticles3D.emitting = true

func _on_timer_timeout() -> void:
	queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body.has_method("takeDamage"):
		var push_dir: Vector3 = (body.global_position - global_position).normalized()
		body.takeDamage(push_dir, damage, knockbackForce, knockbackUpForce)
		
