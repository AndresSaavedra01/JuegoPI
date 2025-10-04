extends CharacterBody3D
@export var health_points := 100.0
@export var damage := 5.0
@export var speed := 4.0
@export var player : CharacterBody3D
@export var rotacion_velo := 10.0

@onready var body := $trash_enemy
@onready var stateMachine : AnimationTree = $AnimationTree

func _physics_process(delta: float) -> void:
	move(delta)

func move(delta : float) -> void:
	var directionPlayer = player.global_position - global_position
	var direction = Vector3(directionPlayer.x, 0, directionPlayer.z).normalized()
	var rotacion = atan2(direction.x, direction.z)
	body.rotation.y = lerp_angle(body.rotation.y, rotacion, rotacion_velo * delta)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity = direction * speed
	if not is_on_floor():
		velocity += get_gravity()
	#animRun(true)
	move_and_slide()
	
func die() -> void:
	pass

func attack(player : CharacterBody3D) -> void:
	pass
	
func animAttack(active : bool) -> void:
	pass
	
func animWalk(active : bool) -> void:
	pass
	
func animRun(active : bool) -> void:
	stateMachine["parameters/conditions/isRunning"] = active
	stateMachine["parameters/conditions/isIdle"] = not active

func animJump(active : bool) -> void:
	pass
	
func animIdle(active : bool) -> void:
	pass
