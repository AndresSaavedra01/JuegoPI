extends CharacterBody3D

#variables
@export var speed := 8.0
@export var rotacion_velo := 10.0
@export var jump := 10.0
@export var gravity := 25.0
@export var jump2 := 12.0
@export var sens_h := 0.5
@export var sens_v := 0.5
@export var pitch_min := -60.0
@export var pitch_max := 40.0
@export var cooldown := 0.5
@export var max_jumps := 2
@export var bubble_fire_rate := 0.3
@export var water_fire_rate := 0.2
@export var melee_fire_rate := 0.6
@export var melee_impulse := 5.0

var pitch := 0.0
var is_jump2 := false
var cant_attack := true
var shooting := false
var current_mode := "bubble"
var modes := ["bubble", "water", "melee"]
var respawn = Vector3(0,0,0)

#nodos
@onready var camera_pivot := $SpringArm3D
@onready var body := $robotV3
@onready var particles := $GPUParticles3D
@onready var areaHit := $robotV3/robotV3/rig/Skeleton3D/BoneAttachment3D/hitbox
@onready var timer := $Timer


func _ready():
	particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))


func _input(event: InputEvent):
	camara(event)


func _physics_process(delta):
	movimiento(delta)
	$Control/Label.text = str(Engine.get_frames_per_second())
	move_and_slide()
	
	if position.y < -3.12:
		respawn_player()


func movimiento(delta: float):
	if is_attacking:
		
		velocity.x = move_toward(velocity.x, 0, speed * delta)
		velocity.z = move_toward(velocity.z, 0, speed * delta)
		
		
		if not is_on_floor():
			velocity.y -= gravity * delta
		return
	
	var input_dir = Input.get_vector("izquierda", "derecha", "atras", "adelante")

	var frente = -camera_pivot.global_transform.basis.z
	frente.y = 0
	frente = frente.normalized()
	var derecha = camera_pivot.global_transform.basis.x
	derecha.y = 0
	derecha = derecha.normalized()
	var direccion = (frente * input_dir.y) + (derecha * input_dir.x)
	direccion = direccion.normalized()

	if direccion.length() > 0:
		var rotacion = atan2(direccion.x, direccion.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		velocity.x = direccion.x * speed
		velocity.z = direccion.z * speed
		body.run()
		particles.emitting = true
	else :
		body.idle()
		particles.emitting = false
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	#salto
	if is_on_floor():
		is_jump2 = false
	if Input.is_action_just_pressed("saltar") and !is_jump2:
		if is_on_floor():
			body.jump()
			velocity.y = jump
		else:
			body.jump2()
			velocity.y = jump2
			is_jump2 = true
		particles.emitting = false
		
	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta
		body.fall()
		if velocity.y > 0:
			body.jump()
		else:
			body.fall()
		particles.emitting = false


func camara(event: InputEvent):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(deg_to_rad(-event.relative.x * sens_h))
		pitch = clamp(pitch - event.relative.y * sens_v, pitch_min, pitch_max)
		camera_pivot.rotation_degrees.x = pitch
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	

func _process(_delta: float) -> void:
	change_clean_tool()
	match current_mode:
		"bubble":
			bubble_attack()
			body.cañonMelee.visible = false
		
		"water":
			water_attack()
			
		"melee":
			melee_attack()
			body.cañonMelee.visible = true


# CAMBIO DE ATAQUES
var count := 0
func change_clean_tool():
	if Input.is_action_just_pressed("change-attack"):
		if count == (modes.size() -1):count = 0
		else: count +=1
		current_mode = modes[count]

# ATAQUES
func bubble_attack():
	if Input.is_action_just_pressed("atacar") and cant_attack:
		cant_attack = false
		timer.start(bubble_fire_rate)
		body.bubble_attack() # animación/disparo

var is_attacking := false

func melee_attack():
	if Input.is_action_just_pressed("atacar") and cant_attack:
		cant_attack = false
		timer.start(melee_fire_rate)
		
		# Activar estado de ataque
		is_attacking = true
		
		# Dar un impulso hacia delante (se aplica 1 vez)
		var forward = body.transform.basis.z.normalized()
		velocity.x = forward.x * melee_impulse
		velocity.z = forward.z * melee_impulse
		
		# Animación de melee
		body.attackMelee()
		
		# Hacer que se desactive después del cooldown
		await get_tree().create_timer(melee_fire_rate).timeout
		is_attacking = false

func water_attack():
	body.water_attack(Input.is_action_pressed("atacar"))


func _on_timer_timeout():
	cant_attack = true

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is RigidBody3D and is_attacking:
		var direction: Vector3 = (body.global_transform.origin - global_transform.origin).normalized()
		body.apply_impulse(direction * 5)
		
func respawn_player():
	position=respawn
	
	
