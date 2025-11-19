class_name Item
extends CharacterBody3D

@export var type : types = 0
@export var models : Array[Array]
@onready var collision : CollisionShape3D = $CollisionShape3D
@onready var rng : RandomNumberGenerator = RandomNumberGenerator.new()
@onready var cuerpo : Node3D
@onready var ray : RayCast3D

enum types {
	Plastic,
	Steel,
	Organic,
	Paper,
	Glass,
	Electronic
}

func _ready() -> void:
	var index = rng.randi_range(0, models[type].size() - 1) 
	cuerpo = models[type][index].instantiate()
	ray = cuerpo.get_node("RayCast3D")
	collision.shape = cuerpo.get_node("Mesh/StaticBody3D/CollisionShape3D").shape
	collision.scale = cuerpo.get_node("Mesh").scale
	add_child(cuerpo)

func _physics_process(delta: float) -> void:
	var gravity : Vector3 = get_gravity()
	if(not velocity.x and not velocity.z):
		gravity *= 0.3
	if(not is_on_floor()):
		velocity += gravity * delta
	if(ray.is_colliding() or is_on_floor()):
		velocity = Vector3(0, 1.5, 0)
	move_and_slide()



func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is player:
		queue_free()
		body.sumarItem()
