extends CharacterBody3D

@export var health_points : float = 100.0
@export var damage : float = 1.0
@export var runSpeed : float = 4.5
@export var walkSpeed : float = 1.5
@export var jumpImpulse : float = 9.0
@export var jumpSpeed : float = 5.0
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 20.0
@export var patrolPoints : Array[Marker3D]
@export var knockbackForce : float = 2.0
@export var knockbackUpForce : float = .3

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $Pegote_skin
@onready var animationTree : AnimationTree= $AnimationTree
@onready var animationPlayer : AnimationPlayer = $Pegote_skin/pegote_enemy/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var detectArea : Area3D = $DetectArea
@onready var detectTimer : Timer = $DetectTimer
@onready var knockbackTimer : Timer = $knockback
@onready var visionCast : RayCast3D = $VisionCast
@onready var floorCast : RayCast3D = $Pegote_skin/pegote_enemy/FloorCast
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var jumping : bool = false
@onready var lastPatrolCheck : int = Time.get_ticks_usec()
@onready var applyingKnockback : bool = false

var patrolTarget : Vector3

func _ready() -> void:
	stateMachine.addState(State.new("idle", Callable(self, "idle")))
	stateMachine.addState(State.new("run", Callable(self, "run")))
	stateMachine.addState(State.new("walk", Callable(self, "walk")))
	var dieState : State = State.new("die", Callable(self, "die"))
	dieState.setOneShot(true)
	stateMachine.addState(dieState)
	stateMachine.addRelations("idle", ["run", "walk", "die"])
	stateMachine.addRelations("run", ["idle", "walk", "die"])
	stateMachine.addRelations("walk", ["run", "idle", "die"])
	stateMachine.addRelations("die", ["run", "idle", "walk"])
	stateMachine.setActiveState("idle")
	
func _physics_process(delta: float) -> void:
	if applyingKnockback:
		applyKnockBack(delta)
	
func run() -> void:
	var delta : float = get_physics_process_delta_time()
	var toPlayeVector = player.global_position - global_position
	lookTo(delta, toPlayeVector.normalized())

	if toPlayeVector.length() <= 0.9 and abs(toPlayeVector.y) < 0.5:
		velocity = Vector3.ZERO
		if not animationPlayer.is_playing():
			animationPlayback.start("attack")
		else:
			animationPlayback.travel("attack")
		if not is_on_floor():
			velocity.y -= delta * fallSpeed

		# Cambio a idle después de terminar la animación de ataque
		if not animationPlayer.is_playing():
			stateMachine.travel("idle")
	elif not animationPlayback.get_current_node() == "attack":
		move("walk", player.global_position, runSpeed)
		if is_on_floor():
			navAgent.set_target_position(player.global_position)
		else:
			velocity.x = Vector3.ZERO.x
			velocity.z = Vector3.ZERO.z

func walk() -> void:
	if not navAgent.is_target_reached():
		move("walk", patrolTarget, walkSpeed)
	else:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("idle")

func idle():
	velocity.x = 0
	velocity.z = 0
	var currentPatrolCheck : int = Time.get_ticks_usec()
	if currentPatrolCheck - lastPatrolCheck >= 2_000_000:
		lastPatrolCheck = Time.get_ticks_usec()
		rng.set_seed(Time.get_ticks_msec())
		if not patrolPoints.is_empty():
			var index : int = rng.randi_range(0, patrolPoints.size() - 1)
			if patrolTarget != patrolPoints[index].global_position:
				patrolTarget = patrolPoints.get(index).global_position
				navAgent.set_target_position(patrolTarget)
				animationPlayer.speed_scale = 2.5
				animationPlayback.travel("walk")
				stateMachine.travel("walk")
		else:
			var x : float = rng.randf_range(1.0,3.0)
			if(rng.randf() > 0.5):
				x *= -1
			var z : float = rng.randf_range(1.0,3.0)
			if(rng.randf() > 0.5):
				z *= -1
			var target : Vector3 = Vector3(x, 0.0, z) + global_position
			var map : RID = navAgent.get_navigation_map()
			patrolTarget = NavigationServer3D.map_get_closest_point(map, target)
			navAgent.set_target_position(patrolTarget)
			animationPlayback.travel("walk")
			stateMachine.travel("walk")
	animationPlayback.travel("idle")
	var delta : float = get_physics_process_delta_time()
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	move_and_slide()

func attack() -> void:
	applyingKnockback = true
	knockbackTimer.start()
	player.takeDamage(damage)

func die() -> void:
	animationPlayback.travel("die")
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

func move(stateFrom : String, target : Vector3, speed : float):
	var delta : float = get_physics_process_delta_time()
	var dest : Vector3 = navAgent.get_next_path_position()
	var dir : Vector3 = (dest - global_position).normalized()
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	#elif dir.y > 0 or not floorCast.is_colliding(): aca acomodar logica de generar basuritas
#		if not animationPlayer.is_playing():
#			animationPlayback.start("Jump")
#			animationPlayback.travel("Jump")
#		velocity.y = jumpImpulse
#		speed = jumpSpeed
#	else:
	animationPlayback.travel(stateFrom)
	lookTo(delta, dir)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
	
func takeDamage(push_dir : Vector3, damage : float, knockbackForce : float, knockbackUpForce : float):
	if health_points > 0:
		health_points -= damage
		var delta : float = get_physics_process_delta_time()
		var knockback :Vector3 = push_dir * knockbackForce
		knockback.y = knockbackUpForce
		velocity = knockback
		print(health_points)
		animationPlayback.travel("takeDamage")
		move_and_slide()
	if health_points <= 0:
		stateMachine.travel("die")

func _on_timer_timeout() -> void:
	var overlaps = detectArea.get_overlapping_bodies()
	if not overlaps.size() > 0: return
	for overlap in overlaps:
		if not overlap.is_in_group("Player"): return
		visionCast.look_at(player.global_transform.origin + Vector3.UP * 0.5)
		visionCast.force_raycast_update()
		if not visionCast.is_colliding(): return
		var collider = visionCast.get_collider()
		if not collider.is_in_group("Player"): return
		if is_on_floor():
			stateMachine.travel("run")
		detectArea.get_node("CollisionShape3D").get_shape().radius = 30
		visionCast.target_position.z = -30

func _on_detect_area_body_exited(bodyExited: Node3D) -> void:
	if bodyExited.is_in_group("Player"):
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("idle")
		detectArea.get_node("CollisionShape3D").get_shape().radius = 10
		visionCast.target_position.z = -10

func _on_area_attack_body_entered(bodyEntered: Node3D) -> void:
	attack()

func applyKnockBack(delta : float):
	var knockback :Vector3 = (player.global_position - global_position).normalized()
	knockback *= knockbackForce
	knockback.y = knockbackUpForce
	player.velocity = knockback
	player.move_and_slide()

func lookTo(delta : float, dir : Vector3) -> void:
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)

func _on_knockback_timeout() -> void:
	applyingKnockback = false


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
