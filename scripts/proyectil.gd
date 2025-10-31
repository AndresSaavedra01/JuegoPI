extends RigidBody3D
class_name Proyectil

@export var vida: float = 3.0
@export var velocidad: float = 20.0
@export var radio_collider: float = 0.1             
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
	if body is CharacterBody3D:
		var dir = body.global_position - global_position
		dir.y = 0
		dir = dir.normalized()
		print(dir)
		if body.has_method("hit"):
			body.hit(dir)
			queue_free()
