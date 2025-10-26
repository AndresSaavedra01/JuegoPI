extends CharacterBody3D

#Variables de movimienos
@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body : Node3D = $caneca
@onready var animationTree : AnimationTree= $caneca/AnimationTree
@onready var animationPlayer : AnimationPlayer = $caneca/AnimationPlayer
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var stateMachine : StateMachine = $StateMachine
@onready var Area : Area3D = $Area3D

#Variables estados-habilidades
@export var health_points : float = 100.0
@export var damage : float = 5.0
@export var attract_var : float = 2.0
var attracting : bool = false
#Movimientos
@export var rotacion_velo : float = 15.0
@export var fallSpeed : float = 20.0
@export var walkSpeed : float = 1.5
@export var patrolPoints : Array[Marker3D]
@export var knockbackForce : float = 40.0
@export var knockbackUpForce : float = 5.0
@onready var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var patrolTarget: Vector3
var lastPatrolCheck: int = Time.get_ticks_usec()
@export var patrolWaitTime: float = 2.0 


func _ready() -> void:
	#Agregar los estados a la state machine
	stateMachine.addState(State.new("Idle", Callable(self, "idle")))
	stateMachine.addState(State.new("Walk", Callable(self, "walk")))
	stateMachine.addState(State.new("Attract", Callable(self, "attract")))
	stateMachine.addState(State.new("Attack", Callable(self, "attrack")))
	stateMachine.addState(State.new("Surprise", Callable(self, "surprise")))
	#Relaciones de lso estados
	stateMachine.addRelations("Idle", ["Walk", "Attract", "Surprise"])
	stateMachine.addRelations("Walk", ["Idle", "Walk", "Surprise"])
	stateMachine.addRelations("Suprise", ["Idle", "Walk", "Attract"])
	stateMachine.addRelations("Attract", ["Idle", "Walk", "Attack", "Surprise"])
	stateMachine.addRelations("Attack", ["Idle", "Walk", "Attract"])
	#Estado inicial
	stateMachine.setActiveState("attract")

func idle() -> void:
	pass	

func attract() -> void:
	if attracting:
		var dir : Vector3 = (global_position - player.global_position).normalized()
		dir *= attract_var
		dir.y = 0
		player.velocity += dir
		player.move_and_slide()

func move (stateFrom: String ,target: Vector3, speed: float) -> void:
	var delta = get_physics_process_delta_time() #tiempo sg desde el ultimo frame physics
	if navAgent.is_target_reachable():
		#No hace nada o detiene la velocidad
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
		
	var nextPos: Vector3 = navAgent.get_next_path_position()
	var dir: Vector3 = (nextPos - global_position).normalized()
	var rotation_y: float = atan2(dir.x, dir.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotation_y, rotacion_velo*delta)
	
	#Mover al enemigo en el plano xz
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	
	#Aplicar gravedad minima por seguridad
	if not is_on_floor():
		velocity.y -= delta * fallSpeed
	else:
		velocity.y = 0
	
	animationPlayback.travel(stateFrom)
	move_and_slide()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		attracting = true
		
		
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		attracting = false
