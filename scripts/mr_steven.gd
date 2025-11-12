extends CharacterBody3D
class_name Boss

@export var health_points : float = 100.0
@export var damage : float = 1.0
@export var speed : float = 1.5
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 20.0
@export var knockbackForce : float = 3.0
@export var knockbackUpForce : float = 2.0
@export var cant_items_drop : int = 15
@export var radio_items_drop : float = 3
@export var itemScene : PackedScene

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $bossFinal
@onready var animationTree : AnimationTree= $AnimationTree
@onready var animationPlayer : AnimationPlayer = $bossFinal/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/StateMachine/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var jumping : bool = false
@onready var applyingKnockback : bool = false
@onready var gpuParticles : GPUParticles3D = $DieParticles
@onready var itemSpawnPoint : Marker3D = $ItemSpawnPoint
@onready var walkTimer : Timer = $WalkTimer
var isDeath : bool = false
var canWalk : bool = false
var is_attacking : bool = false

func _ready() -> void:
	rng.seed = Time.get_ticks_msec()
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	dieState.setOneShot(true)
	stateMachine.addState(dieState)
	stateMachine.addRelations("Idle", ["Walk", "Die"])
	stateMachine.addRelations("Walk", ["Idle", "Die"])
	stateMachine.addRelations("Die", ["Idle", "Walk"])
	stateMachine.setActiveState("Idle")
	
func _physics_process(delta: float) -> void:
	if applyingKnockback:
		var dir : Vector3 = (player.global_position - global_position).normalized()
		applyKnockBack(delta, player, dir, knockbackForce)
	
func walk() -> void:
	if canWalk:
		var delta : float = get_physics_process_delta_time()
		var toPlayeVector = player.global_position - global_position
		lookTo(delta, toPlayeVector.normalized())
		move()
		if is_on_floor():
			navAgent.set_target_position(player.global_position)
		else:
			velocity.y -= delta * fallSpeed
		move_and_slide()
	else:
		stateMachine.travel("Idle")

func idle():
	var distance_to_player : float = player.global_position.distance_to(global_position)
	if not is_attacking:
		if distance_to_player <= 3:
			var ramdon_value = rng.randi_range(0,1_000_000)
			print("1")
			if ramdon_value <= 700_000:
				animationPlayback.travel("Meele")
			else:
				animationPlayback.travel("Explosion")
			is_attacking = true
		elif distance_to_player <= 5:
			print("2")
			var ramdon_value = rng.randi_range(0,1_000_000)
			if ramdon_value <= 700_000:
				animationPlayback.travel("Explosion")
			else:
				animationPlayback.travel("Bean")
			is_attacking = true
		else:
			print("3")
			var ramdon_value = rng.randi_range(0,1_000_000)
			print(ramdon_value)
			if ramdon_value <= 700_000:
				canWalk = true
				if walkTimer.is_stopped():
					walkTimer.start()
				stateMachine.travel("Walk")
			else:
				animationPlayback.travel("Bean")
				is_attacking = true
	var delta : float = get_physics_process_delta_time()
	velocity.x = 0
	velocity.z = 0
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

func move():
	var delta : float = get_physics_process_delta_time()
	var dest : Vector3 = navAgent.get_next_path_position()
	var dir : Vector3 = (dest - global_position).normalized()	
	animationPlayback.travel("Walk")
	lookTo(delta, dir)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	move_and_slide()
	
func takeDamage(push_dir : Vector3, _damage : float, _knockbackForce : float, _knockbackUpForce : float):
	if health_points > 0:
		health_points -= _damage
		print(health_points)
		#if not animationTree.get("parameters/OneShot/active"):
			#animationTree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if health_points <= 0:
		isDeath = true
		stateMachine.travel("Die")

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
		applyingKnockback = false

func lookTo(delta : float, dir : Vector3) -> void:
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Ataque_3_cargando":
		for i in range(cant_items_drop):
			rng.randomize()
			var x : float = rng.randf()
			var z : float = rng.randf()
			if(rng.randf() > 0.5):
				x *= -1
			if(rng.randf() > 0.5):
				z *= -1
			var item_velocity : Vector3 = Vector3(x, 0, z).normalized()
			item_velocity *= radio_items_drop
			item_velocity.y = 2
			var item : Item = itemScene.instantiate()
			item.type = rng.randi_range(1,4)
			get_tree().get_first_node_in_group("World").add_child(item)
			item.velocity = item_velocity
			item.global_position = itemSpawnPoint.global_position
			item.move_and_slide()
		body.visible = false
		gpuParticles.emitting = true
	elif anim_name == "Ataque_1" or anim_name == "Ataque_2" or anim_name == "Ataque_3_completo":
		is_attacking = false
		

func _on_die_particles_finished() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_walk_timer_timeout() -> void:
	canWalk = false
