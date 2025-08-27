extends RigidBody3D

@export var vida: float = 3.0
@export var velocidad: float = 20.0
@export var escala: Vector3 = Vector3(0.2, 0.2, 0.2)  # tamaño visual
@export var radio_collider: float = 0.1              # radio de la esfera

func _ready():
	# Escalar visual
	if $MeshInstance3D:
		$MeshInstance3D.scale = escala

	# Ajustar collider
	if $CollisionShape3D and $CollisionShape3D.shape is SphereShape3D:
		$CollisionShape3D.shape.radius = radio_collider

	# Capas y máscara
	collision_layer = 1 << 2        # proyectil en capa 2
	collision_mask  = (1 << 1) | (1 << 3)  # colisiona con mundo (1) y enemigos (3)

	# Activar colisiones
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	gravity_scale = 0

	# Autodestruir tras vida segundos
	await get_tree().create_timer(vida).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta):
	linear_velocity = transform.basis.z * velocidad

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	for i in range(state.get_contact_count()):
		var collider = state.get_contact_collider_object(i)
		if collider:
			print("💥 Impacto contra:", collider.name)
			queue_free()
