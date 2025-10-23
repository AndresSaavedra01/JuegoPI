extends CharacterBody3D
class_name player

const SPEED = 4.0
const JUMP_VELOCITY = 4.5
var camera_pitch := 0.0
@export var mouse_sens_x := 0.5
@export var mouse_sens_y := 0.5
@export var camera_pitch_min := -60.0
@export var camera_pitch_max := 40.0
@onready var camera_pivot := $camarita
@onready var cuerpo = $MeshInstance3D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("saltar"):
		velocity.y =JUMP_VELOCITY
	
	if camera_pivot.apuntando:
		_shoot_move(delta)
	else :
		_free_move(delta)
	move_and_slide()

func _shoot_move(delta):
	var input_dir = Input.get_vector("izquierda", "derecha", "adelante", "atras")

	# Obtenemos la cámara actual
	var cam = $camarita/EdgeSpringArm3D/RearSpringArm3D/Camera3D
	# Tomamos su orientación (sin inclinación vertical)
	var forward = cam.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = cam.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	# Movimiento relativo a la cámara
	var move_dir = (forward * input_dir.y) + (right * input_dir.x)
	move_dir = move_dir.normalized()

	# Movimiento suave
	if move_dir:
		velocity.x = move_dir.x * SPEED
		velocity.z = move_dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func _free_move(delta: float) -> void:
	var input_dir = Input.get_vector("izquierda", "derecha", "adelante", "atras")
	var forward = camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = camera_pivot.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	var move_dir = (forward * input_dir.y) + (right * input_dir.x)
	move_dir = move_dir.normalized()
	
	
	if move_dir:
		var target_rot = atan2(move_dir.x, move_dir.z)
		$MeshInstance3D.rotation.y = lerp_angle($MeshInstance3D.rotation.y, target_rot, 5 * delta)
		velocity.x = move_dir.x*SPEED
		velocity.z = move_dir.z*SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
