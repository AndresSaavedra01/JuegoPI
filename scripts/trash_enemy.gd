extends CharacterBody3D

@export var health_points : float = 100.0
@export var damage : float = 5.0
@export var runSpeed : float = 4.0
@export var walkSpeed : float = 1.5
@export var jumpImpulse : float = 9.0
@export var jumpSpeed : float = 5.0
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 15.0
@export var patrolPoints : Array[Marker3D]
@export var knockbackForce : float = 40.0
@export var knockbackUpForce : float = 5.0

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $trash_enemy_skin
@onready var animationTree : AnimationTree= $AnimationTree
@onready var animationPlayer : AnimationPlayer = $trash_enemy_skin/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var detectArea : Area3D = $DetectArea
@onready var detectTimer : Timer = $DetectTimer
@onready var visionCast : RayCast3D = $VisionCast
@onready var floorCast : RayCast3D = $trash_enemy_skin/FloorCast
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var jumping : bool = false
@onready var lastPatrolCheck : int = Time.get_ticks_usec()
var patrolTarget : Vector3
var attackStart : int

func _ready() -> void:
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Run", Callable(self, "run")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	stateMachine.addState(State.new("Attack", Callable(self, "attack")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	dieState.setOneShot(true)
	stateMachine.addState(dieState)
	stateMachine.addRelations("Idle", ["Run", "Walk", "Attack", "Die"])
	stateMachine.addRelations("Run", ["Idle", "Walk", "Attack", "Die"])
	stateMachine.addRelations("Walk", ["Run", "Idle", "Attack", "Die"])
	stateMachine.addRelations("Attack", ["Run", "Idle", "Walk", "Die"])
	stateMachine.addRelations("Die", ["Run", "Idle", "Walk", "Attack"])
	stateMachine.setActiveState("Idle")
	
func run() -> void:
	var toPlayeVector = player.global_position - global_position
	if toPlayeVector.length() > 0.7:
		move("Run", player.global_position, runSpeed)
		if is_on_floor():
			navAgent.set_target_position(player.global_position)
	else:
		if not animationPlayback.is_playing():
			animationPlayback.start("Attack")
		else:
			animationPlayback.travel("Attack")
		var delta : float = get_physics_process_delta_time()
		if not is_on_floor():
			velocity.y -= delta * fallSpeed
		move_and_slide()

func walk() -> void:
	if not navAgent.is_target_reached():
		move("Walk", patrolTarget, walkSpeed)
	else:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")

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
				animationPlayback.travel("Walk")
				stateMachine.travel("Walk")
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
			animationPlayback.travel("Walk")
			stateMachine.travel("Walk")
	animationPlayback.travel("Idle")
	var delta : float = get_physics_process_delta_time()
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	move_and_slide()

func attack() -> void:
	var delta : float = get_physics_process_delta_time()
	var knockback :Vector3 = (player.global_position - global_position).normalized()
	knockback *= knockbackForce
	knockback.y = knockbackUpForce
	player.velocity = knockback
	player.move_and_slide()
	player.takeDamage(damage)
	attackStart = Time.get_ticks_msec()

func die() -> void:
	animationPlayback.travel("Die")
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()

func move(stateFrom : String, target : Vector3, speed : float):
	var delta : float = get_physics_process_delta_time()
	var dest : Vector3 = navAgent.get_next_path_position()
	var dir : Vector3 = (dest - global_position).normalized()
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	elif dir.y > 0 or dir.y < 0 and not floorCast.is_colliding():
		velocity.y = jumpImpulse
		speed = jumpSpeed
		animationPlayer.speed_scale = 2
		animationPlayback.travel("Jump")
	else:
		animationPlayback.travel(stateFrom)
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
		stateMachine.travel("Die")

func _on_timer_timeout() -> void:
	var overlaps = detectArea.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("Player"):
				visionCast.look_at(player.global_transform.origin + Vector3.UP * 0.5)
				visionCast.force_raycast_update()
				if visionCast.is_colliding():
					var collider = visionCast.get_collider()
					if collider.is_in_group("Player"):
						if is_on_floor():
							stateMachine.travel("Run")
						detectArea.get_node("CollisionShape3D").get_shape().radius = 30
						visionCast.target_position.z = -30

func _on_detect_area_body_exited(bodyExited: Node3D) -> void:
	if bodyExited.is_in_group("Player"):
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")
		detectArea.get_node("CollisionShape3D").get_shape().radius = 10
		visionCast.target_position.z = -10


func _on_area_3d_body_entered(bodyEntered: Node3D) -> void:
	print(bodyEntered)
	if bodyEntered.is_in_group("Player"):
		attack()
