extends CharacterBody3D

#variables
@export var speed := 8.0
@export var rotacion_velo := 20.0
@export var jump := 10.0
@export var gravity := 15.0
@export var sens_h := 0.5
@export var sens_v := 0.5
@export var pitch_min := -60.0
@export var pitch_max := 40.0
var pitch := 0.0

#nodos
@onready var camera_pivot = $SpringArm3D
@onready var body = $skin
@onready var particles = $GPUParticles3D



func _ready():
	body.idle()
	particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent):
	camara(event)

func _physics_process(delta):
	movimiento(delta)
	ataque()
	move_and_slide()



func movimiento(delta: float):
	
	#Obtener vector de movimiento segun los inputs
	var input_dir = Input.get_vector("izquierda", "derecha", "atras", "adelante")
	#var direccion = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	

	#Cambiar inputs segun la camara
	var frente = -camera_pivot.global_transform.basis.z
	frente.y = 0
	frente = frente.normalized()
	var derecha = camera_pivot.global_transform.basis.x
	derecha.y = 0
	derecha = derecha.normalized()
	var direccion = (frente * input_dir.y) + (derecha * input_dir.x)
	direccion = direccion.normalized()

	if direccion.length() > 0:
		#rotacion de personaje segun inputs
		var rotacion = atan2(direccion.x, direccion.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		#mover el personaje
		velocity.x = direccion.x * speed
		velocity.z = direccion.z * speed
		body.run()
		particles.emitting = true
	else :
		body.idle()
		particles.emitting = false
		velocity.x = move_toward(velocity.x, 0,speed)
		velocity.z = move_toward(velocity.z, 0,speed)
		

	# Salto
	if Input.is_action_just_pressed("saltar") and is_on_floor():
		velocity.y = jump
		body.jump()
		particles.emitting = false

	# Gravedad y estado en aire
	if not is_on_floor():
		velocity.y -= gravity * delta
		body.fall()
		particles.emitting = false

func camara(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		#movimiento horizontal de la camara
		camera_pivot.rotate_y(deg_to_rad(-event.relative.x * sens_h))
		#movimiento vertical de la camara
		pitch = clamp(pitch - event.relative.y * sens_v, pitch_min, pitch_max)
		camera_pivot.rotation_degrees.x = pitch
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func ataque():
	if Input.is_action_just_pressed("atacar"):
		body.attack()
