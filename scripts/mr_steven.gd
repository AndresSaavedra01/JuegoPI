extends CharacterBody3D
class_name Boss

@export var health_points : float = 500.0
@export var meele_damage : float = 2.0
@export var explosion_damage : float = 2.0
@export var bean_damage : float = 2.0
@export var speed : float = 1
@export var fallSpeed : float = 20.0
@export var rotacion_velo : float = 20.0
@export var meeleKnockbackForce : float = 3.0
@export var meeleKnockbackUpForce : float = 2.0
@export var explosionKnockbackForce : float = 3.0
@export var explosionKnockbackUpForce : float = 2.0
@export var beanKnockbackForce : float = 3.0
@export var beanKnockbackUpForce : float = 2.0
@export var cant_items_drop : int = 15
@export var radio_items_drop : float = 3
@export var itemScene : PackedScene
@export var entityScene : PackedScene

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
@onready var trashSpawnPoint : Marker3D = $TrashSpawnPoint
@onready var timer : Timer = $Timer
@onready var couldownTimer : Timer = $CouldownTimer
var isDeath : bool = false
var canWalk : bool = false
var is_attacking : bool = false
var is_steveando : bool = false
var is_in_explosion : bool = false
var is_in_bean : bool = false
var can_do_damage : bool = true
var damage : float
var knockbackForce : float
var knockbackUpForce : float
var current_entity : CharacterBody3D
var final_pos : Vector3

func _ready() -> void:
	rng.randomize()
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	var dieState : State = State.new("Die", Callable(self, "die"))
	dieState.setOneShot(true)
	stateMachine.addState(dieState)
	stateMachine.addRelations("Idle", ["Walk", "Die"])
	stateMachine.addRelations("Walk", ["Idle", "Die"])
	stateMachine.addRelations("Die", ["Idle", "Walk"])
	#stateMachine.setActiveState("Idle")
	
func _physics_process(delta: float) -> void:
	if applyingKnockback:
		var dir : Vector3 = (player.global_position - global_position).normalized()
		applyKnockBack(delta, player, dir, knockbackForce)
	if is_in_bean and can_do_damage:
		attack(bean_damage, beanKnockbackForce, beanKnockbackUpForce)
		can_do_damage = false
		if couldownTimer.is_stopped():
			couldownTimer.start()
	if is_in_explosion and can_do_damage:
		attack(explosion_damage, explosionKnockbackForce,explosionKnockbackUpForce)
		can_do_damage = false
		if couldownTimer.is_stopped():
			couldownTimer.start()
	
func walk() -> void:
	var distance_to_player : float = player.global_position.distance_to(global_position)
	if canWalk and not distance_to_player <= 3:
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
		canWalk = false
		stateMachine.travel("Idle")

func idle():
	var toPlayerVector = player.global_position - global_position
	var yToPlayer = toPlayerVector.y
	toPlayerVector.y = 0
	var distance_to_player : float = toPlayerVector.length()
	if not is_attacking and not is_steveando:
		if distance_to_player <= 3:
			var ramdon_value = rng.randi_range(0,1_000_000)
			if ramdon_value <= 700_000 and abs(yToPlayer) < 1:
				animationPlayback.travel("Meele")
			else:
				animationPlayback.travel("Explosion")
			is_attacking = true
		elif distance_to_player <= 7:
			var ramdon_value = rng.randi_range(0,1_000_000)
			if ramdon_value <= 150_000 and abs(yToPlayer) < 7:
				animationPlayback.travel("Bean")
			elif ramdon_value <= 600_000:
				animationPlayback.travel("Explosion")
			elif ramdon_value:
				animationPlayback.travel("Invocacion")
			is_attacking = true
		else:
			var ramdon_value = rng.randi_range(0,1_000_000)
			if ramdon_value <= 300_000:
				canWalk = true
				var tiempo = rng.randf_range(2.0,3.0)
				timer.wait_time = tiempo
				if timer.is_stopped():
					timer.start()
				stateMachine.travel("Walk")
			elif ramdon_value <= 700_000 and abs(yToPlayer) < 7:
				animationPlayback.travel("Bean")
				is_attacking = true
			elif ramdon_value <= 850_000:
				animationPlayback.travel("Invocacion")
				is_attacking = true
			else:
				animationPlayback.travel("Idle")
				is_steveando = true
				var tiempo = rng.randf_range(0.5,1.0)
				timer.wait_time = tiempo
				if timer.is_stopped():
					timer.start()
	var delta : float = get_physics_process_delta_time()
	velocity.x = 0
	velocity.z = 0
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	lookTo(delta, global_position.direction_to(player.global_position))
	move_and_slide()

func attack(_damage : float,_knockbackForce : float, _knockbackUpForce : float) -> void:
	applyingKnockback = true
	player.velocity.y = _knockbackUpForce
	knockbackForce = _knockbackForce
	player.takeDamage(_damage)

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

func applyKnockBack(delta : float, body : CharacterBody3D, dir : Vector3, _knockbackForce : float) -> void:
	var knockback :Vector3 = dir
	knockback *= _knockbackForce
	body.velocity.x = knockback.x
	body.velocity.z = knockback.z
	if not body.is_on_floor():
		velocity.y -= delta * fallSpeed
	else:
		applyingKnockback = false
	body.move_and_slide()

func lookTo(delta : float, dir : Vector3) -> void:
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	print(anim_name)
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
	elif anim_name == "Ataque_1" or anim_name == "Ataque_2" or anim_name == "Ataque_3_completo" or "Invocacion":
		animationPlayback.travel("Idle")
		is_steveando = true
		var tiempo = rng.randf_range(0.3,5.0)
		timer.wait_time = tiempo
		if timer.is_stopped():
			timer.start()
		is_attacking = false
		
func throw_entity(delta : float) -> void:
	if current_entity:
		if not current_entity.is_on_floor():
			var dir : Vector3 = (final_pos - global_position).normalized()
			current_entity.velocity.y -= delta * fallSpeed
			current_entity.velocity.x = dir.x * speed
			current_entity.velocity.z = dir.z * speed
			current_entity.move_and_slide()
		else:
			current_entity = null

func _on_die_particles_finished() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_walk_timer_timeout() -> void:
	canWalk = false
	is_steveando = false

func _on_meele_area_body_entered(body: Node3D) -> void:
	attack(meele_damage, meeleKnockbackForce, meeleKnockbackUpForce)


func _on_explosion_area_body_entered(body: Node3D) -> void:
	is_in_explosion = true

func _on_explosion_area_body_exited(body: Node3D) -> void:
	is_in_explosion = false


func _on_couldown_timer_timeout() -> void:
	can_do_damage = true


func _on_beam_area_body_entered(body: Node3D) -> void:
	is_in_bean = true


func _on_beam_area_body_exited(body: Node3D) -> void:
	is_in_bean = false


func _on_boss_final_invocar() -> void:
	current_entity = entityScene.instantiate()
	if current_entity:
		current_entity.vision_distance = 1000
		get_tree().get_first_node_in_group("World").add_child(current_entity)
		var pos : Vector3 = global_position.direction_to(player.global_position)
		var map : RID = navAgent.get_navigation_map()
		final_pos = NavigationServer3D.map_get_closest_point(map, pos)
		current_entity.global_position = trashSpawnPoint.global_position
		current_entity.scale *= 0.4
		var dir : Vector3 = (final_pos - global_position).normalized()
		var rotacion : float = atan2(dir.x, dir.z)
		current_entity.hunt_distance = 1000.0
		current_entity.body.rotate_y(rotacion)
