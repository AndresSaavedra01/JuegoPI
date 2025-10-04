extends RigidBody3D
class_name Proyectil

@export var vida: float = 3.0
@export var velocidad: float = 20.0
@export var radio_collider: float = 0.1              # radio de la esfera
@export var gravedad = 0

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

func _physics_process(delta):
	pass
	#linear_velocity = transform.basis.z * velocidad

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	pass
