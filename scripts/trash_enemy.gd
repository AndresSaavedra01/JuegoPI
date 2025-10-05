extends CharacterBody3D

@export var health_points := 100.0
@export var damage := 5.0
@export var speed := 4.0
@export var rotacion_velo := 10.0

@onready var navAgent : NavigationAgent3D = $NavigationAgent3D
@onready var player : CharacterBody3D = get_tree().get_nodes_in_group("Player")[0]
@onready var body := $trash_enemy_skin
@onready var animationTree : AnimationTree = $AnimationTree
@onready var animationPlayback : AnimationNodeStateMachinePlayback = animationTree.get("parameters/playback")
@onready var frontCast : RayCast3D = $trash_enemy_skin/FrontCast
@onready var floorCast : RayCast3D = $trash_enemy_skin/FloorCast

func _ready() -> void:
	animIdle()
	
	
func _physics_process(delta: float) -> void:
	move(delta)

func move(delta : float) -> void:
	if (player.global_position - global_position).length() > 1:
		navAgent.set_target_position(player.global_position)
		var dest = navAgent.get_next_path_position()
		var dir = (dest - global_position).normalized()
		var rotacion = atan2(dir.x, dir.z)
		body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
		velocity = dir * speed
		animRun()
	else:
		idle()
	if not is_on_floor():
			velocity += get_gravity()
	move_and_slide()

func die() -> void:
	print("Fucking die")
	
func idle():
	velocity = Vector3.ZERO
	animIdle()

func attack(player : CharacterBody3D) -> void:
	print("Attack")
	
func patrol() -> void:
	print("Patrolling")
	
func Jump() -> void:
	print("Jumping")
	
func animAttack() -> void:
	animationPlayback.travel("Attack")
	
func animWalk() -> void:
	animationPlayback.travel("Walk")
	
func animRun() -> void:
	animationPlayback.travel("Run")
	
	
func animJump() -> void:
	animationPlayback.travel("Jump")
	
func animIdle() -> void:
	animationPlayback.travel("Idle")
