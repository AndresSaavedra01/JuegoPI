extends RigidBody3D
class_name Proyectil

@export var vida: float = 3.0
@export var gravedad = 0
var knockbackForce : float
var knockbackUpForce : float
var damage : float

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
	if body.has_method("takeDamage"):
		var push_dir: Vector3 = linear_velocity.normalized()
		body.takeDamage(push_dir, damage, knockbackForce, knockbackUpForce)
		if is_instance_valid(self):
			queue_free()
