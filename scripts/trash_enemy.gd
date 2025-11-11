extends CharacterBody3D
class_name TrashEnemy

@export var health_points : float = 100.0
@export var damage : float = 1.0
@export var runSpeed : float = 4.5
@export var walkSpeed : float = 1.5
@export var jumpImpulse : float = 9.0
@export var jumpSpeed : float = 5.0
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 20.0
@export var patrolPoints : Array[Marker3D]
@export var knockbackForce : float = 3.0
@export var knockbackUpForce : float = 2.0
@export var hunt_distance : float = 20
@export var cant_items_drop : int = 6
@export var radio_items_drop : float = 3
@export var itemScene : PackedScene

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $trash_enemy_skin
@onready var animationTree : AnimationTree= $AnimationTree
@onready var animationPlayer : AnimationPlayer = $trash_enemy_skin/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/StateMachine/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var visionCast : RayCast3D = $VisionCast
@onready var floorCast : RayCast3D = $trash_enemy_skin/FloorCast
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var jumping : bool = false
@onready var lastPatrolCheck : int = Time.get_ticks_usec()
@onready var applyingKnockback : bool = false
@onready var receivingKnockback : bool = false
@onready var gpuParticles : GPUParticles3D = $trash_enemy_skin/Armature/GPUParticles3D
var patrolTarget : Vector3
var isDeath : bool = false
var receivingKnockbackForce : float
var receivingKnockbackDir : Vector3

func _ready() -> void:
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Run", Callable(self, "run")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	dieState.setOneShot(true)
	stateMachine.addState(dieState)
	stateMachine.addRelations("Idle", ["Run", "Walk", "Die"])
	stateMachine.addRelations("Run", ["Idle", "Walk", "Die"])
	stateMachine.addRelations("Walk", ["Run", "Idle", "Die"])
	stateMachine.addRelations("Die", ["Run", "Idle", "Walk"])
	stateMachine.setActiveState("Idle")
	
func _physics_process(delta: float) -> void:
	if applyingKnockback:
		var dir : Vector3 = (player.global_position - global_position).normalized()
		applyKnockBack(delta, player, dir, knockbackForce)
	if(receivingKnockback):
		applyKnockBack(delta, self, receivingKnockbackDir, receivingKnockbackForce)
	detect_player()
	
func run() -> void:
	var delta : float = get_physics_process_delta_time()
	var toPlayeVector = player.global_position - global_position
	lookTo(delta, toPlayeVector.normalized())
	if toPlayeVector.length() <= 0.9 and abs(toPlayeVector.y) < 0.5:
		velocity = Vector3.ZERO
		if not animationPlayer.is_playing():
			animationPlayback.start("Attack")
		else:
			animationPlayback.travel("Attack")
		if not is_on_floor():
			velocity.y -= delta * fallSpeed
		move_and_slide()
	elif not animationPlayback.get_current_node() == "Attack":
		move("Run", player.global_position, runSpeed)
		if is_on_floor():
			navAgent.set_target_position(player.global_position)
		else:
			velocity.x = Vector3.ZERO.x
			velocity.z = Vector3.ZERO.z

func walk() -> void:
	if not navAgent.is_target_reached():
		move("Walk", patrolTarget, walkSpeed)
	else:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")

func idle():
	var delta : float = get_physics_process_delta_time()
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
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	move_and_slide()

func attack() -> void:
	applyingKnockback = true
	player.velocity.y = knockbackUpForce
	player.takeDamage(damage)

func die() -> void:
	animationPlayback.travel("Die")

func move(stateFrom : String, target : Vector3, speed : float):
	var delta : float = get_physics_process_delta_time()
	var dest : Vector3 = navAgent.get_next_path_position()
	var dir : Vector3 = (dest - global_position).normalized()
	var new_velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	elif dir.y > 0 or not floorCast.is_colliding():
		if not animationPlayer.is_playing():
			animationPlayback.start("Jump")
		else:
			animationPlayback.travel("Jump")
		velocity.y = jumpImpulse
		speed = jumpSpeed
	else:
		animationPlayback.travel(stateFrom)
	lookTo(delta, dir)
	new_velocity.x = dir.x * speed
	new_velocity.z = dir.z * speed
	if navAgent.avoidance_enabled:
		navAgent.velocity = new_velocity
	else:
		velocity = new_velocity
	move_and_slide()
	
func takeDamage(push_dir : Vector3, _damage : float, _knockbackForce : float, _knockbackUpForce : float):
	if health_points > 0:
		health_points -= _damage
		receivingKnockbackForce = _knockbackForce
		receivingKnockbackDir = push_dir
		receivingKnockback = true
		velocity.y = _knockbackUpForce
		if not animationTree.get("parameters/OneShot/active"):
			animationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if health_points <= 0:
		stateMachine.travel("Die")

func detect_player() -> void:
	if global_position.distance_to(player.global_position) > hunt_distance:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")
	visionCast.look_at(player.global_transform.origin + Vector3.UP * 0.5)
	visionCast.force_raycast_update()
	if not visionCast.is_colliding(): return
	var collider = visionCast.get_collider()
	if not collider.is_in_group("Player"): return
	if is_on_floor():
		stateMachine.travel("Run")

func _on_area_attack_body_entered(bodyEntered: Node3D) -> void:
	attack()

func applyKnockBack(delta : float, body : CharacterBody3D, dir : Vector3, _knockbackForce : float) -> void:
	var knockback :Vector3 = dir
	knockback *= _knockbackForce
	body.velocity.x = knockback.x
	body.velocity.z = knockback.z
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	body.move_and_slide()
	if body.is_on_floor():
		if body.is_in_group("Player"):
			applyingKnockback = false
		else:
			receivingKnockback = false

func lookTo(delta : float, dir : Vector3) -> void:
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Die":
		body.get_node("Armature/Skeleton3D").visible = false
		for i in range(cant_items_drop):
			rng.randomize()
			var x : float = rng.randf()
			var z : float = rng.randf()
			var item_velocity : Vector3 = Vector3(x, 0, z).normalized()
			item_velocity.y = 2
			var item : Item = itemScene.instantiate()
			item.type = rng.randi_range(1,4)
			get_tree().get_first_node_in_group("World").add_child(item)
			item.velocity = item_velocity
			item.global_position = body.get_node("Armature").global_position + Vector3.UP
			item.move_and_slide()
		gpuParticles.emitting = true

func _on_gpu_particles_3d_finished() -> void:
	if is_instance_valid(self):
		queue_free()
