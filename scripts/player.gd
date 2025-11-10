extends CharacterBody3D
class_name player
# ==========================================================
# CONFIGURACIÓN GENERAL
# ==========================================================
@export var move_speed := 8.0
@export var rotation_speed := 10.0
@export var jump_force := 10.0
@export var double_jump_force := 12.0
@export var gravity_force := 20.0
@export var COYOTE_TIME := 0.2
@export var totalHearts : int = 5
@export var heartScene : PackedScene
@export var bubbleKnockbackForce : float = 40.0
@export var bubbleKnockbackUpForce : float = 5.0
@export var waterKnockbackForce : float = 10.0
@export var waterKnockbackUpForce : float = 1.0
@export var bubbleDamage : float = 5.0
@export var waterDamage : float = 0.5
@export var knockbackForce : float = 4
@export var knockbackUpForce : float = 3
@export var damage : float = 10

# Sensibilidad de cámara
@export var mouse_sens_x := 0.5
@export var mouse_sens_y := 0.5
@export var camera_pitch_min := -60.0
@export var camera_pitch_max := 40.0

# Ataques
@export var bubble_rate := 0.3
@export var soap_rate := 0.3
@export var water_rate := 0.2
@export var melee_rate := 0.5
@export var melee_push := 5.0

# ==========================================================
# VARIABLES DE ESTADO
# ==========================================================
var camera_pitch := 0.0
var has_double_jumped := false
var can_attack := true
var is_attacking := false
var current_attack_mode := "bubble"
var attack_modes := ["bubble", "soap", "water", "melee"]
var attack_mode_index := 0
var dead:= false
var combo_step := 0
var combo_window := 1
var combo_timer := 0.0
var in_combo := false
var coyote_timer := 0.0
var currentHeartIndex : int
var health : int
# ==========================================================
# REFERENCIAS A NODOS
# ==========================================================
@onready var camera_pivot := $camaraPivot
@onready var robot : = $robotV3
@onready var particles := $GPUParticles3D
@onready var hitbox := $robotV3/robotV3/rig/Skeleton3D/BoneAttachment3D/Hitbox
@onready var cooldown_timer := $Timer
@onready var heartsContiner : HBoxContainer = $Control/hearts
@onready var mira_sprite := $camaraPivot/EdgeSpringArm3D/RearSpringArm3D/Camera3D/Sprite3D

# ==========================================================
# CICLOS DE VIDA
# ==========================================================
func _ready():
	for i in range(totalHearts):
		heartsContiner.add_child(heartScene.instantiate())
	currentHeartIndex = totalHearts - 1
	health = totalHearts * 2
	particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_end"))



func _physics_process(delta: float):
	handle_movement(delta)
	move_and_slide()
	$Control/Label.text = str(Engine.get_frames_per_second())


func _process(_delta: float) -> void:
	handle_attack_mode_change()
	match current_attack_mode:
		"bubble":
			handle_bubble_attack()
			robot.cañonMelee.visible = false
		"soap":
			handle_soap_attack()
			robot.cañonMelee.visible = false
		"water":
			handle_water_attack()
			robot.cañonMelee.visible = false
		"melee":
			handle_melee_attack(_delta)
			robot.cañonMelee.visible = true


# ==========================================================
# MOVIMIENTO Y SALTO
# ==========================================================
func handle_movement(delta: float):
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, move_speed * delta)
		velocity.z = move_toward(velocity.z, 0, move_speed * delta)
		if not is_on_floor():
			velocity.y -= gravity_force * delta
		return
	if camera_pivot.apuntando:
		handle_movenment_aim(delta)
		mira_sprite.visible = true
	else :
		mira_sprite.visible = false
		handle_movenment_free(delta)
	
	handle_jump(delta)

func handle_movenment_aim(delta:float):
	
	var input_dir = Input.get_vector("izquierda", "derecha", "atras", "adelante")

	var forward = -camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera_pivot.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	var move_dir = (forward * input_dir.y) + (right * input_dir.x)
	move_dir = move_dir.normalized()

	if move_dir.length() > 0 and !is_attacking:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		robot.run()
		particles.emitting = true
	else:
		robot.idle()
		particles.emitting = false
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)


func handle_movenment_free(delta:float):
	var input_dir = Input.get_vector("izquierda", "derecha", "atras", "adelante")
	var forward = -camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = camera_pivot.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	var move_dir = (forward * input_dir.y) + (right * input_dir.x)
	move_dir = move_dir.normalized()

	if move_dir.length() > 0 and !is_attacking:
		var target_rot = atan2(move_dir.x, move_dir.z)
		robot.rotation.y = lerp_angle(robot.rotation.y, target_rot, rotation_speed * delta)
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		robot.run()
		particles.emitting = true
	else:
		robot.idle()
		particles.emitting = false
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)


func handle_jump(delta: float):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_double_jumped = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("saltar"):
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = jump_force
			particles.emitting = false
			coyote_timer = 0.0  
		elif not has_double_jumped:
			robot.jump2()
			velocity.y = double_jump_force
			has_double_jumped = true
			particles.emitting = false
	if not is_on_floor():
		velocity.y -= gravity_force * delta
		if velocity.y > 0:
			robot.jump() 
		else:
			robot.fall()  
		particles.emitting = false




func handle_attack_mode_change():
	if Input.is_action_just_pressed("change-attack"):
		attack_mode_index = (attack_mode_index + 1) % attack_modes.size()
		current_attack_mode = attack_modes[attack_mode_index]


func handle_bubble_attack():
	if Input.is_action_just_pressed("atacar") and can_attack:
		can_attack = false
		cooldown_timer.start(bubble_rate)
		robot.bubble_attack()


func handle_soap_attack():
	if Input.is_action_just_pressed("atacar") and can_attack:
		can_attack = false
		cooldown_timer.start(soap_rate)
		robot.soap_attack()


func handle_melee_attack(delta):
	hitbox.disable_mode = is_attacking
	if not can_attack and Input.is_action_just_pressed("atacar"):
		return  # evita que se inicie otro ataque si está en cooldown

	if Input.is_action_just_pressed("atacar") and can_attack:
		# Si inicia un combo
		if not in_combo:
			start_combo(1)
		# Si ya está en combo, intenta avanzar al siguiente golpe
		elif combo_step < 3:
			continue_combo()
		
	# Si está en combo, cuenta el tiempo
	if in_combo:
		combo_timer += delta
		if combo_timer > combo_window:
			reset_combo()  # se acabó la ventana del combo

func start_combo(step):
	combo_step = step
	in_combo = true
	execute_melee_attack(combo_step)


func continue_combo():
	# Reinicia el tiempo de espera entre ataques
	combo_timer = 0.0
	combo_step += 1
	execute_melee_attack(combo_step)


func execute_melee_attack(step):
	can_attack = false
	cooldown_timer.start(melee_rate)
	is_attacking = true
	if velocity.length() > 0.1:
		velocity *= 0.4  # Reduce la velocidad un 60 % durante el ataque
	# Impulso hacia adelante
	var forward = robot.transform.basis.z.normalized()
	velocity.x += forward.x * melee_push
	velocity.z += forward.z * melee_push

	# Animación según el paso del combo
	match step:
		1:
			robot.attackMelee()
		2:
			robot.attackMelee_2()
		3:
			robot.attackMelee_3()

	# Después del golpe, permitir el siguiente
	await get_tree().create_timer(melee_rate).timeout
	is_attacking = false
	can_attack = true

	# Si ya llegó al final del combo, reiniciar
	if combo_step >= 3:
		reset_combo()


func reset_combo():
	combo_step = 0
	combo_timer = 0.0
	in_combo = false
	is_attacking = false
	can_attack = true


func handle_water_attack():
	robot.water_attack(waterDamage, waterKnockbackForce, waterKnockbackUpForce,Input.is_action_pressed("atacar"))


# ==========================================================
# COLISIONES Y TEMPORIZADOR
# ==========================================================
func _on_cooldown_end():
	can_attack = true


func _on_hitbox_body_entered(target: Node3D) -> void:
	if target is RigidBody3D and is_attacking:
		var push_dir: Vector3 = (target.global_transform.origin - global_transform.origin).normalized()
		target.apply_impulse(push_dir * 5)
	if target is CharacterBody3D and is_attacking:
		var push_dir: Vector3 = (target.global_transform.origin - global_transform.origin).normalized()
		if target.has_method("hit"):
			target.hit(push_dir)
	if target.has_method("takeDamage") and is_attacking:
		var push_dir: Vector3 = (target.global_position - global_position).normalized()
		target.takeDamage(push_dir, damage, knockbackForce, knockbackUpForce)
	

func takeDamage(damage : int):
	if currentHeartIndex >= 0:
		for i in range(damage):
			var heart : Heart = heartsContiner.get_child(currentHeartIndex)
			if heart.isFull():
				heart.mediumHeart()
			else:
				heart.emptyHeart()
				currentHeartIndex -= 1
			health -= 1
	if health <= 0:
		print("muerto")
			
			


func _on_animation_tree_2_animation_started(anim_name: StringName) -> void:
	if anim_name == "attack":
		await get_tree().create_timer(0.3).timeout
		robot.cañon.ataquar(bubbleDamage, bubbleKnockbackForce, bubbleKnockbackUpForce)
