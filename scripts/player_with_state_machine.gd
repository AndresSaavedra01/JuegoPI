extends player

@onready var movementSM: StateMachine = $StateMachine
@onready var attackSM: StateMachine = $StateMachine2
@onready var aimSM: StateMachine = $StateMachine3
var move_dir : Vector3

func _ready() -> void:
	for i in range(totalHearts):
		heartsContiner.add_child(heartScene.instantiate())
	currentHeartIndex = totalHearts - 1
	health = totalHearts * 2
	particles.emitting = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mira_sprite.visible = false
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_end"))
	robot.connect("animation_finished", Callable(self, "on_animation_finished"))



	movementSM.addState(State.new("Idle", Callable(self, "idle")))
	movementSM.addState(State.new("Run", Callable(self, "run")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	movementSM.addState(dieState)
	
	movementSM.addRelations("Idle", ["Run", "Die"])
	movementSM.addRelations("Run", ["Idle", "Die"])
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


func _process(delta: float) -> void:
	$Control/Label.text = str(Engine.get_frames_per_second())


func _physics_process(delta: float) -> void:
	var apuntando = camera_pivot.apuntando
	mira_sprite.visible = apuntando
	
	if current_attack_mode != "Water":
		robot.water_attack(0,0,0,false)
	
	if !apuntando:
		var target_rot = atan2(move_dir.x, move_dir.z)
		robot.rotation.y = lerp_angle(robot.rotation.y, target_rot, rotation_speed *delta)
		
	move_and_slide()


#MOVIMIENTO
func idle():
	robot.idle()
	particles.emitting = false
	velocity.x = move_toward(velocity.x, 0, move_speed)
	velocity.z = move_toward(velocity.z, 0, move_speed)
	handle_jump(get_physics_process_delta_time())

func run():
	robot.run()
	particles.emitting = true
	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed
	handle_jump(get_physics_process_delta_time())

func die():
	print("Muelto")
	velocity = Vector3.ZERO
	velocity.y -= gravity_force
	robot.idle()

#ATAQUES


func bubble():
	#print("Mode Bubble")
	robot.cañonMelee.visible = false
	robot.cañon.proyectil = preload("res://esenas/burbuja.tscn")
	if Input.is_action_just_pressed("atacar") :
		cooldown_timer.start(bubble_rate)
		robot.bubble_attack()

func water():
	#print("Mode water")
	robot.cañonMelee.visible = false
	var active
	robot.cañon.proyectil = preload("res://esenas/burbuja.tscn")
	if Input.is_action_pressed("atacar"):
		active = true
	else:
		active = false
	robot.water_attack(0,0,0,active)

func soap():
	#print("Mode Soap")
	robot.cañonMelee.visible = false
	robot.cañon.proyectil = preload("res://esenas/soap.tscn")
	if Input.is_action_just_pressed("atacar"):
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
				tempo.start(2)
			1:  
				robot.attackMelee_2()
			2:
				robot.attackMelee_3()
		count +=1
		if count > 2:
			count = 0
		can_attack = false



func _on_cooldown_end():
	can_attack = true


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
