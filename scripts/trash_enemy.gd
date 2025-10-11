extends CharacterBody3D

@export var health_points : float = 100.0
@export var damage : float = 5.0
@export var speed : float = 4.0
@export var walkSpeed : float = 3.0
@export var jumpSpeed : float = 9.0
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 15.0
@export var patrolPoints : Array[Marker3D]

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $trash_enemy_skin
@onready var animationTree : AnimationTree= $AnimationTree
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var detectArea : Area3D = $DetectArea
@onready var detectTimer : Timer = $DetectTimer
@onready var visionCast : RayCast3D = $VisionCast
@onready var floorCast : RayCast3D = $trash_enemy_skin/FloorCast
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var jumping : bool = false
@onready var lastPatrolCheck : int = Time.get_ticks_usec()
var dest : Vector3

func _ready() -> void:
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Run", Callable(self, "run")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	stateMachine.addRelations("Idle", ["Run", "Walk", "Jump"])
	stateMachine.addRelations("Run", ["Idle", "Walk", "Jump"])
	stateMachine.addRelations("Walk", ["Run", "Idle", "Jump"])
	stateMachine.setActiveState("Idle")
	
func run() -> void:
	var delta : float = get_physics_process_delta_time()
	if (player.global_position - global_position).length() > 0.8:
		dest = navAgent.get_next_path_position()
		var dir : Vector3 = (dest - global_position).normalized()
		var rotacion : float = atan2(dir.x, dir.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if not is_on_floor():
			velocity.y -= delta * fallSpeed
		elif dir.y > 0 or dir.y < 0 and not floorCast.is_colliding():
			velocity.y = jumpSpeed
			animationPlayback.travel("Jump")
		else:
			navAgent.set_target_position(player.global_position)
			animationPlayback.travel("Run")
		move_and_slide()
	else:
		attack()

func die() -> void:
	print("die")
	
func idle():
	velocity = Vector3.ZERO
	var currentPatrolCheck : int = Time.get_ticks_usec()
	if currentPatrolCheck - lastPatrolCheck >= 2_000_000:
		lastPatrolCheck = Time.get_ticks_usec()
		rng.set_seed(Time.get_ticks_msec())
		if not patrolPoints.is_empty():
			var index : int = rng.randi_range(0, patrolPoints.size() - 1)
			var patrolTarget = patrolPoints.get(index).global_position
			navAgent.set_target_position(patrolTarget)
			animationPlayback.travel("Walk")
			stateMachine.travel("Walk")
	animationPlayback.travel("Idle")
	var delta : float = get_physics_process_delta_time()
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	move_and_slide()

func attack() -> void:
	print("Attack")
	animationPlayback.travel("Attack")
	
func walk() -> void:
	if not navAgent.is_target_reached():
		var delta : float = get_physics_process_delta_time()
		dest = navAgent.get_next_path_position()
		var dir : Vector3 = (dest - global_position).normalized()
		var rotacion : float = atan2(dir.x, dir.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if is_on_floor() and (dir.y > 0 or dir.y < 0 and not floorCast.is_colliding()):
			velocity.y = jumpSpeed
			animationPlayback.travel("Jump")
		else:
			animationPlayback.travel("Walk")
		if not is_on_floor():
			velocity.y -= delta * fallSpeed
		move_and_slide()
	else:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")

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

func _on_detect_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		stateMachine.travel("Idle")
		detectArea.get_node("CollisionShape3D").get_shape().radius = 10
		visionCast.target_position.z = -10
