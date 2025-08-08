extends CharacterBody3D
@export var speed: float = 5.0
@export var jump: float = 5
@export var sensivilidad: float = 0.001
@onready var cam_Pivo = $CamaraPivote


func _physics_process(delta: float) -> void:
	movimiento(delta)
	move_and_slide()
	

func _process(delta: float) -> void:
	pass


func movimiento(delta: float):
	if not is_on_floor():
		velocity += get_gravity() * delta * 1.5
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = jump
	var input := Input.get_vector("izquierda","derecha","adelante","atras")
	print(input)
	var direccion := (transform.basis * Vector3(input.x,0,input.y)).normalized()
	if direccion:
		velocity.x = direccion.x * speed
		velocity.z = direccion.z * speed
	else :
		velocity.x = move_toward(velocity.x,0,speed)
		velocity.z = move_toward(velocity.z,0,speed)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cam_Pivo.rotate_z(deg_to_rad( -event.relative.x * sensivilidad))
		cam_Pivo.rotate_x(deg_to_rad( -event.relative.y * sensivilidad))
		
		
