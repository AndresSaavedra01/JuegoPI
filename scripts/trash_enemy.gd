extends CharacterBody3D

@export var health_points := 100.0
@export var damage := 5.0
@export var speed := 4.0
@export var walkSpeed := 3.0
@export var jumpSpeed := 9.0
@export var fallSpeed := 20.0
@export var rotacion_velo := 15.0

@onready var navAgent := $NavigationAgent3D
@onready var player := get_tree().get_nodes_in_group("Player")[0]
@onready var body := $trash_enemy_skin
@onready var animationTree := $AnimationTree
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine := $StateMachine
@onready var detectArea := $DetectArea
@onready var detectTimer := $DetectTimer
@onready var visionCast := $VisionCast
@onready var floorCast := $trash_enemy_skin/FloorCast
@onready var rng := RandomNumberGenerator.new()
@onready var jumping := false

var dest

func _ready() -> void:
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Run", Callable(self, "run")))
	stateMachine.addState(State.new("Patrol", Callable(self, "patrol")))
	stateMachine.addState(State.new("Jump", Callable(self, "jump")))
	stateMachine.addRelations("Idle", ["Run", "Patrol", "Jump"])
	stateMachine.addRelations("Run", ["Idle", "Patrol", "Jump"])
	stateMachine.addRelations("Patrol", ["Run", "Idle", "Idle"])
	stateMachine.setActiveState("Run")
	
func run() -> void:
	var delta = get_process_delta_time()
	if (player.global_position - global_position).length() > 1:
		navAgent.set_target_position(player.global_position)
		dest = navAgent.get_next_path_position()
		var dir = (dest - global_position).normalized()
		var rotacion = atan2(dir.x, dir.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if is_on_floor() and (dir.y > 0 or dir.y < 0 and not floorCast.is_colliding()):
			velocity.y = jumpSpeed
			stateMachine.travel("Jump")
		animationPlayback.travel("Run")
	if not is_on_floor():
			velocity.y -= delta * fallSpeed
	move_and_slide()

func die() -> void:
	print("Fucking die")
	
func idle():
	velocity = Vector3.ZERO
	rng.seed = Time.get_ticks_usec()
	if rng.randf() * 100000 > 80000:
		stateMachine.travel("Patrol")
	animationPlayback.travel("Idle")

func attack(player : CharacterBody3D) -> void:
	print("Attack")
	animationPlayback.travel("Attack")
	
func patrol() -> void:
	var delta = get_process_delta_time()
	animationPlayback.travel("Walk")
	print("Patrolling")
	
func jump() -> void:
	var delta = get_process_delta_time()
	var dir = (dest - global_position).normalized()
	var rotacion = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	animationPlayback.travel("Jump")
	velocity.y -= delta * fallSpeed
	if is_on_floor():
		stateMachine.travel("Run")
	move_and_slide()
	

func _on_timer_timeout() -> void:
	var overlaps = detectArea.get_overlapping_bodies()
	if overlaps.size() > 0:
		for overlap in overlaps:
			if overlap.is_in_group("Player"):
				visionCast.look_at(player.global_transform.origin + Vector3.UP * 0.5)
				visionCast.force_raycast_update()
				if visionCast.is_colliding():
					var collider = visionCast.get_collider()
					print(collider)
					if collider.is_in_group("Player"):
						if is_on_floor():
							stateMachine.travel("Run")
						detectArea.get_node("CollisionShape3D").get_shape().radius = 30
						visionCast.target_position.z = -30

func _on_detect_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		#stateMachine.travel("Patrol")
		detectArea.get_node("CollisionShape3D").get_shape().radius = 10
		visionCast.target_position.z = -10
