extends CharacterBody3D
@export var speed: float = 5.0
@export var jump: float = 5

func _physics_process(delta: float) -> void:
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
		
	move_and_slide()

func _process(delta: float) -> void:
	pass
