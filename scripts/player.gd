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
@export var heartScene : = preload("res://esenas/heart.tscn")
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
@export var soap_rate := 0.8
@export var water_rate := 0.2
@export var melee_rate := 0.6

# ==========================================================
# VARIABLES DE ESTADO
# ==========================================================
var camera_pitch := 0.0
var has_double_jumped := false
var can_attack := true
var is_attacking := false
var current_attack_mode := "Bubble"
var attack_modes := ["Bubble", "Soap", "Water", "Melee"]
var current_move_mode := "Idle"
var move_mode := ["Idle", "Run", "Die"]
var attack_mode_index := 0
signal dead
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
@onready var robot : skin = $robotV3
@onready var particles := $GPUParticles3D
@onready var hitbox := $robotV3/robotV3/rig/Skeleton3D/BoneAttachment3D/Hitbox
@onready var cooldown_timer := $Timer
@onready var heartsContiner : HBoxContainer = $Control/hearts
@onready var mira_sprite := $camaraPivot/EdgeSpringArm3D/RearSpringArm3D/Camera3D/Sprite3D


@onready var movementSM: StateMachine = $MaquinasdeEstados/StateMachine
@onready var attackSM: StateMachine = $MaquinasdeEstados/StateMachine2
@onready var aimSM: StateMachine = $MaquinasdeEstados/StateMachine3
var move_dir : Vector3

func _ready() -> void:
	for i in range(totalHearts):
		heartsContiner.add_child(heartScene.instantiate())
	currentHeartIndex = totalHearts - 1
	health = totalHearts * 2
	particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mira_sprite.visible = false
	robot.connect("animation_finished", Callable(self, "on_animation_finished"))



	movementSM.addState(State.new("Idle", Callable(self, "idle")))
	movementSM.addState(State.new("Run", Callable(self, "run")))
	movementSM.addState(State.new("Die", Callable(self, "die")))
	
	movementSM.addRelations("Idle", ["Run", "Die"])
	movementSM.addRelations("Run", ["Idle", "Die"])
	movementSM.addRelations("Die", ["Idle"])
	
	movementSM.setActiveState("Idle")


	attackSM.addState(State.new("Bubble", Callable(self, "bubble")))
	attackSM.addState(State.new("Soap", Callable(self, "soap")))
	attackSM.addState(State.new("Water", Callable(self, "water")))
	attackSM.addState(State.new("Melee", Callable(self, "melee")))
	
	attackSM.addRelations("Bubble", ["Soap", "Water", "Melee"])
	attackSM.addRelations("Soap", ["Bubble", "Water", "Melee"])
	attackSM.addRelations("Water", ["Bubble", "Soap", "Melee"])
	attackSM.addRelations("Melee", ["Bubble", "Soap", "Water"])

	attackSM.setActiveState("Bubble")

func _input(event: InputEvent) -> void:
	if current_move_mode != "Die":
		if Input.get_vector("izquierda", "derecha", "atras", "adelante"):
			var input_dir = Input.get_vector("izquierda", "derecha", "atras", "adelante")
			movementSM.travel("Run")
			camera_input(input_dir)
		else :
			movementSM.travel("Idle")
	
	if Input.is_action_just_pressed("change-attack"):
		attack_mode_index = (attack_mode_index + 1) % attack_modes.size()
		current_attack_mode = attack_modes[attack_mode_index]
		attackSM.travel(current_attack_mode)
	
	if Input.is_action_just_pressed(attack_modes[0]):
		current_attack_mode = attack_modes[0]
		attackSM.travel(current_attack_mode)
	if Input.is_action_just_pressed(attack_modes[1]):
		current_attack_mode = attack_modes[1]
		attackSM.travel(current_attack_mode)
	if Input.is_action_just_pressed(attack_modes[2]):
		current_attack_mode = attack_modes[2]
		attackSM.travel(current_attack_mode)
	if Input.is_action_just_pressed(attack_modes[3]):
		current_attack_mode = attack_modes[3]
		attackSM.travel(current_attack_mode)
	



func _process(delta: float) -> void:
	$Control/Label.text = str(Engine.get_frames_per_second())

var step_timer = 0.0
const STEP_INTERVAL = 0.8  # cada 0.4 s un paso
var water_timer = 0.0
const WATER_INTERVAL = .41

func _physics_process(delta: float) -> void:
	var apuntando = camera_pivot.apuntando
	mira_sprite.visible = apuntando
	
	if current_attack_mode != "Water":
		robot.water_attack(0,0,0,false)
	
	if !apuntando:
		var target_rot = atan2(move_dir.x, move_dir.z)
		robot.rotation.y = lerp_angle(robot.rotation.y, target_rot, rotation_speed *delta)
		
	move_and_slide()
	
	if is_on_floor() and current_move_mode == "Run":
		step_timer -= delta
		if step_timer <= 0:
			$Sonidos/Steps.play()
			step_timer = STEP_INTERVAL	
		
	else:
		step_timer = 0
		$Sonidos/Steps.stop()
	
	if current_attack_mode == "Water" and active:
		water_timer -= delta
		if water_timer <= 0:
			$Sonidos/Water.play()
			water_timer = WATER_INTERVAL	
		
	else:
		water_timer = 0
		$Sonidos/Water.stop()


#MOVIMIENTO
func idle():
	robot.idle()
	particles.emitting = false
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)
	current_move_mode = move_mode[0]
	handle_jump(get_physics_process_delta_time())

func run():
	robot.run()
	particles.emitting = true
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	current_move_mode = move_mode[1]
	handle_jump(get_physics_process_delta_time())

var morido := false
func die():
	print("Muelto")
	velocity = Vector3.ZERO
	velocity.y -= gravity_force
	robot.die()
	current_move_mode = move_mode[2]
	particles.emitting =false
	if !morido: 
		dead.emit() 
		morido = true

func reset():
	movementSM.travel("Idle")
	morido = false
	health = totalHearts * 2
	currentHeartIndex = totalHearts - 1
	
	for child in heartsContiner.get_children():
		child.queue_free()

	for i in range(totalHearts):
		var new_heart = heartScene.instantiate()
		heartsContiner.add_child(new_heart)


#ATAQUES

func bubble():
	#print("Mode Bubble")
	robot.cañonMelee.visible = false
	robot.cañon.proyectil = preload("res://esenas/burbuja.tscn")
	robot.cañon.speed = 30.0
	if Input.is_action_just_pressed("atacar") and can_attack:
		cooldown_timer.start(bubble_rate)
		can_attack = false
		$Sonidos/Burbuja.play()
		robot.bubble_attack()

var active := false
func water():
	#print("Mode water")
	robot.cañonMelee.visible = false
	
	if Input.is_action_pressed("atacar"):
		
		active = true
	else:
		active = false
	robot.water_attack(0,0,0,active)

func soap():
	#print("Mode Soap")
	robot.cañonMelee.visible = false
	robot.cañon.proyectil = preload("res://esenas/soap.tscn")
	if Input.is_action_just_pressed("atacar") and can_attack:
		cooldown_timer.start(soap_rate)
		can_attack = false
		robot.soap_attack()


var count = 0
@onready var tempo = $Timer2
func melee():
	#print("Mode melee")
	robot.cañonMelee.visible = true
	if Input.is_action_just_pressed("atacar")  and can_attack:
		cooldown_timer.start(melee_rate)
		print("pepe")
		is_attacking = true
		match count:
			0: 
				robot.attackMelee()
				$Sonidos/Melee1.play()
				tempo.start(2)
			1:  
				robot.attackMelee_2()
				$Sonidos/Melee2.play()
			2:
				robot.attackMelee_3()
				$Sonidos/Melee3.play()
		count +=1
		if count > 2:
			count = 0
		can_attack = false



func handle_jump(delta: float):
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_double_jumped = false
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("saltar"):
		if is_on_floor() or coyote_timer > 0.0:
			velocity.y = jump_force
			$Sonidos/jump.play()
			particles.emitting = false
			coyote_timer = 0.0  
		elif not has_double_jumped:
			robot.jump2()
			$Sonidos/jump.play()
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

func camera_input(input):
	var forward = -camera_pivot.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = camera_pivot.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	move_dir = (forward * input.y) + (right * input.x)
	move_dir = move_dir.normalized()

func on_animation_finished():
	is_attacking = false


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
		movementSM.travel("Die")
		


func _on_timer_2_timeout() -> void:
	count = 0

func _on_animation_tree_2_animation_started(anim_name: StringName) -> void:
	if anim_name == "attack":
		await get_tree().create_timer(0.3).timeout
		robot.cañon.ataquar(bubbleDamage, bubbleKnockbackForce, bubbleKnockbackUpForce)


func _on_hitbox_body_entered(target: Node3D) -> void:
	if target is RigidBody3D and is_attacking:
		var push_dir: Vector3 = (target.global_transform.origin - global_transform.origin).normalized()
		target.apply_impulse(push_dir * 5)
	if target is CharacterBody3D and is_attacking:
		var push_dir: Vector3 = (target.global_transform.origin - global_transform.origin).normalized()
		if target.has_method("hit"):
			target.hit(push_dir)
		if target is TrashEnemy:
			target.takeDamage(push_dir, 10.0, 1, 5)


func _on_timer_timeout() -> void:
	can_attack = true
