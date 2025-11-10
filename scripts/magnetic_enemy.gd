extends CharacterBody3D

#Nodos de mecánicas
@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $caneca
@onready var animationTree : AnimationTree= $caneca/AnimationTree
@onready var animationPlayer : AnimationPlayer = $caneca/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine : StateMachine = $StateMachine

#Variables estados-habilidades
@export var health_points : float = 100.0
@export var damage : float = 5.0

#Movimientos
@export var walk_speed: float = 2.0
@export var rotation_speed: float = 6.0
@export var fall_speed: float = 20.0
@export var patrol_radius: float = 10.0
@export var wait_time: float = 2.0  # segundos de espera entre cada destino
@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var patrol_target: Vector3
@export var patrol_points: Array[Node3D] 
var waiting: bool = false
var last_time: float = 0.0
var lastPatrolCheck: int = Time.get_ticks_usec()
@export var patrolWaitTime: float = 2.0 
#Variables para attract
@export var attract_strength : float = 8.0 #intensidad del campo de atraccion
@export var attract_distance : float = 10.0 #rango maximo de atrracion
@export var min_attract_distance : float = 1.0 #exita que el jugador se peque al enemigo
@export var max_attract_force : float = 20.0 #limite de fuerza 
@export var hunt_distance : float = 20
var surprise_timer: float = 0.0
var is_surprise : bool = false
@export var surprise_duration: float = 1.0  # segundos que se queda sorprendido

#Deteccion de obstáculos
@onready var vision_ray: RayCast3D = $caneca/vision_ray

#Variables de control
var has_been_surprised: bool = false
var is_attacking: bool = false
var can_attack: bool = true

func _ready() -> void:
	#Agregar los estados a la state machine
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	stateMachine.addState(State.new("Attract", Callable(self, "attract")))
	stateMachine.addState(State.new("Attack", Callable(self, "attack")))
	stateMachine.addState(State.new("Surprise", Callable(self, "surprise")))
	#Relaciones de lso estados
	stateMachine.addRelations("Idle", ["Walk", "Attract", "Surprise"])
	stateMachine.addRelations("Walk", ["Idle", "Walk", "Surprise"])
	stateMachine.addRelations("Surprise", ["Idle", "Walk", "Attract", "Attack"])
	stateMachine.addRelations("Attract", ["Idle", "Walk", "Attack", "Surprise"])
	stateMachine.addRelations("Attack", ["Idle", "Walk", "Attract"])
	#Estado inicial
	
	stateMachine.setActiveState("Idle")

func _physics_process(delta: float) -> void:
	detect_player()
	
func idle() -> void:
	velocity.x = 0
	velocity.z = 0
	var currentPatrolCheck : int = Time.get_ticks_usec()
	if currentPatrolCheck - lastPatrolCheck >= 2_000_000:
		lastPatrolCheck = Time.get_ticks_usec()
		rng.set_seed(Time.get_ticks_msec())
		if not patrol_points.is_empty():
			var index : int = rng.randi_range(0, patrol_points.size() - 1)
			var new_target : Vector3 = patrol_points[index].global_position
			if patrol_target != new_target:
				patrol_target = new_target
				navAgent.set_target_position(patrol_target)
				animationPlayer.speed_scale = 2.5
				animationPlayback.travel("Walk")
				stateMachine.travel("Walk")
		else:
			patrol_target = get_valid_patrol_point()
			navAgent.set_target_position(patrol_target)
			animationPlayback.travel("Walk")
			stateMachine.travel("Walk")
	animationPlayback.travel("Idle")
	move_and_slide()

func get_valid_patrol_point() -> Vector3:
	var angle = rng.randf_range(0, 2 * PI)
	var dist = rng.randf_range(1.0, patrol_radius) # puedes ajustar este rango
	var offset = Vector3(
		sin(angle) * dist,
		0,
		cos(angle) * dist
	)
	var candidate = global_position + offset
	var map = navAgent.get_navigation_map()
	return NavigationServer3D.map_get_closest_point(map, candidate)

func walk() -> void:
	if not navAgent.is_target_reached():
		move("Walk", patrol_target, walk_speed)
	else:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")

func attract() -> void:
	print("Ahora estoy en attract")
	var delta : float = get_physics_process_delta_time()
	# vector del jugador hacia el enemigo
	var to_enemy = global_position - player.global_position
	var distance = to_enemy.length()
	# Salirse si está fuera del rango de atracción global
	if distance > attract_distance:
		is_surprise = false
		stateMachine.travel("Idle")
		return
	if distance < min_attract_distance + 0.1:
		print("Atacar")
		return
	var look_dir = -to_enemy.normalized()
	look_dir.y = 0
	lookTo(delta, look_dir)
	# Calcular fuerza de atracción con suavisado e inversamente proporcional a la distanica
	var force_magnitude  = attract_strength * (1.0 - (distance / attract_distance))
	force_magnitude = clamp(force_magnitude, 0.0, max_attract_force)
	var pull_force = to_enemy.normalized() * force_magnitude
	player.velocity += pull_force
	player.move_and_slide()
	if animationPlayback.get_current_node() != "Attract":
		animationPlayback.travel("Attract")
	# Mantener al enemigo estable (no se mueve horizontalmente aquí)
	if is_on_floor():
		velocity.x = 0
		velocity.z = 0
	else:
		velocity.y -= delta * fall_speed
	move_and_slide()

func detect_player() -> void:
	var distance = global_position.distance_to(player.global_position)
	print(distance)
	if distance > hunt_distance:
		lastPatrolCheck = Time.get_ticks_usec()
		stateMachine.travel("Idle")
	# mirar al jugador con el raycast y actualizar
	vision_ray.look_at(player.global_transform.origin + Vector3.UP * 0.5)
	vision_ray.force_raycast_update()
	if not vision_ray.is_colliding():
		return
	var collider = vision_ray.get_collider()
	if not collider.is_in_group("Player"):
		return
	# decidir cuándo entrar a attract
	if is_surprise: return
	if distance < attract_distance + 0.2 and distance > min_attract_distance:
		print("Dentro del area")
		stateMachine.travel("Surprise")

func surprise() -> void:
	is_surprise = true
	var delta : float = get_physics_process_delta_time()
	# Vector hacia el jugador (desde el enemigo)
	var to_player : Vector3 = player.global_position - global_position
	var distance = to_player.length()
	# Mirar al jugador
	var look_dir = to_player.normalized()
	look_dir.y = 0
	lookTo(delta, look_dir)
	# Solo cambiar a la animación si aún no está en "Surprise"
	if animationPlayback.get_current_node() != "Surprise":
		animationPlayback.travel("Surprise")
		surprise_timer = 0.0  # reinicia el contador al entrar
	else:
		# Incrementar el tiempo solo mientras sigue en el estado
		surprise_timer += delta
	# Detener movimiento
	velocity = Vector3.ZERO
	move_and_slide()
	# Transición al terminar el tiempo
	if surprise_timer >= surprise_duration:
		surprise_timer = 0.0  
		if distance < attract_distance and distance > min_attract_distance:
			surprise_timer = 0
			stateMachine.travel("Attract")
			return
		else:
			surprise_timer = 0
			is_surprise = false
			stateMachine.travel("Idle")
			return
		
func attack() -> void:
	pass

func lookTo(delta : float, dir : Vector3) -> void:
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotation_speed * delta)

func move(stateFrom : String, target : Vector3, speed : float):
	var delta : float = get_physics_process_delta_time()
	var dest : Vector3 = navAgent.get_next_path_position()
	var dir : Vector3 = (dest - global_position).normalized()
	var rotacion : float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotation_speed * delta)
	if not is_on_floor():
		velocity.y -= delta * fall_speed
	 
	animationPlayback.travel(stateFrom)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()
