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
	
	robot.animation_finished.connect(_on_attack_animation_finished)
	
	movementSM.addState(State.new("Idle", Callable(self, "idle")))
	movementSM.addState(State.new("Run", Callable(self, "run")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	dieState.setOneShot(true)
	movementSM.addState(dieState)
	movementSM.addRelations("Idle", ["Run", "Die"])
	movementSM.addRelations("Run", ["Idle", "Die"])
	movementSM.addRelations("Die", ["Run", "Idle"])
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
	


func _physics_process(delta: float) -> void:
	var apuntando = camera_pivot.apuntando
	mira_sprite.visible = apuntando
	
	if in_combo:
		combo_timer += delta
		if combo_timer > combo_window:
			reset_combo()
	
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
	pass

#ATAQUES


func bubble():
	print("Mode Bubble")
	robot.cañonMelee.visible = false
	if Input.is_action_just_pressed("atacar"):
		cooldown_timer.start(bubble_rate)
		robot.bubble_attack()

func water():
	print("Mode water")
	robot.cañonMelee.visible = false
	var active
	if Input.is_action_pressed("atacar"):
		active = true
	else:
		active = false
	robot.water_attack(0,0,0,active)

func soap():
	print("Mode Soap")
	robot.cañonMelee.visible = false
	if Input.is_action_just_pressed("atacar"):
		
		robot.soap_attack()


var input_buffer := false  


func melee():
	hitbox.disable_mode = is_attacking

	if Input.is_action_just_pressed("atacar"):
		# Si está atacando, guardar la entrada
		if is_attacking:
			input_buffer = true
			return
		
		# Si puede atacar normalmente
		if can_attack:
			if not in_combo:
				start_combo(1)
			elif combo_step < 3:
				continue_combo()



func continue_combo():
	combo_step += 1
	execute_melee_attack(combo_step)

func start_combo(step: int):
	in_combo = true
	combo_step = step
	execute_melee_attack(combo_step)


func execute_melee_attack(step: int):
	can_attack = false
	is_attacking = true
	input_buffer = false

	if velocity.length() > 0.1:
		velocity *= 0.4

	var forward = robot.transform.basis.z.normalized()
	velocity.x += forward.x * melee_push
	velocity.z += forward.z * melee_push

	match step:
		1: robot.attackMelee()
		2: robot.attackMelee_2()
		3: robot.attackMelee_3()

	# Espera a que termine la animación (controlado por el signal del skin)
	await get_tree().create_timer(0.05).timeout  # da un pequeño margen
	await get_tree().create_timer(combo_window).timeout
	if not input_buffer:
		reset_combo()



func _on_attack_animation_finished():
	is_attacking = false
	can_attack = true

	if input_buffer and combo_step < 3:
		continue_combo()
	else:
		await get_tree().create_timer(combo_window).timeout
		if not input_buffer:
			reset_combo()



func reset_combo():
	in_combo = false
	is_attacking = false
	can_attack = true
	input_buffer = false
	combo_step = 0


func _process(delta: float) -> void:
	pass


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
