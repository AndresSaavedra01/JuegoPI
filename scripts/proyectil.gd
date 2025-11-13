extends RigidBody3D
class_name Proyectil

@export var vida: float = 3.0
@export var gravedad = 0
@export var knockbackForce : float = 0
@export var knockbackUpForce : float = 0
var damage : float = 25.0

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

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body is not player and body.has_method("takeDamage"):
		var push_dir: Vector3 = linear_velocity.normalized()
		body.takeDamage(Vector3.ZERO, damage, knockbackForce, knockbackUpForce)
		if is_instance_valid(self):
			queue_free()
